import SwiftUI
import Charts

struct AnalyticsView: View {
    @State var viewModel: AnalyticsViewModel

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
                    comparisonSection
                    hairline
                    barChartSection
                    hairline
                    if !viewModel.incomeBreakdown.isEmpty {
                        breakdownSection(
                            title: "СТРУКТУРА ДОХОДОВ",
                            rows: viewModel.incomeBreakdown.map { ($0.category.displayName, $0.category.iconName, $0.amount, $0.percent) }
                        )
                        hairline
                    }
                    if !viewModel.expenseBreakdown.isEmpty {
                        breakdownSection(
                            title: "СТРУКТУРА РАСХОДОВ",
                            rows: viewModel.expenseBreakdown.map { ($0.category.displayName, $0.category.iconName, $0.amount, $0.percent) },
                            accentColor: FC.danger
                        )
                    }
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
            Button {
                viewModel.generatePDF()
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
                color: FC.success
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
            .foregroundStyle(viewModel.incomeChange >= 0 ? FC.success : FC.danger)
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
                    .foregroundStyle(FC.danger.opacity(0.6))
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
                    legendItem(color: FC.danger.opacity(0.6), label: "Расходы")
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

    // MARK: Helpers

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

#Preview {
    AnalyticsView(viewModel: .preview())
}
