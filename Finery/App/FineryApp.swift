import SwiftUI
import SwiftData

@main
struct FineryApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [TransactionEntity.self, UserEntity.self], inMemory: false)
    }
}
