# Changelog

## 0.1.0 (unreleased)

- Core library: flow model, redaction with input hardening, local triage
- AI client (OpenAI Responses API) returning allow, block or ask with confidence
- Autonomy engine: monitor, suggest and auto modes; confidence threshold; protected processes; expiring rules; undo; audit log
- Cost controls: verdict cache and daily request budget
- State persistence as a JSON file; policy files
- Evaluation harness with a 24-flow synthetic labeled set and a rule-based baseline
- Command-line tools `edgeguard-cli` and `edgeguard-eval`
- Menu bar app preview running demo flows through the real engine
- CI on macOS, release workflow, Dependabot
