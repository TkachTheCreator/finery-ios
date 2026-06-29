import Foundation

struct MonthlyAverage: Sendable, Identifiable {
    var id: Int { month }
    let month: Int  // 1-12
    let avgIncome: Decimal
    let avgExpense: Decimal

    var shortLabel: String {
        let labels = ["", "Янв", "Фев", "Мар", "Апр", "Май", "Июн",
                      "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]
        return month < labels.count ? labels[month] : ""
    }

    var avgIncomeDouble:  Double { NSDecimalNumber(decimal: avgIncome).doubleValue }
    var avgExpenseDouble: Double { NSDecimalNumber(decimal: avgExpense).doubleValue }
}

struct SeasonalAnalysis: Sendable {
    let monthlyAverages: [MonthlyAverage]
    let bestMonth: Int
    let worstMonth: Int
    let currentMonthInsight: String
    let bestMonthDiffPct: Int
    let worstMonthDiffPct: Int
}
