import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var appLock = AppLockManager.shared
    @State private var container: AppContainer?
    @State private var phase: Phase = .splash
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
    @State private var selectedTab: FineryTab = .dashboard
    @State private var goingRight = true

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
            if appLock.isLocked {
                LockScreenView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appLock.isLocked)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                appLock.lockIfNeeded()
            } else if phase == .active {
                checkClipboard()
            }
        }
        .animation(.fineryPage, value: phase)
        .fontDesign(.rounded)
        .onChange(of: SharedDataService.shared.isLoggedOut) { _, loggedOut in
            if loggedOut {
                let expired = SharedDataService.shared.sessionExpiredMessage != nil
                withAnimation(.fineryPage) { phase = expired ? .login : .welcome }
                selectedTab = .dashboard
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

    // MARK: Main TabView (custom with directional transitions)

    private func mainTabView(c: AppContainer) -> some View {
        ZStack(alignment: .bottom) {
            // Content
            ZStack {
                tabSlide { DashboardView(viewModel: c.dashboard) }
                    .opacity(selectedTab == .dashboard ? 1 : 0)

                if selectedTab == .transactions {
                    TransactionsView(viewModel: c.transactions)
                        .transition(slideTransition)
                }
                if selectedTab == .analytics {
                    AnalyticsView(viewModel: c.analytics)
                        .transition(slideTransition)
                }
                if selectedTab == .clients {
                    ClientsView(viewModel: c.clients)
                        .transition(slideTransition)
                }
                if selectedTab == .tax {
                    TaxView(viewModel: c.tax)
                        .transition(slideTransition)
                }
                if selectedTab == .settings {
                    SettingsView(viewModel: c.settings)
                        .transition(slideTransition)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)

            // Floating tab bar
            FloatingTabBar(selection: Binding(
                get: { selectedTab },
                set: { selectTab($0) }
            ))
            .padding(.bottom, 20)

            // AI FAB — above the tab bar on the left, visible only on Dashboard
            if selectedTab == .dashboard {
                HStack {
                    Button { showChat = true } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(FC.cobalt)
                            .clipShape(Circle())
                            .shadow(color: FC.cobalt.opacity(0.35), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 104)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
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
        .onChange(of: selectedTab) { previous, current in
            // Reload Dashboard only when returning from Settings (tax mode may have changed)
            if current == .dashboard && previous == .settings {
                SharedDataService.shared.invalidate()
                Task { await c.dashboard.load() }
            }
        }
        .sheet(isPresented: $showChat) {
            AIAdvisorView()
        }
    }

    private var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: goingRight ? .trailing : .leading),
            removal:   .move(edge: goingRight ? .leading  : .trailing)
        )
    }

    private func selectTab(_ tab: FineryTab) {
        guard tab != selectedTab else { return }
        goingRight = tab.rawValue > selectedTab.rawValue
        HapticManager.light()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            selectedTab = tab
        }
    }

    @ViewBuilder
    private func tabSlide<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
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
