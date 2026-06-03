enum TransactionDirection: String, Codable, CaseIterable, Sendable {
    case income  = "income"
    case expense = "expense"

    var displayName: String {
        switch self {
        case .income:  "Доход"
        case .expense: "Расход"
        }
    }
}
