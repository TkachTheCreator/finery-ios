import Foundation
import Observation

@Observable
@MainActor
final class AnalyticsViewModel {

    var monthlyData: [MonthlyData] = []
    var incomeBreakdown:  [(category: IncomeCategory,  amount: Decimal, percent: Double)] = []
    var expenseBreakdown: [(category: ExpenseCategory, amount: Decimal, percent: Double)] = []
    var currentMonthIncome:   Decimal = 0
    var previousMonthIncome:  Decimal = 0
    var totalTax: Decimal = 0
    var isLoading = false
    var errorMessage: String?
    var exportedPDFData: Data?
    var showingPDFShare = false

    var incomeChange: Double {
        guard previousMonthIncome > 0 else { return 0 }
        return NSDecimalNumber(
            decimal: (currentMonthIncome - previousMonthIncome) / previousMonthIncome * 100
        ).doubleValue
    }

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
        isLoading = true
        defer { isLoading = false }

        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate))!
        let startOfNext  = cal.date(byAdding: .month, value: 1, to: startOfMonth)!
        let endOfMonth   = cal.date(byAdding: .second, value: -1, to: startOfNext)!
        let prevStart    = cal.date(byAdding: .month, value: -1, to: startOfMonth)!
        let prevEnd      = cal.date(byAdding: .second, value: -1, to: startOfMonth)!

        do {
            async let monthly   = getMonthlyDynamics.execute(referenceDate: referenceDate)
            async let curTxns   = transactionRepository.fetch(from: startOfMonth, to: endOfMonth)
            async let prevTxns  = transactionRepository.fetch(from: prevStart, to: prevEnd)

            let (months, current, prev) = try await (monthly, curTxns, prevTxns)
            monthlyData = months

            currentMonthIncome  = current.filter { $0.direction == .income  }.reduce(0) { $0 + $1.amount }
            previousMonthIncome = prev.filter    { $0.direction == .income  }.reduce(0) { $0 + $1.amount }
            totalTax = months.reduce(0) { $0 + $1.taxAmount }

            incomeBreakdown  = breakdown(from: current.filter { $0.direction == .income  })
            expenseBreakdown = expenseBreakdownCalc(from: current.filter { $0.direction == .expense })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - PDF Export

    func generatePDF() {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy"
        fmt.locale = Locale(identifier: "ru_RU")
        let periodLabel = fmt.string(from: Date()).capitalized

        let totalIncome   = monthlyData.reduce(0) { $0 + $1.income }
        let totalExpenses = monthlyData.reduce(0) { $0 + $1.expenses }
        let netProfit     = totalIncome - totalExpenses - totalTax

        let incomeRows = incomeBreakdown.map { (name: $0.category.displayName, amount: $0.amount, percent: $0.percent) }
        let monthlyRows = monthlyData.map { (label: $0.monthLabel, income: $0.income, expenses: $0.expenses) }

        let reportData = FineryPDFGenerator.ReportData(
            periodLabel: periodLabel,
            income: totalIncome,
            expenses: totalExpenses,
            taxAmount: totalTax,
            netProfit: netProfit,
            incomeBreakdown: incomeRows,
            monthlyData: monthlyRows
        )

        exportedPDFData = FineryPDFGenerator().generate(data: reportData)
        showingPDFShare = exportedPDFData != nil
    }

    // MARK: - Breakdown helpers

    private func breakdown(from transactions: [Transaction]) -> [(category: IncomeCategory, amount: Decimal, percent: Double)] {
        let total = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        guard total > 0 else { return [] }
        let grouped = Dictionary(grouping: transactions, by: { $0.incomeCategory ?? .other })
        return grouped
            .map { cat, txns in
                let amount = txns.reduce(Decimal(0)) { $0 + $1.amount }
                let pct = NSDecimalNumber(decimal: amount / total * 100).doubleValue
                return (category: cat, amount: amount, percent: pct)
            }
            .sorted { $0.amount > $1.amount }
    }

    private func expenseBreakdownCalc(from transactions: [Transaction]) -> [(category: ExpenseCategory, amount: Decimal, percent: Double)] {
        let total = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        guard total > 0 else { return [] }
        let grouped = Dictionary(grouping: transactions, by: { $0.expenseCategory ?? .other })
        return grouped
            .map { cat, txns in
                let amount = txns.reduce(Decimal(0)) { $0 + $1.amount }
                let pct = NSDecimalNumber(decimal: amount / total * 100).doubleValue
                return (category: cat, amount: amount, percent: pct)
            }
            .sorted { $0.amount > $1.amount }
    }
}

extension AnalyticsViewModel {
    static func preview() -> AnalyticsViewModel {
        let tx  = MockTransactionRepository()
        let usr = MockUserRepository()
        let calc = TaxCalculatorService()
        let vm = AnalyticsViewModel(
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: tx, userRepository: usr, taxCalculator: calc),
            transactionRepository: tx,
            userRepository: usr
        )
        vm.monthlyData = PreviewData.monthlyData
        return vm
    }
}
