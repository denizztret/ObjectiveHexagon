import HexagonKit
import HexagonKitUI
import SwiftUI

/// Obstacles (`#range-obstacles`): the hexes a start reaches around the walls
/// within a number of moves, each with its fewest moves, and the way to the
/// hex under the pointer.
struct ObstaclesScreen: View {
  @State private var walls = GuideWalls.movement
  @State private var limit = 4
  @State private var pointer: Hex?
  @State private var paints: Bool
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _pointer = State(initialValue: opening.hex)
    _paints = State(initialValue: opening.paintsWalls)
  }

  var body: some View {
    let moves = Self.moves(walls: walls, limit: limit)
    ScreenFrame(
      caption: "`reachable(steps: \(limit))` reaches \(moves.count) hexes; the number in each "
        + "is the fewest moves to it. Everything beyond radius 5 is a wall too."
    ) {
      Board(
        diagram: Self.diagram(settings.orientation, walls: walls, moves: moves, pointer: pointer),
        point: { pointer = $0 }, walls: paints ? $walls : nil, alwaysOpen: [.zero])
    } controls: {
      Stepper("Limit movement ≤ \(limit)", value: $limit, in: 0...20)
      WallsToggle(paints: $paints)
      OrientationPicker()
    }
  }

  /// The fewest moves to every hex within the limit; the board never lets the
  /// start become a wall.
  static func moves(walls: Set<Hex>, limit: Int) -> [Hex: Int] {
    Hex.zero.reachable(steps: limit) { hex in !walls.contains(hex) && hex.length <= 5 }
  }

  /// A hexagon of radius 5 with the walls, the moves, and the way to the hex
  /// under the pointer in bold.
  static func diagram(
    _ orientation: Orientation, walls: Set<Hex>, moves: [Hex: Int], pointer: Hex?
  ) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 5))
    // Among the reached hexes, a cheapest way from the start: every move costs 1.
    let way = pointer.flatMap { goal in
      Hex.zero.path(to: goal) { _, next in moves[next] == nil ? nil : 1 }
    }
    let onTheWay = Set(way ?? [])
    for hex in diagram.cells {
      if walls.contains(hex) {
        diagram.fills[hex] = Palette.wall
      } else if let steps = moves[hex] {
        diagram.labels[hex] = Label(
          "\(steps)", color: onTheWay.contains(hex) ? Palette.text : Palette.pale,
          bold: onTheWay.contains(hex), scale: 0.4)
      } else {
        diagram.fills[hex] = Palette.shadow
      }
    }
    diagram.fills[.zero] = Palette.start
    return diagram
  }
}
