import Foundation

enum PreviewData {

    static let user = User(
        name: "Алекс",
        taxMode: .npd,
        userType: .blogger
    )

    static let transactions: [Transaction] = [
        Transaction(
            amount: 45_000,
            direction: .income,
            description: "Boosty подписки за май",
            date: ymd(2026, 6, 1),
            source: .boosty,
            incomeCategory: .boosty,
            clientType: .individual,
            createdAt: ymd(2026, 6, 1)
        ),
        Transaction(
            amount: 12_500,
            direction: .income,
            description: "Донаты со стрима 29 мая",
            date: ymd(2026, 5, 29),
            source: .donationAlerts,
            incomeCategory: .donations,
            clientType: .individual,
            createdAt: ymd(2026, 5, 29)
        ),
        Transaction(
            amount: 80_000,
            direction: .income,
            description: "Рекламная интеграция TechBrand",
            date: ymd(2026, 5, 20),
            source: .bank,
            incomeCategory: .advertising,
            clientType: .legal,
            createdAt: ymd(2026, 5, 20)
        ),
        Transaction(
            amount: 35_000,
            direction: .income,
            description: "YouTube AdSense май",
            date: ymd(2026, 5, 15),
            source: .bank,
            incomeCategory: .platforms,
            clientType: .legal,
            createdAt: ymd(2026, 5, 15)
        ),
        Transaction(
            amount: 8_900,
            direction: .expense,
            description: "Adobe Creative Cloud",
            date: ymd(2026, 5, 5),
            source: .bank,
            expenseCategory: .tools,
            createdAt: ymd(2026, 5, 5)
        ),
        Transaction(
            amount: 25_000,
            direction: .expense,
            description: "Выплата монтажёру за май",
            date: ymd(2026, 5, 1),
            source: .bank,
            expenseCategory: .team,
            createdAt: ymd(2026, 5, 1)
        ),
        Transaction(
            amount: 60_000,
            direction: .income,
            description: "Проект: разработка лендинга",
            date: ymd(2026, 4, 28),
            source: .bank,
            incomeCategory: .freelance,
            clientType: .legal,
            createdAt: ymd(2026, 4, 28)
        ),
    ]

    static let monthlyData: [MonthlyData] = [
        MonthlyData(month: ymd(2026, 1, 1), income: 120_000, expenses: 35_000, taxAmount: 4_800),
        MonthlyData(month: ymd(2026, 2, 1), income:  95_000, expenses: 28_000, taxAmount: 3_800),
        MonthlyData(month: ymd(2026, 3, 1), income: 145_000, expenses: 40_000, taxAmount: 5_800),
        MonthlyData(month: ymd(2026, 4, 1), income: 110_000, expenses: 32_000, taxAmount: 4_400),
        MonthlyData(month: ymd(2026, 5, 1), income: 172_500, expenses: 33_900, taxAmount: 6_900),
        MonthlyData(month: ymd(2026, 6, 1), income:  45_000, expenses:      0, taxAmount: 1_800),
    ]

    static let taxStatus = TaxStatus(
        taxMode: .npd,
        yearlyIncome: 687_500,
        taxDue: 8_700,
        taxPaid: 25_700,
        nextDeadline: ymd(2026, 7, 28),
        yearLimit: TaxStatus.npdYearLimit
    )

    static let insights: [Insight] = [
        Insight(
            type: .taxDeadline,
            title: "Дедлайн налога",
            body: "Налог 8 700 ₽ нужно оплатить через 5 дней.",
            severity: .warning
        ),
        Insight(
            type: .incomeGrowth,
            title: "Рост дохода",
            body: "Доход в этом месяце на 57% выше прошлого.",
            severity: .info
        ),
    ]

    private static func ymd(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
