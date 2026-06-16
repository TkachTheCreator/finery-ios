import SwiftUI

struct WelcomeView: View {
    @State private var currentSlide = 0
    @State private var appeared = false
    var onFinish: () -> Void

    let slides: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("chart.line.uptrend.xyaxis",
         "Все твои деньги.\nОдин экран.",
         "Boosty, донаты, реклама — всё в одном месте",
         Color(h: "0047AB")),
        ("percent",
         "Налоги без\nголовной боли.",
         "НПД, УСН — считаем автоматически. Напомним до 28 числа",
         Color(h: "002F7A")),
        ("mic.fill",
         "Голосовой ввод\nтранзакций.",
         "Скажи «получил 50 тысяч за рекламу» — готово",
         Color(h: "003D99")),
        ("doc.text.fill",
         "Отчёт для бренда\nодной кнопкой.",
         "PDF с твоими доходами — отправь прямо из приложения",
         Color(h: "0047AB")),
    ]

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentSlide) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        slideView(slide: slide, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: UIScreen.main.bounds.height * 0.72)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentSlide)

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<slides.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentSlide ? FC.cobalt : FC.border)
                                .frame(width: i == currentSlide ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentSlide)
                        }
                    }

                    VStack(spacing: 12) {
                        Button {
                            HapticManager.impact(.medium)
                            if currentSlide < slides.count - 1 {
                                withAnimation { currentSlide += 1 }
                            } else {
                                onFinish()
                            }
                        } label: {
                            Text(currentSlide < slides.count - 1 ? "Далее" : "Начать бесплатно")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(FC.cobalt)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            HapticManager.light()
                            onFinish()
                        } label: {
                            Text("У меня уже есть аккаунт")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(FC.cobalt)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    func slideView(
        slide: (icon: String, title: String, subtitle: String, color: Color),
        index: Int
    ) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(slide.color)
                    .shadow(color: slide.color.opacity(0.3), radius: 32, x: 0, y: 16)

                VStack(spacing: 24) {
                    HStack {
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Text("F")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                            Circle()
                                .fill(Color(h: "C8FF00"))
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: 2)
                        }
                        Spacer()
                        Text("Finery")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 32)

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Image(systemName: slide.icon)
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)

                    Spacer()

                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color(h: "C8FF00"))
                            .frame(width: 12, height: 12)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.52)
            .padding(.horizontal, 24)
            .padding(.top, 60)

            VStack(spacing: 10) {
                Text(slide.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(FC.ink)
                    .multilineTextAlignment(.center)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)

                Text(slide.subtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.muted)
                    .multilineTextAlignment(.center)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
        }
        .onAppear {
            appeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true }
        }
        .onChange(of: currentSlide) { _, _ in
            appeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true }
        }
    }
}

#Preview {
    WelcomeView(onFinish: {})
}
