# Evaluation

Before recommending `auto` mode, we measure how often a model blocks the wrong thing.

## Method

`edgeguard-eval` runs every flow in a labeled file through a fresh `FirewallEngine` in `auto` mode and counts outcomes:

| | Blocked automatically | Asked the user | Allowed or observed |
|---|---|---|---|
| **Malicious** | true positive | asked | missed |
| **Benign** | **false positive** | asked | true negative |

It reports auto-block precision (how many automatic blocks were right) and recall (how many malicious flows were blocked automatically).

## Dataset

`examples/eval/labeled-flows.json`: 24 synthetic flows, 12 malicious and 12 benign. Hard cases are included on purpose, such as a benign script on an unusual port and a malicious download over port 80. The set is small and invented. It checks the harness and shows how a model differs from the rule-based baseline. It does not measure real-world accuracy.

## Running

```bash
# Rule-based baseline (no key)
swift run edgeguard-eval examples/eval/labeled-flows.json

# AI model
export OPENAI_API_KEY=sk-...
export OPENAI_MODEL=<model name>
swift run edgeguard-eval examples/eval/labeled-flows.json
```

## Next

- Replace synthetic flows with flows recorded in the pilot, labeled by hand
- Compare several models on cost per decision and error rate
- Track results per release in this file
