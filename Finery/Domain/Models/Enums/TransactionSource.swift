enum TransactionSource: String, Codable, CaseIterable, Sendable {
    case boosty         = "Boosty"
    case donationAlerts = "DonationAlerts"
    case bank           = "Банк"
    case manual         = "Вручную"
    case voice          = "Голос"

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .boosty:         "star"
        case .donationAlerts: "heart"
        case .bank:           "building.columns"
        case .manual:         "pencil"
        case .voice:          "mic"
        }
    }
}
