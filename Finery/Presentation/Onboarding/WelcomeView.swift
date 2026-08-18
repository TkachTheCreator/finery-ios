import SwiftUI

struct WelcomeView: View {
    var onRegister: () -> Void
    var onLogin: () -> Void

    @State private var current = 0

    private struct Slide {
        let icon: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(icon: "chart.line.uptrend.xyaxis",
              title: "Финансы\nпод контролем",
              body: "Все доходы и расходы в одном месте.\nBoosty, донаты, реклама — всё учтено"),
        .init(icon: "mic.fill",
              title: "Голосовой\nввод",
              body: "Скажи «получил 50 тысяч за рекламу» —\nтранзакция добавится автоматически"),
        .init(icon: "doc.text.fill",
              title: "Налоги\nавтоматически",
              body: "НПД и УСН считаются сами.\nНапомним за 5 дней до 28 числа"),
        .init(icon: "star.fill",
              title: "Готово\nк старту",
              body: "Начни вести финансы прямо сейчас.\nБесплатно и без лишних сложностей"),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                FC.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Icon zone — top ~62%
                    ZStack {
                        SlideIconView(icon: slides[current].icon)
                            .id(current)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: current)

                    // Bottom block — fixed ~38%
                    bottomBlock
                        .frame(height: geo.size.height * 0.38)
                }
            }
        }
    }

    // MARK: Nested icon view (own @State so each slide animates independently)

    private struct SlideIconView: View {
        let icon: String
        @State private var appeared = false

        var body: some View {
            ZStack {
                Circle()
                    .fill(FC.cobalt.opacity(0.07))
                    .frame(width: 240, height: 240)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1), value: appeared)

                Image(systemName: icon)
                    .font(.system(size: 88, weight: .light))
                    .foregroundStyle(FC.cobalt)
                    .scaleEffect(appeared ? 1.0 : 0.7)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.68).delay(0.2), value: appeared)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { appeared = true }
            }
        }
    }

    // MARK: Bottom block

    private var bottomBlock: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Text(slides[current].title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(FC.ink)
                    .multilineTextAlignment(.center)

                Text(slides[current].body)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(FC.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)

            Spacer()

            // Dots
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { i in
                    Capsule()
                        .fill(i == current ? FC.cobalt : FC.muted.opacity(0.25))
                        .frame(width: i == current ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
                }
            }
            .padding(.bottom, 24)

            // Buttons
            VStack(spacing: 14) {
                Button {
                    HapticManager.impact(.light)
                    if current < slides.count - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            current += 1
                        }
                    } else {
                        onRegister()
                    }
                } label: {
                    Text(current < slides.count - 1 ? "Далее" : "Начать")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FC.cobalt)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    HapticManager.light()
                    onLogin()
                } label: {
                    Text("Уже есть аккаунт? Войти")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(FC.cobalt)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
    }
}

#Preview {
    WelcomeView(onRegister: {}, onLogin: {})
}
