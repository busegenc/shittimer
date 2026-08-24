import ActivityKit
import Foundation

/// Kilit ekranı / Dynamic Island canlı sayacının veri sözleşmesi.
///
/// Bu dosya ana uygulama VE widget extension hedeflerinin ikisinde de
/// birebir aynı içerikle bulunur (Xcode'un klasör-bazlı hedef eşleştirmesi
/// yüzünden tek dosyayı iki hedefe birden bağlamak yerine kopyalandı — tip
/// küçük ve dışa bağımlılığı yok, değiştirirsen iki dosyayı da güncelle).
struct SitHappensActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Oturumun başladığı an — kilit ekranındaki sayaç bundan itibaren
        /// sistem tarafından canlı sayılır, uygulamanın her saniye güncelleme
        /// göndermesi gerekmez.
        var startDate: Date
        /// 0...4 — TimerManager.stage ile aynı ölçek
        var stage: Int
    }
}
