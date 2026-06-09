// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Finery",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/EmergeTools/Pow", from: "1.0.0"),
        .package(url: "https://github.com/airbnb/lottie-spm", from: "4.0.0"),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Finery",
            dependencies: [
                .product(name: "Pow",     package: "Pow"),
                .product(name: "Lottie",  package: "lottie-spm"),
                .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
            ],
            path: "Finery",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
