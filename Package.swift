// swift-tools-version: 5.7
import PackageDescription

let package = Package(
 name: "Storage",
 platforms: [.macOS(.v12)],
 products: [.library(name: "Storage", targets: ["Storage"])],
 dependencies: [
  .package(url: "https://github.com/neutralradiance/core", branch: "main"),
  .package(url: "https://github.com/mxcl/Chalk", branch: "master")
 ],
 targets: [
  .target(
   name: "Storage",
   dependencies: [
    "Chalk",
    .product(name: "Extensions", package: "Core"),
    .product(name: "Composite", package: "Core"),
    .product(name: "Reflection", package: "Core")
   ]
  ),
  .testTarget(name: "StorageTests", dependencies: ["Storage"])
 ]
)
