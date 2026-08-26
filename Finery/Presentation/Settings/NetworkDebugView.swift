import SwiftUI

struct NetworkDebugView: View {
    @State private var isRunning = false
    @State private var lines: [TimingLine] = []
    @State private var timestamp = ""

    struct TimingLine: Identifiable {
        let id = UUID()
        let label: String
        let detail: String
        let isError: Bool
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ДИАГНОСТИКА СЕТИ")
                        .fLabel()
                        .padding(.top, 8)

                    Text("URLSession.shared — изолировано от APIClient")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(FC.muted)

                    Button {
                        Task { await runTiming() }
                    } label: {
                        HStack(spacing: 8) {
                            if isRunning { ProgressView().tint(.white).scaleEffect(0.85) }
                            Text(isRunning ? "Тестируем…" : "Запустить тест")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isRunning ? FC.muted : FC.cobalt)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isRunning)

                    if !lines.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(lines.enumerated()), id: \.element.id) { i, line in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(line.label)
                                        .font(.system(.caption2, design: .monospaced, weight: .semibold))
                                        .foregroundStyle(line.isError ? FC.danger : FC.cobalt)
                                    Text(line.detail)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(line.isError ? FC.danger : FC.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                if i < lines.count - 1 {
                                    Rectangle().fill(FC.border).frame(height: 0.5).padding(.leading, 14)
                                }
                            }
                        }
                        .background(FC.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FC.border, lineWidth: 0.5))
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Debug")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func runTiming() async {
        isRunning = true
        lines = []

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss.SSS"
        timestamp = fmt.string(from: Date())

        // baseURL info
        add("baseURL", APIClient.baseURLString, false)
        add("isAuthenticated", "\(APIClient.shared.isAuthenticated)", false)
        add("lastUpdated", SharedDataService.shared.lastUpdated.map { fmt.string(from: $0) } ?? "nil", false)

        // ── TIMING using URLSession.shared directly ──
        let targetURL = "https://api.finery.pro/health"

        let t0 = Date()
        log("t0", "START", elapsed: 0)
        add("t0: START", "\(fmt.string(from: t0))", false)

        let url = URL(string: targetURL)!
        let t1 = Date()
        let d1 = t1.timeIntervalSince(t0)
        log("t1", "URL created", elapsed: d1)
        add("t1: URL created", "+\(ms(d1))ms", false)

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "GET"
        let t2 = Date()
        let d2 = t2.timeIntervalSince(t0)
        log("t2", "URLRequest created", elapsed: d2)
        add("t2: URLRequest created", "+\(ms(d2))ms", false)

        // Hop off MainActor before the await so we can see if main thread is blocked
        let result: (String, Bool) = await Task.detached(priority: .userInitiated) {
            let t2b = Date()
            print("[TIMING] t2b (detached task started): +\(Int(t2b.timeIntervalSince(t0)*1000))ms")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let t3 = Date()
                let d3 = t3.timeIntervalSince(t0)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                let body = String(data: data, encoding: .utf8) ?? "(empty)"
                print("[TIMING] t3 (response): +\(Int(d3*1000))ms  HTTP \(code)  body: \(body)")
                return ("t3: HTTP \(code) — \(body) | +\(Int(d3*1000))ms total", false)
            } catch {
                let t3 = Date()
                let d3 = t3.timeIntervalSince(t0)
                print("[TIMING] t3 (ERROR): +\(Int(d3*1000))ms  \(error)")
                if let ue = error as? URLError {
                    print("[TIMING] URLError code: \(ue.code.rawValue)  desc: \(ue.localizedDescription)")
                }
                return ("t3: ERROR +\(Int(d3*1000))ms — \(error.localizedDescription)", true)
            }
        }.value

        let (resultText, isError) = result
        add(isError ? "t3: ОШИБКА" : "t3: УСПЕХ", resultText, isError)

        isRunning = false
    }

    private func add(_ label: String, _ detail: String, _ isError: Bool) {
        lines.append(TimingLine(label: label, detail: detail, isError: isError))
    }

    private func log(_ tag: String, _ msg: String, elapsed: TimeInterval) {
        print("[TIMING] \(tag): \(msg)  elapsed=+\(ms(elapsed))ms")
    }

    private func ms(_ t: TimeInterval) -> Int { Int(t * 1000) }
}

#Preview {
    NavigationStack { NetworkDebugView() }
}
