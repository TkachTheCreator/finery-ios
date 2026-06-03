import SwiftUI

struct DashboardView: View {
    @State var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FC.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    hairline
                    incomeHeroSection
                    hairline
                    taxSection
                    hairline
                    topSourcesSection
                    if !viewModel.insights.isEmpty {
                        hairline
                        insightsSection
                    }
                    Color.clear.frame(height: 100)
                }
            }

            addButton
        }
        .task { await viewModel.load() }
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 18)
    }

    // MARK: - Income Hero

    private var incomeHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ДОХОД ЗА \(currentMonthShortUpper)")
                .fLabel()

            Group {
                if viewModel.isLoading {
                    Text("—")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(FC.border)
                } else {
                    Text(viewModel.pnl?.totalIncome.rub() ?? "0\u{202F}₽")
                        .font(.system(size: 46, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(FC.ink)
                        .contentTransition(.numericText())
                }
            }

            HStack(alignment: .top, spacing: 0) {
                miniMetric(
                    label: "РАСХОДЫ",
                    value: viewModel.pnl?.totalExpenses,
                    color: FC.danger,
                    alignment: .leading
                )
                Spacer()
                miniMetric(
                    label: "НАЛОГ",
                    value: viewModel.pnl?.taxAmount,
                    color: FC.muted,
                    alignment: .center
                )
                Spacer()
                miniMetric(
                    label: "ЧИСТАЯ",
                    value: viewModel.pnl?.netProfit,
                    color: FC.success,
                    alignment: .trailing
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private func miniMetric(
        label: String,
        value: Decimal?,
        color: Color,
        alignment: HorizontalAlignment
    ) -> some View {
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

    // MARK: - Tax Section

    private var taxSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ЛИМИТ НПД")
                    .fLabel()
                Spacer()
                Text(limitPercentText)
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(trafficColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(FC.border.opacity(0.4))
                        .frame(height: 3)
                    Rectangle()
                        .fill(trafficColor)
                        .frame(width: geo.size.width * limitFraction, height: 3)
                        .animation(.easeOut(duration: 0.6), value: limitFraction)
                }
            }
            .frame(height: 3)

            if let status = viewModel.taxStatus {
                Text("Использовано \(status.yearlyIncome.rub()) из \(TaxStatus.npdYearLimit.rub())")
                    .font(.system(.caption, design: .default, weight: .regular))
                    .foregroundStyle(FC.muted)
            }

            deadlineRow
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
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

    // MARK: - Top Sources

    private var topSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ТОП ИСТОЧНИКОВ")
                .fLabel()

            if viewModel.isLoading {
                ForEach(0..<3, id: \.self) { _ in
                    skeletonRow
                }
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
                            .fill(FC.border.opacity(0.5))
                            .frame(height: 0.5)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
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

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ИНСАЙТЫ")
                .fLabel()
                .padding(.horizontal, 20)
                .padding(.top, 20)

            VStack(spacing: 5) {
                ForEach(viewModel.insights) { insight in
                    InsightRow(insight: insight)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - FAB

    private var addButton: some View {
        Button {
            // TODO: показать AddTransactionView
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                Text("Добавить")
                    .font(.system(.subheadline, design: .default, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(FC.cobalt)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 36)
    }

    // MARK: - Helpers

    private var hairline: some View {
        Rectangle()
            .fill(FC.border)
            .frame(height: 0.5)
    }

    private var skeletonRow: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(FC.border.opacity(0.5))
                .frame(width: 140, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .fill(FC.border.opacity(0.5))
                .frame(width: 60, height: 14)
        }
        .padding(.vertical, 6)
    }

    private var trafficColor: Color {
        switch viewModel.taxStatus?.trafficLight {
        case .green:  FC.success
        case .yellow: FC.amber
        case .red:    FC.danger
        case nil:     FC.border
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

// MARK: - Preview

#Preview {
    DashboardView(viewModel: .preview())
}
