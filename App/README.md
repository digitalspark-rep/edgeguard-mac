# App (in development)

The menu bar app preview lives in `Sources/EdgeGuardMenuBar` (run with `swift run EdgeGuardMenuBar`). It feeds demo flows through the real engine. Planned Xcode targets for a signed app:

- **EdgeGuardApp**: SwiftUI menu bar app that shows decisions, asks for approval, and offers undo and the audit log.
- **EdgeGuardFilter**: a `NEFilterDataProvider` system extension that sends outbound flows to `FirewallEngine` and enforces its active block rules.

The NetworkExtension needs the `com.apple.developer.networking.networkextension` entitlement and an Apple Developer account. Until it lands, `edgeguard-cli` feeds recorded flows into the same core library.
