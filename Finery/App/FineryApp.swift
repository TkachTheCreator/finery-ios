import SwiftUI
import SwiftData

@main
struct FineryApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: TransactionEntity.self, UserEntity.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
