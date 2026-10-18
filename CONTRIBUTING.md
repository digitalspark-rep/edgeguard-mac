# Contributing

Thanks for helping. Good first areas: triage rules, guardrail tests, an evaluation set of labeled flows, docs, and the menu bar UI.

1. Open an issue to discuss larger changes.
2. Fork, create a branch, and make your change.
3. Run `swift test`. CI runs the same on macOS.
4. Keep the privacy rule: nothing that identifies a person or contains payload data may be sent to an external API. Add a test when you touch `Redactor`.
5. Do not weaken a guardrail in `FirewallEngine` without a test that explains why.
6. Open a pull request that explains what changed and why.

By contributing you agree that your work is released under the MIT license.
