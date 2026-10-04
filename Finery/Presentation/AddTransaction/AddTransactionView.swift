import SwiftUI
import Pow
import Speech

struct AddTransactionView: View {
    @State var viewModel: AddTransactionViewModel
    var onSave: (() -> Void)?
    var autoStartVoice: Bool = false

    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var amountFontSize: CGFloat = 48
    @State private var showOverlay: OverlayState = .none
    @State private var showCategoryPicker = false
    @State private var showError = false
    @State private var showDeleteConfirm = false
    @State private var showReceiptPicker = false
    @State private var isOCRLoading = false
    @State private var showCreateClient = false
    @State private var newClientName = ""
    @State private var isCreatingClient = false

    private enum OverlayState { case none, loading, success }

    init(viewModel: AddTransactionViewModel, onSave: (() -> Void)? = nil, autoStartVoice: Bool = false) {
        _viewModel = State(wrappedValue: viewModel)
        self.onSave = onSave
        self.autoStartVoice = autoStartVoice
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
                    if showTaxHint {
                        hairline
                        taxHintRow
                    }
                    hairline
                    directionToggle
                    hairline
                    formFields
                    Spacer(minLength: 32)
                    bottomButtons
                    Spacer(minLength: 36)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            // Пункт 7: swipe-down anywhere dismisses keyboard
            .simultaneousGesture(
                DragGesture(minimumDistance: 28)
                    .onEnded { value in
                        if value.translation.height > 28 { amountFocused = false }
                    }
            )
        }
        .onAppear {
            if autoStartVoice {
                viewModel.voice.start()
            } else {
                amountFocused = true
            }
        }
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
            if let e = viewModel.errorMessage { Text(e) }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(
                direction: viewModel.direction,
                onSelect: { viewModel.selectCategory($0) }
            )
        }
        .sheet(isPresented: $showCreateClient) {
            createClientSheet
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

    // MARK: Amount + Currency

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Amount input — currency symbol is a tappable menu
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: $viewModel.amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: amountFontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(FC.ink)
                    .focused($amountFocused)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)

                Menu {
                    ForEach(Currency.allCases, id: \.self) { cur in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                viewModel.currency = cur
                            }
                        } label: {
                            Label(cur.displayName, systemImage: viewModel.currency == cur ? "checkmark" : "")
                        }
                    }
                } label: {
                    Text(viewModel.currency.symbol)
                        .font(.system(size: 32, weight: .regular, design: .rounded))
                        .foregroundStyle(FC.inkSecondary)
                        .contentShape(Rectangle())
                }
                .task { await CurrencyService.shared.fetchIfNeeded() }
                .padding(.trailing, 20)
            }
            .padding(.vertical, 12)

            // Rate hint for non-RUB currencies
            if viewModel.currency != .rub {
                let hint = CurrencyService.shared.rateLabel(for: viewModel.currency)
                if !hint.isEmpty {
                    Text(hint)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(FC.inkSecondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                }
            }
        }
        .background(FC.background)
    }

    // MARK: Tax Hint (6.1 + 6.3)

    private var taxHintRow: some View {
        VStack(spacing: 0) {
            // 6.1 — Set-aside hint
            if let hint = viewModel.taxSetAside {
                let pct = NSDecimalNumber(decimal: hint.rate * 100).intValue
                HStack(spacing: 8) {
                    Image(systemName: "piggybank")
                        .font(.system(size: 13))
                        .foregroundStyle(FC.cobalt)
                    Text("Отложи \(hint.amount.rub()) — это \(pct)% налог")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(FC.ink)
                    Spacer()
                    Button {
                        NotificationService.shared.scheduleMonthlyTaxReminder(amount: hint.amount)
                    } label: {
                        Text("До 28-го")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(FC.cobalt)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(FC.cobalt.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(FC.cobalt.opacity(0.04))
            }

            // 6.3 — Мой налог deep link (only for НПД income)
            if viewModel.isNpdMode && viewModel.canSave {
                if viewModel.taxSetAside != nil {
                    Rectangle().fill(FC.border).frame(height: 0.5).padding(.leading, 20)
                }
                Button {
                    let urlStr = "mynalog://"
                    if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    } else if let fallback = URL(string: "https://lknpd.nalog.ru/") {
                        UIApplication.shared.open(fallback)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 13))
                            .foregroundStyle(FC.success)
                        Text("Сформировать чек в Мой налог")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(FC.success)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(.caption))
                            .foregroundStyle(FC.success.opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(h: "1A7A4A").opacity(0.05))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Direction Toggle (Пункт 8: warm palette, matches dataWidget style)

    private var directionToggle: some View {
        HStack(spacing: 8) {
            directionButton(.income,  label: "Доход",  color: FC.cobalt)
            directionButton(.expense, label: "Расход", color: FC.expense)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FC.background)
    }

    private func directionButton(_ dir: TransactionDirection, label: String, color: Color) -> some View {
        let selected = viewModel.direction == dir
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { viewModel.setDirection(dir) }
        } label: {
            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? .white : FC.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? color : FC.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selected ? Color.clear : FC.border, lineWidth: 1))
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: selected)
    }

    // MARK: Receipt OCR Button

    private var receiptButton: some View {
        Button {
            showReceiptPicker = true
        } label: {
            ZStack {
                Circle()
                    .fill(isOCRLoading ? FC.muted.opacity(0.12) : FC.cobalt.opacity(0.10))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(FC.cobalt.opacity(0.25), lineWidth: 1))
                if isOCRLoading {
                    ProgressView().scaleEffect(0.7).tint(FC.cobalt)
                } else {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(FC.cobalt)
                }
            }
        }
        .disabled(isOCRLoading)
        .accessibilityLabel("Распознать чек")
        .sheet(isPresented: $showReceiptPicker) {
            ReceiptPickerSheet { image in
                showReceiptPicker = false
                guard let image else { return }
                isOCRLoading = true
                Task {
                    defer { isOCRLoading = false }
                    guard let result = try? await ReceiptOCRService.scan(image) else { return }
                    if viewModel.amountText.isEmpty {
                        let n = NSDecimalNumber(decimal: result.amount)
                        viewModel.amountText = n.decimalValue == Decimal(n.intValue) ? "\(n.intValue)" : n.stringValue
                    }
                    if !viewModel.userSelectedCategory {
                        viewModel.expenseCategory = result.suggestedCategory
                        viewModel.setDirection(.expense)
                    }
                }
            }
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
                    .frame(width: 44, height: 44)
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
        .accessibilityLabel(isRecording ? "Остановить запись" : "Голосовой ввод")
        // Trigger on state → idle (covers both auto-stop and manual stop)
        .onChange(of: voice.isIdle) { _, isNowIdle in
            if isNowIdle { viewModel.applyVoiceResult() }
        }
    }

    // MARK: Form Fields

    private var formFields: some View {
        VStack(spacing: 0) {
            // При редактировании — полная форма; при создании — только категория
            if viewModel.isEditing {
                // Пункт 3: mic button removed; receipt OCR stays
                fieldRow(label: "Описание") {
                    HStack(spacing: 10) {
                        TextField("За что оплата", text: $viewModel.description)
                            .font(.system(.body))
                            .foregroundStyle(FC.ink)
                            .onChange(of: viewModel.description) { _, _ in viewModel.onDescriptionChanged() }
                        receiptButton
                    }
                }
                hairline

                fieldRow(label: "Дата") {
                    DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(FC.cobalt)
                        .environment(\.locale, Locale(identifier: "ru_RU"))
                }
                hairline
            }

            fieldRow(label: "Категория") {
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

            // Пункт 2: client picker shown in both create and edit modes
            hairline
            clientPickerRow

            if viewModel.isEditing {
                if viewModel.direction == .income {
                    hairline
                    fieldRow(label: "Тип клиента") {
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
                }

                hairline
                fieldRow(label: "Заметки") {
                    TextField("Опционально", text: $viewModel.notes)
                        .font(.system(.body))
                        .foregroundStyle(FC.ink)
                }
                // Пункт 5: "Повторять" row removed — recurring not yet implemented
            }
        }
    }

    // Shared client picker (used in create and edit modes)
    private var clientPickerRow: some View {
        fieldRow(label: "Клиент") {
            Menu {
                Button("Без клиента") {
                    viewModel.selectedClientId   = nil
                    viewModel.selectedClientName = nil
                }
                Divider()
                Button {
                    newClientName = ""
                    showCreateClient = true
                } label: {
                    Label("Создать клиента", systemImage: "person.badge.plus")
                }
                if !SharedDataService.shared.cachedClients.isEmpty {
                    Divider()
                    ForEach(SharedDataService.shared.cachedClients) { client in
                        Button(client.name) {
                            viewModel.selectedClientId   = client.id
                            viewModel.selectedClientName = client.name
                        }
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
    }

    @ViewBuilder
    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundStyle(FC.ink)
                .frame(width: 110, alignment: .leading)
            Spacer()
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(FC.background)
    }

    // MARK: Bottom Buttons (save + optional delete)

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 10) {
            saveButton.padding(.horizontal, 20)
            if viewModel.isEditing {
                deleteButton.padding(.horizontal, 20)
            }
        }
    }

    // Задача 3: hold-to-delete replaces instant tap
    private var deleteButton: some View {
        HoldToDeleteButton {
            Task { await viewModel.deleteExisting() }
        }
    }

    // MARK: Save Button

    private var saveButton: some View {
        Button {
            Task {
                if viewModel.isEditing { await viewModel.update() }
                else                   { await viewModel.save()   }
            }
        } label: {
            Group {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text(viewModel.isEditing ? "Сохранить изменения" : "Добавить")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(FC.cobalt.opacity(viewModel.canSave ? 1.0 : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!viewModel.canSave || viewModel.isSaving)
    }

    private var hairline: some View {
        Rectangle().fill(FC.border).frame(height: 0.5)
    }

    private var showTaxHint: Bool {
        viewModel.taxSetAside != nil || (viewModel.isNpdMode && viewModel.direction == .income && viewModel.canSave)
    }

    // MARK: - Create Client Sheet

    private var createClientSheet: some View {
        NavigationView {
            ZStack {
                FC.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text("Имя клиента")
                        .fLabel()
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    TextField("Например: ООО «Пример»", text: $newClientName)
                        .font(.system(.body, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(FC.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FC.border, lineWidth: 0.5))
                        .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Новый клиент")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        showCreateClient = false
                    }
                    .foregroundStyle(FC.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isCreatingClient {
                        ProgressView()
                    } else {
                        Button("Создать") {
                            Task { await createAndSelectClient() }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(FC.cobalt)
                        .disabled(newClientName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func createAndSelectClient() async {
        let name = newClientName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isCreatingClient = true
        defer { isCreatingClient = false }
        do {
            guard APIClient.shared.isAuthenticated else { return }
            let client = try await APIClient.shared.createClient(
                name: name, email: nil, phone: nil, status: "active", notes: nil
            )
            var updated = SharedDataService.shared.cachedClients
            updated.append(client)
            SharedDataService.shared.persistClients(updated)
            viewModel.selectedClientId   = client.id
            viewModel.selectedClientName = client.name
            newClientName = ""
            showCreateClient = false
        } catch {
            // сеть недоступна — просто закрываем, клиент не создан
            showCreateClient = false
        }
    }
}

#Preview {
    AddTransactionView(viewModel: .preview())
}

// MARK: - Hold-to-Delete Button (Задача 3)

struct HoldToDeleteButton: View {
    let action: () -> Void

    @State private var fillProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdTask: Task<Void, Never>? = nil

    private let holdDuration: Double = 0.8
    private let cornerRadius: CGFloat = 14

    var body: some View {
        ZStack {
            // Base: solid danger background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(FC.danger)

            // Animated fill overlay (white sweep from left)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: geo.size.width * fillProgress)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // Label
            Text(isHolding ? "Отпусти чтобы отменить" : "Удалить · удерживай")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .animation(.easeInOut(duration: 0.18), value: isHolding)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHolding() }
                .onEnded   { _ in cancelHolding() }
        )
    }

    private func startHolding() {
        guard !isHolding else { return }
        isHolding = true
        fillProgress = 0
        withAnimation(.linear(duration: holdDuration)) {
            fillProgress = 1.0
        }
        holdTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(holdDuration * 1_000_000_000))
            guard !Task.isCancelled, isHolding else { return }
            await MainActor.run {
                HapticManager.impact(.medium)
                isHolding = false
                fillProgress = 0
                action()
            }
        }
    }

    private func cancelHolding() {
        holdTask?.cancel()
        holdTask = nil
        isHolding = false
        withAnimation(.spring(response: 0.3)) { fillProgress = 0 }
    }
}
