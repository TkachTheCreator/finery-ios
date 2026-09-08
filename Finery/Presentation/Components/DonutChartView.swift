import SwiftUI
import Charts

struct DonutChartView: View {
    struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let value: Double
        let color: Color
    }

    let slices: [Slice]
    var size: CGFloat = 130
    var innerRatio: Double = 0.52
    var angularInset: Double = 1.5
    var cornerRadius: Double = 3.0

    // Any slice smaller than 5% of total is rendered as 5% so it stays visible
    private func displayValue(for slice: Slice) -> Double {
        let total = slices.reduce(0) { $0 + $1.value }
        guard total > 0 else { return slice.value }
        return max(slice.value, total * 0.05)
    }

    var body: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Сумма", displayValue(for: slice)),
                innerRadius: .ratio(innerRatio),
                angularInset: angularInset
            )
            .cornerRadius(cornerRadius)
            .foregroundStyle(slice.color)
        }
        .frame(width: size, height: size)
    }
}
