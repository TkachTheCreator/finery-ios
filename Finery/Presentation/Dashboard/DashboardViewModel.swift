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
    var userType: UserType = .freelancer
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

        // Populate shared store so Tax/Analytics ViewModels see the same data
        await TransactionStore.shared.load()

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

            let fetchedUserType = u?.userType ?? .freelancer
            pnl        = p
            userType   = fetchedUserType
            taxStatus  = fetchedUserType == .other ? nil : t
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
            if let u = try? await userRepository.fetchUser() {
                userName = u.name
                userType = u.userType
            }
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
        var byCategory: [IncomeCategory: Decimal] = [:]
        for t in income {
            let cat = t.incomeCategory ?? .other
            byCategory[cat, default: 0] += t.amount
        }
        return byCategory
            .map { category, amount in
                IncomeSource(name: category.displayName,
                             icon: category.iconName,
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
