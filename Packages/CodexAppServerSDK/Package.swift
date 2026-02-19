// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "CodexAppServerSDK",
    platforms: [
        .visionOS(.v26),
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "CodexAppServerSDK",
            targets: ["CodexAppServerSDK"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CodexAppServerSDK",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
