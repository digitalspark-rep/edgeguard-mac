import XCTest
@testable import EdgeGuardCore

final class CoreTests: XCTestCase {
    func testRedactorKeepsOnlyExecutableName() {
        let e = FlowEvent(process: "/Users/anna/dev/app/node", remoteHost: "45.83.64.12", remotePort: 4444)
        XCTAssertEqual(Redactor.sanitize(e).process, "node")
    }

    func testRedactorMasksPrivateHosts() {
        let e = FlowEvent(process: "ssh", remoteHost: "192.168.1.20", remotePort: 22)
        XCTAssertEqual(Redactor.sanitize(e).remoteHost, "private-network-host")
    }

    func testRoutineTrafficIsNotFlagged() {
        let e = FlowEvent(process: "Dropbox", remoteHost: "162.125.1.18", remotePort: 443)
        XCTAssertNil(LocalHeuristics.assess(e))
    }

    func testSuspiciousFlowIsHigh() {
        let e = FlowEvent(process: "node", remoteHost: "45.83.64.12", remotePort: 4444)
        XCTAssertEqual(LocalHeuristics.assess(e), .high)
    }

    func testParsesResponsesEnvelope() throws {
        let inner = #"{"severity":"high","action":"block","confidence":0.95,"title":"t","explanation":"e"}"#
        let outer: [String: Any] = ["output": [["content": [["type": "output_text", "text": inner]]]]]
        let data = try JSONSerialization.data(withJSONObject: outer)
        let v = try OpenAIExplainer.parse(data)
        XCTAssertEqual(v.action, .block)
        XCTAssertEqual(v.confidence, 0.95, accuracy: 0.001)
    }

    func testRequestDisablesStorage() throws {
        let ex = OpenAIExplainer(apiKey: "k", model: "m")
        let body = try ex.requestBody(for: FlowEvent(process: "p", remoteHost: "h", remotePort: 1))
        let obj = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(obj?["store"] as? Bool, false)
    }
}
