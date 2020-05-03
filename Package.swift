// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Waxwing",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "Waxwing",
            targets: ["Waxwing"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Waxwing",
            dependencies: [],
            path: "Waxwing/Waxwing"),
        .testTarget(
            name: "WaxwingTests",
            dependencies: ["Waxwing"],
            path: "Waxwing/WaxwingTests"),
    ]
)
