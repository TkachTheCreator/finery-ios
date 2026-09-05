import SwiftUI

// MARK: - Tab Definition

enum FineryTab: Int, CaseIterable {
    case dashboard = 0
    case transactions
    case analytics
    case clients
    case tax
    case settings

    var icon: String {
        switch self {
        case .dashboard:    "house"
        case .transactions: "list.bullet"
        case .analytics:    "chart.bar"
        case .clients:      "person.2"
        case .tax:          "percent"
        case .settings:     "gearshape"
        }
    }

    var label: String {
        switch self {
        case .dashboard:    "Главная"
        case .transactions: "Операции"
        case .analytics:    "Аналитика"
        case .clients:      "Клиенты"
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
            ForEach(FineryTab.allCases.filter { $0 != .settings }, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(FC.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(FC.border, lineWidth: 1)
                )
                .shadow(color: Color(h: "8B7D5A").opacity(0.18), radius: 20, y: 6)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func tabButton(_ tab: FineryTab) -> some View {
        let selected = selection == tab

        Button {
            withAnimation(.fineryMicro) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selected {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(FC.cobalt.opacity(0.12))
                            .frame(width: 44, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 11)
                                    .stroke(FC.cobalt.opacity(0.25), lineWidth: 1)
                            )
                            .matchedGeometryEffect(id: "indicator", in: indicator)
                    }
                    Image(systemName: selected ? tab.icon + ".fill" : tab.icon)
                        .font(.system(size: 15, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? FC.cobalt : FC.muted)
                        .scaleEffect(selected ? 1.08 : 1.0)
                        .animation(.fineryMicro, value: selected)
                        .frame(width: 44, height: 30)
                }

                Text(tab.label)
                    .font(.system(size: 9.5, weight: selected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(selected ? FC.cobalt : FC.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
}

// MARK: - Button press style

private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.fineryMicro, value: configuration.isPressed)
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
