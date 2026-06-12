import Foundation
import IMGLYEngine

/// Internal utilities for converting ``GenerationSettings`` to engine-level request types.
enum ImageGenerationUtils {
  /// Convert ``GenerationSettings`` to ``ImageGenerationRequest``.
  static func createRequest(
    from settings: GenerationSettings,
    includeSize: Bool = true,
  ) -> ImageGenerationRequest {
    let size: ImageSize? = includeSize ? mapSettingsToImageSize(settings) : nil

    return ImageGenerationRequest(
      prompt: settings.prompt,
      size: size,
      selectedStyle: settings.selectedStyle,
      sourceImageData: settings.sourceImageData,
      sourceImageURL: settings.sourceImageURL,
    )
  }

  /// Convert ``GenerationSettings`` to ``ImageSize``.
  static func mapSettingsToImageSize(_ settings: GenerationSettings) -> ImageSize {
    let dims = settings.actualDimensions
    return ImageSize(width: dims.width, height: dims.height)
  }
}
