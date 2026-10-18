# Evaluation set

`labeled-flows.json` holds 24 **synthetic** flows (12 malicious, 12 benign) with ground-truth labels. They are hand-written to cover easy cases and hard ones, such as a benign script on an unusual port and a malicious download over port 80. Hosts use documentation address ranges or invented names. This is a starting point for the harness, not a measurement of real-world accuracy.

Run it:

```bash
swift run edgeguard-eval examples/eval/labeled-flows.json
```

Without `OPENAI_API_KEY` it runs the rule-based baseline. With a key it runs the AI model, so you can compare both on the same flows.
