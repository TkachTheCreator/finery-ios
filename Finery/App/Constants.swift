import Foundation

enum Constants {
    /// Anthropic API key — set in Info.plist under "ANTHROPIC_API_KEY"
    /// or paste your key directly below for local development.
    static let anthropicAPIKey: String = {
        let plistKey = Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String ?? ""
        if !plistKey.isEmpty { return plistKey }
        return ""   // ← paste key here for local dev
    }()
}
