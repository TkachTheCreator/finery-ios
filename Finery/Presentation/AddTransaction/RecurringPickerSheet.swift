import SwiftUI

struct RecurringPickerSheet: View {
    let amount: Decimal
    let direction: TransactionDirection
    let description: String
    let incomeCategory: IncomeCategory
    let expenseCategory: ExpenseCategory
    let onSave: (RecurringTransaction) -> Void
    let onCancel: () -> Void

    @State private var period: RecurringPeriod = .monthly
    @State private var dayOfMonth: Int = 1
    @State private var dayOfWeek: Int = 2 // понедельник

    private let weekdays = [
        (2, "Понедельник"), (3, "Вторник"), (4, "Среда"),
        (5, "Четверг"), (6, "Пятница"), (7, "Суббота"), (1, "Воскресенье")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                FC.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ОПЕРАЦИЯ")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(FC.muted)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        HStack {
                            Text(description.isEmpty ? (direction == .income ? "Доход" : "Расход") : description)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(FC.ink)
                            Spacer()
                            let n = NSDecimalNumber(decimal: amount).intValue
                            Text("\(direction == .income ? "+" : "−")\(n) ₽")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(direction == .income ? FC.success : FC.danger)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(FC.surface)
                    }

                    Rectangle().fill(FC.border).frame(height: 0.5).padding(.top, 8)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("ПЕРИОДИЧНОСТЬ")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(FC.muted)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)

                        Picker("Период", selection: $period) {
                            ForEach(RecurringPeriod.allCases, id: \.self) { p in
                                Text(p.displayName).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)

                        if period == .monthly {
                            HStack {
                                Text("День месяца")
                                    .font(.system(.body))
                                    .foregroundStyle(FC.ink)
                                Spacer()
                                Picker("", selection: $dayOfMonth) {
                                    ForEach(1...28, id: \.self) { d in Text("\(d)").tag(d) }
                                }
                                .labelsHidden()
                                .tint(FC.cobalt)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        } else {
                            HStack {
                                Text("День недели")
                                    .font(.system(.body))
                                    .foregroundStyle(FC.ink)
                                Spacer()
                                Picker("", selection: $dayOfWeek) {
                                    ForEach(weekdays, id: \.0) { d in Text(d.1).tag(d.0) }
                                }
                                .labelsHidden()
                                .tint(FC.cobalt)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                    }
                    .padding(.top, 8)

                    Spacer()

                    Button {
                        var rec = RecurringTransaction(
                            amount: amount,
                            direction: direction,
                            description: description.isEmpty ? (direction == .income ? "Доход" : "Расход") : description,
                            incomeCategory:  direction == .income  ? incomeCategory  : nil,
                            expenseCategory: direction == .expense ? expenseCategory : nil,
                            period: period
                        )
                        rec.dayOfMonth = period == .monthly ? dayOfMonth : nil
                        rec.dayOfWeek  = period == .weekly  ? dayOfWeek  : nil
                        onSave(rec)
                    } label: {
                        Text("Сохранить расписание")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FC.cobalt)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Повторяющийся платёж")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", action: onCancel)
                }
            }
        }
    }
}
