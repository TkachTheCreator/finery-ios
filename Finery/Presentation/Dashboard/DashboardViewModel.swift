import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: Published state

    var pnl: PnL?
    var taxStatus: TaxStatus?
    var topSources: [(category: IncomeCategory, amount: Decimal)] = []
    var insights: [Insight] = []
    var userName: String = ""
    var isLoading = false
    var errorMessage: String?
    var needsAuth = false

    // MARK: Dependencies

    private let getPnL: GetPnLUseCase
    private let calculateTax: CalculateTaxUseCase
    private let getInsights: GetInsightsUseCase
    private let transactionRepository: any TransactionRepository
    private let userRepository: any UserRepository

    init(
        getPnL: GetPnLUseCase,
        calculateTax: CalculateTaxUseCase,
        getInsights: GetInsightsUseCase,
        transactionRepository: any TransactionRepository,
        userRepository: any UserRepository
    ) {
        self.getPnL = getPnL
        self.calculateTax = calculateTax
        self.getInsights = getInsights
        self.transactionRepository = transactionRepository
        self.userRepository = userRepository
    }

    // MARK: Load

    func load(referenceDate: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }
        needsAuth = false

        guard APIClient.shared.isAuthenticated else {
            needsAuth = true
            return
        }

        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate))!
        let startOfNext  = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let endOfMonth   = calendar.date(byAdding: .second, value: -1, to: startOfNext)!
        let year         = calendar.component(.year, from: referenceDate)
        let taxMode      = (try? await userRepository.fetchUser())?.taxMode ?? .npd

        do {
            async let pnlTask      = APIClient.shared.getPnL(from: startOfMonth, to: endOfMonth)
            async let taxTask      = APIClient.shared.getTaxStatus(year: year, taxMode: taxMode)
            async let insightsTask = getInsights.execute(referenceDate: referenceDate)
            async let userTask     = userRepository.fetchUser()

            let (p, t, i, u) = try await (pnlTask, taxTask, insightsTask, userTask)

            pnl        = p
            taxStatus  = t
            insights   = i
            userName   = u?.name ?? ""
            topSources = []          // populated when transactions are synced locally
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Helpers

    private func topIncomeSources(from transactions: [Transaction]) -> [(category: IncomeCategory, amount: Decimal)] {
        let income = transactions.filter { $0.direction == .income }
        let grouped = Dictionary(grouping: income, by: { $0.incomeCategory ?? .other })
        return grouped
            .map { (category: $0.key, amount: $0.value.reduce(Decimal(0)) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
            .prefix(3)
            .map { $0 }
    }
}
