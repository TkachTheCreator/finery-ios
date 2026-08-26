import Foundation
import Observation

enum TimePeriod: String, CaseIterable, Sendable {
    case week    = "Неделя"
    case month   = "Месяц"
    case quarter = "Квартал"
    case year    = "Год"

    var interval: DateInterval {
        let now = Date()
        let cal = Calendar.current
        let start: Date
        switch self {
        case .week:
            start = cal.date(byAdding: .weekOfYear, value: -1, to: now)!
        case .month:
            start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        case .quarter:
            start = cal.date(byAdding: .month, value: -3, to: now)!
        case .year:
            start = cal.date(from: DateComponents(year: cal.component(.year, from: now), month: 1, day: 1))!
        }
        return DateInterval(start: start, end: now)
    }
}

@Observable
@MainActor
final class TransactionsViewModel {

    var allTransactions: [Transaction] = []
    var period: TimePeriod = .month {
        didSet { filterFromService() }
    }
    var directionFilter: TransactionDirection? = nil {
        didSet { filterFromService() }
    }
    var isLoading = false
    var isOffline = false
    var errorMessage: String?

    private let transactionRepository: any TransactionRepository

    init(transactionRepository: any TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    // MARK: Computed

    var filtered: [Transaction] { allTransactions }

    var grouped: [(date: Date, items: [Transaction])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: allTransactions) { cal.startOfDay(for: $0.date) }
        return dict
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
    }

    var totalIncome: Decimal {
        allTransactions.filter { $0.direction == .income  }.reduce(0) { $0 + $1.amount }
    }
    var totalExpenses: Decimal {
        allTransactions.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
    }

    /// For the month period with no direction filter, prefer server-side PnL totals
    /// so the summary always matches the dashboard, even if transaction list is paginated.
    var summaryIncome: Decimal {
        if period == .month, directionFilter == nil,
           let pnl = SharedDataService.shared.pnl { return pnl.totalIncome }
        return totalIncome
    }
    var summaryExpenses: Decimal {
        if period == .month, directionFilter == nil,
           let pnl = SharedDataService.shared.pnl { return pnl.totalExpenses }
        return totalExpenses
    }

    // MARK: Actions

    func load() async {
        isLoading = true
        isOffline = false
        defer { isLoading = false }

        await SharedDataService.shared.loadAll()

        isOffline = SharedDataService.shared.isOffline
        filterFromService()
    }

    func delete(id: UUID) async {
        allTransactions.removeAll { $0.id == id }
        await SharedDataService.shared.deleteTransaction(id: id)
    }

    func makeAddTransactionViewModel() -> AddTransactionViewModel {
        AddTransactionViewModel(transactionRepository: transactionRepository)
    }

    func makeEditTransactionViewModel(_ tx: Transaction) -> AddTransactionViewModel {
        AddTransactionViewModel(transactionRepository: transactionRepository, existing: tx)
    }

    // MARK: Private

    private func filterFromService() {
        let interval = period.interval
        var txns = SharedDataService.shared.transactions
            .filter { $0.date >= interval.start && $0.date <= interval.end }
        if let dir = directionFilter {
            txns = txns.filter { $0.direction == dir }
        }
        allTransactions = txns
    }
}

extension TransactionsViewModel {
    static func preview() -> TransactionsViewModel {
        TransactionsViewModel(transactionRepository: MockTransactionRepository())
    }
}
