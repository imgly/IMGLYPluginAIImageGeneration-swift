import Foundation

/// Protocol defining the interface for AI image generation services.
///
/// Implementations are free to choose their own isolation strategy.
/// The plugin always calls ``generateImage(with:)`` from a `@MainActor`
/// context, but the method itself is not `@MainActor`-isolated so
/// implementations can run network I/O on the cooperative thread pool.
public protocol AIImageService: Sendable {
  /// Generate an image based on the provided request.
  func generateImage(with request: ImageGenerationRequest) async throws -> GeneratedImage
}

/// Errors thrown by ``AIImageService`` implementations.
public enum AIServiceError: LocalizedError {
  /// The request parameters are invalid (e.g. empty prompt, unsupported format).
  case invalidRequest(String)
  /// The generation process failed on the provider side.
  case generationFailed(String)

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
    case let .invalidRequest(reason):
      "Invalid request: \(reason)"
    case let .generationFailed(reason):
      "Image generation failed: \(reason)"
    }
  }
}
