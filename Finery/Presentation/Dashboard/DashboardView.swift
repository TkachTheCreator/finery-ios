import SwiftUI
import Shimmer
import Pow

struct DashboardView: View {
    @State var viewModel: DashboardViewModel
    @State private var appeared       = false
    @State private var progressShown  = false
    @State private var showAdd        = false

    init(viewModel: DashboardViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FC.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    headerSection
                    cardStack
                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, 20)
            }

            addButton
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(
                viewModel: viewModel.makeAddTransactionViewModel(),
                onSave: { Task { await viewModel.load() } }
            )
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { appeared = true }
            withAnimation(.easeOut(duration: 1.2).delay(0.5)) { progressShown = true }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(FC.ink)
                Text(currentMonthFull)
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            Image(systemName: "gearshape")
                .fontWeight(.light)
                .imageScale(.medium)
                .foregroundStyle(FC.muted)
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
        .offset(y: appeared ? 0 : -12)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: appeared)
    }

    // MARK: - Card Stack

    @ViewBuilder
    private var cardStack: some View {
        incomeHeroCard
            .offset(y: appeared ? 0 : 24)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.05), value: appeared)

        taxCard
            .offset(y: appeared ? 0 : 24)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.15), value: appeared)

        topSourcesCard
            .offset(y: appeared ? 0 : 24)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.25), value: appeared)

        if !viewModel.insights.isEmpty {
            insightsCard
                .offset(y: appeared ? 0 : 24)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.35), value: appeared)
        }
    }

    // MARK: - Income Hero Card (Cobalt)

    private var incomeHeroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ДОХОД ЗА \(currentMonthShortUpper)")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.65))

            Group {
                if viewModel.isLoading {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.2))
                        .frame(width: 200, height: 52)
                } else {
                    Text(viewModel.pnl?.totalIncome.rub() ?? "0\u{202F}₽")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.fineryNumber, value: viewModel.pnl?.totalIncome)
                }
            }

            HStack(alignment: .top, spacing: 0) {
                miniMetric(label: "РАСХОДЫ", value: viewModel.pnl?.totalExpenses, align: .leading)
                Spacer()
                miniMetric(label: "НАЛОГ",   value: viewModel.pnl?.taxAmount,     align: .center)
                Spacer()
                miniMetric(label: "ЧИСТАЯ",  value: viewModel.pnl?.netProfit,     align: .trailing)
            }
        }
        .padding(20)
        .background(FC.cobalt)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func miniMetric(label: String, value: Decimal?, align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 4) {
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.6))
            if viewModel.isLoading {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.2))
                    .frame(width: 60, height: 12)
            } else {
                Text(value?.rub() ?? "—")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.9))
                    .contentTransition(.numericText())
                    .animation(.fineryNumber, value: value)
            }
        }
    }

    // MARK: - Tax Card

    private var taxCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ЛИМИТ НПД").fLabel()
                Spacer()
                Text(limitPercentText)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(trafficColor)
                    .contentTransition(.numericText())
                    .animation(.fineryNumber, value: limitPercentText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FC.border)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [FC.cobalt, trafficColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * (progressShown ? limitFraction : 0), height: 5)
                        .animation(.easeOut(duration: 1.2), value: progressShown)
                }
            }
            .frame(height: 5)

            if let status = viewModel.taxStatus {
                Text("Использовано \(status.yearlyIncome.rub()) из \(TaxStatus.npdYearLimit.rub())")
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(FC.muted)
            }

            deadlineRow
        }
        .padding(20)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
    }

    private var deadlineRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .fontWeight(.light)
                .imageScale(.medium)
                .foregroundStyle(FC.muted)
            Text("Следующий налог: ")
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(FC.muted)
            if let tax = viewModel.taxStatus?.taxDue {
                Text(tax.rub())
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(FC.ink)
            }
            Text("· до 28 \(nextMonthGenitive)")
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(FC.muted)
        }
        .padding(.top, 2)
    }

    // MARK: - Top Sources Card

    private var topSourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ТОП ИСТОЧНИКОВ").fLabel()

            if viewModel.isLoading {
                ForEach(0..<3, id: \.self) { _ in skeletonRow }
            } else if viewModel.topSources.isEmpty {
                HStack {
                    Image(systemName: "tray")
                        .fontWeight(.light)
                        .imageScale(.medium)
                        .foregroundStyle(FC.muted)
                    Text("Нет данных за этот месяц")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(FC.muted)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(Array(viewModel.topSources.enumerated()), id: \.element.category) { index, item in
                    sourceRow(rank: index + 1, category: item.category, amount: item.amount)
                    if index < viewModel.topSources.count - 1 {
                        Rectangle().fill(FC.border.opacity(0.5)).frame(height: 0.5)
                    }
                }
            }
        }
        .padding(20)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
    }

    @ViewBuilder
    private func sourceRow(rank: Int, category: IncomeCategory, amount: Decimal) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(FC.muted)
                .frame(width: 14, alignment: .center)
            Image(systemName: category.iconName)
                .fontWeight(.light)
                .imageScale(.medium)
                .foregroundStyle(FC.cobalt)
                .frame(width: 20)
            Text(category.displayName)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(FC.ink)
            Spacer()
            Text(amount.rub())
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(FC.success)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Insights Card

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ИНСАЙТЫ").fLabel()
            VStack(spacing: 6) {
                ForEach(viewModel.insights) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
        .padding(20)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
    }

    // MARK: - FAB

    private var addButton: some View {
        Button {
            HapticManager.impact(.medium)
            showAdd = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                    .imageScale(.medium)
                Text("Добавить")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(FC.cobalt)
                    .shadow(color: FC.cobaltGlow, radius: 12, x: 0, y: 4)
            )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Skeleton

    private var skeletonRow: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(FC.border)
                .frame(width: 130, height: 12)
                .skeleton(active: true)
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(FC.border)
                .frame(width: 60, height: 12)
                .skeleton(active: true)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Computed

    private var trafficColor: Color {
        switch viewModel.taxStatus?.trafficLight {
        case .green:  FC.success
        case .yellow: FC.amber
        case .red:    FC.danger
        case nil:     FC.muted
        }
    }

    private var limitFraction: CGFloat {
        guard let status = viewModel.taxStatus else { return 0 }
        return CGFloat(min(status.limitUsedPercent / 100, 1.0))
    }

    private var limitPercentText: String {
        guard let status = viewModel.taxStatus else { return "—" }
        return "\(Int(status.limitUsedPercent))%"
    }

    private var greeting: String {
        viewModel.userName.isEmpty ? "Привет" : "Привет, \(viewModel.userName)"
    }

    private var currentMonthFull: String { formatted(Date(), "LLLL yyyy") }
    private var currentMonthShortUpper: String { formatted(Date(), "LLLL").uppercased() }
    private var nextMonthGenitive: String {
        let next = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        return formatted(next, "LLLL")
    }

    private func formatted(_ date: Date, _ format: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = format
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt.string(from: date).capitalized
    }
}

#Preview {
    DashboardView(viewModel: .preview())
}
