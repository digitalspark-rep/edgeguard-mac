# Threat model

EdgeGuard makes security decisions with an AI model, so the model and the code around it are part of the attack surface.

## Assets

- The user's network connectivity (a wrong block breaks work)
- The user's privacy (what leaves the Mac)
- The OpenAI API key and its budget

## Threats and mitigations

| Threat | Mitigation | Where |
|---|---|---|
| **Prompt injection.** A hostile process or host name contains instructions aimed at the model | Fields are clipped to a fixed length and control characters are removed. Input is a JSON record, not free text. Output must match a strict JSON shape. Policy code, not the model, decides what happens | `Redactor.clip`, `OpenAIExplainer`, `FirewallEngine` |
| **The model is wrong** (false block or missed threat) | Automatic blocks need high severity and a confidence threshold. Blocks expire and can be undone. Evaluation harness measures error rates before `auto` is recommended | `Policy`, `Evaluator` |
| **The model or network is unavailable** | The engine asks the user and blocks nothing | `FirewallEngine.handle` |
| **Blocking core macOS services** | Protected process list is never blocked automatically | `Policy.protectedProcesses` |
| **Personal data leaves the device** | Metadata only, user paths removed, private hosts masked, routine traffic never sent, `store: false` | `Redactor`, `LocalHeuristics` |
| **Cost abuse or a flood of flows** | Verdict cache and a daily request budget. When the budget is spent the engine asks instead | `CachingExplainer`, `BudgetedExplainer` |
| **API key leaks** | Key comes from the environment. Never committed. Keychain storage is planned | `.gitignore`, roadmap |
| **Tampering with saved rules or logs** | Planned: file permissions and integrity checks | roadmap |

## Out of scope today

Attackers with root on the Mac, attacks that look identical to normal traffic at the metadata level, and enforcement bypasses in the NetworkExtension, which does not exist yet.
