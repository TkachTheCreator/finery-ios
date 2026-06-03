import Foundation

struct GetPnLUseCase: Sendable {
    let transactionRepository: any TransactionRepository
    let userRepository: any UserRepository
    let taxCalculator: TaxCalculatorService

    func execute(from startDate: Date, to endDate: Date) async throws -> PnL {
        async let transactions = transactionRepository.fetch(from: startDate, to: endDate)
        async let user = userRepository.fetchUser()

        let (txns, resolvedUser) = try await (transactions, user)
        let mode = resolvedUser?.taxMode ?? .npd

        let income = txns
            .filter { $0.direction == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }

        let expenses = txns
            .filter { $0.direction == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }

        let tax = taxCalculator.calculateTax(for: txns, mode: mode)

        return PnL(
            period: DateInterval(start: startDate, end: endDate),
            totalIncome: income,
            totalExpenses: expenses,
            taxAmount: tax
        )
    }
}
