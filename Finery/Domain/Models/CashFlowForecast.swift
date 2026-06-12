import Foundation

struct CashFlowForecast: Sendable {
    let currentBalance: Decimal
    let avgMonthlyIncome: Decimal
    let avgMonthlyExpenses: Decimal
    let daysUntilNegative: Int?
    let willGoNegativeIn30Days: Bool

    var dailyBurnRate: Decimal {
        let days = Decimal(30)
        guard days > 0 else { return 0 }
        return avgMonthlyExpenses / days
    }

    var formattedDaysLeft: String {
        guard let days = daysUntilNegative else { return "∞" }
        return "\(days)"
    }
}
