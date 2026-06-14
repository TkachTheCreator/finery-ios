import SwiftUI

struct SplashView: View {
    @State private var iconScale:    CGFloat = 0.3
    @State private var iconOpacity:  Double  = 0
    @State private var waveScale:    CGFloat = 0.01
    @State private var waveOpacity:  Double  = 0
    @State private var dotScale:     CGFloat = 0
    @State private var titleOffset:  CGFloat = 16
    @State private var titleOpacity: Double  = 0
    @State private var tagOffset:    CGFloat = 16
    @State private var tagOpacity:   Double  = 0
    @State private var screenOpacity: Double = 1

    var onFinish: () -> Void

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            // Zoom wave behind icon
            Circle()
                .fill(Color(h: "002F7A"))
                .frame(width: 110, height: 110)
                .scaleEffect(waveScale)
                .opacity(waveOpacity)
                .allowsHitTesting(false)

            VStack(spacing: 20) {
                // Logo icon
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(FC.cobalt)
                        .frame(width: 100, height: 100)
                        .shadow(color: FC.cobalt.opacity(0.28), radius: 24, x: 0, y: 8)

                    // F + chart drawn via Canvas (R4)
                    Canvas { ctx, size in
                        let w = size.width
                        let h = size.height

                        // Vertical bar of F
                        let vertical = Path(roundedRect: CGRect(
                            x: w*0.19, y: h*0.17, width: w*0.11, height: h*0.66
                        ), cornerRadius: w*0.055)
                        ctx.fill(vertical, with: .color(.white))

                        // Top horizontal bar
                        let topBar = Path(roundedRect: CGRect(
                            x: w*0.19, y: h*0.17, width: w*0.50, height: h*0.11
                        ), cornerRadius: w*0.055)
                        ctx.fill(topBar, with: .color(.white))

                        // Mid horizontal bar
                        let midBar = Path(roundedRect: CGRect(
                            x: w*0.19, y: h*0.42, width: w*0.34, height: h*0.10
                        ), cornerRadius: w*0.048)
                        ctx.fill(midBar, with: .color(.white))

                        // Growth chart line (lime)
                        var chart = Path()
                        chart.move(to:    CGPoint(x: w*0.36, y: h*0.74))
                        chart.addLine(to: CGPoint(x: w*0.47, y: h*0.58))
                        chart.addLine(to: CGPoint(x: w*0.59, y: h*0.65))
                        chart.addLine(to: CGPoint(x: w*0.70, y: h*0.44))
                        chart.addLine(to: CGPoint(x: w*0.80, y: h*0.48))
                        ctx.stroke(chart, with: .color(Color(h: "C8FF00")),
                                   style: StrokeStyle(lineWidth: w*0.028, lineCap: .round, lineJoin: .round))

                        // Endpoint dot
                        let endDot = Path(ellipseIn: CGRect(
                            x: w*0.76, y: h*0.40, width: w*0.08, height: w*0.08
                        ))
                        ctx.fill(endDot, with: .color(Color(h: "C8FF00")))
                    }
                    .frame(width: 100, height: 100)

                    // Corner lime badge
                    Circle()
                        .fill(Color(h: "C8FF00"))
                        .frame(width: 14, height: 14)
                        .shadow(color: Color(h: "C8FF00").opacity(0.6), radius: 6)
                        .scaleEffect(dotScale)
                        .offset(x: 5, y: 5)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                // Text block
                VStack(spacing: 5) {
                    Text("Finery")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(FC.ink)
                        .tracking(2)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Text("Все твои деньги. Один экран.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(FC.muted)
                        .tracking(1)
                        .offset(y: tagOffset)
                        .opacity(tagOpacity)
                }
            }
        }
        .opacity(screenOpacity)
        .onAppear { runSequence() }
    }

    private func runSequence() {
        // 1. Icon springs in (0.0s)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
            iconScale   = 1.0
            iconOpacity = 1.0
        }

        // 2. Zoom wave expands from center (0.45s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            waveScale   = 0.01
            waveOpacity = 0.28
            withAnimation(.easeOut(duration: 0.65)) {
                waveScale   = 14
                waveOpacity = 0
            }
        }

        // 5. "Finery" title fadeUp (0.5s)
        withAnimation(.easeOut(duration: 0.38).delay(0.5)) {
            titleOffset  = 0
            titleOpacity = 1.0
        }

        // 4. Slogan fadeUp (0.65s)
        withAnimation(.easeOut(duration: 0.38).delay(0.65)) {
            tagOffset  = 0
            tagOpacity = 1.0
        }

        // 3. Lime badge bounces (0.82s)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.45).delay(0.82)) {
            dotScale = 1.0
        }

        // 6. Whole screen fades out (2.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeIn(duration: 0.35)) {
                screenOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onFinish()
            }
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
