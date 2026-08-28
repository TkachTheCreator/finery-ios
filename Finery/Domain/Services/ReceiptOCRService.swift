import Vision
import UIKit
import Foundation

struct ReceiptOCRResult {
    let amount: Decimal
    let rawText: String
    let suggestedCategory: ExpenseCategory
}

struct ReceiptOCRService {

    // Runs VNRecognizeTextRequest on the given image and extracts receipt data
    static func scan(_ image: UIImage) async throws -> ReceiptOCRResult? {
        guard let cgImage = image.cgImage else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let lines = request.results?
                    .compactMap { $0 as? VNRecognizedTextObservation }
                    .compactMap { $0.topCandidates(1).first?.string }
                    ?? []
                let fullText = lines.joined(separator: "\n")
                let result = parseReceipt(lines: lines, fullText: fullText)
                continuation.resume(returning: result)
            }
            request.recognitionLanguages = ["ru-RU", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Receipt parsing

    private static func parseReceipt(lines: [String], fullText: String) -> ReceiptOCRResult? {
        guard let amount = extractTotal(from: lines, fullText: fullText) else { return nil }
        let category = guessCategory(from: fullText)
        return ReceiptOCRResult(amount: amount, rawText: fullText, suggestedCategory: category)
    }

    // Looks for "ИТОГО", "ИТОГ", "СУММА", "TOTAL", "К ОПЛАТЕ" lines and grabs the number after them
    private static func extractTotal(from lines: [String], fullText: String) -> Decimal? {
        let totalMarkers = ["итого", "итог", "к оплате", "total", "сумма", "sum", "к получению", "оплачено"]

        for (i, line) in lines.enumerated() {
            let lower = line.lowercased()
            if totalMarkers.contains(where: { lower.contains($0) }) {
                // Try same line first
                if let amount = BankSMSParser.extractAmount(line) { return amount }
                // Then look in the next 1-2 lines
                for j in (i+1)...min(i+2, lines.count-1) {
                    if let amount = extractDecimal(from: lines[j]) { return amount }
                }
            }
        }

        // Fallback: find the largest number on the receipt (often the total)
        var largest: Decimal = 0
        for line in lines {
            if let v = extractDecimal(from: line), v > largest { largest = v }
        }
        return largest > 0 ? largest : nil
    }

    private static func extractDecimal(from text: String) -> Decimal? {
        // Match: 1 500.00, 1500,50, 500.00
        let pattern = #"(\d[\d\s]*[.,]\d{2}|\d{3,})"#
        if let m = text.firstMatch(of: try! Regex(pattern, as: (Substring, Substring).self)) {
            let raw = String(m.1)
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ",", with: ".")
            if let v = Decimal(string: raw), v > 0 { return v }
        }
        return nil
    }

    private static func guessCategory(from text: String) -> ExpenseCategory {
        let lower = text.lowercased()
        if lower.contains("кафе") || lower.contains("ресторан") || lower.contains("столовая")
            || lower.contains("coffee") || lower.contains("cafe") || lower.contains("бар") { return .food }
        if lower.contains("такси") || lower.contains("яндекс") || lower.contains("авто")
            || lower.contains("бензин") || lower.contains("метро") || lower.contains("билет") { return .transport }
        if lower.contains("связь") || lower.contains("мтс") || lower.contains("билайн")
            || lower.contains("мегафон") || lower.contains("теле2") { return .communication }
        if lower.contains("реклама") || lower.contains("промо") { return .advertising }
        if lower.contains("ноутбук") || lower.contains("камер") || lower.contains("техника")
            || lower.contains("электроник") { return .equipment }
        return .other
    }
}
