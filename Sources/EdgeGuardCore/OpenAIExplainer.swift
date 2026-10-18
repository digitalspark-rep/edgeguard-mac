import Foundation

public enum ExplainerError: Error {
    case badStatus(Int)
    case emptyOutput
    case budgetExceeded
}

/// Judges a redacted flow and explains the decision using the OpenAI Responses API.
public struct OpenAIExplainer: Sendable, Explaining {
    public let apiKey: String
    public let model: String
    public let endpoint: URL

    public init(apiKey: String, model: String,
                endpoint: URL = URL(string: "https://api.openai.com/v1/responses")!) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
    }

    static let instructions = """
    You are the decision engine of a macOS firewall. You receive metadata about one outbound \
    connection: process name, remote host, port, protocol and bytes sent. Decide what the firewall \
    should do and explain it to a non-specialist in two sentences. Reply with a JSON object with \
    the keys "severity" (info, low, medium or high), "action" (allow, block or ask), \
    "confidence" (a number from 0 to 1) and "title" and "explanation". \
    Use "ask" when the metadata is not enough to decide. Never guess beyond the metadata and \
    lower your confidence when the evidence is weak.
    """

    public func requestBody(for event: FlowEvent) throws -> Data {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        let flowJSON = String(decoding: try enc.encode(event), as: UTF8.self)
        let body: [String: Any] = [
            "model": model,
            "instructions": Self.instructions,
            "input": flowJSON,
            "text": ["format": ["type": "json_object"]],
            "store": false
        ]
        return try JSONSerialization.data(withJSONObject: body)
    }

    public func explain(_ event: FlowEvent) async throws -> Verdict {
        try await explain(event, session: .shared)
    }

    public func explain(_ event: FlowEvent, session: URLSession) async throws -> Verdict {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try requestBody(for: event)

        let (data, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ExplainerError.badStatus(http.statusCode)
        }
        return try Self.parse(data)
    }

    struct Envelope: Decodable {
        struct Item: Decodable {
            struct Part: Decodable { let type: String; let text: String? }
            let content: [Part]?
        }
        let output: [Item]
    }

    static func parse(_ data: Data) throws -> Verdict {
        let env = try JSONDecoder().decode(Envelope.self, from: data)
        let text = env.output
            .flatMap { $0.content ?? [] }
            .filter { $0.type == "output_text" }
            .compactMap { $0.text }
            .joined()
        guard !text.isEmpty else { throw ExplainerError.emptyOutput }
        return try JSONDecoder().decode(Verdict.self, from: Data(text.utf8))
    }
}
