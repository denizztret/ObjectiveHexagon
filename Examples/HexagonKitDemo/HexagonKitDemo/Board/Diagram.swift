import HexagonKit
import SwiftUI

/// What a screen draws, as a value: a map of hexes and the layers over it. A
/// screen computes it from its own state, and the board draws it without ever
/// changing that state.
struct Diagram {
  /// The orientation of the cells.
  var orientation: Orientation

  /// The hexes of the map, in drawing order. The board fits them into its
  /// view, and the pointer counts only over them, as in the guide.
  var cells: [Hex]

  /// The fill of a hex; the others get the plain color of the guide.
  var fills: [Hex: Color] = [:]

  /// The text in the middle of a hex.
  var labels: [Hex: Label] = [:]

  /// Arrows, lines, dots, circles and texts over the map.
  var marks: [Mark] = []

  /// Room around the map for the marks, as a share of the size of a cell.
  var padding = 0.2

  /// The hex of the map that holds a fractional hex, or `nil` off the map.
  func hex(holding fractional: FractionalHex) -> Hex? {
    // Far outside the board the pointer is off the map anyway, and rounding
    // needs finite coordinates within the supported range.
    guard [fractional.q, fractional.r].allSatisfy({ $0.isFinite && abs($0) < 1e6 }) else {
      return nil
    }
    let hex = fractional.rounded()
    return cells.contains(hex) ? hex : nil
  }
}

/// A text of a diagram: runs in their own colors, sized by the cell.
struct Label {
  /// A piece of the text in one color.
  struct Run {
    var text: String
    var color = Palette.text
    var bold = false
  }

  var runs: [Run]

  /// The height of the font as a share of the size of a cell.
  var scale: Double

  init(_ runs: [Run], scale: Double = 0.34) {
    self.runs = runs
    self.scale = scale
  }

  init(_ text: String, color: Color = Palette.text, bold: Bool = false, scale: Double = 0.34) {
    self.init([Run(text: text, color: color, bold: bold)], scale: scale)
  }

  /// The cube coordinates of a hex in the colors of their axes, as the guide
  /// writes them; the coordinates of `bold` stand out.
  static func cube(_ hex: Hex, bold: Set<HexAxis> = [], scale: Double = 0.3) -> Label {
    Label(
      [
        Run(text: "\(hex.q)", color: Palette.axis(.q), bold: bold.contains(.q)),
        Run(text: ", "),
        Run(text: "\(hex.r)", color: Palette.axis(.r), bold: bold.contains(.r)),
        Run(text: ", "),
        Run(text: "\(hex.s)", color: Palette.axis(.s), bold: bold.contains(.s)),
      ], scale: scale)
  }

  /// The names of the axes in their colors, for the hex the others are
  /// counted from.
  static let axes = Label(
    [
      Run(text: "q", color: Palette.axis(.q), bold: true), Run(text: " "),
      Run(text: "r", color: Palette.axis(.r), bold: true), Run(text: " "),
      Run(text: "s", color: Palette.axis(.s), bold: true),
    ], scale: 0.34)

  /// Differences with their signs, such as `+1, 0, -1`, each in its color.
  static func signed(_ values: [(Int, Color)], scale: Double = 0.3) -> Label {
    var runs: [Run] = []
    for (index, (value, color)) in values.enumerated() {
      if index > 0 {
        runs.append(Run(text: ", "))
      }
      runs.append(Run(text: value > 0 ? "+\(value)" : "\(value)", color: color))
    }
    return Label(runs, scale: scale)
  }

  /// The cube coordinates of a vector with their signs.
  static func vector(_ hex: Hex, scale: Double = 0.3) -> Label {
    signed(
      [(hex.q, Palette.axis(.q)), (hex.r, Palette.axis(.r)), (hex.s, Palette.axis(.s))],
      scale: scale)
  }

  /// The axial coordinates of a hex, with the derived `s` pale.
  static func axial(_ hex: Hex, scale: Double = 0.3) -> Label {
    Label(
      [
        Run(text: "\(hex.q)", color: Palette.axis(.q)),
        Run(text: ", "),
        Run(text: "\(hex.r)", color: Palette.axis(.r)),
        Run(text: ", \(hex.s)", color: Palette.pale),
      ], scale: scale)
  }

  /// A column and a row, of an offset or a doubled coordinate.
  static func pair(_ column: Int, _ row: Int, scale: Double = 0.34) -> Label {
    Label(
      [
        Run(text: "\(column)", color: Palette.axis(.q)),
        Run(text: ", "),
        Run(text: "\(row)", color: Palette.axis(.r)),
      ], scale: scale)
  }
}

/// Something drawn over the map, placed by spots.
enum Mark {
  /// An arrow from one spot to another.
  case arrow(Spot, Spot, Color)

  /// A line through spots; its width is a share of the size of a cell.
  case line([Spot], Color, width: Double = 0.05, dashed: Bool = false)

  /// A dot; its radius is a share of the size of a cell.
  case dot(Spot, Color, radius: Double = 0.1)

  /// A circle around a spot through another spot.
  case circle(Spot, through: Spot, Color)

  /// A text centered on a spot.
  case text(Label, Spot)
}

/// A place on the board. The board turns it into a point of its view with the
/// layout it draws with, so a diagram never depends on the size of the view.
enum Spot {
  /// The center of a hex.
  case center(Hex)

  /// A corner of a hex, in the order of `corners(of:)`.
  case corner(Hex, Int)

  /// A point with fractional axial coordinates, as the guide places the
  /// samples of a line: hex to pixel is affine, so the board finds it from the
  /// centers of three hexes.
  case axial(Double, Double)

  /// A point of the rectangle of a hex, `frame(of:)`: `(0, 0)` is its top
  /// leading corner, `(1, 1)` its bottom trailing one.
  case frame(Hex, UnitPoint)

  /// The point with the `x` of one spot and the `y` of another.
  indirect case align(x: Spot, y: Spot)

  /// A spot moved away from another: a factor of 2 doubles their distance.
  indirect case scaled(Spot, from: Spot, by: Double)

  /// The spot a share `t` of the way from the center of one hex to the center
  /// of another.
  static func between(_ a: Hex, _ b: Hex, _ t: Double) -> Spot {
    .axial(Double(a.q) + t * Double(b.q - a.q), Double(a.r) + t * Double(b.r - a.r))
  }
}
