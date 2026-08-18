import UserNotifications
import Foundation

final class NotificationService: @unchecked Sendable {
    static let shared = NotificationService()
    private init() {}

    @discardableResult
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleTaxReminder(deadline: Date, amount: Decimal, daysBefore: Int = 5) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["finery.tax.reminder"])

        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: deadline),
              reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Налог через \(daysBefore) дней"
        content.body  = "Отложи \(amount.rub()) до 28 числа"
        content.sound = .default
        content.badge = 1

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: "finery.tax.reminder", content: content, trigger: trigger))
    }

    func scheduleNpdLimitWarning(usedPercent: Double) {
        guard usedPercent >= 80 else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["finery.npd.warning"])

        let content = UNMutableNotificationContent()
        content.title = "Лимит НПД \(Int(usedPercent))%"
        content.body  = "Пора открывать ИП. Осталось мало до лимита 2 400 000 ₽"
        content.sound = .default

        // Fire next morning at 9:00 so it doesn't interrupt the current session
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        comps.hour = 9; comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: "finery.npd.warning", content: content, trigger: trigger))
    }
}
