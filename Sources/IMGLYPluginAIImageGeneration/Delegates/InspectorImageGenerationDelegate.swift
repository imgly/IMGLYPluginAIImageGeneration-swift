import Foundation
import IMGLYEditor
import IMGLYEngine

/// Delegate for enhancing selected images from the inspector context.
/// Replaces the selected image with AI-generated variations.
@MainActor
final class InspectorImageGenerationDelegate: ImageGenerationDelegate {
  private let service: AIImageService
  private let engine: Engine
  private let selectedBlockID: DesignBlockID?
  private let eventHandler: EditorEventHandler
  private let onError: (@MainActor @Sendable (_ error: Swift.Error) -> Void)?
  private var isGenerating = false

  init(inspectorContext: InspectorBar.Context, service: AIImageService,
       onError: (@MainActor @Sendable (_ error: Swift.Error) -> Void)? = nil) {
    self.service = service
    engine = inspectorContext.engine
    selectedBlockID = inspectorContext.selection.block
    eventHandler = inspectorContext.eventHandler
    self.onError = onError
  }

  func generateImage(with settings: GenerationSettings) async {
    guard !isGenerating else { return }
    guard let selectedBlock = selectedBlockID else { return }
    isGenerating = true
    defer { isGenerating = false }

    do {
      let fill = try engine.block.getFill(selectedBlock)

      try engine.block.setState(selectedBlock, state: .pending(progress: 0))

      // Prepare source image
      let currentImageURI = try engine.block.getString(fill, property: "fill/image/imageFileURI")
      let (sourceImageData, sourceURL) = try await prepareSourceImageData(from: currentImageURI)

      // Build request — sourceImageData/sourceImageURL drives the image-to-image path
      // in AIGatewayService; no separate mode flag needed.
      var modifiedSettings = settings
      modifiedSettings.sourceImageData = sourceImageData
      modifiedSettings.sourceImageURL = sourceURL
      let request = ImageGenerationUtils.createRequest(from: modifiedSettings, includeSize: false)

      // Generate
      let result = try await service.generateImage(with: request)

      // Apply result
      try applyResult(result, to: selectedBlock, fill: fill)

    } catch is CancellationError {
      // Reset to ready on cancellation
      if let selectedBlock = selectedBlockID {
        try? engine.block.setState(selectedBlock, state: .ready)
      }
    } catch {
      if let selectedBlock = selectedBlockID {
        try? engine.block.setState(selectedBlock, state: .error(.unknown))
      }
      reportError(error)
    }
  }

  // MARK: - Private

  private func reportError(_ error: Swift.Error) {
    if let onError {
      onError(error)
    } else {
      eventHandler.send(.showErrorAlert(error))
    }
  }

  private func prepareSourceImageData(from imageURI: String) async throws -> (data: Data?, url: URL?) {
    guard let imageURL = URL(string: imageURI) else {
      throw AIServiceError.invalidRequest("Invalid image URI: \(imageURI)")
    }

    if let scheme = imageURL.scheme?.lowercased(), ["http", "https"].contains(scheme) {
      return (nil, imageURL)
    } else {
      // URLSession.shared.data(from:) is async, off the main thread, and
      // cooperatively respects Task cancellation — replaces the project-banned
      // Task.detached { Data(contentsOf:) }.value pattern. Works for file:// URLs.
      let (imageData, _) = try await URLSession.shared.data(from: imageURL)
      return (imageData, nil)
    }
  }

  private func applyResult(
    _ result: GeneratedImage,
    to block: DesignBlockID,
    fill: DesignBlockID,
  ) throws {
    try engine.block.setString(fill, property: "fill/image/imageFileURI", value: result.imageURL.absoluteString)
    try engine.block.setState(block, state: .ready)
    try engine.editor.addUndoStep()
  }
}
