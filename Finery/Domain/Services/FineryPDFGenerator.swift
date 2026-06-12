import Foundation
import UIKit
import PDFKit

struct FineryPDFGenerator {

    struct ReportData {
        let periodLabel: String
        let income: Decimal
        let expenses: Decimal
        let taxAmount: Decimal
        let netProfit: Decimal
        let incomeBreakdown: [(name: String, amount: Decimal, percent: Double)]
        let monthlyData: [(label: String, income: Decimal, expenses: Decimal)]
    }

    func generate(data: ReportData) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            drawPage(in: pageRect, data: data, context: ctx.cgContext)
        }
    }

    // MARK: - Drawing

    private func drawPage(in rect: CGRect, data: ReportData, context: CGContext) {
        let margin: CGFloat = 48
        var y: CGFloat = margin

        // Background
        context.setFillColor(UIColor(red: 0.04, green: 0.055, blue: 0.102, alpha: 1).cgColor)
        context.fill(rect)

        // Header bar
        context.setFillColor(UIColor(red: 0.29, green: 0.619, blue: 1.0, alpha: 1).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: rect.width, height: 6))

        // Logo / title
        y += 8
        draw("FINERY", at: CGPoint(x: margin, y: y),
             font: .systemFont(ofSize: 26, weight: .bold),
             color: .white)
        draw("Финансовый отчёт", at: CGPoint(x: margin, y: y + 30),
             font: .systemFont(ofSize: 13, weight: .regular),
             color: UIColor(white: 1, alpha: 0.55))
        draw(data.periodLabel, at: CGPoint(x: rect.width - margin - 150, y: y + 6),
             font: .systemFont(ofSize: 12, weight: .semibold),
             color: UIColor(white: 1, alpha: 0.7),
             alignment: .right, width: 150)

        y += 72

        // Divider
        drawDivider(at: y, in: rect, context: context)
        y += 20

        // P&L summary
        draw("P & L  /  ПРИБЫЛЬ И УБЫТКИ", at: CGPoint(x: margin, y: y),
             font: .monospacedSystemFont(ofSize: 9, weight: .semibold),
             color: UIColor(white: 1, alpha: 0.4),
             tracking: 2)
        y += 20

        let col1 = margin
        let col2 = rect.width / 2 + 20

        y = drawKV("Доход", value: data.income.rub(), x: col1, y: y,
                   valueColor: UIColor(red: 0.204, green: 0.827, blue: 0.6, alpha: 1))
        y = drawKV("Расходы", value: data.expenses.rub(), x: col2, y: y - 24,
                   valueColor: UIColor(red: 1, green: 0.357, blue: 0.357, alpha: 1))
        y += 4
        y = drawKV("Налог (НПД)", value: data.taxAmount.rub(), x: col1, y: y,
                   valueColor: UIColor(red: 0.984, green: 0.75, blue: 0.141, alpha: 1))
        y = drawKV("Чистая прибыль", value: data.netProfit.rub(), x: col2, y: y - 24,
                   valueColor: .white, fontSize: 15)
        y += 16

        drawDivider(at: y, in: rect, context: context)
        y += 20

        // Income breakdown
        if !data.incomeBreakdown.isEmpty {
            draw("СТРУКТУРА ДОХОДОВ", at: CGPoint(x: margin, y: y),
                 font: .monospacedSystemFont(ofSize: 9, weight: .semibold),
                 color: UIColor(white: 1, alpha: 0.4),
                 tracking: 2)
            y += 20

            for row in data.incomeBreakdown {
                y = drawBreakdownRow(name: row.name, amount: row.amount, percent: row.percent,
                                     x: margin, y: y, width: rect.width - margin * 2,
                                     context: context)
                y += 4
            }
            y += 8
            drawDivider(at: y, in: rect, context: context)
            y += 20
        }

        // Monthly dynamics
        if !data.monthlyData.isEmpty {
            draw("ДИНАМИКА ПО МЕСЯЦАМ", at: CGPoint(x: margin, y: y),
                 font: .monospacedSystemFont(ofSize: 9, weight: .semibold),
                 color: UIColor(white: 1, alpha: 0.4),
                 tracking: 2)
            y += 20

            for row in data.monthlyData {
                draw(row.label, at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 12),
                     color: UIColor(white: 1, alpha: 0.7))
                draw(row.income.rub(), at: CGPoint(x: margin + 60, y: y),
                     font: .systemFont(ofSize: 12, weight: .medium),
                     color: UIColor(red: 0.204, green: 0.827, blue: 0.6, alpha: 1))
                draw(row.expenses.rub(), at: CGPoint(x: rect.width - margin - 100, y: y),
                     font: .systemFont(ofSize: 11),
                     color: UIColor(red: 1, green: 0.357, blue: 0.357, alpha: 0.8),
                     alignment: .right, width: 100)
                y += 20
            }
        }

        // Footer
        let footerY = rect.height - 36
        drawDivider(at: footerY - 8, in: rect, context: context)
        draw("Создано в Finery · finery.app", at: CGPoint(x: margin, y: footerY),
             font: .systemFont(ofSize: 9),
             color: UIColor(white: 1, alpha: 0.25))
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
        draw(dateStr, at: CGPoint(x: rect.width - margin - 120, y: footerY),
             font: .systemFont(ofSize: 9),
             color: UIColor(white: 1, alpha: 0.25),
             alignment: .right, width: 120)
    }

    // MARK: - Helpers

    @discardableResult
    private func drawKV(_ key: String, value: String, x: CGFloat, y: CGFloat,
                         valueColor: UIColor, fontSize: CGFloat = 14) -> CGFloat {
        draw(key, at: CGPoint(x: x, y: y),
             font: .systemFont(ofSize: 10),
             color: UIColor(white: 1, alpha: 0.4))
        draw(value, at: CGPoint(x: x, y: y + 16),
             font: .systemFont(ofSize: fontSize, weight: .semibold),
             color: valueColor)
        return y + 44
    }

    @discardableResult
    private func drawBreakdownRow(name: String, amount: Decimal, percent: Double,
                                   x: CGFloat, y: CGFloat, width: CGFloat,
                                   context: CGContext) -> CGFloat {
        draw(name, at: CGPoint(x: x, y: y),
             font: .systemFont(ofSize: 12),
             color: .white)
        draw(amount.rub(), at: CGPoint(x: x + width - 100, y: y),
             font: .systemFont(ofSize: 12, weight: .medium),
             color: .white,
             alignment: .right, width: 100)
        let pctStr = String(format: "%.0f%%", percent)
        draw(pctStr, at: CGPoint(x: x + width - 160, y: y),
             font: .systemFont(ofSize: 11),
             color: UIColor(white: 1, alpha: 0.4),
             alignment: .right, width: 50)

        // Bar
        let barY = y + 18
        let barW = width * CGFloat(percent / 100)
        context.setFillColor(UIColor(white: 1, alpha: 0.1).cgColor)
        context.fill(CGRect(x: x, y: barY, width: width, height: 3))
        context.setFillColor(UIColor(red: 0.29, green: 0.619, blue: 1.0, alpha: 0.7).cgColor)
        context.fill(CGRect(x: x, y: barY, width: barW, height: 3))

        return y + 28
    }

    private func drawDivider(at y: CGFloat, in rect: CGRect, context: CGContext) {
        context.setFillColor(UIColor(white: 1, alpha: 0.08).cgColor)
        context.fill(CGRect(x: 0, y: y, width: rect.width, height: 0.5))
    }

    private func draw(_ text: String, at point: CGPoint,
                      font: UIFont, color: UIColor,
                      alignment: NSTextAlignment = .left,
                      width: CGFloat = 400,
                      tracking: CGFloat = 0) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment

        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style,
        ]
        if tracking != 0 {
            attrs[.kern] = tracking
        }

        let drawRect = CGRect(x: point.x, y: point.y, width: width, height: 200)
        text.draw(in: drawRect, withAttributes: attrs)
    }
}

private extension Decimal {
    func rub() -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.maximumFractionDigits = 0
        return (fmt.string(from: self as NSDecimalNumber) ?? "\(self)") + "\u{202F}₽"
    }
}
