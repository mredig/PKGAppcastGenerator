// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PKGAppcastGenerator",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
		.package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.17.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "PKGAppcastGenerator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
				"PKGAppcastGeneratorCore",
			]
        ),
		.target(
			name: "PKGAppcastGeneratorCore",
			dependencies: [
				"XMLCoder",
			])
	]
)
