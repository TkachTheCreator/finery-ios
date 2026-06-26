import Foundation

enum Constants {
    /// Anthropic API key for the AI financial advisor.
    /// Set your key here or add "AnthropicAPIKey" to Info.plist.
    static let anthropicAPIKey: String = {
        if let key = Bundle.main.infoDictionary?["AnthropicAPIKey"] as? String, !key.isEmpty {
            return key
        }
        return ""   // ← paste your key here for local dev
    }()
}
