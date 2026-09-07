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
            CustomCategory(name: "Boosty/Подписки",  type: .income,  icon: "star"),
            CustomCategory(name: "Донаты",           type: .income,  icon: "heart"),
            CustomCategory(name: "Реклама",          type: .income,  icon: "megaphone"),
            CustomCategory(name: "Фриланс",          type: .income,  icon: "briefcase"),
            CustomCategory(name: "Платформы",        type: .income,  icon: "play.rectangle"),
            CustomCategory(name: "Курсы/Обучение",   type: .income,  icon: "graduationcap"),
            CustomCategory(name: "Другое",           type: .income,  icon: "ellipsis.circle"),
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

// MARK: - Categories Screen (unchanged, reachable from Settings)

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
                        Text("Название").fLabel()
                        TextField("Название категории", text: $newName)
                            .font(.system(.body, design: .rounded))
                            .padding(12)
                            .background(FC.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(FC.border, lineWidth: 0.5))
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Иконка").fLabel()
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

// MARK: - Settings (top-level: 4 navigation tiles)

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
                    VStack(alignment: .leading, spacing: 14) {
                        // Title
                        HStack {
                            Text("Настройки")
                                .font(.system(.title2, design: .rounded, weight: .semibold))
                                .foregroundStyle(FC.ink)
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView().tint(FC.cobalt).scaleEffect(0.8)
                            }
                        }
                        .padding(.top, 20)

                        // Top-level tiles — tapping each opens a sub-screen
                        settingsTile(icon: "person.circle", title: "Профиль",
                                     subtitle: viewModel.user.name.isEmpty ? "Имя, тип учёта" : viewModel.user.name,
                                     destination: AnyView(ProfileSettingsView(viewModel: viewModel)))

                        settingsTile(icon: "percent", title: "Налог",
                                     subtitle: viewModel.user.userType == .other ? "Личный трекер" : viewModel.user.taxMode.displayName,
                                     destination: AnyView(TaxSettingsView(viewModel: viewModel)))

                        settingsTile(icon: "lock.circle", title: "Безопасность",
                                     subtitle: "Биометрия, уведомления",
                                     destination: AnyView(SecuritySettingsView(viewModel: viewModel)))

                        settingsTile(icon: "tag.circle", title: "Категории",
                                     subtitle: "Доходы и расходы",
                                     destination: AnyView(CategoriesView()))

                        settingsTile(icon: "info.circle", title: "О приложении",
                                     subtitle: "Версия, выход из аккаунта",
                                     destination: AnyView(AppInfoSettingsView(viewModel: viewModel)))

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .task { await viewModel.load() }
        }
    }

    private func settingsTile(icon: String, title: String, subtitle: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(FC.cobalt)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(FC.ink)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded, weight: .regular))
                        .foregroundStyle(FC.inkSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FC.border)
            }
            .padding(18)
            .dataWidget()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Sub-screen

struct ProfileSettingsView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            List {
                Section {
                    settingsRow(label: "Имя") {
                        TextField("Как тебя зовут?", text: $viewModel.user.name)
                            .font(.system(.body))
                            .foregroundStyle(FC.ink)
                            .multilineTextAlignment(.trailing)
                            .onSubmit { Task { await viewModel.save() } }
                    }
                    settingsRow(label: "Кто ты") {
                        Menu {
                            Button("Самозанятый") {
                                viewModel.user.userType = .selfEmployed
                                Task { await viewModel.save() }
                            }
                            Button("Личные финансы") {
                                viewModel.user.userType = .other
                                Task { await viewModel.save() }
                            }
                            Button("ИП / ООО") {
                                viewModel.user.userType = .freelancer
                                Task { await viewModel.save() }
                            }
                        } label: {
                            menuLabel(userTypeDisplayName)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var userTypeDisplayName: String {
        switch viewModel.user.userType {
        case .selfEmployed: return "Самозанятый"
        case .other:        return "Личные финансы"
        case .freelancer:   return "ИП / ООО"
        case .blogger:      return "Самозанятый"  // legacy mapping
        }
    }

    private func settingsRow<C: View>(label: String, @ViewBuilder content: () -> C) -> some View {
        HStack {
            Text(label).font(.system(.body)).foregroundStyle(FC.ink)
            Spacer()
            content()
        }
    }

    private func menuLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text).font(.system(.body)).foregroundStyle(FC.ink)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(.caption2)).foregroundStyle(FC.muted)
        }
    }
}

// MARK: - Tax Sub-screen

struct TaxSettingsView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            if viewModel.user.userType == .other {
                VStack(spacing: 12) {
                    Image(systemName: "house.circle")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(FC.inkSecondary)
                    Text("Личный трекер")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(FC.ink)
                    Text("Налоги не отслеживаются для этого типа учёта.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(FC.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        // Режим
                        Picker("Режим налогообложения", selection: $viewModel.user.taxMode) {
                            ForEach(TaxMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .font(.system(.body))
                        .onChange(of: viewModel.user.taxMode) { _, _ in
                            Task { await viewModel.save() }
                        }
                    } footer: {
                        Text(viewModel.user.taxMode.shortDescription)
                            .font(.system(.caption))
                            .foregroundStyle(FC.inkSecondary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Налог")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Security Sub-screen

struct SecuritySettingsView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            List {
                Section("Биометрия") {
                    biometricRow
                }
                Section("Уведомления") {
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
                    if viewModel.user.notificationsEnabled {
                        Picker("За сколько дней", selection: $viewModel.user.taxReminderDaysBefore) {
                            ForEach([3, 5, 7, 10], id: \.self) { days in
                                Text("За \(days) дней").tag(days)
                            }
                        }
                        .onChange(of: viewModel.user.taxReminderDaysBefore) { _, _ in
                            Task { await viewModel.save() }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Безопасность")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private var biometricRow: some View {
        let lock = AppLockManager.shared
        return Group {
            if lock.isBiometricAvailable {
                HStack {
                    Text(lock.biometricLabel)
                        .font(.system(.body)).foregroundStyle(FC.ink)
                    Spacer()
                    Toggle("", isOn: Binding(get: { lock.isEnabled }, set: { lock.isEnabled = $0 }))
                        .tint(FC.cobalt).labelsHidden()
                }
            } else {
                Text("Биометрия недоступна")
                    .font(.system(.body)).foregroundStyle(FC.inkSecondary)
            }
        }
    }
}

// MARK: - App Info Sub-screen

struct AppInfoSettingsView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            List {
                Section {
                    infoRow(label: "Версия", value: appVersion)
                    infoRow(label: "Сборка",  value: appBuild)
                }
                Section {
                    NavigationLink(destination: NetworkDebugView()) {
                        Text("Диагностика сети")
                            .font(.system(.body)).foregroundStyle(FC.inkSecondary)
                    }
                }
                Section {
                    Button(role: .destructive) {
                        viewModel.logout()
                    } label: {
                        Text("Выйти из аккаунта")
                            .font(.system(.body)).foregroundStyle(FC.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("О приложении")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(.body)).foregroundStyle(FC.ink)
            Spacer()
            Text(value).font(.system(.body)).foregroundStyle(FC.inkSecondary)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

#Preview {
    SettingsView(viewModel: .preview())
}
