import Foundation

struct Invoice: Identifiable, Codable, Sendable {
    let id: UUID
    var number: String
    var date: Date
    var clientId: UUID?
    var clientName: String
    var items: [InvoiceItem]
    var includeVat: Bool
    var executorName: String
    var total: Decimal
    let createdAt: Date

    init(
        id: UUID = UUID(),
        number: String,
        date: Date = Date(),
        clientId: UUID? = nil,
        clientName: String = "",
        items: [InvoiceItem] = [],
        includeVat: Bool = false,
        executorName: String = "",
        total: Decimal = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.number = number
        self.date = date
        self.clientId = clientId
        self.clientName = clientName
        self.items = items
        self.includeVat = includeVat
        self.executorName = executorName
        self.total = total
        self.createdAt = createdAt
    }

    var computedTotal: Decimal {
        let base = items.reduce(0) { $0 + $1.amount }
        return includeVat ? base * Decimal(1.2) : base
    }
}

struct InvoiceItem: Codable, Sendable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var amount: Decimal

    private enum CodingKeys: String, CodingKey {
        case name, amount
    }
}
