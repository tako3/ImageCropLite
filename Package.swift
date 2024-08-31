// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ImageCropLite",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15), .iOS(.v16),
    ],
    products: [
        .library(
            name: "ImageCropLite",
            targets: ["ImageCropLite"]
        ),
    ],
    targets: [
        .target(
            name: "ImageCropLite",
            path: "Sources",
            resources: [.process("ImageCropLite/Resources")],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
