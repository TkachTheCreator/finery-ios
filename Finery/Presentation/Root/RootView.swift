import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var container: AppContainer?
    @State private var showLogin = false
    @State private var showSplash = true
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(onFinish: { showSplash = false })
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal:   .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .zIndex(2)
            } else if let c = container {
                TabView(selection: $selectedTab) {
                    DashboardView(viewModel: c.dashboard)
                        .tabItem { Label("Главная", systemImage: "house") }
                        .tag(0)
                    TransactionsView(viewModel: c.transactions)
                        .tabItem { Label("Операции", systemImage: "list.bullet") }
                        .tag(1)
                    AnalyticsView(viewModel: c.analytics)
                        .tabItem { Label("Аналитика", systemImage: "chart.bar") }
                        .tag(2)
                    TaxView(viewModel: c.tax)
                        .tabItem { Label("Налоги", systemImage: "percent") }
                        .tag(3)
                    SettingsView(viewModel: c.settings)
                        .tabItem { Label("Настройки", systemImage: "gearshape") }
                        .tag(4)
                }
                .tint(FC.cobalt)
                .onChange(of: selectedTab) { _, _ in HapticManager.light() }
                .zIndex(1)
                .fullScreenCover(isPresented: $showLogin) {
                    LoginView(viewModel: c.auth) {
                        showLogin = false
                        Task { await c.dashboard.load() }
                    }
                }
                .onChange(of: c.dashboard.needsAuth) { _, needed in
                    if needed { showLogin = true }
                }
            } else {
                Color(h: "F5EFE0").ignoresSafeArea()
                    .onAppear { boot() }
                    .zIndex(0)
            }
        }
        .animation(.fineryPage, value: showSplash)
        .fontDesign(.rounded)
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

#Preview {
    RootView()
        .modelContainer(for: [TransactionEntity.self, UserEntity.self], inMemory: true)
}
