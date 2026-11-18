// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "2048",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Game2048Core", targets: ["Game2048Core"]),
        .executable(name: "2048", targets: ["Game2048App"])
    ],
    targets: [
        .target(name: "Game2048Core"),
        .executableTarget(
            name: "Game2048App",
            dependencies: ["Game2048Core"]
        ),
        .testTarget(
            name: "Game2048CoreTests",
            dependencies: ["Game2048Core"]
        )
    ]
)
