import HexagonKit
import SwiftUI

/// The colors of the diagrams of the guide, after its style sheet.
enum Palette {
  /// The page behind the board.
  static let page = Color.white

  /// A plain cell, and the outline of every cell.
  static let cell = Color.hsl(60, 0.10, 0.95)
  static let edge = Color.hsl(0, 0, 0.72)

  /// The cell under the pointer.
  static let pointed = Color.hsl(60, 1, 0.85)

  /// A wall, and a cell out of sight or out of reach.
  static let wall = Color.hsl(0, 0.2, 0.7)
  static let shadow = Color.hsl(60, 0.05, 0.85)

  /// The start of a search, and the observer of the field of view.
  static let start = Color.hsl(55, 1, 0.6)

  /// Text, and text that matters less.
  static let text = Color.hsl(0, 0, 0.2)
  static let pale = Color.hsl(0, 0, 0.62)

  /// The cells of a line or a ring, and the marks drawn over them.
  static let chosen = Color.hsl(200, 0.5, 0.8)
  static let ink = Color.hsl(210, 0.7, 0.35)

  /// The color of an axis: green for `q`, blue for `r`, purple for `s`.
  static func axis(_ axis: HexAxis) -> Color {
    .hsl(hue(axis), 0.6, 0.38)
  }

  /// A light tint of the color of an axis, for cells.
  static func tint(_ axis: HexAxis) -> Color {
    .hsl(hue(axis), 0.5, 0.86)
  }

  private static func hue(_ axis: HexAxis) -> Double {
    switch axis {
    case .q: 100
    case .r: 200
    case .s: 300
    }
  }
}

extension Color {
  /// A color from a hue in degrees, a saturation and a lightness, the way the
  /// style sheet of the guide gives its colors.
  static func hsl(_ hue: Double, _ saturation: Double, _ lightness: Double) -> Color {
    let brightness = lightness + saturation * min(lightness, 1 - lightness)
    let value = brightness == 0 ? 0 : 2 * (1 - lightness / brightness)
    return Color(hue: hue / 360, saturation: value, brightness: brightness)
  }
}
