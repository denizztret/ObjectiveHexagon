import HexagonKit
import HexagonKitUI
import SwiftUI

/// Rings (`#rings-single`, `#rings-spiral`, `#rings-spiral-coordinates`): the
/// ring and the spiral out to the hex under the pointer, and the index of every
/// hex in the spiral.
struct RingsScreen: View {
  enum Part: String, CaseIterable {
    case ring
    case spiral
    case spiralCoordinates = "spiral-coordinates"
  }

  @State private var part: Part
  @State private var pointer: Hex
  @State private var rings = 4
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _part = State(initialValue: opening.part.flatMap(Part.init(rawValue:)) ?? .ring)
    _pointer = State(initialValue: opening.hex ?? Hex(q: 3, r: 0))
  }

  var body: some View {
    let orientation = settings.orientation
    ScreenFrame(caption: caption) {
      switch part {
      case .ring:
        Board(diagram: Self.ring(orientation, radius: pointer.length)) { pointer = $0 }
      case .spiral:
        Board(diagram: Self.spiral(orientation, radius: pointer.length)) { pointer = $0 }
      case .spiralCoordinates:
        Board(diagram: Self.coordinates(orientation, pointer: pointer)) { pointer = $0 }
      }
    } controls: {
      PartPicker(selection: $part)
      if part == .spiral {
        Stepper(
          "For \(rings) rings, there will be \(Hex.zero.spiral(radius: rings).count) hexes",
          value: $rings, in: 0...20)
      }
      OrientationPicker()
    }
  }

  private var caption: String {
    let radius = pointer.length
    switch part {
    case .ring:
      return "`ring(radius: \(radius))` has \(Hex.zero.ring(radius: radius).count) hexes. It "
        + "starts in direction 4 and walks the directions 0...5, counterclockwise on screen."
    case .spiral:
      return "`spiral(radius: \(radius))` is the center and then the rings 1...\(radius): "
        + "\(Hex.zero.spiral(radius: radius).count) hexes."
    case .spiralCoordinates:
      return "The number of a hex is its place in the spiral: `spiralIndex()` gives "
        + "\(pointer.spiralIndex()) here, and `Hex(spiralIndex: \(pointer.spiralIndex()))` "
        + "gives the hex back."
    }
  }

  /// A hexagon of radius 5 with one ring and the order in which it is walked.
  static func ring(_ orientation: Orientation, radius: Int) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 5))
    let ring = Hex.zero.ring(radius: radius)
    for hex in ring {
      diagram.fills[hex] = Palette.chosen
    }
    diagram.marks = chain([.zero] + (radius > 0 ? ring : []))
    return diagram
  }

  /// A hexagon of radius 5 with the spiral out to a radius.
  static func spiral(_ orientation: Orientation, radius: Int) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 5))
    let spiral = Hex.zero.spiral(radius: radius)
    for hex in spiral {
      diagram.fills[hex] = Palette.chosen
    }
    diagram.fills[.zero] = Palette.pointed
    diagram.marks = chain(spiral)
    return diagram
  }

  /// A hexagon of radius 5 with the number of every hex in the spiral.
  static func coordinates(_ orientation: Orientation, pointer: Hex) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 5))
    for hex in diagram.cells {
      diagram.labels[hex] = Label("\(hex.spiralIndex())")
    }
    diagram.fills[pointer] = Palette.pointed
    return diagram
  }

  /// Arrows from each hex to the next one.
  static func chain(_ hexes: [Hex]) -> [Mark] {
    zip(hexes, hexes.dropFirst()).map { from, to in
      .arrow(.between(from, to, 0.15), .between(from, to, 0.85), Palette.ink)
    }
  }
}
