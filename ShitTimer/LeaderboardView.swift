import SwiftUI

/// Tablo sekmesi. Hesap durumuna göre giriş → kullanıcı adı → tablo akışını yönetir.
struct LeaderboardView: View {
    let theme: AppTheme
    @ObservedObject var store: AccountStore
    @ObservedObject var board: LeaderboardStore
    var onOpenSettings: () -> Void = {}
    @EnvironmentObject var timerManager: TimerManager

    @State private var showAddFriend = false
    @State private var reportTarget: LeaderboardEntry?

    var body: some View {
        Group {
            if !store.isSignedIn {
                LoginView(theme: theme, store: store)
            } else if store.needsUsername {
                UsernameView(theme: theme, store: store)
            } else {
                board_
            }
        }
    }

    private var board_: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if let error = board.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(theme.stopTint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                List {
                    if !board.requests.isEmpty {
                        Section {
                            ForEach(board.requests) { entry in
                                requestRow(entry)
                            }
                        } header: {
                            Text(L10n.pendingRequests)
                                .foregroundColor(theme.secondaryText)
                        }
                        .listRowBackground(theme.cardBackground)
                    }

                    Section {
                        if board.entries.isEmpty {
                            Text(L10n.friendsEmpty)
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(board.entries.enumerated()), id: \.element.id) { index, entry in
                                entryRow(index: index, entry: entry)
                            }
                        }
                    } header: {
                        Text(L10n.leaderboardMetric)
                            .foregroundColor(theme.secondaryText)
                    }
                    .listRowBackground(theme.cardBackground)
                }
                .scrollContentBackground(.hidden)
                .refreshable { await reload() }
            }
        }
        .task { await reload() }
        .onChange(of: board.sessionInvalid) { invalid in
            // Sunucu oturumu düşmüşse giriş ekranına dön
            if invalid { store.signOut() }
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendView(theme: theme, board: board)
        }
        .confirmationDialog(L10n.reportUserTitle,
                            isPresented: Binding(get: { reportTarget != nil },
                                                 set: { if !$0 { reportTarget = nil } }),
                            titleVisibility: .visible) {
            ForEach(L10n.reportReasons, id: \.self) { reason in
                Button(reason) {
                    if let target = reportTarget {
                        Task { await board.report(target, reason: reason) }
                    }
                    reportTarget = nil
                }
            }
            Button(L10n.cancel, role: .cancel) { reportTarget = nil }
        }
    }

    private var header: some View {
        HStack {
            Text(L10n.leaderboardTitle)
                .font(.system(size: 30, weight: .heavy, design: theme == .arcade ? .monospaced : .rounded))
                .foregroundColor(theme.primaryText)
            Spacer()
            Button { showAddFriend = true } label: {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.startTint)
            }
            .accessibilityLabel(L10n.addFriend)
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.secondaryText)
            }
            .accessibilityLabel(L10n.settingsTitle)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private func entryRow(index: Int, entry: LeaderboardEntry) -> some View {
        let isMe = entry.userId == store.account?.id
        return HStack(spacing: 14) {
            Text("\(index + 1)")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(index == 0 ? theme.startTint : theme.secondaryText)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.system(size: 16, weight: isMe ? .heavy : .semibold,
                                  design: theme == .arcade ? .monospaced : .rounded))
                    .foregroundColor(theme.primaryText)
                Text(isMe ? L10n.you : "\(entry.sessionCount) \(L10n.sessionsShort)")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            Text(L10n.formatDuration(entry.average))
                .font(theme.digitFont(size: 18))
                .monospacedDigit()
                .foregroundColor(theme.primaryText)
        }
        .padding(.vertical, 6)
        .contextMenu {
            if !isMe {
                Button(L10n.removeFriend, role: .destructive) {
                    Task { await board.remove(entry) }
                }
                Button(L10n.blockUser) { Task { await board.block(entry) } }
                Button(L10n.reportUser) { reportTarget = entry }
            }
        }
    }

    private func requestRow(_ entry: LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            Text(entry.username)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.primaryText)
            Spacer()
            Button {
                Task { await board.respond(to: entry, accept: true) }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.startTint)
            }
            .buttonStyle(.plain)
            Button {
                Task { await board.respond(to: entry, accept: false) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(L10n.blockUser) { Task { await board.block(entry) } }
            Button(L10n.reportUser) { reportTarget = entry }
        }
    }

    private func reload() async {
        await board.refresh(weekAverage: timerManager.weekAverage,
                            sessionCount: timerManager.weekCount)
    }
}

/// Kullanıcı adıyla arkadaş ekleme.
struct AddFriendView: View {
    let theme: AppTheme
    @ObservedObject var board: LeaderboardStore
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var sent = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Text(L10n.addFriend)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(theme.primaryText)
                    .padding(.top, 28)

                Text(L10n.addFriendHint)
                    .font(.footnote)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)

                TextField("", text: $username,
                          prompt: Text("kullaniciadi").foregroundColor(theme.secondaryText.opacity(0.6)))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.primaryText)
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 14).fill(theme.cardBackground))
                    .padding(.horizontal, 24)

                if sent {
                    Text(L10n.requestSent)
                        .font(.footnote)
                        .foregroundColor(theme.startTint)
                } else if let error = board.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(theme.stopTint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                Button {
                    Task {
                        if await board.addFriend(username: username) {
                            sent = true
                            username = ""
                        }
                    }
                } label: {
                    Group {
                        if board.isLoading {
                            ProgressView().tint(theme.startTextColor)
                        } else {
                            Text(L10n.sendRequest).font(theme.buttonFont(size: 19))
                        }
                    }
                    .foregroundColor(theme.startTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(RoundedRectangle(cornerRadius: theme.buttonCornerRadius).fill(theme.startTint))
                }
                .buttonStyle(.plain)
                .disabled(username.isEmpty || board.isLoading)
                .opacity(username.isEmpty ? 0.5 : 1)
                .padding(.horizontal, 24)

                Button(L10n.done) { dismiss() }
                    .font(.footnote)
                    .foregroundColor(theme.secondaryText)
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(theme.prefersDark ? .dark : .light)
    }
}
