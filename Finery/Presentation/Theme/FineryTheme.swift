import SwiftUI

// MARK: - Colors (Warm Sand palette)

enum FC {
    static let background  = Color(h: "F5EFE0")
    static let surface     = Color(h: "EDE4CE")
    static let border      = Color(h: "D4C9A8")
    static let cobalt      = Color(h: "0047AB")
    static let cobaltDark  = Color(h: "002F7A")
    static let ink         = Color(h: "1A1A18")
    static let muted       = Color(h: "8B7D5A")
    static let success     = Color(h: "1A6B3C")
    static let danger      = Color(h: "B03A2E")
    static let amber       = Color(h: "C17F24")

    static let backgroundGradient = LinearGradient(
        colors: [Color(h: "F5EFE0"), Color(h: "EDE4CE")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cobaltGlow  = Color(h: "0047AB").opacity(0.22)
    static let successGlow = Color(h: "1A6B3C").opacity(0.18)
    static let dangerGlow  = Color(h: "B03A2E").opacity(0.18)
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

// MARK: - Animation presets

extension Animation {
    static let fineryMicro  = Animation.spring(response: 0.28, dampingFraction: 0.70)
    static let fineryCard   = Animation.spring(response: 0.50, dampingFraction: 0.82)
    static let fineryPage   = Animation.spring(response: 0.55, dampingFraction: 0.88)
    static let fineryNumber = Animation.spring(response: 0.42, dampingFraction: 0.80)
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
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(FC.muted)
    }

    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func glassCardSmall() -> some View {
        modifier(GlassCardModifier(cornerRadius: 14))
    }

    func glassCardGlow(_ glowColor: Color = FC.cobaltGlow, cornerRadius: CGFloat = 18) -> some View {
        modifier(GlassCardGlowModifier(glowColor: glowColor, cornerRadius: cornerRadius))
    }
}

// MARK: - Pressable

struct PressableModifier: ViewModifier {
    @State private var isPressed = false
    var action: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .brightness(isPressed ? -0.025 : 0)
            .animation(.fineryMicro, value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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

// MARK: - Card modifiers (warm surface style)

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(FC.surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(FC.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color(h: "8B7D5A").opacity(0.10), radius: 10, y: 3)
    }
}

struct GlassCardGlowModifier: ViewModifier {
    var glowColor: Color
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(FC.surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(FC.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color(h: "8B7D5A").opacity(0.10), radius: 10, y: 3)
            .shadow(color: glowColor, radius: 18, y: 2)
    }
}

// MARK: - Skeleton shimmer (warm sand gradient)

struct SkeletonView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                stops: [
                    .init(color: FC.surface,                  location: 0.0),
                    .init(color: FC.border,                   location: 0.4),
                    .init(color: Color(h: "C4B88A"),          location: 0.5),
                    .init(color: FC.border,                   location: 0.6),
                    .init(color: FC.surface,                  location: 1.0),
                ],
                startPoint: .init(x: phase, y: 0),
                endPoint:   .init(x: phase + 1, y: 0)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
    }
}

extension View {
    func skeleton(active: Bool) -> some View {
        self.overlay(active ? AnyView(SkeletonView()) : AnyView(EmptyView()))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
