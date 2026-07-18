import IMGLYEditor
import IMGLYEngine
import SwiftUI

// MARK: - AI Image Generation Plugin

/// A plugin that adds AI-powered image generation to the editor.
///
/// Provides two integration points:
/// - **Dock button**: Opens a text-to-image generation sheet to create new image blocks.
/// - **Inspector bar button**: Opens an image-to-image enhancement sheet for selected images.
///
/// ```swift
/// AIImageGenerationPlugin(options: .init(
///   service: AIGatewayService(apiKey: "sk_…")
/// ))
/// ```
@MainActor
public final class AIImageGenerationPlugin: EditorConfiguration {
  // MARK: - Options

  /// Plugin-specific configuration options.
  public struct Options {
    /// The AI image service provider used for generation.
    public let service: AIImageService

    /// The styles shown in the style picker. Each style carries its own
    /// thumbnail URL and prompt snippet. Defaults to ``PromptStyle/curated``.
    /// Pass an empty array to hide the style picker entirely.
    public let styles: [PromptStyle]

    /// Called when image generation fails. Use this to present a
    /// non-dismissing error alert so the editor stays open.
    /// When `nil`, the plugin falls back to the editor's built-in error
    /// alert which **dismisses the editor** after acknowledgement.
    public let onError: (@MainActor @Sendable (_ error: Swift.Error) -> Void)?

    /// Controls where the AI generation button appears in the dock.
    /// Defaults to prepending the button.
    public let dockModifier: @MainActor @Sendable (_ items: Dock.Modifier, _ button: any Dock.Item) -> Void

    /// Controls where the AI edit button appears in the inspector bar.
    /// Defaults to prepending the button.
    public let inspectorBarModifier: @MainActor @Sendable (
      _ items: InspectorBar.Modifier,
      _ button: any InspectorBar.Item,
    ) -> Void

    /// Creates plugin options.
    /// - Parameters:
    ///   - service: The AI image service provider used for generation.
    ///   - styles: Styles shown in the picker. Defaults to the built-in curated set.
    ///   - onError: Called on generation failure. Pass a closure to keep the editor open.
    ///   - dockModifier: Controls where the dock button appears. Defaults to prepending.
    ///   - inspectorBarModifier: Controls where the inspector bar button appears. Defaults to prepending.
    public init(
      service: AIImageService,
      styles: [PromptStyle] = PromptStyle.curated,
      onError: (@MainActor @Sendable (_ error: Swift.Error) -> Void)? = nil,
      dockModifier: @escaping @MainActor @Sendable (_ items: Dock.Modifier, _ button: any Dock.Item)
        -> Void = { items, button in
          items.addFirst { button }
        },
      inspectorBarModifier: @escaping @MainActor @Sendable (
        _ items: InspectorBar.Modifier,
        _ button: any InspectorBar.Item,
      ) -> Void = { items, button in
        items.addFirst { button }
      },
    ) {
      self.service = service
      self.styles = styles
      self.onError = onError
      self.dockModifier = dockModifier
      self.inspectorBarModifier = inspectorBarModifier
    }
  }

  private let options: Options

  /// Creates the plugin with the given options.
  /// - Parameter options: Plugin-specific configuration.
  public init(options: Options) {
    self.options = options
    super.init()
  }

  // MARK: - Dock

  private var dockButton: any Dock.Item {
    let aiService = options.service
    let styles = options.styles
    let onError = options.onError
    return Dock.Button(
      id: "ly.img.component.dock.button.aiImageGeneration",
      action: { context in
        let delegate = DockImageGenerationDelegate(dockContext: context, service: aiService, onError: onError)
        let config = ImageGenerationUIConfiguration(
          enablesImageToImage: true,
          styles: styles,
        )
        context.eventHandler.send(.openSheet(
          style: .default(isFloating: true, detent: .height(450), detents: [.height(450)]),
          content: {
            ImageGenerationSheet(delegate: delegate, configuration: config)
          },
        ))
      },
      label: { _ in
        Label {
          Text(.aiImageGeneration_buttonGenerate)
        } icon: {
          Image(systemName: "sparkles.rectangle.stack")
        }
      },
    )
  }

  override public var dock: Dock.Configuration? {
    let button = dockButton
    let dockModifier = options.dockModifier
    return Dock.Configuration { builder in
      builder.modify { _, items in
        dockModifier(items, button)
      }
    }
  }

  // MARK: - Inspector Bar

  private var inspectorBarButton: any InspectorBar.Item {
    let aiService = options.service
    let styles = options.styles
    let onError = options.onError
    return InspectorBar.Button(
      id: "ly.img.component.inspectorBar.button.aiImageGeneration",
      action: { context in
        let delegate = InspectorImageGenerationDelegate(inspectorContext: context, service: aiService, onError: onError)
        let config = ImageGenerationUIConfiguration(
          enablesImageToImage: false,
          showsFormatSelector: false,
          styles: styles,
        )
        context.eventHandler.send(.openSheet(
          style: .default(isFloating: true, detent: .height(450), detents: [.height(450)]),
          content: {
            ImageGenerationSheet(delegate: delegate, configuration: config)
          },
        ))
      },
      label: { _ in
        Label {
          Text(.aiImageGeneration_buttonEdit)
        } icon: {
          Image(systemName: "wand.and.stars")
        }
      },
      isEnabled: { _ in true },
      isVisible: { context in
        context.selection.fillType == .image &&
          context.selection.kind != "sticker" &&
          context.selection.kind != "animatedSticker" &&
          ((try? context.engine.block.isAllowedByScope(context.selection.block, key: "fill/change")) ?? false)
      },
    )
  }

  override public var inspectorBar: InspectorBar.Configuration? {
    let button = inspectorBarButton
    let inspectorBarModifier = options.inspectorBarModifier
    return InspectorBar.Configuration { builder in
      builder.modify { _, items in
        inspectorBarModifier(items, button)
      }
    }
  }
}
