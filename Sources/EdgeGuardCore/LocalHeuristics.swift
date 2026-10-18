import Foundation

/// Cheap on-device rules. Routine traffic is judged here and never leaves the Mac.
public enum LocalHeuristics {
    static let suspiciousPorts: Set<Int> = [4444, 1337, 31337, 6667, 9001]
    static let commonPorts: Set<Int> = [80, 443, 53, 22, 993, 587]
    static let shellLikeProcesses: Set<String> = ["bash", "zsh", "sh", "nc", "ncat", "curl", "python3", "node", "perl", "ruby"]

    /// Returns nil when the flow looks routine.
    public static func assess(_ event: FlowEvent) -> Severity? {
        if Redactor.isPrivateHost(event.remoteHost) { return nil }
        var score = 0
        if suspiciousPorts.contains(event.remotePort) { score += 2 }
        if !commonPorts.contains(event.remotePort) { score += 1 }
        if shellLikeProcesses.contains(event.process) { score += 1 }
        if event.bytesOut > 50_000_000 { score += 1 }
        switch score {
        case 0: return nil
        case 1: return .low
        case 2: return .medium
        default: return .high
        }
    }
}
