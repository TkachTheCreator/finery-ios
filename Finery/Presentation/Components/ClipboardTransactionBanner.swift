import SwiftUI

struct ClipboardTransactionBanner: View {
    let result: BankSMSResult
    let onAdd: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.direction == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(result.direction == .income ? FC.success : FC.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.bank)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.muted)
                Text("\(result.direction == .income ? "+" : "−")\(result.amount.rub())")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(FC.ink)
                Text(result.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(FC.muted)
                    .lineLimit(1)
            }

            Spacer()

            VStack(spacing: 6) {
                Button("Добавить", action: onAdd)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(FC.cobalt)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Скрыть", action: onDismiss)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(FC.muted)
            }
        }
        .padding(14)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FC.border, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
