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
        Не используй эмодзи и специальные символы — только обычный текст.
        """

        let history = messages.dropLast().map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": history + [["role": "user", "content": text]]
        ]

        let apiKey = Constants.anthropicAPIKey
        guard !apiKey.isEmpty else {
            messages.append(AIMessage(role: "assistant", content: localAnswer(for: text, income: income, expense: expense, tax: tax, mode: mode)))
            return
        }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch status {
            case 200:
                if let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let content = json["content"] as? [[String: Any]],
                   let reply   = content.first?["text"] as? String {
                    messages.append(AIMessage(role: "assistant", content: reply))
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? "—"
                    messages.append(AIMessage(role: "assistant", content: "Неожиданный ответ API: \(raw.prefix(200))"))
                }
            case 401:
                messages.append(AIMessage(role: "assistant", content: "Неверный API-ключ. Проверьте ключ в настройках сборки (ANTHROPIC_API_KEY)."))
            case 429:
                messages.append(AIMessage(role: "assistant", content: "Слишком много запросов. Подождите немного и повторите."))
            default:
                let raw = String(data: data, encoding: .utf8) ?? "—"
                messages.append(AIMessage(role: "assistant", content: "Ошибка сервера (\(status)): \(raw.prefix(150))"))
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

    // MARK: - Local fallback answers (no API key required)

    private func localAnswer(for text: String, income: Int, expense: Int, tax: Int, mode: String) -> String {
        let q = text.lowercased()

        if q.contains("снизить налог") || q.contains("оптимизир") || q.contains("уменьшить налог") {
            return """
            Способы снизить налог:

            • НПД: применяйте правильный тип клиента — физлицо (4%) или юрлицо (6%). Убедитесь, что ставка выбрана верно при каждой операции.
            • УСН 6%: уменьшайте налог на сумму страховых взносов (до 50% для ИП с сотрудниками, до 100% без них).
            • УСН 15%: фиксируйте все расходы — аренда, ПО, оборудование, связь. Каждый рубль расходов снижает базу.
            • Ваш текущий режим: \(mode). Налог за период: \(tax) ₽.
            """
        }

        if q.contains("расход") || q.contains("анализ") || q.contains("трат") {
            let margin = income > 0 ? Int(Double(income - expense - tax) / Double(income) * 100) : 0
            return """
            Анализ за текущий период:

            • Доход: \(income) ₽
            • Расходы: \(expense) ₽
            • Налог: \(tax) ₽
            • Чистая прибыль: \(income - expense - tax) ₽
            • Маржа: \(margin)%

            \(margin < 40 ? "Маржа ниже 40% — для фрилансеров норма 60–80%. Сократите постоянные расходы." : "Маржа в норме. Продолжайте контролировать расходы.")
            """
        }

        if q.contains("когда") && (q.contains("платить") || q.contains("налог") || q.contains("дедлайн") || q.contains("срок")) {
            let deadline: String
            if mode.lowercased().contains("ндп") || mode.lowercased().contains("npd") || mode.contains("НПД") {
                deadline = "28-го числа каждого месяца следующего за отчётным"
            } else {
                deadline = "28 апреля, 28 июля, 28 октября, 28 января (авансовые платежи по УСН)"
            }
            return """
            Дедлайн для режима \(mode):

            Платить нужно \(deadline).

            • Текущий налог к уплате: \(tax) ₽
            • Настройте напоминание в Настройках — за сколько дней предупреждать.

            Просрочка — пени 1/300 ставки ЦБ за каждый день. Не откладывайте.
            """
        }

        if q.contains("доход") || q.contains("заработок") || q.contains("совет") {
            return """
            Советы по росту дохода:

            • Диверсифицируйте источники — не более 70% дохода из одного канала.
            • Ваш доход за период: \(income) ₽. Расходы: \(expense) ₽.
            • Повышайте ставку раз в 6 месяцев — инфляция в России ~8% в год.
            • Выставляйте счета вовремя, используйте раздел «Счета» в приложении.
            • Для НПД: лимит 2 400 000 ₽/год. При приближении — переходите на УСН.
            """
        }

        return "Задайте вопрос о налогах, расходах или доходах — дам конкретный совет по вашим данным."
    }
}
