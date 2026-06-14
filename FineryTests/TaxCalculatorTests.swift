import Testing
import Foundation
@testable import Finery

struct TaxCalculatorTests {

    // НПД 4% с физлица
    @Test func npd_individual_4percent() {
        let calc = TaxCalculatorService()
        let txns = [Transaction(amount: 100_000, direction: .income,
                                description: "Донат", date: Date(),
                                source: .manual, clientType: .individual)]
        let tax = calc.calculateTax(for: txns, mode: .npd)
        #expect(tax == 4_000)
    }

    // НПД 6% с юрлица
    @Test func npd_business_6percent() {
        let calc = TaxCalculatorService()
        let txns = [Transaction(amount: 100_000, direction: .income,
                                description: "Реклама", date: Date(),
                                source: .bank, clientType: .legal)]
        let tax = calc.calculateTax(for: txns, mode: .npd)
        #expect(tax == 6_000)
    }

    // УСН 6% со всех доходов
    @Test func usn6_all_income() {
        let calc = TaxCalculatorService()
        let txns = [Transaction(amount: 200_000, direction: .income,
                                description: "Проект", date: Date(),
                                source: .bank, clientType: .legal)]
        let tax = calc.calculateTax(for: txns, mode: .usn6)
        #expect(tax == 12_000)
    }

    // УСН 15% с прибыли
    @Test func usn15_profit() {
        let calc = TaxCalculatorService()
        let txns = [
            Transaction(amount: 200_000, direction: .income,
                        description: "Доход", date: Date(), source: .bank),
            Transaction(amount: 50_000, direction: .expense,
                        description: "Расход", date: Date(), source: .manual)
        ]
        let tax = calc.calculateTax(for: txns, mode: .usn15)
        #expect(tax == 22_500) // (200k - 50k) * 15%
    }

    // НПД лимит — предупреждение при 80%+
    @Test func npd_limit_warning() {
        let status = TaxStatus(
            taxMode: .npd,
            yearlyIncome: 2_000_000,
            quarterlyIncome: 500_000,
            quarterlyExpenses: 0,
            taxDue: 80_000,
            taxPaid: 0,
            nextDeadline: Date(),
            yearLimit: 2_400_000
        )
        #expect(status.isNearLimit == true)
        #expect(status.limitUsedPercent > 80)
    }

    // УСН — нет лимита
    @Test func usn_no_limit() {
        let status = TaxStatus(
            taxMode: .usn6,
            yearlyIncome: 5_000_000,
            quarterlyIncome: 1_500_000,
            quarterlyExpenses: 0,
            taxDue: 300_000,
            taxPaid: 0,
            nextDeadline: Date(),
            yearLimit: 0
        )
        #expect(status.showNpdLimit == false)
        #expect(status.limitUsedPercent == 0)
    }

    // Квартальный дедлайн УСН — должен быть 28 числа
    @Test func usn_quarterly_deadline_is_28th() {
        let calc = TaxCalculatorService()
        let deadline = calc.nextQuarterlyDeadline(for: Date())
        let day = Calendar.current.component(.day, from: deadline)
        #expect(day == 28)
    }

    // НПД месячный дедлайн — 28 следующего месяца
    @Test func npd_monthly_deadline_is_28th() {
        let calc = TaxCalculatorService()
        let deadline = calc.nextMonthlyDeadline(for: Date())
        let day = Calendar.current.component(.day, from: deadline)
        #expect(day == 28)
    }
}
