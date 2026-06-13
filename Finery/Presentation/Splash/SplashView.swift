import SwiftUI

struct SplashView: View {
    var onFinish: () -> Void

    @State private var logoScale:    CGFloat = 0.3
    @State private var logoOpacity:  Double  = 0
    @State private var dotScale:     CGFloat = 0
    @State private var textOpacity:  Double  = 0
    @State private var splashOpacity: Double = 1

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(FC.cobalt)
                        .frame(width: 100, height: 100)
                    Text("F")
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color(h: "C8FF00"))
                        .frame(width: 14, height: 14)
                        .scaleEffect(dotScale)
                        .offset(x: 4, y: 4)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 4) {
                    Text("Finery")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(FC.ink)
                        .tracking(3)
                    Text("финансы для своих")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(FC.muted)
                        .tracking(2)
                }
                .opacity(textOpacity)
            }
        }
        .opacity(splashOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.35)) {
                dotScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.5)) {
                textOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeIn(duration: 0.35)) {
                    splashOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onFinish()
                }
            }
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
