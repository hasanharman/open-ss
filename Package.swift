// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "OpenSS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OpenSS", targets: ["OpenSS"])
    ],
    targets: [
        .executableTarget(
            name: "OpenSS",
            path: "Sources/OpenSS"
        )
    ]
)
