# Roadmap

- [x] Core library: flow model, redaction, local triage
- [x] OpenAI client with structured allow, block or ask verdicts
- [x] Autonomy engine: modes, confidence threshold, protected processes, expiring rules, undo, audit log
- [x] Cost controls: verdict cache and daily request budget
- [x] Persistence of rules and audit log, policy files
- [x] Evaluation harness, synthetic labeled set, rule-based baseline
- [x] Command-line tools, unit tests for every guardrail, CI on macOS, release workflow
- [ ] NetworkExtension filter that enforces active block rules on real traffic
- [ ] Menu bar app: connect to live traffic, audit log view, persistence (a demo-flow preview exists)
- [ ] API key storage in the macOS Keychain
- [ ] Replace the synthetic evaluation set with real labeled pilot flows and compare models
- [ ] Move persistence from a JSON file to SQLite
- [ ] Shared team policies and an MDM deployment guide
- [ ] Signed and notarized release
