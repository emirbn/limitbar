import LimitBarCore
import Foundation

extension Notification.Name {
    static let limitbarDebugBlinkNow = Notification.Name("limitbarDebugBlinkNow")
    #if DEBUG
    static let limitbarDebugSimulateMemoryPressure =
        Notification.Name("com.emirbn.limitbar.debug.simulateMemoryPressure")
    #endif
    static let limitbarSessionLimitReset = Notification.Name("limitbarSessionLimitReset")
    static let limitbarWeeklyLimitReset = Notification.Name("limitbarWeeklyLimitReset")
    static let limitbarProviderConfigDidChange = Notification.Name("limitbarProviderConfigDidChange")
    static let limitbarLocalConfigFileDidChange = Notification.Name("limitbarLocalConfigFileDidChange")
    static let limitbarUsageSnapshotsDidChange = Notification.Name("limitbarUsageSnapshotsDidChange")
    static let limitbarQuotaWarningDidPost = Notification.Name("limitbarQuotaWarningDidPost")
}

final class UsageSnapshotsDidChangeEvent: NSObject, @unchecked Sendable {
    let snapshots: [AccountSnapshotSyncPayload]

    init(snapshots: [AccountSnapshotSyncPayload]) {
        self.snapshots = snapshots
    }
}

@MainActor
final class SessionLimitResetEvent: NSObject {
    let provider: UsageProvider
    let accountIdentifier: String
    let accountLabel: String?
    let usedPercent: Double

    init(provider: UsageProvider, accountIdentifier: String, accountLabel: String?, usedPercent: Double) {
        self.provider = provider
        self.accountIdentifier = accountIdentifier
        self.accountLabel = accountLabel
        self.usedPercent = usedPercent
    }
}

@MainActor
final class WeeklyLimitResetEvent: NSObject {
    let provider: UsageProvider
    let accountIdentifier: String
    let accountLabel: String?
    let usedPercent: Double

    init(provider: UsageProvider, accountIdentifier: String, accountLabel: String?, usedPercent: Double) {
        self.provider = provider
        self.accountIdentifier = accountIdentifier
        self.accountLabel = accountLabel
        self.usedPercent = usedPercent
    }
}

@MainActor
final class QuotaWarningPostedEvent: NSObject {
    let provider: UsageProvider
    let window: QuotaWarningWindow
    let threshold: Int
    let postedAt: Date

    init(provider: UsageProvider, window: QuotaWarningWindow, threshold: Int, postedAt: Date) {
        self.provider = provider
        self.window = window
        self.threshold = threshold
        self.postedAt = postedAt
    }
}
