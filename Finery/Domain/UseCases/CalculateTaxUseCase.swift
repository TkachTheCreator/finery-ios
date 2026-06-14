import Foundation

struct CalculateTaxUseCase: Sendable {
    let transactionRepository: any TransactionRepository
    let userRepository: any UserRepository
    let taxCalculator: TaxCalculatorService

    func execute(for referenceDate: Date = Date()) async throws -> TaxStatus {
        let cal  = Calendar.current
        let user = try await userRepository.fetchUser() ?? User()
        let mode = user.taxMode

        // Full year for NPD limit tracking
        let year         = cal.component(.year, from: referenceDate)
        let startOfYear  = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear    = cal.date(from: DateComponents(year: year, month: 12, day: 31))!
        let yearTxns     = try await transactionRepository.fetch(from: startOfYear, to: endOfYear)
        let yearlyIncome = yearTxns.filter { $0.direction == .income }.reduce(Decimal(0)) { $0 + $1.amount }

        // Period for tax calculation: monthly (NPD) vs quarterly (USN)
        let (periodStart, periodEnd): (Date, Date)
        if mode == .npd {
            let sm = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate))!
            let sn = cal.date(byAdding: .month, value: 1, to: sm)!
            periodStart = sm
            periodEnd   = cal.date(byAdding: .second, value: -1, to: sn)!
        } else {
            (periodStart, periodEnd) = taxCalculator.currentQuarter(for: referenceDate)
        }

        let periodTxns = try await transactionRepository.fetch(from: periodStart, to: periodEnd)

        let qIncome   = periodTxns.filter { $0.direction == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let qExpenses = periodTxns.filter { $0.direction == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        let taxDue    = taxCalculator.calculateTax(for: periodTxns, mode: mode)
        let deadline  = taxCalculator.nextDeadline(for: referenceDate, mode: mode)
        let limit     = taxCalculator.yearlyLimit(for: mode)

        return TaxStatus(
            taxMode:             mode,
            yearlyIncome:        yearlyIncome,
            quarterlyIncome:     qIncome,
            quarterlyExpenses:   qExpenses,
            taxDue:              taxDue,
            taxPaid:             0,
            nextDeadline:        deadline,
            yearLimit:           limit
        )
    }
}
