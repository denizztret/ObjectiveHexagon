import HexagonKit
import HexagonKitUI
import SwiftUI

/// Coordinate systems (`#coordinates-offset`, `#coordinates-cube`,
/// `#coordinates-axial`, `#coordinates-doubled`): one map, four ways to number
/// its hexes.
struct CoordinatesScreen: View {
  enum Part: String, CaseIterable {
    case offset
    case cube
    case axial
    case doubled
  }

  @State private var part: Part
  @State private var offsetSystem = OffsetSystem.oddR
  @State private var doubledSystem = DoubledSystem.doubleWidth
  @State private var offsetPointer: OffsetCoordinate
  @State private var cubePointer: Hex
  @State private var doubledPointer: DoubledCoordinate
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _part = State(initialValue: opening.part(or: .offset))
    let hex = opening.hex
    _offsetPointer = State(
      initialValue: hex.map { OffsetCoordinate($0, in: .oddR) }
        ?? OffsetCoordinate(column: 1, row: 1))
    _cubePointer = State(initialValue: hex ?? .zero)
    _doubledPointer = State(
      initialValue: hex.map { DoubledCoordinate($0, in: .doubleWidth) }
        ?? DoubledCoordinate(column: 2, row: 2)!)
  }

  var body: some View {
    ScreenFrame(caption: caption) {
      switch part {
      case .offset:
        Board(diagram: Self.offset(offsetSystem, pointer: offsetPointer)) { hex in
          offsetPointer = OffsetCoordinate(hex, in: offsetSystem)
        }
      case .cube, .axial:
        Board(diagram: Self.cube(settings.orientation, pointer: cubePointer, axial: part == .axial))
        {
          cubePointer = $0
        }
      case .doubled:
        Board(diagram: Self.doubled(doubledSystem, pointer: doubledPointer)) { hex in
          doubledPointer = DoubledCoordinate(hex, in: doubledSystem)
        }
      }
    } controls: {
      PartPicker(selection: $part)
      switch part {
      case .offset:
        SystemPicker(selection: $offsetSystem)
      case .cube, .axial:
        OrientationPicker()
      case .doubled:
        SystemPicker(selection: $doubledSystem)
      }
    }
  }

  private var caption: String {
    switch part {
    case .offset:
      "`OffsetCoordinate` numbers columns and rows; \(SystemPicker.name(offsetSystem)) shifts "
        + "every other one. The column of the hex under the pointer is green, its row blue."
    case .cube:
      "Cube coordinates q, r and s add up to zero. The hexes that share a coordinate with the "
        + "hex under the pointer are tinted in the color of its axis."
    case .axial:
      "Axial coordinates keep q and r; s = -q - r is derived. `Hex` stores these two."
    case .doubled:
      "`DoubledCoordinate` counts \(doubledSystem == .doubleWidth ? "columns" : "rows") twice "
        + "as densely; column plus row is always even."
    }
  }

  /// A rectangle in an offset system: columns and rows 0...6 of a pointy grid,
  /// or columns 0...7 and rows 0...5 of a flat one.
  static func offset(_ system: OffsetSystem, pointer: OffsetCoordinate) -> Diagram {
    let shape =
      system.orientation == .pointy
      ? HexShape.rectangle(columns: 7, rows: 7, in: system)
      : HexShape.rectangle(columns: 8, rows: 6, in: system)
    var diagram = Diagram(orientation: system.orientation, cells: shape.cells())
    for hex in diagram.cells {
      let coordinate = OffsetCoordinate(hex, in: system)
      diagram.labels[hex] = .pair(coordinate.column, coordinate.row)
      if coordinate == pointer {
        diagram.fills[hex] = Palette.pointed
      } else if coordinate.column == pointer.column {
        diagram.fills[hex] = Palette.tint(.q)
      } else if coordinate.row == pointer.row {
        diagram.fills[hex] = Palette.tint(.r)
      }
    }
    return diagram
  }

  /// A hexagon of radius 3 in cube or axial coordinates, the hexes that share
  /// a coordinate with the one under the pointer tinted.
  static func cube(_ orientation: Orientation, pointer: Hex, axial: Bool) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 3))
    for hex in diagram.cells {
      diagram.labels[hex] =
        if hex == .zero { .axes } else if axial { .axial(hex) } else { .cube(hex) }
      if hex == pointer {
        diagram.fills[hex] = Palette.pointed
      } else if hex.q == pointer.q {
        diagram.fills[hex] = Palette.tint(.q)
      } else if hex.r == pointer.r {
        diagram.fills[hex] = Palette.tint(.r)
      } else if hex.s == pointer.s && !axial {
        diagram.fills[hex] = Palette.tint(.s)
      }
    }
    return diagram
  }

  /// Columns 0...13 and rows 0...6 of double-width coordinates on a pointy
  /// grid, or columns 0...7 and rows 0...11 of double-height ones on a flat grid.
  static func doubled(_ system: DoubledSystem, pointer: DoubledCoordinate) -> Diagram {
    let (columns, rows) = system == .doubleWidth ? (14, 7) : (8, 12)
    var cells: [Hex] = []
    for row in 0..<rows {
      for column in 0..<columns {
        // Only the coordinates whose column plus row is even exist.
        if let coordinate = DoubledCoordinate(column: column, row: row) {
          cells.append(Hex(coordinate, in: system))
        }
      }
    }
    var diagram = Diagram(orientation: system.orientation, cells: cells)
    for hex in cells {
      let coordinate = DoubledCoordinate(hex, in: system)
      diagram.labels[hex] = .pair(coordinate.column, coordinate.row)
      if coordinate == pointer {
        diagram.fills[hex] = Palette.pointed
      }
    }
    return diagram
  }
}
