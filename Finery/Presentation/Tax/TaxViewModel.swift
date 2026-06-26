import Foundation
import Observation

@Observable
@MainActor
final class TaxViewModel {

    var taxStatus: TaxStatus?
    var monthlyHistory: [MonthlyData] = []
    var cashFlowForecast: CashFlowForecast?
    var userType: UserType = .freelancer
    var isLoading = false

    private let calculateTax: CalculateTaxUseCase
    private let getMonthlyDynamics: GetMonthlyDynamicsUseCase
    private let transactionRepository: any TransactionRepository
    private let userRepository: any UserRepository

    init(
        calculateTax: CalculateTaxUseCase,
        getMonthlyDynamics: GetMonthlyDynamicsUseCase,
        transactionRepository: any TransactionRepository,
        userRepository: any UserRepository
    ) {
        self.calculateTax = calculateTax
        self.getMonthlyDynamics = getMonthlyDynamics
        self.transactionRepository = transactionRepository
        self.userRepository = userRepository
    }

    func load(referenceDate: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }

        // Populate shared store from backend so all use cases see real data
        await TransactionStore.shared.load()

        // Read userType to decide what to show
        let user = (try? await userRepository.fetchUser()) ?? User()
        userType = user.userType

        guard user.userType != .other else {
            taxStatus = nil
            monthlyHistory = []
            cashFlowForecast = nil
            return
        }

        do {
            async let status  = calculateTax.execute(for: referenceDate)
            async let history = getMonthlyDynamics.execute(monthsBack: 12, referenceDate: referenceDate)
            let (s, h) = try await (status, history)
            taxStatus      = s
            monthlyHistory = h
            cashFlowForecast = await computeForecast(history: h)

            NotificationService.shared.scheduleTaxReminder(
                deadline: s.nextDeadline, amount: s.taxDue, daysBefore: 5)
            if s.isNearLimit {
                NotificationService.shared.scheduleNpdLimitWarning(usedPercent: s.limitUsedPercent)
            }
        } catch {}
    }

    var totalTaxYear: Decimal    { monthlyHistory.reduce(0) { $0 + $1.taxAmount } }
    var totalIncomeYear: Decimal { monthlyHistory.reduce(0) { $0 + $1.income } }

    // MARK: - Cash Flow Forecast

    private func computeForecast(history: [MonthlyData]) async -> CashFlowForecast {
        let last3 = history.suffix(3)
        let avg: (KeyPath<MonthlyData, Decimal>) -> Decimal = { kp in
            last3.isEmpty ? 0 : last3.reduce(0) { $0 + $1[keyPath: kp] } / Decimal(last3.count)
        }
        let avgIncome   = avg(\.income)
        let avgExpenses = avg(\.expenses)
        let avgTax      = avg(\.taxAmount)

        let allTxns       = (try? await transactionRepository.fetchAll()) ?? []
        let totalIn       = allTxns.filter { $0.direction == .income  }.reduce(0) { $0 + $1.amount }
        let totalOut      = allTxns.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
        let totalTax      = history.reduce(0) { $0 + $1.taxAmount }
        let balance       = totalIn - totalOut - totalTax
        let netMonthly    = avgIncome - avgExpenses - avgTax

        var daysUntilNegative: Int? = nil
        var willGoNegativeIn30Days = false

        if netMonthly < 0 && balance > 0 {
            let dailyBurn = (-netMonthly) / 30
            if dailyBurn > 0 {
                let days = Int(NSDecimalNumber(decimal: balance / dailyBurn).doubleValue)
                daysUntilNegative = max(0, days)
                willGoNegativeIn30Days = days <= 30
            }
        } else if balance < 0 {
            daysUntilNegative = 0
            willGoNegativeIn30Days = true
        }

        return CashFlowForecast(
            currentBalance: balance,
            avgMonthlyIncome: avgIncome,
            avgMonthlyExpenses: avgExpenses + avgTax,
            daysUntilNegative: daysUntilNegative,
            willGoNegativeIn30Days: willGoNegativeIn30Days
        )
    }
}

extension TaxViewModel {
    static func preview() -> TaxViewModel {
        let tx   = MockTransactionRepository()
        let usr  = MockUserRepository()
        let calc = TaxCalculatorService()
        let vm = TaxViewModel(
            calculateTax:       CalculateTaxUseCase(transactionRepository: tx, userRepository: usr, taxCalculator: calc),
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: tx, userRepository: usr, taxCalculator: calc),
            transactionRepository: tx,
            userRepository: usr
        )
        vm.taxStatus      = PreviewData.taxStatus
        vm.monthlyHistory = PreviewData.monthlyData
        return vm
    }
}
