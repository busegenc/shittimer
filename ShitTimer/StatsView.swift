import SwiftUI

struct StatsView: View {
    let theme: AppTheme
    var onOpenSettings: () -> Void = {}
    @EnvironmentObject var timerManager: TimerManager

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(L10n.statsTitle)
                        .font(.system(size: 32, weight: .heavy, design: theme == .arcade ? .monospaced : .rounded))
                        .foregroundColor(theme.primaryText)
                    Spacer()
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundColor(theme.secondaryText)
                    }
                    .accessibilityLabel(L10n.settingsTitle)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)

                if timerManager.sessions.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        Image(systemName: "chart.bar.xaxis").font(.system(size: 48)).foregroundColor(theme.secondaryText)
                        Text(L10n.noData)
                            .font(.headline)
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            StatCard(theme: theme, emoji: "☀️", title: L10n.today,
                                     value: L10n.formatDuration(timerManager.todayTotal))
                            StatCard(theme: theme, emoji: "📅", title: L10n.thisWeekTotal,
                                     value: L10n.formatDuration(timerManager.weekTotal))
                            StatCard(theme: theme, emoji: "📊", title: L10n.thisWeekAverage,
                                     value: L10n.formatDuration(timerManager.weekAverage))
                            StatCard(theme: theme, emoji: "🔢", title: L10n.sessionCount,
                                     value: "\(timerManager.weekCount)")
                            StatCard(theme: theme, emoji: "🏆", title: L10n.personalRecord,
                                     value: L10n.formatDuration(timerManager.personalRecord))
                            if let last = timerManager.lastSession {
                                StatCard(theme: theme, emoji: "⏱️", title: L10n.lastSession,
                                         value: L10n.formatDuration(last.duration))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }
}

private struct StatCard: View {
    let theme: AppTheme
    let emoji: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 26))
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: theme == .arcade ? .monospaced : .rounded))
                .foregroundColor(theme.secondaryText)
            Spacer()
            Text(value)
                .font(theme.digitFont(size: 22))
                .foregroundColor(theme.primaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 20).fill(theme.cardBackground))
    }
}
