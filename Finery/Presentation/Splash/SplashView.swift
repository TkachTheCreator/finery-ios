import SwiftUI

struct SplashView: View {
    @State private var scale:         CGFloat = 0.3
    @State private var opacity:       Double  = 0
    @State private var waveScale:     CGFloat = 0
    @State private var dotScale:      CGFloat = 0
    @State private var chartProgress: CGFloat = 0
    @State private var textOpacity:   Double  = 0
    @State private var exit:          Bool    = false
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(FC.cobalt)
                        .frame(width: 100, height: 100)
                        .shadow(color: FC.cobalt.opacity(0.3), radius: 24, x: 0, y: 8)
                        .overlay(
                            Circle()
                                .fill(FC.cobaltDark)
                                .scaleEffect(waveScale)
                                .opacity(waveScale > 0 ? max(0, 1 - waveScale / 2) : 0)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 26))
                        )

                    Canvas { ctx, size in
                        let w = size.width
                        let h = size.height

                        // Vertical bar of F
                        ctx.fill(
                            Path(roundedRect: CGRect(x: w*0.19, y: h*0.17, width: w*0.11, height: h*0.66),
                                 cornerRadius: w*0.055),
                            with: .color(.white))

                        // Top horizontal bar
                        ctx.fill(
                            Path(roundedRect: CGRect(x: w*0.19, y: h*0.17, width: w*0.50, height: h*0.11),
                                 cornerRadius: w*0.055),
                            with: .color(.white))

                        // Mid horizontal bar
                        ctx.fill(
                            Path(roundedRect: CGRect(x: w*0.19, y: h*0.42, width: w*0.34, height: h*0.10),
                                 cornerRadius: w*0.048),
                            with: .color(.white))

                        // Growth chart (draws progressively via chartProgress)
                        let points: [CGPoint] = [
                            CGPoint(x: w*0.33, y: h*0.74),
                            CGPoint(x: w*0.44, y: h*0.58),
                            CGPoint(x: w*0.56, y: h*0.65),
                            CGPoint(x: w*0.68, y: h*0.44),
                            CGPoint(x: w*0.78, y: h*0.48)
                        ]
                        let count = points.count
                        let progressCount = Int(CGFloat(count - 1) * chartProgress)
                        if progressCount > 0 {
                            var chart = Path()
                            chart.move(to: points[0])
                            for i in 1...min(progressCount, count - 1) {
                                chart.addLine(to: points[i])
                            }
                            ctx.stroke(chart,
                                       with: .color(Color(h: "C8FF00")),
                                       style: StrokeStyle(lineWidth: w*0.028, lineCap: .round, lineJoin: .round))
                        }
                    }
                    .frame(width: 100, height: 100)

                    // Lime badge dot
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

    private func animate() {
        // 1. Logo springs in
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
            scale = 1.0; opacity = 1.0
        }
        // 2. Zoom wave inside icon
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            waveScale = 2.0
        }
        // 3. Chart line draws
        withAnimation(.easeInOut(duration: 0.5).delay(0.45)) {
            chartProgress = 1.0
        }
        // 4. Lime dot bounces in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.45).delay(0.85)) {
            dotScale = 1.0
        }
        // 5. Tagline fades up
        withAnimation(.easeOut(duration: 0.35).delay(0.6)) {
            textOpacity = 1.0
        }
        // 6. Exit
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeIn(duration: 0.35)) { exit = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onFinish() }
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
