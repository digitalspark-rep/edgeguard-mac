# EdgeGuard Mac

**An open-source AI firewall for macOS that handles routine threats on its own.**
EdgeGuard watches outbound network connections, decides which ones are dangerous, and blocks confirmed threats automatically within guardrails you set. Every action is logged and reversible.

Built by **DigitalSpark** · Website: [rootop.net](https://rootop.net) · License: MIT

[![CI](https://github.com/digitalspark-rep/edgeguard-mac/actions/workflows/ci.yml/badge.svg)](https://github.com/digitalspark-rep/edgeguard-mac/actions/workflows/ci.yml)
![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform: macOS 13+](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey.svg)

> **Status: early development.** The decision engine, guardrails, cost controls, persistence, evaluation harness and OpenAI integration work today and are tested. A menu bar app preview runs demo flows. The NetworkExtension that enforces blocks on real traffic is in progress. See the [roadmap](docs/ROADMAP.md).

## What it automates

| Task | How |
|---|---|
| Triage | Local rules clear routine traffic. Nothing is sent anywhere for it |
| Decisions | An AI model returns `allow`, `block` or `ask` with a confidence score and a plain-language reason |
| Blocking | In `auto` mode, high-severity threats above your confidence threshold are blocked without waiting for you |
| Cleanup | Automatic block rules expire on their own (one hour by default) |
| Reporting | Every decision is written to an audit log with its evidence |
| Cost control | A verdict cache and a daily request budget keep AI usage predictable |

## You choose the autonomy

| Mode | Behavior |
|---|---|
| `monitor` | Observes and explains. Never blocks |
| `suggest` (default) | Recommends blocks and waits for your approval |
| `auto` | Blocks high-confidence, high-severity threats by itself. Everything else still asks |

Guardrails (protected system processes, fail-safe on AI errors, expiry, undo) are described in [docs/AUTONOMY.md](docs/AUTONOMY.md).

## How it works

```
Flow ─► Redactor ─► LocalHeuristics ─► OpenAI API ─► Policy guardrails ─► Decision
        strips        routine? stop      allow/block/ask   mode, confidence,    allowed, needs approval,
        user data     here               + confidence      protected list       or blocked automatically
```

Details: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/PRIVACY.md](docs/PRIVACY.md).

## Try it

Requires macOS 13+ and Swift 5.9+.

```bash
git clone https://github.com/digitalspark-rep/edgeguard-mac.git
cd edgeguard-mac
swift test

# Local triage only (no network, no key needed)
swift run edgeguard-cli < examples/suspicious-flow.json

# Let the AI decide, in a chosen mode
export OPENAI_API_KEY=sk-...
export OPENAI_MODEL=<model name from your OpenAI account>
EDGEGUARD_MODE=auto swift run edgeguard-cli < examples/suspicious-flow.json
```

## Measure it

```bash
swift run edgeguard-eval examples/eval/labeled-flows.json
```

Runs 24 labeled flows through the engine and reports auto-block precision and recall. Without a key it runs the rule-based baseline, with a key it runs the AI model. See [docs/EVALUATION.md](docs/EVALUATION.md).

## Menu bar preview

```bash
swift run EdgeGuardMenuBar
```

Shows decisions for demo flows, with approve and undo, using the real engine.

## Project layout

| Path | Purpose |
|---|---|
| `Sources/EdgeGuardCore` | Flow model, redaction, triage, OpenAI client, policy, firewall engine, cost controls, persistence, evaluation |
| `Sources/edgeguard-cli`, `Sources/edgeguard-eval` | Command-line tools: run one flow, evaluate a labeled set |
| `Sources/EdgeGuardMenuBar` | Menu bar app preview (demo flows) |
| `Tests/` | Unit tests for redaction, parsing and every guardrail (CI on macOS) |
| `App/` | Menu bar app and NetworkExtension (in development) |
| `docs/` | Architecture, autonomy, threat model, evaluation, privacy, roadmap, OpenAI usage |
| `site/` | Source of the website at rootop.net |

## OpenAI usage

EdgeGuard uses the OpenAI Responses API with `store: false`, only for flows that local rules flag, and only with redacted metadata. See [docs/OPENAI_USAGE.md](docs/OPENAI_USAGE.md).

## Contributing and security

Pull requests are welcome, see [CONTRIBUTING.md](CONTRIBUTING.md). To report a vulnerability, follow [SECURITY.md](SECURITY.md).

## About

DigitalSpark is an early-stage startup incubated by Fundacja Rozwoju Przedsiębiorczości „Twój StartUp", ul. Żurawia 6/12, lok. 766, 00-503 Warszawa, Poland (KRS 0000442857). Contact: euro@twojstartup.pl.
