import SwiftUI

struct SettingsView: View {
    @State var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    pageHeader
                    hairline
                    profileSection
                    sectionGap
                    taxSection
                    sectionGap
                    notificationsSection
                    sectionGap
                    infoSection
                    Color.clear.frame(height: 40)
                }
            }
        }
        .task { await viewModel.load() }
        .overlay(savedToast, alignment: .bottom)
        .alert("Ошибка сохранения", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: Header

    private var pageHeader: some View {
        HStack {
            Text("Настройки")
                .font(.system(.title2, design: .default, weight: .semibold))
                .foregroundStyle(FC.ink)
            Spacer()
            Button {
                Task { await viewModel.save() }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView().tint(FC.cobalt).scaleEffect(0.8)
                    } else {
                        Text("Сохранить")
                            .font(.system(.subheadline, design: .default, weight: .semibold))
                            .foregroundStyle(FC.cobalt)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: Profile

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("ПРОФИЛЬ")
            fieldRow(label: "Имя") {
                TextField("Как тебя зовут?", text: $viewModel.user.name)
                    .font(.system(.body))
                    .foregroundStyle(FC.ink)
                    .multilineTextAlignment(.trailing)
            }
            hairline
            fieldRow(label: "Кто ты") {
                Menu {
                    ForEach(UserType.allCases, id: \.self) { type in
                        Button(type.displayName) { viewModel.user.userType = type }
                    }
                } label: {
                    menuLabel(viewModel.user.userType.displayName)
                }
            }
        }
    }

    // MARK: Tax

    private var taxSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("НАЛОГООБЛОЖЕНИЕ")
            fieldRow(label: "Режим") {
                Menu {
                    ForEach(TaxMode.allCases, id: \.self) { mode in
                        Button {
                            viewModel.user.taxMode = mode
                        } label: {
                            VStack(alignment: .leading) {
                                Text(mode.displayName)
                                Text(mode.shortDescription).font(.caption)
                            }
                        }
                    }
                } label: {
                    menuLabel(viewModel.user.taxMode.displayName)
                }
            }
            hairline
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.user.taxMode.shortDescription)
                    .font(.system(.caption))
                    .foregroundStyle(FC.muted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
            }
        }
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("УВЕДОМЛЕНИЯ")
            HStack {
                Text("Напоминать о налоге")
                    .font(.system(.body))
                    .foregroundStyle(FC.ink)
                Spacer()
                Toggle("", isOn: $viewModel.user.notificationsEnabled)
                    .tint(FC.cobalt)
                    .labelsHidden()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(FC.background)

            if viewModel.user.notificationsEnabled {
                hairline
                fieldRow(label: "За сколько дней") {
                    Menu {
                        ForEach([3, 5, 7, 10], id: \.self) { days in
                            Button("За \(days) дней") { viewModel.user.taxReminderDaysBefore = days }
                        }
                    } label: {
                        menuLabel("За \(viewModel.user.taxReminderDaysBefore) дней")
                    }
                }
            }
        }
    }

    // MARK: Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("О ПРИЛОЖЕНИИ")
            infoRow(label: "Версия", value: "1.0.0")
            hairline
            infoRow(label: "Сборка", value: "1")
        }
    }

    // MARK: Toast

    private var savedToast: some View {
        Group {
            if viewModel.savedFeedback {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(FC.success)
                    Text("Сохранено")
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .foregroundStyle(FC.ink)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(FC.surface)
                .overlay(Rectangle().stroke(FC.border, lineWidth: 0.5))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 48)
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.savedFeedback)
    }

    // MARK: Helpers

    @ViewBuilder
    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(.body))
                .foregroundStyle(FC.ink)
            Spacer()
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(FC.background)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(.body)).foregroundStyle(FC.ink)
            Spacer()
            Text(value).font(.system(.body)).foregroundStyle(FC.muted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(FC.background)
    }

    private func menuLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text).font(.system(.body)).foregroundStyle(FC.ink)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(.caption2))
                .foregroundStyle(FC.muted)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .fLabel()
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private var sectionGap: some View {
        Rectangle().fill(FC.border).frame(height: 0.5)
    }

    private var hairline: some View {
        Rectangle().fill(FC.border).frame(height: 0.5).padding(.leading, 20)
    }
}

#Preview {
    SettingsView(viewModel: .preview())
}
