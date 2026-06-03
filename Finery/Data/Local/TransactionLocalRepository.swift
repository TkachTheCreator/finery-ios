import Foundation
import SwiftData

@MainActor
final class TransactionLocalRepository: TransactionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(from startDate: Date, to endDate: Date) throws -> [Transaction] {
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.date >= startDate && entity.date <= endDate
        }
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func save(_ transaction: Transaction) throws {
        modelContext.insert(TransactionEntity.from(transaction))
        try modelContext.save()
    }

    func update(_ transaction: Transaction) throws {
        let id = transaction.id
        let predicate = #Predicate<TransactionEntity> { $0.id == id }
        guard let entity = try modelContext.fetch(FetchDescriptor(predicate: predicate)).first else { return }

        entity.amount                 = transaction.amount
        entity.directionRaw           = transaction.direction.rawValue
        entity.transactionDescription = transaction.description
        entity.date                   = transaction.date
        entity.sourceRaw              = transaction.source.rawValue
        entity.incomeCategoryRaw      = transaction.incomeCategory?.rawValue
        entity.expenseCategoryRaw     = transaction.expenseCategory?.rawValue
        entity.clientTypeRaw          = transaction.clientType?.rawValue
        entity.notes                  = transaction.notes

        try modelContext.save()
    }

    func delete(id: UUID) throws {
        let predicate = #Predicate<TransactionEntity> { $0.id == id }
        guard let entity = try modelContext.fetch(FetchDescriptor(predicate: predicate)).first else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }

    func fetchYearlyIncome(year: Int) throws -> Decimal {
        let start = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
        let end   = Calendar.current.date(from: DateComponents(year: year, month: 12, day: 31))!
        return try fetch(from: start, to: end)
            .filter { $0.direction == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
}
