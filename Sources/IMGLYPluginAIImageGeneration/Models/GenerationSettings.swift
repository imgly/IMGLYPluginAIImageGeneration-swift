import Foundation

/// Settings for image generation, managed by the UI and passed to delegates.
///
/// Styles are applied client-side by appending ``PromptStyle/promptSnippet``
/// to ``prompt`` before sending the request to the gateway.
///
/// Whether a request is text-to-image or image-to-image is derived from
/// ``sourceImageData``/``sourceImageURL`` being non-nil, not from a separate
/// mode flag — matching the Android implementation.
struct GenerationSettings: Equatable, Codable, Sendable {
  /// The prompt to use for generation.
  var prompt: String = ""

  /// The currently selected prompt style. `nil` means no style applied.
  var selectedStyle: PromptStyle?

  /// The format of the generated image.
  var format: Format = .squareHD

  /// Custom width in pixels when format is `.custom`.
  var customWidth: Int = 1024

  /// Custom height in pixels when format is `.custom`.
  var customHeight: Int = 1024

  /// Source image data for image-to-image generation (local images).
  var sourceImageData: Data?

  /// Source image URL for image-to-image generation (external URLs).
  var sourceImageURL: URL?

  /// Creates a new GenerationSettings instance.
  init() {}

  /// Returns the actual dimensions to use, honouring custom dimensions when
  /// `format == .custom`.
  var actualDimensions: (width: Int, height: Int) {
    if format == .custom {
      (customWidth, customHeight)
    } else {
      format.dimensions
    }
  }

  // Exclude sourceImageData and sourceImageURL: large blobs are expensive to compare,
  // and these transient fields are also excluded from Codable (see CodingKeys below).
  static func == (lhs: GenerationSettings, rhs: GenerationSettings) -> Bool {
    lhs.prompt == rhs.prompt &&
      lhs.selectedStyle == rhs.selectedStyle &&
      lhs.format == rhs.format &&
      lhs.customWidth == rhs.customWidth &&
      lhs.customHeight == rhs.customHeight
  }

  enum CodingKeys: String, CodingKey {
    case prompt, selectedStyle, format, customWidth, customHeight
  }
}
