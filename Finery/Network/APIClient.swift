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
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String:   data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load() -> String? {
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
    let amount: String        // sent as string to preserve Decimal precision
    let direction: String
    let description: String
    let date: Date
    let source: String
    let incomeCategory: String?
    let expenseCategory: String?
    let clientType: String?
    let notes: String?
}

private struct TransactionDTO: Decodable {
    let id: UUID
    let userId: UUID
    let amount: String        // backend serialises Decimal as string
    let direction: String
    let description: String
    let date: Date
    let source: String
    let incomeCategory: String?
    let expenseCategory: String?
    let clientType: String?
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
    private let baseURL = URL(string: "http://localhost:8000")!
    #else
    private let baseURL = URL(string: "http://10.192.204.89:8000")!
    #endif
    private let session: URLSession

    nonisolated var isAuthenticated: Bool {
        KeychainStore.load() != nil
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }

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
            let dto: TokenDTO = try await post("api/v1/auth/register", body: body)
            KeychainStore.save(dto.accessToken)
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
            let dto: TokenDTO = try await post("api/v1/auth/login", body: body)
            KeychainStore.save(dto.accessToken)
            return (dto.accessToken, dto.user.toDomain())
        } catch NetworkError.userNotFound {
            throw NetworkError.userNotFound
        } catch NetworkError.unauthorized {
            throw NetworkError.wrongPassword
        }
    }

    nonisolated func logout() {
        KeychainStore.delete()
    }

    func forgotPassword(email: String) async throws -> String {
        let body = ForgotPasswordRequest(email: email)
        let response: ForgotPasswordResponse = try await post("api/v1/auth/forgot-password", body: body)
        return response.message
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
            notes: tx.notes
        )
        let dto: TransactionDTO = try await post("api/v1/transactions", body: body, authorized: true)
        return dto.toDomain()
    }

    func getTransactions(from: Date? = nil, to: Date? = nil, limit: Int = 200) async throws -> [Transaction] {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        var query: [String: String] = ["limit": "\(limit)"]
        if let from { query["from_date"] = fmt.string(from: from) }
        if let to   { query["to_date"]   = fmt.string(from: to) }
        let dtos: [TransactionDTO] = try await get("api/v1/transactions", query: query, authorized: true)
        return dtos.map { $0.toDomain() }
    }

    func deleteTransaction(id: UUID) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/v1/transactions/\(id.uuidString)"))
        req.httpMethod = "DELETE"
        if let token = KeychainStore.load() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: req)
        } catch {
            throw NetworkError.noConnection
        }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.serverError(code, nil)
        }
    }

    // MARK: Analytics

    func getPnL(from: Date, to: Date) async throws -> PnL {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        let dto: PnLDTO = try await get(
            "api/v1/analytics/pnl",
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
            "api/v1/tax/status",
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

    // MARK: Private helpers

    private func post<B: Encodable, R: Decodable>(
        _ path: String,
        body: B,
        authorized: Bool = false
    ) async throws -> R {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authorized, let token = KeychainStore.load() {
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
        if authorized, let token = KeychainStore.load() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await execute(req)
    }

    private func execute<R: Decodable>(_ request: URLRequest) async throws -> R {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw NetworkError.noConnection
            default:
                throw NetworkError.serverUnavailable
            }
        } catch {
            throw NetworkError.serverUnavailable
        }
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.noConnection
        }
        switch http.statusCode {
        case 200...299:
            do {
                return try makeDecoder().decode(R.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        case 401, 403:
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
