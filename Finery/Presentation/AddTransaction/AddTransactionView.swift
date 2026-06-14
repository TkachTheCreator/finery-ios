import SwiftUI
import Pow
import Speech

struct AddTransactionView: View {
    @State var viewModel: AddTransactionViewModel
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFocused: Bool
    @State private var showSuccess = false

    init(viewModel: AddTransactionViewModel, onSave: (() -> Void)? = nil) {
        _viewModel = State(wrappedValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    hairline
                    amountSection
                    hairline
                    directionToggle
                    hairline
                    formFields
                    Spacer(minLength: 40)
                    saveButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 36)
                }
            }
        }
        .onAppear { amountFocused = true }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved {
                onSave?()
                showSuccess = true
            }
        }
        .fullScreenCover(isPresented: $showSuccess) {
            FinerySuccessView {
                showSuccess = false
                dismiss()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button("Отмена") { dismiss() }
                .font(.system(.body, design: .default, weight: .regular))
                .foregroundStyle(FC.muted)
            Spacer()
            Text("Транзакция")
                .font(.system(.subheadline, design: .default, weight: .semibold))
                .foregroundStyle(FC.ink)
            Spacer()
            Button("Сохранить") { Task { await viewModel.save() } }
                .font(.system(.body, design: .default, weight: .semibold))
                .foregroundStyle(viewModel.canSave ? FC.cobalt : FC.border)
                .disabled(!viewModel.canSave)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: Amount

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("СУММА").fLabel()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: $viewModel.amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(FC.ink)
                    .focused($amountFocused)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("₽")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(FC.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: Direction Toggle

    private var directionToggle: some View {
        HStack(spacing: 0) {
            directionButton(.income,  label: "Доход",  color: FC.cobalt)
            Rectangle().fill(FC.border).frame(width: 0.5)
            directionButton(.expense, label: "Расход", color: FC.muted)
        }
        .frame(height: 48)
    }

    private func directionButton(_ dir: TransactionDirection, label: String, color: Color) -> some View {
        let selected = viewModel.direction == dir
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { viewModel.direction = dir }
        } label: {
            Text(label)
                .font(.system(.subheadline, design: .default, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? .white : FC.muted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(selected ? color : FC.surface)
        }
    }

    // MARK: Mic Button

    private var micButton: some View {
        let voice = viewModel.voice
        let isRecording: Bool
        if case .recording = voice.state { isRecording = true } else { isRecording = false }

        return Button {
            voice.toggle()
            if case .idle = voice.state {
                viewModel.applyVoiceResult()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isRecording ? FC.muted.opacity(0.18) : FC.cobalt.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(isRecording ? FC.muted.opacity(0.5) : FC.cobalt.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: isRecording ? "stop.circle" : "mic")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isRecording ? FC.muted : FC.cobalt)
            }
            .scaleEffect(isRecording ? 1.1 : 1.0)
            .animation(.spring(response: 0.3), value: isRecording)
        }
        .onChange(of: voice.recognizedText) { _, _ in
            if case .idle = voice.state { viewModel.applyVoiceResult() }
        }
    }

    // MARK: Form Fields

    private var formFields: some View {
        VStack(spacing: 0) {
            fieldRow(label: "ОПИСАНИЕ") {
                HStack(spacing: 10) {
                    TextField("За что оплата", text: $viewModel.description)
                        .font(.system(.body))
                        .foregroundStyle(FC.ink)
                        .onChange(of: viewModel.description) { _, _ in viewModel.onDescriptionChanged() }
                    micButton
                }
            }
            hairline

            fieldRow(label: "ДАТА") {
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(FC.cobalt)
            }
            hairline

            fieldRow(label: "КАТЕГОРИЯ") {
                Menu {
                    if viewModel.direction == .income {
                        ForEach(IncomeCategory.allCases, id: \.self) { cat in
                            Button(cat.displayName) { viewModel.incomeCategory = cat }
                        }
                    } else {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Button(cat.displayName) { viewModel.expenseCategory = cat }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.activeCategory)
                            .font(.system(.body))
                            .foregroundStyle(FC.ink)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(.caption2))
                            .foregroundStyle(FC.muted)
                    }
                }
            }
            hairline

            if viewModel.direction == .income {
                fieldRow(label: "ТИП КЛИЕНТА") {
                    Menu {
                        ForEach(ClientType.allCases, id: \.self) { type in
                            Button("\(type.displayName) — \(NSDecimalNumber(decimal: type.npdRate * 100).intValue)%") {
                                viewModel.clientType = type
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(viewModel.clientType.displayName) · \(NSDecimalNumber(decimal: viewModel.clientType.npdRate * 100).intValue)%")
                                .font(.system(.body))
                                .foregroundStyle(FC.ink)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(.caption2))
                                .foregroundStyle(FC.muted)
                        }
                    }
                }
                hairline
            }

            fieldRow(label: "ИСТОЧНИК") {
                Menu {
                    ForEach(TransactionSource.allCases, id: \.self) { src in
                        Button(src.displayName) { viewModel.source = src }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.source.displayName)
                            .font(.system(.body))
                            .foregroundStyle(FC.ink)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(.caption2))
                            .foregroundStyle(FC.muted)
                    }
                }
            }
            hairline

            fieldRow(label: "ЗАМЕТКИ") {
                TextField("Опционально", text: $viewModel.notes)
                    .font(.system(.body))
                    .foregroundStyle(FC.ink)
            }
        }
    }

    @ViewBuilder
    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label).fLabel().frame(width: 110, alignment: .leading)
            Spacer()
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(FC.background)
    }

    // MARK: Save Button

    private var saveButton: some View {
        Button {
            Task { await viewModel.save() }
        } label: {
            Group {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Сохранить")
                        .font(.system(.body, design: .default, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.canSave ? FC.cobalt : FC.border)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!viewModel.canSave || viewModel.isSaving)
    }

    private var hairline: some View {
        Rectangle().fill(FC.border).frame(height: 0.5)
    }
}

// MARK: - Branded Success Screen

struct FinerySuccessView: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var logoRotation: Double = -30
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(FC.cobalt)
                        .frame(width: 80, height: 80)
                    Text("F")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(Color(h: "C8FF00"))
                        .frame(width: 14, height: 14)
                        .offset(x: 4, y: 4)
                }
                .rotationEffect(.degrees(logoRotation))
                .scaleEffect(scale)
                .opacity(opacity)

                VStack(spacing: 8) {
                    Text("Сохранено")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(FC.ink)
                    Text("Транзакция добавлена")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(FC.muted)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                scale = 1.0
                opacity = 1.0
                logoRotation = 0
            }
            HapticManager.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.25)) {
                    opacity = 0
                    scale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    AddTransactionView(viewModel: .preview())
}
