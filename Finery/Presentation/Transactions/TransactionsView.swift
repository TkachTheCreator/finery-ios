import SwiftUI

struct TransactionsView: View {
    @State var viewModel: TransactionsViewModel
    @State private var showAdd = false

    init(viewModel: TransactionsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FC.background.ignoresSafeArea()

            VStack(spacing: 0) {
                filterBar
                hairline
                summaryRow
                hairline

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(FC.cobalt)
                    Spacer()
                } else if viewModel.grouped.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }

            addButton
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.period) { _, _ in Task { await viewModel.load() } }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(
                viewModel: viewModel.makeAddTransactionViewModel(),
                onSave: { Task { await viewModel.load() } }
            )
        }
    }

    // MARK: Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TimePeriod.allCases, id: \.self) { p in
                    periodChip(p)
                }
                Rectangle()
                    .fill(FC.border)
                    .frame(width: 0.5, height: 20)
                directionChip(nil, label: "Все")
                directionChip(.income, label: "Доходы")
                directionChip(.expense, label: "Расходы")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(FC.background)
    }

    private func periodChip(_ p: TimePeriod) -> some View {
        let selected = viewModel.period == p
        return Button(p.rawValue) { viewModel.period = p }
            .font(.system(.caption, design: .default, weight: selected ? .semibold : .regular))
            .foregroundStyle(selected ? .white : FC.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selected ? FC.cobalt : FC.surface)
            .overlay(Rectangle().stroke(FC.border, lineWidth: 0.5))
    }

    private func directionChip(_ dir: TransactionDirection?, label: String) -> some View {
        let selected = viewModel.directionFilter == dir
        let activeColor: Color = dir == .income ? FC.success : dir == .expense ? FC.danger : FC.cobalt
        return Button(label) { viewModel.directionFilter = dir }
            .font(.system(.caption, design: .default, weight: selected ? .semibold : .regular))
            .foregroundStyle(selected ? .white : FC.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selected ? activeColor : FC.surface)
            .overlay(Rectangle().stroke(FC.border, lineWidth: 0.5))
    }

    // MARK: Summary Row

    private var summaryRow: some View {
        HStack {
            summaryItem(label: "ДОХОДЫ", amount: viewModel.totalIncome, color: FC.success)
            Spacer()
            Rectangle().fill(FC.border).frame(width: 0.5, height: 28)
            Spacer()
            summaryItem(label: "РАСХОДЫ", amount: viewModel.totalExpenses, color: FC.danger)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(FC.surface)
    }

    private func summaryItem(label: String, amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).fLabel()
            Text(amount.rub())
                .font(.system(.footnote, design: .default, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    // MARK: Transaction List

    private var transactionList: some View {
        List {
            ForEach(viewModel.grouped, id: \.date) { group in
                Section {
                    ForEach(group.items) { tx in
                        TransactionRow(transaction: tx)
                            .listRowBackground(FC.background)
                            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                            .listRowSeparatorTint(FC.border)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(id: tx.id) }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(dayLabel(group.date))
                        .fLabel()
                        .padding(.top, 14)
                        .padding(.bottom, 6)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
            }
        }
        .listStyle(.plain)
        .background(FC.background)
        .scrollContentBackground(.hidden)
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(FC.border)
            Text("Нет транзакций")
                .font(.system(.headline, design: .default, weight: .regular))
                .foregroundStyle(FC.muted)
            Text("Нажми + чтобы добавить первую")
                .font(.system(.caption))
                .foregroundStyle(FC.border)
            Spacer()
        }
    }

    // MARK: FAB

    private var addButton: some View {
        Button { showAdd = true } label: {
            Image(systemName: "plus")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(FC.cobalt)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 36)
    }

    // MARK: Helpers

    private var hairline: some View {
        Rectangle().fill(FC.border).frame(height: 0.5)
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Сегодня" }
        if cal.isDateInYesterday(date) { return "Вчера" }
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMMM"
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt.string(from: date)
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Rectangle()
                    .fill(transaction.direction == .income ? FC.success.opacity(0.12) : FC.danger.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .fontWeight(.light)
                    .imageScale(.small)
                    .foregroundStyle(transaction.direction == .income ? FC.success : FC.danger)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.system(.subheadline, design: .default, weight: .regular))
                    .foregroundStyle(FC.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(transaction.source.displayName)
                        .font(.system(.caption2, design: .default, weight: .regular))
                        .foregroundStyle(FC.muted)
                    if let cat = categoryLabel {
                        Text("·").foregroundStyle(FC.border)
                        Text(cat)
                            .font(.system(.caption2, design: .default, weight: .regular))
                            .foregroundStyle(FC.muted)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text((transaction.direction == .income ? "+" : "−") + transaction.amount.rub())
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(transaction.direction == .income ? FC.success : FC.danger)
                Text(shortTime(transaction.date))
                    .font(.system(.caption2, design: .default, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
        }
        .padding(.vertical, 10)
    }

    private var iconName: String {
        if transaction.direction == .income {
            return transaction.incomeCategory?.iconName ?? "arrow.down.left"
        } else {
            return transaction.expenseCategory?.iconName ?? "arrow.up.right"
        }
    }

    private var categoryLabel: String? {
        if transaction.direction == .income {
            return transaction.incomeCategory?.displayName
        } else {
            return transaction.expenseCategory?.displayName
        }
    }

    private func shortTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}

#Preview {
    TransactionsView(viewModel: .preview())
}
