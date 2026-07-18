import Foundation

/// Result returned by ``AIImageService/generateImage(with:)``.
public struct GeneratedImage: Sendable {
  /// URL of the generated image (remote or local).
  public let imageURL: URL
  /// Metadata about the generation process.
  public let metadata: ImageMetadata

  /// Creates a generated image result.
  public init(imageURL: URL, metadata: ImageMetadata) {
    self.imageURL = imageURL
    self.metadata = metadata
  }
}

/// Metadata about a generated image.
public struct ImageMetadata: Sendable {
  /// Wall-clock time the generation took, in seconds.
  public let generationTime: TimeInterval
  /// Human-readable description of the service and model used.
  public let serviceUsed: String

  /// Creates image metadata.
  public init(
    generationTime: TimeInterval,
    serviceUsed: String,
  ) {
    self.generationTime = generationTime
    self.serviceUsed = serviceUsed
  }
}
