import Foundation

struct MonthlyData: Identifiable, Sendable {
    let id: UUID
    let month: Date
    let income: Decimal
    let expenses: Decimal
    let taxAmount: Decimal

    var netProfit: Decimal { income - expenses - taxAmount }

    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: month).capitalized
    }

    init(
        id: UUID = UUID(),
        month: Date,
        income: Decimal,
        expenses: Decimal,
        taxAmount: Decimal
    ) {
        self.id = id
        self.month = month
        self.income = income
        self.expenses = expenses
        self.taxAmount = taxAmount
    }
}
