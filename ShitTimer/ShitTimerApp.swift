import SwiftUI
import UserNotifications

@main
struct ShitTimerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerManager = TimerManager()
    @StateObject private var store = StoreManager()

    init() {
        #if DEBUG
        // Ekran görüntüsü için tema seçimi: --theme=poop|arcade|pastel
        if let arg = CommandLine.arguments.first(where: { $0.hasPrefix("--theme=") }) {
            UserDefaults.standard.set(String(arg.dropFirst("--theme=".count)), forKey: "appTheme")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
                .environmentObject(store)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Uygulama öndeyken de bildirimleri banner olarak göster
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
