import Foundation

struct AIService {
    static let shared = AIService()
    private init() {}

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    struct ChatMessage: Codable, Identifiable {
        let id: UUID
        let role: String   // "user" or "assistant"
        let content: String

        init(id: UUID = UUID(), role: String, content: String) {
            self.id = id
            self.role = role
            self.content = content
        }
    }

    private struct RequestBody: Encodable {
        let model: String
        let maxTokens: Int
        let system: String
        let messages: [Msg]
        struct Msg: Encodable { let role: String; let content: String }
    }

    private struct ResponseBody: Decodable {
        let content: [Block]
        struct Block: Decodable { let text: String }
    }

    func send(messages: [ChatMessage], systemPrompt: String) async throws -> String {
        let apiKey = Constants.anthropicAPIKey
        guard !apiKey.isEmpty else {
            return "⚠️ Добавьте Anthropic API ключ в Constants.swift (поле anthropicAPIKey)"
        }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey,               forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",         forHTTPHeaderField: "anthropic-version")

        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        req.httpBody = try enc.encode(RequestBody(
            model: "claude-haiku-4-5-20251001",
            maxTokens: 1024,
            system: systemPrompt,
            messages: messages.map { RequestBody.Msg(role: $0.role, content: $0.content) }
        ))

        let (data, _) = try await URLSession.shared.data(for: req)
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return try dec.decode(ResponseBody.self, from: data).content.first?.text ?? "—"
    }
}
