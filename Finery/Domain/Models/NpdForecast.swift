import Foundation

struct NpdForecast: Sendable {
    let ytdIncome: Decimal
    let limit: Decimal
    let dailyAvg: Decimal
    let daysToLimit: Int?
    let limitDate: Date?

    var remaining: Decimal  { max(0, limit - ytdIncome) }
    var usedPercent: Double {
        guard limit > 0 else { return 0 }
        return min(100, NSDecimalNumber(decimal: ytdIncome / limit * 100).doubleValue)
    }
}
