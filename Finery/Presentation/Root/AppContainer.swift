import Foundation
import SwiftData
import Observation

/// Single dependency graph. Created once at startup.
@Observable
@MainActor
final class AppContainer {

    let auth:         AuthViewModel
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

        // Store-backed repository: reads from in-memory TransactionStore (loaded from API),
        // writes through to SwiftData for offline cache.
        let storeRepo = StoreBackedTransactionRepository(local: txRepo)

        transactionRepository = storeRepo
        userRepository        = usrRepo

        auth = AuthViewModel(userRepository: usrRepo)

        dashboard = DashboardViewModel(
            getPnL:       GetPnLUseCase(transactionRepository: storeRepo, userRepository: usrRepo, taxCalculator: calc),
            calculateTax: CalculateTaxUseCase(transactionRepository: storeRepo, userRepository: usrRepo, taxCalculator: calc),
            getInsights:  GetInsightsUseCase(transactionRepository: storeRepo, userRepository: usrRepo, taxCalculator: calc),
            transactionRepository: storeRepo,
            userRepository: usrRepo
        )

        transactions = TransactionsViewModel(transactionRepository: storeRepo)

        analytics = AnalyticsViewModel(
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: storeRepo, userRepository: usrRepo, taxCalculator: calc),
            transactionRepository: storeRepo,
            userRepository: usrRepo
        )

        tax = TaxViewModel(
            calculateTax:       CalculateTaxUseCase(transactionRepository: storeRepo, userRepository: usrRepo, taxCalculator: calc),
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: storeRepo, userRepository: usrRepo, taxCalculator: calc),
            transactionRepository: storeRepo,
            userRepository: usrRepo
        )

        settings = SettingsViewModel(userRepository: usrRepo)
    }
}
