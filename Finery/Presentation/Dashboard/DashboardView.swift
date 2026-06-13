import SwiftUI
import Shimmer
import Pow

private struct ScrollOffsetKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct DashboardView: View {
    @State var viewModel: DashboardViewModel
    @State private var cardAppeared   = false
    @State private var progressShown  = false
    @State private var scrollOffset:  CGFloat = 0
    @State private var initialOffset: CGFloat?
    @State private var showAdd        = false

    init(viewModel: DashboardViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FC.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .global).minY
                        )
                    }
                    .frame(height: 0)

                    headerSection
                    cardStack
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 16)
            }

            addButton
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(
                viewModel: viewModel.makeAddTransactionViewModel(),
                onSave: { Task { await viewModel.load() } }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .onAppear {
            guard !cardAppeared else { return }
            withAnimation(.fineryCard.delay(0.05)) { cardAppeared = true }
            withAnimation(.easeOut(duration: 1.2).delay(0.5)) { progressShown = true }
        }
        .onPreferenceChange(ScrollOffsetKey.self) { value in
            if initialOffset == nil { initialOffset = value }
            scrollOffset = value - (initialOffset ?? value)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(FC.ink)
                Text(currentMonthFull)
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            Image(systemName: "gearshape")
                .fontWeight(.light)
                .imageScale(.medium)
                .foregroundStyle(FC.muted)
        }
        .padding(.horizontal, 4)
        .padding(.top, 20)
        .padding(.bottom, 4)
        .offset(y: cardAppeared ? 0 : -16)
        .opacity(cardAppeared ? 1 : 0)
        .animation(.fineryCard, value: cardAppeared)
    }

    // MARK: - Staggered Card Stack

    @ViewBuilder
    private var cardStack: some View {
        incomeHeroCard
            .staggered(appeared: cardAppeared, index: 0)
            .pressable()

        taxCard
            .staggered(appeared: cardAppeared, index: 1)
            .pressable()

        topSourcesCard
            .staggered(appeared: cardAppeared, index: 2)
            .pressable()

        if !viewModel.insights.isEmpty {
            insightsCard
                .staggered(appeared: cardAppeared, index: 3)
                .pressable()
        }
    }

    // MARK: - Income Hero Card

    private var incomeHeroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ДОХОД ЗА \(currentMonthShortUpper)")
                .fLabel()

            Group {
                if viewModel.isLoading {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(FC.border)
                        .frame(width: 200, height: 52)
                        .skeleton(active: true)
                } else {
                    Text(viewModel.pnl?.totalIncome.rub() ?? "0\u{202F}₽")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(FC.ink)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.fineryNumber, value: viewModel.pnl?.totalIncome)
                }
            }

            HStack(alignment: .top, spacing: 0) {
                miniMetric(label: "РАСХОДЫ",  value: viewModel.pnl?.totalExpenses, color: FC.danger,   align: .leading)
                Spacer()
                miniMetric(label: "НАЛОГ",    value: viewModel.pnl?.taxAmount,     color: FC.muted,    align: .center)
                Spacer()
                miniMetric(label: "ЧИСТАЯ",   value: viewModel.pnl?.netProfit,     color: FC.success,  align: .trailing)
            }
        }
        .padding(20)
        .glassCardGlow(FC.cobaltGlow.opacity(0.5))
    }

    @ViewBuilder
    private func miniMetric(label: String, value: Decimal?, color: Color, align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 4) {
            Text(label).fLabel()
            if viewModel.isLoading {
                RoundedRectangle(cornerRadius: 4)
                    .fill(FC.border)
                    .frame(width: 70, height: 13)
                    .skeleton(active: true)
            } else {
                Text(value?.rub() ?? "—")
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                    .animation(.fineryNumber, value: value)
            }
        }
    }

    // MARK: - Tax Card

    private var taxCard: some View {
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
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FC.border.opacity(0.6))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [FC.cobalt, trafficColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * (progressShown ? limitFraction : 0), height: 6)
                        .shadow(color: FC.cobaltGlow, radius: 6)
                        .animation(.easeOut(duration: 1.2), value: progressShown)
                }
            }
            .frame(height: 6)

            if let status = viewModel.taxStatus {
                Text("Использовано \(status.yearlyIncome.rub()) из \(TaxStatus.npdYearLimit.rub())")
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.muted)
            }

            deadlineRow
        }
        .padding(20)
        .glassCard()
    }

    private var deadlineRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .fontWeight(.light)
                .imageScale(.small)
                .foregroundStyle(FC.muted)
            Text("Следующий налог: ")
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(FC.muted)
            if let tax = viewModel.taxStatus?.taxDue {
                Text(tax.rub())
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(FC.ink)
            }
            Text(" · до 28 \(nextMonthGenitive)")
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(FC.muted)
        }
        .padding(.top, 2)
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
                        Rectangle().fill(FC.border.opacity(0.6)).frame(height: 0.5)
                    }
                }
            }
        }
        .padding(20)
        .glassCard()
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
                .imageScale(.small)
                .foregroundStyle(FC.cobalt)
                .frame(width: 18)
            Text(category.displayName)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(FC.ink)
            Spacer()
            Text(amount.rub())
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(FC.success)
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
        .glassCard()
    }

    // MARK: - FAB

    private var addButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showAdd = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").fontWeight(.semibold)
                Text("Добавить")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(FC.cobalt)
                    .shadow(color: FC.cobaltGlow, radius: 14, x: 0, y: 5)
            )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 108)
    }

    // MARK: - Skeleton

    private var skeletonRow: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(FC.border)
                .frame(width: 140, height: 13)
                .skeleton(active: true)
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(FC.border)
                .frame(width: 60, height: 13)
                .skeleton(active: true)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private var trafficColor: Color {
        switch viewModel.taxStatus?.trafficLight {
        case .green:  FC.success
        case .yellow: FC.amber
        case .red:    FC.danger
        case nil:     FC.muted
        }
    }

    private var limitFraction: CGFloat {
        guard let status = viewModel.taxStatus else { return 0 }
        return CGFloat(min(status.limitUsedPercent / 100, 1.0))
    }

    private var limitPercentText: String {
        guard let status = viewModel.taxStatus else { return "—" }
        return "\(Int(status.limitUsedPercent))%"
    }

    private var greeting: String {
        viewModel.userName.isEmpty ? "Привет" : "Привет, \(viewModel.userName)"
    }

    private var currentMonthFull: String {
        formatted(Date(), "LLLL yyyy")
    }
    private var currentMonthShortUpper: String {
        formatted(Date(), "LLLL").uppercased()
    }
    private var nextMonthGenitive: String {
        let next = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        return formatted(next, "LLLL")
    }

    private func formatted(_ date: Date, _ format: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = format
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt.string(from: date).capitalized
    }
}

// MARK: - Staggered appearance modifier

private extension View {
    func staggered(appeared: Bool, index: Int) -> some View {
        self
            .offset(y: appeared ? 0 : 40)
            .opacity(appeared ? 1 : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8)
                .delay(Double(index) * 0.10),
                value: appeared
            )
    }
}

#Preview {
    DashboardView(viewModel: .preview())
}
