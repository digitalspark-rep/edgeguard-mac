import Foundation

/// Anything that can judge a flow. `OpenAIExplainer` is the production implementation.
public protocol Explaining: Sendable {
    func explain(_ event: FlowEvent) async throws -> Verdict
}

public struct BlockRule: Codable, Sendable, Equatable, Identifiable {
    public enum Source: String, Codable, Sendable { case automatic, user }
    public var id: UUID
    public var process: String
    public var host: String
    public var createdAt: Date
    public var expiresAt: Date?
    public var source: Source
    public var reason: String
}

public struct Decision: Codable, Sendable, Equatable {
    public enum Outcome: String, Codable, Sendable {
        case allowed              // routine or judged safe
        case observedOnly         // monitor mode: nothing enforced
        case needsApproval        // the user decides
        case blockedAutomatically // the firewall acted on its own
    }
    public var outcome: Outcome
    public var flow: FlowEvent
    public var verdict: Verdict?
    public var reason: String
    public var ruleID: UUID?
}

public struct AuditEntry: Codable, Sendable, Equatable {
    public var date: Date
    public var decision: Decision
}

/// Decides what to do with each flow and records everything it does.
///
/// Safety properties, each covered by tests:
/// - the model is only called for flows that local heuristics flag;
/// - an automatic block needs `auto` mode, a block verdict, high severity and enough confidence;
/// - protected system processes are never blocked automatically;
/// - if the model is unavailable or answers badly, the user is asked and nothing is blocked;
/// - automatic blocks expire and can be undone.
public actor FirewallEngine {
    public let policy: Policy
    private let explainer: Explaining
    private let now: @Sendable () -> Date
    private var rules: [BlockRule] = []
    private var log: [AuditEntry] = []

    public init(policy: Policy, explainer: Explaining, now: @escaping @Sendable () -> Date = { Date() }) {
        self.policy = policy
        self.explainer = explainer
        self.now = now
    }

    public func handle(_ event: FlowEvent) async -> Decision {
        let flow = Redactor.sanitize(event)

        if let rule = activeRules().first(where: { $0.host == flow.remoteHost && $0.process == flow.process }) {
            return record(Decision(outcome: .blockedAutomatically, flow: flow, verdict: nil,
                                   reason: "Matches an active block rule.", ruleID: rule.id))
        }
        guard LocalHeuristics.assess(flow) != nil else {
            return Decision(outcome: .allowed, flow: flow, verdict: nil, reason: "Routine traffic, judged locally.", ruleID: nil)
        }

        let verdict: Verdict
        do {
            verdict = try await explainer.explain(flow)
        } catch {
            return record(Decision(outcome: .needsApproval, flow: flow, verdict: nil,
                                   reason: "Could not get a verdict. Nothing was blocked.", ruleID: nil))
        }

        switch policy.mode {
        case .monitor:
            return record(Decision(outcome: .observedOnly, flow: flow, verdict: verdict,
                                   reason: "Monitor mode: nothing enforced.", ruleID: nil))
        case .suggest:
            let o: Decision.Outcome = verdict.action == .allow ? .allowed : .needsApproval
            return record(Decision(outcome: o, flow: flow, verdict: verdict,
                                   reason: "Suggest mode: the user decides on blocks.", ruleID: nil))
        case .auto:
            return record(decideAutomatically(flow: flow, verdict: verdict))
        }
    }

    private func decideAutomatically(flow: FlowEvent, verdict: Verdict) -> Decision {
        if verdict.action == .allow && verdict.severity <= .low {
            return Decision(outcome: .allowed, flow: flow, verdict: verdict, reason: "Judged safe.", ruleID: nil)
        }
        let canBlock = verdict.action == .block
            && verdict.severity == .high
            && verdict.confidence >= policy.minConfidence
            && !policy.protectedProcesses.contains(flow.process)
        guard canBlock else {
            return Decision(outcome: .needsApproval, flow: flow, verdict: verdict,
                            reason: "Not confident enough, or protected process. The user decides.", ruleID: nil)
        }
        let rule = BlockRule(id: UUID(), process: flow.process, host: flow.remoteHost,
                             createdAt: now(), expiresAt: now().addingTimeInterval(policy.blockTTL),
                             source: .automatic, reason: verdict.title)
        rules.append(rule)
        return Decision(outcome: .blockedAutomatically, flow: flow, verdict: verdict,
                        reason: "High-severity threat, confidence \(verdict.confidence). Blocked until the rule expires.",
                        ruleID: rule.id)
    }

    /// The user confirms a block that needed approval. User rules do not expire.
    public func approveBlock(for event: FlowEvent) {
        let flow = Redactor.sanitize(event)
        rules.append(BlockRule(id: UUID(), process: flow.process, host: flow.remoteHost,
                               createdAt: now(), expiresAt: nil, source: .user, reason: "Approved by the user"))
    }

    /// Removes a rule. Returns false if it does not exist.
    @discardableResult
    public func undo(ruleID: UUID) -> Bool {
        let before = rules.count
        rules.removeAll { $0.id == ruleID }
        return rules.count < before
    }

    public func activeRules() -> [BlockRule] {
        let t = now()
        return rules.filter { $0.expiresAt.map { $0 > t } ?? true }
    }

    public func auditLog() -> [AuditEntry] { log }

    /// Everything that should survive a restart.
    public func snapshot() -> EngineState { EngineState(rules: rules, log: log) }

    public func restore(_ state: EngineState) {
        rules = state.rules
        log = state.log
    }

    private func record(_ d: Decision) -> Decision {
        log.append(AuditEntry(date: now(), decision: d))
        return d
    }
}
