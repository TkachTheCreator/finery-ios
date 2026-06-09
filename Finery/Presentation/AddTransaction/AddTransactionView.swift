import SwiftUI
import Pow

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
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showSuccess = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(1.6))
                    dismiss()
                }
            }
        }
        .overlay {
            if showSuccess {
                ZStack {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    VStack(spacing: 10) {
                        LottieSuccessView()
                            .frame(width: 160, height: 160)
                        Text("Сохранено!")
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
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
            directionButton(.income, label: "Доход", color: FC.success)
            Rectangle().fill(FC.border).frame(width: 0.5)
            directionButton(.expense, label: "Расход", color: FC.danger)
        }
        .frame(height: 48)
        .overlay(Rectangle().stroke(FC.border.opacity(0), lineWidth: 0))
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

    // MARK: Form Fields

    private var formFields: some View {
        VStack(spacing: 0) {
            fieldRow(label: "ОПИСАНИЕ") {
                TextField("За что оплата", text: $viewModel.description)
                    .font(.system(.body))
                    .foregroundStyle(FC.ink)
                    .onChange(of: viewModel.description) { _, _ in viewModel.onDescriptionChanged() }
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
        }
        .disabled(!viewModel.canSave || viewModel.isSaving)
        .changeEffect(
            .spray(origin: UnitPoint(x: 0.5, y: 0.5)) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(FC.success)
            },
            value: viewModel.didSave
        )
    }

    private var hairline: some View {
        Rectangle().fill(FC.border).frame(height: 0.5)
    }
}

#Preview {
    AddTransactionView(viewModel: .preview())
}
