import PhotosUI
import SwiftUI
import UIKit

/// Text-to-image (and optional image-to-image) generation form view.
///
/// Styles are applied **client-side** by appending
/// ``PromptStyle/promptSnippet`` to the prompt before sending the request
/// to the gateway.
struct TextGenerationView: View {
  @Binding var settings: GenerationSettings
  @Binding var sourceImage: UIImage?
  @Binding var sourceImageData: Data?
  @Binding var selectedPhotoItem: PhotosPickerItem?

  let configuration: TextGenerationConfiguration

  @FocusState private var promptIsFocused: Bool
  @State private var showCustomDimensionsInput = false
  @State private var showAllStyles = false

  init(
    settings: Binding<GenerationSettings>,
    sourceImage: Binding<UIImage?> = .constant(nil),
    sourceImageData: Binding<Data?> = .constant(nil),
    selectedPhotoItem: Binding<PhotosPickerItem?> = .constant(nil),
    configuration: TextGenerationConfiguration,
  ) {
    _settings = settings
    _sourceImage = sourceImage
    _sourceImageData = sourceImageData
    _selectedPhotoItem = selectedPhotoItem
    self.configuration = configuration
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: configuration.sectionSpacing) {
        if configuration.showsPromptInput {
          promptInputSection
        }

        if configuration.showsStyleSelector || configuration.showsFormatSelector {
          controlsRow
        }
      }
      .padding()
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
    .onTapGesture {
      promptIsFocused = false
    }
    .onChange(of: settings.format) { _ in
      showCustomDimensionsInput = (settings.format == .custom)
    }
    .sheet(isPresented: $showCustomDimensionsInput) {
      customDimensionsSheet
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }
  }

  // MARK: - Custom Dimensions Sheet

  private var customDimensionsSheet: some View {
    VStack(spacing: 16) {
      Text(.aiImageGeneration_labelCustomSize)
        .font(.headline)

      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(.aiImageGeneration_textImageWidthPx)
            .font(.caption)
            .foregroundColor(.secondary)
          TextField(String("1024"), value: $settings.customWidth, format: .number)
            .font(.title3.monospacedDigit())
            .keyboardType(.numberPad)
            .padding(.horizontal, 10)
            .frame(height: 44)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(.aiImageGeneration_textImageHeightPx)
            .font(.caption)
            .foregroundColor(.secondary)
          TextField(String("1024"), value: $settings.customHeight, format: .number)
            .font(.title3.monospacedDigit())
            .keyboardType(.numberPad)
            .padding(.horizontal, 10)
            .frame(height: 44)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
      }

      HStack(spacing: 12) {
        Button {
          settings.format = .squareHD
          showCustomDimensionsInput = false
        } label: {
          Text(.aiImageGeneration_buttonCancel)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)

        Button {
          showCustomDimensionsInput = false
        } label: {
          Text(.aiImageGeneration_buttonApply)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      }
    }
    .padding(20)
  }

  // MARK: - Prompt Input

  private var promptInputSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 0) {
        if configuration.enablesImageToImage {
          imagePickerRow
            .padding(.top, 10)
            .padding(.horizontal, 10)
        }

        ZStack(alignment: .topLeading) {
          if settings.prompt.isEmpty {
            Text(.aiImageGeneration_placeholderPrompt)
              .foregroundColor(Color(.placeholderText))
              .padding(.horizontal, 12)
              .padding(.vertical, 16)
          }
          TextEditor(text: $settings.prompt)
            .frame(minHeight: configuration.promptMinHeight)
            .padding(8)
            .focused($promptIsFocused)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
      }
      .background(configuration.promptBackgroundColor)
      .cornerRadius(configuration.promptCornerRadius)
    }
  }

  @ViewBuilder
  private var imagePickerRow: some View {
    if let image = sourceImage {
      HStack(spacing: 8) {
        ZStack(alignment: .topTrailing) {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 64, height: 64)
            .clipped()
            .cornerRadius(8)

          Button {
            sourceImage = nil
            sourceImageData = nil
            selectedPhotoItem = nil
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 10, weight: .bold))
              .foregroundColor(.primary)
              .frame(width: 20, height: 20)
              .background(Color(.systemBackground))
              .clipShape(Circle())
              .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
          }
          .offset(x: 6, y: -6)
        }
        Spacer()
      }
    } else {
      PhotosPicker(
        selection: $selectedPhotoItem,
        matching: .images,
        photoLibrary: .shared(),
      ) {
        HStack(alignment: .center, spacing: 3) {
          Image(systemName: "plus")
            .font(.system(size: 12, weight: .medium))
          Text(.aiImageGeneration_buttonAddImageOptional)
            .font(.subheadline)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(.quaternarySystemFill))
        .cornerRadius(40)
      }
    }
  }

  // MARK: - Controls Row

  private var controlsRow: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .bottom, spacing: 12) {
        if configuration.showsStyleSelector {
          styleButton.fixedSize()
        }

        if configuration.showsFormatSelector, sourceImage == nil {
          formatButton.fixedSize()
        }
      }
      .fixedSize()
      .padding(.horizontal)
    }
    .padding(.horizontal, -16)
  }

  // MARK: - Style Button

  private var styleButton: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(.aiImageGeneration_labelImageStyle)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.leading, 14)

      Button {
        showAllStyles = true
      } label: {
        HStack(spacing: 8) {
          styleThumbnailView
            .frame(width: 32, height: 36)
            .background(.black)
            .clipShape(StyleThumbnailShape())
            .overlay(
              StyleThumbnailShape()
                .inset(by: 0.25)
                .stroke(Color(.separator), lineWidth: 0.5),
            )

          Text(currentStyle.displayName)
            .font(.subheadline)
            .foregroundColor(.primary)
        }
        .padding(.trailing, 14)
        .padding(.leading, 2)
        .padding(.vertical, 2)
        .background(Color(.quaternarySystemFill))
        .cornerRadius(40)
      }
    }
    .sheet(isPresented: $showAllStyles) {
      AllStylesSheet(
        styles: configuration.availableStyles,
        selectedStyle: settings.selectedStyle ?? configuration.availableStyles.first,
        onStyleSelected: { style in
          var transaction = Transaction()
          transaction.disablesAnimations = true
          withTransaction(transaction) {
            settings.selectedStyle = style
          }
        },
      )
    }
  }

  // MARK: - Format Button

  private var formatButton: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(.aiImageGeneration_labelFormat)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.leading, 14)

      formatMenu
    }
  }

  private var formatMenu: some View {
    Menu {
      ForEach(configuration.availableFormats, id: \.self) { format in
        Button {
          if format == .custom {
            settings.format = .custom
            showCustomDimensionsInput = true
          } else {
            settings.format = format
          }
        } label: {
          Label(format.label, systemImage: format.iconName)
        }
      }
    } label: {
      HStack(spacing: 4) {
        Image(systemName: settings.format.iconName)
          .font(.subheadline)
        Text(formatButtonLabel)
          .font(.subheadline)
          .lineLimit(1)
      }
      .frame(minWidth: 150, alignment: .center)
      .foregroundColor(.primary)
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background(Color(.quaternarySystemFill))
      .cornerRadius(40)
    }
  }

  private var formatButtonLabel: String {
    if settings.format == .custom {
      return "\(settings.customWidth) × \(settings.customHeight)"
    }
    return settings.format.label
  }

  // MARK: - Style Accessors

  private var currentStyle: PromptStyle {
    settings.selectedStyle ?? configuration.availableStyles.first ?? PromptStyle.curated[0]
  }

  @ViewBuilder
  private var styleThumbnailView: some View {
    if let url = currentStyle.thumbnailURL {
      CachedThumbnailImage(url: url.absoluteString) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Color(.systemGray5)
      }
    } else {
      Color(.systemGray5)
    }
  }
}

// MARK: - Shapes

/// Asymmetric thumbnail shape: left side fully rounded, right side 8pt radius.
struct StyleThumbnailShape: InsettableShape {
  var insetAmount: CGFloat = 0

  func path(in rect: CGRect) -> Path {
    let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
    return Path(
      roundedRect: insetRect,
      cornerRadii: RectangleCornerRadii(
        topLeading: 100,
        bottomLeading: 100,
        bottomTrailing: 8,
        topTrailing: 8,
      ),
    )
  }

  func inset(by amount: CGFloat) -> StyleThumbnailShape {
    var shape = self
    shape.insetAmount += amount
    return shape
  }
}

// MARK: - Style Picker Sheet

/// Full-screen style picker sheet — a grid of ``PromptStyle`` cards.
struct AllStylesSheet: View {
  let styles: [PromptStyle]
  let selectedStyle: PromptStyle?
  let onStyleSelected: (PromptStyle) -> Void

  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 100))], spacing: 8) {
          ForEach(styles) { style in
            StyleThumbnailCard(
              title: style.displayName,
              imageURL: style.thumbnailURL?.absoluteString,
              isSelected: selectedStyle?.id == style.id,
              action: {
                onStyleSelected(style)
                dismiss()
              },
            )
          }
        }
        .padding()
      }
      .navigationTitle(Text(.aiImageGeneration_titleSelectStyle))
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
          } label: {
            Text(.aiImageGeneration_buttonDone)
          }
        }
      }
    }
  }
}

// MARK: - Style Thumbnail Card

/// Unified card view for style selection.
struct StyleThumbnailCard: View {
  let title: String
  let imageURL: String?
  let isSelected: Bool
  let action: () -> Void

  private let thumbnailSize: CGFloat = 80
  private let imageCornerRadius: CGFloat = 8
  private let borderCornerRadius: CGFloat = 10
  private let borderPadding: CGFloat = 4

  var body: some View {
    Button(action: action) {
      VStack(spacing: 3) {
        thumbnailImage
          .frame(width: thumbnailSize, height: thumbnailSize)
          .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius))
          .padding(borderPadding)
          .overlay(
            RoundedRectangle(cornerRadius: borderCornerRadius)
              .inset(by: 1)
              .stroke(Color.accentColor, lineWidth: 2)
              .opacity(isSelected ? 1 : 0),
          )

        Text(title)
          .font(.caption2)
          .lineLimit(2, reservesSpace: true)
          .truncationMode(.tail)
          .multilineTextAlignment(.center)
          .foregroundColor(.primary)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var thumbnailImage: some View {
    if let imageURL {
      CachedThumbnailImage(url: imageURL) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        thumbnailPlaceholder
      }
    } else {
      thumbnailPlaceholder
    }
  }

  private var thumbnailPlaceholder: some View {
    RoundedRectangle(cornerRadius: imageCornerRadius)
      .fill(.linearGradient(
        .init(colors: [Color(.quaternarySystemFill), Color(.systemFill)]),
        startPoint: .top,
        endPoint: .bottom,
      ))
  }
}

// MARK: - Thumbnail Cache

/// Simple in-memory cache for thumbnail data.
final class ThumbnailCache: @unchecked Sendable {
  static let shared = ThumbnailCache()

  private let dataCache = NSCache<NSString, NSData>()

  private init() {
    dataCache.countLimit = 120
  }

  func data(for key: String) -> Data? {
    dataCache.object(forKey: key as NSString) as Data?
  }

  func setData(_ data: Data, for key: String) {
    dataCache.setObject(data as NSData, forKey: key as NSString)
  }
}

/// Cached thumbnail view. Handles both bundle `file://` URLs and remote
/// `https://` URLs.
struct CachedThumbnailImage<Content: View, Placeholder: View>: View {
  let url: String
  let content: (Image) -> Content
  let placeholder: () -> Placeholder

  @State private var uiImage: UIImage?

  init(
    url: String,
    @ViewBuilder content: @escaping (Image) -> Content,
    @ViewBuilder placeholder: @escaping () -> Placeholder,
  ) {
    self.url = url
    self.content = content
    self.placeholder = placeholder
  }

  var body: some View {
    Group {
      if let uiImage {
        content(Image(uiImage: uiImage))
      } else {
        placeholder()
      }
    }
    .task(id: url) {
      await load()
    }
  }

  private func load() async {
    if let cached = ThumbnailCache.shared.data(for: url), let img = UIImage(data: cached) {
      uiImage = img
      return
    }

    guard let requestURL = URL(string: url) else { return }

    if requestURL.isFileURL {
      if let data = try? Data(contentsOf: requestURL) {
        ThumbnailCache.shared.setData(data, for: url)
        uiImage = UIImage(data: data)
      }
      return
    }

    do {
      let (data, response) = try await URLSession.shared.data(from: requestURL)
      guard let httpResponse = response as? HTTPURLResponse,
            (200 ... 299).contains(httpResponse.statusCode),
            let image = UIImage(data: data) else { return }
      ThumbnailCache.shared.setData(data, for: url)
      uiImage = image
    } catch {}
  }
}
