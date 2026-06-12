import Foundation

/// A style preset that steers image generation via prompt engineering.
///
/// The ``AIGatewayService`` appends ``promptSnippet`` to the user's
/// prompt before sending the request — no gateway model exposes a native
/// `style` parameter today. Custom ``AIImageService`` implementations
/// can interpret ``id`` or ``promptSnippet`` however they wish.
public struct PromptStyle: Identifiable, Hashable, Sendable, Codable {
  /// Stable identifier. Custom services can use this to map to their
  /// own provider-specific style parameter.
  public let id: String

  /// Human-readable name shown in the style picker.
  public let displayName: String

  /// Prompt fragment appended to the user's prompt by ``AIGatewayService``.
  /// Empty for the "none" style. Custom services may ignore this.
  public let promptSnippet: String

  /// Optional thumbnail image URL. Both `file://` (bundle) and `https://`
  /// (CDN) URLs are supported. `nil` renders a gradient placeholder.
  public let thumbnailURL: URL?

  public init(
    id: String,
    displayName: String,
    promptSnippet: String,
    thumbnailURL: URL? = nil,
  ) {
    self.id = id
    self.displayName = displayName
    self.promptSnippet = promptSnippet
    self.thumbnailURL = thumbnailURL
  }
}

// MARK: - Curated style list

public extension PromptStyle {
  /// The curated style set the plugin ships with.
  ///
  /// To customize, pass your own `[PromptStyle]` array via the plugin's
  /// ``AIImageGenerationPlugin/Options/styles`` option.
  static let curated: [PromptStyle] = {
    let base = Bundle.module.url(forResource: "StyleThumbnails", withExtension: "bundle")
    func thumbnail(_ name: String) -> URL? {
      base?.appendingPathComponent("\(name).jpeg")
    }
    return [
      .init(id: "none", displayName: "None", promptSnippet: ""),
      .init(
        id: "anime-celshaded", displayName: "Anime",
        promptSnippet: "anime cel\u{2011}shaded, bright pastel palette, expressive eyes, clean line art",
        thumbnailURL: thumbnail("anime-celshaded"),
      ),
      .init(
        id: "cyberpunk-neon", displayName: "Cyberpunk",
        promptSnippet: "cyberpunk cityscape, glowing neon signage, reflective puddles, dark atmosphere",
        thumbnailURL: thumbnail("cyberpunk-neon"),
      ),
      .init(
        id: "kodak-portra-400", displayName: "Kodak Portra 400",
        promptSnippet: "shot on Kodak Portra 400, soft grain, golden\u{2011}hour warmth, 35 mm photo",
        thumbnailURL: thumbnail("kodak-portra-400"),
      ),
      .init(
        id: "watercolor-storybook", displayName: "Watercolor",
        promptSnippet: "loose watercolor washes, gentle gradients, dreamy storybook feel",
        thumbnailURL: thumbnail("watercolor-storybook"),
      ),
      .init(
        id: "dark-fantasy-realism", displayName: "Dark Fantasy",
        promptSnippet: "dark fantasy realm, moody chiaroscuro lighting, hyper\u{2011}real textures",
        thumbnailURL: thumbnail("dark-fantasy-realism"),
      ),
      .init(
        id: "vaporwave-retrofuturism", displayName: "Vaporwave",
        promptSnippet: "retro\u{2011}futuristic vaporwave, pastel sunset gradient, chrome text, VHS scanlines",
        thumbnailURL: thumbnail("vaporwave-retrofuturism"),
      ),
      .init(
        id: "minimal-vector-flat", displayName: "Vector Flat",
        promptSnippet: "minimalist flat vector illustration, bold geometry, two\u{2011}tone palette",
        thumbnailURL: thumbnail("minimal-vector-flat"),
      ),
      .init(
        id: "pixarstyle-3d-render", displayName: "3D Animation",
        promptSnippet: "Pixar\u{2011}style 3D render, oversized eyes, subtle subsurface scattering, cinematic lighting",
        thumbnailURL: thumbnail("pixarstyle-3d-render"),
      ),
      .init(
        id: "ukiyoe-woodblock", displayName: "Ukiyo-e",
        promptSnippet:
        "ukiyo\u{2011}e woodblock print, Edo\u{2011}period style, visible washi texture, limited color ink",
        thumbnailURL: thumbnail("ukiyoe-woodblock"),
      ),
      .init(
        id: "surreal-dreamscape", displayName: "Surreal",
        promptSnippet: "surreal dreamscape, floating objects, impossible architecture, vivid clouds",
        thumbnailURL: thumbnail("surreal-dreamscape"),
      ),
      .init(
        id: "steampunk-victorian", displayName: "Steampunk",
        promptSnippet: "Victorian steampunk world, ornate brass gears, leather attire, atmospheric fog",
        thumbnailURL: thumbnail("steampunk-victorian"),
      ),
      .init(
        id: "nightstreet-photo-bokeh", displayName: "Night Bokeh",
        promptSnippet: "night\u{2011}time street shot, large aperture bokeh lights, candid urban mood",
        thumbnailURL: thumbnail("nightstreet-photo-bokeh"),
      ),
      .init(
        id: "comicbook-pop-art", displayName: "Pop Art",
        promptSnippet: "classic comic\u{2011}book panel, halftone shading, exaggerated action lines, CMYK pop colors",
        thumbnailURL: thumbnail("comicbook-pop-art"),
      ),
    ]
  }()
}
