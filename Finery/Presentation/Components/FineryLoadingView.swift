import SwiftUI

// MARK: - Coin bounce loader

struct FineryCoinLoader: View {
    @State private var offsetY: CGFloat = 0
    @State private var scaleX:  CGFloat = 1.0

    var body: some View {
        ZStack {
            // Shadow under coin
            Ellipse()
                .fill(FC.cobalt.opacity(0.12))
                .frame(width: 44, height: 8)
                .offset(y: 32)
                .scaleEffect(x: scaleX * 0.8)

            // Coin
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [FC.cobalt, FC.cobaltDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 52, height: 52)
                    .shadow(color: FC.cobalt.opacity(0.28), radius: 8, x: 0, y: 4)

                Text("₽")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .scaleEffect(x: scaleX, y: 1.0)
            .offset(y: offsetY)
        }
        .frame(width: 60, height: 80)
        .onAppear { animateCoin() }
    }

    private func animateCoin() {
        withAnimation(.easeOut(duration: 0.35)) {
            offsetY = -20
            scaleX  = 1.0
        }
        withAnimation(.linear(duration: 0.3).delay(0.35)) { scaleX = 0.05 }
        withAnimation(.linear(duration: 0.3).delay(0.65)) { scaleX = 1.0 }
        withAnimation(.easeIn(duration: 0.25).delay(0.95)) {
            offsetY = 0
            scaleX  = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { animateCoin() }
    }
}

// MARK: - Full-screen loading overlay

struct FineryLoadingOverlay: View {
    var message: String = "Обрабатываем..."

    var body: some View {
        ZStack {
            FC.background.opacity(0.95).ignoresSafeArea()
                .background(.ultraThinMaterial)
            VStack(spacing: 24) {
                FineryCoinLoader()
                Text(message)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(FC.muted)
                    .tracking(0.5)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Success overlay (coin → checkmark)

struct FinerySuccessOverlay: View {
    @State private var scale:     CGFloat = 0.3
    @State private var opacity:   Double  = 0
    @State private var showCheck: Bool    = false
    var message:   String = "Сохранено"
    var subtext:   String = "Транзакция добавлена"
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            FC.background.opacity(0.95).ignoresSafeArea()
                .background(.ultraThinMaterial)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [FC.cobalt, FC.cobaltDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 72, height: 72)
                        .shadow(color: FC.cobalt.opacity(0.28), radius: 16, x: 0, y: 6)
                        .scaleEffect(scale)

                    if showCheck {
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("₽")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .opacity(opacity)

                VStack(spacing: 6) {
                    Text(message)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(FC.ink)
                    Text(subtext)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(FC.muted)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                scale   = 1.0
                opacity = 1.0
            }
            HapticManager.impact(.medium)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    showCheck = true
                }
                HapticManager.success()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeIn(duration: 0.25)) {
                    opacity = 0
                    scale   = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    onDismiss()
                }
            }
        }
    }
}

#Preview("Coin Loader") { FineryCoinLoader() }
#Preview("Loading") { FineryLoadingOverlay(message: "Сохраняем транзакцию...") }
#Preview("Success") { FinerySuccessOverlay(message: "Готово!", onDismiss: {}) }
