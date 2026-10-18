import Foundation

/// Removes personal data from a flow before anything is sent to an external API.
public enum Redactor {
    public static func sanitize(_ event: FlowEvent) -> FlowEvent {
        var e = event
        // Keep only the executable name: "/Users/anna/dev/app/node" -> "node".
        e.process = clip((event.process as NSString).lastPathComponent, 64)
        e.remoteHost = isPrivateHost(event.remoteHost) ? "private-network-host" : clip(event.remoteHost, 253)
        e.proto = clip(event.proto, 8)
        return e
    }

    /// Drops control characters and limits length, so a hostile process or host name
    /// cannot smuggle long instructions or odd characters into the model input.
    static func clip(_ s: String, _ maxLength: Int) -> String {
        var out = String.UnicodeScalarView()
        for u in s.unicodeScalars where !CharacterSet.controlCharacters.contains(u) {
            if out.count >= maxLength { break }
            out.append(u)
        }
        return String(out)
    }

    public static func isPrivateHost(_ host: String) -> Bool {
        let parts = host.split(separator: ".").compactMap { Int($0) }
        if parts.count == 4 {
            if parts[0] == 10 || parts[0] == 127 { return true }
            if parts[0] == 192 && parts[1] == 168 { return true }
            if parts[0] == 172 && (16...31).contains(parts[1]) { return true }
            if parts[0] == 169 && parts[1] == 254 { return true }
        }
        return host.hasSuffix(".local") || host == "localhost" || host == "private-network-host"
    }
}
