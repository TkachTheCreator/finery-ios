import Foundation
import SwiftData
import Observation

/// Единая точка сборки зависимостей. Создаётся один раз при старте приложения.
@Observable
@MainActor
final class AppContainer {

    let dashboard:    DashboardViewModel
    let transactions: TransactionsViewModel
    let analytics:    AnalyticsViewModel
    let tax:          TaxViewModel
    let settings:     SettingsViewModel

    let transactionRepository: any TransactionRepository
    let userRepository:        any UserRepository

    init(modelContext: ModelContext) {
        let txRepo  = TransactionLocalRepository(modelContext: modelContext)
        let usrRepo = UserLocalRepository(modelContext: modelContext)
        let calc    = TaxCalculatorService()

        transactionRepository = txRepo
        userRepository        = usrRepo

        dashboard = DashboardViewModel(
            getPnL:       GetPnLUseCase(transactionRepository: txRepo, userRepository: usrRepo, taxCalculator: calc),
            calculateTax: CalculateTaxUseCase(transactionRepository: txRepo, userRepository: usrRepo, taxCalculator: calc),
            getInsights:  GetInsightsUseCase(transactionRepository: txRepo, userRepository: usrRepo, taxCalculator: calc),
            transactionRepository: txRepo,
            userRepository: usrRepo
        )

        transactions = TransactionsViewModel(transactionRepository: txRepo)

        analytics = AnalyticsViewModel(
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: txRepo, userRepository: usrRepo, taxCalculator: calc),
            transactionRepository: txRepo,
            userRepository: usrRepo
        )

        tax = TaxViewModel(
            calculateTax:      CalculateTaxUseCase(transactionRepository: txRepo, userRepository: usrRepo, taxCalculator: calc),
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: txRepo, userRepository: usrRepo, taxCalculator: calc)
        )

        settings = SettingsViewModel(userRepository: usrRepo)
    }
}
