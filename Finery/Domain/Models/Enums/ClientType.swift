import Foundation

enum ClientType: String, Codable, CaseIterable, Sendable {
    case individual = "Физлицо"
    case legal      = "Юрлицо/ИП"

    var displayName: String { rawValue }

    var npdRate: Decimal {
        switch self {
        case .individual: 0.04
        case .legal:      0.06
        }
    }
}
