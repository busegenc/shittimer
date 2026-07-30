import SwiftUI

/// Kilitli bir temaya dokunulduğunda açılan tek seferlik satın alma ekranı.
struct PaywallView: View {
    let theme: AppTheme
    @ObservedObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 8)

                Image(systemName: "lock.open.fill")
                    .font(.system(size: 44))
                    .foregroundColor(theme.startTint)

                Text(L10n.storeTitle)
                    .font(.system(size: 30, weight: .heavy, design: theme == .arcade ? .monospaced : .rounded))
                    .foregroundColor(theme.primaryText)

                Text(L10n.storeSubtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                VStack(spacing: 12) {
                    ForEach(AppTheme.allCases) { option in
                        ThemeRow(theme: theme, option: option, isPremium: store.isPremium)
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 8)

                if let error = store.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(theme.stopTint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 12) {
                    Button {
                        Task {
                            await store.purchase()
                            if store.isPremium { dismiss() }
                        }
                    } label: {
                        Group {
                            if store.isWorking {
                                ProgressView().tint(theme.startTextColor)
                            } else {
                                Text(L10n.buyButton(store.priceText))
                                    .font(theme.buttonFont(size: 20))
                            }
                        }
                        .foregroundColor(theme.startTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(RoundedRectangle(cornerRadius: theme.buttonCornerRadius).fill(theme.startTint))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isWorking || store.product == nil)
                    .opacity(store.product == nil ? 0.5 : 1)

                    if store.product == nil {
                        Text(L10n.storeUnavailable)
                            .font(.footnote)
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(L10n.restoreButton) {
                        Task { await store.restore() }
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(theme.secondaryText)

                    Text(L10n.oneTimeNote)
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)

                Button(L10n.maybeLater) { dismiss() }
                    .font(.footnote)
                    .foregroundColor(theme.secondaryText)
                    .padding(.bottom, 12)
            }
        }
        .preferredColorScheme(theme.prefersDark ? .dark : .light)
        .task {
            // Ekran her açıldığında tekrar dene: ilk açılışta mağazaya
            // ulaşılamamışsa kullanıcı uygulamayı kapatmadan toparlanır
            await store.loadProduct()
        }
    }
}

private struct ThemeRow: View {
    let theme: AppTheme
    let option: AppTheme
    let isPremium: Bool

    private var badge: String {
        if option.isFree { return L10n.freeBadge }
        return isPremium ? L10n.unlockedBadge : L10n.lockedBadge
    }

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(option.swatch)
                .frame(width: 22, height: 22)
                .frame(width: 46, height: 46)
                .background(Circle().fill(theme.cardBackground))

            VStack(alignment: .leading, spacing: 3) {
                Text(option.displayName)
                    .font(.system(size: 16, weight: .bold, design: theme == .arcade ? .monospaced : .rounded))
                    .foregroundColor(theme.primaryText)
                Text(option.tagline)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text(badge)
                .font(.caption.weight(.bold))
                .foregroundColor(option.isFree || isPremium ? theme.startTint : theme.secondaryText)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(theme.cardBackground))
    }
}
