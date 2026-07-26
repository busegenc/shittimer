# ShitTimer (V1 / MVP)

Tuvalet sayacı — belirli eşiklerde mizahi, kademeli sertleşen yerel bildirimler gönderir.
Çalışma adı **ShitTimer**, mağaza-güvenli alternatif **Sit Happens** (bkz. spec).

## Yapı

| Dosya | İçerik |
|---|---|
| `ShitTimer/ShitTimerApp.swift` | App girişi, bildirim delegate'i (öndeyken banner gösterimi) |
| `ShitTimer/TimerManager.swift` | Start/stop, kalıcı oturum (app kapansa da devam), bildirim zamanlama, istatistik hesapları |
| `ShitTimer/Messages.swift` | 5/10/20/30 dk eşikleri, TR+EN mesaj havuzları (eşik başına 9-10 mesaj), arka arkaya tekrar engeli, arayüz metinleri (L10n) |
| `ShitTimer/Theme.swift` | Üç görsel tema (💩 Kaka / 🕹️ Arcade / 🌸 Pastel): renkler, tipografi, eşik emojileri |
| `ShitTimer/ContentView.swift` | Sayaç ekranı: ilerleme halkası, eşiğe göre sertleşen emoji, ekrandaki laf kartı, tema seçici, büyük buton |
| `ShitTimer/StatsView.swift` | Bugün, hafta toplam/ortalama, oturum sayısı, kişisel rekor, son oturum (tema uyumlu kartlar) |
| `ShitTimer/StoreManager.swift` | StoreKit 2: tema paketi satın alma, hak sahipliği, geri yükleme |
| `ShitTimer/PaywallView.swift` | Kilitli temaya dokununca açılan satın alma ekranı |

## Tema ve satın alma

Ana ekranın üstündeki 💩 / 🕹️ / 🌸 düğmeleriyle anında değişir, seçim `appTheme` anahtarında saklanır. Varsayılan: **poop**.

**💩 Kaka ücretsiz; 🕹️ Arcade ve 🌸 Pastel tek seferlik satın almayla açılır.** Kilitli temanın üstünde 🔒 rozeti var, dokununca [PaywallView](ShitTimer/PaywallView.swift) açılıyor.

- Ürün: `com.busegenc.shittimer.themepack`, **non-consumable** (abonelik değil) — [StoreManager.swift](ShitTimer/StoreManager.swift), StoreKit 2.
- Hak sahipliğinin kaynağı `Transaction.currentEntitlements`; `premiumUnlocked` yalnızca çevrimdışı önbellek. Satın alma iade/iptal edilirse ücretli tema seçili kalmaz, uygulama Kaka'ya döner.
- "Satın Alımları Geri Yükle" düğmesi var (App Store non-consumable ürünlerde zorunlu).
- Yerel test için [ShitTimer.storekit](ShitTimer.storekit) yapılandırması ve onu kullanan paylaşımlı şema hazır — Xcode'dan çalıştırınca gerçek satın alma akışı (fiyat, onay, geri yükleme) sahte mağazayla denenebilir.

**Yayına almadan önce:** App Store Connect'te aynı Product ID ile non-consumable ürünü oluşturup fiyatlandırmak ve `Product.products(for:)`'un gerçek fiyatı çektiğini doğrulamak gerekiyor. `StoreManager.priceText` içindeki `₺79,99 / $1.99` yalnızca DEBUG derlemesinde, mağaza yokken arayüzü görebilmek için duruyor.

Varsayılan temayı değiştirmek için `ContentView`'daki `@AppStorage("appTheme") private var themeRaw = AppTheme.poop.rawValue` satırı yeterli.

Eşik aşıldıkça halkanın ortasındaki emoji sertleşiyor (ör. Kaka teması: 💩 → 🧻 → 😅 → 😰 → ☠️) ve o eşiğin mesajı ekranda kart olarak da beliriyor — bildirimi kaçıran görsün diye.

- **Min iOS:** 16.0 · SwiftUI · veri: UserDefaults (backend yok)
- **Bildirimler:** `UNUserNotificationCenter`, timer başlarken 4 ileri tarihli bildirim zamanlanır; durdurunca iptal edilir. Mesaj seçimi rastgele, son kullanılan indeks saklanarak tekrar engellenir.
- **Dil:** sistem diline göre TR/EN; mesajlar çeviri değil, ayrı yazılmış kültürel karşılıklar.
- **10 sn'den kısa oturumlar** istatistiğe yazılmaz (yanlışlıkla basma koruması).

## Derleme / Çalıştırma

Xcode'da `ShitTimer.xcodeproj` aç → çalıştır. Komut satırından:

```
xcodebuild -project ShitTimer.xcodeproj -target ShitTimer -sdk iphonesimulator \
  -configuration Debug -arch arm64 CODE_SIGNING_ALLOWED=NO SYMROOT=$PWD/build build
xcrun simctl install booted build/Debug-iphonesimulator/ShitTimer.app
xcrun simctl launch booted com.busegenc.shittimer
```

### DEBUG launch argümanları (test/ekran görüntüsü için)
- `--autostart` — açılışta sayacı başlatır
- `--fast-thresholds` — eşikler dakika yerine saniye olur (5/10/20/30 sn)
- `--fake-elapsed=1345` — sayacı geçmişten başlatır (ileri eşikleri görmek için)
- `--theme=poop|arcade|pastel` — açılış teması
- `--tab=stats` — istatistik sekmesiyle açılır
- `--seed-stats` — istatistik ekranı için örnek oturumlar üretir
- `--premium` / `--no-premium` — tema paketini açık/kapalı varsayar
- `--paywall` — açılışta satın alma ekranını gösterir
- `--reset` — tüm kayıtlı veriyi siler

> `xcrun simctl launch` ile verilen argümanlar **sonraki açılışlara da taşınır**. Argümansız test etmek için anlamsız bir argüman (`--noop`) vererek eski listeyi geçersiz kıl.

## App Store'a çıkış

Adım adım rehber: **[APPSTORE.md](APPSTORE.md)**. Yayın için gereken teknik parçalar projede hazır:

- **Uygulama ikonu** — `Assets.xcassets/AppIcon.appiconset/AppIcon.png`, 1024×1024, alfa kanalsız (App Store şartı). Şu anki ikon kahverengi degrade üzerine 💩; yerine tasarlanmış bir görsel koyarsan aynı ada/boyuta sadık kal.
- **Gizlilik manifesti** — [PrivacyInfo.xcprivacy](ShitTimer/PrivacyInfo.xcprivacy): veri toplanmıyor, `UserDefaults` erişimi `CA92.1` gerekçesiyle beyan edildi.
- **Şifreleme beyanı** — `ITSAppUsesNonExemptEncryption = false`, her yüklemede tekrar sorulmaz.
- Hem `-sdk iphonesimulator` hem `-sdk iphoneos` (Release) derlemesi ve şema üzerinden derleme doğrulandı.

Yayına çıkmadan verilecek kararlar: mağaza adı (`ShitTimer` riskli / `Sit Happens` güvenli), IAP fiyatı, 6.9" ekran görüntüleri, destek ve gizlilik politikası URL'leri.

## V1 sonrası (spec'ten)
Karakter/ton seçimi, paylaşılabilir kartlar, Watch, leaderboard, otomatik algılama, freemium.
