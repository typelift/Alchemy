// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "Alchemy",
	products: [
		.library(
			name: "Alchemy",
			targets: ["Alchemy"]),
	],
    dependencies: [
      .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.9.0"),
    ],
	targets: [
		.target(
			name: "Alchemy"),
		.testTarget(
			name: "AlchemyTests",
			dependencies: ["Alchemy", "SwiftCheck"]),
		]
)
