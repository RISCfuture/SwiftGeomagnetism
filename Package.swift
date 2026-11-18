// swift-tools-version: 6.2

import PackageDescription

let upcomingFeatures: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("InferIsolatedConformances"),
  .enableUpcomingFeature("ImmutableWeakCaptures"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault"),
  .strictMemorySafety()
]

let package = Package(
  name: "SwiftGeomagnetism",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v9),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "SwiftGeomagnetism",
      targets: ["SwiftGeomagnetism"]
    ),
    .library(
      name: "SwiftGeomagnetismHiRes",
      targets: ["SwiftGeomagnetismHiRes"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-numerics", from: "1.1.1")
  ],
  targets: [
    .target(
      name: "SwiftGeomagnetism",
      resources: [.copy("Resources/WMM2025.COF")],
      swiftSettings: upcomingFeatures
    ),
    .target(
      name: "SwiftGeomagnetismHiRes",
      dependencies: ["SwiftGeomagnetism"],
      resources: [.copy("Resources/WMMHR2025.COF")],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "SwiftGeomagnetismTests",
      dependencies: [
        "SwiftGeomagnetism",
        "SwiftGeomagnetismHiRes",
        .product(name: "Numerics", package: "swift-numerics")
      ],
      resources: [
        .copy("Resources/WMM2025_TEST_VALUES.txt"),
        .copy("Resources/WMMHR2025_TEST_VALUES.txt"),
        .copy("Resources/WMM2025COF_TestValues.txt"),
        .copy("Resources/BGS_WMM2025_reference_values.csv")
      ],
      swiftSettings: upcomingFeatures
    )
  ],
  swiftLanguageModes: [.v5, .v6]
)
