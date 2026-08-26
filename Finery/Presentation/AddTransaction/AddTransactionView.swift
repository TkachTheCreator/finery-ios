import SwiftUI
import Pow
import Speech

struct AddTransactionView: View {
    @State var viewModel: AddTransactionViewModel
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFocused: Bool
    @State private var showOverlay: OverlayState = .none
    @State private var showCategoryPicker = false
    @State private var showError = false
    @State private var showDeleteConfirm = false

    private enum OverlayState { case none, loading, success }

    init(viewModel: AddTransactionViewModel, onSave: (() -> Void)? = nil) {
        _viewModel = State(wrappedValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
                .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }

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
                    if viewModel.isEditing {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Text("Удалить транзакцию")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(FC.danger)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(FC.danger.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                    }
                    Spacer(minLength: 36)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear { amountFocused = true }
        .onDisappear { viewModel.voice.stop() }
        .confirmationDialog("Удалить транзакцию?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) { Task { await viewModel.deleteExisting() } }
            Button("Отмена", role: .cancel) {}
        }
        .onChange(of: viewModel.isSaving) { _, saving in
            if saving { withAnimation { showOverlay = .loading } }
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved {
                onSave?()
                withAnimation { showOverlay = .success }
            }
        }
        .onChange(of: viewModel.errorMessage) { _, msg in
            if msg != nil { showError = true }
        }
        .alert("Ошибка сохранения", isPresented: $showError) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(
                direction: viewModel.direction,
                onSelect: { viewModel.selectCategory($0) }
            )
        }
        .overlay {
            switch showOverlay {
            case .loading:
                FineryLoadingOverlay(message: "Сохраняем транзакцию...")
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .success:
                FinerySuccessOverlay(
                    message: viewModel.savedOffline ? "Сохранено локально" : "Готово!"
                ) {
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
            Text(viewModel.isEditing ? "Редактировать" : "Транзакция")
                .font(.system(.subheadline, design: .default, weight: .semibold))
                .foregroundStyle(FC.ink)
            Spacer()
            Button(viewModel.isEditing ? "Сохранить" : "Добавить") {
                Task {
                    if viewModel.isEditing { await viewModel.update() }
                    else                   { await viewModel.save()   }
                }
            }
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundStyle(FC.cobalt.opacity(viewModel.canSave ? 1.0 : 0.5))
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
        // Trigger on state → idle (covers both auto-stop and manual stop)
        .onChange(of: voice.isIdle) { _, isNowIdle in
            if isNowIdle { viewModel.applyVoiceResult() }
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
                    .environment(\.locale, Locale(identifier: "ru_RU"))
            }
            hairline

            fieldRow(label: "КАТЕГОРИЯ") {
                Button {
                    showCategoryPicker = true
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

                fieldRow(label: "КЛИЕНТ") {
                    Menu {
                        Button("Без клиента") {
                            viewModel.selectedClientId   = nil
                            viewModel.selectedClientName = nil
                        }
                        ForEach(SharedDataService.shared.cachedClients) { client in
                            Button(client.name) {
                                viewModel.selectedClientId   = client.id
                                viewModel.selectedClientName = client.name
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedClientName ?? "Не выбран")
                                .font(.system(.body))
                                .foregroundStyle(viewModel.selectedClientName != nil ? FC.ink : FC.muted)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(.caption2))
                                .foregroundStyle(FC.muted)
                        }
                    }
                }
                hairline
            }

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
            .background(FC.cobalt.opacity(viewModel.canSave ? 1.0 : 0.5))
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
