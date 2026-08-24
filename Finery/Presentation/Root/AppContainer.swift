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
    let clients:      ClientsViewModel
    let tax:          TaxViewModel
    let settings:     SettingsViewModel
    let invoices:     InvoicesViewModel

    let transactionRepository: any TransactionRepository
    let userRepository:        any UserRepository

    init(modelContext: ModelContext) {
        let txRepo  = TransactionLocalRepository(modelContext: modelContext)
        let usrRepo = UserLocalRepository(modelContext: modelContext)
        let calc    = TaxCalculatorService()

        // Store-backed repo: read from in-memory TransactionStore (synced by SharedDataService),
        // write-through to SwiftData for offline cache.
        let storeRepo = StoreBackedTransactionRepository(local: txRepo)

        transactionRepository = storeRepo
        userRepository        = usrRepo

        auth = AuthViewModel(userRepository: usrRepo)

        dashboard = DashboardViewModel(
            getInsights:          GetInsightsUseCase(transactionRepository: storeRepo, userRepository: usrRepo, taxCalculator: calc),
            transactionRepository: storeRepo
        )

        transactions = TransactionsViewModel(transactionRepository: storeRepo)

        analytics = AnalyticsViewModel(
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: storeRepo, userRepository: usrRepo, taxCalculator: calc)
        )

        tax = TaxViewModel(
            getMonthlyDynamics:   GetMonthlyDynamicsUseCase(transactionRepository: storeRepo, userRepository: usrRepo, taxCalculator: calc),
            transactionRepository: storeRepo,
            userRepository:        usrRepo
        )

        settings = SettingsViewModel(userRepository: usrRepo)
        clients  = ClientsViewModel(transactionRepository: storeRepo)
        invoices = InvoicesViewModel()
    }
}
