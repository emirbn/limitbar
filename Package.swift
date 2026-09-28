// swift-tools-version: 6.2
import Foundation
import PackageDescription

let sweetCookieKitPath = "../SweetCookieKit"
let useLocalSweetCookieKit =
    ProcessInfo.processInfo.environment["LIMITBAR_USE_LOCAL_SWEETCOOKIEKIT"] == "1"
let sweetCookieKitDependency: Package.Dependency =
    useLocalSweetCookieKit && FileManager.default.fileExists(atPath: sweetCookieKitPath)
    ? .package(path: sweetCookieKitPath)
    : .package(url: "https://github.com/steipete/SweetCookieKit", from: "0.5.2")

let sqlite3LibDir = ProcessInfo.processInfo.environment["LIMITBAR_SQLITE3_LIB_DIR"]?
    .trimmingCharacters(in: .whitespacesAndNewlines)
let sqlite3LinkerSettings: [LinkerSetting] = if let sqlite3LibDir, !sqlite3LibDir.isEmpty {
    [.unsafeFlags(["-L\(sqlite3LibDir)"], .when(platforms: [.linux]))]
} else {
    []
}

let package = Package(
    name: "LimitBar",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: {
        var products: [Product] = [
            .library(name: "LimitBarCore", targets: ["LimitBarCore"]),
            .executable(name: "LimitBarCLI", targets: ["LimitBarCLI"]),
            // Offline adaptive-refresh replay harness. Keep the supporting library package-internal.
            .executable(name: "AdaptiveReplayCLI", targets: ["AdaptiveReplayCLI"]),
        ]

        #if os(macOS)
        products.append(contentsOf: [
            .executable(name: "LimitBar", targets: ["LimitBar"]),
            .executable(name: "LimitBarClaudeWatchdog", targets: ["LimitBarClaudeWatchdog"]),
            .executable(name: "LimitBarWidget", targets: ["LimitBarWidget"]),
            .executable(name: "LimitBarClaudeWebProbe", targets: ["LimitBarClaudeWebProbe"]),
        ])
        #endif

        return products
    }(),
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.6"),
        .package(url: "https://github.com/steipete/Commander", from: "0.2.4"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "4.5.2"),
        .package(url: "https://github.com/apple/swift-log", from: "1.15.1"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "3.1.0"),
        .package(url: "https://github.com/zats/Vortex", revision: "ef5392088d4aeb255c4eee83157dbdafcd31bf07"),
        sweetCookieKitDependency,
    ],
    targets: {
        var targets: [Target] = [
            .target(
                name: "CQuickJS",
                path: "Sources/CQuickJS",
                exclude: ["README.md", "LICENSE"],
                publicHeadersPath: "include",
                cSettings: [
                    .define("_GNU_SOURCE"),
                ],
                linkerSettings: [
                    .linkedLibrary("m", .when(platforms: [.linux])),
                ]),
            // Both glibc and static-musl CLI builds use this target; the module map supplies sqlite3 linkage.
            .systemLibrary(
                name: "CSQLite3",
                providers: [
                    .apt(["libsqlite3-dev"]),
                    .brew(["sqlite3"]),
                ]),
            .target(
                name: "LimitBarCore",
                dependencies: [
                    "CQuickJS",
                    .target(name: "CSQLite3", condition: .when(platforms: [.linux])),
                    .product(name: "Crypto", package: "swift-crypto"),
                    .product(name: "Logging", package: "swift-log"),
                    .product(name: "SweetCookieKit", package: "SweetCookieKit"),
                ],
                resources: [
                    .process("Resources"),
                ],
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ],
                linkerSettings: sqlite3LinkerSettings + [
                    .linkedFramework("JavaScriptCore", .when(platforms: [.macOS])),
                ]),
            .executableTarget(
                name: "LimitBarCLI",
                dependencies: [
                    "LimitBarCore",
                    .product(name: "Commander", package: "Commander"),
                    .product(name: "Crypto", package: "swift-crypto"),
                ],
                path: "Sources/LimitBarCLI",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ],
                linkerSettings: sqlite3LinkerSettings),
            // Crash-test subprocess: tests SIGKILL it mid-save to prove the cost store's
            // save cycle is atomic. Not shipped; built only as a test dependency.
            .executableTarget(
                name: "LimitBarCostStoreCrashProbe",
                dependencies: ["LimitBarCore"],
                path: "Sources/LimitBarCostStoreCrashProbe",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ],
                linkerSettings: sqlite3LinkerSettings),
            // Sole owner of the adaptive refresh decision table. Package-internal so the app and
            // offline replay tool share behavior without publishing another library product.
            .target(
                name: "AdaptiveRefreshCore",
                dependencies: [],
                path: "Sources/AdaptiveRefreshCore",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
            // Offline adaptive-refresh replay harness: pure Foundation,
            // no LimitBar/LimitBarCore dependency, so it builds anywhere LimitBarCore does.
            .target(
                name: "AdaptiveReplayKit",
                dependencies: ["AdaptiveRefreshCore"],
                path: "Sources/AdaptiveReplayKit",
                exclude: ["README.md"],
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
            .executableTarget(
                name: "AdaptiveReplayCLI",
                dependencies: ["AdaptiveReplayKit"],
                path: "Sources/AdaptiveReplayCLI",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
            .testTarget(
                name: "AdaptiveReplayCLITests",
                dependencies: ["AdaptiveReplayCLI", "AdaptiveReplayKit"],
                path: "Tests/AdaptiveReplayCLITests",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                    .enableExperimentalFeature("SwiftTesting"),
                ]),
            .testTarget(
                name: "AdaptiveReplayKitTests",
                dependencies: ["AdaptiveRefreshCore", "AdaptiveReplayKit"],
                path: "Tests/AdaptiveReplayKitTests",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                    .enableExperimentalFeature("SwiftTesting"),
                ]),
            .testTarget(
                name: "LimitBarPluginTests",
                dependencies: ["LimitBarCore"],
                path: "TestsPlugin",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                    .enableExperimentalFeature("SwiftTesting"),
                ]),
            .testTarget(
                name: "LimitBarLinuxTests",
                dependencies: [
                    "LimitBarCore",
                    "LimitBarCLI",
                    .target(name: "CSQLite3", condition: .when(platforms: [.linux])),
                ],
                path: "TestsLinux",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                    .enableExperimentalFeature("SwiftTesting"),
                ]),
        ]

        #if os(macOS)
        targets.append(contentsOf: [
            .executableTarget(
                name: "LimitBarClaudeWatchdog",
                dependencies: [],
                path: "Sources/LimitBarClaudeWatchdog",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
            .executableTarget(
                name: "LimitBar",
                dependencies: [
                    .product(name: "Sparkle", package: "Sparkle"),
                    .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                    .product(name: "Vortex", package: "Vortex"),
                    "AdaptiveRefreshCore",
                    "LimitBarCore",
                ],
                path: "Sources/LimitBar",
                resources: [
                    .process("Resources"),
                ],
                swiftSettings: [
                    // Opt into Swift 6 strict concurrency (approachable migration path).
                    .enableUpcomingFeature("StrictConcurrency"),
                    .define("ENABLE_SPARKLE"),
                ]),
            .executableTarget(
                name: "LimitBarWidget",
                dependencies: ["LimitBarCore"],
                path: "Sources/LimitBarWidget",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
            .executableTarget(
                name: "LimitBarClaudeWebProbe",
                dependencies: ["LimitBarCore"],
                path: "Sources/LimitBarClaudeWebProbe",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
        ])

        targets.append(.testTarget(
            name: "LimitBarTests",
            dependencies: [
                "LimitBar", "LimitBarCore", "LimitBarCLI", "LimitBarCostStoreCrashProbe", "LimitBarWidget",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Tests",
            exclude: [
                "AdaptiveReplayCLITests",
                "AdaptiveReplayKitTests",
                "LimitBarTests/ProviderPluginDetailsParityTests.swift",
                "LimitBarTests/ProviderPluginExtensionParityTests.swift",
                "LimitBarTests/ProviderPluginParityTests.swift",
                "LimitBarTests/ProviderPluginRuntimeTests.swift",
                "LimitBarTests/Sub2APIPluginGoldenTests.swift",
            ],
            resources: [
                .copy("LimitBarTests/Fixtures"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ],
            linkerSettings: [
                // XCTest's executable is three directories below its sibling framework products.
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@loader_path/../../.."]),
            ]))
        #endif

        return targets
    }())
