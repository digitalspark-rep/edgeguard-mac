import Foundation

/// A rule-based stand-in for the AI. It needs no network or key, and serves as the
/// baseline that real models are compared against in the evaluation harness.
public struct HeuristicBaseline: Explaining {
    public init() {}

    public func explain(_ event: FlowEvent) async throws -> Verdict {
        let target = "\(event.process) -> \(event.remoteHost):\(event.remotePort)"
        switch LocalHeuristics.assess(event) {
        case .high?:
            return Verdict(severity: .high, action: .block, confidence: 0.9,
                           title: "Rule-based: high-risk connection",
                           explanation: "\(target) matches several suspicious indicators.")
        case .medium?:
            return Verdict(severity: .medium, action: .ask, confidence: 0.6,
                           title: "Rule-based: unusual connection",
                           explanation: "\(target) is unusual. Review before allowing.")
        default:
            return Verdict(severity: .low, action: .allow, confidence: 0.8,
                           title: "Rule-based: looks routine",
                           explanation: "\(target) matches no strong indicator.")
        }
    }
}
