import XCTest
@testable import EdgeGuardCore

private struct Mock: Explaining {
    let verdict: Verdict?
    func explain(_ event: FlowEvent) async throws -> Verdict {
        guard let v = verdict else { throw ExplainerError.emptyOutput }
        return v
    }
}

private func verdict(_ action: Action = .block, _ severity: Severity = .high, _ confidence: Double = 0.97) -> Verdict {
    Verdict(severity: severity, action: action, confidence: confidence, title: "Possible reverse shell", explanation: "x")
}

private let badFlow = FlowEvent(process: "node", remoteHost: "45.83.64.12", remotePort: 4444)

final class FirewallEngineTests: XCTestCase {
    func testAutoModeBlocksConfidentThreatAndCreatesExpiringRule() async {
        let engine = FirewallEngine(policy: Policy(mode: .auto), explainer: Mock(verdict: verdict()))
        let d = await engine.handle(badFlow)
        XCTAssertEqual(d.outcome, .blockedAutomatically)
        let rules = await engine.activeRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertNotNil(rules.first?.expiresAt)
    }

    func testLowConfidenceAsksInsteadOfBlocking() async {
        let engine = FirewallEngine(policy: Policy(mode: .auto), explainer: Mock(verdict: verdict(.block, .high, 0.5)))
        let d = await engine.handle(badFlow)
        XCTAssertEqual(d.outcome, .needsApproval)
        let rules = await engine.activeRules()
        XCTAssertTrue(rules.isEmpty)
    }

    func testProtectedProcessIsNeverBlockedAutomatically() async {
        let flow = FlowEvent(process: "launchd", remoteHost: "45.83.64.12", remotePort: 4444)
        let engine = FirewallEngine(policy: Policy(mode: .auto), explainer: Mock(verdict: verdict(.block, .high, 0.99)))
        let d = await engine.handle(flow)
        XCTAssertEqual(d.outcome, .needsApproval)
    }

    func testMonitorModeNeverEnforces() async {
        let engine = FirewallEngine(policy: Policy(mode: .monitor), explainer: Mock(verdict: verdict()))
        let d = await engine.handle(badFlow)
        XCTAssertEqual(d.outcome, .observedOnly)
        let rules = await engine.activeRules()
        XCTAssertTrue(rules.isEmpty)
    }

    func testSuggestModeAsksBeforeBlocking() async {
        let engine = FirewallEngine(policy: Policy(mode: .suggest), explainer: Mock(verdict: verdict()))
        let d = await engine.handle(badFlow)
        XCTAssertEqual(d.outcome, .needsApproval)
    }

    func testModelFailureAsksAndBlocksNothing() async {
        let engine = FirewallEngine(policy: Policy(mode: .auto), explainer: Mock(verdict: nil))
        let d = await engine.handle(badFlow)
        XCTAssertEqual(d.outcome, .needsApproval)
        let rules = await engine.activeRules()
        XCTAssertTrue(rules.isEmpty)
    }

    func testRoutineTrafficNeverReachesTheModel() async {
        let routine = FlowEvent(process: "Dropbox", remoteHost: "162.125.1.18", remotePort: 443)
        let engine = FirewallEngine(policy: Policy(mode: .auto), explainer: Mock(verdict: nil))
        let d = await engine.handle(routine)
        XCTAssertEqual(d.outcome, .allowed)
    }

    func testUndoRemovesRuleAndAuditLogRecordsDecision() async {
        let engine = FirewallEngine(policy: Policy(mode: .auto), explainer: Mock(verdict: verdict()))
        let d = await engine.handle(badFlow)
        let removed = await engine.undo(ruleID: d.ruleID!)
        XCTAssertTrue(removed)
        let rules = await engine.activeRules()
        XCTAssertTrue(rules.isEmpty)
        let log = await engine.auditLog()
        XCTAssertEqual(log.count, 1)
    }

    func testExpiredRuleIsNotActive() async {
        let engine = FirewallEngine(policy: Policy(mode: .auto, blockTTL: -1), explainer: Mock(verdict: verdict()))
        _ = await engine.handle(badFlow)
        let rules = await engine.activeRules()
        XCTAssertTrue(rules.isEmpty)
    }
}
