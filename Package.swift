// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "HexagonKit",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .watchOS(.v8),
    .visionOS(.v1),
  ],
  products: [
    .library(name: "HexagonKit", targets: ["HexagonKit"]),
    .library(name: "HexagonKitUI", targets: ["HexagonKitUI"]),
  ],
  targets: [
    .target(
      name: "HexagonKit",
      // The core imports nothing, so nothing links the C math library for it, and
      // on Linux `squareRoot()` and `rounded()` become calls into `libm`. Without
      // this setting a client that does not import Foundation fails to link.
      linkerSettings: [.linkedLibrary("m", .when(platforms: [.linux]))]
    ),
    .target(name: "HexagonKitUI", dependencies: ["HexagonKit"]),
    .testTarget(
      name: "HexagonKitTests",
      dependencies: ["HexagonKit"],
      resources: [.copy("Fixtures")]
    ),
    .testTarget(name: "HexagonKitUITests", dependencies: ["HexagonKitUI"]),
  ]
)
