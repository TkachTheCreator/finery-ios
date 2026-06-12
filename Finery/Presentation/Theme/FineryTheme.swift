import SwiftUI

// MARK: - Colors

enum FC {
    static let background = Color(h: "0A0E1A")
    static let surface    = Color.white.opacity(0.08)
    static let cobalt     = Color(h: "4A9EFF")
    static let ink        = Color.white
    static let muted      = Color(h: "8B9CC8")
    static let border     = Color(h: "2A3252")
    static let danger     = Color(h: "FF5B5B")
    static let success    = Color(h: "34D399")
    static let amber      = Color(h: "FBBF24")

    static let backgroundGradient = LinearGradient(
        colors: [Color(h: "0A0E1A"), Color(h: "1A1035")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cobaltGlow    = Color(h: "4A9EFF").opacity(0.45)
    static let successGlow   = Color(h: "34D399").opacity(0.35)
    static let dangerGlow    = Color(h: "FF5B5B").opacity(0.35)
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

// MARK: - Animation presets (per ui-ux-pro-max: 150-300ms micro, spring ease-out entry)

extension Animation {
    /// 200ms snappy spring — for tab switches, button presses
    static let fineryMicro   = Animation.spring(response: 0.28, dampingFraction: 0.7)
    /// 350ms smooth spring — for card entrance, sheet appear
    static let fineryCard    = Animation.spring(response: 0.48, dampingFraction: 0.82)
    /// 550ms settled spring — for page-level transitions
    static let fineryPage    = Animation.spring(response: 0.55, dampingFraction: 0.88)
    /// Number roll — numeric text content transition
    static let fineryNumber  = Animation.spring(response: 0.42, dampingFraction: 0.8)
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

    /// Card with ambient glow — use for key data cards on Dashboard
    func glassCardGlow(_ glowColor: Color = FC.cobaltGlow, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardGlowModifier(glowColor: glowColor, cornerRadius: cornerRadius))
    }
}

// MARK: - Pressable (scale 0.97 + haptic, per ui-ux-pro-max active states)

struct PressableModifier: ViewModifier {
    @State private var isPressed = false
    var action: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.965 : 1.0)
            .brightness(isPressed ? -0.04 : 0)
            .animation(.fineryMicro, value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                    .onEnded { _ in
                        isPressed = false
                        action?()
                    }
            )
    }
}

extension View {
    func pressable(action: (() -> Void)? = nil) -> some View {
        modifier(PressableModifier(action: action))
    }
}

// MARK: - Glass Card (enhanced backdrop blur layering)

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.38), radius: 18, y: 6)
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.38), radius: 18, y: 6)
    }
}

// MARK: - Glass Card with ambient glow

struct GlassCardGlowModifier: ViewModifier {
    var glowColor: Color
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.30), .white.opacity(0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.38), radius: 18, y: 6)
            .shadow(color: glowColor, radius: 22, y: 4)
    }
}
