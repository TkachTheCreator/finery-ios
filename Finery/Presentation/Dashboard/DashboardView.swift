import SwiftUI

struct DashboardView: View {
    @State var viewModel: DashboardViewModel
    var onShowSettings: (() -> Void)?
    var onShowTax: (() -> Void)?
    var onShowAI: (() -> Void)?
    var onShowClients: (() -> Void)?
    var onShowAddTransaction: (() -> Void)?
    var onShowAnalyticsDynamics: (() -> Void)?
    var onShowAnalyticsCategories: (() -> Void)?
    var onShowTips: (() -> Void)?
    var zoomNamespace: Namespace.ID?

    private enum AnalyticsTab: Equatable { case dynamics, categories }

    private var analyticsTint: Color {
        analyticsTab == .dynamics ? FC.badgeSage : FC.badgeTerracotta
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared          = false
    @State private var barProgress: Double = 0
    @State private var showCashFlow      = false
    @State private var analyticsTab      = AnalyticsTab.dynamics

    init(
        viewModel: DashboardViewModel,
        onShowSettings: (() -> Void)? = nil,
        onShowTax: (() -> Void)? = nil,
        onShowAI: (() -> Void)? = nil,
        onShowClients: (() -> Void)? = nil,
        onShowAddTransaction: (() -> Void)? = nil,
        onShowAnalyticsDynamics: (() -> Void)? = nil,
        onShowAnalyticsCategories: (() -> Void)? = nil,
        onShowTips: (() -> Void)? = nil,
        zoomNamespace: Namespace.ID? = nil
    ) {
        _viewModel = State(wrappedValue: viewModel)
        self.onShowSettings = onShowSettings
        self.onShowTax = onShowTax
        self.onShowAI = onShowAI
        self.onShowClients = onShowClients
        self.onShowAddTransaction = onShowAddTransaction
        self.onShowAnalyticsDynamics = onShowAnalyticsDynamics
        self.onShowAnalyticsCategories = onShowAnalyticsCategories
        self.onShowTips = onShowTips
        self.zoomNamespace = zoomNamespace
    }

    var body: some View {
        // GeometryReader for minHeight fill + bento column widths (Задача 1)
        GeometryReader { geo in
            ZStack {
                FC.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        headerSection

                        // Row 1: Hero income (full width) — border trail on appear (Задача 4)
                        incomeHeroTile
                            .borderTrail(cornerRadius: 20, delay: 0.5)
                            .widgetAppear(index: 0, appeared: appeared, reduceMotion: reduceMotion)

                        // Row 2: Add (compact) + AI — unequal heights for bento variety
                        HStack(alignment: .top, spacing: 12) {
                            addTransactionTile
                                .widgetAppear(index: 1, appeared: appeared, reduceMotion: reduceMotion)
                            aiTile
                                .widgetAppear(index: 2, appeared: appeared, reduceMotion: reduceMotion)
                        }

                        // Row 3: Tax (full width, ring indicator)
                        taxTile
                            .zoomSource(id: "tax", ns: zoomNamespace)
                            .widgetAppear(index: 3, appeared: appeared, reduceMotion: reduceMotion)

                        // Row 4: Analytics combined tile (Dynamics | Categories tabs)
                        let col1 = (geo.size.width - 40 - 12) * 0.62
                        let col2 = (geo.size.width - 40 - 12) * 0.38
                        analyticsCombinedTile
                            .zoomSource(id: "dynamics", ns: zoomNamespace)
                            .widgetAppear(index: 4, appeared: appeared, reduceMotion: reduceMotion)

                        // Row 5: Clients + Tips
                        HStack(alignment: .top, spacing: 12) {
                            clientsTile
                                .frame(width: col2)
                                .zoomSource(id: "clients", ns: zoomNamespace)
                                .widgetAppear(index: 5, appeared: appeared, reduceMotion: reduceMotion)
                            tipsTile
                                .frame(width: col1)
                                .zoomSource(id: "tips", ns: zoomNamespace)
                                .widgetAppear(index: 6, appeared: appeared, reduceMotion: reduceMotion)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .frame(minHeight: geo.size.height, alignment: .top)
                }
            }
        }
        .overlay {
            if viewModel.isLoading && !appeared {
                ZStack {
                    FC.background.opacity(0.6).ignoresSafeArea()
                    FineryCoinLoader()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.isLoading)
        .task {
            appeared = false
            withAnimation(.spring(response: 0.62, dampingFraction: 0.82)) { appeared = true }
            await viewModel.load()
            if let status = viewModel.taxStatus {
                let target = min(status.limitUsedPercent / 100.0, 1.0)
                withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
                    barProgress = target
                }
            }
        }
        .overlay(alignment: .top) {
            if SharedDataService.shared.isSlowConnection && !viewModel.isOffline {
                slowBanner.transition(.move(edge: .top).combined(with: .opacity))
            } else if viewModel.isOffline {
                offlineBanner.transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isOffline)
        .animation(.spring(response: 0.4, dampingFraction: 0.8),
                   value: SharedDataService.shared.isSlowConnection)
        .sheet(isPresented: $showCashFlow) {
            CashFlowDetailView(dashboardViewModel: viewModel)
        }
    }

    // MARK: - Banners

    private var slowBanner: some View {
        HStack(spacing: 8) {
            ProgressView().tint(.white).scaleEffect(0.8)
            Text("Медленное соединение, подождите…")
                .font(.system(.caption, design: .rounded, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(FC.muted.opacity(0.9)).clipShape(Capsule())
        .padding(.top, 8).padding(.horizontal, 20)
    }

    private var offlineBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash").fontWeight(.light)
            Text("Сервер недоступен")
                .font(.system(.caption, design: .rounded, weight: .medium))
            Spacer(minLength: 0)
            Button { Task { await viewModel.load() } } label: {
                Text("Повторить")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(.white.opacity(0.25)).clipShape(Capsule())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(FC.danger.opacity(0.88)).clipShape(Capsule())
        .padding(.top, 8).padding(.horizontal, 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(.title2, design: .rounded, weight: .medium))  // T0: medium not bold
                    .foregroundStyle(FC.ink)
                Text(currentMonthFull)
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.inkSecondary)
            }
            Spacer()
            Button { onShowSettings?() } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(FC.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Настройки")
        }
        .padding(.top, 16).padding(.bottom, 4)
        .offset(y: appeared ? 0 : -14)
        .opacity(appeared ? 1 : 0)
        .blur(radius: appeared ? 0 : 4)
        .animation(.spring(response: 0.52, dampingFraction: 0.82), value: appeared)
    }

    // MARK: - 1. Hero Income Tile (T0: ivory text, semibold weight; T4: border trail applied above)

    private var incomeHeroTile: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Доход · \(currentMonthShort)")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(FC.ivory.opacity(0.55))

            Text(viewModel.pnl?.totalIncome.rub() ?? "0\u{202F}₽")
                .font(.system(size: 50, weight: .semibold, design: .rounded))  // T0: semibold not bold
                .monospacedDigit()
                .foregroundStyle(FC.ivory.opacity(viewModel.isLoading ? 0.30 : 1))
                .contentTransition(.numericText(countsDown: false))
                .animation(.fineryNumber, value: viewModel.pnl?.totalIncome)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoading)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Rectangle().fill(FC.ivory.opacity(0.10)).frame(height: 0.5).padding(.bottom, 14)

            HStack(alignment: .top, spacing: 0) {
                heroMetric(label: "расходы", value: viewModel.pnl?.totalExpenses, align: .leading)
                Spacer()
                if viewModel.userType != .other {
                    heroMetric(label: "налог", value: viewModel.pnl?.taxAmount, align: .center)
                    Spacer()
                }
                heroMetric(label: "прибыль", value: viewModel.pnl?.netProfit, align: .trailing)
            }
            if let tax = viewModel.pnl?.taxAmount, tax > 0, viewModel.userType != .other {
                Text("Из доходов этого месяца \(tax.rub()) — налог, не тратьте")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(FC.ivory.opacity(0.50))
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .heroWidget()
        .shimmerOverlay(color: FC.ivory, cornerRadius: 20)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.light()
            showCashFlow = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Доход за \(currentMonthShort): \(viewModel.pnl?.totalIncome.rub() ?? "0 ₽"). Нажмите для деталей.")
        .accessibilityAddTraits(.isButton)
    }

    private func heroMetric(label: String, value: Decimal?, align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(FC.ivory.opacity(0.38))
                .lineLimit(1)
            Text(value?.rub() ?? "—")
                .font(.system(.footnote, design: .rounded, weight: .regular))
                .monospacedDigit()
                .foregroundStyle(FC.ivory.opacity(viewModel.isLoading ? 0.18 : 0.72))
                .contentTransition(.numericText())
                .animation(.fineryNumber, value: value)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    // MARK: - 2. Add Transaction Tile (compact — T1)

    private var addTransactionTile: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(FC.cobalt)  // T0: keep cobalt on main CTA
            VStack(alignment: .leading, spacing: 2) {
                Text("Добавить")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(FC.ink)
                Text("операцию")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)  // T1: compact
        .tintedDataWidget(tint: FC.badgeMuted)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.light()
            onShowAddTransaction?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Добавить операцию")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 3. AI Tile

    private var aiTile: some View {
        VStack(alignment: .leading, spacing: 0) {
            BadgeIcon(systemName: "sparkles", badgeColor: FC.badgePlum)

            Spacer(minLength: 14)

            Text("ИИ-помощник")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(FC.ink)
            Text("Спросить")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(FC.inkSecondary)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .tintedDataWidget(tint: FC.badgePlum)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.light()
            onShowAI?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ИИ-помощник")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 4. Tax Tile (full width, ring indicator — Задача 2)

    @ViewBuilder
    private var taxTile: some View {
        if viewModel.taxStatus?.showNpdLimit == true {
            npdRingTile
        } else if let status = viewModel.taxStatus, viewModel.userType != .other {
            usnTile(status)
        } else {
            fullWidthSimpleTile(
                icon: "percent",
                title: "Налоги",
                detail: viewModel.userType == .other ? "личный трекер" : "нет данных",
                badgeColor: FC.badgeAmber,
                action: onShowTax
            )
        }
    }

    // Задача 2: Ring indicator replaces linear bar
    private var npdRingTile: some View {
        HStack(alignment: .center, spacing: 16) {
            // Ring with % in center
            ZStack {
                RingProgressView(progress: barProgress, color: trafficColor, size: 66, lineWidth: 7)
                VStack(spacing: 1) {
                    Text(limitPercentText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(trafficColor)
                        .contentTransition(.numericText())
                        .animation(.fineryNumber, value: limitPercentText)
                    Text("НПД")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(FC.inkSecondary)
                }
            }

            // Info: label + к уплате + дедлайн
            VStack(alignment: .leading, spacing: 3) {
                Text("Налоги · НПД")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
                if let status = viewModel.taxStatus {
                    Text(status.taxDue.rub())
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(FC.ink)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("к уплате · до 28 \(nextMonthGenitive)")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(FC.inkSecondary)
                }
            }

            Spacer()

            if let status = viewModel.taxStatus, status.isNearLimit {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(status.isOverLimit ? FC.danger : FC.warning)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tintedDataWidget(tint: FC.badgeAmber)
        .contentShape(Rectangle())
        .onTapGesture { HapticManager.impact(.medium); onShowTax?() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Налоги")
        .accessibilityAddTraits(.isButton)
    }

    private func usnTile(_ status: TaxStatus) -> some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12))
                        .foregroundStyle(FC.inkSecondary)
                    Text("Налоги · \(status.taxMode == .usn15 ? "УСН 15%" : "УСН 6%")")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(FC.inkSecondary)
                }
                Text(status.taxDue.rub())
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(FC.ink)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                Text("к уплате")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("Дедлайн")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
                Text(formattedDeadline(status.nextDeadline))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(status.daysUntilDeadline <= 7 ? FC.danger : FC.ink)
                Text("\(status.daysUntilDeadline) дн.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(status.daysUntilDeadline <= 7 ? FC.danger : FC.inkSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tintedDataWidget(tint: FC.badgeAmber)
        .contentShape(Rectangle())
        .onTapGesture { HapticManager.impact(.medium); onShowTax?() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Налоги")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 5. Analytics Combined Tile (Variant 2: tabs inside widget)

    private var analyticsCombinedTile: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 20) {
                analyticsTabLabel("Динамика", tab: .dynamics)
                analyticsTabLabel("Категории", tab: .categories)
                Spacer()
                // Page dots — show swipe affordance
                HStack(spacing: 5) {
                    ForEach([AnalyticsTab.dynamics, .categories], id: \.self) { tab in
                        Circle()
                            .fill(analyticsTab == tab ? FC.ink : FC.border)
                            .frame(width: 5, height: 5)
                            .animation(.easeInOut(duration: 0.2), value: analyticsTab)
                    }
                }
                .accessibilityHidden(true)
            }
            Group {
                if analyticsTab == .dynamics {
                    analyticsRowContent(icon: "chart.bar", title: "Динамика", detail: "за 6 месяцев", badgeColor: FC.badgeSage)
                        .contentShape(Rectangle())
                        .onTapGesture { HapticManager.light(); onShowAnalyticsDynamics?() }
                        .transition(.asymmetric(
                            insertion: .push(from: .leading),
                            removal: .push(from: .trailing)
                        ))
                } else {
                    analyticsRowContent(icon: "chart.pie", title: "Категории", detail: "доходы / расходы", badgeColor: FC.badgeTerracotta)
                        .contentShape(Rectangle())
                        .onTapGesture { HapticManager.light(); onShowAnalyticsCategories?() }
                        .transition(.asymmetric(
                            insertion: .push(from: .trailing),
                            removal: .push(from: .leading)
                        ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: analyticsTab)
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        let h = value.translation.width
                        let v = value.translation.height
                        guard abs(h) > abs(v) * 1.5, abs(h) > 40 else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if h < 0, analyticsTab == .dynamics { analyticsTab = .categories }
                            else if h > 0, analyticsTab == .categories { analyticsTab = .dynamics }
                        }
                    }
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .tintedDataWidget(tint: analyticsTint)
    }

    private func analyticsTabLabel(_ label: String, tab: AnalyticsTab) -> some View {
        let active = analyticsTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { analyticsTab = tab }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: active ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(active ? FC.ink : FC.inkSecondary)
                Rectangle()
                    .fill(active ? FC.cobalt : Color.clear)
                    .frame(height: 1.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func analyticsRowContent(icon: String, title: String, detail: String, badgeColor: Color) -> some View {
        HStack(spacing: 12) {
            BadgeIcon(systemName: icon, badgeColor: badgeColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(FC.ink)
                Text(detail)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(FC.border)
        }
    }

    // MARK: - 6. Clients Tile (T1: narrower in bento)

    private var clientsTile: some View {
        let clients  = SharedDataService.shared.cachedClients
        let active   = clients.filter { $0.status == .active }.count
        let done     = clients.filter { $0.status == .completed }.count

        return VStack(alignment: .leading, spacing: 0) {
            BadgeIcon(systemName: "person.2", badgeColor: FC.badgeDustyBlue)

            Spacer(minLength: 12)

            Text("Клиенты")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(FC.ink)

            VStack(alignment: .leading, spacing: 2) {
                Text("Активных: \(active)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
                Text("Завершено: \(done)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .tintedDataWidget(tint: FC.badgeDustyBlue)
        .contentShape(Rectangle())
        .onTapGesture { HapticManager.impact(.medium); onShowClients?() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Клиенты")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 7. Tips Tile — tap to open TipsListView

    private var tipsTile: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                BadgeIcon(systemName: "lightbulb", badgeColor: FC.badgeGold, badgeSize: 26, iconSize: 12)
                Text("Советы")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
            }

            Spacer(minLength: 10)

            if viewModel.insights.isEmpty {
                Text("Всё в порядке")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.insights.prefix(2)) { insight in
                        HStack(spacing: 6) {
                            let accent: Color = insight.severity == .info ? FC.cobalt : FC.warning
                            Circle().fill(accent).frame(width: 5, height: 5)
                            Text(insight.title)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(FC.inkSecondary)
                                .lineLimit(1)
                        }
                    }
                    if viewModel.insights.count > 2 {
                        Text("+ ещё \(viewModel.insights.count - 2)")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(FC.muted)
                    }
                }
            }

            Spacer(minLength: 8)

            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(FC.border)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .tintedDataWidget(tint: FC.badgeGold)
        .contentShape(Rectangle())
        .onTapGesture { HapticManager.impact(.medium); onShowTips?() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Советы")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Simple Tile helper

    private func simpleTile(icon: String, title: String, detail: String, action: (() -> Void)?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(FC.inkSecondary)  // T0: decorative = secondary

            Spacer(minLength: 14)

            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(FC.ink)
            Text(detail)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(FC.inkSecondary)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .dataWidget()
        .contentShape(Rectangle())
        .onTapGesture { HapticManager.impact(.medium); action?() }
    }

    private func fullWidthSimpleTile(icon: String, title: String, detail: String, badgeColor: Color = FC.badgeMuted, action: (() -> Void)?) -> some View {
        HStack {
            BadgeIcon(systemName: icon, badgeColor: badgeColor, badgeSize: 36, iconSize: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(FC.ink)
                Text(detail)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
            }
            .padding(.leading, 8)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .tintedDataWidget(tint: badgeColor)
        .contentShape(Rectangle())
        .onTapGesture { HapticManager.impact(.medium); action?() }
    }

    // MARK: - Computed helpers

    private var trafficColor: Color {
        switch viewModel.taxStatus?.trafficLight {
        case .green:  FC.cobalt
        case .yellow: FC.warning
        case .red:    FC.danger
        case nil:     FC.inkSecondary
        }
    }

    private var limitPercentText: String {
        guard let status = viewModel.taxStatus else { return "—" }
        return "\(Int(status.limitUsedPercent))%"
    }

    private var greeting: String {
        viewModel.userName.isEmpty ? "Привет" : "Привет, \(viewModel.userName)"
    }

    private var currentMonthFull: String { formatted(Date(), "LLLL yyyy") }
    private var currentMonthShort: String { formatted(Date(), "LLLL") }
    private var nextMonthGenitive: String {
        let next = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        return formatted(next, "LLLL")
    }

    private func formatted(_ date: Date, _ format: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = format
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt.string(from: date)
    }

    private func formattedDeadline(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMMM"
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt.string(from: date)
    }
}

// MARK: - Widget appear animation

private extension View {
    @ViewBuilder
    func widgetAppear(index: Int, appeared: Bool, reduceMotion: Bool = false) -> some View {
        if reduceMotion {
            self
                .opacity(appeared ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: appeared)
        } else {
            self
                .offset(y: appeared ? 0 : 36)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.97, anchor: .top)
                .animation(
                    .spring(response: 0.55, dampingFraction: 0.80).delay(Double(index) * 0.055),
                    value: appeared
                )
        }
    }
}

#Preview {
    DashboardView(viewModel: .preview())
}
