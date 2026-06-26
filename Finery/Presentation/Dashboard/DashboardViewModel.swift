import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: Published state (read by DashboardView)

    var pnl:        PnL?
    var taxStatus:  TaxStatus?
    var topSources: [IncomeSource] = []
    var insights:   [Insight] = []
    var userName:   String = ""
    var userType:   UserType = .freelancer
    var isLoading   = false
    var errorMessage: String?
    var needsAuth   = false
    var isOffline   = false

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

        let svc = SharedDataService.shared
        isOffline  = svc.isOffline
        pnl        = svc.pnl
        userType   = svc.userType
        userName   = svc.userName
        taxStatus  = svc.userType == .other ? nil : svc.taxStatus

        // Top income sources for current month (local computation)
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate))!
        let end   = cal.date(byAdding: .second, value: -1,
                             to: cal.date(byAdding: .month, value: 1, to: start)!)!
        let monthTxns = svc.transactions.filter { $0.date >= start && $0.date <= end }
        topSources = topIncomeSources(from: monthTxns)

        // Insights (use-case reads from TransactionStore, which is synced by SharedDataService)
        if let i = try? await getInsights.execute(referenceDate: referenceDate) {
            insights = i
        }
    }

    // MARK: Factory

    func makeAddTransactionViewModel() -> AddTransactionViewModel {
        AddTransactionViewModel(transactionRepository: transactionRepository)
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
