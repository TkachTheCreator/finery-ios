import Foundation
import SwiftData

@Model
final class TransactionEntity {
    var id: UUID
    var amount: Decimal
    var directionRaw: String
    var transactionDescription: String
    var date: Date
    var sourceRaw: String
    var incomeCategoryRaw: String?
    var expenseCategoryRaw: String?
    var clientTypeRaw: String?
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Decimal,
        directionRaw: String,
        transactionDescription: String,
        date: Date,
        sourceRaw: String,
        incomeCategoryRaw: String? = nil,
        expenseCategoryRaw: String? = nil,
        clientTypeRaw: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.directionRaw = directionRaw
        self.transactionDescription = transactionDescription
        self.date = date
        self.sourceRaw = sourceRaw
        self.incomeCategoryRaw = incomeCategoryRaw
        self.expenseCategoryRaw = expenseCategoryRaw
        self.clientTypeRaw = clientTypeRaw
        self.notes = notes
        self.createdAt = createdAt
    }
}

extension TransactionEntity {
    func toDomain() -> Transaction {
        Transaction(
            id: id,
            amount: amount,
            direction: TransactionDirection(rawValue: directionRaw) ?? .income,
            description: transactionDescription,
            date: date,
            source: TransactionSource(rawValue: sourceRaw) ?? .manual,
            incomeCategory:  incomeCategoryRaw.flatMap  { IncomeCategory(rawValue: $0)  },
            expenseCategory: expenseCategoryRaw.flatMap { ExpenseCategory(rawValue: $0) },
            clientType:      clientTypeRaw.flatMap      { ClientType(rawValue: $0)      },
            notes: notes,
            createdAt: createdAt
        )
    }

    static func from(_ t: Transaction) -> TransactionEntity {
        TransactionEntity(
            id: t.id,
            amount: t.amount,
            directionRaw: t.direction.rawValue,
            transactionDescription: t.description,
            date: t.date,
            sourceRaw: t.source.rawValue,
            incomeCategoryRaw:  t.incomeCategory?.rawValue,
            expenseCategoryRaw: t.expenseCategory?.rawValue,
            clientTypeRaw:      t.clientType?.rawValue,
            notes: t.notes,
            createdAt: t.createdAt
        )
    }
}
