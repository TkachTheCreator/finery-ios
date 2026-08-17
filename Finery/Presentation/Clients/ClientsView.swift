import SwiftUI

struct ClientsView: View {
    @State var viewModel: ClientsViewModel
    @State private var appeared   = false
    @State private var selectedClient: Client?
    @State private var showInvoices = false

    init(viewModel: ClientsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                searchBar
                if !viewModel.clients.isEmpty {
                    filterChips
                        .padding(.bottom, 8)
                }
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(FC.cobalt)
                    Spacer()
                } else if viewModel.filtered.isEmpty {
                    emptyState
                } else {
                    clientList
                }
            }
        }
        .task { await viewModel.load() }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) { appeared = true }
        }
        .sheet(isPresented: $viewModel.showAddClient) { addClientSheet }
        .sheet(item: $selectedClient) { ClientDetailView(client: $0, viewModel: viewModel) }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Клиенты")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text("\(viewModel.clients.count) клиентов")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            Button { viewModel.showAddClient = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(FC.cobalt)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .offset(y: appeared ? 0 : -16)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FC.muted)
                .font(.system(size: 14))
            TextField("Поиск по имени или email", text: $viewModel.searchText)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FC.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FC.border, lineWidth: 0.5))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "Все", value: nil)
                filterChip(label: "Активные", value: .active)
                filterChip(label: "Должники", value: .debt)
                filterChip(label: "Завершены", value: .completed)
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(label: String, value: ClientStatus?) -> some View {
        let selected = viewModel.filterStatus == value
        return Button { viewModel.filterStatus = value } label: {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? .white : FC.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? FC.cobalt : FC.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selected ? FC.cobalt : FC.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: Client list

    private var clientList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(Array(viewModel.filtered.enumerated()), id: \.element.id) { idx, client in
                    clientCard(client)
                        .offset(y: appeared ? 0 : 40)
                        .opacity(appeared ? 1 : 0)
                        .animation(.fineryCard.delay(Double(idx) * 0.04), value: appeared)
                        .onTapGesture { selectedClient = client }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(client) }
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    private func clientCard(_ client: Client) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(statusColor(client.status).opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(String(client.name.prefix(1)).uppercased())
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(statusColor(client.status))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(client.name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                if let email = client.email {
                    Text(email)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(FC.muted)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(client.totalPaid.rub())
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(FC.ink)
                statusBadge(client.status)
            }
        }
        .padding(14)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FC.border, lineWidth: 0.5))
    }

    private func statusBadge(_ status: ClientStatus) -> some View {
        Text(status.displayName)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(statusColor(status).opacity(0.1))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: ClientStatus) -> Color {
        switch status {
        case .active:    FC.cobalt
        case .debt:      FC.danger
        case .completed: FC.muted
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(FC.muted.opacity(0.5))
            Text(viewModel.clients.isEmpty ? "Нет клиентов" : "Ничего не найдено")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(FC.ink)
            if viewModel.clients.isEmpty {
                Text("Добавьте первого клиента")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FC.muted)
                Button("Добавить клиента") { viewModel.showAddClient = true }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(FC.cobalt)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: Add client sheet

    private var addClientSheet: some View {
        NavigationView {
            ZStack {
                FC.background.ignoresSafeArea()
                Form {
                    Section("Основное") {
                        TextField("Имя *", text: $viewModel.newName)
                        TextField("Email", text: $viewModel.newEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        TextField("Телефон", text: $viewModel.newPhone)
                            .keyboardType(.phonePad)
                    }
                    Section("Статус") {
                        Picker("Статус", selection: $viewModel.newStatus) {
                            ForEach(ClientStatus.allCases, id: \.self) {
                                Text($0.displayName).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Заметки") {
                        TextField("Заметки", text: $viewModel.newNotes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Новый клиент")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { viewModel.showAddClient = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Добавить") { Task { await viewModel.addClient() } }
                            .disabled(viewModel.newName.trimmingCharacters(in: .whitespaces).isEmpty)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Client Detail

struct ClientDetailView: View {
    let client: Client
    let viewModel: ClientsViewModel
    @Environment(\.dismiss) private var dismiss

    var transactions: [Transaction] { viewModel.clientTransactions(client) }

    var body: some View {
        NavigationView {
            ZStack {
                FC.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Profile card
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().fill(FC.cobalt.opacity(0.12)).frame(width: 64, height: 64)
                                Text(String(client.name.prefix(1)).uppercased())
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(FC.cobalt)
                            }
                            Text(client.name)
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundStyle(FC.ink)
                            if let email = client.email {
                                Text(email).font(.system(.caption, design: .rounded)).foregroundStyle(FC.muted)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(FC.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Stats
                        HStack(spacing: 0) {
                            statCell(label: "Оплачено", value: client.totalPaid.rub())
                            Rectangle().fill(FC.border).frame(width: 1)
                            statCell(label: "Статус", value: client.status.displayName)
                        }
                        .background(FC.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Transactions
                        if !transactions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("ТРАНЗАКЦИИ").font(.system(.caption2, design: .rounded, weight: .semibold)).foregroundStyle(FC.muted)
                                ForEach(transactions.prefix(10)) { tx in
                                    HStack {
                                        Text(tx.description).font(.system(.subheadline, design: .rounded)).foregroundStyle(FC.ink).lineLimit(1)
                                        Spacer()
                                        Text(tx.direction == .income ? "+" + tx.amount.rub() : "-" + tx.amount.rub())
                                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                            .foregroundStyle(tx.direction == .income ? FC.cobalt : FC.danger)
                                    }
                                    .padding(.vertical, 4)
                                    if tx.id != transactions.prefix(10).last?.id {
                                        Rectangle().fill(FC.border.opacity(0.5)).frame(height: 0.5)
                                    }
                                }
                            }
                            .padding()
                            .background(FC.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            Text("Нет привязанных транзакций")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(FC.muted)
                                .padding()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(client.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(.caption2, design: .rounded, weight: .semibold)).foregroundStyle(FC.muted)
            Text(value).font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(FC.ink)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension Decimal {
    func rub() -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal; fmt.locale = Locale(identifier: "ru_RU")
        fmt.maximumFractionDigits = 0
        return (fmt.string(from: self as NSDecimalNumber) ?? "\(self)") + "\u{202F}₽"
    }
}
