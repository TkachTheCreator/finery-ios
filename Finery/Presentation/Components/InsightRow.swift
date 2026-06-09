import SwiftUI

struct InsightRow: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 3)
                .shadow(color: accentColor.opacity(0.6), radius: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.system(.subheadline, design: .default, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text(insight.body)
                    .font(.system(.caption, design: .default, weight: .regular))
                    .foregroundStyle(FC.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: iconName)
                .imageScale(.small)
                .fontWeight(.light)
                .foregroundStyle(accentColor)
                .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(accentColor.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var accentColor: Color {
        switch insight.severity {
        case .info:     FC.cobalt
        case .warning:  FC.amber
        case .critical: FC.danger
        }
    }

    private var iconName: String {
        switch insight.type {
        case .taxDeadline:       "calendar.badge.exclamationmark"
        case .limitWarning:      "exclamationmark.triangle"
        case .incomeGrowth:      "arrow.up.right"
        case .lowMargin:         "arrow.down.right"
        case .concentrationRisk: "chart.pie"
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        InsightRow(insight: Insight(type: .taxDeadline, title: "Дедлайн налога",
                                   body: "Налог 8 700 ₽ нужно оплатить через 5 дней.", severity: .warning))
        InsightRow(insight: Insight(type: .limitWarning, title: "Лимит НПД",
                                   body: "Использовано 85% лимита. Пора открывать ИП.", severity: .critical))
        InsightRow(insight: Insight(type: .incomeGrowth, title: "Рост дохода",
                                   body: "Доход в этом месяце на 57% выше прошлого.", severity: .info))
    }
    .padding()
    .background(FC.backgroundGradient)
}
