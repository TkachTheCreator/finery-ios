import Foundation
import UIKit
import PDFKit

struct FineryPDFGenerator {

    // MARK: - Official Report (light Mercury style, transaction table)

    func generateReport(
        userName: String,
        periodLabel: String,
        income: Decimal,
        expenses: Decimal,
        taxAmount: Decimal,
        netProfit: Decimal,
        transactions: [Transaction],
        clients: [Client]
    ) -> Data {
        let pageSize   = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer   = UIGraphicsPDFRenderer(bounds: pageSize)

        // Layout constants
        let ml: CGFloat = 44          // left margin
        let mr: CGFloat = 44          // right margin
        let mt: CGFloat = 36          // top margin
        let mb: CGFloat = 36          // bottom margin
        let cw: CGFloat = pageSize.width - ml - mr  // content width = 507

        // Column widths for transaction table (total = cw)
        let colDate:  CGFloat = 68
        let colType:  CGFloat = 48
        let colCat:   CGFloat = 120
        let colDesc:  CGFloat = cw - colDate - colType - colCat - 80 - 60  // ≈ 131
        let colAmt:   CGFloat = 80
        let colCli:   CGFloat = 60

        // Row height
        let rowH: CGFloat = 20

        // Reserved height on page 1 (before first data row)
        let page1Header: CGFloat = mt + 68 + 24 + 120 + 24 + 24 + 24  // ≈ 324
        // Reserved per continuation page
        let pageContHeader: CGFloat = mt + 20 + 22  // ≈ 78

        let availPage1 = pageSize.height - page1Header - mb
        let availCont  = pageSize.height - pageContHeader - mb

        let maxRowsPage1 = Int(availPage1 / rowH)
        let maxRowsCont  = Int(availCont  / rowH)

        // Date formatter
        let dfmt = DateFormatter()
        dfmt.dateFormat = "dd.MM.yy"
        dfmt.locale = Locale(identifier: "ru_RU")

        return renderer.pdfData { ctx in
            // ── PAGE 1 ──
            ctx.beginPage()
            let cg = ctx.cgContext

            // Background
            cg.setFillColor(UIColor(red: 0.98, green: 0.972, blue: 0.953, alpha: 1).cgColor)
            cg.fill(pageSize)

            // Accent bar at top
            cg.setFillColor(UIColor(red: 0.102, green: 0.082, blue: 0.063, alpha: 1).cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: pageSize.width, height: 3))

            var y: CGFloat = mt

            // ── HEADER ──
            lightDraw("FINERY", at: CGPoint(x: ml, y: y), font: .systemFont(ofSize: 22, weight: .bold),
                      color: UIColor(red: 0.1, green: 0.082, blue: 0.063, alpha: 1))
            lightDraw("Финансовый отчёт", at: CGPoint(x: ml, y: y + 24),
                      font: .systemFont(ofSize: 11, weight: .regular),
                      color: UIColor(red: 0.54, green: 0.52, blue: 0.47, alpha: 1))

            let nameText = userName.isEmpty ? "" : userName
            lightDraw(nameText, at: CGPoint(x: pageSize.width - mr - 180, y: y + 4),
                      font: .systemFont(ofSize: 11, weight: .medium),
                      color: UIColor(red: 0.1, green: 0.082, blue: 0.063, alpha: 1),
                      alignment: .right, width: 180)
            lightDraw(periodLabel, at: CGPoint(x: pageSize.width - mr - 180, y: y + 20),
                      font: .systemFont(ofSize: 10, weight: .regular),
                      color: UIColor(red: 0.54, green: 0.52, blue: 0.47, alpha: 1),
                      alignment: .right, width: 180)

            y += 68
            lightDivider(at: y, in: pageSize, context: cg, margin: ml)
            y += 16

            // ── SUMMARY ──
            let cardW  = (cw - 12) / 2
            let cardH: CGFloat = 52
            let summaryItems: [(String, Decimal, UIColor)] = [
                ("Доходы",    income,    UIColor(red: 0.1, green: 0.082, blue: 0.063, alpha: 1)),
                ("Расходы",   expenses,  UIColor(red: 0.75, green: 0.3,  blue: 0.2,   alpha: 1)),
                ("Налог",     taxAmount, UIColor(red: 0.6,  green: 0.42, blue: 0.0,   alpha: 1)),
                ("Прибыль",   netProfit, UIColor(red: 0.1,  green: 0.42, blue: 0.235, alpha: 1)),
            ]
            for (i, item) in summaryItems.enumerated() {
                let col: CGFloat = i % 2 == 0 ? ml : ml + cardW + 12
                let row: CGFloat = i < 2 ? y : y + cardH + 8
                // Card background
                cg.setFillColor(UIColor.white.cgColor)
                cg.fill(CGRect(x: col, y: row, width: cardW, height: cardH))
                // Card border
                cg.setStrokeColor(UIColor(red: 0.91, green: 0.886, blue: 0.851, alpha: 1).cgColor)
                cg.setLineWidth(0.5)
                cg.stroke(CGRect(x: col + 0.25, y: row + 0.25, width: cardW - 0.5, height: cardH - 0.5))
                // Text
                lightDraw(item.0, at: CGPoint(x: col + 12, y: row + 8),
                          font: .systemFont(ofSize: 9, weight: .regular),
                          color: UIColor(red: 0.54, green: 0.52, blue: 0.47, alpha: 1))
                lightDraw(item.1.rubPDF(), at: CGPoint(x: col + 12, y: row + 22),
                          font: .systemFont(ofSize: 15, weight: .semibold),
                          color: item.2, width: cardW - 24)
            }
            y += cardH * 2 + 8 + 16

            lightDivider(at: y, in: pageSize, context: cg, margin: ml)
            y += 16

            // ── TABLE HEADER LABEL ──
            lightDraw("ТРАНЗАКЦИИ", at: CGPoint(x: ml, y: y),
                      font: .monospacedSystemFont(ofSize: 8, weight: .semibold),
                      color: UIColor(red: 0.54, green: 0.52, blue: 0.47, alpha: 1), tracking: 1.5)
            y += 16

            // Column header row
            let colHeaders: [(String, CGFloat, NSTextAlignment)] = [
                ("ДАТА",      ml,                                        .left),
                ("ТИП",       ml + colDate,                              .left),
                ("КАТЕГОРИЯ", ml + colDate + colType,                    .left),
                ("ОПИСАНИЕ",  ml + colDate + colType + colCat,           .left),
                ("СУММА",     ml + cw - colAmt - colCli,                 .right),
                ("КЛИЕНТ",    ml + cw - colCli,                          .left),
            ]
            let hdrFont  = UIFont.monospacedSystemFont(ofSize: 8, weight: .semibold)
            let hdrColor = UIColor(red: 0.54, green: 0.52, blue: 0.47, alpha: 1)
            for h in colHeaders {
                lightDraw(h.0, at: CGPoint(x: h.1, y: y), font: hdrFont, color: hdrColor,
                          alignment: h.2, width: 120, tracking: 1.2)
            }
            y += 8
            lightDivider(at: y, in: pageSize, context: cg, margin: ml)
            y += 4

            // ── TRANSACTION ROWS ──
            let batch1 = Array(transactions.prefix(maxRowsPage1))
            var rest   = Array(transactions.dropFirst(maxRowsPage1))
            drawRows(batch1, startY: &y, context: cg, pageW: pageSize.width,
                     ml: ml, colDate: colDate, colType: colType, colCat: colCat,
                     colDesc: colDesc, colAmt: colAmt, colCli: colCli, cw: cw,
                     rowH: rowH, clients: clients, dfmt: dfmt)

            // ── FOOTER PAGE 1 ──
            drawPageFooter(in: pageSize, context: cg, margin: ml)

            // ── CONTINUATION PAGES ──
            var pageNum = 2
            while !rest.isEmpty {
                ctx.beginPage()
                let cg2 = ctx.cgContext
                cg2.setFillColor(UIColor(red: 0.98, green: 0.972, blue: 0.953, alpha: 1).cgColor)
                cg2.fill(pageSize)
                cg2.setFillColor(UIColor(red: 0.102, green: 0.082, blue: 0.063, alpha: 1).cgColor)
                cg2.fill(CGRect(x: 0, y: 0, width: pageSize.width, height: 3))

                var y2: CGFloat = mt
                lightDraw("FINERY · Транзакции, стр. \(pageNum)", at: CGPoint(x: ml, y: y2),
                          font: .systemFont(ofSize: 9, weight: .regular),
                          color: UIColor(red: 0.54, green: 0.52, blue: 0.47, alpha: 1))
                y2 += 20
                lightDivider(at: y2, in: pageSize, context: cg2, margin: ml)
                y2 += 4

                let batch = Array(rest.prefix(maxRowsCont))
                rest = Array(rest.dropFirst(maxRowsCont))
                drawRows(batch, startY: &y2, context: cg2, pageW: pageSize.width,
                         ml: ml, colDate: colDate, colType: colType, colCat: colCat,
                         colDesc: colDesc, colAmt: colAmt, colCli: colCli, cw: cw,
                         rowH: rowH, clients: clients, dfmt: dfmt)

                drawPageFooter(in: pageSize, context: cg2, margin: ml)
                pageNum += 1
            }
        }
    }

    // MARK: Draw helpers for official report

    private func drawRows(
        _ txns: [Transaction],
        startY: inout CGFloat,
        context cg: CGContext,
        pageW: CGFloat,
        ml: CGFloat,
        colDate: CGFloat, colType: CGFloat, colCat: CGFloat,
        colDesc: CGFloat, colAmt: CGFloat, colCli: CGFloat,
        cw: CGFloat,
        rowH: CGFloat,
        clients: [Client],
        dfmt: DateFormatter
    ) {
        let inkColor     = UIColor(red: 0.1,  green: 0.082, blue: 0.063, alpha: 1)
        let mutedColor   = UIColor(red: 0.54, green: 0.52,  blue: 0.47,  alpha: 1)
        let incomeColor  = UIColor(red: 0.1,  green: 0.42,  blue: 0.235, alpha: 1)
        let expenseColor = UIColor(red: 0.75, green: 0.3,   blue: 0.2,   alpha: 1)
        let rowFont      = UIFont.systemFont(ofSize: 10, weight: .regular)
        let amtFont      = UIFont.systemFont(ofSize: 10, weight: .medium)

        for (i, tx) in txns.enumerated() {
            // Alternating row background
            if i % 2 == 0 {
                cg.setFillColor(UIColor(red: 0.96, green: 0.956, blue: 0.942, alpha: 1).cgColor)
                cg.fill(CGRect(x: ml, y: startY, width: cw, height: rowH))
            }

            let date = dfmt.string(from: tx.date)
            let type = tx.direction == .income ? "Доход" : "Расход"
            let cat: String = tx.direction == .income
                ? (tx.incomeCategory?.displayName ?? "—")
                : (tx.expenseCategory?.displayName ?? "—")
            let desc   = String(tx.description.prefix(26))
            let amount = tx.amount.rubPDF()
            let client = tx.clientId
                .flatMap { cid in clients.first(where: { $0.id == cid })?.name.prefix(12).description } ?? ""

            let amtColor = tx.direction == .income ? incomeColor : expenseColor
            let ty = startY + 5

            lightDraw(date,   at: CGPoint(x: ml,                                      y: ty), font: rowFont, color: inkColor,   width: colDate - 4)
            lightDraw(type,   at: CGPoint(x: ml + colDate,                            y: ty), font: rowFont, color: mutedColor, width: colType - 4)
            lightDraw(cat,    at: CGPoint(x: ml + colDate + colType,                  y: ty), font: rowFont, color: inkColor,   width: colCat - 4)
            lightDraw(desc,   at: CGPoint(x: ml + colDate + colType + colCat,         y: ty), font: rowFont, color: mutedColor, width: colDesc - 4)
            lightDraw(amount, at: CGPoint(x: ml + cw - colAmt - colCli,               y: ty), font: amtFont, color: amtColor,   alignment: .right, width: colAmt - 4)
            lightDraw(client, at: CGPoint(x: ml + cw - colCli,                        y: ty), font: rowFont, color: mutedColor, width: colCli)

            startY += rowH
        }
    }

    private func drawPageFooter(in rect: CGRect, context cg: CGContext, margin: CGFloat) {
        let footerY = rect.height - 28
        cg.setFillColor(UIColor(red: 0.91, green: 0.886, blue: 0.851, alpha: 0.7).cgColor)
        cg.fill(CGRect(x: margin, y: footerY - 1, width: rect.width - margin * 2, height: 0.5))
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        lightDraw("Создано в Finery · \(dateStr)",
                  at: CGPoint(x: margin, y: footerY + 4),
                  font: .systemFont(ofSize: 8, weight: .regular),
                  color: UIColor(red: 0.54, green: 0.52, blue: 0.47, alpha: 1))
    }

    private func lightDivider(at y: CGFloat, in rect: CGRect, context cg: CGContext, margin: CGFloat) {
        cg.setFillColor(UIColor(red: 0.91, green: 0.886, blue: 0.851, alpha: 1).cgColor)
        cg.fill(CGRect(x: margin, y: y, width: rect.width - margin * 2, height: 0.5))
    }

    private func lightDraw(_ text: String, at point: CGPoint,
                            font: UIFont, color: UIColor,
                            alignment: NSTextAlignment = .left,
                            width: CGFloat = 300,
                            tracking: CGFloat = 0) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byTruncatingTail
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: style,
        ]
        if tracking != 0 { attrs[.kern] = tracking }
        text.draw(in: CGRect(x: point.x, y: point.y, width: width, height: 24), withAttributes: attrs)
    }


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

    func rubPDF() -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.maximumFractionDigits = 0
        return (fmt.string(from: self as NSDecimalNumber) ?? "\(self)") + " ₽"
    }
}
