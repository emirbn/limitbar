import Foundation
import Testing
@testable import LimitBarCore

struct ClaudeOAuthApplicationDefaultsTests {
    @Test
    func `application domain uses standard defaults without constructing a suite`() {
        var requestedDomains: [String] = []

        let defaults = ClaudeOAuthApplicationDefaults.resolve(
            domain: "com.emirbn.limitbar",
            currentBundleIdentifier: "com.emirbn.limitbar",
            suiteFactory: { domain in
                requestedDomains.append(domain)
                return nil
            })

        #expect(defaults === UserDefaults.standard)
        #expect(requestedDomains.isEmpty)
    }

    @Test
    func `child process keeps using the application suite`() throws {
        let suiteDomain = "ClaudeOAuthApplicationDefaultsTests.\(UUID().uuidString)"
        let suite = try #require(UserDefaults(suiteName: suiteDomain))
        var requestedDomains: [String] = []

        let defaults = ClaudeOAuthApplicationDefaults.resolve(
            domain: "com.emirbn.limitbar",
            currentBundleIdentifier: "com.emirbn.limitbar.widget",
            suiteFactory: { domain in
                requestedDomains.append(domain)
                return suite
            })

        #expect(defaults === suite)
        #expect(requestedDomains == ["com.emirbn.limitbar"])
    }

    @Test
    func `suite creation failure retains the standard fallback`() {
        var requestedDomains: [String] = []

        let defaults = ClaudeOAuthApplicationDefaults.resolve(
            domain: "com.emirbn.limitbar",
            currentBundleIdentifier: nil,
            suiteFactory: { domain in
                requestedDomains.append(domain)
                return nil
            })

        #expect(defaults === UserDefaults.standard)
        #expect(requestedDomains == ["com.emirbn.limitbar"])
    }
}
