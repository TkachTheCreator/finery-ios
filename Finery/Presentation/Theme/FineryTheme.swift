import SwiftUI

// MARK: - Colors

enum FC {
    static let background = Color(h: "0A0E1A")
    static let surface    = Color(h: "131629")
    static let cobalt     = Color(h: "4A9EFF")
    static let ink        = Color(h: "F0F4FF")
    static let muted      = Color(h: "8B9CC8")
    static let border     = Color(h: "2A3252")
    static let danger     = Color(h: "FF5B5B")
    static let success    = Color(h: "34D399")
    static let amber      = Color(h: "FBBF24")

    static let backgroundGradient = LinearGradient(
        colors: [Color(h: "0A0E1A"), Color(h: "1A1035")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cobaltGlow = Color(h: "4A9EFF").opacity(0.45)
}

extension Color {
    init(h hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Number formatting

extension Decimal {
    func rub(decimals: Int = 0) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.maximumFractionDigits = decimals
        fmt.minimumFractionDigits = decimals
        return (fmt.string(from: self as NSDecimalNumber) ?? "\(self)") + "\u{202F}₽"
    }

    func percent() -> String {
        "\(Int(NSDecimalNumber(decimal: self).doubleValue))%"
    }
}

// MARK: - View modifiers

extension View {
    func fLabel() -> some View {
        self
            .font(.system(.caption2, design: .default, weight: .semibold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(FC.muted)
    }

    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func glassCardSmall() -> some View {
        modifier(GlassCardModifier(cornerRadius: 14))
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
    }
}
