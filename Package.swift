// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Finery",
    platforms: [
        .iOS(.v18)
    ],
    targets: [
        .executableTarget(
            name: "Finery",
            path: "Finery",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
