import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var dotScale: CGFloat = 0
    @State private var dotOpacity: Double = 0
    @State private var nameOpacity: Double = 0
    @State private var exit: Bool = false
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(h: "F5EFE0").ignoresSafeArea()

            VStack(spacing: 24) {

                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color(h: "0047AB"))
                        .frame(width: 96, height: 96)
                        .shadow(color: Color(h: "0047AB").opacity(0.3),
                                radius: 24, x: 0, y: 8)

                    Canvas { ctx, _ in
                        ctx.fill(
                            Path(CGRect(x: 28, y: 22, width: 8, height: 52)),
                            with: .color(.white)
                        )
                        ctx.fill(
                            Path(CGRect(x: 28, y: 22, width: 36, height: 8)),
                            with: .color(.white)
                        )
                        ctx.fill(
                            Path(CGRect(x: 28, y: 44, width: 26, height: 7)),
                            with: .color(.white)
                        )
                    }
                    .frame(width: 96, height: 96)

                    Circle()
                        .fill(Color(h: "C8FF00"))
                        .frame(width: 16, height: 16)
                        .shadow(color: Color(h: "C8FF00").opacity(0.5),
                                radius: 8, x: 0, y: 0)
                        .scaleEffect(dotScale)
                        .opacity(dotOpacity)
                        .offset(x: 6, y: 6)
                }
                .scaleEffect(scale)
                .opacity(opacity)

                VStack(spacing: 6) {
                    Text("Finery")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(h: "1A1A18"))
                        .tracking(2)

                    Text("финансы для своих")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(h: "8B7D5A"))
                        .tracking(3)
                }
                .opacity(nameOpacity)
            }
        }
        .scaleEffect(exit ? 1.05 : 1.0)
        .opacity(exit ? 0 : 1)
        .onAppear { animate() }
    }

    private func animate() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
            scale   = 1.0
            opacity = 1.0
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.45).delay(0.4)) {
            dotScale   = 1.0
            dotOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            nameOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.easeIn(duration: 0.35)) {
                exit = true
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
