import SwiftUI
import Speech

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
            Task {
                try? await Task.sleep(for: .seconds(0.30))
                withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) { appeared = true }
            }
        }
        .sheet(isPresented: $viewModel.showAddClient, onDismiss: { viewModel.voice.stop() }) { addClientSheet }
        .sheet(item: $selectedClient) { ClientDetailView(client: $0, viewModel: viewModel) }
        .alert("Ошибка", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
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
                Text(SharedDataService.shared.localIncome(for: client.id).rub())
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
                    Section {
                        HStack {
                            TextField("Имя *", text: $viewModel.newName)
                            clientMicButton
                        }
                        TextField("Телефон", text: $viewModel.newPhone)
                            .keyboardType(.phonePad)
                    } header: {
                        Text("Основное")
                    } footer: {
                        if case .recording = viewModel.voice.state {
                            Text("Говорите... «Иван Иванов 79001234567»")
                                .foregroundStyle(FC.cobalt)
                        } else if case .error(let msg) = viewModel.voice.state {
                            Text(msg).foregroundStyle(FC.danger)
                        }
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
                .scrollDismissesKeyboard(.interactively)
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

    private var clientMicButton: some View {
        let voice = viewModel.voice
        let isRecording: Bool
        if case .recording = voice.state { isRecording = true } else { isRecording = false }

        return Button {
            voice.toggle()
        } label: {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle")
                .font(.system(size: 22))
                .foregroundStyle(isRecording ? FC.danger : FC.cobalt)
                .animation(.spring(response: 0.3), value: isRecording)
        }
        .buttonStyle(.plain)
        .onChange(of: voice.isIdle) { _, isNowIdle in
            if isNowIdle { viewModel.applyVoiceToClient() }
        }
    }
}

// MARK: - Client Detail

struct ClientDetailView: View {
    let client: Client
    let viewModel: ClientsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var linkedTransactions: [Transaction] = []
    @State private var isLoadingTx = false
    @State private var editingAmount = false
    @State private var amountText = ""
    @State private var isSavingAmount = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var showAddTransaction = false

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
                                    .font(.system(.title, design: .rounded, weight: .semibold))
                                    .foregroundStyle(FC.inkSecondary)
                            }
                            Text(client.name)
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundStyle(FC.ink)
                            if let phone = client.phone {
                                Text(phone).font(.system(.caption, design: .rounded)).foregroundStyle(FC.muted)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(FC.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Stats + amount editing
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Оплачено").fLabel()
                                    if editingAmount {
                                        HStack(spacing: 4) {
                                            TextField("0", text: $amountText)
                                                .keyboardType(.decimalPad)
                                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                .foregroundStyle(FC.ink)
                                            Text("₽").foregroundStyle(FC.muted).font(.system(.caption))
                                        }
                                    } else {
                                        Text(SharedDataService.shared.localIncome(for: client.id).rub())
                                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                            .foregroundStyle(FC.ink)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Rectangle().fill(FC.border).frame(width: 1)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Статус").fLabel()
                                    Text(client.status.displayName)
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundStyle(FC.ink)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if editingAmount {
                                Rectangle().fill(FC.border).frame(height: 0.5)
                                HStack(spacing: 12) {
                                    Button("Отмена") {
                                        editingAmount = false
                                        amountText = ""
                                    }
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(FC.muted)
                                    Spacer()
                                    Button {
                                        Task { await saveAmount() }
                                    } label: {
                                        if isSavingAmount {
                                            ProgressView().tint(.white).scaleEffect(0.8)
                                        } else {
                                            Text("Сохранить")
                                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(FC.cobalt)
                                    .clipShape(Capsule())
                                    .disabled(isSavingAmount)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                        }
                        .background(FC.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Linked transactions
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Транзакции").fLabel()
                                Spacer()
                                if isLoadingTx {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Button {
                                        showAddTransaction = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                            Text("Добавить")
                                        }
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .foregroundStyle(FC.cobalt)
                                    }
                                }
                            }
                            if linkedTransactions.isEmpty && !isLoadingTx {
                                Text("Нет привязанных транзакций")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(FC.muted)
                                    .padding(.vertical, 4)
                            } else {
                                ForEach(linkedTransactions.prefix(20)) { tx in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(tx.description)
                                                .font(.system(.subheadline, design: .rounded))
                                                .foregroundStyle(FC.ink)
                                                .lineLimit(1)
                                            Text(tx.date, style: .date)
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundStyle(FC.muted)
                                        }
                                        Spacer()
                                        Text((tx.direction == .income ? "+" : "-") + tx.amount.rub())
                                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                            .monospacedDigit()
                                            .foregroundStyle(tx.direction == .income ? FC.cobalt : FC.expense)
                                    }
                                    .padding(.vertical, 4)
                                    if tx.id != linkedTransactions.prefix(20).last?.id {
                                        Rectangle().fill(FC.border.opacity(0.5)).frame(height: 0.5)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(FC.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(16)
                }
            }
            .navigationTitle(client.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !editingAmount {
                        Button {
                            amountText = "\(NSDecimalNumber(decimal: client.totalPaid).doubleValue)"
                            editingAmount = true
                        } label: {
                            Label("Сумма", systemImage: "pencil")
                                .font(.system(.caption, design: .rounded))
                        }
                        .foregroundStyle(FC.cobalt)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showEditSheet = true } label: {
                            Label("Редактировать", systemImage: "pencil")
                        }
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Удалить клиента", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(FC.cobalt)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                ClientEditSheet(client: client, viewModel: viewModel)
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView(
                    viewModel: viewModel.makeAddTransactionViewModel(client: client),
                    onSave: {
                        Task {
                            isLoadingTx = true
                            linkedTransactions = await viewModel.fetchClientTransactions(clientId: client.id)
                            isLoadingTx = false
                        }
                    }
                )
            }
            .confirmationDialog("Удалить клиента \(client.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    Task { await viewModel.deleteClient(id: client.id); dismiss() }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
        .task {
            isLoadingTx = true
            linkedTransactions = await viewModel.fetchClientTransactions(clientId: client.id)
            isLoadingTx = false
        }
    }

    private func saveAmount() async {
        guard let decimal = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) else { return }
        isSavingAmount = true
        await viewModel.updateTotalPaid(client: client, amount: decimal)
        isSavingAmount = false
        editingAmount = false
    }
}

// MARK: - Client Edit Sheet

struct ClientEditSheet: View {
    let client: Client
    let viewModel: ClientsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var phone: String
    @State private var status: ClientStatus
    @State private var notes: String
    @State private var isSaving = false

    init(client: Client, viewModel: ClientsViewModel) {
        self.client = client
        self.viewModel = viewModel
        _name   = State(wrappedValue: client.name)
        _phone  = State(wrappedValue: client.phone ?? "")
        _status = State(wrappedValue: client.status)
        _notes  = State(wrappedValue: client.notes ?? "")
    }

    var body: some View {
        NavigationView {
            ZStack {
                FC.background.ignoresSafeArea()
                Form {
                    Section("Основное") {
                        TextField("Имя *", text: $name)
                        TextField("Телефон", text: $phone).keyboardType(.phonePad)
                    }
                    Section("Статус") {
                        Picker("Статус", selection: $status) {
                            ForEach(ClientStatus.allCases, id: \.self) {
                                Text($0.displayName).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Заметки") {
                        TextField("Заметки", text: $notes, axis: .vertical).lineLimit(3...6)
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving { ProgressView() } else {
                        Button("Сохранить") {
                            Task {
                                isSaving = true
                                await viewModel.updateClient(
                                    id: client.id,
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    phone: phone.isEmpty ? nil : phone,
                                    status: status,
                                    notes: notes.isEmpty ? nil : notes
                                )
                                isSaving = false
                                dismiss()
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }
}

