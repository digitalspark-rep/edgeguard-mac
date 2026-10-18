import Foundation

public struct EngineState: Codable, Sendable, Equatable {
    public var rules: [BlockRule]
    public var log: [AuditEntry]
    public init(rules: [BlockRule] = [], log: [AuditEntry] = []) {
        self.rules = rules
        self.log = log
    }
}

/// Stores engine state as a JSON file, written atomically.
public struct JSONFileStore: Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }

    public func save(_ state: EngineState) throws {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try enc.encode(state).write(to: url, options: .atomic)
    }

    /// Returns nil when no state has been saved yet.
    public func load() throws -> EngineState? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(EngineState.self, from: Data(contentsOf: url))
    }
}

extension Policy {
    /// Loads a policy from a JSON file, for example one shared with a team.
    public static func load(from url: URL) throws -> Policy {
        try JSONDecoder().decode(Policy.self, from: Data(contentsOf: url))
    }
}
