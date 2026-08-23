import Foundation

@MainActor
final class LeaderboardStore: ObservableObject {
    @Published private(set) var entries: [LeaderboardEntry] = []
    @Published private(set) var requests: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// Sunucu oturumu geçersiz: kullanıcının yeniden giriş yapması gerekiyor
    @Published var sessionInvalid = false

    private let backend: AppBackend

    init(backend: AppBackend) {
        self.backend = backend
    }

    /// Tablo sekmesi açıldığında: önce kendi skorunu gönder, sonra listeyi çek.
    func refresh(weekAverage: TimeInterval, sessionCount: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if sessionCount > 0 {
                try await backend.submitWeeklyScore(avgSeconds: Int(weekAverage.rounded()),
                                                    sessionCount: sessionCount)
            }
            entries = try await backend.friendsLeaderboard()
            requests = try await backend.pendingRequests()
            errorMessage = nil
        } catch {
            handle(error)
        }
    }

    private func handle(_ error: Error) {
        if case SupabaseClient.ClientError.noSession = error {
            sessionInvalid = true
            errorMessage = nil
        } else {
            errorMessage = error.localizedDescription
        }
    }

    /// Kullanıcı adıyla arayıp istek gönderir.
    func addFriend(username: String) async -> Bool {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !name.isEmpty else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            guard let found = try await backend.findUser(username: name) else {
                errorMessage = L10n.userNotFound
                return false
            }
            try await backend.sendFriendRequest(to: found.userId)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func respond(to entry: LeaderboardEntry, accept: Bool) async {
        do {
            try await backend.respondToRequest(from: entry.userId, accept: accept)
            requests.removeAll { $0.userId == entry.userId }
            if accept { entries = try await backend.friendsLeaderboard() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(_ entry: LeaderboardEntry) async {
        do {
            try await backend.removeFriend(entry.userId)
            entries.removeAll { $0.userId == entry.userId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Engelleme: karşılıklı görünürlüğü keser (App Store 1.2)
    func block(_ entry: LeaderboardEntry) async {
        do {
            try await backend.blockUser(entry.userId)
            entries.removeAll { $0.userId == entry.userId }
            requests.removeAll { $0.userId == entry.userId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Şikayet: moderasyon kaydı açar (App Store 1.2)
    func report(_ entry: LeaderboardEntry, reason: String) async {
        do {
            try await backend.report(userId: entry.userId, reason: reason)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Kullanıcı adlarında açıkça saldırgan ifadeleri engeller.
/// Tam bir moderasyon değil; şikayet ve engelleme mekanizmasıyla birlikte çalışır.
enum ProfanityFilter {
    private static let blocked: [String] = [
        // TR
        "amk", "aq", "orospu", "piç", "yarrak", "sikik", "sik", "göt", "amcık",
        "oruspu", "pezevenk", "gavat", "ibne", "kahpe", "siktir",
        // EN
        "fuck", "shit", "cunt", "bitch", "whore", "slut", "nigger", "nigga",
        "faggot", "rape", "nazi", "hitler", "kys",
        // taklit/kimlik
        "admin", "moderator", "support", "sithappens", "official"
    ]

    static func isClean(_ username: String) -> Bool {
        let normalized = username.lowercased()
            .replacingOccurrences(of: "0", with: "o")
            .replacingOccurrences(of: "1", with: "i")
            .replacingOccurrences(of: "3", with: "e")
            .replacingOccurrences(of: "4", with: "a")
            .replacingOccurrences(of: "5", with: "s")
            .replacingOccurrences(of: "_", with: "")
        return !blocked.contains { normalized.contains($0) }
    }
}
