// swift-tools-version: 6.4

import PackageDescription

let baseSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("ApproachableConcurrency"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error),
]

let mainActorSwiftSettings: [SwiftSetting] =
    baseSwiftSettings + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "KinetixKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "KinetixDomain",
            targets: ["KinetixDomain"],
        ),
        .library(
            name: "KinetixData",
            targets: ["KinetixData"],
        ),
        .library(
            name: "KinetixPresentation",
            targets: ["KinetixPresentation"],
        ),
    ],
    targets: [
        .target(
            name: "KinetixDomain",
            swiftSettings: baseSwiftSettings,
        ),
        .target(
            name: "KinetixData",
            dependencies: ["KinetixDomain"],
            swiftSettings: baseSwiftSettings,
        ),
        .target(
            name: "KinetixPresentation",
            dependencies: ["KinetixDomain"],
            swiftSettings: mainActorSwiftSettings,
        ),
        .target(
            name: "KinetixFakes",
            dependencies: ["KinetixDomain"],
            path: "Tests/KinetixFakes",
            swiftSettings: baseSwiftSettings,
        ),
        .testTarget(
            name: "KinetixDomainTests",
            dependencies: [
                "KinetixDomain",
                "KinetixFakes",
            ],
            swiftSettings: baseSwiftSettings,
        ),
        .testTarget(
            name: "KinetixDataTests",
            dependencies: [
                "KinetixDomain",
                "KinetixData",
                "KinetixFakes",
            ],
            swiftSettings: baseSwiftSettings,
        ),
        .testTarget(
            name: "KinetixPresentationTests",
            dependencies: [
                "KinetixDomain",
                "KinetixPresentation",
                "KinetixFakes",
            ],
            swiftSettings: mainActorSwiftSettings,
        ),
        .testTarget(
            name: "KinetixGateTests",
            swiftSettings: baseSwiftSettings,
        ),
    ],
)
