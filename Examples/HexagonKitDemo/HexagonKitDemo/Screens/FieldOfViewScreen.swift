import HexagonKit
import HexagonKitUI
import SwiftUI

/// Field of view (`#field-of-view`): the hexes an observer sees past the
/// walls, and the samples of the line to the hex under the pointer.
struct FieldOfViewScreen: View {
  @State private var walls = GuideWalls.fieldOfView
  @State private var pointer: Hex
  @State private var paints: Bool
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _pointer = State(initialValue: opening.hex ?? Hex(q: 3, r: -5))
    _paints = State(initialValue: opening.paintsWalls)
  }

  var body: some View {
    let visible = Self.visible(walls: walls)
    ScreenFrame(
      caption: "`fieldOfView(radius: 8)` sees \(visible.count) hexes, "
        + "\(visible.intersection(walls).count) of them walls: a wall is seen and hides what "
        + "is behind it. The diagram of the guide shows walls as never seen (deviation 13)."
    ) {
      Board(
        diagram: Self.diagram(
          settings.orientation, walls: walls, visible: visible, pointer: pointer),
        point: { pointer = $0 }, walls: paints ? $walls : nil, alwaysOpen: [.zero])
    } controls: {
      WallsToggle(paints: $paints)
      OrientationPicker()
    }
  }

  /// What the observer at the center sees; the board never lets the observer
  /// become a wall, so the count of walls in sight is that of the picture.
  static func visible(walls: Set<Hex>) -> Set<Hex> {
    Hex.zero.fieldOfView(radius: 8) { walls.contains($0) }
  }

  /// A hexagon of radius 8 with the walls, the hexes out of sight in shadow,
  /// and the samples of the line to the hex under the pointer: yellow while
  /// nothing blocks it, red at the first wall, gray beyond.
  static func diagram(
    _ orientation: Orientation, walls: Set<Hex>, visible: Set<Hex>, pointer: Hex
  ) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 8))
    for hex in diagram.cells {
      if walls.contains(hex) {
        diagram.fills[hex] = Palette.wall
      } else if !visible.contains(hex) {
        diagram.fills[hex] = Palette.shadow
      }
    }
    diagram.fills[.zero] = Palette.start
    let line = Hex.zero.line(to: pointer)
    let steps = max(line.count - 1, 1)
    var blocked = false
    for (index, hex) in line.enumerated() {
      let wall = index > 0 && walls.contains(hex)
      let color: Color = if blocked { Palette.pale } else if wall { .red } else { Palette.start }
      diagram.marks.append(
        .dot(.between(.zero, pointer, Double(index) / Double(steps)), color, radius: 0.18))
      blocked = blocked || wall
    }
    return diagram
  }
}
