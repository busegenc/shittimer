import Foundation

/// Bildirim eşikleri (dakika) ve her eşik için TR/EN mesaj havuzları.
/// Mesajlar çeviri değil, ayrı yazılmış kültürel karşılıklar.
enum Threshold: Int, CaseIterable, Codable {
    case fiveMin = 5
    case tenMin = 10
    case twentyMin = 20
    case thirtyMin = 30

    var seconds: TimeInterval {
        #if DEBUG
        // UI testi için: --fast-thresholds ile eşikler dakika yerine saniye olur
        if CommandLine.arguments.contains("--fast-thresholds") {
            return TimeInterval(rawValue)
        }
        #endif
        return TimeInterval(rawValue * 60)
    }
}

/// Uygulama dili. Varsayılan cihaz dili; kullanıcı Ayarlar'dan sabitleyebilir.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, turkish, english

    static let storageKey = "appLanguage"
    var id: String { rawValue }

    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .system
    }

    /// Seçenekler kendi dillerinde yazılır; sistem seçeneği arayüz diline uyar.
    var displayName: String {
        switch self {
        case .system: return MessagePool.isTurkish ? "Sistem dili" : "System language"
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
}

enum MessagePool {
    static var isTurkish: Bool {
        switch AppLanguage.current {
        case .turkish: return true
        case .english: return false
        case .system: return Locale.preferredLanguages.first?.hasPrefix("tr") ?? false
        }
    }

    private static let tr: [Threshold: [String]] = [
        .fiveMin: [
            "Hâlâ mı? Telefonu mu düşürdün?",
            "5 dakika oldu, her şey yolunda mı?",
            "Scroll etmeyi bırak, işini bitir.",
            "Bu arada dışarıda sıra oluşmadı, merak etme.",
            "5 dakika... klasik giriş süresi. Devam.",
            "Rahat ol ama unutma, hayat dışarıda devam ediyor.",
            "Kısa bir ziyaret olacaktı hani?",
            "Instagram'ın sonuna gelemezsin, biliyorsun değil mi?",
            "Kapı çalınmadan çıkmak ister misin?",
            "İlk 5 dakika doldu. Isınma turları bitti mi?"
        ],
        .tenMin: [
            "Bu bir toplantı değil.",
            "10 dakika... bir dizi bölümü kadar oldu.",
            "Bacakların hâlâ hissediyor mu?",
            "İçeride Wi-Fi mi kurdun?",
            "10 dakika oldu, telefonun şarjı bitmesin.",
            "Sanki orada yaşamaya karar verdin.",
            "Ev halkı endişelenmeye başladı.",
            "Klozet seni sahiplenmeden kalk bence.",
            "Bir işi 10 dakikada bitiremiyorsan o iş sen demektir."
        ],
        .twentyMin: [
            "Bacakların uyuştu mu bari?",
            "20 dakika oldu, bu artık bir yaşam tarzı.",
            "Dışarıda insanlar seni merak etmeye başladı.",
            "Bu süre bir film izlemeye yeter de artar.",
            "İçeride her şey yolunda mı, yoksa keşif mi yapıyorsun?",
            "20 dakika, resmî olarak 'uzun mola' kategorisine girdin.",
            "Artık orada oturmuyorsun, ikamet ediyorsun.",
            "Nüfus kağıdına yeni adres mi yazdıralım?",
            "Bu noktadan sonra çıkışın ayakta alkışlanması lazım.",
            "Arama ekibi kurma aşamasına geldik."
        ],
        .thirtyMin: [
            "20 dakikadan uzun oturmak gerçekten hemoroid riskini artırıyor, çık artık 😅",
            "30+ dakika oldu, bu artık sağlık uyarısı seviyesinde.",
            "Bacaklarını biraz hareket ettir, uzun oturmak iyi değil.",
            "Tamam, gerçekten merak etmeye başladık.",
            "Bu kadar uzun oturmak sırt ve bacaklar için pek iyi değil.",
            "Çıkma vakti geldi, sağlığın için mola ver artık.",
            "Yarım saat oldu. Bu artık mola değil, yaşam tarzı. Kalk biraz yürü 🚶",
            "Bacakların sana küstü. Barışmak için ayağa kalkman gerekiyor.",
            "Telefonu bırak, sifonu çek, hayata dön. Bu bir sağlık duyurusudur."
        ]
    ]

    private static let en: [Threshold: [String]] = [
        .fiveMin: [
            "Still going? Did you drop the phone?",
            "5 minutes in — everything okay in there?",
            "Put the phone down and finish up.",
            "No line outside yet, don't worry.",
            "5 minutes, the classic warm-up. Carry on.",
            "Take your time, but life's still happening out here.",
            "This was supposed to be a quick visit.",
            "You can't reach the end of Instagram, you know that right?",
            "Wrap it up before someone knocks.",
            "First 5 minutes down. Warm-up laps over?"
        ],
        .tenMin: [
            "This isn't a board meeting.",
            "10 minutes — that's a whole sitcom episode.",
            "Legs still working over there?",
            "Did you set up Wi-Fi in there?",
            "10 minutes in, don't let your phone die.",
            "At this point you might as well move in.",
            "The household is getting concerned.",
            "Get up before the toilet claims you as its own.",
            "Your legs called. They want their blood flow back."
        ],
        .twentyMin: [
            "Your legs asleep yet?",
            "20 minutes — this is a lifestyle now.",
            "People out here are starting to wonder about you.",
            "You could've watched half a movie by now.",
            "Everything okay, or are you exploring in there?",
            "20 minutes officially makes this a 'long break.'",
            "You're not sitting anymore, you're residing.",
            "Should we update your mailing address?",
            "At this point your exit deserves a standing ovation.",
            "We're approaching search-party territory."
        ],
        .thirtyMin: [
            "Sitting this long actually isn't great for you — time to wrap up 😅",
            "30+ minutes in, this is health-warning territory now.",
            "Move your legs a bit, sitting this long isn't ideal.",
            "Okay, we're genuinely a little worried now.",
            "This long sitting isn't doing your back or legs any favors.",
            "Time to head out — give yourself a break for real.",
            "Half an hour. This isn't a break anymore, it's a lifestyle. Go for a walk 🚶",
            "Your legs have officially filed a complaint. Stand up to settle.",
            "Put the phone down, flush, rejoin society. This is a public health announcement."
        ]
    ]

    /// Eşik için rastgele mesaj döndürür; aynı mesajın arka arkaya
    /// gelmemesi için son kullanılan indeks UserDefaults'ta tutulur.
    static func nextMessage(for threshold: Threshold) -> String {
        let pool = (isTurkish ? tr : en)[threshold] ?? []
        guard !pool.isEmpty else { return "" }
        let key = "lastMessageIndex.\(threshold.rawValue)"
        let last = UserDefaults.standard.object(forKey: key) as? Int
        var candidates = Array(pool.indices)
        if let last, candidates.count > 1 {
            candidates.removeAll { $0 == last }
        }
        let picked = candidates.randomElement()!
        UserDefaults.standard.set(picked, forKey: key)
        return pool[picked]
    }
}

/// Arayüz metinleri — sistem diline göre TR/EN.
enum L10n {
    private static var tr: Bool { MessagePool.isTurkish }

    /// Kullanıcıya görünen ad. Mağaza adıyla aynı olmalı — App Store'da
    /// "ShitTimer" adı 1.1.1 kapsamında riskli olduğu için "Sit Happens".
    /// Çalışma adına dönmek istersen tek değişecek yer burası ve
    /// pbxproj'daki INFOPLIST_KEY_CFBundleDisplayName.
    static var appTitle: String { "Sit Happens" }
    static var start: String { tr ? "BAŞLAT" : "START" }
    static var stop: String { tr ? "BİTİR" : "DONE" }
    static var sessionActive: String { tr ? "Sayaç çalışıyor..." : "The clock is ticking..." }
    static var idleHint: String { tr ? "Oturunca bas." : "Tap when you sit down." }
    static var statsTitle: String { tr ? "İstatistikler" : "Stats" }
    static var timerTab: String { tr ? "Sayaç" : "Timer" }
    static var today: String { tr ? "Bugün" : "Today" }
    static var thisWeekTotal: String { tr ? "Bu Hafta Toplam" : "This Week Total" }
    static var thisWeekAverage: String { tr ? "Oturum Ortalaması" : "Avg. per Session" }
    static var personalRecord: String { tr ? "Kişisel Rekor" : "Personal Record" }
    static var sessionCount: String { tr ? "Bu Hafta Oturum" : "Sessions This Week" }
    static var noData: String { tr ? "Henüz veri yok. İlk seansını başlat!" : "No data yet. Start your first session!" }
    static var notifDenied: String {
        tr ? "Bildirim izni yok — dürtmeleri kaçıracaksın. Ayarlar'dan açabilirsin."
           : "Notifications are off — you'll miss the nudges. Enable them in Settings."
    }
    static var lastSession: String { tr ? "Son oturum" : "Last session" }

    // Tema paketi / satın alma
    static var storeTitle: String { tr ? "Tema Paketi" : "Theme Pack" }
    static var storeSubtitle: String {
        tr ? "Arcade ve Pastel temalarının kilidini tek seferlik ödemeyle aç. Abonelik yok, reklam yok."
           : "Unlock the Arcade and Pastel themes with a one-time payment. No subscription, no ads."
    }
    static func buyButton(_ price: String?) -> String {
        guard let price else { return tr ? "Kilidi Aç" : "Unlock" }
        return tr ? "Kilidi Aç — \(price)" : "Unlock — \(price)"
    }
    static var restoreButton: String { tr ? "Satın Alımları Geri Yükle" : "Restore Purchases" }
    static var maybeLater: String { tr ? "Şimdi değil" : "Not now" }
    static var oneTimeNote: String {
        tr ? "Tek seferlik satın alma. Aynı Apple hesabıyla tüm cihazlarında geçerli."
           : "One-time purchase. Works on all your devices with the same Apple Account."
    }
    static var storeUnavailable: String {
        tr ? "Tema paketi şu an mağazadan alınamıyor. Bağlantını kontrol edip biraz sonra tekrar dene."
           : "The Theme Pack isn't available from the store right now. Check your connection and try again shortly."
    }
    static var nothingToRestore: String {
        tr ? "Geri yüklenecek bir satın alma bulunamadı." : "No previous purchase found to restore."
    }
    // Ayarlar
    static var settingsTitle: String { tr ? "Ayarlar" : "Settings" }
    static var languageSection: String { tr ? "Dil" : "Language" }
    static var languageNote: String {
        tr ? "Bildirim mesajları da seçtiğin dilde gelir."
           : "Notification messages follow this setting too."
    }
    static var accountSection: String { tr ? "Hesap" : "Account" }
    static var notSignedIn: String { tr ? "Giriş yapılmadı" : "Not signed in" }
    static var signedInWith: String { tr ? "ile giriş yapıldı" : "signed in" }
    static var notificationsSection: String { tr ? "Bildirimler" : "Notifications" }
    static var openSystemSettings: String { tr ? "iOS Ayarları'nda aç" : "Open in iOS Settings" }
    static var notificationsNote: String {
        tr ? "Eşik bildirimlerini açıp kapatmak için sistem ayarlarını kullan."
           : "Use system settings to turn threshold notifications on or off."
    }
    static var aboutSection: String { tr ? "Hakkında" : "About" }
    static var supportLink: String { tr ? "Destek" : "Support" }
    static var privacyLink: String { tr ? "Gizlilik politikası" : "Privacy policy" }
    static var versionLabel: String { tr ? "Sürüm" : "Version" }
    static var done: String { tr ? "Bitti" : "Done" }

    // Hesap ve tablo
    static var loginTitle: String { tr ? "Tabloya katıl" : "Join the leaderboard" }
    static var loginSubtitle: String {
        tr ? "Kullanıcı adı belirle, arkadaşlarını ekle ve haftalık ortalamanızı karşılaştırın. Kısa olan kazanır."
           : "Pick a username, add friends and compare weekly averages. Shorter wins."
    }
    static var continueWithGoogle: String { tr ? "Google ile devam et" : "Continue with Google" }
    static var loginPrivacyNote: String {
        tr ? "Yalnızca kullanıcı adın ve oturum sürelerin paylaşılır. Hesabını uygulama içinden istediğin an silebilirsin."
           : "Only your username and session durations are shared. You can delete your account from inside the app at any time."
    }
    static var signInNotConfigured: String {
        tr ? "Google girişi henüz hazır değil, Apple ile devam edebilirsin."
           : "Google sign-in isn't ready yet — you can continue with Apple."
    }
    static var chooseUsername: String { tr ? "Kullanıcı adın" : "Your username" }
    static var usernameRules: String {
        tr ? "3-16 karakter; küçük harf, rakam ve alt çizgi kullanabilirsin."
           : "3-16 characters: lowercase letters, numbers and underscores."
    }
    static var usernameTaken: String { tr ? "Bu kullanıcı adı alınmış, başka bir tane dene." : "That username is taken, try another." }
    static var continueButton: String { tr ? "Devam" : "Continue" }
    static var leaderboardTitle: String { tr ? "Tablo" : "Leaderboard" }
    static var leaderboardTab: String { tr ? "Tablo" : "Board" }
    static var leaderboardMetric: String {
        tr ? "Haftalık oturum ortalaması — kısa olan üstte" : "Weekly average per session — shorter is better"
    }
    static var you: String { tr ? "sen" : "you" }
    static var friendsEmpty: String {
        tr ? "Henüz arkadaşın yok. Arkadaş ekleme yakında açılacak."
           : "No friends yet. Adding friends is coming soon."
    }
    static var signOut: String { tr ? "Çıkış yap" : "Sign out" }
    static var deleteAccount: String { tr ? "Hesabı sil" : "Delete account" }
    static var deleteAccountConfirm: String {
        tr ? "Hesabın ve tablodaki kaydın kalıcı olarak silinecek." : "Your account and leaderboard entry will be permanently deleted."
    }
    static var cancel: String { tr ? "Vazgeç" : "Cancel" }

    static var freeBadge: String { tr ? "Ücretsiz" : "Free" }
    static var unlockedBadge: String { tr ? "Açık" : "Unlocked" }
    static var lockedBadge: String { tr ? "Kilitli" : "Locked" }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }
}
