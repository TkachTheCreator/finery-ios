import SwiftUI

// MARK: - Color Tokens

enum FC {
    // Base surfaces
    static let background    = Color(h: "FAF8F3")   // warm almost-white (was F5EFE0 — lighter, cleaner)
    static let surface       = Color(h: "FFFFFF")    // pure white cards (was EDE4CE — contrast with bg)
    static let border        = Color(h: "E8E2D9")   // subtle hairline dividers

    // Text
    static let ink           = Color(h: "1A1A1A")   // near-black primary text
    static let inkSecondary  = Color(h: "8A8578")   // warm gray for labels/secondary
    static let muted         = Color(h: "8A8578")   // alias for inkSecondary (backwards compat)

    // Brand / Interactive — ONLY for interactive elements (buttons, links, active states)
    // Warm espresso dark — replaces cold blue as primary accent throughout the app
    static let cobalt        = Color(h: "1A1510")
    static let cobaltDark    = Color(h: "120F0A")

    // Semantic
    static let income        = Color(h: "1A1510")   // same as cobalt
    static let expense       = Color(h: "C04E35")   // warm terracotta for expense amounts
    static let danger        = Color(h: "B03A2E")   // critical errors / over-limit
    static let warning       = Color(h: "9B6B00")   // NPD limit approaching (visually distinct from danger)
    static let amber         = Color(h: "9B6B00")   // alias for warning (backwards compat)
    static let success       = Color(h: "1A6B3C")

    // Hero widget — warm dark, unified with primary accent
    static let heroSurface   = Color(h: "1A1510")
    // Text on dark hero widget — warm ivory, not harsh pure white
    static let ivory         = Color(h: "EDE8DE")

    static let backgroundGradient = LinearGradient(
        colors: [Color(h: "FAF8F3"), Color(h: "F0EBE2")],
        startPoint: .top, endPoint: .bottom
    )

    static let cobaltGlow  = Color(h: "1A1510").opacity(0.18)
    static let successGlow = Color(h: "1A6B3C").opacity(0.15)
    static let dangerGlow  = Color(h: "B03A2E").opacity(0.15)
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

// MARK: - Typography Scale
//
// Display  60pt  bold      — one hero number per screen, used max once
// Title    26pt  semibold  — screen title ("Клиенты", "Налоги")
// Heading  18pt  semibold  — widget sub-headings
// Body     16pt  regular   — list rows, descriptions
// Caption  13pt  medium    — labels under values, NO all-caps

extension View {
    func fDisplay() -> some View {
        self
            .font(.system(size: 60, weight: .bold, design: .rounded))
            .monospacedDigit()
    }

    func fTitle() -> some View {
        self.font(.system(size: 26, weight: .semibold, design: .rounded))
    }

    func fHeading() -> some View {
        self.font(.system(size: 18, weight: .semibold, design: .rounded))
    }

    func fBody() -> some View {
        self.font(.system(.body, design: .rounded, weight: .regular))
    }

    // Caption label — 13pt medium warm gray. No all-caps.
    func fLabel() -> some View {
        self
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(FC.inkSecondary)
    }
}

// MARK: - Widget card modifiers

// DATA WIDGET: white surface + hairline border — Mercury rule: surface contrast, no drop shadow.
struct DataWidgetModifier: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(FC.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(FC.border.opacity(0.7), lineWidth: 0.5)
            )
    }
}

// HERO WIDGET: dark surface, white text. One per screen maximum.
struct HeroWidgetModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(FC.heroSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func dataWidget(cornerRadius: CGFloat = 18) -> some View {
        modifier(DataWidgetModifier(cornerRadius: cornerRadius))
    }

    func heroWidget(cornerRadius: CGFloat = 20) -> some View {
        modifier(HeroWidgetModifier(cornerRadius: cornerRadius))
    }

    // glassCard → now maps to dataWidget (shadow-based, no border stroke)
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(DataWidgetModifier(cornerRadius: cornerRadius))
    }

    func glassCardSmall() -> some View {
        modifier(DataWidgetModifier(cornerRadius: 14))
    }

}

// Keep struct names for code that references them directly
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(FC.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(FC.border.opacity(0.7), lineWidth: 0.5)
            )
    }
}


// MARK: - Category color palette (shared across analytics screens)

let fineryCategoryColors: [String: Color] = [
    "Boosty/Подписки":  Color(red: 0.90, green: 0.27, blue: 0.27),
    "Донаты":           Color(red: 0.97, green: 0.55, blue: 0.14),
    "Реклама":          Color(red: 0.97, green: 0.78, blue: 0.09),
    "Фриланс":          Color(red: 0.20, green: 0.65, blue: 0.42),
    "Платформы":        Color(red: 0.06, green: 0.60, blue: 0.75),
    "Курсы/Обучение":   Color(red: 0.38, green: 0.35, blue: 0.82),
    "Инструменты":      Color(red: 0.06, green: 0.60, blue: 0.75),
    "Своя реклама":     Color(red: 0.97, green: 0.55, blue: 0.14),
    "Оборудование":     Color(red: 0.20, green: 0.65, blue: 0.42),
    "Команда":          Color(red: 0.90, green: 0.27, blue: 0.27),
    "Еда":              Color(red: 0.55, green: 0.76, blue: 0.29),
    "Транспорт":        Color(red: 0.97, green: 0.78, blue: 0.09),
    "Связь":            Color(red: 0.38, green: 0.35, blue: 0.82),
    "Другое":           Color(red: 0.60, green: 0.57, blue: 0.54),
    "Остальное":        Color(red: 0.75, green: 0.72, blue: 0.68),
]

func fineryCategoryColor(_ name: String) -> Color {
    if let c = fineryCategoryColors[name] { return c }
    let h = Double(abs(name.hashValue) % 360) / 360.0
    return Color(hue: h, saturation: 0.6, brightness: 0.72)
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
                        HapticManager.impact()
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

// MARK: - Skeleton shimmer

struct SkeletonView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { _ in
            LinearGradient(
                stops: [
                    .init(color: FC.surface,              location: 0.0),
                    .init(color: FC.border,               location: 0.4),
                    .init(color: Color(h: "E0D8CC"),      location: 0.5),
                    .init(color: FC.border,               location: 0.6),
                    .init(color: FC.surface,              location: 1.0),
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

// MARK: - Button modifiers

struct FineryPrimaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(FC.cobalt)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct FinerySecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .rounded, weight: .medium))
            .foregroundStyle(FC.cobalt)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(FC.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(FC.border, lineWidth: 1))
    }
}

extension View {
    func fineryPrimaryButton() -> some View { modifier(FineryPrimaryButton()) }
    func finerySecondaryButton() -> some View { modifier(FinerySecondaryButton()) }
}

// MARK: - Scale press ButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Finery Tap (cobalt ripple + action)

private struct FineryTapModifier: ViewModifier {
    let action: () -> Void
    @State private var rippleScale:   CGFloat = 0.01
    @State private var rippleOpacity: Double  = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(FC.cobalt.opacity(0.18))
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .allowsHitTesting(false)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                rippleScale   = 0.01
                rippleOpacity = 0.32
                withAnimation(.easeOut(duration: 0.38)) {
                    rippleScale   = 3.5
                    rippleOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    action()
                }
            }
    }
}

extension View {
    func fineryTap(action: @escaping () -> Void = {}) -> some View {
        modifier(FineryTapModifier(action: action))
    }
}

// MARK: - Ring Progress (Activity Ring style — Задача 2)

struct RingProgressView: View {
    let progress: Double   // 0.0 – 1.0
    let color: Color
    var size: CGFloat     = 70
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(color.opacity(0.14), lineWidth: lineWidth)
            // Fill
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.2, dampingFraction: 0.82), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Border Trail (Задача 4)

struct BorderTrailModifier: ViewModifier {
    @State private var progress: CGFloat = 0
    var cornerRadius: CGFloat = 20
    var color: Color = FC.ivory.opacity(0.45)
    var delay: Double = 0.4

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .trim(from: max(0, progress - 0.18), to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.clear, color, .clear],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
        )
        .onAppear {
            progress = 0
            withAnimation(
                .timingCurve(0, 0.5, 0.8, 0.5, duration: 4)
                .delay(delay)
                .repeatCount(2, autoreverses: false)
            ) {
                progress = 1.0
            }
        }
    }
}

extension View {
    func borderTrail(cornerRadius: CGFloat = 20, color: Color = FC.ivory.opacity(0.45), delay: Double = 0.4) -> some View {
        modifier(BorderTrailModifier(cornerRadius: cornerRadius, color: color, delay: delay))
    }

    @ViewBuilder
    func zoomSource(id: some Hashable, ns: Namespace.ID?) -> some View {
        if let ns {
            self.matchedTransitionSource(id: id, in: ns)
        } else {
            self
        }
    }
}
