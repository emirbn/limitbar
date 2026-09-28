import LimitBarCore
import Testing
@testable import LimitBar

struct KeychainPromptCoordinatorTests {
    @Test
    func `detects raw SwiftPM debug executable`() {
        #expect(KeychainPromptCoordinator.isUnbundledLimitBarExecutable(
            "/Users/me/LimitBar/.build/arm64-apple-macosx/debug/LimitBar"))
        #expect(KeychainPromptCoordinator.isUnbundledLimitBarExecutable(
            "/Users/me/LimitBar/.build/debug/LimitBar"))
    }

    @Test
    func `detects raw SwiftPM release executable`() {
        #expect(KeychainPromptCoordinator.isUnbundledLimitBarExecutable(
            "/Users/me/LimitBar/.build/arm64-apple-macosx/release/LimitBar"))
    }

    @Test
    func `detects custom SwiftPM scratch path`() {
        #expect(KeychainPromptCoordinator.isUnbundledLimitBarExecutable(
            "/tmp/limitbar-build/arm64-apple-macosx/debug/LimitBar"))
    }

    @Test
    func `keeps packaged app keychain behavior`() {
        #expect(!KeychainPromptCoordinator.isUnbundledLimitBarExecutable(
            "/Applications/LimitBar.app/Contents/MacOS/LimitBar"))
        #expect(!KeychainPromptCoordinator.isUnbundledLimitBarExecutable(
            "/Users/me/LimitBar/.build/package/LimitBar.app/Contents/MacOS/LimitBar"))
    }

    @Test
    func `ignores unrelated executable paths`() {
        #expect(!KeychainPromptCoordinator.isUnbundledLimitBarExecutable(
            "/Users/me/LimitBar/.build/debug/LimitBarCLI"))
        #expect(!KeychainPromptCoordinator.isUnbundledLimitBarExecutable(""))
        #expect(!KeychainPromptCoordinator.isUnbundledLimitBarExecutable("LimitBar"))
    }

    @Test
    func `browser cookie alert explains password handling and opt out`() {
        let model = KeychainPromptCoordinator.browserCookieAlertModel(label: "Chrome Safe Storage")

        #expect(model.title == "Keychain Access Required")
        #expect(model.message.contains("Chrome Safe Storage"))
        #expect(model.message.contains("macOS—not LimitBar—handles any Mac login password entry"))
        #expect(model.message.contains("Settings → Advanced"))
        #expect(model.primaryButtonTitle == "OK")
        #expect(model.learnMoreButtonTitle == "Learn More…")
        #expect(model.documentationURL.hasSuffix("/docs/keychain-prompts.md"))
    }

    @Test
    func `provider alert preserves the requested keychain purpose`() {
        let context = KeychainPromptContext(
            kind: .claudeOAuth,
            service: "Claude Code-credentials",
            account: nil)

        let model = KeychainPromptCoordinator.alertModel(for: context)

        #expect(model.message.contains("Claude Code OAuth token"))
        #expect(model.message.contains("fetch your Claude usage"))
        #expect(model.learnMoreButtonTitle == "Learn More…")
    }
}
