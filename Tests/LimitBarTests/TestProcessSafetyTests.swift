import Testing
@testable import LimitBarCore

struct TestProcessSafetyTests {
    @Test
    func `current process is recognized without callers supplying runner signals`() {
        #expect(TestProcessSafety.isRunning)
    }

    @Test(arguments: [["/tmp/Suite.xctest"], ["swift-testing"], ["/tmp/XCTestRunner"]])
    func `recognizes runner executable arguments`(arguments: [String]) {
        #expect(TestProcessSafety.isRunningUnderTests(
            processName: "runner",
            environment: [:],
            arguments: arguments))
    }

    @Test(arguments: [
        ["/usr/local/bin/limitbar", "--account", "swift-testing"],
        ["/usr/local/bin/limitbar", "--account", "xctest"],
        ["/usr/local/bin/limitbar", "--account", "Example.xctest"],
        ["/tmp/swift-testing/limitbar", "usage"],
        ["/tmp/Example.xctest/limitbar", "usage"],
        ["/tmp/XCTestRunnerTools/limitbar", "usage"],
    ])
    func `ordinary argument values and installation paths retain production behavior`(arguments: [String]) {
        #expect(!TestProcessSafety.isRunningUnderTests(
            processName: "limitbar",
            environment: [:],
            arguments: arguments))
    }

    @Test(arguments: [
        ("swiftpm-testing-helper", [:]),
        ("LimitBarPackageTests", [:]),
        ("LimitBarPackageTests.xctest", [:]),
        ("LimitBar", ["XCTestConfigurationFilePath": "fixture"]),
        ("LimitBar", ["XCTestBundlePath": "fixture"]),
        ("LimitBar", ["XCTestSessionIdentifier": "fixture"]),
        ("LimitBar", ["TESTING_LIBRARY_VERSION": "fixture"]),
        ("LimitBar", ["SWIFT_TESTING": "fixture"]),
        ("LimitBar", ["SWIFT_TESTING_ENABLED": "fixture"]),
    ] as [(String, [String: String])])
    func `recognizes every supported runner signal`(
        processName: String,
        environment: [String: String])
    {
        #expect(TestProcessSafety.isRunningUnderTests(
            processName: processName,
            environment: environment))
    }

    @Test
    func `recognizes the loaded XCTest fallback without class lookup side effects`() {
        #expect(TestProcessSafety.isRunningUnderTests(
            processName: "LimitBar",
            environment: [:],
            hasLoadedXCTestCase: true))
    }

    @Test
    func `does not classify an ordinary app process as a test runner`() {
        #expect(!TestProcessSafety.isRunningUnderTests(
            processName: "LimitBar",
            environment: [:]))
    }
}
