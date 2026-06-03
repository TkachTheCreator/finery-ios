import Foundation

struct TaxCalculatorService: Sendable {

    func calculateTax(for transactions: [Transaction], mode: TaxMode) -> Decimal {
        switch mode {
        case .npd:
            return transactions
                .filter { $0.direction == .income }
                .reduce(Decimal(0)) { sum, t in
                    sum + t.amount * (t.clientType?.npdRate ?? Decimal(0.04))
                }
        case .usn6:
            let income = transactions
                .filter { $0.direction == .income }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return income * Decimal(0.06)

        case .usn15:
            let income = transactions
                .filter { $0.direction == .income }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let expenses = transactions
                .filter { $0.direction == .expense }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return max(0, (income - expenses) * Decimal(0.15))
        }
    }

    func nextDeadline(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: date)
        components.month = (components.month ?? 1) + 1
        components.day = 28
        return calendar.date(from: components) ?? date
    }

    func yearlyLimit(for mode: TaxMode) -> Decimal {
        switch mode {
        case .npd:          TaxStatus.npdYearLimit
        case .usn6, .usn15: Decimal(999_999_999)
        }
    }
}
