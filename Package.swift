// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "set_default_browser",
	platforms: [
		.macOS(.v11)
	],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "set_default_browser",
            dependencies: []),
        .testTarget(
            name: "set_default_browserTests",
            dependencies: ["set_default_browser"]),
    ]
)
