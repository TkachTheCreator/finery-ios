import SwiftUI

// MARK: - Tab Definition

enum FineryTab: Int, CaseIterable {
    case dashboard = 0
    case transactions
    case analytics
    case tax
    case settings

    var icon: String {
        switch self {
        case .dashboard:    "house"
        case .transactions: "list.bullet"
        case .analytics:    "chart.bar"
        case .tax:          "percent"
        case .settings:     "gearshape"
        }
    }

    var label: String {
        switch self {
        case .dashboard:    "Главная"
        case .transactions: "Операции"
        case .analytics:    "Аналитика"
        case .tax:          "Налоги"
        case .settings:     "Настройки"
        }
    }
}

// MARK: - Floating Tab Bar

struct FloatingTabBar: View {
    @Binding var selection: FineryTab
    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FineryTab.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.25),
                                    .white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.45), radius: 24, y: 8)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func tabButton(_ tab: FineryTab) -> some View {
        let selected = selection == tab

        Button {
            guard selection != tab else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(FC.cobalt.opacity(0.18))
                            .frame(width: 44, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(FC.cobalt.opacity(0.35), lineWidth: 1)
                            )
                            .matchedGeometryEffect(id: "indicator", in: indicator)
                    }
                    Image(systemName: selected ? tab.icon + ".fill" : tab.icon)
                        .font(.system(size: 16, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? FC.cobalt : FC.muted)
                        .scaleEffect(selected ? 1.1 : 1.0)
                        .frame(width: 44, height: 30)
                }

                Text(tab.label)
                    .font(.system(size: 9.5, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? FC.cobalt : FC.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
}

// MARK: - Press style (no default highlight)

private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        FC.background.ignoresSafeArea()
        VStack {
            Spacer()
            FloatingTabBar(selection: .constant(.dashboard))
                .padding(.bottom, 20)
        }
    }
}
