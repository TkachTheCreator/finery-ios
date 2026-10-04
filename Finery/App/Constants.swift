import Foundation

enum Constants {
    // ANTHROPIC_API_KEY намеренно не хранится в бандле (Info.plist/xcconfig извлекаемы).
    // Для продакшна: передавать через backend-прокси (запросы идут через /api/v1/ai/*).
    // Для локальной разработки: задать переменную окружения ANTHROPIC_API_KEY в схеме Xcode
    // (Product → Scheme → Edit → Run → Arguments → Environment Variables) — она не попадает в бандл.
    static let anthropicAPIKey: String = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
}
