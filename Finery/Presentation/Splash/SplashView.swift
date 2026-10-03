import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale:        CGFloat = 0.3
    @State private var opacity:      Double  = 0
    @State private var waveScale:    CGFloat = 0
    @State private var dotScale:     CGFloat = 0
    @State private var textOpacity:  Double  = 0
    @State private var exit:         Bool    = false
    @State private var shimmerPhase: CGFloat = -1.5
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack(alignment: .bottomTrailing) {
                    // ── Logo square ──────────────────────────────────────
                    ZStack {
                        // Dark espresso background
                        RoundedRectangle(cornerRadius: 26)
                            .fill(FC.cobalt)
                            .shadow(color: FC.cobalt.opacity(0.3), radius: 24, x: 0, y: 8)

                        // Wave pulse overlay
                        Circle()
                            .fill(FC.cobaltDark)
                            .scaleEffect(waveScale)
                            .opacity(waveScale > 0 ? max(0, 1 - waveScale / 2) : 0)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 26))

                        // Two-petal F logo (vectorized)
                        FineryLogoMarkFitted()
                            .frame(width: 78, height: 78)

                        // Shimmer sweep — one diagonal pass per cycle
                        if !reduceMotion {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear,                location: 0.28),
                                    .init(color: .white.opacity(0.44),  location: 0.50),
                                    .init(color: .clear,                location: 0.72),
                                ],
                                startPoint: UnitPoint(x: shimmerPhase,       y: 0),
                                endPoint:   UnitPoint(x: shimmerPhase + 1.0, y: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                            .allowsHitTesting(false)
                        }
                    }
                    .frame(width: 100, height: 100)

                    // Lime accent dot at bottom-trailing
                    Circle()
                        .fill(Color(h: "C8FF00"))
                        .frame(width: 14, height: 14)
                        .shadow(color: Color(h: "C8FF00").opacity(0.6), radius: 8)
                        .scaleEffect(dotScale)
                        .offset(x: 5, y: 5)
                }
                .scaleEffect(scale)
                .opacity(opacity)

                VStack(spacing: 6) {
                    Text("Finery")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(FC.ink)
                        .tracking(3)
                    Text("Все твои деньги. Один экран.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(FC.muted)
                        .tracking(1)
                }
                .opacity(textOpacity)
            }
        }
        .scaleEffect(exit ? 1.08 : 1.0)
        .opacity(exit ? 0 : 1.0)
        .onAppear { animate() }
    }

    // MARK: - Animation

    private func animate() {
        if reduceMotion {
            scale = 1.0; waveScale = 2.0; dotScale = 1.0
            withAnimation(.easeInOut(duration: 0.3)) { opacity = 1.0; textOpacity = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.25)) { exit = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onFinish() }
            }
            return
        }

        // 1. Logo bounces in
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
            scale = 1.0; opacity = 1.0
        }
        // 2. Wave pulse inside logo
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            waveScale = 2.0
        }
        // 3. Lime dot bounces
        withAnimation(.spring(response: 0.4, dampingFraction: 0.45).delay(0.75)) {
            dotScale = 1.0
        }
        // 4. Tagline fades up
        withAnimation(.easeOut(duration: 0.35).delay(0.55)) {
            textOpacity = 1.0
        }
        // 5. Shimmer: two diagonal passes after logo springs in
        //    delay 0.45s → 2 × 0.88s = 1.76s → ends at 2.21s, exit at 2.5s ✓
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.88).repeatCount(2, autoreverses: false)) {
                shimmerPhase = 2.5
            }
        }
        // 6. Exit
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeIn(duration: 0.35)) { exit = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onFinish() }
        }
    }
}

#Preview("Splash") {
    SplashView(onFinish: {})
}
