// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "set_default_browser",
    dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "set_default_browser",
            dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]),
        .testTarget(
            name: "set_default_browserTests",
            dependencies: ["set_default_browser"]),
    ]
)
