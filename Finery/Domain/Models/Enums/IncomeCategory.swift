enum IncomeCategory: String, Codable, CaseIterable, Sendable {
    case boosty      = "Boosty/Подписки"
    case donations   = "Донаты"
    case advertising = "Реклама"
    case freelance   = "Фриланс"
    case platforms   = "Платформы"
    case education   = "Курсы/Обучение"
    case other       = "Другое"

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .boosty:      "star"
        case .donations:   "heart"
        case .advertising: "megaphone"
        case .freelance:   "briefcase"
        case .platforms:   "play.rectangle"
        case .education:   "graduationcap"
        case .other:       "ellipsis.circle"
        }
    }
}
