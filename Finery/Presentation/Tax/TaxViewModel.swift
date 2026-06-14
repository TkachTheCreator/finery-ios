import Foundation
import Observation

@Observable
@MainActor
final class TaxViewModel {

    var taxStatus: TaxStatus?
    var monthlyHistory: [MonthlyData] = []
    var cashFlowForecast: CashFlowForecast?
    var isLoading = false

    private let calculateTax: CalculateTaxUseCase
    private let getMonthlyDynamics: GetMonthlyDynamicsUseCase
    private let transactionRepository: any TransactionRepository

    init(
        calculateTax: CalculateTaxUseCase,
        getMonthlyDynamics: GetMonthlyDynamicsUseCase,
        transactionRepository: any TransactionRepository
    ) {
        self.calculateTax = calculateTax
        self.getMonthlyDynamics = getMonthlyDynamics
        self.transactionRepository = transactionRepository
    }

    func load(referenceDate: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let status  = calculateTax.execute(for: referenceDate)
            async let history = getMonthlyDynamics.execute(monthsBack: 12, referenceDate: referenceDate)
            let (s, h) = try await (status, history)
            taxStatus     = s
            monthlyHistory = h
            cashFlowForecast = await computeForecast(history: h, referenceDate: referenceDate)

            NotificationService.shared.scheduleTaxReminder(
                deadline: s.nextDeadline, amount: s.taxDue, daysBefore: 5)
            if s.isNearLimit {
                NotificationService.shared.scheduleNpdLimitWarning(
                    usedPercent: s.limitUsedPercent)
            }
        } catch {}
    }

    var totalTaxYear: Decimal {
        monthlyHistory.reduce(0) { $0 + $1.taxAmount }
    }

    var totalIncomeYear: Decimal {
        monthlyHistory.reduce(0) { $0 + $1.income }
    }

    // MARK: - Cash Flow Forecast

    private func computeForecast(history: [MonthlyData], referenceDate: Date) async -> CashFlowForecast {
        let cal = Calendar.current
        let last3 = history.suffix(3)

        let avgIncome   = last3.isEmpty ? 0 : last3.reduce(0) { $0 + $1.income }   / Decimal(last3.count)
        let avgExpenses = last3.isEmpty ? 0 : last3.reduce(0) { $0 + $1.expenses } / Decimal(last3.count)
        let avgTax      = last3.isEmpty ? 0 : last3.reduce(0) { $0 + $1.taxAmount } / Decimal(last3.count)

        // Current balance = all-time income minus expenses minus taxes
        let allTxns = (try? await transactionRepository.fetchAll()) ?? []
        let totalIncome   = allTxns.filter { $0.direction == .income  }.reduce(0) { $0 + $1.amount }
        let totalExpenses = allTxns.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
        let totalTax      = history.reduce(0) { $0 + $1.taxAmount }
        let currentBalance = totalIncome - totalExpenses - totalTax

        // Monthly outflow = avg expenses + avg tax
        let monthlyOutflow = avgExpenses + avgTax
        let monthlyInflow  = avgIncome

        // Net monthly flow (positive = surplus, negative = burning cash)
        let netMonthly = monthlyInflow - monthlyOutflow

        var daysUntilNegative: Int? = nil
        var willGoNegativeIn30Days = false

        if netMonthly < 0 && currentBalance > 0 {
            // Days = currentBalance / dailyBurnRate
            let dailyBurn = (-netMonthly) / 30
            if dailyBurn > 0 {
                let days = Int(NSDecimalNumber(decimal: currentBalance / dailyBurn).doubleValue)
                daysUntilNegative = max(0, days)
                willGoNegativeIn30Days = days <= 30
            }
        } else if currentBalance < 0 {
            daysUntilNegative = 0
            willGoNegativeIn30Days = true
        }

        return CashFlowForecast(
            currentBalance: currentBalance,
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
            calculateTax: CalculateTaxUseCase(transactionRepository: tx, userRepository: usr, taxCalculator: calc),
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: tx, userRepository: usr, taxCalculator: calc),
            transactionRepository: tx
        )
        vm.taxStatus     = PreviewData.taxStatus
        vm.monthlyHistory = PreviewData.monthlyData
        return vm
    }
}
