import Foundation
import Observation

@Observable
@MainActor
final class AnalyticsViewModel {

    var monthlyData:       [MonthlyData] = []
    var incomeBreakdown:   [(category: IncomeCategory,  amount: Decimal, percent: Double)] = []
    var expenseBreakdown:  [(category: ExpenseCategory, amount: Decimal, percent: Double)] = []
    var currentMonthIncome:  Decimal = 0
    var previousMonthIncome: Decimal = 0
    var totalTax:  Decimal = 0
    var isLoading  = false
    var errorMessage: String?
    var exportedPDFData: Data?
    var showingPDFShare = false
    var seasonalAnalysis: SeasonalAnalysis? = nil

    // 7.1 — client revenue
    var clientIncomeBreakdown: [(clientName: String, amount: Decimal, percent: Double)] = []

    // 7.2 — forecast
    var nextMonthForecast: Decimal? = nil

    var incomeChange: Double {
        guard previousMonthIncome > 0 else { return 0 }
        return NSDecimalNumber(
            decimal: (currentMonthIncome - previousMonthIncome) / previousMonthIncome * 100
        ).doubleValue
    }

    private let getMonthlyDynamics: GetMonthlyDynamicsUseCase

    init(getMonthlyDynamics: GetMonthlyDynamicsUseCase) {
        self.getMonthlyDynamics = getMonthlyDynamics
    }

    func load(referenceDate: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }

        // Populate shared store
        await SharedDataService.shared.loadAll(referenceDate: referenceDate)

        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate))!
        let endOfMonth   = cal.date(byAdding: .second, value: -1,
                                    to: cal.date(byAdding: .month, value: 1, to: startOfMonth)!)!
        let prevStart    = cal.date(byAdding: .month, value: -1, to: startOfMonth)!
        let prevEnd      = cal.date(byAdding: .second, value: -1, to: startOfMonth)!

        // Transactions come from SharedDataService (already fetched)
        let allTxns = SharedDataService.shared.transactions
        let curTxns  = allTxns.filter { $0.date >= startOfMonth && $0.date <= endOfMonth }
        let prevTxns = allTxns.filter { $0.date >= prevStart    && $0.date <= prevEnd }

        currentMonthIncome  = curTxns.filter  { $0.direction == .income }.reduce(0) { $0 + $1.amount }
        previousMonthIncome = prevTxns.filter { $0.direction == .income }.reduce(0) { $0 + $1.amount }

        incomeBreakdown  = breakdown(from: curTxns.filter { $0.direction == .income  })
        expenseBreakdown = expenseBreakdownCalc(from: curTxns.filter { $0.direction == .expense })

        // Monthly dynamics via use-case (TransactionStore is synced by SharedDataService)
        do {
            let months = try await getMonthlyDynamics.execute(referenceDate: referenceDate)
            monthlyData = months
            totalTax    = months.reduce(0) { $0 + $1.taxAmount }
        } catch {
            errorMessage = error.localizedDescription
        }

        seasonalAnalysis = computeSeasonalAnalysis()
        clientIncomeBreakdown = computeClientIncome(from: allTxns)
        nextMonthForecast = computeForecast()
    }

    // MARK: - Seasonal Analysis

    private func computeSeasonalAnalysis() -> SeasonalAnalysis? {
        let transactions = SharedDataService.shared.transactions
        guard !transactions.isEmpty else { return nil }

        let cal = Calendar.current
        // Group totals by (year, month)
        var byYearMonth: [Int: [Int: (income: Decimal, expense: Decimal)]] = [:]
        for tx in transactions {
            let y = cal.component(.year,  from: tx.date)
            let m = cal.component(.month, from: tx.date)
            if byYearMonth[y] == nil { byYearMonth[y] = [:] }
            var cur = byYearMonth[y]![m] ?? (0, 0)
            if tx.direction == .income  { cur.income  += tx.amount }
            else                        { cur.expense += tx.amount }
            byYearMonth[y]![m] = cur
        }

        // Average per calendar month across all years
        var averages: [MonthlyAverage] = []
        for month in 1...12 {
            var incomes: [Decimal]  = []
            var expenses: [Decimal] = []
            for (_, mdata) in byYearMonth {
                if let d = mdata[month] { incomes.append(d.income); expenses.append(d.expense) }
            }
            let avgI = incomes.isEmpty  ? 0 : incomes.reduce(0, +)  / Decimal(incomes.count)
            let avgE = expenses.isEmpty ? 0 : expenses.reduce(0, +) / Decimal(expenses.count)
            averages.append(MonthlyAverage(month: month, avgIncome: avgI, avgExpense: avgE))
        }

        let best  = averages.max(by: { $0.avgIncome < $1.avgIncome }) ?? averages[0]
        let worst = averages.min(by: { $0.avgIncome < $1.avgIncome }) ?? averages[0]
        let overallAvg = averages.reduce(Decimal(0)) { $0 + $1.avgIncome } / 12

        func diffPct(_ val: Decimal) -> Int {
            guard overallAvg > 0 else { return 0 }
            return Int(NSDecimalNumber(decimal: (val - overallAvg) / overallAvg * 100).doubleValue)
        }

        let curMonth = cal.component(.month, from: Date())
        let curAvg   = averages.first(where: { $0.month == curMonth })?.avgIncome ?? 0
        let diff     = diffPct(curAvg)
        let dir      = diff >= 0 ? "выше" : "ниже"
        let curLabel = averages.first(where: { $0.month == curMonth })?.shortLabel ?? ""
        let insight  = "\(curLabel) исторически \(dir) среднего на \(abs(diff))%"

        return SeasonalAnalysis(
            monthlyAverages: averages,
            bestMonth: best.month, worstMonth: worst.month,
            currentMonthInsight: insight,
            bestMonthDiffPct: diffPct(best.avgIncome),
            worstMonthDiffPct: diffPct(worst.avgIncome)
        )
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

        let incomeRows  = incomeBreakdown.map { (name: $0.category.displayName, amount: $0.amount, percent: $0.percent) }
        let monthlyRows = monthlyData.map { (label: $0.monthLabel, income: $0.income, expenses: $0.expenses) }

        exportedPDFData = FineryPDFGenerator().generate(data: .init(
            periodLabel: periodLabel, income: totalIncome, expenses: totalExpenses,
            taxAmount: totalTax, netProfit: netProfit,
            incomeBreakdown: incomeRows, monthlyData: monthlyRows
        ))
        showingPDFShare = exportedPDFData != nil
    }

    // MARK: - Client income (7.1)

    private func computeClientIncome(from transactions: [Transaction]) -> [(clientName: String, amount: Decimal, percent: Double)] {
        let income = transactions.filter { $0.direction == .income && $0.clientId != nil }
        let total  = income.reduce(Decimal(0)) { $0 + $1.amount }
        guard total > 0 else { return [] }

        let clients = SharedDataService.shared.cachedClients
        let grouped = Dictionary(grouping: income, by: { $0.clientId! })
        return grouped.map { cid, txns in
            let name   = clients.first(where: { $0.id == cid })?.name ?? txns.first?.description ?? "Клиент"
            let amount = txns.reduce(Decimal(0)) { $0 + $1.amount }
            return (clientName: name, amount: amount,
                    percent: NSDecimalNumber(decimal: amount / total * 100).doubleValue)
        }
        .sorted { $0.amount > $1.amount }
        .prefix(5)
        .map { $0 }
    }

    // MARK: - Forecast (7.2) — average of last 3 completed months

    private func computeForecast() -> Decimal? {
        let cal = Calendar.current
        let today = Date()
        var monthlyTotals: [Decimal] = []

        for offset in 1...3 {
            guard let start = cal.date(byAdding: .month, value: -offset, to: cal.date(from: cal.dateComponents([.year, .month], from: today))!),
                  let end   = cal.date(byAdding: .second, value: -1, to: cal.date(byAdding: .month, value: 1, to: start)!)
            else { continue }

            let total = SharedDataService.shared.transactions
                .filter { $0.direction == .income && $0.date >= start && $0.date <= end }
                .reduce(Decimal(0)) { $0 + $1.amount }
            monthlyTotals.append(total)
        }

        guard !monthlyTotals.isEmpty else { return nil }
        return monthlyTotals.reduce(0, +) / Decimal(monthlyTotals.count)
    }

    // MARK: - CSV Export (7.3)

    func generateCSV() -> String {
        var rows = ["Дата,Тип,Категория,Описание,Сумма,Клиент"]
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        for tx in SharedDataService.shared.transactions.sorted(by: { $0.date > $1.date }) {
            let date     = fmt.string(from: tx.date)
            let type_    = tx.direction == .income ? "Доход" : "Расход"
            let category = tx.direction == .income
                ? (tx.incomeCategory?.displayName  ?? "")
                : (tx.expenseCategory?.displayName ?? "")
            let desc     = tx.description.replacingOccurrences(of: ",", with: ";")
            let amount   = NSDecimalNumber(decimal: tx.amount).stringValue
            let client   = SharedDataService.shared.cachedClients.first(where: { $0.id == tx.clientId })?.name ?? ""
            rows.append("\(date),\(type_),\(category),\(desc),\(amount),\(client)")
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - Breakdown helpers

    private func breakdown(from transactions: [Transaction]) -> [(category: IncomeCategory, amount: Decimal, percent: Double)] {
        let total = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        guard total > 0 else { return [] }
        return Dictionary(grouping: transactions, by: { $0.incomeCategory ?? .other })
            .map { cat, txns in
                let amount = txns.reduce(Decimal(0)) { $0 + $1.amount }
                return (category: cat, amount: amount,
                        percent: NSDecimalNumber(decimal: amount / total * 100).doubleValue)
            }
            .sorted { $0.amount > $1.amount }
    }

    private func expenseBreakdownCalc(from transactions: [Transaction]) -> [(category: ExpenseCategory, amount: Decimal, percent: Double)] {
        let total = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        guard total > 0 else { return [] }
        return Dictionary(grouping: transactions, by: { $0.expenseCategory ?? .other })
            .map { cat, txns in
                let amount = txns.reduce(Decimal(0)) { $0 + $1.amount }
                return (category: cat, amount: amount,
                        percent: NSDecimalNumber(decimal: amount / total * 100).doubleValue)
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
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: tx, userRepository: usr, taxCalculator: calc)
        )
        vm.monthlyData = PreviewData.monthlyData
        return vm
    }
}
