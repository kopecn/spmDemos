// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "variousDemos",
    platforms: [
        .macOS(.v14)  // Minimum macOS version
    ],
    dependencies: [
        .package(url: "git@github.com:kopecn/spmFoundationTools.git", branch: "dev"),
        .package(url: "git@github.com:kopecn/spmFoundationUITools.git", branch: "dev"),
        .package(url: "git@github.com:kopecn/spmSocketHandlers.git", branch: "dev"),
        .package(url: "git@github.com:kopecn/spmSwiftRobotics.git", branch: "dev"),
        .package(url: "https://github.com/daikimat/depermaid.git", from: "1.1.0"),
        .package(url: "https://github.com/stackotter/swift-cross-ui", branch: "main"),
        .package(url: "https://github.com/kopecn/spmMathTools.git", branch: "dev"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0"),
    ],
    targets: [
        .executableTarget(
            name: "TransactionDemo",
            dependencies: [
                .product(name: "SwiftRobotics", package: "spmSwiftRobotics"),
                .product(name: "NIOHandler", package: "spmSocketHandlers"),
                .product(name: "FoundationTools", package: "spmFoundationTools"),
                .product(name: "FoundationInterfaces", package: "spmFoundationTools"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "OpenCombine", package: "OpenCombine"),
            ],
            path: "spm/Sources/TransactionDemo"
        ),
        .executableTarget(
            name: "OTGUIDemo",
            dependencies: [
                .product(name: "FoundationUITools", package: "spmFoundationUITools"),
                .product(name: "spmMathTools", package: "spmMathTools"),
                .product(name: "FoundationTypes", package: "spmFoundationTools"),
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
            ],
            path: "spm/Sources/OTGUIDemo",
            exclude: []
        ),
    ]
)
