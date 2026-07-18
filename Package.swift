// swift-tools-version:6.3.1
import PackageDescription

let package = Package(
  name: "IMGLYPluginAIImageGeneration",
  defaultLocalization: "en",
  platforms: [.iOS(.v16)],
  products: [
    .library(name: "IMGLYPluginAIImageGeneration", targets: ["IMGLYPluginAIImageGeneration"]),
  ],
  dependencies: [
    .package(url: "https://github.com/imgly/IMGLYUI-swift.git", exact: "1.79.0-rc.0"),
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
