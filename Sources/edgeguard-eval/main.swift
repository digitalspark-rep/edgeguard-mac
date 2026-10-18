import Foundation
import EdgeGuardCore

// Usage: swift run edgeguard-eval examples/eval/labeled-flows.json
// Env:   OPENAI_API_KEY and OPENAI_MODEL run the AI model. Without them the rule-based baseline runs.
//        EDGEGUARD_EVAL_BUDGET caps AI requests (default 200).
guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write(Data("Usage: edgeguard-eval <labeled-flows.json>\n".utf8))
    exit(1)
}

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
guard let data = FileManager.default.contents(atPath: CommandLine.arguments[1]),
      let flows = try? decoder.decode([LabeledFlow].self, from: data) else {
    FileHandle.standardError.write(Data("Could not read labeled flows from \(CommandLine.arguments[1]).\n".utf8))
    exit(1)
}

let env = ProcessInfo.processInfo.environment
let explainer: Explaining
let name: String
if let key = env["OPENAI_API_KEY"], let model = env["OPENAI_MODEL"] {
    let limit = Int(env["EDGEGUARD_EVAL_BUDGET"] ?? "") ?? 200
    explainer = BudgetedExplainer(CachingExplainer(OpenAIExplainer(apiKey: key, model: model)),
                                  budget: RequestBudget(dailyLimit: limit))
    name = "AI model \(model) (budget \(limit) requests)"
} else {
    explainer = HeuristicBaseline()
    name = "rule-based baseline"
}

print("Explainer: \(name)")
let report = await Evaluator.run(flows, explainer: explainer, policy: Policy(mode: .auto))
print(report.summary())
