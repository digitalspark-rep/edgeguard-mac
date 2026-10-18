# Autonomy and guardrails

An autonomous firewall can do harm if it is wrong: blocking a legitimate connection can break work. EdgeGuard limits what it may do alone, and every limit below is enforced in `FirewallEngine` and covered by a test in `Tests/EdgeGuardCoreTests/FirewallEngineTests.swift`.

## Modes

| Mode | May observe | May recommend | May block alone |
|---|---|---|---|
| `monitor` | yes | no | no |
| `suggest` | yes | yes | no |
| `auto` | yes | yes | only within the guardrails |

## Guardrails for automatic blocks

An automatic block requires all of these:

1. Mode is `auto`.
2. The model's action is `block`.
3. Severity is `high`.
4. Confidence is at least `Policy.minConfidence` (default 0.9).
5. The process is not in `Policy.protectedProcesses` (core macOS services such as `launchd` and `mDNSResponder`).

If any condition fails, the user is asked.

## Fail-safe behavior

- If the daily request budget is spent, EdgeGuard asks the user and blocks nothing.
- If the OpenAI request fails or the answer is not valid JSON in the expected shape, EdgeGuard asks the user and blocks nothing.
- Routine traffic never reaches the model and is allowed.
- Private network hosts are never flagged.

## Reversibility and audit

- Automatic rules expire after `Policy.blockTTL` (default one hour).
- `FirewallEngine.undo(ruleID:)` removes a rule at any time.
- Every non-routine decision is appended to the audit log with the redacted flow, the verdict and the reason.

## Known limits

- The model sees metadata only, so some attacks look like normal traffic and some normal tools look suspicious. Confidence thresholds reduce, not remove, wrong calls.
- Enforcement on real traffic arrives with the NetworkExtension filter. Today the engine produces decisions and rules that the filter will apply.
- We plan an evaluation set of labeled flows to measure false-positive and false-negative rates before recommending `auto` mode (see the roadmap).
