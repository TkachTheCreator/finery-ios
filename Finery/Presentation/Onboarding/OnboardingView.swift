import SwiftUI
import Pow

struct OnboardingView: View {
    var onComplete: (User) -> Void

    @State private var step = 0
    @State private var selectedUserType = UserType.freelancer
    @State private var selectedTaxMode  = TaxMode.npd
    @State private var name = ""
    @State private var appeared = false

    @FocusState private var nameFocused: Bool

    private let totalSteps = 3

    var body: some View {
        ZStack {
            FC.backgroundGradient.ignoresSafeArea()

            // Subtle glow orb behind content
            Circle()
                .fill(FC.cobalt.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -60, y: -120)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -12)

                ZStack {
                    if step == 0 {
                        stepWhoAreYou
                            .transition(AnyTransition.movingParts.iris(origin: .center))
                    } else if step == 1 {
                        stepTaxMode
                            .transition(AnyTransition.movingParts.iris(origin: .center))
                    } else {
                        stepName
                            .transition(AnyTransition.movingParts.iris(origin: .center))
                    }
                }
                .animation(.spring(response: 0.55, dampingFraction: 0.82), value: step)

                bottomControls
                    .padding(.bottom, 48)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appeared)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.1)) { appeared = true }
        }
        .onChange(of: step) { _, newStep in
            if newStep == 2 { nameFocused = true }
        }
    }

    // MARK: Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        i <= step
                        ? LinearGradient(colors: [FC.cobalt, Color(h: "7AB8FF")],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.12)],
                                         startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 3)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: Step 1 — Who Are You

    private var stepWhoAreYou: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Кто ты?")
                    .font(.system(.largeTitle, design: .default, weight: .bold))
                    .foregroundStyle(FC.ink)
                Text("Finery подстроится под твою работу")
                    .font(.system(.body))
                    .foregroundStyle(FC.muted)
            }

            VStack(spacing: 10) {
                ForEach(UserType.allCases, id: \.self) { type in
                    userTypeCard(type)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    private func userTypeCard(_ type: UserType) -> some View {
        let selected = selectedUserType == type
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { selectedUserType = type }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selected ? FC.cobalt : Color.white.opacity(0.1))
                        .frame(width: 42, height: 42)
                        .shadow(color: selected ? FC.cobaltGlow : .clear, radius: 10)
                    Image(systemName: userTypeIcon(type))
                        .fontWeight(.light)
                        .foregroundStyle(selected ? .white : FC.muted)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(FC.ink)
                    Text(userTypeDescription(type))
                        .font(.system(.caption))
                        .foregroundStyle(FC.muted)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .imageScale(.small)
                    .foregroundStyle(FC.cobalt)
                    .opacity(selected ? 1 : 0)
                    .scaleEffect(selected ? 1 : 0.5)
                    .frame(width: 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassCardSmall()
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? FC.cobalt.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
    }

    // MARK: Step 2 — Tax Mode

    private var stepTaxMode: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Как платишь налоги?")
                    .font(.system(.largeTitle, design: .default, weight: .bold))
                    .foregroundStyle(FC.ink)
                Text("Это влияет на расчёт налоговой нагрузки")
                    .font(.system(.body))
                    .foregroundStyle(FC.muted)
            }

            VStack(spacing: 10) {
                ForEach(TaxMode.allCases, id: \.self) { mode in
                    taxModeCard(mode)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    private func taxModeCard(_ mode: TaxMode) -> some View {
        let selected = selectedTaxMode == mode
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { selectedTaxMode = mode }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selected ? FC.cobalt : Color.white.opacity(0.1))
                        .frame(width: 42, height: 42)
                        .shadow(color: selected ? FC.cobaltGlow : .clear, radius: 10)
                    Text("%")
                        .font(.system(.headline, weight: .light))
                        .foregroundStyle(selected ? .white : FC.muted)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(FC.ink)
                    Text(mode.shortDescription)
                        .font(.system(.caption))
                        .foregroundStyle(FC.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .imageScale(.small)
                    .foregroundStyle(FC.cobalt)
                    .opacity(selected ? 1 : 0)
                    .scaleEffect(selected ? 1 : 0.5)
                    .frame(width: 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassCardSmall()
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? FC.cobalt.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
    }

    // MARK: Step 3 — Name

    private var stepName: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Как тебя зовут?")
                    .font(.system(.largeTitle, design: .default, weight: .bold))
                    .foregroundStyle(FC.ink)
                Text("Для персонализации приложения")
                    .font(.system(.body))
                    .foregroundStyle(FC.muted)
            }

            TextField("Имя", text: $name)
                .font(.system(.title2, design: .default, weight: .regular))
                .foregroundStyle(FC.ink)
                .focused($nameFocused)
                .tint(FC.cobalt)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .glassCardSmall()

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    // MARK: Bottom Controls

    private var bottomControls: some View {
        HStack {
            if step > 0 {
                Button("Назад") {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { step -= 1 }
                }
                .font(.system(.body, design: .default, weight: .regular))
                .foregroundStyle(FC.muted)
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if step < totalSteps - 1 {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { step += 1 }
                } else {
                    complete()
                }
            } label: {
                Text(step == totalSteps - 1 ? "Начать" : "Далее")
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 15)
                    .background(
                        Capsule()
                            .fill(canProceed ? FC.cobalt : Color.white.opacity(0.15))
                            .shadow(color: canProceed ? FC.cobaltGlow : .clear, radius: 14, x: 0, y: 6)
                    )
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Helpers

    private var canProceed: Bool {
        switch step {
        case 0: true
        case 1: true
        case 2: !name.trimmingCharacters(in: .whitespaces).isEmpty
        default: false
        }
    }

    private func complete() {
        let user = User(
            name: name.trimmingCharacters(in: .whitespaces),
            taxMode: selectedTaxMode,
            userType: selectedUserType
        )
        onComplete(user)
    }

    private func userTypeIcon(_ type: UserType) -> String {
        switch type {
        case .blogger:      "play.rectangle"
        case .freelancer:   "briefcase"
        case .selfEmployed: "person"
        case .other:        "ellipsis.circle"
        }
    }

    private func userTypeDescription(_ type: UserType) -> String {
        switch type {
        case .blogger:      "YouTube, Twitch, Boosty, DonationAlerts"
        case .freelancer:   "Дизайн, разработка, копирайтинг"
        case .selfEmployed: "Репетитор, мастер, консультант"
        case .other:        "Другой вид деятельности"
        }
    }
}

#Preview {
    OnboardingView { _ in }
}
