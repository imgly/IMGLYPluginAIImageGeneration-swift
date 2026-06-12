import PhotosUI
import SwiftUI
import UIKit

/// Modal view for image generation with prompt input, style/format pickers, and a generate button.
struct ImageGenerationView: View {
  // MARK: - Properties

  var delegate: ImageGenerationDelegate?
  let configuration: ImageGenerationUIConfiguration

  @Environment(\.dismiss) var dismiss

  // MARK: - State

  @State private var settings = GenerationSettings()
  @State private var sourceImageData: Data?
  @State private var sourceImage: UIImage?
  @State private var selectedPhotoItem: PhotosPickerItem?

  // MARK: - Body

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        TextGenerationView(
          settings: $settings,
          sourceImage: $sourceImage,
          sourceImageData: $sourceImageData,
          selectedPhotoItem: $selectedPhotoItem,
          configuration: textGenerationConfiguration,
        )

        generateButton
      }
      .navigationTitle(Text(.aiImageGeneration_titleAIImageGeneration))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if configuration.showsCancelButton {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              dismiss()
            } label: {
              Image(systemName: "chevron.down.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.secondary)
                .font(.title2)
            }
            .buttonStyle(.borderless)
          }
        }
      }
    }
    .onChange(of: sourceImageData) { _ in
      settings.sourceImageData = sourceImageData
    }
    .onChange(of: selectedPhotoItem) { _ in
      Task {
        if let item = selectedPhotoItem,
           let data = try? await item.loadTransferable(type: Data.self) {
          sourceImageData = data
          sourceImage = UIImage(data: data)
        } else {
          sourceImageData = nil
          sourceImage = nil
        }
      }
    }
  }

  // MARK: - Private Views

  @ViewBuilder
  private var generateButton: some View {
    Button(action: generate) {
      Label {
        Text(.aiImageGeneration_buttonMakeIt)
      } icon: {
        Image(systemName: "sparkles")
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
    .padding()
    .disabled(isGenerateButtonDisabled)
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
  }

  // MARK: - Computed Properties

  private var isGenerateButtonDisabled: Bool {
    settings.prompt.isEmpty
  }

  private var textGenerationConfiguration: TextGenerationConfiguration {
    TextGenerationConfiguration(
      showsPromptInput: true,
      showsStyleSelector: !configuration.styles.isEmpty,
      showsFormatSelector: configuration.showsFormatSelector,
      enablesImageToImage: configuration.enablesImageToImage,
      availableStyles: configuration.styles,
      availableFormats: Format.allCases,
    )
  }

  // MARK: - Private Methods

  private func generate() {
    var finalSettings = settings
    finalSettings.sourceImageData = sourceImageData

    // Intentionally capture delegate strongly — generation must complete
    // after the sheet is dismissed, so the delegate (and its engine refs)
    // must survive until the async call finishes.
    let capturedDelegate = delegate
    dismiss()

    Task { @MainActor in
      await capturedDelegate?.generateImage(with: finalSettings)
    }
  }
}
