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
            // Persist locally first
            try await userRepository.updateUser(user)
            // Sync name, taxMode, userType to backend so tax calculations use the latest mode
            if APIClient.shared.isAuthenticated {
                let updated = try await APIClient.shared.updateProfile(
                    name: user.name,
                    taxMode: user.taxMode,
                    userType: user.userType
                )
                // Refresh local store with backend-confirmed values
                try? await userRepository.updateUser(updated)
                // Invalidate transaction store so next Dashboard load re-fetches with correct tax
                TransactionStore.shared.reset()
            }
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
