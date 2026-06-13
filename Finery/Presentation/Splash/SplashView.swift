import SwiftUI

struct SplashView: View {
    var onFinish: () -> Void

    @State private var logoScale:      CGFloat = 0.3
    @State private var logoOpacity:    CGFloat = 0.0
    @State private var strokePath1:    CGFloat = 0      // top bar + stem
    @State private var strokePath2:    CGFloat = 0      // middle bar
    @State private var dotScale:       CGFloat = 0
    @State private var exitOffset:     CGFloat = 0
    @State private var exitOpacity:    CGFloat = 1.0

    var body: some View {
        ZStack {
            Color(h: "F5EFE0").ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo
                ZStack {
                    // Blue square
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(h: "0047AB"))
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(h: "0047AB").opacity(0.30), radius: 20, y: 8)

                    // F as animated stroke
                    Canvas { ctx, size in } // placeholder layer
                        .frame(width: 100, height: 100)
                        .overlay(fStroke)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Wordmark
                Text("Finery")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color(h: "1A1A18"))
                    .opacity(logoOpacity)

                // Dot bounce indicator
                Circle()
                    .fill(Color(h: "0047AB"))
                    .frame(width: 6, height: 6)
                    .scaleEffect(dotScale)
                    .opacity(dotScale)
            }
            .offset(y: exitOffset)
            .opacity(exitOpacity)
        }
        .onAppear { runSequence() }
    }

    // MARK: - F Stroke Drawing

    private var fStroke: some View {
        ZStack {
            // Path 1: top-right → top-left → bottom of stem
            Path { p in
                p.move(to:    CGPoint(x: 72, y: 22))
                p.addLine(to: CGPoint(x: 26, y: 22))
                p.addLine(to: CGPoint(x: 26, y: 78))
            }
            .trim(from: 0, to: strokePath1)
            .stroke(
                Color.white,
                style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
            )

            // Path 2: middle bar
            Path { p in
                p.move(to:    CGPoint(x: 26, y: 52))
                p.addLine(to: CGPoint(x: 62, y: 52))
            }
            .trim(from: 0, to: strokePath2)
            .stroke(
                Color.white,
                style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: 100, height: 100)
    }

    // MARK: - Animation Sequence

    private func runSequence() {
        // 1. Logo appears
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }

        // 2. F top bar + stem draws
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.65)) {
                strokePath1 = 1.0
            }
        }

        // 3. F middle bar draws
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            withAnimation(.easeOut(duration: 0.40)) {
                strokePath2 = 1.0
            }
        }

        // 4. Dot bounces in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.45)) {
                dotScale = 1.0
            }
        }

        // 5. Exit: everything moves up, callback fires
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                exitOffset  = -60
                exitOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                onFinish()
            }
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
