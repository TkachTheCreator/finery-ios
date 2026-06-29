import SwiftUI

struct ShareParseView: View {
    let parsed: ParsedTransaction
    let originalText: String
    let onSave: (ParsedTransaction) -> Void
    let onCancel: () -> Void

    @State private var amount: String
    @State private var direction: String
    @State private var description: String
    @State private var category: String
    @State private var showOriginal = false

    private let allCategories = [
        "Еда", "Транспорт", "Продукты", "Здоровье", "Одежда",
        "Коммуналка", "Развлечения", "Зарплата", "Переводы", "Другое"
    ]

    init(parsed: ParsedTransaction, originalText: String,
         onSave: @escaping (ParsedTransaction) -> Void,
         onCancel: @escaping () -> Void) {
        self.parsed       = parsed
        self.originalText = originalText
        self.onSave       = onSave
        self.onCancel     = onCancel
        _amount      = State(initialValue: parsed.amount > 0
                             ? String(format: "%.0f", parsed.amount) : "")
        _direction   = State(initialValue: parsed.direction)
        _description = State(initialValue: parsed.description)
        _category    = State(initialValue: parsed.category)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F5EFE0").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Банк + уверенность
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .foregroundColor(Color(hex: "#0047AB"))
                            Text(parsed.bankName)
                                .font(.headline)
                                .foregroundColor(Color(hex: "#1A1A18"))
                            Spacer()
                            Text("\(Int(parsed.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#8B7D5A"))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        // Тип операции
                        HStack(spacing: 0) {
                            directionButton("Расход", value: "expense",
                                            activeColor: .red)
                            directionButton("Доход",  value: "income",
                                            activeColor: Color(hex: "#0047AB"))
                        }
                        .background(Color.white)
                        .cornerRadius(12)

                        // Сумма
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Сумма")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#8B7D5A"))
                            HStack {
                                TextField("0", text: $amount)
                                    .font(.system(size: 32, weight: .bold))
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(Color(hex: "#1A1A18"))
                                Text("₽")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color(hex: "#0047AB"))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        // Категория
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Категория")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#8B7D5A"))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(allCategories, id: \.self) { cat in
                                        Button { category = cat } label: {
                                            Text(cat)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(category == cat
                                                            ? Color(hex: "#0047AB")
                                                            : Color(hex: "#F5EFE0"))
                                                .foregroundColor(category == cat
                                                                 ? .white
                                                                 : Color(hex: "#1A1A18"))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        // Описание
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Описание")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#8B7D5A"))
                            TextField("Описание", text: $description)
                                .foregroundColor(Color(hex: "#1A1A18"))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        // Оригинальный текст
                        Button { withAnimation { showOriginal.toggle() } } label: {
                            HStack {
                                Text("Исходный текст")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#8B7D5A"))
                                Spacer()
                                Image(systemName: showOriginal
                                      ? "chevron.up" : "chevron.down")
                                    .foregroundColor(Color(hex: "#8B7D5A"))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        if showOriginal {
                            Text(originalText)
                                .font(.caption)
                                .foregroundColor(Color(hex: "#8B7D5A"))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }

                        // Сохранить
                        Button {
                            var updated = parsed
                            updated.amount      = Double(amount) ?? parsed.amount
                            updated.direction   = direction
                            updated.description = description
                            updated.category    = category
                            onSave(updated)
                        } label: {
                            Text("Добавить в Finery")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#0047AB"))
                                .cornerRadius(16)
                        }
                        .disabled(amount.isEmpty)
                        .opacity(amount.isEmpty ? 0.4 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Новая транзакция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", action: onCancel)
                }
            }
        }
    }

    @ViewBuilder
    private func directionButton(_ label: String, value: String,
                                 activeColor: Color) -> some View {
        Button { withAnimation { direction = value } } label: {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(direction == value ? activeColor : Color.clear)
                .foregroundColor(direction == value
                                 ? .white : Color(hex: "#8B7D5A"))
        }
    }
}

// Local Color(hex:) — share extension is a separate module
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
