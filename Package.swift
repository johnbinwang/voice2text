// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Voice2Text",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Voice2Text",
            targets: ["Voice2TextApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Voice2TextApp",
            path: "Sources/Voice2TextApp"
        )
    ]
)
