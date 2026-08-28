import Foundation

struct BankSMSResult {
    let amount: Decimal
    let direction: TransactionDirection
    let description: String
    let bank: String
}

// Парсит тексты SMS/push от Тинькофф и Сбербанка
struct BankSMSParser {

    // MARK: - Public

    static func parse(_ text: String) -> BankSMSResult? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }

        if let r = parseTinkoff(t) { return r }
        if let r = parseSber(t)    { return r }
        return nil
    }

    // MARK: - Тинькофф

    private static func parseTinkoff(_ text: String) -> BankSMSResult? {
        let lower = text.lowercased()
        guard lower.contains("тинькофф") || lower.contains("tinkoff") else { return nil }

        // Тинькофф. Оплата 500.00 RUB. МАГАЗИН. Баланс: ...
        // Тинькофф: вы списали 500 р в МАГАЗИН
        // Тинькофф: Перевод 500 р. на карту
        // Tinkoff: покупка 1 500.00 RUB

        let expenseKeywords = ["оплата", "списан", "покупка", "расход", "оплачен", "перевод с", "снятие"]
        let incomeKeywords  = ["зачислен", "пополнен", "поступил", "получен", "перевод от", "возврат"]

        let direction = detectDirection(lower, expense: expenseKeywords, income: incomeKeywords)
        guard let amount = extractAmount(text) else { return nil }

        let merchant = extractMerchantTinkoff(text)
        let desc = merchant ?? (direction == .expense ? "Списание Тинькофф" : "Пополнение Тинькофф")

        return BankSMSResult(amount: amount, direction: direction, description: desc, bank: "Тинькофф")
    }

    private static func extractMerchantTinkoff(_ text: String) -> String? {
        // Pattern: "RUB. MERCHANT. " or "RUB в MERCHANT" or "в МАГАЗИН"
        let patterns = [
            #"RUB[.:]?\s+([A-ZА-ЯЁ][A-ZА-ЯЁ\s\d\-]{2,40?})\."#,
            #"(?:списали|оплата)\s+[\d\s.,]+\s+(?:рублей?|руб\.?|RUB|₽)\s+(?:в|на)\s+([^\.\n,]{2,40})"#,
            #"покупка\s+[\d\s.,]+\s+RUB\s+([A-ZА-ЯЁ][^\.\n,]{2,40})"#
        ]
        for pattern in patterns {
            if let m = text.firstMatch(of: try! Regex(pattern, as: (Substring, Substring).self)) {
                let merchant = String(m.1).trimmingCharacters(in: .whitespacesAndNewlines)
                if !merchant.isEmpty { return merchant }
            }
        }
        return nil
    }

    // MARK: - Сбербанк

    private static func parseSber(_ text: String) -> BankSMSResult? {
        let lower = text.lowercased()
        guard lower.contains("сбер") || lower.contains("sber") else { return nil }

        // SBERBANK: Оплата 500р. МАГАЗИН.
        // Сбер: Списание 1500.50р.
        // СберБанк: зачисление 10000р

        let expenseKeywords = ["оплата", "списан", "покупка", "расход", "перевод с", "снятие", "payment"]
        let incomeKeywords  = ["зачислен", "пополнен", "поступил", "получен", "перевод от", "возврат", "deposit"]

        let direction = detectDirection(lower, expense: expenseKeywords, income: incomeKeywords)
        guard let amount = extractAmount(text) else { return nil }

        let merchant = extractMerchantSber(text)
        let desc = merchant ?? (direction == .expense ? "Списание Сбер" : "Пополнение Сбер")

        return BankSMSResult(amount: amount, direction: direction, description: desc, bank: "Сбербанк")
    }

    private static func extractMerchantSber(_ text: String) -> String? {
        let patterns = [
            #"(?:оплата|покупка)\s+[\d\s.,]+\s*(?:рублей?|руб\.?|RUB|₽|р\.?)\s+([^\.\n,]{2,40})\."#,
            #"(?:магазин|в)\s+([A-ZА-ЯЁ][^\.\n,]{2,30})"#
        ]
        for pattern in patterns {
            if let m = text.firstMatch(of: try! Regex(pattern, as: (Substring, Substring).self)) {
                let merchant = String(m.1).trimmingCharacters(in: .whitespacesAndNewlines)
                if !merchant.isEmpty { return merchant }
            }
        }
        return nil
    }

    // MARK: - Helpers

    private static func detectDirection(_ lower: String, expense: [String], income: [String]) -> TransactionDirection {
        if income.contains(where: { lower.contains($0) }) { return .income }
        return .expense
    }

    static func extractAmount(_ text: String) -> Decimal? {
        // Matches: 1 500.00, 1500,50, 500р, 500 RUB, 500₽
        let pattern = #"(\d[\d\s]*(?:[.,]\d{1,2})?)\s*(?:рублей?|руб\.?|RUB|₽|р\.?)"#
        if let m = text.firstMatch(of: try! Regex(pattern, as: (Substring, Substring).self)) {
            let raw = String(m.1)
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ",", with: ".")
            if let value = Decimal(string: raw), value > 0 { return value }
        }
        return nil
    }
}
