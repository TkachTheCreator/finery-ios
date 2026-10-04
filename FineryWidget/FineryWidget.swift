import WidgetKit
import SwiftUI

// MARK: - Data model

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
        FineryEntry(date: Date(), income: 150000, expense: 30000,
                    netProfit: 114000, taxAmount: 6000, taxMode: "НПД", lastTransactions: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (FineryEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FineryEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> FineryEntry {
        let d = UserDefaults(suiteName: "group.com.tkachev.finery")
        let income  = d?.double(forKey: "widget_income")  ?? 0
        let expense = d?.double(forKey: "widget_expense") ?? 0
        let tax     = d?.double(forKey: "widget_tax")     ?? 0
        let taxMode = d?.string(forKey: "widget_taxMode") ?? "НПД"
        var txs: [WidgetTransaction] = []
        if let data = d?.data(forKey: "widget_transactions"),
           let decoded = try? JSONDecoder().decode([WidgetTransaction].self, from: data) {
            txs = Array(decoded.prefix(3))
        }
        return FineryEntry(date: Date(), income: income, expense: expense,
                           netProfit: income - expense - tax,
                           taxAmount: tax, taxMode: taxMode, lastTransactions: txs)
    }
}

// MARK: - Palette helpers

private let sand    = Color(hex: "#F5EFE0")
private let cobalt  = Color(hex: "#0047AB")
private let ink     = Color(hex: "#1A1A18")
private let muted   = Color(hex: "#6B6560")
private let divider = Color(hex: "#C8C0B0")
private let success = Color(hex: "#1A7A4A")
private let danger  = Color(hex: "#C0392B")

// MARK: - ═══════════════════════════
// MARK:   HOME SCREEN — systemSmall
// MARK:   "Быстрое добавление"
// MARK: - ═══════════════════════════

struct QuickAddSmallView: View {
    var body: some View {
        ZStack {
            sand
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(cobalt)
                        .frame(width: 52, height: 52)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("Добавить\nоперацию")
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ink)
                    .lineSpacing(1)
            }
        }
        .widgetURL(URL(string: "finery://add-transaction")!)
        .accessibilityLabel("Finery: добавить операцию")
    }
}

struct FineryQuickAddWidget: Widget {
    let kind = "FineryQuickAdd"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FineryProvider()) { _ in
            QuickAddSmallView()
                .containerBackground(sand, for: .widget)
        }
        .configurationDisplayName("Finery — Добавить")
        .description("Открывает быстрое добавление операции одним тапом")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - ═══════════════════════════
// MARK:   HOME SCREEN — systemSmall
// MARK:   "Баланс"
// MARK: - ═══════════════════════════

struct BalanceSmallView: View {
    let entry: FineryEntry

    var body: some View {
        ZStack {
            sand
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Finery")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(muted)
                    Spacer()
                    Text(entry.taxMode)
                        .font(.caption2)
                        .foregroundStyle(cobalt)
                }

                Spacer()

                Text("Доход")
                    .font(.caption2)
                    .foregroundStyle(muted)
                Text(fmtAmt(entry.income))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(cobalt)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                Spacer()

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Расход")
                            .font(.caption2)
                            .foregroundStyle(muted)
                        Text(fmtAmt(entry.expense))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ink)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Налог")
                            .font(.caption2)
                            .foregroundStyle(muted)
                        Text(fmtAmt(entry.taxAmount))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ink)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
        }
        .accessibilityLabel("Finery. Доход: \(fmtAmt(entry.income)), расход: \(fmtAmt(entry.expense)), налог: \(fmtAmt(entry.taxAmount))")
    }
}

struct FineryBalanceWidget: Widget {
    let kind = "FineryWidgetSmall"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FineryProvider()) { entry in
            BalanceSmallView(entry: entry)
                .containerBackground(sand, for: .widget)
        }
        .configurationDisplayName("Finery — Баланс")
        .description("Доходы, расходы и налог за текущий месяц")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - ═══════════════════════════
// MARK:   HOME SCREEN — systemMedium
// MARK:   "Сводка + Добавить"
// MARK: - ═══════════════════════════

struct ComboMediumView: View {
    let entry: FineryEntry

    var body: some View {
        ZStack {
            sand
            HStack(spacing: 0) {

                // ── Left: balance ──
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Finery")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(muted)
                        Spacer()
                        Text(entry.taxMode)
                            .font(.caption2)
                            .foregroundStyle(cobalt)
                    }

                    Spacer()

                    Text("Доход за месяц")
                        .font(.caption2)
                        .foregroundStyle(muted)
                    Text(fmtAmt(entry.income))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(cobalt)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Расход")
                                .font(.caption2).foregroundStyle(muted)
                            Text(fmtAmt(entry.expense))
                                .font(.caption.weight(.semibold)).foregroundStyle(ink)
                                .minimumScaleFactor(0.8).lineLimit(1)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Прибыль")
                                .font(.caption2).foregroundStyle(muted)
                            Text(fmtAmt(entry.netProfit))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(entry.netProfit >= 0 ? success : danger)
                                .minimumScaleFactor(0.8).lineLimit(1)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                // ── Divider ──
                Rectangle()
                    .fill(divider.opacity(0.6))
                    .frame(width: 0.5)

                // ── Right: add button ──
                Link(destination: URL(string: "finery://add-transaction")!) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(cobalt)
                                .frame(width: 46, height: 46)
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Text("Добавить")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(ink)
                    }
                }
                .frame(width: 90)
            }
        }
    }
}

struct FineryComboWidget: Widget {
    let kind = "FineryWidgetMedium"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FineryProvider()) { entry in
            ComboMediumView(entry: entry)
                .containerBackground(sand, for: .widget)
        }
        .configurationDisplayName("Finery — Сводка")
        .description("Баланс за месяц и кнопка быстрого добавления")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - ═══════════════════════════
// MARK:   LOCK SCREEN — accessoryRectangular "Добавить"
// MARK: - ═══════════════════════════

struct LockRectView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 38, weight: .medium))
                .frame(width: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Добавить операцию")
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Finery")
                    .font(.caption2)
                    .opacity(0.55)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(URL(string: "finery://add-transaction")!)
        .accessibilityLabel("Finery: добавить операцию")
    }
}

// MARK: - ═══════════════════════════
// MARK:   LOCK SCREEN — accessoryRectangular "Баланс"
// MARK: - ═══════════════════════════

struct LockRectBalanceView: View {
    let entry: FineryEntry

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ДОХОД")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.55)
                Text(fmtAmt(entry.income))
                    .font(.title3.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .frame(width: 0.5)
                .padding(.vertical, 6)
                .opacity(0.35)

            VStack(alignment: .trailing, spacing: 2) {
                Text("РАСХОД")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.55)
                Text(fmtAmt(entry.expense))
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ═══════════════════════════
// MARK:   LOCK SCREEN — accessoryCircular
// MARK: - ═══════════════════════════

struct LockCircularView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 26, weight: .medium))
                .accessibilityHidden(true)
        }
        .widgetURL(URL(string: "finery://add-transaction")!)
        .accessibilityLabel("Finery: добавить операцию")
    }
}

// MARK: - ═══════════════════════════
// MARK:   LOCK SCREEN WIDGET — "Добавить" (circular + rectangular)
// MARK: - ═══════════════════════════

private struct LockAddAdaptiveView: View {
    @Environment(\.widgetFamily) var family
    var body: some View {
        if family == .accessoryCircular {
            LockCircularView()
        } else {
            LockRectView()
        }
    }
}

struct FineryLockScreenWidget: Widget {
    let kind = "FineryLockScreen"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FineryProvider()) { _ in
            LockAddAdaptiveView()
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Finery — Добавить")
        .description("Открыть запись операции прямо с экрана блокировки")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - ═══════════════════════════
// MARK:   LOCK SCREEN WIDGET — "Баланс" (rectangular only)
// MARK: - ═══════════════════════════

struct FineryLockBalanceWidget: Widget {
    let kind = "FineryLockBalance"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FineryProvider()) { entry in
            LockRectBalanceView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Finery — Баланс (блокировка)")
        .description("Доходы и расходы за месяц на экране блокировки")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - ═══════════════════════════
// MARK:   WIDGET BUNDLE
// MARK: - ═══════════════════════════

@main
struct FineryWidgetBundle: WidgetBundle {
    var body: some Widget {
        FineryQuickAddWidget()    // Home: "Добавить" small
        FineryBalanceWidget()     // Home: "Баланс" small
        FineryComboWidget()       // Home: "Сводка" medium
        FineryLockScreenWidget()  // Lock Screen: + circular + rectangular
        FineryLockBalanceWidget() // Lock Screen: баланс rectangular
    }
}

// MARK: - Helpers

private func fmtAmt(_ amount: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = "\u{202F}"
    f.maximumFractionDigits = 0
    return "\(f.string(from: NSNumber(value: amount)) ?? "0") ₽"
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
