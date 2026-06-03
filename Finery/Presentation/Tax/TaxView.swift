import SwiftUI

struct TaxView: View {
    @State var viewModel: TaxViewModel

    init(viewModel: TaxViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    pageHeader
                    hairline
                    if let status = viewModel.taxStatus {
                        taxModeSection(status)
                        hairline
                        limitSection(status)
                        hairline
                        deadlineSection(status)
                        hairline
                        yearSummarySection
                        hairline
                        historySection
                    } else if viewModel.isLoading {
                        loadingState
                    }
                    Color.clear.frame(height: 40)
                }
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: Header

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Налоги")
                    .font(.system(.title2, design: .default, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text(currentYearLabel)
                    .font(.system(.caption, design: .default, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: Tax Mode

    private func taxModeSection(_ status: TaxStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("РЕЖИМ").fLabel()
                Text(status.taxMode.displayName)
                    .font(.system(.title3, design: .default, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text(status.taxMode.shortDescription)
                    .font(.system(.caption))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            ZStack {
                Rectangle()
                    .fill(FC.cobalt.opacity(0.1))
                    .frame(width: 52, height: 52)
                Text("%")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(FC.cobalt)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: NPD Limit

    private func limitSection(_ status: TaxStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ЛИМИТ НПД").fLabel()
                Spacer()
                if status.isNearLimit {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .fontWeight(.light)
                            .imageScale(.small)
                        Text(status.isOverLimit ? "Превышен" : "Внимание")
                            .font(.system(.caption, design: .default, weight: .semibold))
                    }
                    .foregroundStyle(status.isOverLimit ? FC.danger : FC.amber)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(FC.border.opacity(0.4)).frame(height: 4)
                    Rectangle()
                        .fill(trafficColor(status))
                        .frame(width: geo.size.width * CGFloat(min(status.limitUsedPercent / 100, 1.0)), height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Использовано").fLabel()
                    Text(status.yearlyIncome.rub())
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(trafficColor(status))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Осталось").fLabel()
                    Text(status.remaining.rub())
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(FC.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Лимит").fLabel()
                    Text(TaxStatus.npdYearLimit.rub())
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(FC.ink)
                }
            }

            if status.isNearLimit {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .fontWeight(.light)
                        .foregroundStyle(FC.cobalt)
                    Text("При превышении лимита потеряешь статус самозанятого. Оформи ИП заранее.")
                        .font(.system(.caption))
                        .foregroundStyle(FC.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(FC.cobalt.opacity(0.07))
                .overlay(Rectangle().stroke(FC.cobalt.opacity(0.2), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: Deadline

    private func deadlineSection(_ status: TaxStatus) -> some View {
        HStack(spacing: 0) {
            deadlineCard(
                label: "К УПЛАТЕ",
                value: status.taxDue.rub(),
                valueColor: status.taxDue > 0 ? FC.danger : FC.muted
            )
            Rectangle().fill(FC.border).frame(width: 0.5)
            deadlineCard(
                label: "ДНЕЙ ОСТАЛОСЬ",
                value: "\(max(0, status.daysUntilDeadline))",
                valueColor: status.daysUntilDeadline <= 5 ? FC.danger : FC.ink
            )
            Rectangle().fill(FC.border).frame(width: 0.5)
            deadlineCard(
                label: "ДЕДЛАЙН",
                value: formattedDeadline(status.nextDeadline),
                valueColor: FC.ink
            )
        }
        .background(FC.surface)
    }

    private func deadlineCard(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(value)
                .font(.system(.headline, design: .default, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Year Summary

    private var yearSummarySection: some View {
        HStack(spacing: 0) {
            yearCard(label: "ДОХОД ЗА ГОД", amount: viewModel.totalIncomeYear, color: FC.success)
            Rectangle().fill(FC.border).frame(width: 0.5)
            yearCard(label: "НАЛОГ ЗА ГОД", amount: viewModel.totalTaxYear, color: FC.danger)
        }
    }

    private func yearCard(label: String, amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(amount.rub())
                .font(.system(.subheadline, design: .default, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FC.background)
    }

    // MARK: History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ИСТОРИЯ ПО МЕСЯЦАМ").fLabel()

            ForEach(viewModel.monthlyHistory.reversed()) { item in
                HStack {
                    Text(item.monthLabel)
                        .font(.system(.subheadline, design: .default, weight: .regular))
                        .foregroundStyle(FC.ink)
                        .frame(width: 50, alignment: .leading)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.income.rub())
                            .font(.system(.subheadline, design: .default, weight: .regular))
                            .monospacedDigit()
                            .foregroundStyle(FC.success)
                        Text("Налог: " + item.taxAmount.rub())
                            .font(.system(.caption2, design: .default, weight: .regular))
                            .monospacedDigit()
                            .foregroundStyle(FC.muted)
                    }
                }
                .padding(.vertical, 6)
                if item.id != viewModel.monthlyHistory.reversed().last?.id {
                    Rectangle().fill(FC.border.opacity(0.5)).frame(height: 0.5)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: Loading

    private var loadingState: some View {
        HStack {
            Spacer()
            ProgressView().tint(FC.cobalt).padding(.vertical, 60)
            Spacer()
        }
    }

    // MARK: Helpers

    private var hairline: some View {
        Rectangle().fill(FC.border).frame(height: 0.5)
    }

    private func trafficColor(_ status: TaxStatus) -> Color {
        switch status.trafficLight {
        case .green:  FC.success
        case .yellow: FC.amber
        case .red:    FC.danger
        }
    }

    private func formattedDeadline(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMMM"
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt.string(from: date)
    }

    private var currentYearLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy"
        return fmt.string(from: Date()) + " год"
    }
}

#Preview {
    TaxView(viewModel: .preview())
}
