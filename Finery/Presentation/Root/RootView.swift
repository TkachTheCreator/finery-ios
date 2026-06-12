import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var container: AppContainer?
    @State private var showLogin = false
    @State private var showAddTransaction = false
    @State private var selectedTab: FineryTab = .dashboard

    var body: some View {
        Group {
            if let c = container {
                mainView(c)
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
        .preferredColorScheme(.dark)
    }

    // MARK: Main Layout

    private func mainView(_ c: AppContainer) -> some View {
        ZStack(alignment: .bottom) {
            // Page content — switch without TabView to control transitions
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(viewModel: c.dashboard)
                        .transition(pageTransition)
                case .transactions:
                    TransactionsView(viewModel: c.transactions)
                        .transition(pageTransition)
                case .analytics:
                    AnalyticsView(viewModel: c.analytics)
                        .transition(pageTransition)
                case .tax:
                    TaxView(viewModel: c.tax)
                        .transition(pageTransition)
                case .settings:
                    SettingsView(viewModel: c.settings)
                        .transition(pageTransition)
                }
            }
            .id(selectedTab)   // force view replacement for transition
            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selectedTab)

            // Floating tab bar
            FloatingTabBar(selection: $selectedTab)
                .padding(.bottom, 20)
                .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom).animation(.spring(response: 0.4, dampingFraction: 0.85))),
            removal:   .opacity.animation(.easeIn(duration: 0.12))
        )
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
