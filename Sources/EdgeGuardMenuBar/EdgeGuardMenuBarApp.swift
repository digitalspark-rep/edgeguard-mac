import SwiftUI
import EdgeGuardCore

/// Preview of the menu bar app. It runs demo flows through the real engine until the
/// NetworkExtension filter supplies live traffic.
@MainActor
final class AppModel: ObservableObject {
    @Published var decisions: [Decision] = []
    @Published var rules: [BlockRule] = []
    @Published var mode: AutonomyMode = .suggest
    private var engine: FirewallEngine

    static func makeEngine(mode: AutonomyMode) -> FirewallEngine {
        let env = ProcessInfo.processInfo.environment
        let explainer: Explaining
        if let key = env["OPENAI_API_KEY"], let model = env["OPENAI_MODEL"] {
            explainer = BudgetedExplainer(CachingExplainer(OpenAIExplainer(apiKey: key, model: model)),
                                          budget: RequestBudget(dailyLimit: 500))
        } else {
            explainer = HeuristicBaseline()
        }
        return FirewallEngine(policy: Policy(mode: mode), explainer: explainer)
    }

    init() { engine = AppModel.makeEngine(mode: .suggest) }

    func setMode(_ newMode: AutonomyMode) {
        mode = newMode
        engine = AppModel.makeEngine(mode: newMode)
        decisions = []
        rules = []
    }

    func runDemo() async {
        for flow in DemoFlows.all {
            let d = await engine.handle(flow)
            if d.outcome != .allowed { decisions.insert(d, at: 0) }
        }
        rules = await engine.activeRules()
    }

    func approve(_ d: Decision) async {
        await engine.approveBlock(for: d.flow)
        rules = await engine.activeRules()
    }

    func undo(_ rule: BlockRule) async {
        await engine.undo(ruleID: rule.id)
        rules = await engine.activeRules()
    }
}

enum DemoFlows {
    static let all: [FlowEvent] = [
        FlowEvent(process: "node", remoteHost: "45.83.64.12", remotePort: 4444, bytesOut: 18_240),
        FlowEvent(process: "Dropbox", remoteHost: "162.125.1.18", remotePort: 443, bytesOut: 820_000),
        FlowEvent(process: "python3", remoteHost: "203.0.113.50", remotePort: 6667, bytesOut: 2_200),
        FlowEvent(process: "curl", remoteHost: "cdn-update.top", remotePort: 8080, bytesOut: 64_000)
    ]
}

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EdgeGuard").font(.headline)
            Picker("Mode", selection: Binding(get: { model.mode }, set: { model.setMode($0) })) {
                Text("Monitor").tag(AutonomyMode.monitor)
                Text("Suggest").tag(AutonomyMode.suggest)
                Text("Auto").tag(AutonomyMode.auto)
            }
            .pickerStyle(.segmented)

            Button("Run demo flows") { Task { await model.runDemo() } }

            if model.decisions.isEmpty {
                Text("No decisions yet. Demo flows only: live traffic arrives with the NetworkExtension.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(Array(model.decisions.enumerated()), id: \.offset) { _, d in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(d.flow.process) → \(d.flow.remoteHost):\(d.flow.remotePort)").font(.subheadline)
                    Text(d.outcome.rawValue + ": " + d.reason).font(.caption).foregroundStyle(.secondary)
                    if d.outcome == .needsApproval {
                        Button("Block") { Task { await model.approve(d) } }
                    }
                }
            }

            if !model.rules.isEmpty {
                Divider()
                Text("Active block rules").font(.subheadline)
                ForEach(model.rules) { rule in
                    HStack {
                        Text("\(rule.process) → \(rule.host)").font(.caption)
                        Spacer()
                        Button("Undo") { Task { await model.undo(rule) } }
                    }
                }
            }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        .padding(12)
        .frame(width: 340)
    }
}

@main
struct EdgeGuardMenuBarApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("EdgeGuard", systemImage: "shield.lefthalf.filled") {
            ContentView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
