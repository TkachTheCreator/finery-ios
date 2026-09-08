import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Intent (widget extension scope — opens app)

struct OpenAddTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Добавить операцию в Finery"
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - iOS 18 Control Widget

struct FineryAddTransactionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.tkachev.finery.control.add") {
            ControlWidgetButton(action: OpenAddTransactionIntent()) {
                Label("Добавить", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Finery — Добавить")
        .description("Открыть запись операции в Finery")
    }
}

// MARK: - Bundle entry point

@main
struct FineryControlBundle: WidgetBundle {
    var body: some Widget {
        FineryAddTransactionControl()
    }
}
