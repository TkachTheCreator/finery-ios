import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var resultMessage: String?
    @State private var isError = false

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(FC.ink)
                            .frame(width: 40, height: 40)
                            .background(FC.surface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Восстановление пароля")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(FC.ink)
                        Text("Введите email — пришлём ссылку для сброса")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(FC.muted)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        AuthInputField(
                            placeholder: "Email",
                            text: $email,
                            keyboard: .emailAddress,
                            onChange: { resultMessage = nil }
                        )

                        if let msg = resultMessage {
                            Text(msg)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(isError ? Color(h: "C0392B") : Color(h: "1A7A4A"))
                                .padding(.horizontal, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: resultMessage)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer()

                Button(action: sendReset) {
                    ZStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Отправить ссылку")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(FC.cobalt.opacity(canSend ? 1 : 0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!canSend || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
            )
        }
    }

    private var canSend: Bool {
        email.contains("@") && email.contains(".")
    }

    private func sendReset() {
        guard canSend, !isLoading else { return }
        isLoading = true
        resultMessage = nil
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        Task {
            do {
                _ = try await APIClient.shared.forgotPassword(email: trimmed)
                isError = false
                resultMessage = "Письмо отправлено на \(trimmed)"
            } catch NetworkError.userNotFound {
                isError = true
                resultMessage = "Email не найден"
            } catch NetworkError.serverUnavailable {
                isError = true
                resultMessage = "Сервер недоступен, попробуйте позже"
            } catch {
                isError = true
                resultMessage = "Проверь подключение к интернету"
            }
            isLoading = false
        }
    }
}

#Preview {
    ForgotPasswordView()
}
