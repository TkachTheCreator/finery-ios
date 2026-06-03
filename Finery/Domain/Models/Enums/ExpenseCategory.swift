enum ExpenseCategory: String, Codable, CaseIterable, Sendable {
    case tools         = "Инструменты"
    case advertising   = "Своя реклама"
    case equipment     = "Оборудование"
    case team          = "Команда"
    case food          = "Еда"
    case transport     = "Транспорт"
    case communication = "Связь"
    case other         = "Другое"

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .tools:         "wrench.and.screwdriver"
        case .advertising:   "megaphone"
        case .equipment:     "camera"
        case .team:          "person.2"
        case .food:          "fork.knife"
        case .transport:     "car"
        case .communication: "phone"
        case .other:         "ellipsis.circle"
        }
    }
}
