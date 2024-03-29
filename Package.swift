// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "URLSessionAsync",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(
            name: "URLSessionAsync",
            targets: ["URLSessionAsync"]),
    ],
    targets: [
        .target(
            name: "URLSessionAsync"),
        .testTarget(
            name: "URLSessionAsyncTests",
            dependencies: ["URLSessionAsync"]),
    ]
)
