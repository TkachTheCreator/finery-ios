import WidgetKit
import SwiftUI

// MARK: - Модель данных виджета

struct FineryEntry: TimelineEntry {
    let date: Date
    let income: Double
    let expense: Double
    let netProfit: Double
    let taxAmount: Double
    let taxMode: String
    let lastTransactions: [WidgetTransaction]
}

struct WidgetTransaction: Codable {
    let amount: Double
    let direction: String
    let description: String
    let date: Date
}

// MARK: - Provider

struct FineryProvider: TimelineProvider {
    func placeholder(in context: Context) -> FineryEntry {
        FineryEntry(
            date: Date(), income: 150000,
            expense: 30000, netProfit: 114000,
            taxAmount: 6000, taxMode: "НПД",
            lastTransactions: []
        )
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (FineryEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<FineryEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> FineryEntry {
        let defaults = UserDefaults(suiteName: "group.com.tkachev.finery")
        let income  = defaults?.double(forKey: "widget_income")  ?? 0
        let expense = defaults?.double(forKey: "widget_expense") ?? 0
        let tax     = defaults?.double(forKey: "widget_tax")     ?? 0
        let taxMode = defaults?.string(forKey: "widget_taxMode") ?? "НПД"

        var transactions: [WidgetTransaction] = []
        if let data = defaults?.data(forKey: "widget_transactions"),
           let txs = try? JSONDecoder().decode([WidgetTransaction].self, from: data) {
            transactions = Array(txs.prefix(3))
        }

        return FineryEntry(
            date: Date(),
            income: income,
            expense: expense,
            netProfit: income - expense - tax,
            taxAmount: tax,
            taxMode: taxMode,
            lastTransactions: transactions
        )
    }
}

// MARK: - Маленький виджет (systemSmall)

struct SmallWidgetView: View {
    let entry: FineryEntry

    var body: some View {
        ZStack {
            Color(hex: "#F5EFE0")
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Finery")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#8B7D5A"))
                    Spacer()
                    Text(entry.taxMode)
                        .font(.caption2)
                        .foregroundColor(Color(hex: "#0047AB"))
                }
                Spacer()
                Text("Доход")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "#8B7D5A"))
                Text(formatAmount(entry.income))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#1A1A18"))
                    .minimumScaleFactor(0.7)
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text("Расход")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "#8B7D5A"))
                        Text(formatAmount(entry.expense))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Налог")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "#8B7D5A"))
                        Text(formatAmount(entry.taxAmount))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "#0047AB"))
                    }
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Средний виджет (systemMedium)

struct MediumWidgetView: View {
    let entry: FineryEntry

    var body: some View {
        ZStack {
            Color(hex: "#F5EFE0")
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Finery")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#8B7D5A"))
                    Text("Чистая прибыль")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "#8B7D5A"))
                    Text(formatAmount(entry.netProfit))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#1A1A18"))
                        .minimumScaleFactor(0.6)
                    Spacer()
                    Link(destination: URL(string: "finery://add-transaction")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Добавить")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#0047AB"))
                        .cornerRadius(8)
                    }
                }

                Divider()
                    .background(Color(hex: "#8B7D5A").opacity(0.3))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Последние")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "#8B7D5A"))
                    if entry.lastTransactions.isEmpty {
                        Text("Нет транзакций")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#8B7D5A"))
                    } else {
                        ForEach(Array(entry.lastTransactions.prefix(3).enumerated()), id: \.offset) { _, tx in
                            HStack {
                                Text(tx.description)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .foregroundColor(Color(hex: "#1A1A18"))
                                Spacer()
                                Text(tx.direction == "income"
                                     ? "+\(formatAmount(tx.amount))"
                                     : "-\(formatAmount(tx.amount))")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(tx.direction == "income" ? .green : .red)
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Виджет быстрой записи

struct QuickRecordWidgetView: View {
    var body: some View {
        ZStack {
            Color(hex: "#F5EFE0")
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#0047AB").opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "#0047AB"))
                }
                Text("Запись")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#1A1A18"))
                Text("Finery")
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "#8B7D5A"))
            }
        }
        .widgetURL(URL(string: "finery://voice")!)
    }
}

struct FineryQuickRecordWidget: Widget {
    let kind = "FineryQuickRecord"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FineryProvider()) { _ in
            QuickRecordWidgetView()
                .containerBackground(Color(hex: "#F5EFE0"), for: .widget)
        }
        .configurationDisplayName("Finery — Быстрая запись")
        .description("Открывает голосовой ввод транзакции одним тапом")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Widget bundle (entry point)

@main
struct FineryWidgetBundle: WidgetBundle {
    var body: some Widget {
        FineryWidgetSmall()
        FineryWidgetMedium()
        FineryQuickRecordWidget()
    }
}

struct FineryWidgetSmall: Widget {
    let kind = "FineryWidgetSmall"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FineryProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(Color(hex: "#F5EFE0"), for: .widget)
        }
        .configurationDisplayName("Finery — Баланс")
        .description("Доходы, расходы и налог за месяц")
        .supportedFamilies([.systemSmall])
    }
}

struct FineryWidgetMedium: Widget {
    let kind = "FineryWidgetMedium"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FineryProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(Color(hex: "#F5EFE0"), for: .widget)
        }
        .configurationDisplayName("Finery — Сводка")
        .description("Баланс и последние транзакции")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Helpers

private func formatAmount(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = " "
    formatter.maximumFractionDigits = 0
    return "\(formatter.string(from: NSNumber(value: amount)) ?? "0") ₽"
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
