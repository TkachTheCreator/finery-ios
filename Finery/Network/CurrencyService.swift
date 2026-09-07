import Foundation

// MARK: - Currency

enum Currency: String, CaseIterable, Codable, Sendable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
    case byn = "BYN"
    case cny = "CNY"

    var symbol: String {
        switch self {
        case .rub: "₽"
        case .usd: "$"
        case .eur: "€"
        case .byn: "Br"
        case .cny: "¥"
        }
    }

    var displayName: String {
        switch self {
        case .rub: "₽ Рубль"
        case .usd: "$ Доллар"
        case .eur: "€ Евро"
        case .byn: "Br Бел. рубль"
        case .cny: "¥ Юань"
        }
    }
}

// MARK: - Currency Service (ЦБ РФ XML API)

@Observable
@MainActor
final class CurrencyService {
    static let shared = CurrencyService()
    private init() {}

    /// Exchange rates relative to RUB: 1 USD → rate RUB
    private(set) var rates: [String: Decimal] = [:]
    private(set) var isLoading = false
    private var lastFetch: Date?

    // Fetches today's rates from ЦБ РФ (cached for the day)
    func fetchIfNeeded() async {
        guard !isLoading else { return }
        if let last = lastFetch, Calendar.current.isDateInToday(last) { return }
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "https://www.cbr.ru/scripts/XML_daily.asp") else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }

        let parsed = XMLParserWrapper(data: data).parse()
        if !parsed.isEmpty {
            rates = parsed
            lastFetch = Date()
        }
    }

    /// Convert `amount` in `currency` to RUB.
    /// Returns nil if rate is unavailable (treat as 1:1 = stay in RUB).
    func toRub(_ amount: Decimal, currency: Currency) -> Decimal {
        guard currency != .rub else { return amount }
        guard let rate = rates[currency.rawValue] else { return amount }
        return amount * rate
    }

    /// Human-readable rate string, e.g. "1 $ = 92.35 ₽"
    func rateLabel(for currency: Currency) -> String {
        guard currency != .rub, let rate = rates[currency.rawValue] else { return "" }
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.maximumFractionDigits = 2
        let rateStr = fmt.string(from: rate as NSDecimalNumber) ?? ""
        return "1 \(currency.symbol) = \(rateStr) ₽"
    }
}

// MARK: - ЦБ РФ XML parser

private final class XMLParserWrapper: NSObject, XMLParserDelegate {
    private let data: Data
    private var currentCharCode = ""
    private var currentNominal  = 1
    private var currentValue    = ""
    private var inValute        = false
    private var inCharCode      = false
    private var inNominal       = false
    private var inValue         = false
    private var charContent     = ""
    var result: [String: Decimal] = [:]

    init(data: Data) { self.data = data }

    func parse() -> [String: Decimal] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return result
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        charContent = ""
        switch elementName {
        case "Valute": inValute = true
        case "CharCode": inCharCode = inValute
        case "Nominal":  inNominal  = inValute
        case "Value":    inValue    = inValute
        default: break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        charContent += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "CharCode": if inCharCode { currentCharCode = charContent.trimmingCharacters(in: .whitespaces) }
        case "Nominal":  if inNominal  { currentNominal  = Int(charContent.trimmingCharacters(in: .whitespaces)) ?? 1 }
        case "Value":
            if inValue {
                // CBR uses comma as decimal separator
                currentValue = charContent
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: ",", with: ".")
            }
        case "Valute":
            if let dec = Decimal(string: currentValue), !currentCharCode.isEmpty {
                // rate per 1 unit
                result[currentCharCode] = dec / Decimal(max(currentNominal, 1))
            }
            currentCharCode = ""; currentNominal = 1; currentValue = ""; inValute = false
        default: break
        }
        charContent = ""
        inCharCode = false; inNominal = false; inValue = false
    }
}
