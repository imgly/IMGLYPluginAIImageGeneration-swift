import IMGLYEditor
import SwiftUI

/// A wrapper view that presents ``ImageGenerationView`` with the given configuration.
struct ImageGenerationSheet: View {
  var delegate: ImageGenerationDelegate
  let configuration: ImageGenerationUIConfiguration

  init(
    delegate: ImageGenerationDelegate,
    configuration: ImageGenerationUIConfiguration = ImageGenerationUIConfiguration(),
  ) {
    self.delegate = delegate
    self.configuration = configuration
  }

  var body: some View {
    ImageGenerationView(
      delegate: delegate,
      configuration: configuration,
    )
  }
}
