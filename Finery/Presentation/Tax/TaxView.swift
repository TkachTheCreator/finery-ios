import SwiftUI

struct TaxView: View {
    @State var viewModel: TaxViewModel
    @State private var appeared = false

    init(viewModel: TaxViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    pageHeader
                        .offset(y: appeared ? 0 : -16)
                        .opacity(appeared ? 1 : 0)

                    if let status = viewModel.taxStatus {
                        taxModeCard(status)
                            .cardAppear(appeared: appeared, delay: 0.08)

                        if status.showNpdLimit {
                            npdLimitCard(status)
                                .cardAppear(appeared: appeared, delay: 0.16)
                        } else {
                            usnTaxCard(status)
                                .cardAppear(appeared: appeared, delay: 0.16)
                        }

                        deadlineCard(status)
                            .cardAppear(appeared: appeared, delay: 0.24)

                        if let forecast = viewModel.cashFlowForecast {
                            cashFlowCard(forecast)
                                .cardAppear(appeared: appeared, delay: 0.30)
                        }
                        yearSummaryCard
                            .cardAppear(appeared: appeared, delay: 0.38)
                        historyCard
                            .cardAppear(appeared: appeared, delay: 0.46)
                    } else if viewModel.isLoading {
                        loadingState
                    } else if viewModel.userType == .other {
                        personalTrackerStub
                            .cardAppear(appeared: appeared, delay: 0.08)
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
        }
        .task { await viewModel.load() }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) { appeared = true }
        }
    }

    // MARK: - Header

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Налоги")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text(currentYearLabel)
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    // MARK: - Tax Mode Card

    private func taxModeCard(_ status: TaxStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("РЕЖИМ").fLabel()
                Text(status.taxMode.displayName)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text(status.taxMode.shortDescription)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(FC.cobalt.opacity(0.14))
                    .frame(width: 52, height: 52)
                Text("%")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(FC.cobalt)
            }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - NPD Limit Card (only for НПД)

    private func npdLimitCard(_ status: TaxStatus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ЛИМИТ НПД").fLabel()
                Spacer()
                if status.isNearLimit {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle").fontWeight(.light).imageScale(.small)
                        Text(status.isOverLimit ? "Превышен" : "Внимание")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(status.isOverLimit ? FC.danger : FC.amber)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5).fill(FC.border.opacity(0.6)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(
                            colors: [FC.cobalt, FC.amber, FC.danger],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * CGFloat(min(status.limitUsedPercent / 100, 1.0)), height: 8)
                        .animation(.fineryCard.delay(0.2), value: status.limitUsedPercent)
                }
            }
            .frame(height: 8)

            HStack {
                statBlock(label: "Использовано", value: status.yearlyIncome.rub(),
                          color: trafficColor(status), align: .leading)
                Spacer()
                statBlock(label: "Осталось", value: status.remaining.rub(),
                          color: FC.muted, align: .center)
                Spacer()
                statBlock(label: "Лимит", value: TaxStatus.npdYearLimit.rub(),
                          color: FC.ink, align: .trailing)
            }

            if status.isNearLimit {
                infoBox(
                    icon: "info.circle",
                    text: "При превышении лимита потеряешь статус самозанятого. Оформи ИП заранее.",
                    color: FC.cobalt
                )
            }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - USN Tax Card (УСН 6% / УСН 15%)

    private func usnTaxCard(_ status: TaxStatus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(status.taxMode == .usn15 ? "НАЛОГ С ПРИБЫЛИ" : "НАЛОГ ЗА КВАРТАЛ").fLabel()
                Spacer()
                Text(status.effectiveRate)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.cobalt)
            }

            if status.taxMode == .usn15 {
                // Show income – expenses = profit × 15%
                HStack(spacing: 0) {
                    statBlock(label: "ДОХОД", value: status.quarterlyIncome.rub(),
                              color: FC.cobalt, align: .leading)
                    Rectangle().fill(FC.border).frame(width: 1, height: 44)
                    statBlock(label: "РАСХОДЫ", value: status.quarterlyExpenses.rub(),
                              color: FC.muted, align: .center)
                    Rectangle().fill(FC.border).frame(width: 1, height: 44)
                    statBlock(label: "ПРИБЫЛЬ", value: status.quarterlyProfit.rub(),
                              color: FC.ink, align: .trailing)
                }
                .frame(maxWidth: .infinity)
            } else {
                // USN 6%: just show quarterly income
                HStack {
                    statBlock(label: "ДОХОД ЗА КВАРТАЛ", value: status.quarterlyIncome.rub(),
                              color: FC.cobalt, align: .leading)
                    Spacer()
                    statBlock(label: "СТАВКА", value: "6%",
                              color: FC.ink, align: .trailing)
                }
            }

            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("К УПЛАТЕ").fLabel()
                    Text(status.taxDue.rub())
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(FC.cobalt)
                }
            }

            infoBox(
                icon: "calendar",
                text: status.taxMode == .usn15
                    ? "Налог с прибыли (доходы минус расходы). Авансовый платёж раз в квартал."
                    : "Авансовый платёж раз в квартал: 28 апреля, июля, октября, января.",
                color: FC.cobalt
            )
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Deadline Card

    private func deadlineCard(_ status: TaxStatus) -> some View {
        HStack(spacing: 0) {
            deadlineCell(label: "К УПЛАТЕ",       value: status.taxDue.rub(),
                         color: status.taxDue > 0 ? FC.cobalt : FC.muted)
            Rectangle().fill(FC.border).frame(width: 1)
            deadlineCell(label: "ДНЕЙ ОСТАЛОСЬ",  value: "\(status.daysUntilDeadline)",
                         color: status.daysUntilDeadline <= 5 ? FC.danger : FC.ink)
            Rectangle().fill(FC.border).frame(width: 1)
            deadlineCell(label: "ДЕДЛАЙН",        value: formattedDeadline(status.nextDeadline),
                         color: FC.ink)
        }
        .glassCard()
    }

    private func deadlineCell(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Cash Flow Forecast

    private func cashFlowCard(_ forecast: CashFlowForecast) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ПРОГНОЗ КАССОВОГО РАЗРЫВА").fLabel()
                Spacer()
                if forecast.willGoNegativeIn30Days {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle").fontWeight(.light).imageScale(.small)
                        Text("Риск разрыва").font(.system(.caption, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(FC.amber)
                }
            }

            HStack(spacing: 0) {
                forecastCell(label: "ТЕКУЩИЙ БАЛАНС",
                             value: forecast.currentBalance.rub(),
                             color: forecast.currentBalance >= 0 ? FC.cobalt : FC.muted)
                Rectangle().fill(FC.border).frame(width: 1)
                forecastCell(label: "ХВАТИТ НА",
                             value: forecast.daysUntilNegative.map { "\($0) дн." } ?? "∞",
                             color: forecastDaysColor(forecast))
                Rectangle().fill(FC.border).frame(width: 1)
                forecastCell(label: "РАСХОДЫ/МЕС",
                             value: forecast.avgMonthlyExpenses.rub(),
                             color: FC.muted)
            }
            .background(FC.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            infoBox(
                icon: forecast.willGoNegativeIn30Days ? "arrow.down.circle" : "chart.line.uptrend.xyaxis",
                text: forecast.willGoNegativeIn30Days
                    ? "Средний расход (\(forecast.avgMonthlyExpenses.rub())/мес) превышает доход. Пора сократить траты."
                    : "Среднемесячный доход за 3 мес: \(forecast.avgMonthlyIncome.rub()). Подушка в норме.",
                color: forecast.willGoNegativeIn30Days ? FC.amber : FC.cobalt
            )
        }
        .padding(20)
        .glassCard()
    }

    private func forecastCell(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func forecastDaysColor(_ forecast: CashFlowForecast) -> Color {
        guard let days = forecast.daysUntilNegative else { return FC.cobalt }
        if days <= 7  { return FC.amber }
        if days <= 30 { return FC.amber }
        return FC.cobalt
    }

    // MARK: - Year Summary

    private var yearSummaryCard: some View {
        HStack(spacing: 0) {
            yearCell(label: "ДОХОД ЗА ГОД", amount: viewModel.totalIncomeYear, color: FC.cobalt)
            Rectangle().fill(FC.border).frame(width: 1)
            yearCell(label: "НАЛОГ ЗА ГОД",  amount: viewModel.totalTaxYear,   color: FC.muted)
        }
        .glassCard()
    }

    private func yearCell(label: String, amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(amount.rub())
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - History

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ИСТОРИЯ ПО МЕСЯЦАМ").fLabel()
            ForEach(viewModel.monthlyHistory.reversed()) { item in
                HStack {
                    Text(item.monthLabel)
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .foregroundStyle(FC.ink)
                        .frame(width: 50, alignment: .leading)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.income.rub())
                            .font(.system(.subheadline, design: .rounded, weight: .regular))
                            .monospacedDigit()
                            .foregroundStyle(FC.cobalt)
                        Text("Налог: " + item.taxAmount.rub())
                            .font(.system(.caption2, design: .rounded, weight: .regular))
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
        .padding(20)
        .glassCard()
    }

    // MARK: - Personal Tracker Stub

    private var personalTrackerStub: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(FC.muted)
            VStack(spacing: 8) {
                Text("Личный трекер")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text("Налоги не отслеживаются.\nЭтот режим — для личного бюджета без налоговой отчётности.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FC.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Loading

    private var loadingState: some View {
        HStack {
            Spacer()
            ProgressView().tint(FC.cobalt).padding(.vertical, 60)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func statBlock(label: String, value: String, color: Color, align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 2) {
            Text(label).fLabel()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
    }

    private func infoBox(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).fontWeight(.light).foregroundStyle(color)
            Text(text)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(FC.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func trafficColor(_ status: TaxStatus) -> Color {
        switch status.trafficLight {
        case .green:  FC.cobalt
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
        DateFormatter().also { $0.dateFormat = "yyyy" }.string(from: Date()) + " год"
    }
}

private extension DateFormatter {
    func also(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self); return self
    }
}

// MARK: - Card appear

private extension View {
    func cardAppear(appeared: Bool, delay: Double) -> some View {
        self
            .offset(y: appeared ? 0 : 60)
            .opacity(appeared ? 1 : 0)
            .animation(.fineryCard.delay(delay), value: appeared)
    }
}

#Preview {
    TaxView(viewModel: .preview())
}
