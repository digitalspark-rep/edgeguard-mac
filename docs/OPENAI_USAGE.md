# How EdgeGuard uses the OpenAI API

## Purpose

EdgeGuard is an AI firewall. The model is its decision step: for one redacted connection record it returns whether to allow, block or ask, how confident it is, and a plain-language reason. Deterministic code then checks that recommendation against the user's policy before anything is enforced.

## Integration

- Endpoint: `POST https://api.openai.com/v1/responses`
- Output: JSON with `severity`, `action`, `confidence`, `title`, `explanation`
- Storage: `store: false`
- Model: set with `OPENAI_MODEL`, so cost and quality can be tuned without code changes
- Code: [`OpenAIExplainer.swift`](../Sources/EdgeGuardCore/OpenAIExplainer.swift) and [`FirewallEngine.swift`](../Sources/EdgeGuardCore/FirewallEngine.swift)

## Request volume

The local filter sends only unusual flows. Repeated flows hit existing block rules or the verdict cache without a model call, and a daily request budget caps usage. Planning assumptions, to be replaced by measurements once the NetworkExtension ships:

| Assumption | Value |
|---|---|
| Tokens per request (input plus output) | about 420 |
| Flagged flows per device per day | 20 |
| Devices in the first pilot | 25 |
| Requests per month | about 15,000 |
| Tokens per month | about 6.3 million |

## Planned uses of credits

1. Build an evaluation set of labeled flows and measure false positives and false negatives across models, to decide when `auto` mode is safe to recommend.
2. Pilot with 25 Macs in small remote teams.
3. Tune prompts to keep tokens per request low.

## Safety

No payloads or personal data are sent. The model cannot act directly. See [AUTONOMY.md](AUTONOMY.md) and [PRIVACY.md](PRIVACY.md).
