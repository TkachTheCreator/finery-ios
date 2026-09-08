import SwiftUI
import SwiftData
import AppIntents

@main
struct FineryApp: App {
    init() {
        FineryShortcutsProvider.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { await NotificationService.shared.requestPermission() }
        }
        .environment(\.font, .system(.body, design: .rounded))
        .modelContainer(for: [TransactionEntity.self, UserEntity.self], inMemory: false, isAutosaveEnabled: false)
    }
}
