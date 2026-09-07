import SwiftUI

struct TaxView: View {
    @State var viewModel: TaxViewModel
    @State private var appeared = false
    @State private var ringProgress: Double = 0

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
                        // WIDGET 1: Tax mode (НПД / УСН) — режим одной строкой
                        taxModeWidget(status)
                            .cardAppear(appeared: appeared, delay: 0.08)

                        if status.showNpdLimit {
                            // WIDGET 2: NPD limit progress — only current state, no duplicates
                            npdLimitWidget(status)
                                .cardAppear(appeared: appeared, delay: 0.16)

                            // WIDGET 3: NPD forecast — only forecast data, no used/remaining repeat
                            if let nf = viewModel.npdForecast {
                                npdForecastWidget(nf)
                                    .cardAppear(appeared: appeared, delay: 0.22)
                            }
                        } else {
                            // WIDGET 2 (USN): quarterly tax breakdown
                            usnTaxWidget(status)
                                .cardAppear(appeared: appeared, delay: 0.16)
                        }

                        // WIDGET 4: Deadline — к уплате / дней / дедлайн
                        deadlineWidget(status)
                            .cardAppear(appeared: appeared, delay: 0.28)

                        // WIDGET 5: Cash flow forecast
                        if let forecast = viewModel.cashFlowForecast {
                            cashFlowWidget(forecast)
                                .cardAppear(appeared: appeared, delay: 0.34)
                        }

                        // WIDGET 6: Year summary
                        yearSummaryWidget
                            .cardAppear(appeared: appeared, delay: 0.40)

                        // WIDGET 7: Monthly history
                        historyWidget
                            .cardAppear(appeared: appeared, delay: 0.46)

                    } else if viewModel.isLoading {
                        loadingState
                    } else if viewModel.userType == .other {
                        personalTrackerStub
                            .cardAppear(appeared: appeared, delay: 0.08)
                    } else {
                        noDataStub
                            .cardAppear(appeared: appeared, delay: 0.08)
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
        }
        .task {
            await viewModel.load()
            if let status = viewModel.taxStatus, status.showNpdLimit {
                let target = min(status.limitUsedPercent / 100.0, 1.0)
                withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
                    ringProgress = target
                }
            }
        }
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
                    .fTitle()
                    .foregroundStyle(FC.ink)
                Text(currentYearLabel)
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.inkSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    // MARK: - WIDGET 1: Tax Mode

    private func taxModeWidget(_ status: TaxStatus) -> some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Режим").fLabel()
                Text(status.taxMode.displayName)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text(status.taxMode.shortDescription)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
            }
            Spacer()
            Text(status.taxMode.shortDescription.contains("4") || status.taxMode.shortDescription.contains("6") ? status.effectiveRate : "%")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(FC.cobalt.opacity(0.20))
        }
        .padding(20)
        .dataWidget()
    }

    // MARK: - WIDGET 2a: NPD Limit (progress + numbers, no duplicate text)

    private func npdLimitWidget(_ status: TaxStatus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Лимит НПД").fLabel()
                Spacer()
                if status.isNearLimit {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle").fontWeight(.light).imageScale(.small)
                        Text(status.isOverLimit ? "Превышен" : "Внимание")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(status.isOverLimit ? FC.danger : FC.warning)
                }
            }

            // Ring + stats
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    RingProgressView(
                        progress: ringProgress,
                        color: trafficColor(status),
                        size: 72,
                        lineWidth: 7
                    )
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: appeared)

                    VStack(spacing: 1) {
                        Text("\(Int(status.limitUsedPercent))%")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(trafficColor(status))
                            .contentTransition(.numericText())
                        Text("НПД")
                            .font(.system(size: 9, weight: .regular, design: .rounded))
                            .foregroundStyle(FC.inkSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    statBlock(label: "Использовано", value: status.yearlyIncome.rub(),
                              color: trafficColor(status), align: .leading)
                    statBlock(label: "Осталось", value: status.remaining.rub(),
                              color: FC.inkSecondary, align: .leading)
                    statBlock(label: "Лимит", value: TaxStatus.npdYearLimit.rub(),
                              color: FC.ink, align: .leading)
                }

                Spacer()
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
        .dataWidget()
    }

    // MARK: - WIDGET 3: NPD Forecast (only forecast, used/remaining NOT repeated here)

    private func npdForecastWidget(_ forecast: NpdForecast) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Прогноз лимита НПД").fLabel()

            if let days = forecast.daysToLimit {
                let color = days < 30 ? FC.danger : days < 90 ? FC.warning : FC.success
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: days < 30 ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
                            .foregroundStyle(color)
                            .font(.system(size: 15))
                        Text("При текущем темпе — через \(days) дн.")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(FC.ink)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.18), lineWidth: 0.5))

                    if days < 60 {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb").foregroundStyle(FC.warning)
                                .font(.system(size: 13))
                            Text("Рассмотрите переход на УСН 6%")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(FC.inkSecondary)
                        }
                    }
                }
            } else {
                Text("Темп поступлений пока не определён")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
            }
        }
        .padding(20)
        .dataWidget()
    }

    // MARK: - WIDGET 2b: USN Quarterly Tax

    private func usnTaxWidget(_ status: TaxStatus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(status.taxMode == .usn15 ? "Налог с прибыли" : "Налог за квартал").fLabel()
                Spacer()
                Text(status.effectiveRate)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.cobalt)
            }

            if status.taxMode == .usn15 {
                HStack(spacing: 0) {
                    statBlock(label: "Доход", value: status.quarterlyIncome.rub(),
                              color: FC.cobalt, align: .leading)
                    Rectangle().fill(FC.border).frame(width: 1, height: 44)
                    statBlock(label: "Расходы", value: status.quarterlyExpenses.rub(),
                              color: FC.inkSecondary, align: .center)
                    Rectangle().fill(FC.border).frame(width: 1, height: 44)
                    statBlock(label: "Прибыль", value: status.quarterlyProfit.rub(),
                              color: FC.ink, align: .trailing)
                }
                .frame(maxWidth: .infinity)
            } else {
                HStack {
                    statBlock(label: "Доход за квартал", value: status.quarterlyIncome.rub(),
                              color: FC.cobalt, align: .leading)
                    Spacer()
                    statBlock(label: "Ставка", value: "6%", color: FC.ink, align: .trailing)
                }
            }

            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("К уплате").fLabel()
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
        .dataWidget()
    }

    // MARK: - WIDGET 4: Deadline (к уплате / дней / дедлайн)

    private func deadlineWidget(_ status: TaxStatus) -> some View {
        HStack(spacing: 0) {
            deadlineCell(label: "К уплате",
                         value: status.taxDue.rub(),
                         color: status.taxDue > 0 ? FC.cobalt : FC.inkSecondary)
            Rectangle().fill(FC.border).frame(width: 1)
            deadlineCell(label: "Дней осталось",
                         value: "\(status.daysUntilDeadline)",
                         color: status.daysUntilDeadline <= 5 ? FC.danger : FC.ink)
            Rectangle().fill(FC.border).frame(width: 1)
            deadlineCell(label: "Дедлайн",
                         value: formattedDeadline(status.nextDeadline),
                         color: FC.ink)
        }
        .dataWidget()
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

    // MARK: - WIDGET 5: Cash Flow Forecast (no detail screen — not tappable)

    private func cashFlowWidget(_ forecast: CashFlowForecast) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Прогноз кассового разрыва").fLabel()
                Spacer()
                if forecast.willGoNegativeIn30Days {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle").fontWeight(.light).imageScale(.small)
                        Text("Риск разрыва")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(FC.warning)
                }
            }

            HStack(spacing: 0) {
                forecastCell(label: "Текущий баланс",
                             value: forecast.currentBalance.rub(),
                             color: forecast.currentBalance >= 0 ? FC.cobalt : FC.inkSecondary)
                Rectangle().fill(FC.border).frame(width: 1)
                forecastCell(label: "Хватит на",
                             value: forecast.daysUntilNegative.map { "\($0) дн." } ?? "∞",
                             color: forecastDaysColor(forecast))
                Rectangle().fill(FC.border).frame(width: 1)
                forecastCell(label: "Расходы/мес",
                             value: forecast.avgMonthlyExpenses.rub(),
                             color: FC.inkSecondary)
            }
            .background(FC.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            infoBox(
                icon: forecast.willGoNegativeIn30Days ? "arrow.down.circle" : "chart.line.uptrend.xyaxis",
                text: forecast.willGoNegativeIn30Days
                    ? "Средний расход (\(forecast.avgMonthlyExpenses.rub())/мес) превышает доход. Пора сократить траты."
                    : "Среднемесячный доход за 3 мес: \(forecast.avgMonthlyIncome.rub()). Подушка в норме.",
                color: forecast.willGoNegativeIn30Days ? FC.warning : FC.cobalt
            )
        }
        .padding(20)
        .dataWidget()
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
        if days <= 7  { return FC.warning }
        if days <= 30 { return FC.warning }
        return FC.cobalt
    }

    // MARK: - WIDGET 6: Year Summary

    private var yearSummaryWidget: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Доход за год").fLabel()
                Text(viewModel.totalIncomeYear.rub())
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(FC.cobalt)
                    .contentTransition(.numericText())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Налог за год").fLabel()
                Text(viewModel.totalTaxYear.rub())
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(FC.inkSecondary)
                    .contentTransition(.numericText())
            }
        }
        .padding(20)
        .dataWidget()
    }

    // MARK: - WIDGET 7: Monthly History

    private var historyWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("История по месяцам").fLabel()
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
                            .foregroundStyle(FC.inkSecondary)
                    }
                }
                .padding(.vertical, 6)
                if item.id != viewModel.monthlyHistory.reversed().last?.id {
                    Rectangle().fill(FC.border.opacity(0.5)).frame(height: 0.5)
                }
            }
        }
        .padding(20)
        .dataWidget()
    }

    // MARK: - Stubs

    private var noDataStub: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(FC.inkSecondary)
            VStack(spacing: 8) {
                Text("Нет данных")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text("Налоговый статус загружается с сервера.\nПроверьте подключение и обновите экран.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Обновить")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(FC.cobalt)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(FC.cobalt.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity)
    }

    private var personalTrackerStub: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(FC.inkSecondary)
            VStack(spacing: 8) {
                Text("Личный трекер")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text("Налоги не отслеживаются.\nЭтот режим — для личного бюджета без налоговой отчётности.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FC.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity)
    }

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
                .foregroundStyle(FC.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(color.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.18), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func trafficColor(_ status: TaxStatus) -> Color {
        switch status.trafficLight {
        case .green:  FC.cobalt
        case .yellow: FC.warning
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
