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
            let income = transactions.filter { $0.direction == .income }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return income * Decimal(0.06)

        case .usn15:
            let income   = transactions.filter { $0.direction == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
            let expenses = transactions.filter { $0.direction == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
            return max(0, (income - expenses) * Decimal(0.15))
        }
    }

    func yearlyLimit(for mode: TaxMode) -> Decimal {
        switch mode {
        case .npd:          TaxStatus.npdYearLimit
        case .usn6, .usn15: 0
        }
    }

    // NPD: 28th of next month
    func nextMonthlyDeadline(for date: Date = Date()) -> Date {
        let cal = Calendar.current
        var c = cal.dateComponents([.year, .month], from: date)
        c.month = (c.month ?? 1) + 1
        c.day = 28
        return cal.date(from: c) ?? date
    }

    // USN: quarterly — 28 April / July / October / January
    func nextQuarterlyDeadline(for date: Date = Date()) -> Date {
        let cal = Calendar.current
        let year  = cal.component(.year, from: date)

        let slots: [(month: Int, yearOffset: Int)] = [(4, 0), (7, 0), (10, 0), (1, 1)]
        for slot in slots {
            let y = year + slot.yearOffset
            if let d = cal.date(from: DateComponents(year: y, month: slot.month, day: 28)), d > date {
                return d
            }
        }
        return cal.date(from: DateComponents(year: year + 1, month: 1, day: 28)) ?? date
    }

    func nextDeadline(for date: Date = Date(), mode: TaxMode = .npd) -> Date {
        switch mode {
        case .npd:          nextMonthlyDeadline(for: date)
        case .usn6, .usn15: nextQuarterlyDeadline(for: date)
        }
    }

    // Convenience overload without date (for API usage)
    func nextDeadline(mode: TaxMode) -> Date {
        nextDeadline(for: Date(), mode: mode)
    }

    // Returns the start and end of the current quarter for `date`
    func currentQuarter(for date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let year  = cal.component(.year, from: date)
        let qStart = ((month - 1) / 3) * 3 + 1  // 1, 4, 7, 10
        let qEnd   = qStart + 2

        let start = cal.date(from: DateComponents(year: year, month: qStart, day: 1))!
        let nextQStart = cal.date(from: DateComponents(year: qEnd == 12 ? year + 1 : year,
                                                        month: qEnd == 12 ? 1 : qEnd + 1, day: 1))!
        let end = cal.date(byAdding: .second, value: -1, to: nextQStart)!
        return (start, end)
    }
}
