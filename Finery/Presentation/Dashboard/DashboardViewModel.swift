import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: Reactive state — read directly from SharedDataService so they update
    // immediately after appendTransaction/refreshPnL without waiting for a full load().

    var pnl:        PnL?      { SharedDataService.shared.pnl }
    var taxStatus:  TaxStatus? {
        SharedDataService.shared.userType == .other ? nil : SharedDataService.shared.taxStatus
    }
    var userName:   String    { SharedDataService.shared.userName }
    var userType:   UserType  { SharedDataService.shared.userType }
    var isOffline:  Bool      { SharedDataService.shared.isOffline }

    var topSources: [IncomeSource] {
        let cal   = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
        let end   = cal.date(byAdding: .second, value: -1,
                             to: cal.date(byAdding: .month, value: 1, to: start)!)!
        let txns  = SharedDataService.shared.transactions.filter { $0.date >= start && $0.date <= end }
        return topIncomeSources(from: txns)
    }

    // MARK: Stored state (async-computed or view-only)

    var insights:   [Insight] = []
    var isLoading   = false
    var errorMessage: String?
    var needsAuth   = false

    // MARK: Dependencies

    private let getInsights: GetInsightsUseCase
    private let transactionRepository: any TransactionRepository  // needed for makeAddTransactionViewModel

    init(
        getInsights: GetInsightsUseCase,
        transactionRepository: any TransactionRepository
    ) {
        self.getInsights = getInsights
        self.transactionRepository = transactionRepository
    }

    // MARK: Load

    func load(referenceDate: Date = Date()) async {
        guard APIClient.shared.isAuthenticated else {
            needsAuth = true
            return
        }
        isLoading = true
        defer { isLoading = false }
        needsAuth = false

        // One call populates everything for all screens
        await SharedDataService.shared.loadAll(referenceDate: referenceDate)

        // Insights (use-case reads from TransactionStore, which is synced by SharedDataService)
        if let i = try? await getInsights.execute(referenceDate: referenceDate) {
            insights = i
        }
    }

    // MARK: Factory

    func makeAddTransactionViewModel() -> AddTransactionViewModel {
        AddTransactionViewModel(transactionRepository: transactionRepository)
    }

    func makeEditTransactionViewModel(_ tx: Transaction) -> AddTransactionViewModel {
        AddTransactionViewModel(transactionRepository: transactionRepository, existing: tx)
    }

    // MARK: Helpers

    private func topIncomeSources(from transactions: [Transaction]) -> [IncomeSource] {
        var byCategory: [IncomeCategory: Decimal] = [:]
        for t in transactions where t.direction == .income {
            byCategory[t.incomeCategory ?? .other, default: 0] += t.amount
        }
        return byCategory
            .map { IncomeSource(name: $0.key.displayName, icon: $0.key.iconName, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(3)
            .map { $0 }
    }
}

// MARK: - IncomeSource

struct IncomeSource: Identifiable, Sendable {
    let id     = UUID()
    let name:   String
    let icon:   String
    let amount: Decimal
}
