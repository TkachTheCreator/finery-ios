import Foundation

struct GetMonthlyDynamicsUseCase: Sendable {
    let transactionRepository: any TransactionRepository
    let userRepository: any UserRepository
    let taxCalculator: TaxCalculatorService

    func execute(monthsBack: Int = 6, referenceDate: Date = Date()) async throws -> [MonthlyData] {
        let calendar = Calendar.current
        let user = try await userRepository.fetchUser() ?? User()

        var results: [MonthlyData] = []
        for offset in (0..<monthsBack).reversed() {
            let monthDate    = calendar.date(byAdding: .month, value: -offset, to: referenceDate)!
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let startOfNext  = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            let endOfMonth   = calendar.date(byAdding: .second, value: -1, to: startOfNext)!

            let txns     = try await transactionRepository.fetch(from: startOfMonth, to: endOfMonth)
            let income   = txns.filter { $0.direction == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
            let expenses = txns.filter { $0.direction == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
            let tax      = taxCalculator.calculateTax(for: txns, mode: user.taxMode)

            results.append(MonthlyData(month: startOfMonth, income: income, expenses: expenses, taxAmount: tax))
        }
        return results.sorted { $0.month < $1.month }
    }
}
