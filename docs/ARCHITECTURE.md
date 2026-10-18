# Architecture

## Components

| Component | State | Responsibility |
|---|---|---|
| `FlowEvent` | Available | Metadata of one outbound flow: process, host, port, protocol, bytes, first seen |
| `Redactor` | Available | Removes user paths and masks private network hosts before any external call |
| `LocalHeuristics` | Available | On-device triage. Returns nothing for routine traffic |
| `OpenAIExplainer` | Available | Sends a redacted flow to the OpenAI Responses API and parses a structured verdict |
| `Policy`, `AutonomyMode` | Available | Mode, confidence threshold, block expiry, protected processes |
| `FirewallEngine` | Available | Combines triage, verdict and policy into a decision. Keeps block rules and the audit log |
| `CachingExplainer`, `BudgetedExplainer` | Available | Verdict cache and a daily request budget around any explainer |
| `HeuristicBaseline` | Available | Rule-based stand-in for the AI, used as a comparison baseline |
| `JSONFileStore`, `EngineState` | Available | Saves block rules and the audit log across restarts |
| `Evaluator`, `edgeguard-eval` | Available | Measures precision and recall of automatic blocking on labeled flows |
| `edgeguard-cli` | Available | Runs a flow through the engine from JSON |
| EdgeGuardMenuBar | Preview | SwiftUI menu bar app that runs demo flows through the real engine |
| EdgeGuardFilter (NetworkExtension) | In development | Captures real flows and enforces active block rules |
| Shared team policies | Planned | Shareable policy files for MDM rollout |

## Decision flow

1. A flow arrives as a `FlowEvent` and is redacted.
2. An active block rule for the same process and host blocks it immediately, with no model call.
3. `LocalHeuristics` returns `nil` for routine traffic. The flow is allowed and nothing is sent.
4. Otherwise `OpenAIExplainer` returns a verdict: `severity`, `action` (allow, block, ask), `confidence`, `title`, `explanation`.
5. `FirewallEngine` applies the policy for the current mode. In `auto` mode it may create an expiring block rule. See [AUTONOMY.md](AUTONOMY.md).
6. The decision is returned and written to the audit log.

## Design decisions

- **Local first.** A cheap filter keeps most traffic off the network and keeps API usage proportional to real anomalies.
- **The model recommends, the policy decides.** The AI never acts directly. Deterministic code checks every recommendation against guardrails.
- **Structured output.** The model must return a fixed JSON shape. Anything else is treated as a failure and the user is asked.
- **Model is configuration.** The model name comes from `OPENAI_MODEL`.
- **No payload access.** The agent only sees flow metadata.
