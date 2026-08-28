import Foundation

enum RecurringPeriod: String, Codable, CaseIterable, Sendable {
    case weekly  = "weekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .weekly:  "Еженедельно"
        case .monthly: "Ежемесячно"
        }
    }
}

struct RecurringTransaction: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var amount: Decimal
    var direction: TransactionDirection
    var description: String
    var incomeCategory:  IncomeCategory?
    var expenseCategory: ExpenseCategory?
    var period: RecurringPeriod
    // weekly: 1=Mon…7=Sun (Calendar.weekday)  monthly: 1…31
    var dayOfWeek:  Int?
    var dayOfMonth: Int?
    var isActive: Bool = true
    var lastFiredDate: Date?
    var createdAt: Date = Date()

    // True if the recurring is due today and hasn't fired yet this period
    func isDueToday() -> Bool {
        guard isActive else { return false }
        let cal = Calendar.current
        let today = Date()

        switch period {
        case .weekly:
            let weekday = cal.component(.weekday, from: today) // 1=Sun…7=Sat
            guard weekday == (dayOfWeek ?? 2) else { return false }
            if let last = lastFiredDate {
                return !cal.isDate(last, equalTo: today, toGranularity: .weekOfYear)
            }
            return true

        case .monthly:
            let dom = cal.component(.day, from: today)
            guard dom == (dayOfMonth ?? 1) else { return false }
            if let last = lastFiredDate {
                return !cal.isDate(last, equalTo: today, toGranularity: .month)
            }
            return true
        }
    }
}
