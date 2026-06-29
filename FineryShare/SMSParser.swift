import Foundation

struct ParsedTransaction {
    var amount: Double
    var direction: String // "income" | "expense"
    var description: String
    var category: String
    var bankName: String
    var confidence: Double // 0-1
}

struct SMSParser {

    static func parse(_ text: String) -> ParsedTransaction {
        let lowered = text.lowercased()
        let bank      = detectBank(lowered)
        let direction = detectDirection(lowered)
        let amount    = extractAmount(text)
        let category  = detectCategory(lowered)
        let desc      = generateDescription(text, bank: bank, direction: direction)

        return ParsedTransaction(
            amount: amount,
            direction: direction,
            description: desc,
            category: category,
            bankName: bank,
            confidence: amount > 0 ? 0.9 : 0.3
        )
    }

    // MARK: - Банк

    private static func detectBank(_ text: String) -> String {
        let banks: [(keywords: [String], name: String)] = [
            (["сбербанк", "sberbank", "сбер"],       "Сбербанк"),
            (["тинькофф", "tinkoff", "т-банк"],      "Тинькофф"),
            (["альфа", "alfa", "alpha"],              "Альфа-Банк"),
            (["втб", "vtb"],                          "ВТБ"),
            (["райффайзен", "raiffeisen"],            "Райффайзен"),
            (["озон", "ozon"],                        "Озон Банк"),
            (["яндекс", "yandex"],                    "Яндекс Пэй"),
            (["qiwi", "киви"],                        "QIWI"),
            (["юмани", "yoomoney"],                   "ЮMoney"),
            (["газпром", "gazprom"],                  "Газпромбанк"),
            (["росбанк", "rosbank"],                  "Росбанк"),
            (["открытие", "otkritie"],                "Открытие"),
        ]
        for bank in banks {
            if bank.keywords.contains(where: { text.contains($0) }) { return bank.name }
        }
        return "Банк"
    }

    // MARK: - Направление

    private static func detectDirection(_ text: String) -> String {
        let incomeKeywords = [
            "зачислено", "поступление", "пополнение", "получено",
            "доход", "зарплата", "перевод получен", "credited",
            "income", "deposit", "кредит", "credit", "возврат"
        ]
        let expenseKeywords = [
            "списано", "списание", "оплата", "покупка", "перевод",
            "снятие", "расход", "потрачено", "оплачено", "withdrawn",
            "payment", "purchase", "дебет", "debit", "израсходовано"
        ]
        for kw in incomeKeywords  { if text.contains(kw) { return "income"  } }
        for kw in expenseKeywords { if text.contains(kw) { return "expense" } }
        return "expense"
    }

    // MARK: - Сумма

    static func extractAmount(_ text: String) -> Double {
        let patterns = [
            #"(\d[\d\s]*[\d])[\s]*(?:руб|₽|rub|р\.?)"#,
            #"(?:руб|₽|rub|р\.?)[\s]*(\d[\d\s]*[\d])"#,
            #"на сумму[\s]*(\d[\d\s,\.]*)"#,
            #"(\d+[\d\s,\.]*\d)[\s]*(?:руб|₽)"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern,
                                                       options: .caseInsensitive)
            else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               let numRange = Range(match.range(at: 1), in: text) {
                let numStr = String(text[numRange])
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: ",", with: ".")
                if let amount = Double(numStr) { return amount }
            }
        }
        return 0
    }

    // MARK: - Категория

    private static func detectCategory(_ text: String) -> String {
        let categories: [(keywords: [String], category: String)] = [
            (["кафе", "ресторан", "еда", "food", "cafe", "restaurant",
              "макдональдс", "kfc", "burger", "пицца", "суши"],       "Еда"),
            (["такси", "uber", "яндекс.такси", "bolt", "транспорт",
              "метро", "автобус", "проезд"],                           "Транспорт"),
            (["супермаркет", "пятёрочка", "магнит", "лента", "ашан",
              "перекрёсток", "продукты", "market"],                    "Продукты"),
            (["аптека", "pharmacy", "лекарств", "здоровье"],           "Здоровье"),
            (["одежда", "zara", "h&m", "wildberries", "ozon",
              "lamoda", "обувь"],                                       "Одежда"),
            (["коммунальн", "жкх", "электричество", "газ", "вода",
              "интернет", "связь", "телефон"],                          "Коммуналка"),
            (["кино", "театр", "развлечен", "spotify", "netflix",
              "игр"],                                                   "Развлечения"),
            (["зарплат", "оклад", "аванс", "фриланс", "гонорар"],     "Зарплата"),
            (["перевод", "transfer", "p2p"],                           "Переводы"),
        ]
        for cat in categories {
            if cat.keywords.contains(where: { text.contains($0) }) { return cat.category }
        }
        return "Другое"
    }

    // MARK: - Описание

    private static func generateDescription(_ text: String,
                                            bank: String,
                                            direction: String) -> String {
        let action = direction == "income" ? "Поступление" : "Списание"
        if let range = text.range(of: #"(?:в|от|для)\s+([А-ЯA-Z][^\n,\.]{2,30})"#,
                                  options: .regularExpression) {
            let merchant = String(text[range])
                .replacingOccurrences(of: #"^(в|от|для)\s+"#,
                                      with: "",
                                      options: .regularExpression)
            return "\(action): \(merchant)"
        }
        return "\(action) через \(bank)"
    }
}
