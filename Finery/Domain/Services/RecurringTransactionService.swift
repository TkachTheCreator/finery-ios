import Foundation
import Observation

@Observable
@MainActor
final class RecurringTransactionService {
    static let shared = RecurringTransactionService()
    private init() { load() }

    private let storeKey = "finery_recurring_transactions"
    private(set) var items: [RecurringTransaction] = []

    // MARK: - CRUD

    func add(_ item: RecurringTransaction) {
        items.append(item)
        persist()
        scheduleNotification(for: item)
    }

    func delete(_ item: RecurringTransaction) {
        items.removeAll { $0.id == item.id }
        persist()
        cancelNotification(id: item.id)
    }

    func toggle(_ item: RecurringTransaction) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isActive.toggle()
        persist()
    }

    // MARK: - Processing

    // Call on foreground / app launch (after authentication)
    func processIfNeeded(repository: any TransactionRepository) async {
        guard APIClient.shared.isAuthenticated else { return }

        for i in items.indices where items[i].isDueToday() {
            let rec = items[i]
            let tx = Transaction(
                amount: rec.amount,
                direction: rec.direction,
                description: rec.description,
                date: Date(),
                source: .manual,
                incomeCategory:  rec.incomeCategory,
                expenseCategory: rec.expenseCategory,
                clientType: rec.direction == .income ? .individual : nil,
                clientId: nil,
                notes: nil
            )
            do {
                let synced = try await APIClient.shared.createTransaction(tx)
                try? await repository.save(synced)
                SharedDataService.shared.appendTransaction(synced)
                items[i].lastFiredDate = Date()
                persist()

                let n = NSDecimalNumber(decimal: rec.amount).intValue
                NotificationService.shared.fireImmediate(
                    title: "Повторяющийся платёж",
                    body: "\(rec.direction == .income ? "Доход" : "Расход") \(n) ₽ — \(rec.description)"
                )
            } catch {
                // Non-critical: will retry next app launch
            }
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([RecurringTransaction].self, from: data)
        else { return }
        items = decoded
    }

    private func persist() {
        UserDefaults.standard.set(try? JSONEncoder().encode(items), forKey: storeKey)
    }

    // MARK: - Notifications

    private func scheduleNotification(for item: RecurringTransaction) {
        guard item.isActive else { return }
        // Re-uses NotificationService for scheduling
        // Notification fires at 9:00 on the due day
        NotificationService.shared.scheduleRecurring(
            id: "finery.recurring.\(item.id.uuidString)",
            title: "Повторяющийся платёж",
            body: "\(item.direction == .income ? "Доход" : "Расход") \(NSDecimalNumber(decimal: item.amount).intValue) ₽ — \(item.description)",
            period: item.period,
            dayOfWeek: item.dayOfWeek,
            dayOfMonth: item.dayOfMonth
        )
    }

    private func cancelNotification(id: UUID) {
        NotificationService.shared.cancel(identifier: "finery.recurring.\(id.uuidString)")
    }
}
