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
    var userSelectedCategory = false
    var isSaving      = false
    var didSave       = false
    var errorMessage: String?

    let voice = VoiceInputManager()

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
        return a > 0
    }

    var activeCategory: String {
        direction == .income ? incomeCategory.displayName : expenseCategory.displayName
    }

    // MARK: Direction change (reset category selection)

    func setDirection(_ dir: TransactionDirection) {
        guard dir != direction else { return }
        direction = dir
        userSelectedCategory = false
        incomeCategory  = .other
        expenseCategory = .other
    }

    // MARK: Category selection (marks as user-chosen, blocks auto-classifier)

    func selectIncomeCategory(_ cat: IncomeCategory) {
        incomeCategory = cat
        userSelectedCategory = true
    }

    func selectExpenseCategory(_ cat: ExpenseCategory) {
        expenseCategory = cat
        userSelectedCategory = true
    }

    // MARK: Auto-classify from description (skips if user already chose)

    func onDescriptionChanged() {
        guard !description.isEmpty, !userSelectedCategory else { return }
        let result = classifier.execute(description: description, direction: direction)
        if let cat = result.income  { incomeCategory  = cat }
        if let cat = result.expense { expenseCategory = cat }
    }

    func applyVoiceResult() {
        let text = voice.recognizedText
        guard !text.isEmpty else { return }
        if description.isEmpty { description = text }
        if let amount = voice.parsedAmount, amountText.isEmpty {
            let n = NSDecimalNumber(decimal: amount)
            amountText = n.decimalValue == Decimal(n.intValue) ? "\(n.intValue)" : n.stringValue
        }
        onDescriptionChanged()
    }

    // MARK: Save

    func save() async {
        guard let amount, canSave else { return }
        isSaving = true
        defer { isSaving = false }

        let trimmedDesc: String = {
            let d = description.trimmingCharacters(in: .whitespaces)
            if !d.isEmpty { return d }
            return direction == .income ? incomeCategory.displayName : expenseCategory.displayName
        }()
        let transaction = Transaction(
            amount: amount,
            direction: direction,
            description: trimmedDesc,
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
