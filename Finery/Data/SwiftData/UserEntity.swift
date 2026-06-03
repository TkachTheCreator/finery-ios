import Foundation
import SwiftData

@Model
final class UserEntity {
    var id: UUID
    var name: String
    var taxModeRaw: String
    var userTypeRaw: String
    var notificationsEnabled: Bool
    var taxReminderDaysBefore: Int

    init(
        id: UUID = UUID(),
        name: String,
        taxModeRaw: String,
        userTypeRaw: String,
        notificationsEnabled: Bool,
        taxReminderDaysBefore: Int
    ) {
        self.id = id
        self.name = name
        self.taxModeRaw = taxModeRaw
        self.userTypeRaw = userTypeRaw
        self.notificationsEnabled = notificationsEnabled
        self.taxReminderDaysBefore = taxReminderDaysBefore
    }
}

extension UserEntity {
    func toDomain() -> User {
        User(
            id: id,
            name: name,
            taxMode:  TaxMode(rawValue: taxModeRaw)   ?? .npd,
            userType: UserType(rawValue: userTypeRaw)  ?? .freelancer,
            notificationsEnabled: notificationsEnabled,
            taxReminderDaysBefore: taxReminderDaysBefore
        )
    }

    static func from(_ user: User) -> UserEntity {
        UserEntity(
            id: user.id,
            name: user.name,
            taxModeRaw:  user.taxMode.rawValue,
            userTypeRaw: user.userType.rawValue,
            notificationsEnabled: user.notificationsEnabled,
            taxReminderDaysBefore: user.taxReminderDaysBefore
        )
    }
}
