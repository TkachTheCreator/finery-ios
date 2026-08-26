import SwiftUI

struct NetworkDebugView: View {
    @State private var isRunning = false
    @State private var result: DebugResult?
    @State private var timestamp = ""

    struct DebugResult {
        let baseURL: String
        let healthOK: Bool
        let healthDetail: String
        let healthMs: Int
        let tokenPreview: String
        let lastUpdated: String
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ДИАГНОСТИКА СЕТИ")
                        .fLabel()
                        .padding(.top, 8)

                    if isRunning {
                        HStack(spacing: 10) {
                            ProgressView().tint(FC.cobalt)
                            Text("Проверяем…")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(FC.muted)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FC.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let r = result {
                        resultCard(r)
                    }

                    Button {
                        Task { await runDiag() }
                    } label: {
                        Text(isRunning ? "Проверяем…" : "Запустить диагностику")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isRunning ? FC.muted : FC.cobalt)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isRunning)
                }
                .padding(20)
            }
        }
        .navigationTitle("Debug")
        .navigationBarTitleDisplayMode(.inline)
        .task { await runDiag() }
    }

    private func resultCard(_ r: DebugResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            row(label: "Base URL", value: r.baseURL, mono: true)
            divider
            row(label: "Health", value: "\(r.healthOK ? "✓" : "✗") \(r.healthDetail) (\(r.healthMs) ms)",
                color: r.healthOK ? FC.success : FC.danger)
            divider
            row(label: "JWT Token", value: r.tokenPreview, mono: true)
            divider
            row(label: "Last load", value: r.lastUpdated)
            divider
            row(label: "Tested at", value: timestamp)
        }
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FC.border, lineWidth: 0.5))
    }

    @ViewBuilder
    private func row(label: String, value: String, mono: Bool = false, color: Color = FC.ink) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fLabel()
            Text(value)
                .font(mono ? .system(.caption, design: .monospaced) : .system(.caption, design: .rounded))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var divider: some View {
        Rectangle().fill(FC.border).frame(height: 0.5).padding(.leading, 14)
    }

    @MainActor
    private func runDiag() async {
        isRunning = true
        defer { isRunning = false }

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        timestamp = fmt.string(from: Date())

        // Health check (raw, full error)
        let health = await APIClient.shared.healthCheckRaw()

        // JWT token preview
        let tokenPreview: String
        if let token = UserDefaults.standard.string(forKey: "_dbg_token") {
            tokenPreview = String(token.prefix(20)) + "…"
        } else {
            // Try reading from keychain indirectly via isAuthenticated
            tokenPreview = APIClient.shared.isAuthenticated ? "(токен есть, <скрыт>)" : "НЕТ ТОКЕНА"
        }

        // Last updated
        let lastUpdate: String
        if let t = SharedDataService.shared.lastUpdated {
            let f2 = DateFormatter()
            f2.dateFormat = "dd.MM HH:mm:ss"
            lastUpdate = f2.string(from: t)
        } else {
            lastUpdate = "никогда"
        }

        result = DebugResult(
            baseURL: APIClient.baseURLString,
            healthOK: health.ok,
            healthDetail: health.detail,
            healthMs: health.ms,
            tokenPreview: tokenPreview,
            lastUpdated: lastUpdate
        )
    }
}

#Preview {
    NavigationStack { NetworkDebugView() }
}
