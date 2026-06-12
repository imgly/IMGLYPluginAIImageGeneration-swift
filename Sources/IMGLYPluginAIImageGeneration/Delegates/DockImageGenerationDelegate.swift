import IMGLYEditor
import IMGLYEngine

/// Delegate for generating new images from the dock context.
/// Creates new image blocks on the canvas.
@MainActor
final class DockImageGenerationDelegate: ImageGenerationDelegate {
  private let service: AIImageService
  private let engine: Engine?
  private let eventHandler: EditorEventHandler?
  private let onError: (@MainActor @Sendable (_ error: Swift.Error) -> Void)?
  private var isGenerating = false

  init(dockContext: Dock.Context?, service: AIImageService,
       onError: (@MainActor @Sendable (_ error: Swift.Error) -> Void)? = nil) {
    self.service = service
    engine = dockContext?.engine
    eventHandler = dockContext?.eventHandler
    self.onError = onError
  }

  func generateImage(with settings: GenerationSettings) async {
    guard !isGenerating else { return }
    guard let engine else {
      reportError(AIServiceError.generationFailed("Editor engine unavailable."))
      return
    }
    isGenerating = true
    defer { isGenerating = false }

    var loadingBlock: DesignBlockID?

    do {
      // 1. Create loading block on canvas
      let imageSize = ImageGenerationUtils.mapSettingsToImageSize(settings)
      loadingBlock = try engine.createImageBlock(size: imageSize)

      // 2. Generate image via AI service
      let request = ImageGenerationUtils.createRequest(from: settings)
      let result = try await service.generateImage(with: request)

      // 3. Update block with generated image URL
      guard let loadingBlock else {
        throw AIServiceError.generationFailed("Failed to create image block.")
      }
      try engine.updateBlockWithURL(loadingBlock, imageURL: result.imageURL)
      try engine.editor.addUndoStep()

    } catch is CancellationError {
      // Clean up on cancellation
      if let loadingBlock {
        try? engine.block.destroy(loadingBlock)
      }
    } catch {
      // Keep the block and set error state to match Android behavior
      if let loadingBlock {
        try? engine.block.setState(loadingBlock, state: .error(.unknown))
      }
      reportError(error)
    }
  }

  private func reportError(_ error: Swift.Error) {
    if let onError {
      onError(error)
    } else {
      eventHandler?.send(.showErrorAlert(error))
    }
  }
}
