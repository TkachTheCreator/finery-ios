import SwiftUI
import UIKit

// MARK: - Period model

enum ExportPeriod: Equatable {
    case month, quarter, year, custom

    var label: String {
        switch self {
        case .month:   return "Месяц"
        case .quarter: return "Квартал"
        case .year:    return "Год"
        case .custom:  return "Диапазон"
        }
    }

    static var presets: [ExportPeriod] { [.month, .quarter, .year, .custom] }
}

// MARK: - ViewModel

@Observable
@MainActor
final class ExportViewModel {
    var period:       ExportPeriod = .month
    var format:       ExportFormat = .pdf
    var customFrom:   Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    var customTo:     Date = Date()
    var isGenerating  = false
    var exportData:   Data?
    var exportName:   String?
    var showShare     = false

    enum ExportFormat { case pdf, csv }

    func export() async {
        isGenerating = true
        defer { isGenerating = false }

        // Ensure latest data is loaded
        await SharedDataService.shared.loadAll()

        let interval = resolvedInterval
        let allTxns  = SharedDataService.shared.transactions
        let txns     = allTxns
            .filter { $0.date >= interval.start && $0.date <= interval.end }
            .sorted { $0.date > $1.date }

        let income   = txns.filter { $0.direction == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let expenses = txns.filter { $0.direction == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        let taxRate  = SharedDataService.shared.taxMode == .npd
            ? Decimal(string: "0.04")!
            : (SharedDataService.shared.taxMode == .usn6 ? Decimal(string: "0.06")! : Decimal(string: "0.15")!)
        let taxAmount  = roundDecimal(income * taxRate)
        let netProfit  = income - expenses - taxAmount
        let userName   = SharedDataService.shared.userName
        let clients    = SharedDataService.shared.cachedClients
        let pLabel     = periodLabel(interval)
        let stamp      = filenameDate

        switch format {
        case .pdf:
            exportData = FineryPDFGenerator().generateReport(
                userName: userName,
                periodLabel: pLabel,
                income: income,
                expenses: expenses,
                taxAmount: taxAmount,
                netProfit: netProfit,
                transactions: txns,
                clients: clients
            )
            exportName = "finery-report-\(stamp).pdf"

        case .csv:
            let csv = generateCSV(txns: txns, clients: clients, periodLabel: pLabel)
            exportData = csv.data(using: .utf8)
            exportName = "finery-transactions-\(stamp).csv"
        }

        showShare = exportData != nil
    }

    // MARK: Helpers

    var resolvedInterval: DateInterval {
        let now = Date()
        let cal = Calendar.current
        switch period {
        case .month:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            return DateInterval(start: start, end: now)
        case .quarter:
            return DateInterval(start: cal.date(byAdding: .month, value: -3, to: now)!, end: now)
        case .year:
            let start = cal.date(from: DateComponents(year: cal.component(.year, from: now), month: 1, day: 1))!
            return DateInterval(start: start, end: now)
        case .custom:
            let to = min(customTo, now)
            return DateInterval(start: customFrom, end: to)
        }
    }

    private func periodLabel(_ interval: DateInterval) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM yyyy"
        fmt.locale = Locale(identifier: "ru_RU")
        return "\(fmt.string(from: interval.start)) — \(fmt.string(from: interval.end))"
    }

    private var filenameDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    private func roundDecimal(_ d: Decimal) -> Decimal {
        var r = d; var result = Decimal()
        NSDecimalRound(&result, &r, 0, .plain)
        return result
    }

    private func generateCSV(txns: [Transaction], clients: [Client], periodLabel: String) -> String {
        var lines: [String] = []
        lines.append("Finery — Финансовый отчёт")
        lines.append("Период: \(periodLabel)")
        lines.append("")
        lines.append("Дата;Тип;Категория;Описание;Сумма (руб.);Клиент")

        let fmt = DateFormatter()
        fmt.dateFormat = "dd.MM.yyyy"

        for tx in txns {
            let date = fmt.string(from: tx.date)
            let type = tx.direction == .income ? "Доход" : "Расход"
            let cat: String = tx.direction == .income
                ? (tx.incomeCategory?.displayName ?? "Другое")
                : (tx.expenseCategory?.displayName ?? "Другое")
            let desc   = tx.description.replacingOccurrences(of: ";", with: ",")
            let amount = "\(tx.amount)"
            let client = tx.clientId
                .flatMap { cid in clients.first(where: { $0.id == cid })?.name } ?? ""
            lines.append("\(date);\(type);\(cat);\(desc);\(amount);\(client)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - View

struct ExportView: View {
    @State private var vm = ExportViewModel()

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            List {
                periodSection
                formatSection
                infoSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Экспорт")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if vm.isGenerating {
                    ProgressView().tint(FC.cobalt).scaleEffect(0.85)
                } else {
                    Button("Экспортировать") {
                        Task { await vm.export() }
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.cobalt)
                }
            }
        }
        .sheet(isPresented: $vm.showShare) {
            if let data = vm.exportData, let name = vm.exportName {
                ExportShareSheet(data: data, filename: name).ignoresSafeArea()
            }
        }
    }

    // MARK: Period

    private var periodSection: some View {
        Section("Период") {
            ForEach(ExportPeriod.presets, id: \.label) { p in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        vm.period = p
                    }
                } label: {
                    HStack {
                        Text(p.label)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(FC.ink)
                        Spacer()
                        if vm.period == p {
                            Image(systemName: "checkmark")
                                .font(.system(.callout, weight: .semibold))
                                .foregroundStyle(FC.cobalt)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            if vm.period == .custom {
                DatePicker("С", selection: $vm.customFrom, in: ...vm.customTo, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "ru_RU"))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(FC.ink)
                DatePicker("По", selection: $vm.customTo, in: vm.customFrom..., displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "ru_RU"))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(FC.ink)
            }
        }
    }

    // MARK: Format

    private var formatSection: some View {
        Section("Формат") {
            formatRow(label: "PDF", icon: "doc.richtext", selected: vm.format == .pdf) {
                vm.format = .pdf
            }
            formatRow(label: "CSV (Excel / Google Sheets)", icon: "tablecells", selected: vm.format == .csv) {
                vm.format = .csv
            }
        }
    }

    private func formatRow(label: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(selected ? FC.cobalt : FC.inkSecondary)
                    .frame(width: 22)
                Text(label)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(FC.ink)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(.callout, weight: .semibold))
                        .foregroundStyle(FC.cobalt)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Info

    private var infoSection: some View {
        Section {
            infoRow(icon: "person.fill",   text: "Имя пользователя из профиля")
            infoRow(icon: "list.bullet",   text: "Все транзакции за период")
            infoRow(icon: "sum",           text: "Сводка: доходы, расходы, налог, прибыль")
            if vm.format == .pdf {
                infoRow(icon: "person.2",  text: "Привязанные клиенты")
            }
        } header: {
            Text("Содержимое файла")
        } footer: {
            Text("PDF оформлен как официальный финансовый документ. CSV открывается в Excel и Google Sheets без настройки.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(FC.muted)
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(FC.inkSecondary)
                .frame(width: 18)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FC.inkSecondary)
        }
    }
}

// MARK: - Share Sheet

struct ExportShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
