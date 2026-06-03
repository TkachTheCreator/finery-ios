import Foundation

struct PnL: Sendable {
    let period: DateInterval
    let totalIncome: Decimal
    let totalExpenses: Decimal
    let taxAmount: Decimal

    var grossProfit: Decimal { totalIncome - totalExpenses }
    var netProfit: Decimal   { grossProfit - taxAmount }

    var margin: Double {
        guard totalIncome > 0 else { return 0 }
        return NSDecimalNumber(decimal: netProfit / totalIncome * 100).doubleValue
    }
}
