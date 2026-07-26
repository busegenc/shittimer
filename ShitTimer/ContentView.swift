import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var store: StoreManager
    @AppStorage("appTheme") private var themeRaw = AppTheme.poop.rawValue
    @State private var selectedTab = Self.initialTab

    /// Satın alma iptal/iade edilmişse ücretli tema seçili kalmasın.
    private var theme: AppTheme {
        let stored = AppTheme(rawValue: themeRaw) ?? .poop
        return (stored.isFree || store.isPremium) ? stored : .poop
    }

    private static var initialTab: Int {
        #if DEBUG
        return CommandLine.arguments.contains("--tab=stats") ? 1 : 0
        #else
        return 0
        #endif
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView(theme: theme, themeRaw: $themeRaw)
                .tabItem { Label(L10n.timerTab, systemImage: "timer") }
                .tag(0)
            StatsView(theme: theme)
                .tabItem { Label(L10n.statsTitle, systemImage: "chart.bar.fill") }
                .tag(1)
        }
        .tint(theme.startTint)
        .preferredColorScheme(theme.prefersDark ? .dark : .light)
    }
}

struct TimerView: View {
    let theme: AppTheme
    @Binding var themeRaw: String
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var store: StoreManager
    @State private var showPaywall = Self.paywallAtLaunch

    private static var paywallAtLaunch: Bool {
        #if DEBUG
        return CommandLine.arguments.contains("--paywall")
        #else
        return false
        #endif
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                themePicker
                    .padding(.top, 8)

                Spacer(minLength: 12)

                dial

                Spacer(minLength: 12)

                tauntCard
                    .padding(.horizontal, 24)

                Spacer(minLength: 12)

                mainButton
                    .padding(.horizontal, 24)

                if timerManager.notificationsDenied {
                    Text(L10n.notifDenied)
                        .font(.footnote)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                Spacer().frame(height: 8)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(theme: theme, store: store)
        }
    }

    // MARK: - Parçalar

    private var themePicker: some View {
        HStack(spacing: 10) {
            ForEach(AppTheme.allCases) { option in
                let locked = !option.isFree && !store.isPremium
                Button {
                    if locked {
                        showPaywall = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) { themeRaw = option.rawValue }
                    }
                } label: {
                    Text(option.pickerEmoji)
                        .font(.system(size: 22))
                        .opacity(locked ? 0.45 : 1)
                        .frame(width: 46, height: 46)
                        .background(
                            Circle()
                                .fill(theme.cardBackground)
                                .overlay(
                                    Circle().stroke(option == theme ? theme.startTint : .clear, lineWidth: 2)
                                )
                        )
                        .overlay(alignment: .bottomTrailing) {
                            if locked {
                                Text("🔒")
                                    .font(.system(size: 11))
                                    .padding(3)
                                    .background(Circle().fill(theme.cardBackground))
                                    .offset(x: 2, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dial: some View {
        ZStack {
            Circle()
                .stroke(theme.ringTrack, lineWidth: 18)

            Circle()
                .trim(from: 0, to: timerManager.isRunning ? max(0.005, timerManager.progress) : 0)
                .stroke(theme.ringGradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: timerManager.progress)
                .shadow(color: theme.glow?.opacity(0.7) ?? .clear, radius: 10)

            VStack(spacing: 6) {
                Text(theme.stageEmoji(timerManager.isRunning ? timerManager.stage : 0))
                    .font(.system(size: 52))
                    .scaleEffect(timerManager.isRunning ? 1.08 : 1.0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.55), value: timerManager.stage)

                Text(L10n.formatDuration(timerManager.elapsed))
                    .font(theme.digitFont(size: 52))
                    .foregroundColor(theme.primaryText)
                    .monospacedDigit()
                    .shadow(color: theme.glow?.opacity(0.8) ?? .clear, radius: 8)

                Text(timerManager.isRunning ? L10n.sessionActive : L10n.idleHint)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(theme.secondaryText)
            }
        }
        .frame(width: 280, height: 280)
    }

    private var tauntCard: some View {
        Group {
            if let taunt = timerManager.currentTaunt, timerManager.isRunning {
                Text(taunt)
                    .font(.system(size: 17, weight: .semibold, design: theme == .arcade ? .monospaced : .rounded))
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(theme.cardBackground)
                    )
                    .transition(.scale.combined(with: .opacity))
            } else {
                Color.clear.frame(height: 84)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timerManager.currentTaunt)
    }

    private var mainButton: some View {
        Button {
            withAnimation { timerManager.toggle() }
        } label: {
            Text(timerManager.isRunning ? L10n.stop : L10n.start)
                .font(theme.buttonFont(size: 26))
                .foregroundColor(timerManager.isRunning ? .white : theme.startTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 84)
                .background(
                    RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                        .fill(timerManager.isRunning ? theme.stopTint : theme.startTint)
                )
                .shadow(color: (timerManager.isRunning ? theme.stopTint : theme.startTint).opacity(0.45),
                        radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}
