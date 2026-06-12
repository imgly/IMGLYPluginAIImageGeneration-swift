import Foundation

/// Pixel dimensions for a generated image.
public struct ImageSize: Sendable {
  /// Width in pixels.
  public let width: Int
  /// Height in pixels.
  public let height: Int

  /// Convenience accessor returning `(width, height)`.
  public var dimensions: (width: Int, height: Int) { (width, height) }

  /// Creates an image size with the given pixel dimensions.
  public init(width: Int, height: Int) {
    self.width = width
    self.height = height
  }
}

/// Request model for image generation.
///
/// `selectedStyle` is applied client-side: ``AIGatewayService`` appends
/// `selectedStyle.promptSnippet` onto `prompt` before sending the request
/// to the gateway. The gateway itself only sees a single concatenated prompt.
public struct ImageGenerationRequest: Sendable {
  /// The text prompt describing the desired image.
  public let prompt: String
  /// Target output dimensions, or `nil` to let the service choose.
  public let size: ImageSize?
  /// The prompt style to apply (appended to the prompt client-side).
  public let selectedStyle: PromptStyle?
  /// Source image data for image-to-image generation (local images).
  public let sourceImageData: Data?
  /// Source image URL for image-to-image generation (external URLs).
  public let sourceImageURL: URL?

  /// Creates an image generation request.
  public init(
    prompt: String,
    size: ImageSize?,
    selectedStyle: PromptStyle?,
    sourceImageData: Data? = nil,
    sourceImageURL: URL? = nil,
  ) {
    self.prompt = prompt
    self.size = size
    self.selectedStyle = selectedStyle
    self.sourceImageData = sourceImageData
    self.sourceImageURL = sourceImageURL
  }
}
