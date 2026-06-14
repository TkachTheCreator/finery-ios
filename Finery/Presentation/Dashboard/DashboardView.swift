import SwiftUI
import Shimmer
import Pow

struct DashboardView: View {
    @State var viewModel: DashboardViewModel
    @State private var appeared    = false
    @State private var barProgress: Double = 0
    @State private var fabPressed  = false
    @State private var showAdd     = false

    init(viewModel: DashboardViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FC.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    headerSection
                    cardStack
                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, 20)
            }

            addButton
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
            await viewModel.load()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
                appeared = true
            }
            if let status = viewModel.taxStatus {
                let raw = Double(status.limitUsedPercent.description) ?? 0
                let target = raw > 100 ? 1.0 : raw / 100.0
                withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.4)) {
                    barProgress = target
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(
                viewModel: viewModel.makeAddTransactionViewModel(),
                onSave: { Task { await viewModel.load() } }
            )
        }
        .overlay(alignment: .top) {
            if viewModel.isOffline {
                offlineBanner.transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isOffline)
    }

    // MARK: - Offline Banner

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash").fontWeight(.light)
            Text("Нет подключения · локальные данные")
                .font(.system(.caption, design: .rounded, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FC.muted.opacity(0.92))
        .clipShape(Capsule())
        .padding(.top, 8)
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
            .fineryTap()
            .offset(y: appeared ? 0 : 40)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05), value: appeared)

        taxCard
            .fineryTap()
            .offset(y: appeared ? 0 : 40)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15), value: appeared)

        topSourcesCard
            .fineryTap()
            .offset(y: appeared ? 0 : 40)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25), value: appeared)

        if !viewModel.insights.isEmpty {
            insightsCard
                .fineryTap()
                .offset(y: appeared ? 0 : 40)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.35), value: appeared)
        }
    }

    // MARK: - Income Hero Card

    private var incomeHeroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ДОХОД ЗА \(currentMonthShortUpper)")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.65))

            Group {
                if viewModel.isLoading {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.2))
                        .frame(width: 200, height: 52)
                } else {
                    Text(viewModel.pnl?.totalIncome.rub() ?? "0\u{202F}₽")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.fineryNumber, value: viewModel.pnl?.totalIncome)
                }
            }

            HStack(alignment: .top, spacing: 0) {
                miniMetric(label: "РАСХОДЫ", value: viewModel.pnl?.totalExpenses, align: .leading,  valueColor: .white.opacity(0.7))
                Spacer()
                miniMetric(label: "НАЛОГ",   value: viewModel.pnl?.taxAmount,     align: .center,   valueColor: .white.opacity(0.7))
                Spacer()
                miniMetric(label: "ЧИСТАЯ",  value: viewModel.pnl?.netProfit,     align: .trailing, valueColor: .white)
            }
        }
        .padding(20)
        .background(FC.cobalt)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func miniMetric(label: String, value: Decimal?, align: HorizontalAlignment, valueColor: Color = .white) -> some View {
        VStack(alignment: align, spacing: 4) {
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.55))
            if viewModel.isLoading {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.2))
                    .frame(width: 60, height: 12)
            } else {
                Text(value?.rub() ?? "—")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(valueColor)
                    .contentTransition(.numericText())
                    .animation(.fineryNumber, value: value)
            }
        }
    }

    // MARK: - Tax Card

    @ViewBuilder
    private var taxCard: some View {
        if viewModel.taxStatus?.showNpdLimit == true || viewModel.taxStatus == nil {
            npdLimitCard
        } else if let status = viewModel.taxStatus {
            usnQuarterlyCard(status)
        }
    }

    // НПД: limit progress bar
    private var npdLimitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ЛИМИТ НПД").fLabel()
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
                Text("НАЛОГ ЗА КВАРТАЛ").fLabel()
                Spacer()
                Text(status.effectiveRate)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.cobalt)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("К УПЛАТЕ").fLabel()
                    Text(status.taxDue.rub())
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(FC.cobalt)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ДЕДЛАЙН").fLabel()
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
            Text("ТОП ИСТОЧНИКОВ").fLabel()

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
                ForEach(Array(viewModel.topSources.enumerated()), id: \.element.category) { index, item in
                    sourceRow(rank: index + 1, category: item.category, amount: item.amount)
                    if index < viewModel.topSources.count - 1 {
                        Rectangle().fill(FC.border.opacity(0.5)).frame(height: 0.5)
                    }
                }
            }
        }
        .padding(20)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
    }

    @ViewBuilder
    private func sourceRow(rank: Int, category: IncomeCategory, amount: Decimal) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(FC.muted)
                .frame(width: 14, alignment: .center)
            Image(systemName: category.iconName)
                .fontWeight(.light)
                .imageScale(.medium)
                .foregroundStyle(FC.cobalt)
                .frame(width: 20)
            Text(category.displayName)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(FC.ink)
            Spacer()
            Text(amount.rub())
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(FC.cobalt)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Insights Card

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ИНСАЙТЫ").fLabel()
            VStack(spacing: 6) {
                ForEach(viewModel.insights) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
        .padding(20)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
    }

    // MARK: - FAB

    private var addButton: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus").fontWeight(.semibold).imageScale(.medium)
            Text("Добавить").font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(FC.cobalt)
                .shadow(color: FC.cobaltGlow, radius: 12, x: 0, y: 4)
        )
        .scaleEffect(fabPressed ? 0.92 : 1.0)
        .animation(.spring(duration: 0.2), value: fabPressed)
        .onTapGesture {
            withAnimation { fabPressed = true }
            HapticManager.impact(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                fabPressed = false
                showAdd = true
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
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
    private var currentMonthShortUpper: String { formatted(Date(), "LLLL").uppercased() }
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
