import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {

    var user = User()
    var isSaving = false
    var savedFeedback = false
    var errorMessage: String?

    private let userRepository: any UserRepository

    init(userRepository: any UserRepository) {
        self.userRepository = userRepository
    }

    func load() async {
        if let u = try? await userRepository.fetchUser() {
            user = u
        }
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            errorMessage = nil
            try await userRepository.updateUser(user)
            savedFeedback = true
            try? await Task.sleep(for: .seconds(1.5))
            savedFeedback = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension SettingsViewModel {
    static func preview() -> SettingsViewModel {
        let vm = SettingsViewModel(userRepository: MockUserRepository())
        vm.user = PreviewData.user
        return vm
    }
}
