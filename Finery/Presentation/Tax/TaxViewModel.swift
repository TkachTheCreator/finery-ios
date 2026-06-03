import Foundation
import Observation

@Observable
@MainActor
final class TaxViewModel {

    var taxStatus: TaxStatus?
    var monthlyHistory: [MonthlyData] = []
    var isLoading = false

    private let calculateTax: CalculateTaxUseCase
    private let getMonthlyDynamics: GetMonthlyDynamicsUseCase

    init(calculateTax: CalculateTaxUseCase, getMonthlyDynamics: GetMonthlyDynamicsUseCase) {
        self.calculateTax = calculateTax
        self.getMonthlyDynamics = getMonthlyDynamics
    }

    func load(referenceDate: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let status  = calculateTax.execute(for: referenceDate)
            async let history = getMonthlyDynamics.execute(monthsBack: 12, referenceDate: referenceDate)
            let (s, h) = try await (status, history)
            taxStatus     = s
            monthlyHistory = h
        } catch {}
    }

    var totalTaxYear: Decimal {
        monthlyHistory.reduce(0) { $0 + $1.taxAmount }
    }

    var totalIncomeYear: Decimal {
        monthlyHistory.reduce(0) { $0 + $1.income }
    }
}

extension TaxViewModel {
    static func preview() -> TaxViewModel {
        let tx   = MockTransactionRepository()
        let usr  = MockUserRepository()
        let calc = TaxCalculatorService()
        let vm = TaxViewModel(
            calculateTax: CalculateTaxUseCase(transactionRepository: tx, userRepository: usr, taxCalculator: calc),
            getMonthlyDynamics: GetMonthlyDynamicsUseCase(transactionRepository: tx, userRepository: usr, taxCalculator: calc)
        )
        vm.taxStatus     = PreviewData.taxStatus
        vm.monthlyHistory = PreviewData.monthlyData
        return vm
    }
}
