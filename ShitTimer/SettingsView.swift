import SwiftUI
import UIKit

/// Hesap, dil ve uygulama bilgileri. Hesap bölümü yalnızca hesap özelliği
/// açıkken görünür; dil ayarı her durumda erişilebilir.
struct SettingsView: View {
    let theme: AppTheme
    @ObservedObject var accountStore: AccountStore
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue
    @State private var showDeleteConfirm = false

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if Features.accountsEnabled {
                        accountSection
                    }
                    languageSection
                    notificationsSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Text(L10n.settingsTitle)
                    .font(.system(size: 28, weight: .heavy, design: theme == .arcade ? .monospaced : .rounded))
                    .foregroundColor(theme.primaryText)
                Spacer()
                Button(L10n.done) { dismiss() }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.startTint)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(theme.background)
        }
        .preferredColorScheme(theme.prefersDark ? .dark : .light)
        .confirmationDialog(L10n.deleteAccountConfirm, isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button(L10n.deleteAccount, role: .destructive) {
                Task { await accountStore.deleteAccount() }
            }
            Button(L10n.cancel, role: .cancel) {}
        }
    }

    // MARK: - Bölümler

    private var accountSection: some View {
        section(L10n.accountSection) {
            if let account = accountStore.account {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(theme.startTint)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(account.username ?? L10n.chooseUsername)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        Text("\(account.provider.displayName) \(L10n.signedInWith)")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                    Spacer()
                }
                .padding(.bottom, 4)

                Divider().overlay(theme.secondaryText.opacity(0.25))

                Button(L10n.signOut) { accountStore.signOut() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)

                Button(L10n.deleteAccount) { showDeleteConfirm = true }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.stopTint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                Text(L10n.notSignedIn)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
            }
        }
    }

    private var languageSection: some View {
        section(L10n.languageSection) {
            ForEach(AppLanguage.allCases) { option in
                Button {
                    languageRaw = option.rawValue
                    timerManager.rescheduleNotifications()
                } label: {
                    HStack {
                        Text(option.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                        Spacer()
                        if option.rawValue == languageRaw {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(theme.startTint)
                        }
                    }
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if option != AppLanguage.allCases.last {
                    Divider().overlay(theme.secondaryText.opacity(0.2))
                }
            }

            Text(L10n.languageNote)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
    }

    private var notificationsSection: some View {
        section(L10n.notificationsSection) {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text(L10n.openSystemSettings)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .foregroundColor(theme.secondaryText)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(L10n.notificationsNote)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var aboutSection: some View {
        section(L10n.aboutSection) {
            linkRow(L10n.supportLink, url: "https://busegenc.github.io/sit-happens-support/")
            Divider().overlay(theme.secondaryText.opacity(0.2))
            linkRow(L10n.privacyLink, url: "https://busegenc.github.io/sit-happens-support/privacy.html")
            Divider().overlay(theme.secondaryText.opacity(0.2))
            HStack {
                Text(L10n.versionLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                Text(version)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(theme.secondaryText)
            }
            .padding(.vertical, 11)
        }
    }

    // MARK: - Yardımcılar

    private func linkRow(_ title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.secondaryText)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(theme.cardBackground))
        }
    }
}
