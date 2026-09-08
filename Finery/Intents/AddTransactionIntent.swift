import AppIntents
import Foundation

// MARK: - App Intent: "Добавить операцию в Finery"
// Доступен через приложение "Команды" и Control Center без Siri capability.
// Siri-фразы ("Hey Siri, добавь расход") — отложены до подключения Apple Developer Program.

struct AddTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Добавить операцию в Finery"
    static let description = IntentDescription(
        "Записывает доход или расход по тексту. Например: «расход 500 такси».",
        categoryName: "Финансы"
    )
    static let openAppWhenRun: Bool = false

    @Parameter(
        title: "Операция",
        description: "Например: расход 500 рублей обед",
        requestValueDialog: IntentDialog("Что добавить? Например: «расход 500 такси»")
    )
    var input: String

    func perform() async throws -> some ProvidesDialog {
        guard let amount = VoiceInputManager.parseAmount(from: input) else {
            return .result(dialog: "Не удалось распознать сумму. Введите, например: «расход 500 обед».")
        }

        let lower = input.lowercased()
        let expenseWords = ["расход", "потратил", "потратила", "заплатил", "заплатила", "купил", "купила"]
        let incomeWords  = ["доход", "получил", "получила", "заработал", "заработала", "поступление"]

        let direction: TransactionDirection
        if expenseWords.contains(where: { lower.contains($0) }) {
            direction = .expense
        } else if incomeWords.contains(where: { lower.contains($0) }) {
            direction = .income
        } else {
            direction = .expense
        }

        var cleaned = input
        for word in expenseWords + incomeWords {
            cleaned = cleaned.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
        }
        let amountWords = ["рублей", "рубля", "рубль", "руб", "₽"]
        for word in amountWords {
            cleaned = cleaned.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
        }
        let txDescription = cleaned
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty && Int($0) == nil }
            .joined(separator: " ")

        let finalDescription = txDescription.isEmpty
            ? (direction == .income ? "Доход" : "Расход")
            : txDescription

        let tx = Transaction(
            amount: amount,
            direction: direction,
            description: finalDescription,
            date: Date(),
            source: .voice,
            incomeCategory:  direction == .income  ? .other : nil,
            expenseCategory: direction == .expense ? .other : nil,
            clientType:      direction == .income  ? .individual : nil,
            clientId: nil,
            notes: nil
        )

        guard APIClient.shared.isAuthenticated else {
            return .result(dialog: "Сначала войдите в Finery.")
        }

        do {
            let synced = try await APIClient.shared.createTransaction(tx)
            await MainActor.run { SharedDataService.shared.appendTransaction(synced) }
            let dirStr = direction == .income ? "доход" : "расход"
            let amountInt = NSDecimalNumber(decimal: amount).intValue
            return .result(dialog: "Записал \(dirStr) \(amountInt) рублей\(txDescription.isEmpty ? "" : ": \(txDescription)").")
        } catch {
            return .result(dialog: "Не удалось сохранить. Проверьте интернет и повторите.")
        }
    }
}
