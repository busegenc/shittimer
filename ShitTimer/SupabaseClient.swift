import Foundation
import Security

/// Supabase Auth + PostgREST için asgari istemci.
///
/// Hazır SDK yerine URLSession kullanılıyor: ihtiyacımız birkaç uç noktayla
/// sınırlı, böylece projeye paket bağımlılığı girmiyor.
actor SupabaseClient {
    static let shared = SupabaseClient()

    struct Session: Codable {
        let accessToken: String
        let refreshToken: String
        let expiresAt: Date
        let userId: String

        var isExpired: Bool { Date() >= expiresAt.addingTimeInterval(-60) }
    }

    enum ClientError: LocalizedError {
        case notConfigured
        case noSession
        case http(Int, String)
        case decoding

        var errorDescription: String? {
            switch self {
            case .notConfigured: return L10n.serverNotConfigured
            case .noSession: return L10n.sessionExpired
            case .http(let code, _):
                // Sunucudan gelen ham mesaj kullanıcıya gösterilmez; yalnızca
                // benzersizlik çakışması (409) anlamlı bir mesaja çevrilir.
                return code == 409 ? L10n.usernameTaken : L10n.serverError
            case .decoding: return L10n.serverError
            }
        }
    }

    private var session: Session?
    private let keychainKey = "supabase.session"

    private init() {
        session = Keychain.load(keychainKey).flatMap {
            try? JSONDecoder().decode(Session.self, from: $0)
        }
    }

    var isSignedIn: Bool { session != nil }
    var currentUserId: String? { session?.userId }

    // MARK: - Kimlik

    /// Apple'ın kimlik jetonunu Supabase oturumuna çevirir.
    /// `nonce`, Apple isteğinde SHA256'lanmış hâliyle gönderilen ham değerdir.
    func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        let body: [String: Any] = ["provider": "apple", "id_token": idToken, "nonce": nonce]
        let data = try await send(path: "/auth/v1/token",
                                  query: [URLQueryItem(name: "grant_type", value: "id_token")],
                                  method: "POST", body: body, authenticated: false)
        let session = try decodeSession(from: data)
        store(session)
        return session
    }

    func signOut() {
        session = nil
        Keychain.delete(keychainKey)
    }

    private func refreshIfNeeded() async throws {
        guard let current = session else { throw ClientError.noSession }
        guard current.isExpired else { return }
        let data = try await send(path: "/auth/v1/token",
                                  query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
                                  method: "POST", body: ["refresh_token": current.refreshToken],
                                  authenticated: false)
        store(try decodeSession(from: data))
    }

    private func decodeSession(from data: Data) throws -> Session {
        struct Response: Decodable {
            let access_token: String
            let refresh_token: String
            let expires_in: Double
            let user: User
            struct User: Decodable { let id: String }
        }
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            throw ClientError.decoding
        }
        return Session(accessToken: response.access_token,
                       refreshToken: response.refresh_token,
                       expiresAt: Date().addingTimeInterval(response.expires_in),
                       userId: response.user.id)
    }

    private func store(_ newSession: Session) {
        session = newSession
        if let data = try? JSONEncoder().encode(newSession) {
            Keychain.save(data, for: keychainKey)
        }
    }

    // MARK: - Veri

    /// PostgREST çağrısı. Oturum jetonu otomatik yenilenir.
    func rest(path: String,
              query: [URLQueryItem] = [],
              method: String = "GET",
              body: Any? = nil,
              prefer: String? = nil) async throws -> Data {
        try await refreshIfNeeded()
        return try await send(path: "/rest/v1/\(path)", query: query, method: method,
                              body: body, authenticated: true, prefer: prefer)
    }

    // MARK: - Aktarım

    private func send(path: String,
                      query: [URLQueryItem],
                      method: String,
                      body: Any?,
                      authenticated: Bool,
                      prefer: String? = nil) async throws -> Data {
        guard SupabaseConfig.isConfigured, let base = SupabaseConfig.baseURL else {
            throw ClientError.notConfigured
        }
        var components = URLComponents(url: base.appendingPathComponent(path),
                                       resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let prefer { request.setValue(prefer, forHTTPHeaderField: "Prefer") }
        if authenticated {
            guard let token = session?.accessToken else { throw ClientError.noSession }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.decoding }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }
}

/// Oturum jetonları UserDefaults'ta değil Keychain'de saklanır.
enum Keychain {
    static func save(_ data: Data, for key: String) {
        delete(key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
