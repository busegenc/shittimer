import SwiftUI
import AuthenticationServices

/// Tablo sekmesinde, hesabı olmayan kullanıcıya gösterilen giriş ekranı.
struct LoginView: View {
    let theme: AppTheme
    @ObservedObject var store: AccountStore

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 44))
                .foregroundColor(theme.startTint)

            Text(L10n.loginTitle)
                .font(.system(size: 26, weight: .heavy, design: theme == .arcade ? .monospaced : .rounded))
                .foregroundColor(theme.primaryText)
                .multilineTextAlignment(.center)

            Text(L10n.loginSubtitle)
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email]
                } onCompletion: { result in
                    Task { await store.handleAppleSignIn(result) }
                }
                .signInWithAppleButtonStyle(theme.prefersDark ? .white : .black)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task { await store.signInWithGoogle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text(L10n.continueWithGoogle)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(theme.prefersDark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.prefersDark ? Color.white : Color.black)
                    )
                }
                .buttonStyle(.plain)

                if let error = store.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(theme.stopTint)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(L10n.loginPrivacyNote)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryText.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background.ignoresSafeArea())
    }
}

/// Girişten sonra bir kez gösterilir: tabloda görünecek ad.
struct UsernameView: View {
    let theme: AppTheme
    @ObservedObject var store: AccountStore
    @State private var username = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 44))
                .foregroundColor(theme.startTint)

            Text(L10n.chooseUsername)
                .font(.system(size: 24, weight: .heavy, design: theme == .arcade ? .monospaced : .rounded))
                .foregroundColor(theme.primaryText)

            Text(L10n.usernameRules)
                .font(.footnote)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)

            TextField("", text: $username, prompt: Text("kullaniciadi").foregroundColor(theme.secondaryText.opacity(0.6)))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(theme.primaryText)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 14).fill(theme.cardBackground))
                .padding(.horizontal, 28)

            if let error = store.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(theme.stopTint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Spacer()

            Button {
                Task {
                    if await store.claimUsername(username) { focused = false }
                }
            } label: {
                Group {
                    if store.isWorking {
                        ProgressView().tint(theme.startTextColor)
                    } else {
                        Text(L10n.continueButton).font(theme.buttonFont(size: 20))
                    }
                }
                .foregroundColor(theme.startTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(RoundedRectangle(cornerRadius: theme.buttonCornerRadius).fill(theme.startTint))
            }
            .buttonStyle(.plain)
            .disabled(store.isWorking || username.isEmpty)
            .opacity(username.isEmpty ? 0.5 : 1)
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background.ignoresSafeArea())
        .onAppear { focused = true }
    }
}
