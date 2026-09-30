import HexagonKit
import HexagonKitUI
import SwiftUI

/// Rotation and reflection (`#rotation`, `#reflection`): the hex under the
/// pointer turned around the center by steps of 60 degrees, or mirrored
/// across an axis.
struct RotationScreen: View {
  enum Part: String, CaseIterable {
    case rotation
    case reflection
  }

  @State private var part: Part
  @State private var pointer: Hex
  @State private var axis = HexAxis.r
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _part = State(initialValue: opening.part(or: .rotation))
    _pointer = State(initialValue: opening.hex ?? Hex(q: 2, r: -3))
  }

  var body: some View {
    ScreenFrame(caption: caption) {
      switch part {
      case .rotation:
        Board(diagram: Self.rotation(settings.orientation, pointer: pointer)) { pointer = $0 }
      case .reflection:
        Board(diagram: Self.reflection(settings.orientation, pointer: pointer, axis: axis)) {
          pointer = $0
        }
      }
    } controls: {
      PartPicker(selection: $part)
      if part == .reflection {
        Choice(title: "Axis", values: HexAxis.allCases, selection: $axis) { $0.rawValue }
      }
      OrientationPicker()
    }
  }

  private var caption: String {
    switch part {
    case .rotation:
      "`rotated(by: 1)` turns the hex 60° clockwise on screen (purple), `rotated(by: -1)` "
        + "counterclockwise (green); lighter tints are 120°, the gray-blue hex is 180°."
    case .reflection:
      "`reflected(across: .\(axis))` keeps \(axis) and swaps \(Self.others(of: axis)): the "
        + "hexes on the thick line, where those two are equal, stay in place. The white hexes, "
        + "where \(axis) is zero, lie on the dashed line; the gray arrows show negation."
    }
  }

  /// A hexagon of radius 5 with the hex under the pointer and its turns around
  /// the center.
  static func rotation(_ orientation: Orientation, pointer: Hex) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 5))
    for hex in diagram.cells {
      diagram.labels[hex] = .cube(hex, scale: 0.26)
    }
    let turns: [(Int, Color)] = [
      (-2, .hsl(100, 0.4, 0.88)), (-1, .hsl(100, 0.45, 0.75)), (1, .hsl(300, 0.4, 0.8)),
      (2, .hsl(300, 0.35, 0.9)), (3, .hsl(210, 0.2, 0.8)),
    ]
    for (steps, color) in turns {
      diagram.fills[pointer.rotated(by: steps)] = color
    }
    diagram.fills[pointer] = Palette.pointed
    diagram.marks = [
      .arrow(.center(.zero), .center(pointer), Palette.ink),
      .arrow(.center(pointer), .center(pointer.rotated(by: -1)), Palette.axis(.q)),
      .arrow(.center(pointer), .center(pointer.rotated(by: 1)), Palette.axis(.s)),
    ]
    return diagram
  }

  /// A hexagon of radius 5 with an axis, the hex under the pointer, its mirror
  /// image, and both negated.
  static func reflection(_ orientation: Orientation, pointer: Hex, axis: HexAxis) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 5))
    for hex in diagram.cells {
      diagram.labels[hex] = .cube(hex, scale: 0.26)
      if hex[axis] == 0 {
        diagram.fills[hex] = Palette.page
      }
    }
    // The axis runs through the hexes the reflection keeps in place: along the
    // two diagonals that carry its name, as in the tests of the core. The line
    // where the coordinate of the axis is zero is the second line of the guide.
    let (behind, ahead): (HexDiagonal, HexDiagonal) =
      switch axis {
      case .q: (.minusQ, .plusQ)
      case .r: (.minusR, .plusR)
      case .s: (.minusS, .plusS)
      }
    let (from, to) = (behind.vector * 2, ahead.vector * 2)
    let (start, end): (Hex, Hex) =
      switch axis {
      case .q: (Hex(q: 0, r: -5), Hex(q: 0, r: 5))
      case .r: (Hex(q: -5, r: 0), Hex(q: 5, r: 0))
      case .s: (Hex(q: -5, r: 5), Hex(q: 5, r: -5))
      }
    let mirrored = pointer.reflected(across: axis)
    diagram.fills[mirrored] = Palette.tint(axis)
    diagram.fills[pointer] = Palette.pointed
    diagram.marks = [
      .line(
        [.between(start, end, -0.05), .between(start, end, 1.05)], Palette.pale, width: 0.04,
        dashed: true),
      .line(
        [.between(from, to, -0.15), .between(from, to, 1.15)], Palette.axis(axis), width: 0.12),
      .arrow(.center(pointer), .center(mirrored), Palette.axis(axis)),
      .arrow(.center(mirrored), .center(mirrored * -1), Palette.pale),
      .arrow(.center(pointer), .center(pointer * -1), Palette.pale),
    ]
    return diagram
  }

  /// The two coordinates a reflection across an axis swaps.
  static func others(of axis: HexAxis) -> String {
    switch axis {
    case .q: "r and s"
    case .r: "q and s"
    case .s: "q and r"
    }
  }
}
