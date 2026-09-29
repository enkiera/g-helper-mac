// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GHelperMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "GHelperMac",
            targets: ["GHelperMac"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "GHelperMac",
            dependencies: [],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
