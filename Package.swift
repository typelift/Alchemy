import PackageDescription

let package = Package(
	name: "Alchemy",
	targets: [
		Target(name: "Alchemy"),
	]
)

let libAlchemy = Product(name: "Alchemy", type: .Library(.Dynamic), modules: "Alchemy")
products.append(libAlchemy)

