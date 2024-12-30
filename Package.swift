// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "Swipy",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Swipy",
            targets: ["Swipy"]
        )
    ],
    targets: [
        .target(
            name: "Swipy",
            dependencies: [],
            path: "Swipy"
        )
    ],
    swiftLanguageModes: [.v5, .v6]
)
