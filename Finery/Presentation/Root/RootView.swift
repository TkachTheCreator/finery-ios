import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var appLock = AppLockManager.shared
    @State private var container: AppContainer?
    @State private var phase: Phase = .splash
    @Namespace var zoomNS
    @State private var showReAuth = false
    @State private var showSessionExpiredAlert = false
    @State private var showChat            = false
    @State private var showAddTransaction  = false
    @State private var showVoiceInput      = false
    @State private var clipboardResult: BankSMSResult? = nil
    @State private var showClipboardBanner = false
    @State private var clipboardChangeCount = -1
    @State private var pendingClipboardVM: AddTransactionViewModel? = nil
    @State private var showClipboardAdd = false
    @State private var navPath = NavigationPath()
    @State private var showSettings = false

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
        .overlay(alignment: .top) {
            if showClipboardBanner, let result = clipboardResult, phase == .main {
                ClipboardTransactionBanner(
                    result: result,
                    onAdd: {
                        guard let c = container else { return }
                        let vm = AddTransactionViewModel(transactionRepository: c.transactionRepository)
                        let n = NSDecimalNumber(decimal: result.amount)
                        vm.amountText = n.decimalValue == Decimal(n.intValue) ? "\(n.intValue)" : n.stringValue
                        vm.setDirection(result.direction)
                        vm.description = result.description
                        pendingClipboardVM = vm
                        showClipboardBanner = false
                        showClipboardAdd = true
                    },
                    onDismiss: { showClipboardBanner = false }
                )
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(50)
            }
        }
        .overlay {
            if appLock.isLocked && phase == .main {
                LockScreenView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appLock.isLocked)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                appLock.didEnterBackground()
            } else if newPhase == .active {
                appLock.didBecomeActive()
                checkClipboard()
                checkControlCenterFlag()
            }
        }
        .animation(.fineryPage, value: phase)
        .fontDesign(.rounded)
        // Намеренное решение: приложение работает только в светлой теме, вся дизайн-система
        // (Mercury-палитра) построена под светлый режим. Dark Mode не поддерживается по дизайну, не баг.
        .preferredColorScheme(.light)
        .onChange(of: SharedDataService.shared.isLoggedOut) { _, loggedOut in
            if loggedOut {
                let expired = SharedDataService.shared.sessionExpiredMessage != nil
                navPath = NavigationPath()
                withAnimation(.fineryPage) { phase = expired ? .login : .welcome }
                if expired { showSessionExpiredAlert = true }
            }
        }
        .alert("Сессия истекла", isPresented: $showSessionExpiredAlert) {
            Button("Войти снова", role: .cancel) {}
        } message: {
            Text(SharedDataService.shared.sessionExpiredMessage ?? "")
        }
        .onOpenURL { url in
            guard url.scheme == "finery", phase == .main else { return }
            switch url.host {
            case "add-transaction": showAddTransaction = true
            case "voice":           showVoiceInput     = true
            default: break
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            if let c = container {
                AddTransactionView(
                    viewModel: AddTransactionViewModel(
                        transactionRepository: c.transactionRepository
                    )
                )
            }
        }
        .sheet(isPresented: $showVoiceInput) {
            if let c = container {
                AddTransactionView(
                    viewModel: AddTransactionViewModel(
                        transactionRepository: c.transactionRepository
                    ),
                    autoStartVoice: true
                )
            }
        }
        .sheet(isPresented: $showClipboardAdd) {
            if let vm = pendingClipboardVM {
                AddTransactionView(viewModel: vm) {
                    pendingClipboardVM = nil
                }
            }
        }
    }

    // MARK: - Navigation Routes

    private enum FineryRoute: Hashable {
        case tax
        case clients
        case transactions
        case analyticsDynamics
        case analyticsCategories
        case tips
    }

    // MARK: - Main App (NavigationStack, no tab bar)

    private func mainTabView(c: AppContainer) -> some View {
        NavigationStack(path: $navPath) {
            DashboardView(
                viewModel: c.dashboard,
                onShowSettings: { showSettings = true },
                onShowTax: { navPath.append(FineryRoute.tax) },
                onShowAI: { showChat = true },
                onShowClients: { navPath.append(FineryRoute.clients) },
                onShowAddTransaction: { showAddTransaction = true },
                onShowAnalyticsDynamics: { navPath.append(FineryRoute.analyticsDynamics) },
                onShowAnalyticsCategories: { navPath.append(FineryRoute.analyticsCategories) },
                onShowTips: { navPath.append(FineryRoute.tips) },
                zoomNamespace: zoomNS
            )
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: FineryRoute.self) { route in
                switch route {
                case .tax:
                    TaxView(viewModel: c.tax)
                        .navigationTitle("")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTransition(.zoom(sourceID: "tax", in: zoomNS))
                case .clients:
                    ClientsView(viewModel: c.clients)
                        .navigationTitle("")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTransition(.zoom(sourceID: "clients", in: zoomNS))
                case .transactions:
                    TransactionsView(viewModel: c.transactions)
                        .navigationTitle("")
                        .navigationBarTitleDisplayMode(.inline)
                case .analyticsDynamics:
                    AnalyticsDynamicsView(viewModel: c.analytics)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTransition(.zoom(sourceID: "dynamics", in: zoomNS))
                case .analyticsCategories:
                    AnalyticsCategoriesView(viewModel: c.analytics)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTransition(.zoom(sourceID: "categories", in: zoomNS))
                case .tips:
                    TipsListView(insights: c.dashboard.insights, onShowAI: { showChat = true })
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTransition(.zoom(sourceID: "tips", in: zoomNS))
                }
            }
        }
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
        .sheet(isPresented: $showSettings, onDismiss: {
            SharedDataService.shared.invalidate()
            Task { await c.dashboard.load() }
        }) {
            SettingsView(viewModel: c.settings)
        }
        .sheet(isPresented: $showChat) {
            AIAdvisorView()
        }
    }

    // MARK: Control Center flag check

    private func checkControlCenterFlag() {
        guard phase == .main else { return }
        let ud = UserDefaults(suiteName: "group.com.tkachev.finery")
        guard ud?.bool(forKey: "shouldShowAddTransaction") == true else { return }
        ud?.set(false, forKey: "shouldShowAddTransaction")
        showAddTransaction = true
    }

    // MARK: Clipboard bank SMS check

    private func checkClipboard() {
        guard phase == .main else { return }
        let count = UIPasteboard.general.changeCount
        guard count != clipboardChangeCount else { return }
        clipboardChangeCount = count
        guard let text = UIPasteboard.general.string,
              let result = BankSMSParser.parse(text) else { return }
        clipboardResult = result
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showClipboardBanner = true
        }
        // Auto-hide after 8 seconds
        Task {
            try? await Task.sleep(for: .seconds(8))
            withAnimation { showClipboardBanner = false }
        }
    }

    // MARK: Boot

    private func boot() {
        if container == nil {
            container = AppContainer(modelContext: modelContext)
        }
        guard let c = container else { return }

        // Show cached data instantly while network loads
        SharedDataService.shared.loadCached()

        let welcomeSeen = UserDefaults.standard.bool(forKey: "finery_welcome_seen")

        if APIClient.shared.isAuthenticated {
            appLock.lockOnLaunch()
            phase = .main
            Task { await c.dashboard.load() }
            Task { await RecurringTransactionService.shared.processIfNeeded(repository: c.transactionRepository) }
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
