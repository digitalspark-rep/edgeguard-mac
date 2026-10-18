import Foundation

/// How much the firewall may do without asking.
public enum AutonomyMode: String, Codable, Sendable {
    /// Observe and explain only. Never blocks.
    case monitor
    /// Explain and ask the user before any block.
    case suggest
    /// Block high-confidence threats by itself, within the guardrails below.
    case auto
}

/// Guardrails that bound what the firewall may do on its own.
public struct Policy: Codable, Sendable, Equatable {
    public var mode: AutonomyMode
    /// Minimum model confidence required for an automatic block.
    public var minConfidence: Double
    /// Automatic blocks expire after this many seconds.
    public var blockTTL: TimeInterval
    /// Processes that are never blocked automatically.
    public var protectedProcesses: Set<String>

    public static let defaultProtected: Set<String> = [
        "launchd", "kernel_task", "mDNSResponder", "configd", "trustd",
        "apsd", "nsurlsessiond", "softwareupdated"
    ]

    public init(mode: AutonomyMode = .suggest,
                minConfidence: Double = 0.9,
                blockTTL: TimeInterval = 3600,
                protectedProcesses: Set<String> = Policy.defaultProtected) {
        self.mode = mode
        self.minConfidence = minConfidence
        self.blockTTL = blockTTL
        self.protectedProcesses = protectedProcesses
    }
}
