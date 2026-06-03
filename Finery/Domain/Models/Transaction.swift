import Foundation

struct Transaction: Identifiable, Codable, Sendable {
    let id: UUID
    var amount: Decimal
    var direction: TransactionDirection
    var description: String
    var date: Date
    var source: TransactionSource
    var incomeCategory: IncomeCategory?
    var expenseCategory: ExpenseCategory?
    var clientType: ClientType?
    var notes: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Decimal,
        direction: TransactionDirection,
        description: String,
        date: Date = Date(),
        source: TransactionSource = .manual,
        incomeCategory: IncomeCategory? = nil,
        expenseCategory: ExpenseCategory? = nil,
        clientType: ClientType? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.direction = direction
        self.description = description
        self.date = date
        self.source = source
        self.incomeCategory = incomeCategory
        self.expenseCategory = expenseCategory
        self.clientType = clientType
        self.notes = notes
        self.createdAt = createdAt
    }
}
