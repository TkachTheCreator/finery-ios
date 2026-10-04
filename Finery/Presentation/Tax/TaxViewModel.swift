import Foundation
import Observation

@Observable
@MainActor
final class TaxViewModel {

    var taxStatus:        TaxStatus?
    var monthlyHistory:   [MonthlyData] = []
    var cashFlowForecast: CashFlowForecast?
    var npdForecast:      NpdForecast?
    var userType:         UserType = .freelancer
    var isLoading = false

    private let getMonthlyDynamics: GetMonthlyDynamicsUseCase
    private let transactionRepository: any TransactionRepository
    private let userRepository: any UserRepository

    init(
        getMonthlyDynamics: GetMonthlyDynamicsUseCase,
        transactionRepository: any TransactionRepository,
        userRepository: any UserRepository
    ) {
        self.getMonthlyDynamics = getMonthlyDynamics
        self.transactionRepository = transactionRepository
        self.userRepository = userRepository
    }

    func load(referenceDate: Date = Date()) async {
        print("[DEBUG] TaxViewModel.load() — START")
        isLoading = true
        defer {
            isLoading = false
            print("[DEBUG] TaxViewModel.load() — DONE, isLoading=false")
        }

        await SharedDataService.shared.loadAll(referenceDate: referenceDate)

        // loadAll() returned early because another caller holds isLoading.
        // Wait up to 5 s, but bail immediately on task cancellation.
        if SharedDataService.shared.isLoading {
            print("[DEBUG] TaxViewModel — waiting for SharedDataService.loadAll to finish")
            var ticks = 0
            while SharedDataService.shared.isLoading && ticks < 50 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                ticks += 1
            }
            print("[DEBUG] TaxViewModel — wait done, ticks=\(ticks), cancelled=\(Task.isCancelled)")
        }

        let svc = SharedDataService.shared
        userType = svc.userType

        guard svc.userType != .other else {
            taxStatus = nil
            monthlyHistory = []
            cashFlowForecast = nil
            return
        }

        // Tax status comes from API (via SharedDataService) — correct tax_mode applied
        taxStatus = svc.taxStatus

        // Monthly history from TransactionStore (synced by SharedDataService above)
        do {
            let h = try await getMonthlyDynamics.execute(monthsBack: 12, referenceDate: referenceDate)
            monthlyHistory = h
            cashFlowForecast = await computeForecast(history: h)

            if svc.taxMode == .npd {
                npdForecast = computeNpdForecast()
            } else {
                npdForecast = nil
            }

            if let user = svc.currentUser {
                NotificationService.shared.rescheduleAll(user: user, status: svc.taxStatus)
            }
        } catch {
            // getMonthlyDynamics failure is non-fatal — charts stay empty
        }
    }

    var totalTaxYear:    Decimal { monthlyHistory.reduce(0) { $0 + $1.taxAmount } }
    var totalIncomeYear: Decimal { monthlyHistory.reduce(0) { $0 + $1.income } }

    // MARK: - NPD Forecast

    private func computeNpdForecast() -> NpdForecast {
        let svc = SharedDataService.shared
        let limit = TaxStatus.npdYearLimit
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: Date())!

        let ytd = svc.transactions
            .filter { $0.direction == .income && cal.component(.year, from: $0.date) == currentYear }
            .reduce(Decimal(0)) { $0 + $1.amount }

        let recent = svc.transactions
            .filter { $0.direction == .income && $0.date >= thirtyDaysAgo }
            .reduce(Decimal(0)) { $0 + $1.amount }

        let dailyAvg = recent / 30
        let remaining = max(0, limit - ytd)

        var daysToLimit: Int? = nil
        var limitDate: Date? = nil
        if dailyAvg > 0 {
            let days = Int(NSDecimalNumber(decimal: remaining / dailyAvg).doubleValue)
            daysToLimit = max(0, days)
            limitDate = cal.date(byAdding: .day, value: max(0, days), to: Date())
        }

        return NpdForecast(ytdIncome: ytd, limit: limit, dailyAvg: dailyAvg,
                           daysToLimit: daysToLimit, limitDate: limitDate)
    }

    // MARK: - Cash Flow Forecast

    private func computeForecast(history: [MonthlyData]) async -> CashFlowForecast {
        let last3 = history.suffix(3)
        let avg: (KeyPath<MonthlyData, Decimal>) -> Decimal = { kp in
            last3.isEmpty ? 0 : last3.reduce(0) { $0 + $1[keyPath: kp] } / Decimal(last3.count)
        }
        let avgIncome   = avg(\.income)
        let avgExpenses = avg(\.expenses)
        let avgTax      = avg(\.taxAmount)

        // Use SharedDataService transactions for all-time balance
        let all  = SharedDataService.shared.transactions
        let totalIn  = all.filter { $0.direction == .income  }.reduce(0) { $0 + $1.amount }
        let totalOut = all.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
        let totalTax = history.reduce(0) { $0 + $1.taxAmount }
        let balance  = totalIn - totalOut - totalTax

        let netMonthly = avgIncome - avgExpenses - avgTax
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
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: tx, userRepository: usr, taxCalculator: calc),
            transactionRepository: tx,
            userRepository: usr
        )
        vm.taxStatus      = PreviewData.taxStatus
        vm.monthlyHistory = PreviewData.monthlyData
        return vm
    }
}
