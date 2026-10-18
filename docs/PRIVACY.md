# Privacy and data handling

## What EdgeGuard sends to the OpenAI API

Only flows that local rules flag as unusual, and only these fields:

| Field | Example | Notes |
|---|---|---|
| `process` | `node` | Executable name only. Folder paths are removed |
| `remoteHost` | `45.83.64.12` | Private network hosts are replaced with `private-network-host` |
| `remotePort` | `4444` | |
| `proto` | `tcp` | |
| `bytesOut` | `18240` | A count, not content |
| `firstSeen` | `2026-10-18T12:02:00Z` | |

## What is never sent

Packet contents, URLs and paths, file names, user names, device names, IP addresses of the user's own network, and traffic judged routine.

## Where decisions and logs live

Block rules and the audit log stay on the device. The model returns a verdict. It does not receive rules, logs or any history.

## OpenAI settings

- Requests set `store: false`.
- The API key belongs to the user or team. Teams on paid plans can request zero data retention from OpenAI.
- See OpenAI's business data policies: https://openai.com/business-data/

## Verifying

`swift run edgeguard-cli < examples/suspicious-flow.json` without an API key prints the exact payload that would be sent. Tests in `Tests/EdgeGuardCoreTests` cover redaction.
