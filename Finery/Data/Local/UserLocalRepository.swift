import Foundation
import SwiftData

@MainActor
final class UserLocalRepository: UserRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchUser() throws -> User? {
        try modelContext.fetch(FetchDescriptor<UserEntity>()).first?.toDomain()
    }

    func saveUser(_ user: User) throws {
        modelContext.insert(UserEntity.from(user))
        try modelContext.save()
    }

    func updateUser(_ user: User) throws {
        let id = user.id
        let predicate = #Predicate<UserEntity> { $0.id == id }
        if let entity = try modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
            entity.name                   = user.name
            entity.taxModeRaw             = user.taxMode.rawValue
            entity.userTypeRaw            = user.userType.rawValue
            entity.notificationsEnabled   = user.notificationsEnabled
            entity.taxReminderDaysBefore  = user.taxReminderDaysBefore
        } else {
            modelContext.insert(UserEntity.from(user))
        }
        try modelContext.save()
    }
}
