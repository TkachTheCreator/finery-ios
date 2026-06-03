import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var container: AppContainer?
    @State private var showOnboarding = false
    @State private var showAddTransaction = false

    var body: some View {
        Group {
            if let c = container {
                mainTabView(c)
                    .sheet(isPresented: $showOnboarding) {
                        OnboardingView { user in
                            Task {
                                try? await c.userRepository.saveUser(user)
                                UserDefaults.standard.set(true, forKey: "finery_onboarding_done")
                                showOnboarding = false
                                await c.dashboard.load()
                            }
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
            } else {
                FC.background.ignoresSafeArea()
                    .task { await boot() }
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
    }

    // MARK: Boot

    private func boot() async {
        let c = AppContainer(modelContext: modelContext)
        container = c

        let onboardingDone = UserDefaults.standard.bool(forKey: "finery_onboarding_done")
        if !onboardingDone {
            showOnboarding = true
        } else {
            await c.dashboard.load()
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(for: [TransactionEntity.self, UserEntity.self], inMemory: true)
}
