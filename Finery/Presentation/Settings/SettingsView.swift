import SwiftUI

// MARK: - Custom Category Model

struct CustomCategory: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var type: CategoryKind
    var icon: String

    enum CategoryKind: String, Codable, Sendable {
        case income, expense
    }
}

@Observable
@MainActor
final class CustomCategoryStore {
    static let shared = CustomCategoryStore()
    private let key        = "finery_custom_categories"
    private let migratedKey = "finery_categories_v2_seeded"
    private(set) var categories: [CustomCategory] = []

    private init() { load() }

    private func load() {
        let alreadyMigrated = UserDefaults.standard.bool(forKey: migratedKey)
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([CustomCategory].self, from: data)
        else { seedDefaults(); return }

        if !alreadyMigrated {
            // Keep only user-created entries (not from old minimal seed)
            let oldSeedNames: Set<String> = ["Основной доход", "Подработка", "Еда", "Транспорт", "Прочее"]
            let userAdded = saved.filter { !oldSeedNames.contains($0.name) }
            seedDefaults()
            categories.append(contentsOf: userAdded)
            persist()
        } else {
            categories = saved
        }
    }

    private func seedDefaults() {
        categories = [
            // Доходы (совпадают с displayName перечисления IncomeCategory)
            CustomCategory(name: "Boosty/Подписки",  type: .income,  icon: "star"),
            CustomCategory(name: "Донаты",           type: .income,  icon: "heart"),
            CustomCategory(name: "Реклама",          type: .income,  icon: "megaphone"),
            CustomCategory(name: "Фриланс",          type: .income,  icon: "briefcase"),
            CustomCategory(name: "Платформы",        type: .income,  icon: "play.rectangle"),
            CustomCategory(name: "Курсы/Обучение",   type: .income,  icon: "graduationcap"),
            CustomCategory(name: "Другое",           type: .income,  icon: "ellipsis.circle"),
            // Расходы (совпадают с displayName перечисления ExpenseCategory)
            CustomCategory(name: "Инструменты",      type: .expense, icon: "wrench.and.screwdriver"),
            CustomCategory(name: "Своя реклама",     type: .expense, icon: "megaphone"),
            CustomCategory(name: "Оборудование",     type: .expense, icon: "camera"),
            CustomCategory(name: "Команда",          type: .expense, icon: "person.2"),
            CustomCategory(name: "Еда",              type: .expense, icon: "fork.knife"),
            CustomCategory(name: "Транспорт",        type: .expense, icon: "car"),
            CustomCategory(name: "Связь",            type: .expense, icon: "phone"),
            CustomCategory(name: "Другое",           type: .expense, icon: "ellipsis.circle"),
        ]
        UserDefaults.standard.set(true, forKey: migratedKey)
        persist()
    }

    func add(name: String, type: CustomCategory.CategoryKind, icon: String) {
        categories.append(CustomCategory(name: name, type: type, icon: icon))
        persist()
    }

    func delete(_ category: CustomCategory) {
        categories.removeAll { $0.id == category.id }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(try? JSONEncoder().encode(categories), forKey: key)
    }
}

// MARK: - Categories Screen

struct CategoriesView: View {
    private let store = CustomCategoryStore.shared
    @State private var showAdd = false
    @State private var addKind: CustomCategory.CategoryKind = .income
    @State private var newName = ""
    @State private var newIcon = "tag"

    private let icons = [
        "tag", "star", "heart", "briefcase", "car", "fork.knife",
        "house", "cart", "wifi", "phone", "book", "graduationcap",
        "music.note", "gamecontroller", "airplane", "cross.case",
        "ellipsis.circle", "bolt", "drop", "pawprint"
    ]

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            List {
                categorySection(kind: .income,  title: "Доходы")
                categorySection(kind: .expense, title: "Расходы")
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Категории")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Menu {
                    Button("+ Доход")  { addKind = .income;  showAdd = true }
                    Button("+ Расход") { addKind = .expense; showAdd = true }
                } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) { addSheet }
    }

    @ViewBuilder
    private func categorySection(kind: CustomCategory.CategoryKind, title: String) -> some View {
        Section(title) {
            ForEach(store.categories.filter { $0.type == kind }) { cat in
                HStack(spacing: 12) {
                    Image(systemName: cat.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(FC.cobalt)
                        .frame(width: 28)
                    Text(cat.name)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(FC.ink)
                }
            }
            .onDelete { idx in
                let filtered = store.categories.filter { $0.type == kind }
                idx.forEach { store.delete(filtered[$0]) }
            }
        }
    }

    private var addSheet: some View {
        NavigationView {
            ZStack {
                FC.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("НАЗВАНИЕ").fLabel()
                        TextField("Название категории", text: $newName)
                            .font(.system(.body, design: .rounded))
                            .padding(12)
                            .background(FC.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(FC.border, lineWidth: 0.5))
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ИКОНКА").fLabel()
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button { newIcon = icon } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(newIcon == icon ? .white : FC.ink)
                                        .frame(width: 48, height: 48)
                                        .background(newIcon == icon ? FC.cobalt : FC.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(FC.border, lineWidth: 0.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        let n = newName.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { return }
                        store.add(name: n, type: addKind, icon: newIcon)
                        newName = ""; newIcon = "tag"; showAdd = false
                    } label: {
                        Text("Добавить")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(FC.cobalt.opacity(newName.isEmpty ? 0.4 : 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Новая категория (\(addKind == .income ? "Доход" : "Расход"))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { showAdd = false }
                }
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @State var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
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
                        categoriesSection
                        sectionGap
                        infoSection
                        Color.clear.frame(height: 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
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
    }

    // MARK: Header

    private var pageHeader: some View {
        HStack {
            Text("Настройки")
                .font(.system(.title2, design: .default, weight: .semibold))
                .foregroundStyle(FC.ink)
            Spacer()
            if viewModel.isSaving {
                ProgressView().tint(FC.cobalt).scaleEffect(0.8)
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
                    .onSubmit { Task { await viewModel.save() } }
            }
            hairline
            fieldRow(label: "Кто ты") {
                Menu {
                    ForEach(UserType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            viewModel.user.userType = type
                            Task { await viewModel.save() }
                        }
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
            if viewModel.user.userType == .other {
                fieldRow(label: "Режим") {
                    Text("Без налогов")
                        .font(.system(.body))
                        .foregroundStyle(FC.muted)
                }
                hairline
                Text("Личный трекер — налоги и лимиты не отслеживаются")
                    .font(.system(.caption))
                    .foregroundStyle(FC.muted)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            } else {
                fieldRow(label: "Режим") {
                    Menu {
                        ForEach(TaxMode.allCases, id: \.self) { mode in
                            Button {
                                viewModel.user.taxMode = mode
                                Task { await viewModel.save() }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(mode.displayName)
                                    Text(mode.shortDescription)
                                        .font(.caption)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    } label: {
                        menuLabel(viewModel.user.taxMode.displayName)
                    }
                }
                hairline
                Text(viewModel.user.taxMode.shortDescription)
                    .font(.system(.caption))
                    .foregroundStyle(FC.muted)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
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
                    .onChange(of: viewModel.user.notificationsEnabled) { _, _ in
                        Task { await viewModel.save() }
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(FC.background)

            if viewModel.user.notificationsEnabled {
                hairline
                fieldRow(label: "За сколько дней") {
                    Menu {
                        ForEach([3, 5, 7, 10], id: \.self) { days in
                            Button("За \(days) дней") {
                                viewModel.user.taxReminderDaysBefore = days
                                Task { await viewModel.save() }
                            }
                        }
                    } label: {
                        menuLabel("За \(viewModel.user.taxReminderDaysBefore) дней")
                    }
                }
            }
        }
    }

    // MARK: Categories

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("КАТЕГОРИИ")
            NavigationLink(destination: CategoriesView()) {
                HStack {
                    Text("Управление категориями")
                        .font(.system(.body))
                        .foregroundStyle(FC.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(.caption))
                        .foregroundStyle(FC.muted)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(FC.background)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("О ПРИЛОЖЕНИИ")
            infoRow(label: "Версия", value: appVersion)
            hairline
            infoRow(label: "Сборка", value: appBuild)
            hairline
            Button {
                viewModel.logout()
            } label: {
                HStack {
                    Text("Выйти из аккаунта")
                        .font(.system(.body))
                        .foregroundStyle(FC.danger)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(FC.background)
            }
            .buttonStyle(.plain)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
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
                .padding(.bottom, 110)
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
            Text(text)
                .font(.system(.body))
                .foregroundStyle(FC.ink)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
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
