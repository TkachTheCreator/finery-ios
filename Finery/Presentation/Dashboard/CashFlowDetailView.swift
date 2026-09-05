import SwiftUI
import Charts

// MARK: - Category slice model

private struct CategorySlice: Identifiable {
    let id = UUID()
    let name: String
    let amount: Decimal       // настоящая сумма — для легенды
    var percentage: Double = 0  // настоящий процент — для легенды
    var chartValue: Double      // скорректированное значение — только для SectorMark

    init(name: String, amount: Decimal, percentage: Double = 0) {
        self.name = name
        self.amount = amount
        self.percentage = percentage
        self.chartValue = NSDecimalNumber(decimal: amount).doubleValue
    }
}

// MARK: - Fixed color palette

private let categoryPalette: [String: Color] = [
    // Income
    "Boosty/Подписки":  Color(red: 0.90, green: 0.27, blue: 0.27),
    "Донаты":           Color(red: 0.97, green: 0.55, blue: 0.14),
    "Реклама":          Color(red: 0.97, green: 0.78, blue: 0.09),
    "Фриланс":          Color(red: 0.20, green: 0.65, blue: 0.42),
    "Платформы":        Color(red: 0.06, green: 0.60, blue: 0.75),
    "Курсы/Обучение":   Color(red: 0.38, green: 0.35, blue: 0.82),
    // Expense
    "Инструменты":      Color(red: 0.06, green: 0.60, blue: 0.75),
    "Своя реклама":     Color(red: 0.97, green: 0.55, blue: 0.14),
    "Оборудование":     Color(red: 0.20, green: 0.65, blue: 0.42),
    "Команда":          Color(red: 0.90, green: 0.27, blue: 0.27),
    "Еда":              Color(red: 0.55, green: 0.76, blue: 0.29),
    "Транспорт":        Color(red: 0.97, green: 0.78, blue: 0.09),
    "Связь":            Color(red: 0.38, green: 0.35, blue: 0.82),
    // Shared
    "Другое":           Color(red: 0.60, green: 0.57, blue: 0.54),
    "Остальное":        Color(red: 0.75, green: 0.72, blue: 0.68),
]

private func categoryColor(_ name: String) -> Color {
    if let c = categoryPalette[name] { return c }
    let h = Double(abs(name.hashValue) % 360) / 360.0
    return Color(hue: h, saturation: 0.6, brightness: 0.72)
}

// MARK: - CashFlowDetailView

struct CashFlowDetailView: View {
    let dashboardViewModel: DashboardViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage   = 0
    @State private var monthOffset    = 0   // 0 = current, -1 = prev, …
    @State private var animDirection  = 0   // +1 newer→left-in, -1 older→right-in
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
            selectorTab(label: "Доходы",  index: 0, color: FC.cobalt, amount: displayedIncome)
            Rectangle().fill(FC.border).frame(width: 0.5)
            selectorTab(label: "Расходы", index: 1, color: FC.muted,  amount: displayedExpenses)
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
        let total: Decimal = direction == .income ? displayedIncome : displayedExpenses
        let slices = categorySlices(for: direction)
        let txns = monthTransactions.filter { $0.direction == direction }.sorted { $0.date > $1.date }
        let emptyLabel = direction == .income ? "Нет доходов" : "Нет расходов"
        let sectionTitle = direction == .income ? "Все доходы" : "Все расходы"

        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                chartCard(total: total, slices: slices, emptyLabel: emptyLabel, direction: direction)
                transactionBlock(title: sectionTitle, transactions: txns, emptyLabel: emptyLabel)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Month Navigation

    private func changeMonth(_ delta: Int) {
        let next = monthOffset + delta
        guard next <= 0 else { return }   // не заходим в будущее
        withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
            animDirection = delta > 0 ? 1 : -1
            monthOffset   = next
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
            // Header row: month nav + amount
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(periodLabel)
                        .fLabel()
                    Text(total.rub())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(direction == .income ? FC.cobalt : FC.ink)
                        .contentTransition(.numericText())
                        .animation(.fineryNumber, value: total)
                }
                Spacer()
                // Month navigation chevrons
                HStack(spacing: 12) {
                    Button { changeMonth(-1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(FC.muted)
                            .frame(width: 28, height: 28)
                            .background(FC.surface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(FC.border, lineWidth: 0.5))
                    }
                    Button { changeMonth(+1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(monthOffset < 0 ? FC.muted : FC.border)
                            .frame(width: 28, height: 28)
                            .background(FC.surface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(FC.border, lineWidth: 0.5))
                    }
                    .disabled(monthOffset >= 0)
                }
                .padding(.top, 2)
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
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Сумма", slice.chartValue),
                            innerRadius: .ratio(0.58),
                            angularInset: 2.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(categoryColor(slice.name))
                    }
                    .frame(width: 130, height: 130)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(slices) { slice in
                            legendRow(slice: slice)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 4)
                .id(monthOffset)
                .transition(.asymmetric(
                    insertion: .move(edge: animDirection >= 0 ? .trailing : .leading)
                        .combined(with: .opacity),
                    removal:   .move(edge: animDirection >= 0 ? .leading  : .trailing)
                        .combined(with: .opacity)
                ))
            }
        }
        .padding(16)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
        // Swipe on chart card — highPriority to win over TabView page swipe
        .highPriorityGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -40 { changeMonth(+1) }  // влево = вперёд
                    else if value.translation.width > 40 { changeMonth(-1) }  // вправо = назад
                }
        )
    }

    // MARK: - Legend Row

    private func legendRow(slice: CategorySlice) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(categoryColor(slice.name))
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
                    TransactionRow(transaction: tx)
                        .contentShape(Rectangle())
                        .onTapGesture { editingTransaction = tx }
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
        slices = slices.map { slice in
            var s = slice
            s.percentage = totalDouble > 0
                ? NSDecimalNumber(decimal: slice.amount).doubleValue / totalDouble * 100
                : 0
            return s
        }

        return enforceMinimumAngle(slices)
    }

    /// Гарантирует минимум 5° дуги для каждого сегмента.
    /// Легенда остаётся с реальными числами — корректируется только chartValue.
    private func enforceMinimumAngle(_ slices: [CategorySlice]) -> [CategorySlice] {
        guard slices.count > 1 else { return slices }

        let totalChart = slices.reduce(0.0) { $0 + $1.chartValue }
        guard totalChart > 0 else { return slices }

        // 5° из 360° = минимальная доля
        let minFraction = 5.0 / 360.0
        let minValue    = totalChart * minFraction

        var result   = slices
        var totalBoost = 0.0

        for i in result.indices where result[i].chartValue < minValue {
            totalBoost += minValue - result[i].chartValue
            result[i].chartValue = minValue
        }

        // Снимаем прирост с самого крупного сегмента
        if totalBoost > 0,
           let maxIdx = result.indices.max(by: { result[$0].chartValue < result[$1].chartValue }) {
            result[maxIdx].chartValue = max(minValue, result[maxIdx].chartValue - totalBoost)
        }

        return result
    }
}
