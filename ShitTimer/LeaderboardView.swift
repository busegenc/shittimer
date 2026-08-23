import SwiftUI

/// Tablo sekmesi. Hesap durumuna göre giriş → kullanıcı adı → tablo akışını yönetir.
struct LeaderboardView: View {
    let theme: AppTheme
    @ObservedObject var store: AccountStore
    @EnvironmentObject var timerManager: TimerManager
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if !store.isSignedIn {
                LoginView(theme: theme, store: store)
            } else if store.needsUsername {
                UsernameView(theme: theme, store: store)
            } else {
                board
            }
        }
    }

    private var board: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(L10n.leaderboardTitle)
                        .font(.system(size: 30, weight: .heavy, design: theme == .arcade ? .monospaced : .rounded))
                        .foregroundColor(theme.primaryText)
                    Spacer()
                    Menu {
                        Button(L10n.signOut) { store.signOut() }
                        Button(L10n.deleteAccount, role: .destructive) { showDeleteConfirm = true }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 24))
                            .foregroundColor(theme.secondaryText)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)

                Text(L10n.leaderboardMetric)
                    .font(.footnote)
                    .foregroundColor(theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // Kullanıcının kendi satırı — veriler cihazdaki oturumlardan
                selfRow
                    .padding(.horizontal, 20)

                Spacer()

                // Arkadaş listesi arka uç bağlanınca dolacak
                VStack(spacing: 10) {
                    Image(systemName: "person.2")
                        .font(.system(size: 34))
                        .foregroundColor(theme.secondaryText.opacity(0.7))
                    Text(L10n.friendsEmpty)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
        .confirmationDialog(L10n.deleteAccountConfirm, isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button(L10n.deleteAccount, role: .destructive) {
                Task { await store.deleteAccount() }
            }
            Button(L10n.cancel, role: .cancel) {}
        }
    }

    private var selfRow: some View {
        HStack(spacing: 14) {
            Text("1")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(theme.startTint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.account?.username ?? "—")
                    .font(.system(size: 17, weight: .bold, design: theme == .arcade ? .monospaced : .rounded))
                    .foregroundColor(theme.primaryText)
                Text(L10n.you)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            Text(L10n.formatDuration(timerManager.weekAverage))
                .font(theme.digitFont(size: 20))
                .monospacedDigit()
                .foregroundColor(theme.primaryText)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(theme.cardBackground))
    }
}
