import Foundation

struct Client: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var email: String?
    var phone: String?
    var totalPaid: Decimal
    var lastPayment: Date?
    var status: ClientStatus
    var notes: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        phone: String? = nil,
        totalPaid: Decimal = 0,
        lastPayment: Date? = nil,
        status: ClientStatus = .active,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.totalPaid = totalPaid
        self.lastPayment = lastPayment
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum ClientStatus: String, Codable, CaseIterable, Sendable {
    case active    = "active"
    case debt      = "debt"
    case completed = "completed"

    var displayName: String {
        switch self {
        case .active:    "Активный"
        case .debt:      "Должник"
        case .completed: "Завершён"
        }
    }
}
