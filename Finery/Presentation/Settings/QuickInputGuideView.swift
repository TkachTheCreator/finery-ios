import SwiftUI

// MARK: - Quick Input Guide Screen

struct QuickInputGuideView: View {

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerNote
                    guideCard(
                        icon: "square.grid.2x2",
                        title: "Виджет на рабочем столе",
                        subtitle: "Один тап — сразу форма добавления операции",
                        steps: [
                            "Зажмите пустое место на рабочем столе",
                            "Нажмите «+» в левом верхнем углу",
                            "В поиске введите «Finery»",
                            "Выберите нужный виджет и нажмите «Добавить»"
                        ],
                        settingsURL: nil,
                        settingsLabel: nil
                    )
                    guideCard(
                        icon: "lock.square",
                        title: "Виджет на экране блокировки",
                        subtitle: "Добавить операцию не разблокируя телефон",
                        steps: [
                            "Заблокируйте телефон",
                            "Нажмите и удерживайте экран блокировки",
                            "Нажмите «Настроить» → «Экран блокировки»",
                            "Нажмите на область виджетов под временем",
                            "Найдите Finery в списке и добавьте"
                        ],
                        settingsURL: nil,
                        settingsLabel: nil
                    )
                    guideCard(
                        icon: "switch.2",
                        title: "Кнопка в Пункте управления",
                        subtitle: "Смахните вниз — кнопка Finery всегда под рукой",
                        steps: [
                            "Откройте Настройки → Пункт управления",
                            "В разделе «Другие элементы» найдите Finery",
                            "Нажмите «+» рядом с названием"
                        ],
                        settingsURL: URL(string: "App-prefs:root=ControlCenter"),
                        settingsLabel: "Открыть Пункт управления"
                    )
                    guideCard(
                        icon: "hand.tap",
                        title: "Быстрый ввод через Back Tap",
                        subtitle: "Дважды постучите по задней панели телефона",
                        steps: [
                            "Настройки → Специальные возможности",
                            "Касание → Касание задней панели",
                            "Выберите «Двойное» или «Тройное касание»",
                            "Прокрутите до раздела «Команды»",
                            "Найдите «Добавить операцию в Finery» и выберите"
                        ],
                        settingsURL: URL(string: "App-prefs:root=ACCESSIBILITY"),
                        settingsLabel: "Открыть Специальные возможности"
                    )
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Быстрый ввод")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header note

    private var headerNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(FC.inkSecondary)
                .padding(.top, 1)
            Text("Ниже — инструкции по четырём способам добавлять операции, не заходя в Finery.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FC.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FC.border, lineWidth: 0.5))
    }

    // MARK: - Guide card builder

    @ViewBuilder
    private func guideCard(
        icon: String,
        title: String,
        subtitle: String,
        steps: [String],
        settingsURL: URL?,
        settingsLabel: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header row
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(FC.inkSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(FC.ink)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(FC.inkSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.bottom, 14)

            Rectangle().fill(FC.border).frame(height: 0.5)
                .padding(.bottom, 14)

            // Steps
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepRow(number: index + 1, text: step)
                }
            }

            // Optional "Open Settings" button
            if let url = settingsURL {
                Rectangle().fill(FC.border).frame(height: 0.5)
                    .padding(.top, 14)
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    HStack {
                        Text(settingsLabel ?? "Открыть Настройки")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(FC.cobalt)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(FC.inkSecondary)
                    }
                    .padding(.top, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .dataWidget()
    }

    // MARK: - Step row

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(FC.cobalt)
                    .frame(width: 22, height: 22)
                Text("\(number)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(FC.ivory)
            }
            .padding(.top, 1)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FC.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        QuickInputGuideView()
    }
}
