import SwiftUI
import SwiftData

@main
struct FineryApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .environment(\.font, .system(.body, design: .rounded))
        .modelContainer(for: [TransactionEntity.self, UserEntity.self], inMemory: false, isAutosaveEnabled: false)
    }
}
