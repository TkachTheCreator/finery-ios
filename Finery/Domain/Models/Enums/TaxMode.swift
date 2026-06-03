import Foundation

enum TaxMode: String, Codable, CaseIterable, Sendable {
    case npd  = "НПД"
    case usn6 = "УСН 6%"
    case usn15 = "УСН 15%"

    var displayName: String { rawValue }

    var shortDescription: String {
        switch self {
        case .npd:   "4% с физлиц, 6% с юрлиц. Лимит 2.4 млн ₽/год"
        case .usn6:  "6% со всех доходов"
        case .usn15: "15% с прибыли (доходы − расходы)"
        }
    }
}
