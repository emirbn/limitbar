import SwiftUI
import WidgetKit

@main
struct LimitBarWidgetBundle: WidgetBundle {
    var body: some Widget {
        LimitBarSwitcherWidget()
        LimitBarUsageWidget()
        LimitBarHistoryWidget()
        LimitBarCompactWidget()
        LimitBarBurnDownWidget()
        LimitBarCombinedBurnDownWidget()
        LimitBarAccountUsageWidget()
    }
}

struct LimitBarSwitcherWidget: Widget {
    private let kind = "LimitBarSwitcherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: self.kind,
            provider: LimitBarSwitcherTimelineProvider())
        { entry in
            LimitBarSwitcherWidgetView(entry: entry)
        }
        .configurationDisplayName("LimitBar Switcher")
        .description("Usage widget with a provider switcher.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct LimitBarUsageWidget: Widget {
    private let kind = "LimitBarUsageWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: self.kind,
            intent: ProviderSelectionIntent.self,
            provider: LimitBarTimelineProvider())
        { entry in
            LimitBarUsageWidgetView(entry: entry)
        }
        .configurationDisplayName("LimitBar Usage")
        .description("Session and weekly usage with credits and costs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct LimitBarHistoryWidget: Widget {
    private let kind = "LimitBarHistoryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: self.kind,
            intent: ProviderSelectionIntent.self,
            provider: LimitBarTimelineProvider())
        { entry in
            LimitBarHistoryWidgetView(entry: entry)
        }
        .configurationDisplayName("LimitBar History")
        .description("Usage history chart with recent totals.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct LimitBarCompactWidget: Widget {
    private let kind = "LimitBarCompactWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: self.kind,
            intent: CompactMetricSelectionIntent.self,
            provider: LimitBarCompactTimelineProvider())
        { entry in
            LimitBarCompactWidgetView(entry: entry)
        }
        .configurationDisplayName("LimitBar Metric")
        .description("Compact widget for credits or cost.")
        .supportedFamilies([.systemSmall])
    }
}

enum BurnDownWidgetBackgroundConfiguration {
    static let isRemovable = true
}

struct LimitBarBurnDownWidget: Widget {
    private let kind = "LimitBarBurnDownWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: self.kind,
            intent: BurnDownSelectionIntent.self,
            provider: BurnDownTimelineProvider())
        { entry in
            BurnDownWidgetView(entry: entry)
        }
        .configurationDisplayName("LimitBar Burn Down")
        .description("Remaining budget compared with an ideal steady burn rate.")
        .supportedFamilies([.systemMedium])
        .containerBackgroundRemovable(BurnDownWidgetBackgroundConfiguration.isRemovable)
    }
}

struct LimitBarCombinedBurnDownWidget: Widget {
    private let kind = "LimitBarCombinedBurnDownWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: self.kind,
            intent: BurnProviderSelectionIntent.self,
            provider: CombinedBurnDownTimelineProvider())
        { entry in
            CombinedBurnDownWidgetView(entry: entry)
        }
        .configurationDisplayName("LimitBar Burn Down (Combined)")
        .description("Two quota burn-down charts in one tile.")
        .supportedFamilies([.systemMedium])
        .containerBackgroundRemovable(BurnDownWidgetBackgroundConfiguration.isRemovable)
    }
}
