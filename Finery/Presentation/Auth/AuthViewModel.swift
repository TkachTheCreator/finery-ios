import Foundation
import Observation

@Observable
@MainActor
final class AuthViewModel {

    enum Mode { case login, register }

    // MARK: State

    var mode: Mode = .login
    var email    = ""
    var password = ""
    var name     = ""
    var taxMode  = TaxMode.npd
    var userType = UserType.freelancer

    var isLoading    = false
    var errorMessage: String?

    // MARK: Dependencies

    private let userRepository: any UserRepository

    init(userRepository: any UserRepository) {
        self.userRepository = userRepository
    }

    // MARK: Validation

    var canSubmit: Bool {
        let trimmedEmail    = email.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)
        let trimmedName     = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else { return false }
        if mode == .register { return !trimmedName.isEmpty }
        return true
    }

    // MARK: Actions

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            switch mode {
            case .login:
                let (_, user) = try await APIClient.shared.login(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                try? await userRepository.saveUser(user)

            case .register:
                let (_, user) = try await APIClient.shared.register(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password,
                    name: name.trimmingCharacters(in: .whitespaces),
                    taxMode: taxMode,
                    userType: userType
                )
                try? await userRepository.saveUser(user)
            }
            return true
        } catch NetworkError.wrongPassword {
            errorMessage = "Неверный пароль"
            return false
        } catch NetworkError.userNotFound {
            errorMessage = "Аккаунт с таким email не найден"
            return false
        } catch NetworkError.emailTaken {
            errorMessage = "Этот email уже зарегистрирован"
            return false
        } catch {
            errorMessage = "Проверь подключение к интернету"
            return false
        }
    }

    func toggleMode() {
        mode = mode == .login ? .register : .login
        errorMessage = nil
    }
}
