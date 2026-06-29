import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class InvoicesViewModel {

    var invoices: [Invoice] = []
    var clients: [Client]   = []
    var isLoading  = false
    var errorMessage: String?
    var exportedPDFData: Data?
    var showPDFShare = false

    // Create form state
    var showCreateInvoice = false
    var newNumber        = ""
    var newDate          = Date()
    var selectedClientId: UUID? = nil
    var newClientName    = ""
    var newExecutorName  = ""
    var newItems:  [InvoiceItem] = [InvoiceItem(name: "", amount: 0)]
    var includeVat = false
    var isSaving   = false

    var nextInvoiceNumber: String {
        let n = (invoices.count) + 1
        let year = Calendar.current.component(.year, from: Date())
        return String(format: "%d-%03d", year, n)
    }

    var computedTotal: Decimal {
        newItems.reduce(0) { $0 + $1.amount }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let inv = (try? APIClient.shared.getInvoices()) ?? []
        async let cl  = (try? APIClient.shared.getClients()) ?? []
        (invoices, clients) = await (inv, cl)
    }

    func createInvoice() async {
        isSaving = true
        defer { isSaving = false }
        let selectedClient = clients.first(where: { $0.id == selectedClientId })
        let invoice = Invoice(
            number: newNumber.isEmpty ? nextInvoiceNumber : newNumber,
            date: newDate,
            clientId: selectedClientId,
            clientName: selectedClient?.name ?? newClientName,
            items: newItems.filter { !$0.name.isEmpty },
            includeVat: includeVat,
            executorName: newExecutorName
        )
        let saved = (try? await APIClient.shared.createInvoice(invoice)) ?? invoice
        invoices.insert(saved, at: 0)
        showCreateInvoice = false
        resetForm()
    }

    func generatePDF(for invoice: Invoice) {
        exportedPDFData = InvoicePDFGenerator().generate(invoice: invoice)
        showPDFShare = exportedPDFData != nil
    }

    func delete(_ invoice: Invoice) async {
        invoices.removeAll { $0.id == invoice.id }
        try? await APIClient.shared.deleteRequest("api/v1/invoices/\(invoice.id.uuidString)")
    }

    private func resetForm() {
        newNumber = ""; newDate = Date(); selectedClientId = nil
        newClientName = ""; newExecutorName = ""
        newItems = [InvoiceItem(name: "", amount: 0)]; includeVat = false
    }
}

// MARK: - Invoice PDF

struct InvoicePDFGenerator {
    func generate(invoice: Invoice) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        return UIGraphicsPDFRenderer(bounds: pageRect).pdfData { ctx in
            ctx.beginPage()
            draw(in: pageRect, invoice: invoice, ctx: ctx.cgContext)
        }
    }

    private func draw(in rect: CGRect, invoice: Invoice, ctx: CGContext) {
        let margin: CGFloat = 48
        var y: CGFloat = margin

        // Background
        ctx.setFillColor(UIColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1).cgColor)
        ctx.fill(rect)
        ctx.setFillColor(UIColor(red: 0, green: 0.28, blue: 0.67, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: rect.width, height: 6))

        // Header
        t("FINERY", at: CGPoint(x: margin, y: y + 8), size: 24, weight: .bold, color: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1))
        let numStr = "СЧЁТ №\(invoice.number)"
        let dateStr = "от " + DateFormatter.localizedString(from: invoice.date, dateStyle: .long, timeStyle: .none)
        t(numStr,  at: CGPoint(x: margin, y: y + 40), size: 16, weight: .semibold, color: .darkGray)
        t(dateStr, at: CGPoint(x: margin, y: y + 60), size: 12, weight: .regular,  color: .gray)
        y += 92

        // Executor
        t("Исполнитель:", at: CGPoint(x: margin, y: y), size: 9, weight: .semibold, color: .gray)
        t(invoice.executorName.isEmpty ? "—" : invoice.executorName, at: CGPoint(x: margin, y: y + 14), size: 12, weight: .medium, color: .darkGray)
        y += 40

        // Client
        if !invoice.clientName.isEmpty {
            t("Клиент:", at: CGPoint(x: margin, y: y), size: 9, weight: .semibold, color: .gray)
            t(invoice.clientName, at: CGPoint(x: margin, y: y + 14), size: 12, weight: .medium, color: .darkGray)
            y += 40
        }

        // Divider
        ctx.setFillColor(UIColor.darkGray.withAlphaComponent(0.2).cgColor)
        ctx.fill(CGRect(x: margin, y: y, width: rect.width - margin * 2, height: 1))
        y += 14

        // Items header
        t("УСЛУГА", at: CGPoint(x: margin, y: y), size: 8, weight: .semibold, color: .gray)
        t("СУММА", at: CGPoint(x: rect.width - margin - 80, y: y), size: 8, weight: .semibold, color: .gray, align: .right, width: 80)
        y += 20

        for item in invoice.items where !item.name.isEmpty {
            t(item.name, at: CGPoint(x: margin, y: y), size: 12, weight: .regular, color: .darkGray)
            t(item.amount.rub(), at: CGPoint(x: rect.width - margin - 100, y: y), size: 12, weight: .medium, color: .darkGray, align: .right, width: 100)
            y += 24
        }

        // Divider
        ctx.setFillColor(UIColor.darkGray.withAlphaComponent(0.2).cgColor)
        ctx.fill(CGRect(x: margin, y: y, width: rect.width - margin * 2, height: 1))
        y += 14

        // Total
        let total = invoice.computedTotal
        let vatNote = invoice.includeVat ? " (с НДС 20%)" : " (без НДС)"
        t("ИТОГО\(vatNote)", at: CGPoint(x: margin, y: y), size: 10, weight: .semibold, color: .gray)
        t(total.rub(), at: CGPoint(x: rect.width - margin - 140, y: y - 4), size: 20, weight: .bold, color: UIColor(red: 0, green: 0.28, blue: 0.67, alpha: 1), align: .right, width: 140)
        y += 40

        // Footer
        let footerY = rect.height - 36
        t("Сформировано в Finery", at: CGPoint(x: margin, y: footerY), size: 9, weight: .regular, color: .lightGray)
    }

    @discardableResult
    private func t(_ text: String, at p: CGPoint, size: CGFloat, weight: UIFont.Weight,
                   color: UIColor, align: NSTextAlignment = .left, width: CGFloat = 400) -> CGFloat {
        let style = NSMutableParagraphStyle(); style.alignment = align
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color, .paragraphStyle: style
        ]
        text.draw(in: CGRect(x: p.x, y: p.y, width: width, height: 200), withAttributes: attrs)
        return p.y + size + 4
    }
}

private extension Decimal {
    func rub() -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal; fmt.locale = Locale(identifier: "ru_RU")
        fmt.maximumFractionDigits = 0
        return (fmt.string(from: self as NSDecimalNumber) ?? "\(self)") + "\u{202F}₽"
    }
}
