import Foundation
import Observation

@Observable
@MainActor
final class AddTransactionViewModel {

    // Form state
    var amountText   = ""
    var direction    = TransactionDirection.income
    var description  = ""
    var date         = Date()
    var incomeCategory  = IncomeCategory.other
    var expenseCategory = ExpenseCategory.other
    var clientType   = ClientType.individual
    var source       = TransactionSource.manual
    var notes        = ""

    // UI state
    var isSaving      = false
    var didSave       = false
    var errorMessage: String?

    private let transactionRepository: any TransactionRepository
    private let classifier = ClassifyTransactionUseCase()

    init(transactionRepository: any TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    // MARK: Computed

    var amount: Decimal? {
        let normalized = amountText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Decimal(string: normalized)
    }

    var canSave: Bool {
        guard let a = amount else { return false }
        return a > 0 && !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var activeCategory: String {
        direction == .income ? incomeCategory.displayName : expenseCategory.displayName
    }

    // MARK: Actions

    func onDescriptionChanged() {
        guard !description.isEmpty else { return }
        let result = classifier.execute(description: description, direction: direction)
        if let cat = result.income  { incomeCategory  = cat }
        if let cat = result.expense { expenseCategory = cat }
    }

    func save() async {
        guard let amount, canSave else { return }
        isSaving = true
        defer { isSaving = false }

        let transaction = Transaction(
            amount: amount,
            direction: direction,
            description: description.trimmingCharacters(in: .whitespaces),
            date: date,
            source: source,
            incomeCategory:  direction == .income  ? incomeCategory  : nil,
            expenseCategory: direction == .expense ? expenseCategory : nil,
            clientType:      direction == .income  ? clientType      : nil,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        )

        do {
            if APIClient.shared.isAuthenticated {
                let synced = try await APIClient.shared.createTransaction(transaction)
                // Persist locally so TransactionsView and Analytics see it immediately
                try? await transactionRepository.save(synced)
            } else {
                try await transactionRepository.save(transaction)
            }
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension AddTransactionViewModel {
    static func preview() -> AddTransactionViewModel {
        AddTransactionViewModel(transactionRepository: MockTransactionRepository())
    }
}
