import Foundation

struct GetInsightsUseCase: Sendable {
    let transactionRepository: any TransactionRepository
    let userRepository: any UserRepository
    let taxCalculator: TaxCalculatorService

    func execute(referenceDate: Date = Date()) async throws -> [Insight] {
        let calendar = Calendar.current
        let user = try await userRepository.fetchUser() ?? User()

        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate))!
        let startOfNext  = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let endOfMonth   = calendar.date(byAdding: .second, value: -1, to: startOfNext)!

        let year = calendar.component(.year, from: referenceDate)
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear   = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!

        let startOfPrevMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
        let endOfPrevMonth   = calendar.date(byAdding: .second, value: -1, to: startOfMonth)!

        async let monthTxns    = transactionRepository.fetch(from: startOfMonth, to: endOfMonth)
        async let yearTxns     = transactionRepository.fetch(from: startOfYear, to: endOfYear)
        async let prevMonthTxns = transactionRepository.fetch(from: startOfPrevMonth, to: endOfPrevMonth)
        let (thisMonth, allYear, prevMonth) = try await (monthTxns, yearTxns, prevMonthTxns)

        var insights: [Insight] = []

        // Tax deadline
        let deadline = taxCalculator.nextDeadline(for: referenceDate)
        let daysLeft = calendar.dateComponents([.day], from: referenceDate, to: deadline).day ?? 0
        if daysLeft <= 7 {
            let tax = taxCalculator.calculateTax(for: thisMonth, mode: user.taxMode)
            insights.append(Insight(
                type: .taxDeadline,
                title: "Дедлайн налога",
                body: "Налог \(formatRub(tax)) нужно оплатить через \(daysLeft) дн.",
                severity: daysLeft <= 3 ? .critical : .warning
            ))
        }

        // NPD limit warning
        if user.taxMode == .npd {
            let yearlyIncome = allYear
                .filter { $0.direction == .income }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let pct = NSDecimalNumber(decimal: yearlyIncome / TaxStatus.npdYearLimit * 100).doubleValue
            if pct >= 80 {
                insights.append(Insight(
                    type: .limitWarning,
                    title: "Лимит НПД",
                    body: "Ты использовал \(Int(pct))% лимита. Пора открывать ИП.",
                    severity: pct >= 95 ? .critical : .warning
                ))
            }
        }

        // Income growth vs previous month
        let curIncome  = thisMonth.filter { $0.direction == .income }.reduce(Decimal(0)) { $0 + $1.amount }
        let prevIncome = prevMonth.filter { $0.direction == .income }.reduce(Decimal(0)) { $0 + $1.amount }
        if prevIncome > 0 && curIncome > prevIncome {
            let growthPct = NSDecimalNumber(decimal: (curIncome - prevIncome) / prevIncome * 100).intValue
            insights.append(Insight(
                type: .incomeGrowth,
                title: "Рост дохода",
                body: "Доход в этом месяце на \(growthPct)% выше прошлого.",
                severity: .info
            ))
        }

        // Concentration risk
        if curIncome > 0 {
            let byCategory = Dictionary(grouping: thisMonth.filter { $0.direction == .income }, by: {
                $0.incomeCategory ?? .other
            })
            for (category, txns) in byCategory {
                let total = txns.reduce(Decimal(0)) { $0 + $1.amount }
                let share = NSDecimalNumber(decimal: total / curIncome * 100).intValue
                if share >= 70 {
                    insights.append(Insight(
                        type: .concentrationRisk,
                        title: "Концентрация дохода",
                        body: "\(share)% дохода из одного источника (\(category.displayName)) — высокий риск.",
                        severity: .warning
                    ))
                    break
                }
            }
        }

        // Low margin warning
        let expenses = thisMonth.filter { $0.direction == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        if curIncome > 0 {
            let tax = taxCalculator.calculateTax(for: thisMonth, mode: user.taxMode)
            let netProfit = curIncome - expenses - tax
            let margin = NSDecimalNumber(decimal: netProfit / curIncome * 100).doubleValue
            if margin < 40 {
                insights.append(Insight(
                    type: .lowMargin,
                    title: "Низкая маржа",
                    body: "Маржа \(Int(margin))% — ниже нормы для фрилансеров (60–80%).",
                    severity: .warning
                ))
            }
        }

        return insights
    }

    private func formatRub(_ amount: Decimal) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        let str = fmt.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        return "\(str) ₽"
    }
}
