import Foundation
import Security

// MARK: - NetworkError

enum NetworkError: LocalizedError {
    case wrongPassword
    case userNotFound
    case emailTaken
    case unauthorized
    case serverError(Int, String?)
    case decodingFailed(Error)
    case noConnection
    case serverUnavailable

    var errorDescription: String? {
        switch self {
        case .wrongPassword:      return "Неверный пароль"
        case .userNotFound:       return "Аккаунт с таким email не найден"
        case .emailTaken:         return "Этот email уже зарегистрирован"
        case .unauthorized:       return "Необходима авторизация"
        case .serverError(let code, let msg):
            return "Ошибка сервера \(code): \(msg ?? "неизвестная ошибка")"
        case .decodingFailed(let e):
            return "Ошибка разбора ответа: \(e.localizedDescription)"
        case .noConnection:       return "Проверь подключение к интернету"
        case .serverUnavailable:  return "Сервер недоступен, попробуйте позже"
        }
    }
}

// MARK: - Keychain

private enum KeychainStore {
    private static let service = "com.finery.app"
    private static let account = "jwt_token"

    static func save(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        delete()
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      account,
            kSecValueData as String:        data,
            kSecAttrAccessible as String:   kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load() -> String? {
        #if DEBUG
        if let debugToken = UserDefaults.standard.string(forKey: "DEBUG_JWT_TOKEN") {
            return debugToken
        }
        #endif
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Private DTOs (snake_case bridged via convertFromSnakeCase)

private struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String
    let taxMode: String
    let userType: String
}

private struct LoginRequest: Encodable {
    let email: String
    let password: String
}

private struct ForgotPasswordRequest: Encodable {
    let email: String
}

private struct ForgotPasswordResponse: Decodable {
    let message: String
}

private struct UpdateProfileRequest: Encodable {
    let name: String
    let taxMode: String
    let userType: String
}

private struct PaginatedTransactionsDTO: Decodable {
    let items: [TransactionDTO]
    let total: Int
    let page: Int
    let pages: Int
}

private struct TokenDTO: Decodable {
    let accessToken: String
    let user: UserDTO
}

private struct UserDTO: Decodable {
    let id: UUID
    let email: String
    let name: String
    let taxMode: String
    let userType: String
    let createdAt: Date

    func toDomain() -> User {
        User(
            id: id,
            name: name,
            taxMode: TaxMode(apiValue: taxMode) ?? .npd,
            userType: UserType(apiValue: userType) ?? .freelancer
        )
    }
}

private struct TransactionRequestDTO: Encodable {
    let amount: String
    let direction: String
    let description: String
    let date: Date
    let source: String
    let incomeCategory: String?
    let expenseCategory: String?
    let clientType: String?
    let clientId: UUID?
    let notes: String?
}

private struct TransactionDTO: Decodable {
    let id: UUID
    let userId: UUID
    let amount: String
    let direction: String
    let description: String
    let date: Date
    let source: String
    let incomeCategory: String?
    let expenseCategory: String?
    let clientType: String?
    let clientId: UUID?
    let notes: String?
    let createdAt: Date

    func toDomain() -> Transaction {
        Transaction(
            id: id,
            amount: Decimal(string: amount) ?? 0,
            direction: TransactionDirection(rawValue: direction) ?? .income,
            description: description,
            date: date,
            source: TransactionSource(apiValue: source),
            incomeCategory: incomeCategory.flatMap { IncomeCategory(apiValue: $0) },
            expenseCategory: expenseCategory.flatMap { ExpenseCategory(apiValue: $0) },
            clientType: clientType.flatMap { ClientType(apiValue: $0) },
            clientId: clientId,
            notes: notes,
            createdAt: createdAt
        )
    }
}

private struct PnLDTO: Decodable {
    let totalIncome: Double
    let totalExpenses: Double
    let taxAmount: Double
    let netProfit: Double
}

private struct TaxStatusDTO: Decodable {
    let totalIncome: Double
    let totalTax: Double
    let limitUsedPercent: Double
    let yearlyLimit: Double
    let remaining: Double
    let isNearLimit: Bool
    let isOverLimit: Bool
    let nextDeadline: String   // "YYYY-MM-DD"
    let daysUntilDeadline: Int
}

private struct ClientDTO: Decodable {
    let id: UUID
    let userId: UUID
    let name: String
    let email: String?
    let phone: String?
    let totalPaid: String
    let lastPayment: Date?
    let status: String
    let notes: String?
    let createdAt: Date

    func toDomain() -> Client {
        Client(
            id: id, name: name, email: email, phone: phone,
            totalPaid: Decimal(string: totalPaid) ?? 0,
            lastPayment: lastPayment,
            status: ClientStatus(rawValue: status) ?? .active,
            notes: notes, createdAt: createdAt
        )
    }
}

private struct InvoiceItemDTO: Decodable { let name: String; let amount: Double }
private struct InvoiceDTO: Decodable {
    let id: UUID; let userId: UUID; let number: String; let date: Date
    let clientId: UUID?; let clientName: String
    let items: [InvoiceItemDTO]; let includeVat: Bool
    let executorName: String; let total: Double; let createdAt: Date

    func toDomain() -> Invoice {
        Invoice(id: id, number: number, date: date, clientId: clientId,
                clientName: clientName,
                items: items.map { InvoiceItem(name: $0.name, amount: Decimal($0.amount)) },
                includeVat: includeVat, executorName: executorName,
                total: Decimal(total), createdAt: createdAt)
    }
}

private struct SeasonalMonthDTO: Decodable {
    let month: Int; let label: String
    let avgIncome: Double; let avgExpense: Double
}
private struct SeasonalMonthInfoDTO: Decodable { let month: Int; let label: String; let diffPct: Int }
private struct SeasonalDTO: Decodable {
    let monthlyAverages: [SeasonalMonthDTO]
    let bestMonth: SeasonalMonthInfoDTO
    let worstMonth: SeasonalMonthInfoDTO
    let currentMonthInsight: String

    func toDomain() -> SeasonalAnalysis {
        SeasonalAnalysis(
            monthlyAverages: monthlyAverages.map {
                MonthlyAverage(month: $0.month, avgIncome: Decimal($0.avgIncome), avgExpense: Decimal($0.avgExpense))
            },
            bestMonth: bestMonth.month,
            worstMonth: worstMonth.month,
            currentMonthInsight: currentMonthInsight,
            bestMonthDiffPct: bestMonth.diffPct,
            worstMonthDiffPct: worstMonth.diffPct
        )
    }
}

// MARK: - API value mappings

private extension TaxMode {
    var apiValue: String {
        switch self {
        case .npd:   "npd"
        case .usn6:  "usn6"
        case .usn15: "usn15"
        }
    }

    init?(apiValue: String) {
        switch apiValue {
        case "npd":   self = .npd
        case "usn6":  self = .usn6
        case "usn15": self = .usn15
        default:      return nil
        }
    }
}

private extension UserType {
    var apiValue: String {
        switch self {
        case .blogger:      "blogger"
        case .freelancer:   "freelancer"
        case .selfEmployed: "self_employed"
        case .other:        "other"
        }
    }

    init?(apiValue: String) {
        switch apiValue {
        case "blogger":       self = .blogger
        case "freelancer":    self = .freelancer
        case "self_employed": self = .selfEmployed
        default:              self = .other
        }
    }
}

private extension ClientType {
    var apiValue: String {
        switch self {
        case .individual: "individual"
        case .legal:      "business"
        }
    }

    init?(apiValue: String) {
        switch apiValue {
        case "individual": self = .individual
        case "business":   self = .legal
        default:           return nil
        }
    }
}

private extension IncomeCategory {
    var apiValue: String {
        switch self {
        case .boosty:      "boosty"
        case .donations:   "donations"
        case .advertising: "advertising"
        case .freelance:   "freelance"
        case .platforms:   "platforms"
        case .education:   "education"
        case .other:       "other"
        }
    }

    init?(apiValue: String) {
        switch apiValue {
        case "boosty":                      self = .boosty
        case "donations":                   self = .donations
        case "advertising":                 self = .advertising
        case "freelance", "services",
             "consulting":                  self = .freelance
        case "platforms", "content",
             "sales":                       self = .platforms
        case "education", "teaching":       self = .education
        default:                            self = .other
        }
    }
}

private extension ExpenseCategory {
    var apiValue: String {
        switch self {
        case .tools:         "tools"
        case .advertising:   "advertising"
        case .equipment:     "equipment"
        case .team:          "team"
        case .food:          "food"
        case .transport:     "transport"
        case .communication: "communication"
        case .other:         "other"
        }
    }

    init?(apiValue: String) {
        switch apiValue {
        case "tools", "software":           self = .tools
        case "advertising", "marketing":    self = .advertising
        case "equipment", "office":         self = .equipment
        case "team", "salary":              self = .team
        case "food":                        self = .food
        case "transport":                   self = .transport
        case "communication":               self = .communication
        default:                            self = .other
        }
    }
}

private extension TransactionSource {
    var apiValue: String {
        switch self {
        case .boosty:         "boosty"
        case .donationAlerts: "donation_alerts"
        case .bank:           "bank"
        case .manual:         "manual"
        case .voice:          "voice"
        }
    }

    init(apiValue: String) {
        switch apiValue {
        case "boosty":          self = .boosty
        case "donation_alerts": self = .donationAlerts
        case "bank":            self = .bank
        case "voice":           self = .voice
        default:                self = .manual
        }
    }
}

// MARK: - APIClient

actor APIClient {
    static let shared = APIClient()

    #if targetEnvironment(simulator)
    private let baseURL = URL(string: "http://127.0.0.1:8000/api/v1")!
    static let baseURLString = "http://127.0.0.1:8000/api/v1"
    #else
    private let baseURL = URL(string: "https://api.finery.pro/api/v1")!
    static let baseURLString = "https://api.finery.pro/api/v1"
    #endif
    private let session: URLSession
    /// In-memory token cache — loaded once at init, updated on login/logout.
    /// Eliminates repeated synchronous Keychain reads on every request.
    private var cachedToken: String?

    nonisolated var isAuthenticated: Bool {
        KeychainStore.load() != nil
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        // Single Keychain read at startup; all subsequent reads use cachedToken.
        cachedToken = KeychainStore.load()
    }

    private func _clearCache() { cachedToken = nil }

    // MARK: Auth

    func register(
        email: String,
        password: String,
        name: String,
        taxMode: TaxMode,
        userType: UserType
    ) async throws -> (token: String, user: User) {
        let body = RegisterRequest(
            email: email, password: password, name: name,
            taxMode: taxMode.apiValue, userType: userType.apiValue
        )
        do {
            let dto: TokenDTO = try await post("auth/register", body: body)
            KeychainStore.save(dto.accessToken)
            cachedToken = dto.accessToken
            return (dto.accessToken, dto.user.toDomain())
        } catch NetworkError.emailTaken {
            throw NetworkError.emailTaken
        } catch NetworkError.unauthorized {
            throw NetworkError.wrongPassword
        }
    }

    func login(email: String, password: String) async throws -> (token: String, user: User) {
        let body = LoginRequest(email: email, password: password)
        do {
            let dto: TokenDTO = try await post("auth/login", body: body)
            KeychainStore.save(dto.accessToken)
            cachedToken = dto.accessToken
            return (dto.accessToken, dto.user.toDomain())
        } catch NetworkError.userNotFound {
            throw NetworkError.userNotFound
        } catch NetworkError.unauthorized {
            throw NetworkError.wrongPassword
        }
    }

    nonisolated func logout() {
        KeychainStore.delete()
        Task { await self._clearCache() }
    }

    func forgotPassword(email: String) async throws -> String {
        let body = ForgotPasswordRequest(email: email)
        let response: ForgotPasswordResponse = try await post("auth/forgot-password", body: body)
        return response.message
    }

    /// Raw health check — returns full error string for debug UI.
    func healthCheckRaw() async -> (ok: Bool, detail: String, ms: Int) {
        guard let url = URL(string: APIClient.baseURLString.replacingOccurrences(of: "/api/v1", with: "/health")) else {
            return (false, "Bad URL", 0)
        }
        let req = URLRequest(url: url, timeoutInterval: 10)
        let start = Date()
        do {
            let (data, resp) = try await session.data(for: req)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            return (code == 200, "HTTP \(code) — \(body)", ms)
        } catch let e as URLError {
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            return (false, "URLError \(e.code.rawValue): \(e.localizedDescription)", ms)
        } catch {
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            return (false, "Error: \(error.localizedDescription)", ms)
        }
    }

    func getCurrentUser() async throws -> User {
        let dto: UserDTO = try await get("auth/me", authorized: true)
        return dto.toDomain()
    }

    func updateProfile(name: String, taxMode: TaxMode, userType: UserType) async throws -> User {
        let body = UpdateProfileRequest(name: name, taxMode: taxMode.apiValue, userType: userType.apiValue)
        let dto: UserDTO = try await put("auth/me", body: body)
        return dto.toDomain()
    }

    // MARK: Transactions

    func createTransaction(_ tx: Transaction) async throws -> Transaction {
        let body = TransactionRequestDTO(
            amount: "\(tx.amount)",
            direction: tx.direction.rawValue,
            description: tx.description,
            date: tx.date,
            source: tx.source.apiValue,
            incomeCategory: tx.incomeCategory?.apiValue,
            expenseCategory: tx.expenseCategory?.apiValue,
            clientType: tx.clientType?.apiValue,
            clientId: tx.clientId,
            notes: tx.notes
        )
        let dto: TransactionDTO = try await post("transactions", body: body, authorized: true)
        return dto.toDomain()
    }

    func getClientTransactions(clientId: UUID) async throws -> [Transaction] {
        let dtos: [TransactionDTO] = try await get("clients/\(clientId.uuidString)/transactions", authorized: true)
        return dtos.map { $0.toDomain() }
    }

    func updateClientTotalPaid(id: UUID, totalPaid: Decimal) async throws -> Client {
        struct Body: Encodable { let totalPaid: String }
        let dto: ClientDTO = try await put("clients/\(id.uuidString)", body: Body(totalPaid: "\(totalPaid)"))
        return dto.toDomain()
    }

    func getTransactions(from: Date? = nil, to: Date? = nil, perPage: Int = 200) async throws -> [Transaction] {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        var query: [String: String] = ["page": "1", "per_page": "\(min(perPage, 500))"]
        if let from { query["from_date"] = fmt.string(from: from) }
        if let to   { query["to_date"]   = fmt.string(from: to) }
        let paginated: PaginatedTransactionsDTO = try await get("transactions", query: query, authorized: true)
        return paginated.items.map { $0.toDomain() }
    }

    func deleteTransaction(id: UUID) async throws {
        try await deleteRequest("transactions/\(id.uuidString)")
    }

    func updateTransaction(
        id: UUID,
        amount: Decimal,
        direction: TransactionDirection,
        description: String,
        date: Date,
        incomeCategory: IncomeCategory?,
        expenseCategory: ExpenseCategory?,
        clientType: ClientType?,
        notes: String?
    ) async throws -> Transaction {
        struct Body: Encodable {
            let amount: String
            let direction: String
            let description: String
            let date: Date
            let incomeCategory: String?
            let expenseCategory: String?
            let clientType: String?
            let notes: String?
        }
        let body = Body(
            amount: "\(amount)",
            direction: direction.rawValue,
            description: description,
            date: date,
            incomeCategory: incomeCategory?.apiValue,
            expenseCategory: expenseCategory?.apiValue,
            clientType: clientType?.apiValue,
            notes: notes
        )
        let dto: TransactionDTO = try await patch("transactions/\(id.uuidString)", body: body, authorized: true)
        return dto.toDomain()
    }

    func updateClient(id: UUID, name: String, phone: String?, status: String, notes: String?) async throws -> Client {
        struct Body: Encodable { let name: String; let phone: String?; let status: String; let notes: String? }
        let dto: ClientDTO = try await put("clients/\(id.uuidString)", body: Body(name: name, phone: phone, status: status, notes: notes))
        return dto.toDomain()
    }

    // MARK: Analytics

    func getPnL(from: Date, to: Date) async throws -> PnL {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        let dto: PnLDTO = try await get(
            "analytics/pnl",
            query: ["from_date": fmt.string(from: from), "to_date": fmt.string(from: to)],
            authorized: true
        )
        return PnL(
            period: DateInterval(start: from, end: to),
            totalIncome: Decimal(dto.totalIncome),
            totalExpenses: Decimal(dto.totalExpenses),
            taxAmount: Decimal(dto.taxAmount)
        )
    }

    // MARK: Tax

    func getTaxStatus(year: Int, taxMode: TaxMode) async throws -> TaxStatus {
        let dto: TaxStatusDTO = try await get(
            "tax/status",
            query: ["year": "\(year)"],
            authorized: true
        )
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .current
        let deadline = df.date(from: dto.nextDeadline) ?? Date()
        let calc = TaxCalculatorService()
        let limit: Decimal = taxMode == .npd ? Decimal(dto.yearlyLimit) : 0
        let nextDL = dto.nextDeadline.isEmpty ? calc.nextDeadline(mode: taxMode) : deadline
        return TaxStatus(
            taxMode:           taxMode,
            yearlyIncome:      Decimal(dto.totalIncome),
            quarterlyIncome:   Decimal(dto.totalIncome),
            quarterlyExpenses: 0,
            taxDue:            Decimal(dto.totalTax),
            taxPaid:           0,
            nextDeadline:      nextDL,
            yearLimit:         limit
        )
    }

    // MARK: Clients

    func getClients() async throws -> [Client] {
        let dtos: [ClientDTO] = try await get("clients", authorized: true)
        return dtos.map { $0.toDomain() }
    }

    func createClient(name: String, email: String?, phone: String?, status: String, notes: String?) async throws -> Client {
        struct Body: Encodable { let name: String; let email: String?; let phone: String?; let status: String; let notes: String? }
        let dto: ClientDTO = try await post("clients", body: Body(name: name, email: email, phone: phone, status: status, notes: notes), authorized: true)
        return dto.toDomain()
    }

    func deleteClient(id: UUID) async throws {
        try await deleteRequest("clients/\(id.uuidString)")
    }

    // MARK: Invoices

    func getInvoices() async throws -> [Invoice] {
        let dtos: [InvoiceDTO] = try await get("invoices", authorized: true)
        return dtos.map { $0.toDomain() }
    }

    func createInvoice(_ invoice: Invoice) async throws -> Invoice {
        struct ItemBody: Encodable { let name: String; let amount: String }
        struct Body: Encodable {
            let number: String; let date: Date; let clientId: UUID?
            let clientName: String; let items: [ItemBody]
            let includeVat: Bool; let executorName: String; let total: String
        }
        let body = Body(
            number: invoice.number, date: invoice.date, clientId: invoice.clientId,
            clientName: invoice.clientName,
            items: invoice.items.map { ItemBody(name: $0.name, amount: "\($0.amount)") },
            includeVat: invoice.includeVat, executorName: invoice.executorName,
            total: "\(invoice.computedTotal)"
        )
        let dto: InvoiceDTO = try await post("invoices", body: body, authorized: true)
        return dto.toDomain()
    }

    // MARK: Seasonal

    func getSeasonalData() async throws -> SeasonalAnalysis {
        let dto: SeasonalDTO = try await get("analytics/seasonal", authorized: true)
        return dto.toDomain()
    }

    // MARK: Private helpers

    func deleteRequest(_ path: String) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "DELETE"
        if let token = cachedToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (_, response): (Data, URLResponse)
        do { (_, response) = try await session.data(for: req) }
        catch { throw NetworkError.noConnection }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0, nil)
        }
    }

    private func put<B: Encodable, R: Decodable>(
        _ path: String,
        body: B,
        authorized: Bool = true
    ) async throws -> R {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authorized, let token = cachedToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try makeEncoder().encode(body)
        return try await execute(req)
    }

    private func patch<B: Encodable, R: Decodable>(
        _ path: String,
        body: B,
        authorized: Bool = true
    ) async throws -> R {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authorized, let token = cachedToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try makeEncoder().encode(body)
        return try await execute(req)
    }

    private func post<B: Encodable, R: Decodable>(
        _ path: String,
        body: B,
        authorized: Bool = false
    ) async throws -> R {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authorized, let token = cachedToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try makeEncoder().encode(body)
        return try await execute(req)
    }

    private func get<R: Decodable>(
        _ path: String,
        query: [String: String] = [:],
        authorized: Bool = false
    ) async throws -> R {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var req = URLRequest(url: components.url!)
        req.httpMethod = "GET"
        if authorized, let token = cachedToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await execute(req)
    }

    // Only retry on transient transport errors. SSL/TLS failures (secureConnectionFailed)
    // are NOT retried — they indicate a handshake problem that won't fix itself in 1 s.
    private static let retryableCodes: Set<URLError.Code> = [
        .timedOut, .networkConnectionLost, .cannotConnectToHost,
    ]

    private func execute<R: Decodable>(_ request: URLRequest, attempt: Int = 0) async throws -> R {
        let method = request.httpMethod ?? "GET"
        let url    = request.url?.absoluteString ?? "?"
        print("[API] \(method) \(url) — attempt \(attempt + 1)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            print("[ERROR DETAIL] URL: \(url)")
            print("[ERROR DETAIL] URLError code: \(urlError.code.rawValue) (\(urlError.code))")
            print("[ERROR DETAIL] localizedDescription: \(urlError.localizedDescription)")
            print("[ERROR DETAIL] Error: \(urlError)")
            if let reason = urlError.failureURLString { print("[ERROR DETAIL] failureURL: \(reason)") }

            // One retry with 0.5 s back-off on transient errors only.
            if Self.retryableCodes.contains(urlError.code), attempt < 1 {
                print("[API] Retrying \(url) after transient error…")
                try await Task.sleep(nanoseconds: 500_000_000)
                return try await execute(request, attempt: attempt + 1)
            }
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw NetworkError.noConnection
            default:
                throw NetworkError.serverUnavailable
            }
        } catch {
            print("[ERROR DETAIL] URL: \(url)")
            print("[ERROR DETAIL] Non-URLError: \(error)")
            print("[ERROR DETAIL] localizedDescription: \(error.localizedDescription)")
            throw NetworkError.serverUnavailable
        }
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.noConnection
        }
        print("[API] \(method) \(url) → \(http.statusCode)")
        switch http.statusCode {
        case 200...299:
            do {
                return try makeDecoder().decode(R.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        case 401, 403:
            // Do NOT delete the token here — that silently breaks isAuthenticated
            // without triggering logout. Token is cleared only in handleSessionExpired().
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.userNotFound
        case 409:
            throw NetworkError.emailTaken
        default:
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
            throw NetworkError.serverError(http.statusCode, msg)
        }
    }

    private func makeEncoder() -> JSONEncoder {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        enc.dateEncodingStrategy = .iso8601
        return enc
    }

    private func makeDecoder() -> JSONDecoder {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        dec.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: str) { return date }
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognised date format: \(str)"
            )
        }
        return dec
    }
}
