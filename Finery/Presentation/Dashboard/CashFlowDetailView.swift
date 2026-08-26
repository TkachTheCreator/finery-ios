import SwiftUI
import Charts

// MARK: - Daily amount model (used by the chart)

private struct DailyAmount: Identifiable {
    let id = UUID()
    let day: Date
    let amount: Decimal
    var doubleAmount: Double { NSDecimalNumber(decimal: amount).doubleValue }
}

// MARK: - CashFlowDetailView

struct CashFlowDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage = 0

    private var cal: Calendar { Calendar.current }

    private var monthStart: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }

    private var monthTransactions: [Transaction] {
        SharedDataService.shared.transactions
            .filter { $0.date >= monthStart && $0.date <= Date() }
    }

    private var totalIncome: Decimal {
        SharedDataService.shared.pnl?.totalIncome
            ?? monthTransactions.filter { $0.direction == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Decimal {
        SharedDataService.shared.pnl?.totalExpenses
            ?? monthTransactions.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                hairline
                pageSelector
                hairline

                TabView(selection: $selectedPage) {
                    pageContent(direction: .income).tag(0)
                    pageContent(direction: .expense).tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FC.muted)
                    .frame(width: 30, height: 30)
                    .background(FC.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(FC.border, lineWidth: 0.5))
            }
            Spacer()
            Text("Денежный поток")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(FC.ink)
            Spacer()
            Color.clear.frame(width: 30, height: 30)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var hairline: some View {
        Rectangle().fill(FC.border).frame(height: 0.5)
    }

    // MARK: - Page Selector

    private var pageSelector: some View {
        HStack(spacing: 0) {
            selectorTab(label: "ДОХОДЫ", index: 0, color: FC.cobalt, amount: totalIncome)
            Rectangle().fill(FC.border).frame(width: 0.5)
            selectorTab(label: "РАСХОДЫ", index: 1, color: FC.muted, amount: totalExpenses)
        }
        .frame(height: 62)
    }

    private func selectorTab(label: String, index: Int, color: Color, amount: Decimal) -> some View {
        let selected = selectedPage == index
        return Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) { selectedPage = index }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(selected ? color : FC.muted)
                Text(amount.rub())
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(selected ? color : FC.muted.opacity(0.6))
                    .contentTransition(.numericText())
                    .animation(.fineryNumber, value: amount)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .background(selected ? color.opacity(0.06) : Color.clear)
            .overlay(alignment: .bottom) {
                Rectangle().fill(selected ? color : Color.clear).frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selected)
    }

    // MARK: - Page Content

    @ViewBuilder
    private func pageContent(direction: TransactionDirection) -> some View {
        let color: Color = direction == .income ? FC.cobalt : FC.muted
        let total: Decimal = direction == .income ? totalIncome : totalExpenses
        let txns = monthTransactions.filter { $0.direction == direction }.sorted { $0.date > $1.date }
        let daily = dailyTotals(for: direction)
        let emptyLabel = direction == .income ? "Нет доходов за этот месяц" : "Нет расходов за этот месяц"
        let sectionTitle = direction == .income ? "ВСЕ ДОХОДЫ" : "ВСЕ РАСХОДЫ"

        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                chartCard(color: color, total: total, daily: daily, emptyLabel: emptyLabel, direction: direction)
                transactionBlock(title: sectionTitle, transactions: txns, emptyLabel: emptyLabel)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Chart Card

    private func chartCard(
        color: Color,
        total: Decimal,
        daily: [DailyAmount],
        emptyLabel: String,
        direction: TransactionDirection
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(direction == .income ? "ДОХОД ЗА МЕСЯЦ" : "РАСХОДЫ ЗА МЕСЯЦ")
                    .fLabel()
                Text(total.rub())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(direction == .income ? FC.cobalt : FC.ink)
                    .contentTransition(.numericText())
                    .animation(.fineryNumber, value: total)
            }

            if daily.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .foregroundStyle(FC.muted.opacity(0.5))
                    Text(emptyLabel)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(FC.muted)
                }
                .padding(.vertical, 12)
            } else {
                Chart(daily) { point in
                    BarMark(
                        x: .value("День", point.day, unit: .day),
                        y: .value("Сумма", point.doubleAmount)
                    )
                    .foregroundStyle(color.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(FC.muted)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(FC.border.opacity(0.5))
                        AxisValueLabel {
                            if let d = val.as(Double.self) {
                                Text(compactRub(d))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(FC.muted)
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(16)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
    }

    // MARK: - Transaction block

    @ViewBuilder
    private func transactionBlock(title: String, transactions: [Transaction], emptyLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).fLabel()

            if transactions.isEmpty {
                Text(emptyLabel)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FC.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(transactions) { tx in
                    TransactionRow(transaction: tx)
                }
            }
        }
    }

    // MARK: - Helpers

    private func dailyTotals(for direction: TransactionDirection) -> [DailyAmount] {
        var byDay: [Date: Decimal] = [:]
        for tx in monthTransactions where tx.direction == direction {
            let day = cal.startOfDay(for: tx.date)
            byDay[day, default: 0] += tx.amount
        }
        return byDay
            .map { DailyAmount(day: $0.key, amount: $0.value) }
            .sorted { $0.day < $1.day }
    }

    private func compactRub(_ value: Double) -> String {
        let suffix = "\u{202F}₽"
        if value >= 1_000_000 { return String(format: "%.1fМ", value / 1_000_000) + suffix }
        if value >= 1_000     { return String(format: "%.0fК", value / 1_000)     + suffix }
        return String(format: "%.0f", value) + suffix
    }
}
