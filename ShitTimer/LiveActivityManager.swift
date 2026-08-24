import Foundation
import ActivityKit

/// Sayaç çalışırken kilit ekranında ve Dynamic Island'da canlı gösterim.
/// iOS 16.2 altında hiç kullanılmaz; çağıran taraf `if #available` ile korur.
@available(iOS 16.2, *)
enum LiveActivityManager {
    private static var activity: Activity<SitHappensActivityAttributes>?

    static func start(startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endAll()
        let state = SitHappensActivityAttributes.ContentState(startDate: startDate, stage: 0)
        activity = try? Activity.request(
            attributes: SitHappensActivityAttributes(),
            content: .init(state: state, staleDate: nil))
    }

    /// Yalnızca eşik (stage) değiştiğinde çağrılır — elapsed her saniye
    /// gönderilmiyor, kilit ekranındaki sayaç sistemin kendisi tarafından
    /// startDate'ten itibaren canlı sayılıyor.
    static func update(stage: Int, startDate: Date) {
        guard let activity else { return }
        let state = SitHappensActivityAttributes.ContentState(startDate: startDate, stage: stage)
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    static func end() {
        endAll()
        activity = nil
    }

    /// Uygulama, oturum çalışırken kapanıp yeniden açıldığında çağrılır.
    /// Live Activity uygulama süreci olmadan da sistemde yaşamaya devam eder;
    /// burada onu yeniden oluşturmak yerine devralıyoruz — aksi halde kilit
    /// ekranındaki kart bir an kaybolup yenisiyle değişir.
    static func adoptExistingOrStart(startDate: Date, stage: Int) {
        if let existing = Activity<SitHappensActivityAttributes>.activities.first {
            activity = existing
            update(stage: stage, startDate: startDate)
        } else {
            start(startDate: startDate)
        }
    }

    /// Yalnızca bu süreçte tutulan referansı değil, önceki bir süreçten kalmış
    /// (uygulama oturum ortasında uygulama değiştiriciden kapatılmışsa oluşan)
    /// tüm etkinlikleri kapatır. `start()`in başında çağrılmazsa eski bir
    /// oturumdan kalan kart Dynamic Island'da asılı kalabilir.
    private static func endAll() {
        for existing in Activity<SitHappensActivityAttributes>.activities {
            Task { await existing.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
