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
    var period: TimePeriod = .month
    var directionFilter: TransactionDirection? = nil
    var isLoading = false
    var isOffline = false
    var errorMessage: String?

    private let transactionRepository: any TransactionRepository

    init(transactionRepository: any TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    // MARK: Computed

    var filtered: [Transaction] {
        allTransactions
            .filter { directionFilter == nil || $0.direction == directionFilter }
    }

    var grouped: [(date: Date, items: [Transaction])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        return dict
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
    }

    var totalIncome: Decimal {
        filtered.filter { $0.direction == .income  }.reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Decimal {
        filtered.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
    }

    // MARK: Actions

    func load() async {
        isLoading = true
        isOffline = false
        defer { isLoading = false }
        let interval = period.interval
        do {
            allTransactions = try await APIClient.shared.getTransactions(from: interval.start, to: interval.end)
        } catch NetworkError.noConnection, NetworkError.unauthorized {
            isOffline = true
            allTransactions = (try? await transactionRepository.fetch(from: interval.start, to: interval.end)) ?? []
        } catch {
            allTransactions = (try? await transactionRepository.fetch(from: interval.start, to: interval.end)) ?? []
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        allTransactions.removeAll { $0.id == id }
        do {
            try await APIClient.shared.deleteTransaction(id: id)
            try? await transactionRepository.delete(id: id)
        } catch {
            try? await transactionRepository.delete(id: id)
        }
    }

    func makeAddTransactionViewModel() -> AddTransactionViewModel {
        AddTransactionViewModel(transactionRepository: transactionRepository)
    }
}

extension TransactionsViewModel {
    static func preview() -> TransactionsViewModel {
        TransactionsViewModel(transactionRepository: MockTransactionRepository())
    }
}
