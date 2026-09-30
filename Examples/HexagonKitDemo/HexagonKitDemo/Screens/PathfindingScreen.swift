import HexagonKit
import HexagonKitUI
import SwiftUI

/// Pathfinding (`#pathfinding`): a cheapest path from the start around the
/// walls to the hex under the pointer.
struct PathfindingScreen: View {
  @State private var walls = GuideWalls.movement
  @State private var pointer: Hex
  @State private var paints: Bool
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _pointer = State(initialValue: opening.hex ?? Hex(q: 4, r: 0))
    _paints = State(initialValue: opening.paintsWalls)
  }

  var body: some View {
    let path = Self.path(walls: walls, to: pointer)
    ScreenFrame(
      caption: path.map {
        "`path(to:)` runs A* and finds \($0.count - 1) moves. The diagram of the guide runs a "
          + "breadth-first search: its path may differ, its length may not (deviation 14)."
      } ?? "No path reaches the hex under the pointer."
    ) {
      Board(
        diagram: Self.diagram(settings.orientation, walls: walls, path: path, goal: pointer),
        point: { pointer = $0 }, walls: paints ? $walls : nil, alwaysOpen: [.zero])
    } controls: {
      WallsToggle(paints: $paints)
      OrientationPicker()
    }
  }

  /// A cheapest path from the center; every move costs 1, and everything beyond
  /// radius 5 is a wall too. The board never lets the start become a wall.
  static func path(walls: Set<Hex>, to goal: Hex) -> [Hex]? {
    Hex.zero.path(to: goal) { _, next in
      walls.contains(next) || next.length > 5 ? nil : 1
    }
  }

  /// A hexagon of radius 5 with the walls and the path.
  static func diagram(_ orientation: Orientation, walls: Set<Hex>, path: [Hex]?, goal: Hex)
    -> Diagram
  {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 5))
    for hex in walls {
      diagram.fills[hex] = Palette.wall
    }
    for hex in path ?? [] {
      diagram.fills[hex] = .hsl(210, 0.25, 0.78)
    }
    diagram.fills[goal] = Palette.pointed
    diagram.fills[.zero] = Palette.start
    return diagram
  }
}
