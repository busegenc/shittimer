import Foundation

/// Tabloda görünen bir satır.
struct LeaderboardEntry: Codable, Identifiable, Equatable {
    let userId: String
    let username: String
    let avgSeconds: Int
    let sessionCount: Int

    var id: String { userId }
    var average: TimeInterval { TimeInterval(avgSeconds) }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case avgSeconds = "avg_seconds"
        case sessionCount = "session_count"
    }
}

/// Arkadaş listesi ve tablo işlemleri.
protocol LeaderboardBackend {
    func submitWeeklyScore(avgSeconds: Int, sessionCount: Int) async throws
    func friendsLeaderboard() async throws -> [LeaderboardEntry]
    func findUser(username: String) async throws -> LeaderboardEntry?
    func sendFriendRequest(to userId: String) async throws
    func respondToRequest(from userId: String, accept: Bool) async throws
    func pendingRequests() async throws -> [LeaderboardEntry]
    func removeFriend(_ userId: String) async throws
    func blockUser(_ userId: String) async throws
    func report(userId: String, reason: String) async throws
}

typealias AppBackend = AccountBackend & LeaderboardBackend

// MARK: - Supabase

struct SupabaseBackend: AppBackend {
    private let client = SupabaseClient.shared
    private let decoder = JSONDecoder()

    /// Haftanın başlangıcı (pazartesi), sunucudaki `week_start` ile aynı olmalı
    private var weekStart: String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: start)
    }

    // MARK: AccountBackend

    /// Apple girişi Supabase oturumuna çevrilir; profil satırı ilk girişte oluşur.
    func register(id: String, provider: AuthProvider) async throws -> Account {
        guard let userId = await client.currentUserId else { throw SupabaseClient.ClientError.noSession }
        let existingUsername = try await username(forUserId: userId)
        return Account(id: userId, provider: provider, username: existingUsername)
    }

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let data = try await client.rest(path: "profiles", query: [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "username", value: "eq.\(username)"),
            URLQueryItem(name: "limit", value: "1")
        ])
        let rows = try decoder.decode([[String: String]].self, from: data)
        return rows.isEmpty
    }

    func setUsername(_ username: String, for account: Account) async throws {
        _ = try await client.rest(path: "profiles", method: "POST",
                                  body: [["id": account.id, "username": username]],
                                  prefer: "resolution=merge-duplicates")
    }

    func deleteAccount(_ account: Account) async throws {
        // profiles satırı silinince skorlar ve arkadaşlıklar cascade ile gider
        _ = try await client.rest(path: "profiles",
                                  query: [URLQueryItem(name: "id", value: "eq.\(account.id)")],
                                  method: "DELETE")
        await client.signOut()
    }

    /// Profil satırı yoksa nil döner — kullanıcı adı ekranı bu durumda açılır.
    private func username(forUserId userId: String) async throws -> String? {
        let data = try await client.rest(path: "profiles", query: [
            URLQueryItem(name: "select", value: "username"),
            URLQueryItem(name: "id", value: "eq.\(userId)"),
            URLQueryItem(name: "limit", value: "1")
        ])
        let rows = try decoder.decode([[String: String]].self, from: data)
        return rows.first?["username"]
    }

    // MARK: LeaderboardBackend

    func submitWeeklyScore(avgSeconds: Int, sessionCount: Int) async throws {
        guard let userId = await client.currentUserId else { throw SupabaseClient.ClientError.noSession }
        _ = try await client.rest(path: "weekly_scores", method: "POST", body: [[
            "user_id": userId,
            "week_start": weekStart,
            "avg_seconds": avgSeconds,
            "session_count": sessionCount
        ]], prefer: "resolution=merge-duplicates")
    }

    /// Sunucudaki `friends_leaderboard` görünümü: kabul edilmiş arkadaşlar + kendisi
    func friendsLeaderboard() async throws -> [LeaderboardEntry] {
        let data = try await client.rest(path: "friends_leaderboard", query: [
            URLQueryItem(name: "select", value: "user_id,username,avg_seconds,session_count"),
            URLQueryItem(name: "week_start", value: "eq.\(weekStart)"),
            URLQueryItem(name: "order", value: "avg_seconds.asc")
        ])
        return try decoder.decode([LeaderboardEntry].self, from: data)
    }

    func findUser(username: String) async throws -> LeaderboardEntry? {
        let data = try await client.rest(path: "profiles", query: [
            URLQueryItem(name: "select", value: "id,username"),
            URLQueryItem(name: "username", value: "eq.\(username.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ])
        let rows = try decoder.decode([[String: String]].self, from: data)
        guard let row = rows.first, let id = row["id"], let name = row["username"] else { return nil }
        return LeaderboardEntry(userId: id, username: name, avgSeconds: 0, sessionCount: 0)
    }

    func sendFriendRequest(to userId: String) async throws {
        guard let me = await client.currentUserId else { throw SupabaseClient.ClientError.noSession }
        _ = try await client.rest(path: "friendships", method: "POST", body: [[
            "requester": me, "addressee": userId, "status": "pending"
        ]], prefer: "resolution=merge-duplicates")
    }

    func respondToRequest(from userId: String, accept: Bool) async throws {
        guard let me = await client.currentUserId else { throw SupabaseClient.ClientError.noSession }
        if accept {
            _ = try await client.rest(path: "friendships", query: [
                URLQueryItem(name: "requester", value: "eq.\(userId)"),
                URLQueryItem(name: "addressee", value: "eq.\(me)")
            ], method: "PATCH", body: ["status": "accepted"])
        } else {
            _ = try await client.rest(path: "friendships", query: [
                URLQueryItem(name: "requester", value: "eq.\(userId)"),
                URLQueryItem(name: "addressee", value: "eq.\(me)")
            ], method: "DELETE")
        }
    }

    func pendingRequests() async throws -> [LeaderboardEntry] {
        let data = try await client.rest(path: "pending_requests", query: [
            URLQueryItem(name: "select", value: "user_id,username,avg_seconds,session_count")
        ])
        return try decoder.decode([LeaderboardEntry].self, from: data)
    }

    func removeFriend(_ userId: String) async throws {
        guard let me = await client.currentUserId else { throw SupabaseClient.ClientError.noSession }
        _ = try await client.rest(path: "friendships", query: [
            URLQueryItem(name: "or", value: "(and(requester.eq.\(me),addressee.eq.\(userId)),and(requester.eq.\(userId),addressee.eq.\(me)))")
        ], method: "DELETE")
    }

    /// Engelleme: karşılıklı görünürlüğü keser (1.2 gereği)
    func blockUser(_ userId: String) async throws {
        guard let me = await client.currentUserId else { throw SupabaseClient.ClientError.noSession }
        _ = try await client.rest(path: "friendships", method: "POST", body: [[
            "requester": me, "addressee": userId, "status": "blocked"
        ]], prefer: "resolution=merge-duplicates")
    }

    /// Şikayet: moderasyon için kayıt açar (1.2 gereği)
    func report(userId: String, reason: String) async throws {
        guard let me = await client.currentUserId else { throw SupabaseClient.ClientError.noSession }
        _ = try await client.rest(path: "reports", method: "POST", body: [[
            "reporter": me, "reported": userId, "reason": reason
        ]])
    }
}

// MARK: - Yerel (geliştirme)

extension LocalAccountBackend: LeaderboardBackend {
    func submitWeeklyScore(avgSeconds: Int, sessionCount: Int) async throws {}
    func friendsLeaderboard() async throws -> [LeaderboardEntry] { [] }
    func findUser(username: String) async throws -> LeaderboardEntry? { nil }
    func sendFriendRequest(to userId: String) async throws { throw AccountError.notConfigured }
    func respondToRequest(from userId: String, accept: Bool) async throws {}
    func pendingRequests() async throws -> [LeaderboardEntry] { [] }
    func removeFriend(_ userId: String) async throws {}
    func blockUser(_ userId: String) async throws {}
    func report(userId: String, reason: String) async throws {}
}
