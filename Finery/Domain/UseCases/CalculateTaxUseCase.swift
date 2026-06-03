import Foundation

struct CalculateTaxUseCase: Sendable {
    let transactionRepository: any TransactionRepository
    let userRepository: any UserRepository
    let taxCalculator: TaxCalculatorService

    func execute(for month: Date) async throws -> TaxStatus {
        let calendar = Calendar.current
        let user = try await userRepository.fetchUser() ?? User()

        let year = calendar.component(.year, from: month)
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear   = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!

        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let startOfNext  = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let endOfMonth   = calendar.date(byAdding: .second, value: -1, to: startOfNext)!

        async let yearTxns  = transactionRepository.fetch(from: startOfYear, to: endOfYear)
        async let monthTxns = transactionRepository.fetch(from: startOfMonth, to: endOfMonth)
        let (allYear, thisMonth) = try await (yearTxns, monthTxns)

        let yearlyIncome = allYear
            .filter { $0.direction == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }

        let monthTax = taxCalculator.calculateTax(for: thisMonth, mode: user.taxMode)
        let deadline  = taxCalculator.nextDeadline(for: month)
        let limit     = taxCalculator.yearlyLimit(for: user.taxMode)

        return TaxStatus(
            taxMode: user.taxMode,
            yearlyIncome: yearlyIncome,
            taxDue: monthTax,
            taxPaid: 0,
            nextDeadline: deadline,
            yearLimit: limit
        )
    }
}
