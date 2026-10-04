import SwiftUI

struct TipsListView: View {
    let insights: [Insight]
    var onShowAI: (() -> Void)?
    var accentTint: Color = .clear

    @State private var expandedId: UUID? = nil
    @State private var appeared = false

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            accentTint.opacity(0.08).ignoresSafeArea()

            if insights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(FC.success)
                    Text("Всё в порядке")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(FC.ink)
                    Text("Нет текущих советов")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(FC.inkSecondary)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                            disclosureCard(insight, index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Советы")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            appeared = false
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
        }
    }

    @ViewBuilder
    private func disclosureCard(_ insight: Insight, index: Int) -> some View {
        let isExpanded = expandedId == insight.id
        let accent: Color = {
            switch insight.severity {
            case .critical: return FC.danger
            case .warning:  return FC.warning
            case .info:     return FC.cobalt
            }
        }()

        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedId = isExpanded ? nil : insight.id
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(accent)
                        .frame(width: 7, height: 7)
                        .padding(.top, 5)
                    Text(insight.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(FC.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(FC.border)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text(insight.body)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(FC.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)

                    if onShowAI != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles").font(.system(size: 13))
                            Text("Уточнить у ИИ")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(FC.cobalt)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard onShowAI != nil else { return }
                    HapticManager.light()
                    onShowAI?()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(accent.opacity(isExpanded ? 0.07 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.15), lineWidth: 1)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.06), value: appeared)
    }
}
