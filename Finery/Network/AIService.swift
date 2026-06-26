import Foundation
import Observation

// MARK: - AIMessage

struct AIMessage: Identifiable {
    let id = UUID()
    let role: String      // "user" | "assistant"
    let content: String
}

// MARK: - AIService

@Observable
@MainActor
final class AIService {
    static let shared = AIService()
    private init() {}

    var messages: [AIMessage] = []
    var isLoading = false

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    // MARK: - Send

    func sendMessage(_ text: String) async {
        messages.append(AIMessage(role: "user", content: text))
        isLoading = true
        defer { isLoading = false }

        let svc    = SharedDataService.shared
        let income  = NSDecimalNumber(decimal: svc.totalIncome ).intValue
        let expense = NSDecimalNumber(decimal: svc.totalExpense).intValue
        let tax     = NSDecimalNumber(decimal: svc.taxAmount   ).intValue
        let mode    = svc.taxMode.displayName

        let systemPrompt = """
        Ты финансовый советник приложения Finery для самозанятых и фрилансеров России.
        Данные пользователя за текущий месяц:
        - Доход: \(income) ₽
        - Расход: \(expense) ₽
        - Налог: \(tax) ₽
        - Налоговый режим: \(mode)
        Давай конкретные советы по экономии налогов и финансовому планированию.
        Отвечай кратко на русском языке, используй конкретные цифры.
        """

        let history = messages.dropLast().map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 500,
            "system": systemPrompt,
            "messages": history + [["role": "user", "content": text]]
        ]

        let apiKey = Constants.anthropicAPIKey
        guard !apiKey.isEmpty else {
            messages.append(AIMessage(
                role: "assistant",
                content: "⚠️ Добавьте Anthropic API ключ в Constants.swift или Info.plist (ANTHROPIC_API_KEY)"
            ))
            return
        }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let reply   = content.first?["text"] as? String {
                messages.append(AIMessage(role: "assistant", content: reply))
            } else {
                let raw = String(data: data, encoding: .utf8) ?? "—"
                messages.append(AIMessage(role: "assistant", content: "Ошибка API: \(raw.prefix(200))"))
            }
        } catch {
            messages.append(AIMessage(
                role: "assistant",
                content: "Не удалось получить ответ. Проверьте подключение к интернету."
            ))
        }
    }

    func clearHistory() {
        messages = []
    }
}
