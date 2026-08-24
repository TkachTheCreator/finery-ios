import Foundation
import Observation

@Observable
@MainActor
final class ClientsViewModel {

    var clients: [Client] = []
    var isLoading = false
    var errorMessage: String?

    init(transactionRepository: any TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func makeAddTransactionViewModel(client: Client) -> AddTransactionViewModel {
        let vm = AddTransactionViewModel(transactionRepository: transactionRepository)
        vm.selectedClientId   = client.id
        vm.selectedClientName = client.name
        return vm
    }

    // Add form state
    var showAddClient = false
    var newName    = ""
    var newPhone   = ""
    var newStatus  = ClientStatus.active
    var newNotes   = ""
    var isSaving   = false

    let voice = VoiceInputManager()

    private let transactionRepository: any TransactionRepository

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
        print("[DEBUG] ClientsViewModel.load() — START")
        isLoading = true
        defer {
            isLoading = false
            print("[DEBUG] ClientsViewModel.load() — DONE, isLoading=false")
        }
        do {
            let loaded = try await APIClient.shared.getClients()
            clients = loaded
            SharedDataService.shared.persistClients(loaded)
            print("[DEBUG] ClientsViewModel — loaded \(loaded.count) clients")
        } catch NetworkError.unauthorized {
            print("[DEBUG] ClientsViewModel — 401, session expired")
            await SharedDataService.shared.handleSessionExpired()
        } catch {
            print("[DEBUG] ClientsViewModel — error: \(error)")
            if clients.isEmpty {
                clients = SharedDataService.shared.cachedClients
            }
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
                email: nil,
                phone: newPhone.isEmpty ? nil : newPhone,
                status: newStatus.rawValue,
                notes: newNotes.isEmpty ? nil : newNotes
            )
            clients.insert(client, at: 0)
            resetForm()
            showAddClient = false
        } catch NetworkError.unauthorized {
            await SharedDataService.shared.handleSessionExpired()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyVoiceToClient() {
        let text = voice.recognizedText
        guard !text.isEmpty else { return }

        // Extract phone: sequence of 10+ digits possibly with spaces/dashes/+
        let phoneRegex = /(\+?[\d][\d\s\-]{8,}[\d])/
        var phoneFound = ""
        if let match = text.firstMatch(of: phoneRegex) {
            phoneFound = String(match.0)
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
            if newPhone.isEmpty { newPhone = phoneFound }
        }

        // Name: text minus the phone number
        if newName.isEmpty {
            let namePart = phoneFound.isEmpty
                ? text
                : text.replacingOccurrences(of: phoneFound, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            // Capitalise first letter of each word
            newName = namePart.split(separator: " ")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }
    }

    func updateClient(id: UUID, name: String, phone: String?, status: ClientStatus, notes: String?) async {
        do {
            let updated = try await APIClient.shared.updateClient(
                id: id, name: name, phone: phone, status: status.rawValue, notes: notes)
            if let idx = clients.firstIndex(where: { $0.id == id }) {
                clients[idx] = updated
                SharedDataService.shared.persistClients(clients)
            }
        } catch NetworkError.unauthorized {
            await SharedDataService.shared.handleSessionExpired()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteClient(id: UUID) async {
        clients.removeAll { $0.id == id }
        SharedDataService.shared.persistClients(clients)
        do {
            try await APIClient.shared.deleteClient(id: id)
        } catch NetworkError.unauthorized {
            await SharedDataService.shared.handleSessionExpired()
        } catch { }
    }

    func updateTotalPaid(client: Client, amount: Decimal) async {
        do {
            let updated = try await APIClient.shared.updateClientTotalPaid(id: client.id, totalPaid: amount)
            if let idx = clients.firstIndex(where: { $0.id == client.id }) {
                clients[idx] = updated
                SharedDataService.shared.persistClients(clients)
            }
        } catch NetworkError.unauthorized {
            await SharedDataService.shared.handleSessionExpired()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchClientTransactions(clientId: UUID) async -> [Transaction] {
        do {
            return try await APIClient.shared.getClientTransactions(clientId: clientId)
        } catch {
            return []
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
        newName = ""; newPhone = ""
        newStatus = .active; newNotes = ""
    }
}
