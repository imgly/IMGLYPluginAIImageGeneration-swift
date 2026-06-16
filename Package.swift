// swift-tools-version:6.2
import PackageDescription

let package = Package(
  name: "IMGLYPluginAIImageGeneration",
  defaultLocalization: "en",
  platforms: [.iOS(.v16)],
  products: [
    .library(name: "IMGLYPluginAIImageGeneration", targets: ["IMGLYPluginAIImageGeneration"]),
  ],
  dependencies: [
    .package(url: "https://github.com/imgly/IMGLYUI-swift.git", exact: "1.77.0-rc.1"),
  ],
  targets: [
    .target(
      name: "IMGLYPluginAIImageGeneration",
      dependencies: [
        .product(name: "IMGLYUI", package: "IMGLYUI-swift"),
      ],
      resources: [
        .copy("Resources/StyleThumbnails.bundle"),
      ],
    ),
  ],
)
