import Foundation

struct User: Codable, Sendable {
    var id: UUID
    var name: String
    var taxMode: TaxMode
    var userType: UserType
    var notificationsEnabled: Bool
    var npdLimitNotificationEnabled: Bool
    var taxReminderDaysBefore: Int

    init(
        id: UUID = UUID(),
        name: String = "",
        taxMode: TaxMode = .npd,
        userType: UserType = .freelancer,
        notificationsEnabled: Bool = true,
        npdLimitNotificationEnabled: Bool = true,
        taxReminderDaysBefore: Int = 5
    ) {
        self.id = id
        self.name = name
        self.taxMode = taxMode
        self.userType = userType
        self.notificationsEnabled = notificationsEnabled
        self.npdLimitNotificationEnabled = npdLimitNotificationEnabled
        self.taxReminderDaysBefore = taxReminderDaysBefore
    }
}

enum UserType: String, Codable, CaseIterable, Sendable {
    case blogger      = "Блогер/Стример"
    case freelancer   = "Фрилансер"
    case selfEmployed = "Самозанятый"
    case other        = "Другое"

    var displayName: String { rawValue }
}
