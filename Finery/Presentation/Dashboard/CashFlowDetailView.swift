import SwiftUI
import Charts

// MARK: - Category slice model

private struct CategorySlice: Identifiable {
    let id = UUID()
    let name: String
    let amount: Decimal
    var percentage: Double = 0
}

// MARK: - CashFlowDetailView

struct CashFlowDetailView: View {
    let dashboardViewModel: DashboardViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage   = 0
    @State private var monthOffset    = 0
    @State private var editingTransaction: Transaction? = nil

    private var cal: Calendar { Calendar.current }

    private var displayedMonthStart: Date {
        let thisMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
        return cal.date(byAdding: .month, value: monthOffset, to: thisMonth)!
    }

    private var displayedMonthEnd: Date {
        cal.date(byAdding: .second, value: -1,
                 to: cal.date(byAdding: .month, value: 1, to: displayedMonthStart)!)!
    }

    private var monthTransactions: [Transaction] {
        let end = monthOffset == 0 ? Date() : displayedMonthEnd
        return SharedDataService.shared.transactions
            .filter { $0.date >= displayedMonthStart && $0.date <= end }
    }

    private var displayedIncome: Decimal {
        monthTransactions.filter { $0.direction == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var displayedExpenses: Decimal {
        monthTransactions.filter { $0.direction == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "LLLL yyyy"
        let s = fmt.string(from: displayedMonthStart)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    // MARK: - Current-page helpers (no TabView — direction switches via pageSelector buttons only)

    private var currentDirection: TransactionDirection {
        selectedPage == 0 ? .income : .expense
    }
    private var currentTotal: Decimal {
        selectedPage == 0 ? displayedIncome : displayedExpenses
    }
    private var currentEmptyLabel: String {
        selectedPage == 0 ? "Нет доходов" : "Нет расходов"
    }
    private var currentSectionTitle: String {
        selectedPage == 0 ? "Все доходы" : "Все расходы"
    }
    private var currentTransactions: [Transaction] {
        monthTransactions
            .filter { $0.direction == currentDirection }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                hairline
                pageSelector
                hairline
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        chartCard(
                            total: currentTotal,
                            slices: categorySlices(for: currentDirection),
                            emptyLabel: currentEmptyLabel,
                            direction: currentDirection
                        )
                        transactionBlock(
                            title: currentSectionTitle,
                            transactions: currentTransactions,
                            emptyLabel: currentEmptyLabel
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(item: $editingTransaction) { tx in
            AddTransactionView(
                viewModel: dashboardViewModel.makeEditTransactionViewModel(tx)
            )
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FC.muted)
                    .frame(width: 30, height: 30)
                    .background(FC.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(FC.border, lineWidth: 0.5))
            }
            Spacer()
            VStack(spacing: 1) {
                Text("Денежный поток")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text(monthLabel)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(FC.muted)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: monthOffset)
            }
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
            selectorTab(label: "Доходы",  index: 0, color: FC.cobalt,  amount: displayedIncome)
            Rectangle().fill(FC.border).frame(width: 0.5)
            selectorTab(label: "Расходы", index: 1, color: FC.expense, amount: displayedExpenses)
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
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(selected ? color : FC.muted)
                Text(amount.rub())
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(selected ? color : FC.muted.opacity(0.6))
                    .contentTransition(.numericText())
                    .animation(.fineryNumber, value: amount)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .background(selected ? color.opacity(0.09) : Color.clear)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selected)
    }

    // MARK: - Month Navigation

    private func changeMonth(_ delta: Int) {
        let next = monthOffset + delta
        guard next <= 0 else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
            monthOffset = next
        }
    }

    // MARK: - Chart Card

    private func chartCard(
        total: Decimal,
        slices: [CategorySlice],
        emptyLabel: String,
        direction: TransactionDirection
    ) -> some View {
        let periodLabel = direction == .income
            ? "Доход · \(monthLabel)"
            : "Расходы · \(monthLabel)"

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(periodLabel).fLabel()
                Text(total.rub())
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(direction == .income ? FC.cobalt : FC.expense)
                    .contentTransition(.numericText())
                    .animation(.fineryNumber, value: total)
            }

            if slices.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .foregroundStyle(FC.muted.opacity(0.5))
                    Text(emptyLabel)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(FC.muted)
                }
                .padding(.vertical, 12)
            } else {
                HStack(alignment: .top, spacing: 20) {
                    DonutChartView(
                        slices: slices.map {
                            DonutChartView.Slice(
                                name: $0.name,
                                value: $0.percentage,
                                color: fineryCategoryColor($0.name)
                            )
                        },
                        size: 130,
                        innerRatio: 0.58,
                        angularInset: 2.5,
                        cornerRadius: 4
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: monthOffset)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(slices) { slice in
                            legendRow(slice: slice)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: monthOffset)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
        // Swipe on chart card changes month — no TabView above this, so no gesture conflict
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -40 { changeMonth(+1) }
                    else if value.translation.width > 40 { changeMonth(-1) }
                }
        )
    }

    // MARK: - Legend Row

    private func legendRow(slice: CategorySlice) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(fineryCategoryColor(slice.name))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(slice.name)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(FC.ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(slice.amount.rub())
                        .font(.system(.caption2, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(FC.muted)
                    Text("·")
                        .foregroundStyle(FC.border)
                        .font(.system(.caption2))
                    Text(String(format: "%.0f%%", slice.percentage))
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(FC.muted)
                }
            }
        }
    }

    // MARK: - Transaction Block

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
                    Button {
                        HapticManager.light()
                        editingTransaction = tx
                    } label: {
                        categoryColoredRow(tx)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    // MARK: - Category Slices

    private func categorySlices(for direction: TransactionDirection) -> [CategorySlice] {
        var byCategory: [String: Decimal] = [:]
        for tx in monthTransactions where tx.direction == direction {
            let name = direction == .income
                ? (tx.incomeCategory?.displayName ?? "Другое")
                : (tx.expenseCategory?.displayName ?? "Другое")
            byCategory[name, default: 0] += tx.amount
        }

        let total = byCategory.values.reduce(0, +)
        guard total > 0 else { return [] }

        var slices = byCategory
            .map { CategorySlice(name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }

        let maxVisible = 6
        if slices.count > maxVisible {
            let top = Array(slices.prefix(maxVisible - 1))
            let restAmount = slices.dropFirst(maxVisible - 1).reduce(Decimal(0)) { $0 + $1.amount }
            slices = top + [CategorySlice(name: "Остальное", amount: restAmount)]
        }

        let totalDouble = NSDecimalNumber(decimal: total).doubleValue
        return slices.map { slice in
            var s = slice
            s.percentage = totalDouble > 0
                ? NSDecimalNumber(decimal: slice.amount).doubleValue / totalDouble * 100
                : 0
            return s
        }
    }

    // MARK: - Category-colored transaction row

    private func categoryColoredRow(_ tx: Transaction) -> some View {
        let catName = tx.direction == .income
            ? (tx.incomeCategory?.displayName ?? "Другое")
            : (tx.expenseCategory?.displayName ?? "Другое")
        let catColor = fineryCategoryColor(catName)
        let iconSys  = tx.direction == .income
            ? (tx.incomeCategory?.iconName  ?? "arrow.down.left")
            : (tx.expenseCategory?.iconName ?? "arrow.up.right")

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(catColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: iconSys)
                    .fontWeight(.light)
                    .imageScale(.small)
                    .foregroundStyle(catColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.description)
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.ink)
                    .lineLimit(1)
                Text(catName)
                    .font(.system(.caption2, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.inkSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text((tx.direction == .income ? "+" : "−") + tx.amount.rub())
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(catColor)
                Text(cfShortTime(tx.date))
                    .font(.system(.caption2, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.inkSecondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .glassCardSmall()
    }

    private func cfShortTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}
