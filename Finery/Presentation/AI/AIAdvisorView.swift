import SwiftUI

struct AIAdvisorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service = AIService.shared
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    private let quickQuestions = [
        "Как снизить налог?",
        "Анализ расходов",
        "Когда платить?",
        "Советы по доходу"
    ]

    var body: some View {
        ZStack {
            Color(h: "F5EFE0").ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                Divider().opacity(0.4)
                messageList
                Divider().opacity(0.3)
                inputPanel
            }
        }
    }

    // MARK: - Navigation bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(FC.ink)
                    .frame(width: 36, height: 36)
                    .background(FC.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text("Финансовый советник")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                HStack(spacing: 5) {
                    Circle().fill(Color(h: "1A7A4A")).frame(width: 6, height: 6)
                    Text("Claude AI").font(.system(.caption2, design: .rounded)).foregroundStyle(FC.muted)
                }
            }

            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(h: "F5EFE0"))
    }

    // MARK: - Messages list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if service.messages.isEmpty { emptyState }

                    ForEach(service.messages) { msg in
                        messageBubble(msg).id(msg.id)
                    }

                    if service.isLoading {
                        typingBubble.id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: service.messages.count) { _, _ in scroll(proxy) }
            .onChange(of: service.isLoading)      { _, _ in scroll(proxy) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            advisorAvatar(size: 56)
            Text("Задайте вопрос о финансах")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(FC.ink)
            Text("Знаю ваши доходы, расходы и налоговый режим —\nдам конкретный совет")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(FC.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 48)
    }

    private func advisorAvatar(size: CGFloat) -> some View {
        ZStack {
            Circle().fill(FC.cobalt).frame(width: size, height: size)
            Text("F")
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private func messageBubble(_ msg: AIMessage) -> some View {
        if msg.role == "user" {
            HStack(alignment: .bottom, spacing: 8) {
                Spacer(minLength: 48)
                Text(msg.content)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 18).fill(FC.cobalt))
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        } else {
            HStack(alignment: .top, spacing: 10) {
                advisorAvatar(size: 28)
                TypewriterText(text: msg.content, speed: 0.018)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(FC.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .transition(.opacity.combined(with: .move(edge: .leading)))
        }
    }

    private var typingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            advisorAvatar(size: 28)
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(FC.muted.opacity(0.5))
                        .frame(width: 7, height: 7)
                        .scaleEffect(service.isLoading ? 1 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                            value: service.isLoading
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
            Spacer(minLength: 48)
        }
    }

    // MARK: - Input panel

    private var inputPanel: some View {
        VStack(spacing: 0) {
            // Quick chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickQuestions, id: \.self) { q in
                        Button(q) { tap(q) }
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(FC.cobalt)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(FC.cobalt.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(FC.cobalt.opacity(0.25), lineWidth: 1))
                            .disabled(service.isLoading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            // Text input
            HStack(spacing: 10) {
                TextField("Напишите вопрос...", text: $inputText, axis: .vertical)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(1...4)
                    .foregroundStyle(FC.ink)
                    .tint(FC.cobalt)
                    .focused($inputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(FC.border, lineWidth: 0.5))

                Button(action: sendTapped) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(FC.cobalt.opacity(canSend ? 1 : 0.35)))
                }
                .disabled(!canSend)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 32)
        }
        .background(Color(h: "F5EFE0"))
    }

    // MARK: - Actions

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !service.isLoading
    }

    private func tap(_ text: String) {
        guard !service.isLoading else { return }
        Task { await service.sendMessage(text) }
    }

    private func sendTapped() {
        let t = inputText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !service.isLoading else { return }
        inputText = ""
        inputFocused = false
        Task { await service.sendMessage(t) }
    }

    private func scroll(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if service.isLoading { proxy.scrollTo("typing", anchor: .bottom) }
            else if let last = service.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
        }
    }
}

#Preview {
    AIAdvisorView()
}

// MARK: - Typewriter Text (Задача 5)

struct TypewriterText: View {
    let text: String
    var speed: Double = 0.018

    @State private var displayed = ""
    @State private var isDone = false

    var body: some View {
        Text(displayed.isEmpty ? " " : displayed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear { animate() }
    }

    @MainActor
    private func animate() {
        // Already played — show instantly without replay
        if isDone {
            displayed = text
            return
        }
        displayed = ""
        Task { @MainActor in
            for char in text {
                displayed.append(char)
                try? await Task.sleep(nanoseconds: UInt64(speed * 1_000_000_000))
            }
            isDone = true
        }
    }
}
