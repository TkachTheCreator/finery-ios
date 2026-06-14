import Foundation

struct TaxStatus: Sendable {
    let taxMode: TaxMode
    let yearlyIncome: Decimal
    let quarterlyIncome: Decimal
    let quarterlyExpenses: Decimal
    let taxDue: Decimal
    let taxPaid: Decimal
    let nextDeadline: Date
    let yearLimit: Decimal

    static let npdYearLimit: Decimal = 2_400_000

    // MARK: - Mode flags

    var showNpdLimit: Bool   { taxMode == .npd }
    var hasYearlyLimit: Bool { taxMode == .npd }
    var isQuarterly: Bool    { taxMode != .npd }

    // MARK: - NPD limit

    var limitUsedPercent: Double {
        guard yearLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: yearlyIncome / yearLimit * 100).doubleValue
    }

    var remaining: Decimal {
        guard yearLimit > 0 else { return 0 }
        return max(0, yearLimit - yearlyIncome)
    }

    var isNearLimit: Bool { taxMode == .npd && limitUsedPercent >= 80 }
    var isOverLimit: Bool { taxMode == .npd && limitUsedPercent >= 100 }

    // MARK: - USN

    var quarterlyProfit: Decimal { max(0, quarterlyIncome - quarterlyExpenses) }
    var effectiveRate: String {
        switch taxMode {
        case .npd:   "4–6%"
        case .usn6:  "6%"
        case .usn15: "15%"
        }
    }

    // MARK: - Shared

    var taxBalance: Decimal { taxDue - taxPaid }

    var daysUntilDeadline: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: nextDeadline).day ?? 0)
    }

    var trafficLight: TrafficLight {
        if taxMode == .npd {
            switch limitUsedPercent {
            case ..<60:   .green
            case 60..<80: .yellow
            default:      .red
            }
        } else {
            daysUntilDeadline <= 7 ? .red : daysUntilDeadline <= 14 ? .yellow : .green
        }
    }
}

enum TrafficLight: Sendable { case green, yellow, red }
