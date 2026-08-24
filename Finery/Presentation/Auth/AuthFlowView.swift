import SwiftUI

// MARK: - AuthFlowView

struct AuthFlowView: View {
    let isRegistering: Bool
    @State var viewModel: AuthViewModel
    var onSuccess: () -> Void
    var onBack: (() -> Void)? = nil
    @State private var step = 0
    @State private var forward = true
    @State private var localError: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showForgotPassword = false

    // register: 0=name  1=email  2=password  3=confirmPassword  4=userType
    // login:    0=email 1=password
    private var totalSteps: Int { isRegistering ? 5 : 2 }
    private var progress: Double { Double(step + 1) / Double(totalSteps) }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar.padding(.top, 8)

                ZStack {
                    currentStep
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                            removal:   .move(edge: forward ? .leading  : .trailing).combined(with: .opacity)
                        ))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.82), value: step)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onTapGesture { dismissKeyboard() }
        .onAppear {
            viewModel.mode = isRegistering ? .register : .login
            viewModel.errorMessage = nil
            localError = nil
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 14) {
            Button(action: handleBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(FC.ink)
                    .frame(width: 40, height: 40)
                    .background(FC.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(FC.muted.opacity(0.18)).frame(height: 4)
                    Capsule()
                        .fill(FC.cobalt)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: step)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: Step routing

    @ViewBuilder
    private var currentStep: some View {
        if isRegistering {
            switch step {
            case 0: nameStep
            case 1: emailStep
            case 2: passwordStep
            case 3: confirmPasswordStep
            case 4: userTypeStep
            default: EmptyView()
            }
        } else {
            switch step {
            case 0: emailStep
            case 1: passwordStep
            default: EmptyView()
            }
        }
    }

    // MARK: Individual steps

    private var nameStep: some View {
        StepLayout(
            question: "Как вас зовут?",
            subtitle: "Мы персонализируем приложение под вас",
            isValid: isStepValid,
            isLoading: false,
            error: localError,
            onContinue: handleContinue
        ) {
            AuthInputField(
                placeholder: "Имя",
                text: $viewModel.name,
                onChange: { localError = nil }
            )
        }
    }

    private var emailStep: some View {
        StepLayout(
            question: "Ваш email?",
            subtitle: "Для входа и восстановления доступа",
            isValid: isStepValid,
            isLoading: false,
            error: localError,
            onContinue: handleContinue
        ) {
            AuthInputField(
                placeholder: "Email",
                text: $viewModel.email,
                keyboard: .emailAddress,
                onChange: { localError = nil }
            )
        }
    }

    private var passwordStep: some View {
        StepLayout(
            question: isRegistering ? "Придумайте пароль" : "Введите пароль",
            subtitle: isRegistering ? "Минимум 8 символов" : "Пароль от вашего аккаунта",
            isValid: isStepValid,
            isLoading: viewModel.isLoading,
            error: localError,
            hint: viewModel.isSlowNetwork ? "Сервер просыпается, подождите немного…" : nil,
            continueLabel: isRegistering ? "Продолжить" : "Войти",
            onContinue: handleContinue
        ) {
            AuthPasswordField(
                text: $viewModel.password,
                showPassword: $showPassword,
                onChange: { localError = nil }
            )
            if !isRegistering {
                Button("Забыли пароль?") {
                    showForgotPassword = true
                }
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(FC.cobalt)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 4)
            }
        }
    }

    private var confirmPasswordStep: some View {
        let mismatch = !viewModel.confirmPassword.isEmpty
            && viewModel.confirmPassword != viewModel.password
        return StepLayout(
            question: "Повторите пароль",
            subtitle: "Введите пароль ещё раз",
            isValid: isStepValid,
            isLoading: false,
            error: mismatch ? "Пароли не совпадают" : nil,
            onContinue: handleContinue
        ) {
            AuthPasswordField(
                text: $viewModel.confirmPassword,
                showPassword: $showConfirmPassword,
                onChange: { }
            )
        }
    }

    private var userTypeStep: some View {
        StepLayout(
            question: "Кем вы являетесь?",
            subtitle: "Настроим налоги и отчёты под вас",
            isValid: true,
            isLoading: viewModel.isLoading,
            error: localError,
            hint: viewModel.isSlowNetwork ? "Сервер просыпается, подождите немного…" : nil,
            continueLabel: "Зарегистрироваться",
            onContinue: handleContinue
        ) {
            VStack(spacing: 12) {
                ForEach(AuthUserTypeOption.all) { opt in
                    AuthUserTypeCard(option: opt, isSelected: viewModel.userType == opt.userType) {
                        HapticManager.impact(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.userType = opt.userType
                            viewModel.taxMode  = opt.taxMode
                        }
                    }
                }
            }
        }
    }

    // MARK: Validation

    private var isStepValid: Bool {
        if isRegistering {
            switch step {
            case 0: return viewModel.name.trimmingCharacters(in: .whitespaces).count >= 1
            case 1: return viewModel.email.contains("@") && viewModel.email.contains(".")
            case 2: return viewModel.password.count >= 8
            case 3: return !viewModel.confirmPassword.isEmpty
                        && viewModel.confirmPassword == viewModel.password
            case 4: return true
            default: return false
            }
        } else {
            switch step {
            case 0: return viewModel.email.contains("@") && viewModel.email.contains(".")
            case 1: return !viewModel.password.isEmpty
            default: return false
            }
        }
    }

    // MARK: Actions

    private func handleContinue() {
        guard isStepValid, !viewModel.isLoading else { return }
        HapticManager.impact(.light)
        localError = nil
        dismissKeyboard()

        if step < totalSteps - 1 {
            forward = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { step += 1 }
        } else {
            Task {
                let ok = await viewModel.submit()
                if ok {
                    onSuccess()
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        localError = viewModel.errorMessage
                    }
                }
            }
        }
    }

    private func handleBack() {
        HapticManager.light()
        localError = nil
        if step > 0 {
            forward = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { step -= 1 }
        } else {
            onBack?()
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
    }
}

// MARK: - StepLayout

private struct StepLayout<Content: View>: View {
    let question: String
    let subtitle: String
    let isValid: Bool
    let isLoading: Bool
    let error: String?
    var hint: String? = nil
    var continueLabel: String = "Продолжить"
    let onContinue: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(question)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(FC.ink)

                    Text(subtitle)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(FC.muted)
                }

                VStack(alignment: .leading, spacing: 8) {
                    content()

                    if let err = error {
                        Text(err)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color(h: "C0392B"))
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeOut(duration: 0.2), value: error)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            if let hint {
                Text(hint)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(FC.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .transition(.opacity)
                    .animation(.easeIn(duration: 0.3), value: hint)
            }

            Spacer()

            Button(action: onContinue) {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(continueLabel)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(FC.cobalt.opacity(isValid ? 1 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!isValid || isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - AuthInputField

struct AuthInputField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var onChange: () -> Void = {}

    @FocusState private var focused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
            .font(.system(.body, design: .rounded))
            .foregroundStyle(FC.ink)
            .tint(FC.cobalt)
            .focused($focused)
            .padding(16)
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(focused ? FC.cobalt.opacity(0.5) : FC.cobalt.opacity(0.2), lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.15), value: focused)
            .onChange(of: text) { _, _ in onChange() }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true }
            }
    }
}

// MARK: - AuthPasswordField

private struct AuthPasswordField: View {
    @Binding var text: String
    @Binding var showPassword: Bool
    var onChange: () -> Void = {}

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if showPassword {
                    TextField("Пароль", text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField("Пароль", text: $text)
                }
            }
            .font(.system(.body, design: .rounded))
            .foregroundStyle(FC.ink)
            .tint(FC.cobalt)
            .focused($focused)

            Button {
                showPassword.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(FC.muted)
                    .font(.system(size: 17))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(focused ? FC.cobalt.opacity(0.5) : FC.cobalt.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.15), value: focused)
        .onChange(of: text) { _, _ in onChange() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true }
        }
    }
}

// MARK: - UserType cards

private struct AuthUserTypeOption: Identifiable {
    let id: UserType
    let title: String
    let subtitle: String
    let icon: String
    let userType: UserType
    let taxMode: TaxMode

    static let all: [AuthUserTypeOption] = [
        .init(id: .selfEmployed,
              title: "Самозанятый",
              subtitle: "НПД, до 2.4 млн в год",
              icon: "person.badge.shield.checkmark.fill",
              userType: .selfEmployed,
              taxMode: .npd),
        .init(id: .blogger,
              title: "Блогер / Стример",
              subtitle: "НПД, донаты, Boosty, реклама",
              icon: "play.rectangle.fill",
              userType: .blogger,
              taxMode: .npd),
        .init(id: .freelancer,
              title: "ИП / Фрилансер",
              subtitle: "УСН 6%, патент и другие режимы",
              icon: "briefcase.fill",
              userType: .freelancer,
              taxMode: .usn6),
        .init(id: .other,
              title: "Для себя",
              subtitle: "Личный бюджет без налогов",
              icon: "house.fill",
              userType: .other,
              taxMode: .npd),
    ]
}

private struct AuthUserTypeCard: View {
    let option: AuthUserTypeOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? FC.cobalt : FC.surface)
                        .frame(width: 48, height: 48)
                    Image(systemName: option.icon)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(isSelected ? .white : FC.muted)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(FC.ink)
                    Text(option.subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(FC.muted)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? FC.cobalt : FC.border, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(FC.cobalt)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? FC.cobalt.opacity(0.06) : FC.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? FC.cobalt.opacity(0.35) : FC.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview("Register") {
    AuthFlowView(
        isRegistering: true,
        viewModel: AuthViewModel(userRepository: MockUserRepository()),
        onSuccess: {}
    )
}

#Preview("Login") {
    AuthFlowView(
        isRegistering: false,
        viewModel: AuthViewModel(userRepository: MockUserRepository()),
        onSuccess: {}
    )
}
