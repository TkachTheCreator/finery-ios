import Foundation

// MARK: - Mock Transaction Repository

final class MockTransactionRepository: TransactionRepository, @unchecked Sendable {
    private var transactions: [Transaction]

    init(_ transactions: [Transaction] = PreviewData.transactions) {
        self.transactions = transactions
    }

    func fetchAll() async throws -> [Transaction] { transactions }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        transactions.filter { $0.date >= startDate && $0.date <= endDate }
    }

    func save(_ transaction: Transaction) async throws {
        transactions.append(transaction)
    }

    func update(_ transaction: Transaction) async throws {
        transactions = transactions.map { $0.id == transaction.id ? transaction : $0 }
    }

    func delete(id: UUID) async throws {
        transactions.removeAll { $0.id == id }
    }

    func fetchYearlyIncome(year: Int) async throws -> Decimal {
        transactions
            .filter { $0.direction == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
}

// MARK: - Mock User Repository

final class MockUserRepository: UserRepository, @unchecked Sendable {
    private var user: User?

    init(_ user: User = PreviewData.user) {
        self.user = user
    }

    func fetchUser() async throws -> User? { user }
    func saveUser(_ user: User) async throws { self.user = user }
    func updateUser(_ user: User) async throws { self.user = user }
}

// MARK: - Preview ViewModel factory

extension DashboardViewModel {
    static func preview() -> DashboardViewModel {
        let txRepo  = MockTransactionRepository()
        let usrRepo = MockUserRepository()
        let calc    = TaxCalculatorService()
        return DashboardViewModel(
            getInsights:          GetInsightsUseCase(transactionRepository: txRepo, userRepository: usrRepo, taxCalculator: calc),
            transactionRepository: txRepo
        )
    }
}
