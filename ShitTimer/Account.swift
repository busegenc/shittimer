import Foundation
import AuthenticationServices

enum AuthProvider: String, Codable {
    case apple, google

    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        }
    }
}

struct Account: Codable, Equatable {
    /// Sağlayıcıdan gelen kalıcı kullanıcı kimliği
    let id: String
    let provider: AuthProvider
    /// Apple e-postayı yalnızca ilk girişte veriyor; gizle seçilirse relay adresi gelir
    var email: String?
    /// Kullanıcının kendi belirlediği ad — tabloda bu görünür
    var username: String?
}

/// Arka uçla konuşan katman. Şu an yerel bir taklit uygulama kullanılıyor;
/// Supabase/Firebase seçimi yapıldığında yalnızca bu protokolün gerçek
/// uygulaması yazılacak, arayüz tarafı değişmeyecek.
protocol AccountBackend {
    func register(id: String, provider: AuthProvider, email: String?) async throws -> Account
    func isUsernameAvailable(_ username: String) async throws -> Bool
    func setUsername(_ username: String, for account: Account) async throws
    func deleteAccount(_ account: Account) async throws
}

enum AccountError: LocalizedError {
    case usernameTaken
    case notConfigured
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .usernameTaken: return L10n.usernameTaken
        case .notConfigured: return L10n.signInNotConfigured
        case .cancelled: return nil
        case .failed(let message): return message
        }
    }
}

/// Geliştirme sırasında kullanılan yerel arka uç: hesabı ve alınmış
/// kullanıcı adlarını cihazda tutar. Gerçek arka uç bağlanınca kaldırılacak.
struct LocalAccountBackend: AccountBackend {
    private let takenKey = "takenUsernames"

    func register(id: String, provider: AuthProvider, email: String?) async throws -> Account {
        Account(id: id, provider: provider, email: email, username: nil)
    }

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let taken = UserDefaults.standard.stringArray(forKey: takenKey) ?? []
        return !taken.contains(username.lowercased())
    }

    func setUsername(_ username: String, for account: Account) async throws {
        var taken = UserDefaults.standard.stringArray(forKey: takenKey) ?? []
        taken.append(username.lowercased())
        UserDefaults.standard.set(taken, forKey: takenKey)
    }

    func deleteAccount(_ account: Account) async throws {
        guard let username = account.username else { return }
        var taken = UserDefaults.standard.stringArray(forKey: takenKey) ?? []
        taken.removeAll { $0 == username.lowercased() }
        UserDefaults.standard.set(taken, forKey: takenKey)
    }
}

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var account: Account?
    @Published var isWorking = false
    @Published var errorMessage: String?

    private let backend: AccountBackend
    private let defaults = UserDefaults.standard
    private let accountKey = "account"

    var isSignedIn: Bool { account != nil }
    var needsUsername: Bool { account != nil && account?.username == nil }

    init(backend: AccountBackend = LocalAccountBackend()) {
        self.backend = backend
        if let data = defaults.data(forKey: accountKey),
           let decoded = try? JSONDecoder().decode(Account.self, from: data) {
            account = decoded
        }
        #if DEBUG
        if CommandLine.arguments.contains("--signed-out") { signOut() }
        if CommandLine.arguments.contains("--needs-username") {
            account = Account(id: "debug", provider: .apple, email: nil, username: nil)
        }
        if CommandLine.arguments.contains("--signed-in") {
            account = Account(id: "debug", provider: .apple, email: nil, username: "buse")
        }
        #endif
    }

    // MARK: - Giriş

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = AccountError.failed("Beklenmeyen kimlik türü").errorDescription
                return
            }
            await register(id: credential.user, provider: .apple, email: credential.email)
        case .failure(let error):
            // Kullanıcı vazgeçtiyse hata gösterme
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Google girişi, arka uç seçildikten sonra bağlanacak (GoogleSignIn SDK + istemci kimliği).
    func signInWithGoogle() async {
        errorMessage = AccountError.notConfigured.errorDescription
    }

    private func register(id: String, provider: AuthProvider, email: String?) async {
        isWorking = true
        defer { isWorking = false }
        do {
            account = try await backend.register(id: id, provider: provider, email: email)
            persist()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Kullanıcı adı

    /// 3-16 karakter, küçük harf/rakam/alt çizgi. Tabloda herkese görüneceği için sade tutuluyor.
    static func validate(username: String) -> Bool {
        let pattern = "^[a-z0-9_]{3,16}$"
        return username.range(of: pattern, options: .regularExpression) != nil
    }

    func claimUsername(_ raw: String) async -> Bool {
        let username = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Self.validate(username: username) else {
            errorMessage = L10n.usernameRules
            return false
        }
        guard var account else { return false }
        isWorking = true
        defer { isWorking = false }
        do {
            guard try await backend.isUsernameAvailable(username) else {
                errorMessage = AccountError.usernameTaken.errorDescription
                return false
            }
            try await backend.setUsername(username, for: account)
            account.username = username
            self.account = account
            persist()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Hesap yönetimi

    func signOut() {
        account = nil
        defaults.removeObject(forKey: accountKey)
    }

    /// App Store kuralı 5.1.1(v): hesap oluşturan uygulamalar uygulama içinden
    /// hesap silme imkânı sunmak zorunda.
    func deleteAccount() async {
        guard let account else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await backend.deleteAccount(account)
            signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persist() {
        guard let account, let data = try? JSONEncoder().encode(account) else { return }
        defaults.set(data, forKey: accountKey)
    }
}
