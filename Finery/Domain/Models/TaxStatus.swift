import Foundation

struct TaxStatus: Sendable {
    let taxMode: TaxMode
    let yearlyIncome: Decimal
    let taxDue: Decimal
    let taxPaid: Decimal
    let nextDeadline: Date
    let yearLimit: Decimal

    static let npdYearLimit: Decimal = 2_400_000

    var limitUsedPercent: Double {
        guard yearLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: yearlyIncome / yearLimit * 100).doubleValue
    }

    var remaining: Decimal { max(0, yearLimit - yearlyIncome) }

    var taxBalance: Decimal { taxDue - taxPaid }

    var isNearLimit: Bool  { limitUsedPercent >= 80 }
    var isOverLimit: Bool  { limitUsedPercent >= 100 }

    var daysUntilDeadline: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDeadline).day ?? 0
    }

    var trafficLight: TrafficLight {
        switch limitUsedPercent {
        case ..<60:  .green
        case 60..<80: .yellow
        default:     .red
        }
    }
}

enum TrafficLight: Sendable {
    case green, yellow, red
}
