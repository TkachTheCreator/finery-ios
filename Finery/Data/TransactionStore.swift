import Foundation
import Observation

/// Single in-memory cache of transactions loaded from the backend.
/// All ViewModels read through StoreBackedTransactionRepository which delegates here.
@Observable
@MainActor
final class TransactionStore {
    static let shared = TransactionStore()
    private init() {}

    private(set) var transactions: [Transaction] = []
    private var loadedAt: Date?

    private var isStale: Bool {
        guard let t = loadedAt else { return true }
        return Date().timeIntervalSince(t) > 30
    }

    /// Fetches all transactions for the past 2 years from the backend.
    /// No-ops if data is fresh (< 30 seconds old).
    func load() async {
        guard APIClient.shared.isAuthenticated, isStale else { return }
        do {
            let cal  = Calendar.current
            let year = cal.component(.year, from: Date())
            let from = cal.date(from: DateComponents(year: year - 1, month: 1, day: 1))!
            transactions = try await APIClient.shared.getTransactions(from: from, limit: 500)
            loadedAt = Date()
        } catch {}
    }

    func append(_ tx: Transaction) {
        transactions.removeAll { $0.id == tx.id }
        transactions.insert(tx, at: 0)
    }

    func remove(id: UUID) {
        transactions.removeAll { $0.id == id }
    }

    func reset() {
        transactions = []
        loadedAt = nil
    }

    func items(from: Date, to: Date) -> [Transaction] {
        transactions.filter { $0.date >= from && $0.date <= to }
    }

    func items(year: Int) -> [Transaction] {
        let cal = Calendar.current
        return transactions.filter { cal.component(.year, from: $0.date) == year }
    }

    func yearlyIncome(_ year: Int) -> Decimal {
        items(year: year).filter { $0.direction == .income }.reduce(0) { $0 + $1.amount }
    }
}
