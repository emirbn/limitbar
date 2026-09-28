#if os(Linux)
import Foundation
import Testing
@testable import LimitBarCLI
@testable import LimitBarCore

struct AlibabaTokenPlanLinuxTests {
    @Test
    func `manual cookie source does not require macOS web support`() {
        // The Alibaba/Qwen Token Plan fetch is plain URLSession + cookies, so a manually
        // configured cookie header must be usable off macOS (matches qoder/commandcode).
        #expect(!LimitBarCLI.sourceModeRequiresWebSupport(
            .web,
            provider: .alibabatokenplan,
            settings: ProviderSettingsSnapshot.make(
                alibabaTokenPlan: .init(
                    cookieSource: .manual,
                    manualCookieHeader: "login_qwencloud_ticket=t"))))
    }

    @Test
    func `auto cookie source still requires web support off macOS`() {
        #expect(LimitBarCLI.sourceModeRequiresWebSupport(
            .web,
            provider: .alibabatokenplan,
            settings: ProviderSettingsSnapshot.make(
                alibabaTokenPlan: .init(cookieSource: .auto, manualCookieHeader: nil))))
    }
}
#endif
