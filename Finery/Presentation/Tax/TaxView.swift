import SwiftUI

struct TaxView: View {
    @State var viewModel: TaxViewModel
    @State private var appeared = false

    init(viewModel: TaxViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            FC.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    pageHeader
                        .offset(y: appeared ? 0 : -16)
                        .opacity(appeared ? 1 : 0)

                    if let status = viewModel.taxStatus {
                        taxModeCard(status)
                            .cardAppear(appeared: appeared, delay: 0.08)
                        limitCard(status)
                            .cardAppear(appeared: appeared, delay: 0.16)
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
        .padding(.horizontal, 4)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    // MARK: Tax Mode Card

    private func taxModeCard(_ status: TaxStatus) -> some View {
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
                Circle()
                    .fill(FC.cobalt.opacity(0.18))
                    .frame(width: 52, height: 52)
                Text("%")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(FC.cobalt)
            }
            .shadow(color: FC.cobaltGlow, radius: 10)
        }
        .padding(20)
        .glassCard()
    }

    // MARK: NPD Limit Card

    private func limitCard(_ status: TaxStatus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(
                            colors: [FC.success, FC.amber, FC.danger],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(
                            width: geo.size.width * CGFloat(min(status.limitUsedPercent / 100, 1.0)),
                            height: 8
                        )
                        .shadow(color: trafficColor(status).opacity(0.5), radius: 8)
                        .animation(.fineryCard.delay(0.2), value: status.limitUsedPercent)
                }
            }
            .frame(height: 8)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Использовано").fLabel()
                    Text(status.yearlyIncome.rub())
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(trafficColor(status))
                        .contentTransition(.numericText())
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
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .fontWeight(.light)
                        .foregroundStyle(FC.cobalt)
                    Text("При превышении лимита потеряешь статус самозанятого. Оформи ИП заранее.")
                        .font(.system(.caption))
                        .foregroundStyle(FC.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(FC.cobalt.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(FC.cobalt.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: Deadline Card

    private func deadlineCard(_ status: TaxStatus) -> some View {
        HStack(spacing: 0) {
            deadlineCell(
                label: "К УПЛАТЕ",
                value: status.taxDue.rub(),
                color: status.taxDue > 0 ? FC.danger : FC.muted
            )
            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1)
            deadlineCell(
                label: "ДНЕЙ ОСТАЛОСЬ",
                value: "\(max(0, status.daysUntilDeadline))",
                color: status.daysUntilDeadline <= 5 ? FC.danger : FC.ink
            )
            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1)
            deadlineCell(
                label: "ДЕДЛАЙН",
                value: formattedDeadline(status.nextDeadline),
                color: FC.ink
            )
        }
        .glassCard()
    }

    private func deadlineCell(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(value)
                .font(.system(.headline, design: .default, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Cash Flow Forecast Card

    private func cashFlowCard(_ forecast: CashFlowForecast) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ПРОГНОЗ КАССОВОГО РАЗРЫВА").fLabel()
                Spacer()
                if forecast.willGoNegativeIn30Days {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .fontWeight(.light)
                            .imageScale(.small)
                        Text("Риск разрыва")
                            .font(.system(.caption, design: .default, weight: .semibold))
                    }
                    .foregroundStyle(FC.danger)
                }
            }

            HStack(spacing: 0) {
                forecastCell(
                    label: "ТЕКУЩИЙ БАЛАНС",
                    value: forecast.currentBalance.rub(),
                    color: forecast.currentBalance >= 0 ? FC.success : FC.danger
                )
                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1)
                forecastCell(
                    label: "ХВАТИТ НА",
                    value: forecast.daysUntilNegative.map { "\($0) дн." } ?? "∞",
                    color: forecastDaysColor(forecast)
                )
                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1)
                forecastCell(
                    label: "РАСХОДЫ/МЕС",
                    value: forecast.avgMonthlyExpenses.rub(),
                    color: FC.muted
                )
            }
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Average income trend
            HStack(spacing: 10) {
                Image(systemName: forecast.willGoNegativeIn30Days ? "arrow.down.circle" : "chart.line.uptrend.xyaxis")
                    .fontWeight(.light)
                    .foregroundStyle(forecast.willGoNegativeIn30Days ? FC.danger : FC.cobalt)
                let avgIncome = forecast.avgMonthlyIncome
                let avgExpenses = forecast.avgMonthlyExpenses
                if forecast.willGoNegativeIn30Days {
                    Text("Средний расход (\(avgExpenses.rub())/мес) превышает доход (\(avgIncome.rub())/мес). Пора сократить траты.")
                        .font(.system(.caption))
                        .foregroundStyle(FC.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Среднемесячный доход за 3 мес: \(avgIncome.rub()). Финансовая подушка в норме.")
                        .font(.system(.caption))
                        .foregroundStyle(FC.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(forecast.willGoNegativeIn30Days ? FC.danger.opacity(0.1) : FC.cobalt.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(forecast.willGoNegativeIn30Days ? FC.danger.opacity(0.3) : FC.cobalt.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
        .glassCard()
    }

    private func forecastCell(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(value)
                .font(.system(.subheadline, design: .default, weight: .semibold))
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
        guard let days = forecast.daysUntilNegative else { return FC.success }
        if days <= 7  { return FC.danger }
        if days <= 30 { return FC.amber }
        return FC.success
    }

    // MARK: Year Summary Card

    private var yearSummaryCard: some View {
        HStack(spacing: 0) {
            yearCell(label: "ДОХОД ЗА ГОД", amount: viewModel.totalIncomeYear, color: FC.success)
            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1)
            yearCell(label: "НАЛОГ ЗА ГОД",  amount: viewModel.totalTaxYear,   color: FC.danger)
        }
        .glassCard()
    }

    private func yearCell(label: String, amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(amount.rub())
                .font(.system(.subheadline, design: .default, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: History Card

    private var historyCard: some View {
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
                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 0.5)
                }
            }
        }
        .padding(20)
        .glassCard()
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

// MARK: - Card appear animation helper

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
