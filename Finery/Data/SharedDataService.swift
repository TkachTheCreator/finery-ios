import Foundation
import Observation

/// Central data hub. All ViewModels read from here; one API round-trip
/// populates every screen simultaneously.
@Observable
@MainActor
final class SharedDataService {
    static let shared = SharedDataService()
    private init() {}

    // MARK: - State

    private(set) var transactions: [Transaction] = []
    private(set) var pnl:         PnL?
    private(set) var taxStatus:   TaxStatus?
    private(set) var currentUser: User?

    private(set) var isLoading  = false
    private(set) var isOffline  = false
    private(set) var lastUpdated: Date?

    // MARK: - Computed shortcuts

    var totalIncome:  Decimal   { pnl?.totalIncome   ?? 0 }
    var totalExpense: Decimal   { pnl?.totalExpenses ?? 0 }
    var netProfit:    Decimal   { pnl?.netProfit      ?? 0 }
    var taxAmount:    Decimal   { pnl?.taxAmount      ?? 0 }
    var taxMode:      TaxMode   { currentUser?.taxMode  ?? .npd }
    var userType:     UserType  { currentUser?.userType ?? .freelancer }
    var userName:     String    { currentUser?.name ?? "" }

    private var isStale: Bool {
        guard let t = lastUpdated else { return true }
        return Date().timeIntervalSince(t) > 30
    }

    // MARK: - Load

    func loadAll(referenceDate: Date = Date()) async {
        guard APIClient.shared.isAuthenticated else { return }
        guard !isLoading, isStale else { return }
        isLoading = true
        defer { isLoading = false }

        let cal = Calendar.current
        let year         = cal.component(.year, from: referenceDate)
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate))!
        let endOfMonth   = cal.date(byAdding: .second, value: -1,
                                    to: cal.date(byAdding: .month, value: 1, to: startOfMonth)!)!
        let fromTwoYears = cal.date(from: DateComponents(year: year - 1, month: 1, day: 1))!
        let resolvedMode = currentUser?.taxMode ?? .npd

        async let txTask   = APIClient.shared.getTransactions(from: fromTwoYears, perPage: 500)
        async let pnlTask  = APIClient.shared.getPnL(from: startOfMonth, to: endOfMonth)
        async let taxTask  = APIClient.shared.getTaxStatus(year: year, taxMode: resolvedMode)
        async let userTask = APIClient.shared.getCurrentUser()

        let txResult   = try? await txTask
        let pnlResult  = try? await pnlTask
        let taxResult  = try? await taxTask
        let userResult = try? await userTask

        isOffline = (txResult == nil) && transactions.isEmpty

        if let txs = txResult {
            transactions = txs
            TransactionStore.shared.syncFromService(txs)   // keep use-cases in sync
        }
        if let p = pnlResult  { pnl = p }
        if let t = taxResult  { taxStatus = t }
        if let u = userResult { currentUser = u }

        lastUpdated = Date()
    }

    // MARK: - Mutations

    func addTransaction(_ tx: Transaction) async throws {
        let created = try await APIClient.shared.createTransaction(tx)
        transactions.insert(created, at: 0)
        TransactionStore.shared.append(created)
        lastUpdated = nil  // force refresh on next loadAll
        await loadAll()
    }

    func deleteTransaction(id: UUID) async {
        transactions.removeAll { $0.id == id }
        TransactionStore.shared.remove(id: id)
        try? await APIClient.shared.deleteTransaction(id: id)
    }

    func reset() {
        transactions = []
        pnl = nil
        taxStatus = nil
        currentUser = nil
        lastUpdated = nil
        isOffline = false
        TransactionStore.shared.reset()
    }
}
