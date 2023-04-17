// swift-tools-version: 5.5

import PackageDescription

let package = Package(
 name: "Storage",
 platforms: [.macOS(.v12), .iOS(.v14)],
 products: [.library(name: "Storage", targets: ["Storage"])],
 dependencies: [
//  .package(path: "../Core"),
//  .package(path: "../Configuration")
  .package(url: "https://github.com/neutralradiance/core", branch: "main"),
  .package(
   url: "https://github.com/neutralradiance/configuration", branch: "main"
  )
 ],
 targets: [
  .target(
   name: "Storage",
   dependencies: [
    .product(name: "Extensions", package: "Core"),
    .product(name: "Composite", package: "Core"),
    .product(name: "Reflection", package: "Core"),
    .product(name: "Configuration", package: "configuration")
   ]
  ),
  .testTarget(name: "StorageTests", dependencies: ["Storage"])
 ]
)
