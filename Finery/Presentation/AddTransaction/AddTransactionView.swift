import SwiftUI
import Pow
import Speech

struct AddTransactionView: View {
    @State var viewModel: AddTransactionViewModel
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFocused: Bool
    @State private var showOverlay: OverlayState = .none

    private enum OverlayState { case none, loading, success }

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
        .onChange(of: viewModel.isSaving) { _, saving in
            if saving { withAnimation { showOverlay = .loading } }
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved {
                onSave?()
                withAnimation { showOverlay = .success }
            }
        }
        .overlay {
            switch showOverlay {
            case .loading:
                FineryLoadingOverlay(message: "Сохраняем транзакцию...")
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .success:
                FinerySuccessOverlay(message: "Готово!") {
                    showOverlay = .none
                    dismiss()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .none:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: showOverlay == .none)
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
            withAnimation(.easeInOut(duration: 0.15)) { viewModel.setDirection(dir) }
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
                            Button(cat.displayName) {
                                viewModel.selectIncomeCategory(cat)
                            }
                        }
                    } else {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Button(cat.displayName) {
                                viewModel.selectExpenseCategory(cat)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.activeCategory)
                            .id(viewModel.activeCategory)
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

#Preview {
    AddTransactionView(viewModel: .preview())
}
