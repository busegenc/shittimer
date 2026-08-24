import ActivityKit
import WidgetKit
import SwiftUI

// Klasik temanın renkleri — widget hedefi ana uygulamanın Theme.swift'ine
// bağımlı olmadığından burada aynı tonlar sabit tutuluyor.
private let gold = Color(red: 1.0, green: 0.784, blue: 0.341)      // 0xFFC857
private let darkBrown = Color(red: 0.18, green: 0.106, blue: 0.063) // 0x2E1B10
private let cream = Color(red: 1.0, green: 0.953, blue: 0.878)     // 0xFFF3E0

/// 0...4 aşamasına karşılık gelen simge ve etiket. TimerManager.stage /
/// Theme.stageEmoji ile aynı ölçek, karikatür görsel yok (App Store 1.1 uyumu).
private func stageInfo(_ stage: Int, turkish: Bool) -> (symbol: String, label: String) {
    switch stage {
    case 0: return ("timer", turkish ? "Başladı" : "Started")
    case 1: return ("clock", turkish ? "5 dk geçti" : "5 min in")
    case 2: return ("clock.badge.exclamationmark", turkish ? "10 dk geçti" : "10 min in")
    case 3: return ("exclamationmark.triangle", turkish ? "20 dk geçti" : "20 min in")
    default: return ("exclamationmark.triangle.fill", turkish ? "30+ dk" : "30+ min")
    }
}

private var isTurkish: Bool {
    Locale.preferredLanguages.first?.hasPrefix("tr") ?? false
}

/// Sürekli artan bir sayaç: sistem bunu kendi başına, uygulamadan güncelleme
/// almadan canlı tutar. Üst sınır yalnızca API'nin istediği bir aralık
/// belirtmek için var, gerçek kullanımda çoktan aşılıp geçilir.
private func elapsedText(since start: Date) -> Text {
    Text(timerInterval: start...start.addingTimeInterval(24 * 3600), countsDown: false, showsHours: true)
}

struct ShitTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SitHappensActivityAttributes.self) { context in
            lockScreenView(context.state)
                .activityBackgroundTint(darkBrown)
                .activitySystemActionForegroundColor(cream)
        } dynamicIsland: { context in
            let info = stageInfo(context.state.stage, turkish: isTurkish)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: info.symbol)
                        .foregroundStyle(gold)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    elapsedText(since: context.state.startDate)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(cream)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(L10nWidget.appName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: info.symbol)
                    .foregroundStyle(gold)
            } compactTrailing: {
                elapsedText(since: context.state.startDate)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .frame(width: 44)
            } minimal: {
                Image(systemName: info.symbol)
                    .foregroundStyle(gold)
            }
            .keylineTint(gold)
        }
    }

    @ViewBuilder
    private func lockScreenView(_ state: SitHappensActivityAttributes.ContentState) -> some View {
        let info = stageInfo(state.stage, turkish: isTurkish)
        HStack(spacing: 14) {
            Image(systemName: info.symbol)
                .font(.system(size: 30))
                .foregroundStyle(gold)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(L10nWidget.appName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(cream)
                Text(info.label)
                    .font(.caption)
                    .foregroundStyle(cream.opacity(0.7))
            }

            Spacer()

            elapsedText(since: state.startDate)
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(cream)
                .monospacedDigit()
        }
        .padding(16)
    }
}

/// Widget hedefi ana uygulamanın L10n'ine bağlı değil; tek gereken metin
/// için burada minik bir kopya yeterli.
private enum L10nWidget {
    static var appName: String { "Sit Happens" }
}

