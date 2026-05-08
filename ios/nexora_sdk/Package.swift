// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "nexora_sdk",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "nexora-sdk", targets: ["nexora_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "nexora_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreBluetooth"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("CoreMotion"),
                .linkedFramework("LocalAuthentication"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("Vision"),
                .linkedFramework("Accelerate")
            ]
        )
    ]
)
