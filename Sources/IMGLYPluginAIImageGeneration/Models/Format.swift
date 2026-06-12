import Foundation

/// Format presets for generated images.
///
/// The gateway accepts `format` as either a ratio enum or a `{width, height}`
/// object. The plugin exposes the preset ratios below plus a custom option
/// for free-form dimensions.
enum Format: String, CaseIterable, Codable, Sendable {
  case squareHD = "Square HD"
  case square = "Square"
  case portrait43 = "Portrait 4:3"
  case portrait169 = "Portrait 16:9"
  case landscape43 = "Landscape 4:3"
  case landscape169 = "Landscape 16:9"
  case custom = "Custom"

  /// Label shown in the picker.
  var label: String {
    switch self {
    case .squareHD: "1:1 (Square HD)"
    case .square: "1:1 (Square)"
    case .portrait43: "3:4 (Portrait)"
    case .portrait169: "9:16 (Portrait)"
    case .landscape43: "4:3 (Landscape)"
    case .landscape169: "16:9 (Landscape)"
    case .custom: "Custom"
    }
  }

  /// SF Symbol name for this format.
  var iconName: String {
    switch self {
    case .square, .squareHD: "square"
    case .portrait43, .portrait169: "rectangle.portrait"
    case .landscape43, .landscape169: "rectangle"
    case .custom: "aspectratio"
    }
  }

  var dimensions: (width: Int, height: Int) {
    switch self {
    case .squareHD: (1024, 1024)
    case .square: (512, 512)
    case .portrait43: (1024, 1365)
    case .portrait169: (1024, 1820)
    case .landscape43: (1365, 1024)
    case .landscape169: (1820, 1024)
    case .custom: (512, 512)
    }
  }

  var aspectRatio: CGFloat {
    let dims = dimensions
    return CGFloat(dims.width) / CGFloat(dims.height)
  }

  var aspectRatioLabel: String {
    switch self {
    case .square, .squareHD: "1:1"
    case .portrait43: "3:4"
    case .portrait169: "9:16"
    case .landscape43: "4:3"
    case .landscape169: "16:9"
    case .custom: "Custom"
    }
  }
}
