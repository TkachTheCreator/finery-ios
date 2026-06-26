import Foundation

/// Implements TransactionRepository by reading from the in-memory TransactionStore
/// and writing through to local SwiftData as an offline cache.
@MainActor
final class StoreBackedTransactionRepository: TransactionRepository, @unchecked Sendable {
    private let local: TransactionLocalRepository

    init(local: TransactionLocalRepository) {
        self.local = local
    }

    func fetchAll() throws -> [Transaction] {
        TransactionStore.shared.transactions
    }

    func fetch(from: Date, to: Date) throws -> [Transaction] {
        TransactionStore.shared.items(from: from, to: to)
    }

    func save(_ tx: Transaction) throws {
        TransactionStore.shared.append(tx)
        try? local.save(tx)
    }

    func update(_ tx: Transaction) throws {
        TransactionStore.shared.append(tx)
        try? local.update(tx)
    }

    func delete(id: UUID) throws {
        TransactionStore.shared.remove(id: id)
        try? local.delete(id: id)
    }

    func fetchYearlyIncome(year: Int) throws -> Decimal {
        TransactionStore.shared.yearlyIncome(year)
    }
}
