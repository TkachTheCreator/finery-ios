import Foundation
import Observation
import WidgetKit

/// Central data hub. All ViewModels read from here; one API round-trip
/// populates every screen simultaneously.
@Observable
@MainActor
final class SharedDataService {
    static let shared = SharedDataService()
    private init() {}

    // MARK: - State

    private(set) var transactions: [Transaction] = []
    private(set) var pnl:         PnL?
    private(set) var taxStatus:   TaxStatus?
    private(set) var currentUser: User?

    private(set) var isLoading          = false
    private(set) var isOffline          = false
    private(set) var lastUpdated: Date?
    private(set) var isLoggedOut        = false
    private(set) var sessionExpiredMessage: String?
    /// True while loadAll is running but data hasn't arrived yet (slow connection).
    private(set) var isSlowConnection   = false

    // MARK: - Computed shortcuts

    var totalIncome:  Decimal   { pnl?.totalIncome   ?? 0 }
    var totalExpense: Decimal   { pnl?.totalExpenses ?? 0 }
    var netProfit:    Decimal   { pnl?.netProfit      ?? 0 }
    var taxAmount:    Decimal   { pnl?.taxAmount      ?? 0 }
    var taxMode:      TaxMode   { currentUser?.taxMode  ?? .npd }
    var userType:     UserType  { currentUser?.userType ?? .freelancer }
    var userName:     String    { currentUser?.name ?? "" }

    private var isStale: Bool {
        guard let t = lastUpdated else { return true }
        return Date().timeIntervalSince(t) > 30
    }

    // MARK: - Cache keys

    private enum CacheKey {
        static let transactions = "cached_transactions"
        static let income       = "cached_income"
        static let expense      = "cached_expense"
        static let tax          = "cached_tax"
    }

    // MARK: - Load cached data (called at startup)

    func loadCached() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: CacheKey.transactions),
           let txs = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = txs
            TransactionStore.shared.syncFromService(txs)
        }
        let income  = Decimal(defaults.double(forKey: CacheKey.income))
        let expense = Decimal(defaults.double(forKey: CacheKey.expense))
        let tax     = Decimal(defaults.double(forKey: CacheKey.tax))
        if income > 0 || expense > 0 {
            let cal   = Calendar.current
            let start = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
            pnl = PnL(period: DateInterval(start: start, end: Date()),
                      totalIncome: income, totalExpenses: expense, taxAmount: tax)
        }
    }

    // MARK: - Persist to cache

    private func saveToCache() {
        let defaults = UserDefaults.standard
        defaults.set(try? JSONEncoder().encode(transactions), forKey: CacheKey.transactions)
        defaults.set(NSDecimalNumber(decimal: totalIncome ).doubleValue, forKey: CacheKey.income)
        defaults.set(NSDecimalNumber(decimal: totalExpense).doubleValue, forKey: CacheKey.expense)
        defaults.set(NSDecimalNumber(decimal: taxAmount   ).doubleValue, forKey: CacheKey.tax)
    }

    // MARK: - Load from network

    func loadAll(referenceDate: Date = Date()) async {
        guard APIClient.shared.isAuthenticated else { return }
        guard !isLoading, isStale else { return }
        isLoading = true
        isSlowConnection = false
        defer { isLoading = false; isSlowConnection = false }

        // After 4 s with no data, flag slow connection so the UI can update.
        let slowTimer = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled { isSlowConnection = true }
        }
        defer { slowTimer.cancel() }

        await processPendingTransactions()

        let cal = Calendar.current
        let year         = cal.component(.year, from: referenceDate)
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate))!
        let endOfMonth   = cal.date(byAdding: .second, value: -1,
                                    to: cal.date(byAdding: .month, value: 1, to: startOfMonth)!)!
        let fromTwoYears = cal.date(from: DateComponents(year: year - 1, month: 1, day: 1))!
        let resolvedMode = currentUser?.taxMode ?? .npd

        // All 4 requests run in parallel
        async let userTask = APIClient.shared.getCurrentUser()
        async let txTask   = APIClient.shared.getTransactions(from: fromTwoYears, perPage: 500)
        async let pnlTask  = APIClient.shared.getPnL(from: startOfMonth, to: endOfMonth)
        async let taxTask  = APIClient.shared.getTaxStatus(year: year, taxMode: resolvedMode)

        // Check user first to detect expired token vs network outage
        do {
            let u = try await userTask
            currentUser = u
        } catch NetworkError.unauthorized {
            _ = try? await txTask
            _ = try? await pnlTask
            _ = try? await taxTask
            handleSessionExpired()
            return
        } catch {
            // If the task was cancelled (user switched tabs), bail without touching state
            if Task.isCancelled { return }
        }

        let txResult  = try? await txTask
        let pnlResult = try? await pnlTask
        let taxResult = try? await taxTask

        // Don't corrupt state on cancellation
        guard !Task.isCancelled else { return }

        let networkFailed = txResult == nil && pnlResult == nil
        isOffline = networkFailed

        if let txs = txResult {
            transactions = txs
            TransactionStore.shared.syncFromService(txs)
        }
        if let p = pnlResult { pnl = p }
        if let t = taxResult { taxStatus = t }

        // Only mark as loaded when data actually arrived — failed/cancelled loads
        // leave lastUpdated nil so the next call retries immediately.
        if !networkFailed {
            lastUpdated = Date()
            saveToCache()
            saveToWidget()
        }
    }

    /// Force the next loadAll() to fetch fresh data regardless of the 30-second window.
    func invalidate() { lastUpdated = nil }

    // MARK: - Process transactions queued by Share Extension

    func processPendingTransactions() async {
        let defaults = UserDefaults(suiteName: "group.com.tkachev.finery")
        guard let pending = defaults?.array(forKey: "pending_transactions")
                as? [[String: Any]], !pending.isEmpty else { return }

        for item in pending {
            guard let amount    = item["amount"]      as? Double,
                  let dirRaw   = item["direction"]    as? String,
                  let desc     = item["description"]  as? String else { continue }

            let dir = TransactionDirection(rawValue: dirRaw) ?? .expense
            let tx  = Transaction(
                amount:      Decimal(amount),
                direction:   dir,
                description: desc,
                date:        Date()
            )
            try? await addTransaction(tx)
        }

        defaults?.removeObject(forKey: "pending_transactions")
    }

    // MARK: - Write to App Group for widget

    private func saveToWidget() {
        let defaults = UserDefaults(suiteName: "group.com.tkachev.finery")
        defaults?.set(NSDecimalNumber(decimal: totalIncome ).doubleValue, forKey: "widget_income")
        defaults?.set(NSDecimalNumber(decimal: totalExpense).doubleValue, forKey: "widget_expense")
        defaults?.set(NSDecimalNumber(decimal: taxAmount   ).doubleValue, forKey: "widget_tax")
        defaults?.set(taxMode.rawValue,                                   forKey: "widget_taxMode")

        struct WidgetTx: Codable {
            let amount: Double; let direction: String
            let description: String; let date: Date
        }
        let widgetTxs = transactions.prefix(3).map {
            WidgetTx(amount: NSDecimalNumber(decimal: $0.amount).doubleValue,
                     direction: $0.direction.rawValue,
                     description: $0.description,
                     date: $0.date)
        }
        if let data = try? JSONEncoder().encode(Array(widgetTxs)) {
            defaults?.set(data, forKey: "widget_transactions")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Mutations

    func addTransaction(_ tx: Transaction) async throws {
        let created = try await APIClient.shared.createTransaction(tx)
        transactions.insert(created, at: 0)
        TransactionStore.shared.append(created)
        lastUpdated = nil  // force refresh on next loadAll
        await loadAll()
    }

    func deleteTransaction(id: UUID) async {
        transactions.removeAll { $0.id == id }
        TransactionStore.shared.remove(id: id)
        try? await APIClient.shared.deleteTransaction(id: id)
    }

    func reset() {
        transactions = []
        pnl = nil
        taxStatus = nil
        currentUser = nil
        lastUpdated = nil
        isOffline = false
        TransactionStore.shared.reset()
    }

    func logout() {
        sessionExpiredMessage = nil
        APIClient.shared.logout()
        UserDefaults.standard.removeObject(forKey: "finery_welcome_seen")
        reset()
        isLoggedOut = true
    }

    /// Called whenever any authenticated API request returns 401.
    /// Clears the token, sets the expiry message, and triggers logout flow.
    func handleSessionExpired() {
        guard !isLoggedOut else { return }
        sessionExpiredMessage = "Сессия истекла, войдите снова"
        APIClient.shared.logout()   // clears Keychain token
        reset()
        isLoggedOut = true
    }
}
