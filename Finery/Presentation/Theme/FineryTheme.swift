import SwiftUI

// MARK: - Colors

enum FC {
    static let background = Color(h: "F5F0E8")
    static let surface    = Color(h: "EDE8DC")
    static let cobalt     = Color(h: "0047AB")
    static let ink        = Color(h: "1A1A18")
    static let muted      = Color(h: "6B6560")
    static let border     = Color(h: "C8C0B0")
    static let danger     = Color(h: "C0392B")
    static let success    = Color(h: "1A7A4A")
    static let amber      = Color(h: "B07800")
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
}
