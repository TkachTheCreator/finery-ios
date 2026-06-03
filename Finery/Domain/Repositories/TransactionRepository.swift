import Foundation

protocol TransactionRepository: Sendable {
    func fetchAll() async throws -> [Transaction]
    func fetch(from startDate: Date, to endDate: Date) async throws -> [Transaction]
    func save(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
    func delete(id: UUID) async throws
    func fetchYearlyIncome(year: Int) async throws -> Decimal
}
