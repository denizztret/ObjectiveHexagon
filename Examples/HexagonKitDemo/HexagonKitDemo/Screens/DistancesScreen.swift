import HexagonKit
import HexagonKitUI
import SwiftUI

/// Distances (`#distances-cube`): the rings of equal distance around a hex,
/// and in each hex of the ring under the pointer the coordinate that is the
/// distance.
struct DistancesScreen: View {
  @State private var pointer: Hex
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _pointer = State(initialValue: opening.hex ?? Hex(q: 2, r: 0))
  }

  var body: some View {
    let distance = pointer.length
    ScreenFrame(
      caption: "`distance(to:)` is the largest of |q|, |r| and |s| of the difference: "
        + "\(distance) for every highlighted hex. Its coordinates of that size are in bold."
    ) {
      Board(diagram: Self.diagram(settings.orientation, pointer: pointer)) { pointer = $0 }
    } controls: {
      OrientationPicker()
    }
  }

  /// A hexagon of radius 4, darker towards the middle, with the ring of the
  /// hex under the pointer highlighted.
  static func diagram(_ orientation: Orientation, pointer: Hex) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 4))
    let ring = Hex.zero.distance(to: pointer)
    for hex in diagram.cells {
      let distance = Hex.zero.distance(to: hex)
      diagram.fills[hex] =
        distance == ring ? Palette.pointed : .hsl(60, 0.1, 0.8 + 0.04 * Double(distance))
      let bold = distance == ring ? Set(HexAxis.allCases.filter { abs(hex[$0]) == distance }) : []
      diagram.labels[hex] = .cube(hex, bold: bold)
    }
    return diagram
  }
}
