# Security policy

EdgeGuard is a security tool, so we take reports seriously.

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's private vulnerability reporting (Security tab → "Report a vulnerability") or email euro@twojstartup.pl with the subject "EdgeGuard security".

Include the affected version or commit, steps to reproduce and the impact you see. We aim to reply within 5 working days.

## Scope

- Leaks of personal data to external services (see [docs/PRIVACY.md](docs/PRIVACY.md))
- Bypasses of the redaction or local filtering
- Unsafe handling of the OpenAI API key
- Ways to make the firewall block something it should not, or skip a guardrail (see [docs/AUTONOMY.md](docs/AUTONOMY.md))

## Handling secrets

Never commit API keys. EdgeGuard reads the key from the `OPENAI_API_KEY` environment variable or the macOS Keychain (planned).
