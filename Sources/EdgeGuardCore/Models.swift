import Foundation

/// One outbound network flow observed on the Mac. Metadata only: no payloads, no URLs.
public struct FlowEvent: Codable, Sendable, Equatable {
    public var process: String
    public var remoteHost: String
    public var remotePort: Int
    public var proto: String
    public var bytesOut: Int
    public var firstSeen: Date

    public init(process: String, remoteHost: String, remotePort: Int,
                proto: String = "tcp", bytesOut: Int = 0, firstSeen: Date = Date()) {
        self.process = process
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.proto = proto
        self.bytesOut = bytesOut
        self.firstSeen = firstSeen
    }
}

public enum Severity: String, Codable, Sendable, Comparable {
    case info, low, medium, high

    private var rank: Int {
        switch self {
        case .info: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
    public static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rank < rhs.rank }
}

/// What the model recommends doing with a flow.
public enum Action: String, Codable, Sendable {
    case allow, block, ask
}

/// Structured result returned by the explainer.
public struct Verdict: Codable, Sendable, Equatable {
    public var severity: Severity
    public var action: Action
    public var confidence: Double
    public var title: String
    public var explanation: String

    public init(severity: Severity, action: Action, confidence: Double, title: String, explanation: String) {
        self.severity = severity
        self.action = action
        self.confidence = confidence
        self.title = title
        self.explanation = explanation
    }
}
