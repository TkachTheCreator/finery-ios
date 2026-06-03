import SwiftUI

struct OnboardingView: View {
    var onComplete: (User) -> Void

    @State private var step = 0
    @State private var selectedUserType = UserType.freelancer
    @State private var selectedTaxMode  = TaxMode.npd
    @State private var name = ""

    @FocusState private var nameFocused: Bool

    private let totalSteps = 3

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 20)

                TabView(selection: $step) {
                    stepWhoAreYou.tag(0)
                    stepTaxMode.tag(1)
                    stepName.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: step)

                bottomControls
                    .padding(.bottom, 48)
            }
        }
        .onChange(of: step) { _, newStep in
            if newStep == 2 { nameFocused = true }
        }
    }

    // MARK: Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Rectangle()
                    .fill(i <= step ? FC.cobalt : FC.border)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
        .padding(.horizontal, 20)
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
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }

    private func userTypeCard(_ type: UserType) -> some View {
        let selected = selectedUserType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedUserType = type }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Rectangle()
                        .fill(selected ? FC.cobalt : FC.surface)
                        .frame(width: 40, height: 40)
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
                Image(systemName: selected ? "checkmark" : "")
                    .fontWeight(.semibold)
                    .imageScale(.small)
                    .foregroundStyle(FC.cobalt)
                    .frame(width: 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(FC.background)
            .overlay(
                Rectangle()
                    .stroke(selected ? FC.cobalt : FC.border, lineWidth: selected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
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
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }

    private func taxModeCard(_ mode: TaxMode) -> some View {
        let selected = selectedTaxMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedTaxMode = mode }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Rectangle()
                        .fill(selected ? FC.cobalt : FC.surface)
                        .frame(width: 40, height: 40)
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
                Image(systemName: selected ? "checkmark" : "")
                    .fontWeight(.semibold)
                    .imageScale(.small)
                    .foregroundStyle(FC.cobalt)
                    .frame(width: 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(FC.background)
            .overlay(
                Rectangle()
                    .stroke(selected ? FC.cobalt : FC.border, lineWidth: selected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
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

            VStack(alignment: .leading, spacing: 0) {
                TextField("Имя", text: $name)
                    .font(.system(.title2, design: .default, weight: .regular))
                    .foregroundStyle(FC.ink)
                    .focused($nameFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(FC.background)
                    .overlay(Rectangle().stroke(FC.border, lineWidth: 0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }

    // MARK: Bottom Controls

    private var bottomControls: some View {
        HStack {
            if step > 0 {
                Button("Назад") {
                    withAnimation { step -= 1 }
                }
                .font(.system(.body, design: .default, weight: .regular))
                .foregroundStyle(FC.muted)
            }

            Spacer()

            Button {
                if step < totalSteps - 1 {
                    withAnimation { step += 1 }
                } else {
                    complete()
                }
            } label: {
                Text(step == totalSteps - 1 ? "Начать" : "Далее")
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(canProceed ? FC.cobalt : FC.border)
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, 20)
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
