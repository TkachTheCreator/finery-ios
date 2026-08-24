import SwiftUI
import Shimmer
import Pow

struct TransactionsView: View {
    @State var viewModel: TransactionsViewModel
    @State private var showAdd = false
    @State private var appeared = false
    @State private var editingTransaction: Transaction? = nil

    init(viewModel: TransactionsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FC.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                filterBar
                    .offset(y: appeared ? 0 : -20)
                    .opacity(appeared ? 1 : 0)

                summaryCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appeared)

                if viewModel.isLoading {
                    shimmerRows
                        .transition(.opacity)
                } else if viewModel.grouped.isEmpty {
                    emptyState
                } else {
                    transactionList
                        .transition(AnyTransition.movingParts.swoosh)
                }
            }

            addButton
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.isLoading)
        .task { await viewModel.load() }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) { appeared = true }
        }
        .onChange(of: viewModel.period) { _, _ in Task { await viewModel.load() } }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(
                viewModel: viewModel.makeAddTransactionViewModel(),
                onSave: { Task { await viewModel.load() } }
            )
        }
        .sheet(item: $editingTransaction) { tx in
            AddTransactionView(
                viewModel: viewModel.makeEditTransactionViewModel(tx),
                onSave: { Task { await viewModel.load() } }
            )
        }
    }

    // MARK: Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimePeriod.allCases, id: \.self) { p in
                    periodChip(p)
                }
                Rectangle()
                    .fill(FC.border)
                    .frame(width: 1, height: 20)
                directionChip(nil,      label: "Все")
                directionChip(.income,  label: "Доходы")
                directionChip(.expense, label: "Расходы")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func periodChip(_ p: TimePeriod) -> some View {
        let selected = viewModel.period == p
        return Button(p.rawValue) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { viewModel.period = p }
        }
        .font(.system(.caption, design: .default, weight: selected ? .semibold : .regular))
        .foregroundStyle(selected ? .white : FC.muted)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(selected ? FC.cobalt : FC.surface)
                .shadow(color: selected ? FC.cobaltGlow : .clear, radius: 8)
        )
        .overlay(
            Capsule().stroke(
                selected ? Color.clear : FC.border,
                lineWidth: 1
            )
        )
    }

    private func directionChip(_ dir: TransactionDirection?, label: String) -> some View {
        let selected = viewModel.directionFilter == dir
        let activeColor: Color = dir == .income ? FC.cobalt : dir == .expense ? FC.muted : FC.cobalt
        return Button(label) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { viewModel.directionFilter = dir }
        }
        .font(.system(.caption, design: .default, weight: selected ? .semibold : .regular))
        .foregroundStyle(selected ? .white : FC.muted)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(selected ? activeColor : FC.surface)
                .shadow(color: selected ? activeColor.opacity(0.4) : .clear, radius: 8)
        )
        .overlay(
            Capsule().stroke(
                selected ? Color.clear : FC.border,
                lineWidth: 1
            )
        )
    }

    // MARK: Summary Card

    private var summaryCard: some View {
        HStack {
            summaryItem(label: "ДОХОДЫ",  amount: viewModel.totalIncome,   color: FC.cobalt)
            Spacer()
            Rectangle().fill(FC.border).frame(width: 1, height: 32)
            Spacer()
            summaryItem(label: "РАСХОДЫ", amount: viewModel.totalExpenses, color: FC.muted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .glassCardSmall()
    }

    private func summaryItem(label: String, amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).fLabel()
            Text(amount.rub())
                .font(.system(.footnote, design: .default, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
    }

    // MARK: Transaction List

    private var transactionList: some View {
        List {
            ForEach(viewModel.grouped, id: \.date) { group in

                Section {
                    ForEach(group.items) { tx in
                        TransactionRow(transaction: tx)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture { editingTransaction = tx }
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
                        .padding(.bottom, 4)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .refreshable { await viewModel.load() }
    }

    // MARK: Shimmer Skeleton

    private var shimmerRows: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(FC.border)
                            .frame(width: 38, height: 38)
                            .shimmering(active: true)
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(FC.border)
                                .frame(width: 130, height: 12)
                                .shimmering(active: true)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(FC.surface)
                                .frame(width: 80, height: 10)
                                .shimmering(active: true)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(FC.border)
                                .frame(width: 65, height: 12)
                                .shimmering(active: true)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(FC.surface)
                                .frame(width: 36, height: 10)
                                .shimmering(active: true)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .glassCardSmall()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(FC.muted)
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
        Button {
            HapticManager.impact()
            showAdd = true
        } label: {
            Image(systemName: "plus")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(FC.cobalt)
                        .shadow(color: FC.cobaltGlow, radius: 14, x: 0, y: 6)
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 124)
    }

    // MARK: Helpers

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
    @State private var pressed = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.direction == .income
                          ? FC.cobalt.opacity(0.12)
                          : FC.muted.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: iconName)
                    .fontWeight(.light)
                    .imageScale(.small)
                    .foregroundStyle(transaction.direction == .income ? FC.cobalt : FC.ink)
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
                    .foregroundStyle(transaction.direction == .income ? FC.cobalt : FC.ink)
                Text(shortTime(transaction.date))
                    .font(.system(.caption2, design: .default, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .glassCardSmall()
        .scaleEffect(pressed ? 0.97 : 1)
        .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = isPressing }
        }, perform: {})
    }

    private var iconName: String {
        if transaction.direction == .income {
            return transaction.incomeCategory?.iconName ?? "arrow.down.left"
        } else {
            return transaction.expenseCategory?.iconName ?? "arrow.up.right"
        }
    }

    private var categoryLabel: String? {
        if transaction.direction == .income { return transaction.incomeCategory?.displayName }
        else { return transaction.expenseCategory?.displayName }
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
