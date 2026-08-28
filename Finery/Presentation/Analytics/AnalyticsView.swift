import SwiftUI
import Charts

private enum AnalyticsMode: String, CaseIterable {
    case dynamics   = "Динамика"
    case seasonal   = "Сезонность"
}

struct AnalyticsView: View {
    @State var viewModel: AnalyticsViewModel
    @State private var mode: AnalyticsMode = .dynamics
    @State private var csvShareData: Data? = nil
    @State private var showCSVShare = false

    init(viewModel: AnalyticsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    pageHeader
                    hairline
                    modePicker
                    hairline
                    if mode == .seasonal {
                        seasonalSection
                    } else {
                    comparisonSection
                    hairline
                    barChartSection
                    hairline
                    if !viewModel.incomeBreakdown.isEmpty {
                        hairline
                        pieSection(
                            title: "ДОХОДЫ ПО КАТЕГОРИЯМ",
                            slices: viewModel.incomeBreakdown.map { ($0.category.displayName, $0.amount, $0.percent) },
                            accentColor: FC.cobalt
                        )
                        hairline
                        breakdownSection(
                            title: "СТРУКТУРА ДОХОДОВ",
                            rows: viewModel.incomeBreakdown.map { ($0.category.displayName, $0.category.iconName, $0.amount, $0.percent) }
                        )
                        hairline
                    }
                    if !viewModel.expenseBreakdown.isEmpty {
                        pieSection(
                            title: "РАСХОДЫ ПО КАТЕГОРИЯМ",
                            slices: viewModel.expenseBreakdown.map { ($0.category.displayName, $0.amount, $0.percent) },
                            accentColor: FC.danger
                        )
                        hairline
                        breakdownSection(
                            title: "СТРУКТУРА РАСХОДОВ",
                            rows: viewModel.expenseBreakdown.map { ($0.category.displayName, $0.category.iconName, $0.amount, $0.percent) },
                            accentColor: FC.muted
                        )
                    }
                    // 7.1 — Top clients
                    if !viewModel.clientIncomeBreakdown.isEmpty {
                        hairline
                        topClientsSection
                    }

                    // 7.2 — Forecast
                    if let forecast = viewModel.nextMonthForecast {
                        hairline
                        forecastSection(forecast)
                    }

                    } // end else (dynamics mode)
                    Color.clear.frame(height: 40)
                }
            }
        }
        .task { await viewModel.load() }
        .alert("Ошибка загрузки", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showingPDFShare) {
            if let data = viewModel.exportedPDFData {
                ShareSheet(data: data, filename: "finery-report.pdf")
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showCSVShare) {
            if let data = csvShareData {
                ShareSheet(data: data, filename: "finery-transactions.csv")
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: Header

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Аналитика")
                    .font(.system(.title2, design: .default, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text(currentMonthLabel)
                    .font(.system(.caption, design: .default, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            Menu {
                Button { viewModel.generatePDF() } label: {
                    Label("PDF-отчёт", systemImage: "doc.richtext")
                }
                Button { exportCSV() } label: {
                    Label("CSV (Excel)", systemImage: "tablecells")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .fontWeight(.medium)
                        .imageScale(.small)
                    Text("Экспорт")
                        .font(.system(.caption, design: .default, weight: .semibold))
                }
                .foregroundStyle(FC.cobalt)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(FC.cobalt.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(FC.cobalt.opacity(0.25), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: Comparison

    private var comparisonSection: some View {
        HStack(spacing: 0) {
            comparisonCard(
                label: "ЭТОТ МЕСЯЦ",
                amount: viewModel.currentMonthIncome,
                color: FC.cobalt
            )
            Rectangle().fill(FC.border).frame(width: 0.5)
            comparisonCard(
                label: "ПРОШЛЫЙ МЕСЯЦ",
                amount: viewModel.previousMonthIncome,
                color: FC.muted
            )
            Rectangle().fill(FC.border).frame(width: 0.5)
            changeCard
        }
        .background(FC.surface)
    }

    private func comparisonCard(label: String, amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(amount.rub())
                .font(.system(.subheadline, design: .default, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var changeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ИЗМЕНЕНИЕ").fLabel()
            HStack(spacing: 4) {
                Image(systemName: viewModel.incomeChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .fontWeight(.semibold)
                    .imageScale(.small)
                Text(String(format: "%.0f%%", abs(viewModel.incomeChange)))
                    .font(.system(.subheadline, design: .default, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(viewModel.incomeChange >= 0 ? FC.cobalt : FC.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Bar Chart

    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ДИНАМИКА ЗА 6 МЕСЯЦЕВ").fLabel()

            if viewModel.monthlyData.isEmpty {
                Rectangle()
                    .fill(FC.border.opacity(0.3))
                    .frame(height: 160)
                    .overlay(
                        Text("Нет данных")
                            .font(.system(.caption))
                            .foregroundStyle(FC.muted)
                    )
            } else {
                Chart(viewModel.monthlyData) { item in
                    BarMark(
                        x: .value("Месяц", item.monthLabel),
                        y: .value("Доход", NSDecimalNumber(decimal: item.income).doubleValue)
                    )
                    .foregroundStyle(FC.cobalt)
                    .cornerRadius(0)

                    BarMark(
                        x: .value("Месяц", item.monthLabel),
                        y: .value("Расходы", -NSDecimalNumber(decimal: item.expenses).doubleValue)
                    )
                    .foregroundStyle(FC.muted.opacity(0.55))
                    .cornerRadius(0)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(FC.border)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(Decimal(v).rub())
                                    .font(.system(.caption2))
                                    .foregroundStyle(FC.muted)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(.caption2, design: .default, weight: .regular))
                            .foregroundStyle(FC.muted)
                    }
                }
                .frame(height: 180)

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: FC.cobalt, label: "Доходы")
                    legendItem(color: FC.muted.opacity(0.55), label: "Расходы")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Rectangle().fill(color).frame(width: 12, height: 3)
            Text(label)
                .font(.system(.caption2, design: .default, weight: .regular))
                .foregroundStyle(FC.muted)
        }
    }

    // MARK: Breakdown

    private func breakdownSection(
        title: String,
        rows: [(name: String, icon: String, amount: Decimal, percent: Double)],
        accentColor: Color = FC.cobalt
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).fLabel()

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: row.icon)
                            .fontWeight(.light)
                            .imageScale(.small)
                            .foregroundStyle(accentColor)
                            .frame(width: 16)
                        Text(row.name)
                            .font(.system(.subheadline, design: .default, weight: .regular))
                            .foregroundStyle(FC.ink)
                        Spacer()
                        Text(row.amount.rub())
                            .font(.system(.subheadline, design: .default, weight: .medium))
                            .monospacedDigit()
                            .foregroundStyle(FC.ink)
                        Text(String(format: "%.0f%%", row.percent))
                            .font(.system(.caption, design: .default, weight: .regular))
                            .monospacedDigit()
                            .foregroundStyle(FC.muted)
                            .frame(width: 36, alignment: .trailing)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(FC.border.opacity(0.4)).frame(height: 2)
                            Rectangle()
                                .fill(accentColor)
                                .frame(width: geo.size.width * CGFloat(row.percent / 100), height: 2)
                        }
                    }
                    .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: Pie Chart

    private func pieSection(
        title: String,
        slices: [(name: String, amount: Decimal, percent: Double)],
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).fLabel()
            HStack(alignment: .center, spacing: 20) {
                Chart(Array(slices.enumerated()), id: \.offset) { idx, item in
                    SectorMark(
                        angle: .value("Сумма", max(item.percent, 1)),
                        innerRadius: .ratio(0.52),
                        angularInset: 1.5
                    )
                    .foregroundStyle(pieColor(idx, base: accentColor))
                    .cornerRadius(3)
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(slices.prefix(6).enumerated()), id: \.offset) { idx, item in
                        HStack(spacing: 7) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(pieColor(idx, base: accentColor))
                                .frame(width: 10, height: 10)
                            Text(item.name)
                                .font(.system(.caption2, design: .default))
                                .foregroundStyle(FC.ink)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text(String(format: "%.0f%%", item.percent))
                                .font(.system(.caption2, design: .default, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(FC.muted)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    private func pieColor(_ index: Int, base: Color) -> Color {
        let opacities: [Double] = [1.0, 0.72, 0.52, 0.38, 0.26, 0.18]
        return base.opacity(opacities[min(index, opacities.count - 1)])
    }

    // MARK: Helpers

    // MARK: Mode Picker

    private var modePicker: some View {
        Picker("Режим", selection: $mode) {
            ForEach(AnalyticsMode.allCases, id: \.self) { m in
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: Seasonal Section

    @ViewBuilder
    private var seasonalSection: some View {
        if let data = viewModel.seasonalAnalysis {
            VStack(alignment: .leading, spacing: 0) {
                // Insight card
                VStack(alignment: .leading, spacing: 8) {
                    Text("СЕЗОННЫЙ АНАЛИЗ").fLabel()
                    Text(data.currentMonthInsight)
                        .font(.system(.subheadline, design: .default, weight: .medium))
                        .foregroundStyle(FC.ink)

                    let best  = data.monthlyAverages.first(where: { $0.month == data.bestMonth })
                    let worst = data.monthlyAverages.first(where: { $0.month == data.worstMonth })

                    if let b = best {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill").foregroundStyle(Color(h: "4A7A2E"))
                            Text("Лучший месяц — \(b.shortLabel) (+\(data.bestMonthDiffPct)% к среднему)")
                                .font(.system(.caption, design: .default)).foregroundStyle(FC.muted)
                        }
                    }
                    if let w = worst {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill").foregroundStyle(FC.danger)
                            Text("Слабый месяц — \(w.shortLabel) (\(data.worstMonthDiffPct)% к среднему)")
                                .font(.system(.caption, design: .default)).foregroundStyle(FC.muted)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                hairline

                // Bar chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("ДОХОД ПО МЕСЯЦАМ").fLabel()
                    Chart {
                        ForEach(data.monthlyAverages) { avg in
                            BarMark(
                                x: .value("Месяц", avg.shortLabel),
                                y: .value("Доход", avg.avgIncomeDouble)
                            )
                            .foregroundStyle(
                                avg.month == data.bestMonth
                                    ? Color(h: "5A9A2E")   // highlighted best — green
                                    : FC.cobalt.opacity(0.75)
                            )
                            .cornerRadius(3)

                            BarMark(
                                x: .value("Месяц", avg.shortLabel),
                                y: .value("Расход", -avg.avgExpenseDouble)
                            )
                            .foregroundStyle(
                                avg.month == data.worstMonth
                                    ? FC.danger
                                    : FC.muted.opacity(0.4)
                            )
                            .cornerRadius(3)
                        }
                    }
                    .chartYAxis {
                        AxisMarks {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(FC.border)
                            AxisValueLabel()
                                .font(.system(.caption2))
                                .foregroundStyle(FC.muted)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.system(size: 9, design: .default))
                                .foregroundStyle(FC.muted)
                        }
                    }
                    .frame(height: 200)

                    HStack(spacing: 16) {
                        legendItem(color: FC.cobalt.opacity(0.75), label: "Доходы (ср.)")
                        legendItem(color: FC.muted.opacity(0.4), label: "Расходы (ср.)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(FC.muted.opacity(0.5))
                Text("Недостаточно данных для сезонного анализа")
                    .font(.system(.subheadline, design: .default))
                    .foregroundStyle(FC.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        }
    }

    private var hairline: some View {
        Rectangle().fill(FC.border).frame(height: 0.5)
    }

    private var currentMonthLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy"
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt.string(from: Date()).capitalized
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 7.1 Top clients

extension AnalyticsView {
    var topClientsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ТОП КЛИЕНТОВ").fLabel()
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 10)
            ForEach(Array(viewModel.clientIncomeBreakdown.enumerated()), id: \.offset) { idx, row in
                HStack(spacing: 12) {
                    Text("\(idx + 1)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(FC.muted)
                        .frame(width: 18)
                    Text(row.clientName)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(FC.ink)
                        .lineLimit(1)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(row.amount.rub())
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(FC.ink)
                        Text(String(format: "%.0f%%", row.percent))
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(FC.muted)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                if idx < viewModel.clientIncomeBreakdown.count - 1 {
                    Rectangle().fill(FC.border).frame(height: 0.5).padding(.leading, 50)
                }
            }
            Color.clear.frame(height: 8)
        }
    }
}

// MARK: - 7.2 Forecast + 7.3 CSV export

extension AnalyticsView {
    func forecastSection(_ forecast: Decimal) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ПРОГНОЗ НА СЛ. МЕСЯЦ").fLabel()
                Text(forecast.rub())
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text("Среднее за последние 3 месяца")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(FC.cobalt.opacity(0.5))
        }
        .padding(20)
    }

    func exportCSV() {
        let csv = viewModel.generateCSV()
        if let data = csv.data(using: .utf8) {
            csvShareData = data
            showCSVShare = true
        }
    }
}

#Preview {
    AnalyticsView(viewModel: .preview())
}
