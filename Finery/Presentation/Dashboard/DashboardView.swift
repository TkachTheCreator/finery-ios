import SwiftUI

struct DashboardView: View {
    @State var viewModel: DashboardViewModel
    @State private var appeared = false

    init(viewModel: DashboardViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FC.backgroundGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    headerSection
                    incomeHeroCard
                    taxCard
                    topSourcesCard
                    if !viewModel.insights.isEmpty {
                        insightsCard
                    }
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
            }

            addButton
        }
        .task { await viewModel.load() }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greeting)
                    .font(.system(.title2, design: .default, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text(currentMonthFull)
                    .font(.system(.caption, design: .default, weight: .regular))
                    .tracking(0.3)
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
        .offset(y: appeared ? 0 : -16)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Income Hero Card

    private var incomeHeroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ДОХОД ЗА \(currentMonthShortUpper)")
                .fLabel()

            Group {
                if viewModel.isLoading {
                    Text("—")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(FC.muted)
                } else {
                    Text(viewModel.pnl?.totalIncome.rub() ?? "0\u{202F}₽")
                        .font(.system(size: 46, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(FC.ink)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.pnl?.totalIncome)
                }
            }

            HStack(alignment: .top, spacing: 0) {
                miniMetric(label: "РАСХОДЫ",  value: viewModel.pnl?.totalExpenses, color: FC.danger,  alignment: .leading)
                Spacer()
                miniMetric(label: "НАЛОГ",    value: viewModel.pnl?.taxAmount,     color: FC.muted,   alignment: .center)
                Spacer()
                miniMetric(label: "ЧИСТАЯ",   value: viewModel.pnl?.netProfit,     color: FC.success, alignment: .trailing)
            }
        }
        .padding(20)
        .glassCard()
        .offset(y: appeared ? 0 : 60)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.08), value: appeared)
    }

    @ViewBuilder
    private func miniMetric(label: String, value: Decimal?, color: Color, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.system(.caption2, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(FC.muted)
            Text(value?.rub() ?? "—")
                .font(.system(.footnote, design: .default, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    // MARK: - Tax Card

    private var taxCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ЛИМИТ НПД").fLabel()
                Spacer()
                Text(limitPercentText)
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(trafficColor)
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [FC.cobalt, trafficColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * limitFraction, height: 6)
                        .shadow(color: FC.cobaltGlow, radius: 6)
                        .animation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.3), value: limitFraction)
                }
            }
            .frame(height: 6)

            if let status = viewModel.taxStatus {
                Text("Использовано \(status.yearlyIncome.rub()) из \(TaxStatus.npdYearLimit.rub())")
                    .font(.system(.caption, design: .default, weight: .regular))
                    .foregroundStyle(FC.muted)
            }

            deadlineRow
        }
        .padding(20)
        .glassCard()
        .offset(y: appeared ? 0 : 60)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.16), value: appeared)
    }

    private var deadlineRow: some View {
        HStack(spacing: 0) {
            Image(systemName: "calendar")
                .fontWeight(.light)
                .imageScale(.small)
                .foregroundStyle(FC.muted)
                .padding(.trailing, 6)
            Text("Следующий налог: ")
                .font(.system(.caption, design: .default, weight: .regular))
                .foregroundStyle(FC.muted)
            if let tax = viewModel.taxStatus?.taxDue {
                Text(tax.rub())
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(FC.ink)
            }
            Text(" · до 28 \(nextMonthGenitive)")
                .font(.system(.caption, design: .default, weight: .regular))
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
                Text("Нет данных за этот месяц")
                    .font(.system(.subheadline))
                    .foregroundStyle(FC.muted)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(viewModel.topSources.enumerated()), id: \.element.category) { index, item in
                    sourceRow(rank: index + 1, category: item.category, amount: item.amount)
                    if index < viewModel.topSources.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 0.5)
                    }
                }
            }
        }
        .padding(20)
        .glassCard()
        .offset(y: appeared ? 0 : 60)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.24), value: appeared)
    }

    @ViewBuilder
    private func sourceRow(rank: Int, category: IncomeCategory, amount: Decimal) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(.caption2, design: .default, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(FC.muted)
                .frame(width: 14, alignment: .center)
            Image(systemName: category.iconName)
                .fontWeight(.light)
                .imageScale(.small)
                .foregroundStyle(FC.cobalt)
                .frame(width: 18)
            Text(category.displayName)
                .font(.system(.subheadline, design: .default, weight: .regular))
                .foregroundStyle(FC.ink)
            Spacer()
            Text(amount.rub())
                .font(.system(.subheadline, design: .default, weight: .medium))
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
        .offset(y: appeared ? 0 : 60)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.32), value: appeared)
    }

    // MARK: - FAB

    private var addButton: some View {
        Button {
            // TODO: показать AddTransactionView
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").fontWeight(.semibold)
                Text("Добавить")
                    .font(.system(.subheadline, design: .default, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(FC.cobalt)
                    .shadow(color: FC.cobaltGlow, radius: 14, x: 0, y: 6)
            )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 36)
    }

    // MARK: - Helpers

    private var skeletonRow: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
                .frame(width: 140, height: 13)
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
                .frame(width: 60, height: 13)
        }
        .padding(.vertical, 6)
    }

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

    private var currentMonthFull: String        { formatted(Date(), "LLLL yyyy") }
    private var currentMonthShortUpper: String  { formatted(Date(), "LLLL").uppercased() }
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

#Preview {
    DashboardView(viewModel: .preview())
}
