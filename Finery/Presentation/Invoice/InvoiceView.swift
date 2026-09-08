import SwiftUI

struct InvoiceView: View {
    @State var viewModel: InvoicesViewModel
    @State private var appeared = false

    init(viewModel: InvoicesViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Rectangle().fill(FC.border).frame(height: 0.5)
                if viewModel.isLoading {
                    Spacer(); ProgressView().tint(FC.cobalt); Spacer()
                } else if viewModel.invoices.isEmpty {
                    emptyState
                } else {
                    invoiceList
                }
            }
        }
        .task { await viewModel.load() }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) { appeared = true }
        }
        .sheet(isPresented: $viewModel.showCreateInvoice) { createSheet }
        .sheet(isPresented: $viewModel.showPDFShare) {
            if let data = viewModel.exportedPDFData {
                ShareSheet(data: data, filename: "invoice.pdf").ignoresSafeArea()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Счета")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                Text("\(viewModel.invoices.count) счётов")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            Button { viewModel.showCreateInvoice = true } label: {
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
        .padding(.vertical, 16)
        .offset(y: appeared ? 0 : -16)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: List

    private var invoiceList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(Array(viewModel.invoices.enumerated()), id: \.element.id) { idx, invoice in
                    invoiceCard(invoice)
                        .offset(y: appeared ? 0 : 40)
                        .opacity(appeared ? 1 : 0)
                        .animation(.fineryCard.delay(Double(idx) * 0.04), value: appeared)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(invoice) }
                            } label: { Label("Удалить", systemImage: "trash") }
                        }
                        .swipeActions(edge: .leading) {
                            Button { viewModel.generatePDF(for: invoice) } label: {
                                Label("PDF", systemImage: "doc.fill")
                            }
                            .tint(FC.cobalt)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 40)
        }
    }

    private func invoiceCard(_ invoice: Invoice) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(FC.cobalt.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(FC.cobalt)
                    .font(.system(size: 18, weight: .light))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Счёт №\(invoice.number)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)
                if !invoice.clientName.isEmpty {
                    Text(invoice.clientName)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(FC.muted)
                }
                Text(invoice.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(FC.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(invoice.computedTotal.rub())
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(FC.ink)
                Button { viewModel.generatePDF(for: invoice) } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                        .foregroundStyle(FC.cobalt)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(FC.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FC.border, lineWidth: 0.5))
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text").font(.system(size: 52, weight: .light)).foregroundStyle(FC.muted.opacity(0.5))
            Text("Нет счётов").font(.system(.headline, design: .rounded)).foregroundStyle(FC.ink)
            Text("Создайте первый счёт для клиента")
                .font(.system(.subheadline, design: .rounded)).foregroundStyle(FC.muted)
            Button("Создать счёт") { viewModel.showCreateInvoice = true }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(FC.cobalt).clipShape(Capsule())
            Spacer()
        }
    }

    // MARK: Create sheet

    private var createSheet: some View {
        NavigationView {
            ZStack {
                FC.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Number + date
                        formSection("РЕКВИЗИТЫ") {
                            row {
                                Text("Номер").fLabel()
                                Spacer()
                                TextField(viewModel.nextInvoiceNumber, text: $viewModel.newNumber)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(.subheadline, design: .rounded))
                            }
                            Divider()
                            row {
                                Text("Дата").fLabel()
                                Spacer()
                                DatePicker("", selection: $viewModel.newDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            Divider()
                            row {
                                Text("Исполнитель").fLabel()
                                Spacer()
                                TextField("Ваше имя / ИП", text: $viewModel.newExecutorName)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(.subheadline, design: .rounded))
                            }
                        }

                        // Client
                        formSection("КЛИЕНТ") {
                            if viewModel.clients.isEmpty {
                                TextField("Имя клиента", text: $viewModel.newClientName)
                                    .font(.system(.subheadline, design: .rounded))
                                    .padding(.vertical, 4)
                            } else {
                                Picker("Клиент", selection: $viewModel.selectedClientId) {
                                    Text("Не выбрано").tag(UUID?.none)
                                    ForEach(viewModel.clients) { c in
                                        Text(c.name).tag(Optional(c.id))
                                    }
                                }
                            }
                        }

                        // Items
                        formSection("УСЛУГИ") {
                            ForEach($viewModel.newItems) { $item in
                                HStack(spacing: 8) {
                                    TextField("Название", text: $item.name)
                                        .font(.system(.subheadline, design: .rounded))
                                    Spacer()
                                    TextField("0", value: $item.amount, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .frame(width: 90)
                                    Text("₽").foregroundStyle(FC.muted).font(.system(.subheadline))
                                }
                                .padding(.vertical, 4)
                                if $item.id != $viewModel.newItems.last?.id {
                                    Divider()
                                }
                            }
                            Divider()
                            Button {
                                viewModel.newItems.append(InvoiceItem(name: "", amount: 0))
                            } label: {
                                Label("Добавить строку", systemImage: "plus.circle")
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundStyle(FC.cobalt)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }

                        // VAT toggle
                        formSection("НАЛОГ") {
                            HStack {
                                Text("Включить НДС 20%")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(FC.ink)
                                Spacer()
                                SpringToggle(isOn: $viewModel.includeVat)
                            }
                        }

                        // Total
                        HStack {
                            Text("ИТОГО")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(FC.muted)
                            Spacer()
                            Text(viewModel.computedTotal.rub())
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(FC.cobalt)
                        }
                        .padding()
                        .background(FC.cobalt.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Create
                        Button {
                            Task { await viewModel.createInvoice() }
                        } label: {
                            if viewModel.isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Создать счёт")
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(FC.cobalt)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .disabled(viewModel.isSaving)
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Новый счёт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { viewModel.showCreateInvoice = false }
                }
            }
        }
    }

    @ViewBuilder
    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(FC.muted)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            VStack(spacing: 0) { content() }
                .padding(14)
                .background(FC.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(FC.border, lineWidth: 0.5))
        }
    }

    @ViewBuilder
    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { content() }.padding(.vertical, 4)
    }
}

// MARK: - Share Sheet helper

private struct ShareSheet: UIViewControllerRepresentable {
    let data: Data; let filename: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

