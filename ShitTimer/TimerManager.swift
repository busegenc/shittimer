import Foundation
import UserNotifications
import SwiftUI

/// Oturum kaydı — istatistikler için UserDefaults'ta JSON olarak saklanır.
struct Session: Codable, Identifiable {
    var id = UUID()
    let startedAt: Date
    let duration: TimeInterval
}

@MainActor
final class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var elapsed: TimeInterval = 0
    @Published var sessions: [Session] = []
    @Published var notificationsDenied = false
    /// Eşik aşıldığında ekranda gösterilen laf (bildirimin uygulama içi karşılığı)
    @Published var currentTaunt: String?
    /// Sayaç akıl sağlığı sınırını (bkz. sanityCapSeconds) aşınca bir kez true olur;
    /// arayüz bunu gösterip kullanıcı kapatınca false'a döner.
    @Published var autoEndedNotice = false

    private var lastStageShown = 0
    private var startDate: Date?
    private var ticker: Timer?
    private let defaults = UserDefaults.standard
    private let sessionsKey = "sessions"
    private let activeStartKey = "activeSessionStart"

    init() {
        #if DEBUG
        if CommandLine.arguments.contains("--reset") {
            defaults.removeObject(forKey: sessionsKey)
            defaults.removeObject(forKey: activeStartKey)
        }
        #endif
        loadSessions()
        #if DEBUG
        if CommandLine.arguments.contains("--seed-stats"), sessions.isEmpty {
            let now = Date()
            sessions = [(-1.0, 480.0), (-1.0, 940.0), (-2.0, 1260.0), (-3.0, 620.0), (0.0, 1150.0), (0.0, 380.0)]
                .map { Session(startedAt: now.addingTimeInterval($0.0 * 86_400), duration: $0.1) }
            saveSessions()
        }
        #endif
        // Uygulama kapansa bile aktif oturum kaldığı yerden devam eder
        if let saved = defaults.object(forKey: activeStartKey) as? Date {
            startDate = saved
            isRunning = true
            elapsed = Date().timeIntervalSince(saved)
            if !abandonIfPastSanityCap() {
                startTicker()
                if #available(iOS 16.2, *) {
                    LiveActivityManager.adoptExistingOrStart(startDate: saved, stage: stage)
                }
            }
        }
        #if DEBUG
        if CommandLine.arguments.contains("--autostart"), !isRunning {
            toggle()
        }
        if CommandLine.arguments.contains("--force-autoended") {
            DispatchQueue.main.async { [weak self] in self?.autoEndedNotice = true }
        }
        #endif
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    private func start() {
        var now = Date()
        #if DEBUG
        // Ekran görüntüsü/test için sayacı geçmişten başlatır: --fake-elapsed=1320
        if let arg = CommandLine.arguments.first(where: { $0.hasPrefix("--fake-elapsed=") }),
           let value = Double(arg.dropFirst("--fake-elapsed=".count)) {
            now = now.addingTimeInterval(-value)
        }
        #endif
        lastStageShown = 0
        currentTaunt = nil
        startDate = now
        defaults.set(now, forKey: activeStartKey)
        elapsed = Date().timeIntervalSince(now)
        isRunning = true
        startTicker()
        requestPermissionAndSchedule()
        if #available(iOS 16.2, *) { LiveActivityManager.start(startDate: now) }
    }

    private func stop() {
        guard let startDate else { return }
        let duration = Date().timeIntervalSince(startDate)
        ticker?.invalidate()
        ticker = nil
        isRunning = false
        self.startDate = nil
        defaults.removeObject(forKey: activeStartKey)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        if #available(iOS 16.2, *) { LiveActivityManager.end() }

        // 10 saniyeden kısa oturumları kaydetme (yanlışlıkla basılma)
        if duration >= 10 {
            sessions.append(Session(startedAt: startDate, duration: duration))
            saveSessions()
        }
        elapsed = 0
        currentTaunt = nil
        lastStageShown = 0
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startDate = self.startDate else { return }
                self.elapsed = Date().timeIntervalSince(startDate)
                if self.abandonIfPastSanityCap() { return }
                self.refreshTauntIfNeeded()
            }
        }
    }

    // MARK: - Akıl sağlığı sınırı

    #if DEBUG
    private var sanityCapSeconds: TimeInterval {
        CommandLine.arguments.contains("--fast-thresholds") ? 90 : 2 * 3600
    }
    private var nagIntervalSeconds: TimeInterval {
        CommandLine.arguments.contains("--fast-thresholds") ? 8 : 20 * 60
    }
    #else
    private let sanityCapSeconds: TimeInterval = 2 * 3600
    private let nagIntervalSeconds: TimeInterval = 20 * 60
    #endif

    /// 30 dakika eşiğinden `sanityCapSeconds`e kadar, `nagIntervalSeconds`
    /// aralıklarla tekrarlanan hatırlatma zamanları.
    private var nagOffsetsSeconds: [TimeInterval] {
        var offset = Threshold.thirtyMin.seconds + nagIntervalSeconds
        var offsets: [TimeInterval] = []
        while offset < sanityCapSeconds {
            offsets.append(offset)
            offset += nagIntervalSeconds
        }
        return offsets
    }

    /// Sayaç sınırı aştıysa oturumu istatistiklere eklemeden sonlandırır.
    /// Kullanıcı unutup gitmiş bir sayacın kalıcı olarak istatistikleri
    /// bozmasını engeller. `true` dönerse oturum artık çalışmıyor demektir.
    @discardableResult
    private func abandonIfPastSanityCap() -> Bool {
        guard isRunning, elapsed >= sanityCapSeconds else { return false }
        ticker?.invalidate()
        ticker = nil
        isRunning = false
        startDate = nil
        defaults.removeObject(forKey: activeStartKey)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        if #available(iOS 16.2, *) { LiveActivityManager.end() }
        elapsed = 0
        currentTaunt = nil
        lastStageShown = 0
        // SwiftUI'nin .alert'i, ilk render'dan önce zaten true olan bir değeri
        // güvenilir göstermeyebiliyor (false→true geçişi bekliyor). init()
        // içinden tetiklendiğinde (uygulama saatler sonra yeniden açıldığında)
        // görünüm henüz yokken bu satır çalışır; bir sonraki run loop turuna
        // erteleyerek her durumda gerçek bir geçiş sağlanır.
        DispatchQueue.main.async { [weak self] in self?.autoEndedNotice = true }
        return true
    }

    // MARK: - Eşik durumu

    /// Aşılan eşik sayısı: 0 (henüz 5 dk yok) … 4 (30+ dk)
    var stage: Int {
        Threshold.allCases.filter { elapsed >= $0.seconds }.count
    }

    /// Bir sonraki eşiğe ilerleme (0…1). Son eşikten sonra 30→60 dk aralığına yayılır.
    var progress: Double {
        let marks = Threshold.allCases.map(\.seconds)
        let s = stage
        let lower = s == 0 ? 0 : marks[s - 1]
        let upper = s < marks.count ? marks[s] : marks[marks.count - 1] * 2
        guard upper > lower else { return 1 }
        return min(1, max(0, (elapsed - lower) / (upper - lower)))
    }

    private func refreshTauntIfNeeded() {
        let s = stage
        guard s != lastStageShown else { return }
        lastStageShown = s
        currentTaunt = s > 0 ? MessagePool.nextMessage(for: Threshold.allCases[s - 1]) : nil
        if #available(iOS 16.2, *), let startDate {
            LiveActivityManager.update(stage: s, startDate: startDate)
        }
    }

    // MARK: - Bildirimler

    private func requestPermissionAndSchedule() {
        #if DEBUG
        // Pazarlama ekran görüntülerinde izin diyaloğu araya girmesin
        if CommandLine.arguments.contains("--marketing") { return }
        #endif
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.notificationsDenied = !granted
                if granted { self?.scheduleNotifications() }
            }
        }
    }

    /// Dil değiştiğinde çağrılır: zaten zamanlanmış bildirimler eski dilde
    /// kalmasın diye kalan eşikler yeniden yazılır.
    func rescheduleNotifications() {
        guard isRunning, !notificationsDenied else { return }
        scheduleNotifications()
    }

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for threshold in Threshold.allCases {
            // Geçmiş eşikler yeniden zamanlanmaz
            let remaining = threshold.seconds - elapsed
            guard remaining > 0 else { continue }
            schedule(id: "threshold-\(threshold.rawValue)", after: remaining,
                    body: MessagePool.nextMessage(for: threshold))
        }

        // 30 dakikadan sonra sayaç açık unutulursa sessizliğe düşülmesin diye
        // sınıra kadar tekrarlayan hatırlatmalar
        for (index, offset) in nagOffsetsSeconds.enumerated() {
            let remaining = offset - elapsed
            guard remaining > 0 else { continue }
            schedule(id: "nag-\(index)", after: remaining, body: MessagePool.nextNagMessage())
        }

        // Sınıra ulaşınca: oturum otomatik sonlanacağını haber ver
        let capRemaining = sanityCapSeconds - elapsed
        if capRemaining > 0 {
            schedule(id: "cap-notice", after: capRemaining, body: L10n.capNoticeMessage)
        }
    }

    private func schedule(id: String, after interval: TimeInterval, body: String) {
        let content = UNMutableNotificationContent()
        content.title = L10n.appTitle
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(id: id, content: content, trigger: trigger))
    }

    // MARK: - İstatistikler

    var todayTotal: TimeInterval {
        sessions.filter { Calendar.current.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.duration }
    }

    private var thisWeekSessions: [Session] {
        guard let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        return sessions.filter { $0.startedAt >= weekStart }
    }

    var weekTotal: TimeInterval {
        thisWeekSessions.reduce(0) { $0 + $1.duration }
    }

    var weekAverage: TimeInterval {
        let s = thisWeekSessions
        return s.isEmpty ? 0 : weekTotal / Double(s.count)
    }

    var weekCount: Int { thisWeekSessions.count }

    var personalRecord: TimeInterval {
        sessions.map(\.duration).max() ?? 0
    }

    var lastSession: Session? { sessions.last }

    private func loadSessions() {
        guard let data = defaults.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([Session].self, from: data) else { return }
        sessions = decoded
    }

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            defaults.set(data, forKey: sessionsKey)
        }
    }
}

private extension UNNotificationRequest {
    convenience init(id: String, content: UNNotificationContent, trigger: UNNotificationTrigger) {
        self.init(identifier: id, content: content, trigger: trigger)
    }
}
