import HexagonKit
import HexagonKitUI
import SwiftUI

/// Wraparound maps (`#wraparound`): a hexagon of radius 2 and its six mirror
/// copies; a hex anywhere wraps to one hex of the map and shows up in every copy.
struct WraparoundScreen: View {
  static let map = WrappedHexagon(radius: 2)

  @State private var pointer: Hex?
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _pointer = State(initialValue: opening.hex)
  }

  var body: some View {
    ScreenFrame(caption: caption) {
      Board(diagram: Self.diagram(settings.orientation, pointer: pointer)) { pointer = $0 }
    } controls: {
      OrientationPicker()
    }
  }

  private var caption: String {
    guard let pointer else {
      return "The six copies sit around the mirror centers; the first one is at 5, -2, -3."
    }
    let original = Self.map.wrap(pointer)
    return "`wrap(_:)` takes \(pointer.q), \(pointer.r), \(pointer.s) to \(original.q), "
      + "\(original.r), \(original.s) of the map, highlighted in the middle and in every copy."
  }

  /// The map, its copies around the mirror centers in two alternating shades
  /// with the centers darker, and the hex the pointer wraps to, in all of them.
  static func diagram(_ orientation: Orientation, pointer: Hex?) -> Diagram {
    let cells = map.shape.cells()
    var diagram = Diagram(orientation: orientation, cells: cells)
    for (index, center) in map.mirrorCenters.enumerated() {
      let light = index.isMultiple(of: 2)
      for hex in cells {
        diagram.cells.append(hex + center)
        diagram.fills[hex + center] = .hsl(light ? 200 : 40, 0.35, 0.88)
      }
      diagram.fills[center] = .hsl(light ? 200 : 40, 0.35, 0.72)
    }
    if let pointer {
      let original = map.wrap(pointer)
      for center in [Hex.zero] + map.mirrorCenters {
        diagram.fills[original + center] = Palette.pointed
      }
    }
    return diagram
  }
}
