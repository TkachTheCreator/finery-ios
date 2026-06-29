import Foundation
import Observation

@Observable
@MainActor
final class ClientsViewModel {

    var clients: [Client] = []
    var isLoading = false
    var errorMessage: String?

    // Add form state
    var showAddClient = false
    var newName    = ""
    var newEmail   = ""
    var newPhone   = ""
    var newStatus  = ClientStatus.active
    var newNotes   = ""
    var isSaving   = false

    // Filter + search
    var searchText   = ""
    var filterStatus: ClientStatus? = nil  // nil = all

    var filtered: [Client] {
        var result = clients
        if let f = filterStatus { result = result.filter { $0.status == f } }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return result
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            clients = try await APIClient.shared.getClients()
        } catch {
            // Graceful empty state — backend may not be deployed yet
            clients = []
        }
    }

    func addClient() async {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let client = try await APIClient.shared.createClient(
                name: name,
                email: newEmail.isEmpty ? nil : newEmail,
                phone: newPhone.isEmpty ? nil : newPhone,
                status: newStatus.rawValue,
                notes: newNotes.isEmpty ? nil : newNotes
            )
            clients.insert(client, at: 0)
            resetForm()
            showAddClient = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ client: Client) async {
        clients.removeAll { $0.id == client.id }
        try? await APIClient.shared.deleteClient(id: client.id)
    }

    func clientTransactions(_ client: Client) -> [Transaction] {
        SharedDataService.shared.transactions.filter {
            $0.description.localizedCaseInsensitiveContains(client.name)
        }
    }

    private func resetForm() {
        newName = ""; newEmail = ""; newPhone = ""
        newStatus = .active; newNotes = ""
    }
}
