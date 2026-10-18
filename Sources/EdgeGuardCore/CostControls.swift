import Foundation

/// Remembers recent verdicts so the same connection is not sent to the AI twice.
public actor VerdictCache {
    private var entries: [String: (verdict: Verdict, stored: Date)] = [:]

    public init() {}

    func get(_ key: String, ttl: TimeInterval) -> Verdict? {
        guard let e = entries[key], Date().timeIntervalSince(e.stored) < ttl else { return nil }
        return e.verdict
    }

    func set(_ key: String, _ verdict: Verdict) {
        entries[key] = (verdict, Date())
    }
}

public struct CachingExplainer: Explaining {
    private let inner: Explaining
    private let ttl: TimeInterval
    private let cache = VerdictCache()

    public init(_ inner: Explaining, ttl: TimeInterval = 900) {
        self.inner = inner
        self.ttl = ttl
    }

    public func explain(_ event: FlowEvent) async throws -> Verdict {
        let key = "\(event.process)|\(event.remoteHost)|\(event.remotePort)|\(event.proto)"
        if let hit = await cache.get(key, ttl: ttl) { return hit }
        let verdict = try await inner.explain(event)
        await cache.set(key, verdict)
        return verdict
    }
}

/// Caps AI requests per calendar day. When the cap is reached the engine asks the user instead.
public actor RequestBudget {
    public let dailyLimit: Int
    private var day = Calendar.current.startOfDay(for: Date())
    private var used = 0

    public init(dailyLimit: Int) { self.dailyLimit = dailyLimit }

    public func take() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        if today != day { day = today; used = 0 }
        guard used < dailyLimit else { return false }
        used += 1
        return true
    }

    public func usedToday() -> Int { used }
}

public struct BudgetedExplainer: Explaining {
    private let inner: Explaining
    public let budget: RequestBudget

    public init(_ inner: Explaining, budget: RequestBudget) {
        self.inner = inner
        self.budget = budget
    }

    public func explain(_ event: FlowEvent) async throws -> Verdict {
        guard await budget.take() else { throw ExplainerError.budgetExceeded }
        return try await inner.explain(event)
    }
}
