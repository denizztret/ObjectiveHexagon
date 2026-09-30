import HexagonKit
import HexagonKitUI
import SwiftUI

/// Map shapes (`#map-storage`; the pictures of section 4.2 of the
/// implementation page): the five shapes of `HexShape`, their coordinates
/// colored as on that page, and the index of a hex in its shape.
struct ShapesScreen: View {
  enum Part: String, CaseIterable {
    case parallelogram
    case triangleDown = "triangle-down"
    case triangleUp = "triangle-up"
    case hexagon
    case rectangle
    case rectangleCentered = "rectangle-centered"
  }

  @State private var part: Part
  @State private var pointer: Hex?
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _part = State(initialValue: opening.part.flatMap(Part.init(rawValue:)) ?? .parallelogram)
    _pointer = State(initialValue: opening.hex)
  }

  var body: some View {
    let shape = Self.shape(part, settings.orientation)
    ScreenFrame(caption: caption(shape)) {
      Board(diagram: Self.diagram(shape, settings.orientation, pointer: pointer)) { pointer = $0 }
    } controls: {
      PartPicker(selection: $part)
      OrientationPicker()
    }
  }

  private func caption(_ shape: HexShape) -> String {
    let count = "The shape has \(shape.count) hexes, numbered row by row."
    guard let pointer, let index = shape.index(of: pointer) else {
      return count + " Center black; q = 0 green, r = 0 blue, s = 0 purple."
    }
    return count + " `index(of:)` gives \(index) for the hex under the pointer, the place of "
      + "its value in a `DenseHexMap` of this shape."
  }

  /// The shapes of the implementation page: a parallelogram with q and r in
  /// -2...2, triangles and a hexagon of size 5 and 3, and rectangles of 7 by 5
  /// hexes from a corner and around the middle, odd-r for pointy cells and
  /// odd-q for flat ones.
  static func shape(_ part: Part, _ orientation: Orientation) -> HexShape {
    let system: OffsetSystem = orientation == .pointy ? .oddR : .oddQ
    switch part {
    case .parallelogram:
      return .parallelogram(origin: Hex(q: -2, r: -2), columns: 5, rows: 5)
    case .triangleDown:
      return .triangleDown(size: 5)
    case .triangleUp:
      return .triangleUp(size: 5)
    case .hexagon:
      return .hexagon(radius: 3)
    case .rectangle:
      return .rectangle(columns: 7, rows: 5, in: system)
    case .rectangleCentered:
      return .rectangle(
        origin: OffsetCoordinate(column: -3, row: -2), columns: 7, rows: 5, in: system)
    }
  }

  /// The cells of a shape labeled with their coordinates.
  static func diagram(_ shape: HexShape, _ orientation: Orientation, pointer: Hex?) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: shape.cells())
    for hex in diagram.cells {
      diagram.labels[hex] = Label(
        "\(hex.q), \(hex.r), \(hex.s)", color: color(of: hex), scale: 0.28)
    }
    if let pointer {
      diagram.fills[pointer] = Palette.pointed
    }
    return diagram
  }

  /// The colors of the implementation page: the center black, the hexes where
  /// q, r or s is zero in the color of that axis, the others gray.
  static func color(of hex: Hex) -> Color {
    if hex == .zero {
      return .black
    }
    if let axis = HexAxis.allCases.first(where: { hex[$0] == 0 }) {
      return Palette.axis(axis)
    }
    return Palette.pale
  }
}
