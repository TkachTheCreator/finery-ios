import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var container: AppContainer?
    @State private var phase: Phase = .splash
    @State private var showReAuth = false
    @State private var selectedTab: Int = 0

    private enum Phase: Equatable {
        case splash, welcome, register, login, main
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            // Splash
            if phase == .splash {
                SplashView(onFinish: { boot() })
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal:   .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(10)
            }

            // Welcome stays visible while register/login slide over it
            if phase == .welcome || phase == .register || phase == .login {
                WelcomeView(
                    onRegister: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            phase = .register
                        }
                    },
                    onLogin: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            phase = .login
                        }
                    }
                )
                .zIndex(1)
            }

            // Auth — register
            if phase == .register, let c = container {
                AuthFlowView(
                    isRegistering: true,
                    viewModel: c.auth,
                    onSuccess: {
                        UserDefaults.standard.set(true, forKey: "finery_welcome_seen")
                        withAnimation(.fineryPage) { phase = .main }
                        Task { await c.dashboard.load() }
                    },
                    onBack: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            phase = .welcome
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(2)
            }

            // Auth — login
            if phase == .login, let c = container {
                AuthFlowView(
                    isRegistering: false,
                    viewModel: c.auth,
                    onSuccess: {
                        UserDefaults.standard.set(true, forKey: "finery_welcome_seen")
                        withAnimation(.fineryPage) { phase = .main }
                        Task { await c.dashboard.load() }
                    },
                    onBack: {
                        let seen = UserDefaults.standard.bool(forKey: "finery_welcome_seen")
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            phase = seen ? .login : .welcome
                        }
                        // if already seen welcome — no back, just stay (onBack won't be called)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(2)
            }

            // Main app
            if phase == .main, let c = container {
                mainTabView(c: c)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.fineryPage, value: phase)
        .fontDesign(.rounded)
    }

    // MARK: Main TabView

    private func mainTabView(c: AppContainer) -> some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: c.dashboard)
                .tabItem { Label("Главная",   systemImage: "house") }
                .tag(0)
            TransactionsView(viewModel: c.transactions)
                .tabItem { Label("Операции",  systemImage: "list.bullet") }
                .tag(1)
            AnalyticsView(viewModel: c.analytics)
                .tabItem { Label("Аналитика", systemImage: "chart.bar") }
                .tag(2)
            TaxView(viewModel: c.tax)
                .tabItem { Label("Налоги",    systemImage: "percent") }
                .tag(3)
            SettingsView(viewModel: c.settings)
                .tabItem { Label("Настройки", systemImage: "gearshape") }
                .tag(4)
        }
        .tint(FC.cobalt)
        .onChange(of: selectedTab) { _, _ in HapticManager.light() }
        .fullScreenCover(isPresented: $showReAuth) {
            if let c = container {
                AuthFlowView(
                    isRegistering: false,
                    viewModel: c.auth,
                    onSuccess: {
                        showReAuth = false
                        Task { await c.dashboard.load() }
                    }
                )
            }
        }
        .onChange(of: c.dashboard.needsAuth) { _, needed in
            if needed { showReAuth = true }
        }
    }

    // MARK: Boot

    private func boot() {
        if container == nil {
            container = AppContainer(modelContext: modelContext)
        }
        guard let c = container else { return }

        let welcomeSeen = UserDefaults.standard.bool(forKey: "finery_welcome_seen")

        if APIClient.shared.isAuthenticated {
            phase = .main
            Task { await c.dashboard.load() }
        } else if welcomeSeen {
            phase = .login
        } else {
            phase = .welcome
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [TransactionEntity.self, UserEntity.self], inMemory: true)
}
