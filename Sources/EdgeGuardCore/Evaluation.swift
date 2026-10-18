import Foundation

/// A flow with a ground-truth label: `.block` for malicious, `.allow` for benign.
public struct LabeledFlow: Codable, Sendable {
    public var flow: FlowEvent
    public var label: Action
}

/// Confusion counts for automatic blocking. Positive means "the firewall should block".
public struct EvalReport: Codable, Sendable, Equatable {
    public var malicious = 0
    public var benign = 0
    public var truePositives = 0     // malicious, blocked automatically
    public var askedMalicious = 0    // malicious, handed to the user
    public var missedMalicious = 0   // malicious, allowed or only observed
    public var falsePositives = 0    // benign, blocked automatically
    public var askedBenign = 0       // benign, handed to the user
    public var trueNegatives = 0     // benign, allowed

    public init() {}

    public var precision: Double? {
        let blocked = truePositives + falsePositives
        return blocked == 0 ? nil : Double(truePositives) / Double(blocked)
    }
    public var recall: Double? {
        malicious == 0 ? nil : Double(truePositives) / Double(malicious)
    }

    public func summary() -> String {
        func pct(_ v: Double?) -> String { v.map { String(format: "%.0f%%", $0 * 100) } ?? "n/a" }
        return """
        Flows: \(malicious + benign) (\(malicious) malicious, \(benign) benign)
        Malicious: \(truePositives) blocked, \(askedMalicious) asked, \(missedMalicious) missed
        Benign: \(trueNegatives) allowed, \(askedBenign) asked, \(falsePositives) wrongly blocked
        Auto-block precision: \(pct(precision))   recall: \(pct(recall))
        """
    }
}

public enum Evaluator {
    /// Runs every labeled flow through a fresh engine in the given policy and counts outcomes.
    public static func run(_ flows: [LabeledFlow], explainer: Explaining, policy: Policy) async -> EvalReport {
        var report = EvalReport()
        for item in flows {
            let engine = FirewallEngine(policy: policy, explainer: explainer)
            let outcome = await engine.handle(item.flow).outcome
            switch item.label {
            case .block:
                report.malicious += 1
                switch outcome {
                case .blockedAutomatically: report.truePositives += 1
                case .needsApproval: report.askedMalicious += 1
                default: report.missedMalicious += 1
                }
            default:
                report.benign += 1
                switch outcome {
                case .blockedAutomatically: report.falsePositives += 1
                case .needsApproval: report.askedBenign += 1
                default: report.trueNegatives += 1
                }
            }
        }
        return report
    }
}
