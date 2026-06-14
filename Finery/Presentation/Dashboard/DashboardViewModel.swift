import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: Published state

    var pnl: PnL?
    var taxStatus: TaxStatus?
    var topSources: [IncomeSource] = []
    var insights: [Insight] = []
    var userName: String = ""
    var isLoading = false
    var errorMessage: String?
    var needsAuth = false
    var isOffline = false

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
        isOffline = false

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
            async let txnsTask     = transactionRepository.fetch(from: startOfMonth, to: endOfMonth)

            let (p, t, i, u, txns) = try await (pnlTask, taxTask, insightsTask, userTask, txnsTask)

            pnl        = p
            taxStatus  = t
            insights   = i
            userName   = u?.name ?? ""
            topSources = topIncomeSources(from: txns)
        } catch NetworkError.noConnection {
            isOffline = true
            // Fallback: compute PnL from local SwiftData
            if let txns = try? await transactionRepository.fetch(from: startOfMonth, to: endOfMonth) {
                topSources = topIncomeSources(from: txns)
                let income   = txns.filter { $0.direction == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
                let expenses = txns.filter { $0.direction == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
                pnl = PnL(
                    period: DateInterval(start: startOfMonth, end: endOfMonth),
                    totalIncome: income,
                    totalExpenses: expenses,
                    taxAmount: 0
                )
            }
            userName = (try? await userRepository.fetchUser())?.name ?? userName
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Factory

    func makeAddTransactionViewModel() -> AddTransactionViewModel {
        AddTransactionViewModel(transactionRepository: transactionRepository)
    }

    // MARK: Helpers

    private func topIncomeSources(from transactions: [Transaction]) -> [IncomeSource] {
        let income = transactions.filter { $0.direction == .income }
        var bySource: [String: Decimal] = [:]
        for t in income {
            bySource[t.source.displayName, default: 0] += t.amount
        }
        let iconMap: [String: String] = [
            "Boosty":          "star",
            "DonationAlerts":  "heart",
            "Банк":            "building.columns",
            "Вручную":         "pencil",
            "Голос":           "mic"
        ]
        return bySource
            .map { name, amount in
                IncomeSource(name: name,
                             icon: iconMap[name] ?? "ellipsis.circle",
                             amount: amount)
            }
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
