import Foundation
import SwiftUI

// MARK: - Sheet Configuration

/// Configuration for the image generation sheet (feature toggles, styles).
struct ImageGenerationUIConfiguration: Sendable {
  let showsCancelButton: Bool
  let enablesImageToImage: Bool
  let showsFormatSelector: Bool
  let styles: [PromptStyle]

  init(
    showsCancelButton: Bool = true,
    enablesImageToImage: Bool = true,
    showsFormatSelector: Bool = true,
    styles: [PromptStyle] = PromptStyle.curated,
  ) {
    self.showsCancelButton = showsCancelButton
    self.enablesImageToImage = enablesImageToImage
    self.showsFormatSelector = showsFormatSelector
    self.styles = styles
  }
}

// MARK: - Form Configuration

/// Configuration for the text generation form (sections, layout).
struct TextGenerationConfiguration: Sendable {
  let showsPromptInput: Bool
  let showsStyleSelector: Bool
  let showsFormatSelector: Bool
  let enablesImageToImage: Bool
  let promptMinHeight: CGFloat
  let promptBackgroundColor: Color
  let promptCornerRadius: CGFloat
  let availableStyles: [PromptStyle]
  let availableFormats: [Format]
  let sectionSpacing: CGFloat

  init(
    showsPromptInput: Bool = true,
    showsStyleSelector: Bool = true,
    showsFormatSelector: Bool = true,
    enablesImageToImage: Bool = true,
    promptMinHeight: CGFloat = 100,
    promptBackgroundColor: Color = Color(.systemBackground),
    promptCornerRadius: CGFloat = 10,
    availableStyles: [PromptStyle] = PromptStyle.curated,
    availableFormats: [Format] = Format.allCases,
    sectionSpacing: CGFloat = 20,
  ) {
    self.showsPromptInput = showsPromptInput
    self.showsStyleSelector = showsStyleSelector
    self.showsFormatSelector = showsFormatSelector
    self.enablesImageToImage = enablesImageToImage
    self.promptMinHeight = promptMinHeight
    self.promptBackgroundColor = promptBackgroundColor
    self.promptCornerRadius = promptCornerRadius
    self.availableStyles = availableStyles
    self.availableFormats = availableFormats
    self.sectionSpacing = sectionSpacing
  }
}
