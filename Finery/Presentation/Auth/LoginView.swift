import SwiftUI

struct LoginView: View {
    @State var viewModel: AuthViewModel
    var onSuccess: () -> Void

    @FocusState private var focus: Field?

    private enum Field: Hashable { case name, email, password }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            Circle()
                .fill(FC.cobalt.opacity(0.10))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: 60, y: -160)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo
                    VStack(spacing: 8) {
                        Text("F")
                            .font(.system(size: 48, weight: .black))
                            .foregroundStyle(FC.cobalt)
                        Text("Finery")
                            .font(.system(.title2, design: .default, weight: .semibold))
                            .foregroundStyle(FC.ink)
                        Text("Финансовый менеджер")
                            .font(.system(.caption))
                            .foregroundStyle(FC.muted)
                    }
                    .padding(.top, 64)
                    .padding(.bottom, 40)

                    // Card
                    VStack(spacing: 16) {
                        modeToggle

                        if viewModel.mode == .register {
                            inputField("Имя", text: $viewModel.name, field: .name)
                        }
                        inputField("Email", text: $viewModel.email, field: .email, keyboard: .emailAddress)
                        inputField("Пароль", text: $viewModel.password, field: .password, secure: true)

                        if viewModel.mode == .register {
                            taxModeRow
                            userTypeRow
                        }

                        if let msg = viewModel.errorMessage {
                            Text(msg)
                                .font(.system(.caption))
                                .foregroundStyle(FC.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        submitButton
                    }
                    .padding(20)
                    .background(FC.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(FC.border, lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)

                    Color.clear.frame(height: 60)
                }
            }
        }
        .onTapGesture { focus = nil }
    }

    // MARK: Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach([AuthViewModel.Mode.login, .register], id: \.self) { m in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.mode = m
                        viewModel.errorMessage = nil
                    }
                } label: {
                    Text(m == .login ? "Войти" : "Регистрация")
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .foregroundStyle(viewModel.mode == m ? FC.cobalt : FC.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.mode == m
                            ? FC.cobalt.opacity(0.10)
                            : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3), value: viewModel.mode)
            }
        }
        .padding(4)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Input Field

    @ViewBuilder
    private func inputField(
        _ placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboard: UIKeyboardType = .default,
        secure: Bool = false
    ) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .autocapitalization(keyboard == .emailAddress ? .none : .words)
                    .autocorrectionDisabled(keyboard == .emailAddress)
            }
        }
        .font(.system(.body))
        .foregroundStyle(FC.ink)
        .tint(FC.cobalt)
        .focused($focus, equals: field)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(focus == field ? FC.cobalt.opacity(0.6) : FC.border, lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.15), value: focus)
    }

    // MARK: TaxMode Row

    private var taxModeRow: some View {
        HStack {
            Text("Налог")
                .font(.system(.subheadline))
                .foregroundStyle(FC.muted)
            Spacer()
            Picker("", selection: $viewModel.taxMode) {
                ForEach(TaxMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .tint(FC.cobalt)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: UserType Row

    private var userTypeRow: some View {
        HStack {
            Text("Тип")
                .font(.system(.subheadline))
                .foregroundStyle(FC.muted)
            Spacer()
            Picker("", selection: $viewModel.userType) {
                ForEach(UserType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)
            .tint(FC.cobalt)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Submit Button

    private var submitButton: some View {
        Button {
            focus = nil
            Task {
                if await viewModel.submit() {
                    onSuccess()
                }
            }
        } label: {
            ZStack {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(viewModel.mode == .login ? "Войти" : "Создать аккаунт")
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                Capsule()
                    .fill(viewModel.canSubmit ? FC.cobalt : Color.white.opacity(0.15))
                    .shadow(color: viewModel.canSubmit ? FC.cobaltGlow : .clear, radius: 14, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit || viewModel.isLoading)
        .animation(.easeOut(duration: 0.2), value: viewModel.canSubmit)
        .padding(.top, 4)
    }
}

#Preview {
    LoginView(
        viewModel: AuthViewModel(userRepository: MockUserRepository()),
        onSuccess: {}
    )
}
