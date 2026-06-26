import SwiftUI

struct ChatView: View {
    let income:  Decimal
    let expense: Decimal
    let tax:     Decimal
    let taxMode: String

    @Environment(\.dismiss) private var dismiss
    @State private var messages: [AIService.ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false

    private let quickQuestions = [
        "Как снизить налог?",
        "Анализ расходов",
        "Когда платить НПД?",
        "Советы по доходу"
    ]

    private var systemPrompt: String {
        """
        Ты финансовый советник приложения Finery для самозанятых и фрилансеров России.
        Данные пользователя за текущий месяц:
        — Доход: \(income.rub())
        — Расходы: \(expense.rub())
        — Налог: \(tax.rub())
        — Налоговый режим: \(taxMode)
        Давай конкретные советы по экономии налогов, управлению доходами и финансовому планированию.
        Отвечай кратко, по делу, на русском языке. Используй конкретные цифры из профиля.
        """
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                messagesList
                inputArea
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
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
                HStack(spacing: 4) {
                    Circle().fill(FC.success).frame(width: 6, height: 6)
                    Text("Claude AI")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(FC.muted)
                }
            }

            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FC.surface)
        .overlay(Rectangle().fill(FC.border).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Messages

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    if messages.isEmpty { emptyState }

                    ForEach(messages) { msg in
                        bubble(msg).id(msg.id)
                    }

                    if isLoading {
                        typingIndicator.id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _, _ in scroll(proxy) }
            .onChange(of: isLoading)      { _, _ in scroll(proxy) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(FC.cobalt)
            Text("Задайте вопрос о финансах")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FC.muted)
            Text("Я знаю ваши доходы и расходы\nи дам конкретный совет")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(FC.muted.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 48)
    }

    private func bubble(_ msg: AIService.ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            if msg.role == "user" { Spacer(minLength: 56) }

            Text(msg.content)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(msg.role == "user" ? .white : FC.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(msg.role == "user" ? FC.cobalt : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(msg.role == "user" ? Color.clear : FC.border.opacity(0.4), lineWidth: 0.5)
                )

            if msg.role == "assistant" { Spacer(minLength: 56) }
        }
        .transition(.opacity.combined(with: .move(edge: msg.role == "user" ? .trailing : .leading)))
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(FC.muted.opacity(0.5))
                        .frame(width: 7, height: 7)
                        .scaleEffect(isLoading ? 1 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                            value: isLoading
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
            Spacer(minLength: 56)
        }
    }

    // MARK: - Input

    private var inputArea: some View {
        VStack(spacing: 0) {
            Rectangle().fill(FC.border).frame(height: 0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickQuestions, id: \.self) { q in
                        Button(q) { send(q) }
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(FC.cobalt)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(FC.cobalt.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(FC.cobalt.opacity(0.25), lineWidth: 1))
                            .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            HStack(spacing: 10) {
                TextField("Напишите вопрос...", text: $inputText, axis: .vertical)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(1...4)
                    .foregroundStyle(FC.ink)
                    .tint(FC.cobalt)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(FC.border, lineWidth: 0.5))

                Button(action: { send(inputText) }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle().fill(FC.cobalt.opacity(canSend ? 1 : 0.35))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 32)
        }
        .background(FC.background)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    // MARK: - Actions

    private func send(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !isLoading else { return }
        inputText = ""
        let userMsg = AIService.ChatMessage(role: "user", content: t)
        withAnimation(.easeOut(duration: 0.2)) { messages.append(userMsg) }
        isLoading = true

        Task {
            do {
                let reply = try await AIService.shared.send(messages: messages, systemPrompt: systemPrompt)
                withAnimation(.easeOut(duration: 0.2)) {
                    messages.append(AIService.ChatMessage(role: "assistant", content: reply))
                }
            } catch {
                withAnimation {
                    messages.append(AIService.ChatMessage(
                        role: "assistant",
                        content: "Ошибка: \(error.localizedDescription)"
                    ))
                }
            }
            isLoading = false
        }
    }

    private func scroll(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if isLoading { proxy.scrollTo("typing", anchor: .bottom) }
            else if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
        }
    }
}

#Preview {
    ChatView(income: 200000, expense: 30000, tax: 12000, taxMode: "НПД")
}
