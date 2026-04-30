// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "nexora_sdk",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14)
    ],
    products: [
        .library(name: "nexora-sdk", targets: ["nexora_sdk"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "nexora_sdk",
            dependencies: [],
            path: "ios/Classes"
        )
    ]
)
