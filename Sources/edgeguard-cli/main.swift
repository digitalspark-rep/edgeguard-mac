import Foundation
import EdgeGuardCore

// Usage: swift run edgeguard-cli < examples/suspicious-flow.json
// Env:   OPENAI_API_KEY and OPENAI_MODEL (a current model name from your OpenAI account)
//        EDGEGUARD_MODE = monitor | suggest (default) | auto
let input = FileHandle.standardInput.readDataToEndOfFile()
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

guard let event = try? decoder.decode(FlowEvent.self, from: input) else {
    FileHandle.standardError.write(Data("Could not read a FlowEvent JSON object from stdin.\n".utf8))
    exit(1)
}

let flow = Redactor.sanitize(event)
guard let level = LocalHeuristics.assess(flow) else {
    print("Routine traffic. Judged locally; nothing was sent to the API.")
    exit(0)
}
print("Local assessment: \(level.rawValue)")

let env = ProcessInfo.processInfo.environment
guard let key = env["OPENAI_API_KEY"], let model = env["OPENAI_MODEL"] else {
    print("Set OPENAI_API_KEY and OPENAI_MODEL to let the AI decide. Payload that would be sent:")
    let enc = JSONEncoder()
    enc.dateEncodingStrategy = .iso8601
    enc.outputFormatting = [.prettyPrinted]
    print(String(decoding: try enc.encode(flow), as: UTF8.self))
    exit(0)
}

let mode = AutonomyMode(rawValue: env["EDGEGUARD_MODE"] ?? "suggest") ?? .suggest
let engine = FirewallEngine(policy: Policy(mode: mode),
                            explainer: OpenAIExplainer(apiKey: key, model: model))
let decision = await engine.handle(event)

print("Mode: \(mode.rawValue)")
print("Outcome: \(decision.outcome.rawValue). \(decision.reason)")
if let v = decision.verdict {
    print("[\(v.severity.rawValue), confidence \(v.confidence)] \(v.title)\n\(v.explanation)")
}
for rule in await engine.activeRules() {
    print("Active rule: block \(rule.process) -> \(rule.host) until \(rule.expiresAt.map { "\($0)" } ?? "removed by user")")
}
