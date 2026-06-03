import Foundation

protocol UserRepository: Sendable {
    func fetchUser() async throws -> User?
    func saveUser(_ user: User) async throws
    func updateUser(_ user: User) async throws
}
