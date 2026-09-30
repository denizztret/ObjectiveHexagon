import HexagonKit
import HexagonKitUI
import SwiftUI

/// Line drawing (`#line-drawing`): the hexes of the line from a fixed start to
/// the hex under the pointer, and the points it samples on the way.
struct LineScreen: View {
  static let start = Hex(q: -5, r: 0)

  @State private var pointer: Hex
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _pointer = State(initialValue: opening.hex ?? Hex(q: 4, r: 1))
  }

  var body: some View {
    let steps = Self.start.distance(to: pointer)
    ScreenFrame(
      caption: "`line(to:)` samples N + 1 points evenly between the centers and rounds each "
        + "to its hex. Here N = \(steps), the distance, so the line has \(steps + 1) hexes."
    ) {
      Board(diagram: Self.diagram(settings.orientation, end: pointer)) { pointer = $0 }
    } controls: {
      OrientationPicker()
    }
  }

  /// A hexagon of radius 6 with the line and a dot on each sample point.
  static func diagram(_ orientation: Orientation, end: Hex) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 6))
    for hex in start.line(to: end) {
      diagram.fills[hex] = Palette.chosen
    }
    let steps = max(start.distance(to: end), 1)
    diagram.marks = (0...steps).map { index in
      .dot(.between(start, end, Double(index) / Double(steps)), Palette.ink, radius: 0.13)
    }
    return diagram
  }
}
