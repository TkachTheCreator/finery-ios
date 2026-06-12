import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var container: AppContainer?
    @State private var showLogin = false
    @State private var showAddTransaction = false

    var body: some View {
        Group {
            if let c = container {
                mainTabView(c)
                    .fullScreenCover(isPresented: $showLogin) {
                        LoginView(viewModel: c.auth) {
                            showLogin = false
                            Task { await c.dashboard.load() }
                        }
                    }
                    .sheet(isPresented: $showAddTransaction) {
                        AddTransactionView(
                            viewModel: AddTransactionViewModel(
                                transactionRepository: c.transactionRepository
                            ),
                            onSave: {
                                Task {
                                    await c.dashboard.load()
                                    await c.transactions.load()
                                }
                            }
                        )
                    }
                    .onChange(of: c.dashboard.needsAuth) { _, needed in
                        if needed { showLogin = true }
                    }
            } else {
                FC.background.ignoresSafeArea()
                    .onAppear { boot() }
            }
        }
    }

    // MARK: Tab View

    private func mainTabView(_ c: AppContainer) -> some View {
        TabView {
            DashboardView(viewModel: c.dashboard)
                .tabItem { Label("Главная", systemImage: "house") }

            TransactionsView(viewModel: c.transactions)
                .tabItem { Label("Транзакции", systemImage: "list.bullet") }

            AnalyticsView(viewModel: c.analytics)
                .tabItem { Label("Аналитика", systemImage: "chart.bar") }

            TaxView(viewModel: c.tax)
                .tabItem { Label("Налоги", systemImage: "percent") }

            SettingsView(viewModel: c.settings)
                .tabItem { Label("Настройки", systemImage: "gearshape") }
        }
        .tint(FC.cobalt)
        .preferredColorScheme(.dark)
    }

    // MARK: Boot

    private func boot() {
        let c = AppContainer(modelContext: modelContext)
        container = c

        if !APIClient.shared.isAuthenticated {
            showLogin = true
            return
        }
        Task { await c.dashboard.load() }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(for: [TransactionEntity.self, UserEntity.self], inMemory: true)
}
