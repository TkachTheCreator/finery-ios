// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Finery",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Finery",
            targets: ["Finery"]
        )
    ],
    targets: [
        .target(
            name: "Finery",
            path: "Finery",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
