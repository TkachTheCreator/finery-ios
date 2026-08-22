import SwiftUI

struct CategoryPickerSheet: View {
    let direction: TransactionDirection
    let onSelect: (CustomCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showAddSheet = false
    @State private var newName      = ""
    @State private var newIcon      = "tag"

    private let store = CustomCategoryStore.shared

    private var kind: CustomCategory.CategoryKind {
        direction == .income ? .income : .expense
    }

    private var categories: [CustomCategory] {
        store.categories.filter { $0.type == kind }
    }

    private let icons = [
        "tag", "star", "heart", "briefcase", "car", "fork.knife",
        "house", "cart", "wifi", "phone", "book", "graduationcap",
        "music.note", "gamecontroller", "airplane", "cross.case",
        "ellipsis.circle", "bolt", "drop", "pawprint"
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { cat in
                    Button {
                        onSelect(cat)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(FC.cobalt.opacity(0.12)).frame(width: 30, height: 30)
                                Image(systemName: cat.icon)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(FC.cobalt)
                            }
                            Text(cat.name)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(FC.ink)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(FC.surface)
                }
                .onDelete { indices in
                    let cats = categories
                    indices.forEach { store.delete(cats[$0]) }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(FC.background.ignoresSafeArea())
            .navigationTitle("Категория")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Готово") { dismiss() }
                        .font(.system(.body, weight: .medium))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newName = ""; newIcon = "tag"
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) { addSheet }
        }
    }

    private var addSheet: some View {
        NavigationStack {
            ZStack {
                FC.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("НАЗВАНИЕ").fLabel()
                        TextField("Название категории", text: $newName)
                            .font(.system(.body))
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
                        store.add(name: n, type: kind, icon: newIcon)
                        showAddSheet = false
                    } label: {
                        Text("Добавить")
                            .font(.system(.body, weight: .semibold))
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
            .navigationTitle("Новая категория")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { showAddSheet = false }
                }
            }
        }
    }
}
