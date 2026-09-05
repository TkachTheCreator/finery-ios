import SwiftUI
import Shimmer
import Pow

struct DashboardView: View {
    @State var viewModel: DashboardViewModel
    var onShowSettings: (() -> Void)?
    @State private var appeared    = false
    @State private var barProgress: Double = 0
    @State private var showCashFlow = false

    init(viewModel: DashboardViewModel, onShowSettings: (() -> Void)? = nil) {
        _viewModel = State(wrappedValue: viewModel)
        self.onShowSettings = onShowSettings
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    headerSection
                    cardStack
                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, 20)
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
            barProgress = 0
            // Карточки появляются сразу (stagger) — с нулями
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appeared = true
            }
            // Данные загружаются — числа считаются через contentTransition
            await viewModel.load()
            if let status = viewModel.taxStatus {
                let target = min(status.limitUsedPercent / 100.0, 1.0)
                withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2)) {
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: SharedDataService.shared.isSlowConnection)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FC.muted.opacity(0.9))
        .clipShape(Capsule())
        .padding(.top, 8)
        .padding(.horizontal, 20)
    }

    private var offlineBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash").fontWeight(.light)
            Text("Сервер недоступен")
                .font(.system(.caption, design: .rounded, weight: .medium))
            Spacer(minLength: 0)
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Повторить")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.25))
                    .clipShape(Capsule())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FC.danger.opacity(0.88))
        .clipShape(Capsule())
        .padding(.top, 8)
        .padding(.horizontal, 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(FC.ink)
                Text(currentMonthFull)
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            Button { onShowSettings?() } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(FC.muted)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
        .offset(y: appeared ? 0 : -12)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: appeared)
    }

    // MARK: - Card Stack

    @ViewBuilder
    private var cardStack: some View {
        incomeHeroCard
            .offset(y: appeared ? 0 : 40)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05), value: appeared)

        if viewModel.userType != .other {
            taxCard
                .offset(y: appeared ? 0 : 40)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15), value: appeared)
        }

        topSourcesCard
            .offset(y: appeared ? 0 : 40)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25), value: appeared)

        if !viewModel.insights.isEmpty {
            insightsCard
                .offset(y: appeared ? 0 : 40)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.35), value: appeared)
        }
    }

    // MARK: - Income Hero Card

    private var incomeHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Доход за \(currentMonthShort)").fLabel()
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(FC.border)
            }

            Text(viewModel.pnl?.totalIncome.rub() ?? "0\u{202F}₽")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(FC.cobalt.opacity(viewModel.isLoading ? 0.22 : 1))
                .contentTransition(.numericText(countsDown: false))
                .animation(.fineryNumber, value: viewModel.pnl?.totalIncome)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoading)

            HStack(alignment: .top, spacing: 0) {
                miniMetric(label: "Расходы", value: viewModel.pnl?.totalExpenses, align: .leading,  valueColor: FC.ink)
                Spacer()
                if viewModel.userType != .other {
                    miniMetric(label: "Налог", value: viewModel.pnl?.taxAmount, align: .center, valueColor: FC.muted)
                    Spacer()
                }
                miniMetric(label: "Чистая",  value: viewModel.pnl?.netProfit, align: .trailing, valueColor: FC.cobalt)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { showCashFlow = true }
    }

    @ViewBuilder
    private func miniMetric(label: String, value: Decimal?, align: HorizontalAlignment, valueColor: Color = FC.ink) -> some View {
        VStack(alignment: align, spacing: 4) {
            Text(label).fLabel()
            Text(value?.rub() ?? "—")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle((viewModel.isLoading ? FC.muted : valueColor).opacity(viewModel.isLoading ? 0.35 : 1))
                .contentTransition(.numericText())
                .animation(.fineryNumber, value: value)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoading)
        }
    }

    // MARK: - Tax Card

    @ViewBuilder
    private var taxCard: some View {
        if viewModel.taxStatus?.showNpdLimit == true {
            npdLimitCard
        } else if let status = viewModel.taxStatus {
            usnQuarterlyCard(status)
        }
    }

    // НПД: limit progress bar
    private var npdLimitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Лимит НПД").fLabel()
                Spacer()
                Text(limitPercentText)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(trafficColor)
                    .contentTransition(.numericText())
                    .animation(.fineryNumber, value: limitPercentText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(FC.border).frame(height: 5)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [FC.cobalt, trafficColor],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * barProgress, height: 5)
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: barProgress)
                }
            }
            .frame(height: 5)

            if let status = viewModel.taxStatus {
                Text("Использовано \(status.yearlyIncome.rub()) из \(TaxStatus.npdYearLimit.rub())")
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.muted)
            }

            npdDeadlineRow
        }
        .padding(20)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
    }

    // УСН: quarterly tax card
    private func usnQuarterlyCard(_ status: TaxStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Налог за квартал").fLabel()
                Spacer()
                Text(status.effectiveRate)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.cobalt)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("К уплате").fLabel()
                    Text(status.taxDue.rub())
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(FC.cobalt)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Дедлайн").fLabel()
                    Text(formattedDeadline(status.nextDeadline))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(status.daysUntilDeadline <= 7 ? FC.danger : FC.ink)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar").fontWeight(.light).imageScale(.medium).foregroundStyle(FC.muted)
                Text("Авансовый платёж раз в квартал")
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
            .padding(.top, 2)
        }
        .padding(20)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
    }

    private var npdDeadlineRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar").fontWeight(.light).imageScale(.medium).foregroundStyle(FC.muted)
            Text("Следующий налог: ")
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(FC.muted)
            if let tax = viewModel.taxStatus?.taxDue {
                Text(tax.rub())
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(FC.ink)
            }
            Text("· до 28 \(nextMonthGenitive)")
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(FC.muted)
        }
        .padding(.top, 2)
    }

    private func formattedDeadline(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMMM"
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt.string(from: date)
    }

    // MARK: - Top Sources Card

    private var topSourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Топ источников").fLabel()

            if viewModel.isLoading {
                ForEach(0..<3, id: \.self) { _ in skeletonRow }
            } else if viewModel.topSources.isEmpty {
                HStack {
                    Image(systemName: "tray")
                        .fontWeight(.light)
                        .imageScale(.medium)
                        .foregroundStyle(FC.muted)
                    Text("Нет данных за этот месяц")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(FC.muted)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(Array(viewModel.topSources.enumerated()), id: \.element.id) { index, item in
                    sourceRow(rank: index + 1, source: item)
                    if index < viewModel.topSources.count - 1 {
                        Rectangle().fill(FC.border.opacity(0.5)).frame(height: 0.5)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func sourceRow(rank: Int, source: IncomeSource) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(FC.muted)
                .frame(width: 14, alignment: .center)
            Image(systemName: source.icon)
                .fontWeight(.light)
                .imageScale(.medium)
                .foregroundStyle(FC.cobalt)
                .frame(width: 20)
            Text(source.name)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(FC.ink)
            Spacer()
            Text(source.amount.rub())
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(FC.cobalt)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Insights Card

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Инсайты").fLabel()
            VStack(spacing: 6) {
                ForEach(viewModel.insights) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Skeleton

    private var skeletonRow: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4).fill(FC.border).frame(width: 130, height: 12).skeleton(active: true)
            Spacer()
            RoundedRectangle(cornerRadius: 4).fill(FC.border).frame(width: 60, height: 12).skeleton(active: true)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Computed

    private var trafficColor: Color {
        switch viewModel.taxStatus?.trafficLight {
        case .green:  FC.cobalt
        case .yellow: FC.amber
        case .red:    FC.danger
        case nil:     FC.muted
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
        formatted(Calendar.current.date(byAdding: .month, value: 1, to: Date())!, "LLLL")
    }

    private func formatted(_ date: Date, _ format: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = format
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt.string(from: date).capitalized
    }
}

#Preview {
    DashboardView(viewModel: .preview())
}
