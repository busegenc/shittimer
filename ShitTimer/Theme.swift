import SwiftUI

/// Uygulamanın görsel kimliği. Kullanıcı ana ekrandaki renk noktalarından seçer,
/// seçim UserDefaults'ta ("appTheme") saklanır.
enum AppTheme: String, CaseIterable, Identifiable {
    case classic   // Kahverengi/altın, sade ve sıcak
    case arcade    // Neon retro arcade
    case pastel    // Pastel, yumuşak

    var id: String { rawValue }

    /// Kullanıcıya gösterilecek temalar — tema paketi kapalıyken yalnızca ücretsiz olan.
    static var available: [AppTheme] {
        Features.themePackEnabled ? allCases : [.classic]
    }

    /// Yalnızca Klasik tema ücretsiz; diğerleri tema paketiyle açılır.
    var isFree: Bool { self == .classic }

    /// Paywall'da temayı tanıtan kısa açıklama
    var tagline: String {
        let tr = MessagePool.isTurkish
        switch self {
        case .classic: return tr ? "Sıcak kahve tonları, altın halka." : "Warm browns with a golden ring."
        case .arcade: return tr ? "Neon retro. Ekran kaydı alanların favorisi." : "Retro neon. Made for screen recordings."
        case .pastel: return tr ? "Yumuşak ve şirin. Konuyu kibarca hatırlatır." : "Soft and cute. Nags you politely."
        }
    }

    /// Tema seçici düğmesindeki renk noktası (görsel yerine renk örneği)
    var swatch: Color {
        switch self {
        case .classic: return Color(hex: 0xFFC857)
        case .arcade: return Color(hex: 0x39FF14)
        case .pastel: return Color(hex: 0xFF8FAB)
        }
    }

    var displayName: String {
        switch self {
        case .classic: return MessagePool.isTurkish ? "Klasik" : "Classic"
        case .arcade: return "Arcade"
        case .pastel: return MessagePool.isTurkish ? "Pastel" : "Pastel"
        }
    }

    var prefersDark: Bool {
        switch self {
        case .classic, .arcade: return true
        case .pastel: return false
        }
    }

    // MARK: - Renkler

    var background: LinearGradient {
        switch self {
        case .classic:
            return LinearGradient(colors: [Color(hex: 0x5A3A22), Color(hex: 0x2E1B10)],
                                  startPoint: .top, endPoint: .bottom)
        case .arcade:
            return LinearGradient(colors: [Color(hex: 0x1A0B2E), Color(hex: 0x05010D)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastel:
            return LinearGradient(colors: [Color(hex: 0xFFF3E6), Color(hex: 0xFFE0EC)],
                                  startPoint: .top, endPoint: .bottom)
        }
    }

    var primaryText: Color {
        switch self {
        case .classic: return Color(hex: 0xFFF3E0)
        case .arcade: return Color(hex: 0x39FF14)
        case .pastel: return Color(hex: 0x5B3A46)
        }
    }

    var secondaryText: Color {
        switch self {
        case .classic: return Color(hex: 0xD8B48C)
        case .arcade: return Color(hex: 0xFF4FD8)
        case .pastel: return Color(hex: 0xA1748A)
        }
    }

    var ringTrack: Color {
        switch self {
        case .classic: return Color.white.opacity(0.12)
        case .arcade: return Color(hex: 0x39FF14).opacity(0.15)
        case .pastel: return Color(hex: 0xFFC2D4).opacity(0.45)
        }
    }

    var ringGradient: AngularGradient {
        switch self {
        case .classic:
            return AngularGradient(colors: [Color(hex: 0xFFC857), Color(hex: 0xC98B45), Color(hex: 0xFFC857)],
                                   center: .center)
        case .arcade:
            return AngularGradient(colors: [Color(hex: 0x39FF14), Color(hex: 0x00E5FF), Color(hex: 0xFF4FD8), Color(hex: 0x39FF14)],
                                   center: .center)
        case .pastel:
            return AngularGradient(colors: [Color(hex: 0xFF8FAB), Color(hex: 0xFFC49B), Color(hex: 0xFF8FAB)],
                                   center: .center)
        }
    }

    /// Başlat düğmesi rengi
    var startTint: Color {
        switch self {
        case .classic: return Color(hex: 0xFFC857)
        case .arcade: return Color(hex: 0x39FF14)
        case .pastel: return Color(hex: 0xFF8FAB)
        }
    }

    var startTextColor: Color {
        switch self {
        case .classic: return Color(hex: 0x3A2413)
        case .arcade: return Color(hex: 0x05010D)
        case .pastel: return .white
        }
    }

    var stopTint: Color {
        switch self {
        case .classic: return Color(hex: 0xE2574C)
        case .arcade: return Color(hex: 0xFF4FD8)
        case .pastel: return Color(hex: 0xB07BAC)
        }
    }

    var cardBackground: Color {
        switch self {
        case .classic: return Color.white.opacity(0.10)
        case .arcade: return Color(hex: 0x39FF14).opacity(0.10)
        case .pastel: return .white.opacity(0.75)
        }
    }

    var glow: Color? {
        switch self {
        case .classic: return nil
        case .arcade: return Color(hex: 0x39FF14)
        case .pastel: return nil
        }
    }

    // MARK: - Tipografi

    func digitFont(size: CGFloat) -> Font {
        switch self {
        case .classic, .pastel: return .system(size: size, weight: .heavy, design: .rounded)
        case .arcade: return .system(size: size, weight: .bold, design: .monospaced)
        }
    }

    func buttonFont(size: CGFloat) -> Font {
        switch self {
        case .classic, .pastel: return .system(size: size, weight: .heavy, design: .rounded)
        case .arcade: return .system(size: size, weight: .heavy, design: .monospaced)
        }
    }

    var buttonCornerRadius: CGFloat {
        switch self {
        case .classic: return 30
        case .arcade: return 8
        case .pastel: return 34
        }
    }

    /// Eşik aşıldıkça sertleşen ana emoji (0 = henüz 5 dk dolmadı)
    func stageEmoji(_ stage: Int) -> String {
        let set: [String]
        switch self {
        case .classic: set = ["⏱️", "🙂", "😐", "😅", "😰"]
        case .arcade: set = ["⏱️", "🙂", "⚠️", "🔥", "😰"]
        case .pastel: set = ["⏱️", "🫧", "😊", "😥", "🥴"]
        }
        return set[min(max(stage, 0), set.count - 1)]
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
