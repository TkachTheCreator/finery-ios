import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var container: AppContainer?
    @State private var showLogin = false
    @State private var showSplash = true
    @State private var selectedTab: FineryTab = .dashboard
    @State private var previousTab: FineryTab = .dashboard

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
                mainView(c)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal:   .opacity
                        )
                    )
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

    // MARK: Main Layout

    private func mainView(_ c: AppContainer) -> some View {
        let forward = selectedTab.rawValue > previousTab.rawValue
        let tabBinding = Binding<FineryTab>(
            get: { selectedTab },
            set: { newTab in
                guard newTab != selectedTab else { return }
                HapticManager.light()
                previousTab = selectedTab
                selectedTab = newTab
            }
        )
        return ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(viewModel: c.dashboard)
                        .transition(tabTransition(forward: forward))
                case .transactions:
                    TransactionsView(viewModel: c.transactions)
                        .transition(tabTransition(forward: forward))
                case .analytics:
                    AnalyticsView(viewModel: c.analytics)
                        .transition(tabTransition(forward: forward))
                case .tax:
                    TaxView(viewModel: c.tax)
                        .transition(tabTransition(forward: forward))
                case .settings:
                    SettingsView(viewModel: c.settings)
                        .transition(tabTransition(forward: forward))
                }
            }
            .id(selectedTab)
            .animation(.spring(response: 0.40, dampingFraction: 0.84), value: selectedTab)

            FloatingTabBar(selection: tabBinding)
                .padding(.bottom, 20)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func tabTransition(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal:   .move(edge: forward ? .leading  : .trailing).combined(with: .opacity)
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

#Preview {
    RootView()
        .modelContainer(for: [TransactionEntity.self, UserEntity.self], inMemory: true)
}
