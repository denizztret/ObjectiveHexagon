import HexagonKit
import HexagonKitUI
import SwiftUI

/// Neighbors (`#neighbors-cube`, `#neighbors-diagonal`, `#neighbors-offset`,
/// `#neighbors-doubled`): the six directions and the six diagonals, and the
/// steps to the neighbors in the offset and the doubled systems.
struct NeighborsScreen: View {
  enum Part: String, CaseIterable {
    case axial
    case diagonals
    case offset
    case doubled
  }

  @State private var part: Part
  @State private var pointer: Hex
  @State private var offsetSystem = OffsetSystem.oddR
  @State private var doubledSystem = DoubledSystem.doubleWidth
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _part = State(initialValue: opening.part.flatMap(Part.init(rawValue:)) ?? .axial)
    _pointer = State(initialValue: opening.hex ?? Hex(q: 1, r: 0))
  }

  var body: some View {
    ScreenFrame(caption: caption) {
      switch part {
      case .axial:
        Board(diagram: Self.directions(settings.orientation, pointer: pointer)) { pointer = $0 }
      case .diagonals:
        Board(diagram: Self.diagonals(settings.orientation, pointer: pointer)) { pointer = $0 }
      case .offset:
        Pair {
          Board(diagram: Self.offset(offsetSystem, odd: false))
        } second: {
          Board(diagram: Self.offset(offsetSystem, odd: true))
        }
      case .doubled:
        Board(diagram: Self.doubled(doubledSystem))
      }
    } controls: {
      PartPicker(selection: $part)
      switch part {
      case .axial, .diagonals:
        OrientationPicker()
      case .offset:
        Choice(title: "System", values: OffsetSystem.allCases, selection: $offsetSystem) {
          CoordinatesScreen.name($0.rawValue)
        }
      case .doubled:
        Choice(title: "System", values: DoubledSystem.allCases, selection: $doubledSystem) {
          CoordinatesScreen.name($0.rawValue)
        }
      }
    }
  }

  private var caption: String {
    switch part {
    case .axial:
      if let direction = HexDirection.allCases.first(where: { $0.vector == pointer }) {
        return "`neighbor(.\(direction))` adds the vector of direction \(direction.rawValue); "
          + "`neighbors` lists the six in the order of the directions 0...5."
      }
      return "`neighbors` lists the six neighbors in the order of the directions 0...5."
    case .diagonals:
      if let diagonal = HexDiagonal.allCases.first(where: { $0.vector == pointer }) {
        return "`diagonalNeighbor(.\(diagonal))` adds the vector of diagonal \(diagonal.rawValue): "
          + "two steps along one axis, one back along each of the others."
      }
      return "`diagonalNeighbors` lists the six diagonals in the order 0...5."
    case .offset:
      return "In \(CoordinatesScreen.name(offsetSystem.rawValue)) the steps to the neighbors "
        + "depend on whether the \(offsetSystem.orientation == .pointy ? "row" : "column") is "
        + "even or odd: `neighbor(_:in:)` knows both."
    case .doubled:
      return "In \(CoordinatesScreen.name(doubledSystem.rawValue)) the steps to the neighbors "
        + "are the same everywhere: `neighbor(_:in:)`."
    }
  }

  /// A hex and its six neighbors, each labeled with its vector, and the number
  /// of each direction outside the ring.
  static func directions(_ orientation: Orientation, pointer: Hex) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 1), padding: 0.8)
    diagram.labels[.zero] = .axes
    for direction in HexDirection.allCases {
      let hex = direction.vector
      diagram.labels[hex] = .vector(hex)
      diagram.marks.append(
        .text(
          Label("\(direction.rawValue)", color: Palette.pale, bold: true, scale: 0.3),
          .scaled(.center(hex), from: .center(.zero), by: 1.6)))
    }
    diagram.fills[pointer] = Palette.pointed
    return diagram
  }

  /// The ring around a hex, pale, and the six diagonal neighbors beyond it.
  static func diagonals(_ orientation: Orientation, pointer: Hex) -> Diagram {
    let ring = Hex.zero.ring(radius: 1)
    var diagram = Diagram(
      orientation: orientation, cells: [.zero] + ring + Hex.zero.diagonalNeighbors, padding: 0.9)
    diagram.labels[.zero] = .axes
    for hex in ring {
      diagram.fills[hex] = Palette.shadow
    }
    for diagonal in HexDiagonal.allCases {
      let hex = diagonal.vector
      diagram.labels[hex] = .vector(hex)
      diagram.marks.append(
        .text(
          Label("\(diagonal.rawValue)", color: Palette.pale, bold: true, scale: 0.3),
          .scaled(.center(hex), from: .center(.zero), by: 1.45)))
    }
    if pointer != .zero && !ring.contains(pointer) {
      diagram.fills[pointer] = Palette.pointed
    }
    return diagram
  }

  /// A hex on an even or an odd row (or column) and its neighbors, labeled
  /// with the steps of the offset coordinates.
  static func offset(_ system: OffsetSystem, odd: Bool) -> Diagram {
    let pointy = system.orientation == .pointy
    let center = OffsetCoordinate(column: pointy ? 1 : 2, row: pointy ? 2 : 1)
    let start =
      pointy
      ? OffsetCoordinate(column: center.column, row: center.row + (odd ? 1 : 0))
      : OffsetCoordinate(column: center.column + (odd ? 1 : 0), row: center.row)
    let middle = Hex(start, in: system)
    var diagram = Diagram(
      orientation: system.orientation, cells: [middle] + middle.neighbors, padding: 0.9)
    diagram.labels[middle] = Label("\(start.column), \(start.row)", bold: true)
    diagram.fills[middle] = Palette.pointed
    for neighbor in start.neighbors(in: system) {
      diagram.labels[Hex(neighbor, in: system)] = .signed(
        [
          (neighbor.column - start.column, Palette.axis(.q)),
          (neighbor.row - start.row, Palette.axis(.r)),
        ])
    }
    let title = (odd ? "ODD " : "EVEN ") + (pointy ? "row" : "column")
    diagram.marks.append(
      .text(
        Label(title, color: Palette.pale, bold: true, scale: 0.3),
        .frame(middle, UnitPoint(x: 0.5, y: pointy ? -0.95 : -1.25))))
    return diagram
  }

  /// A hex and its neighbors, labeled with the steps of the doubled coordinates.
  static func doubled(_ system: DoubledSystem) -> Diagram {
    let start = DoubledCoordinate(column: 4, row: 2)!
    let middle = Hex(start, in: system)
    var diagram = Diagram(orientation: system.orientation, cells: [middle] + middle.neighbors)
    diagram.labels[middle] = Label("\(start.column), \(start.row)", bold: true)
    diagram.fills[middle] = Palette.pointed
    for neighbor in start.neighbors(in: system) {
      diagram.labels[Hex(neighbor, in: system)] = .signed(
        [
          (neighbor.column - start.column, Palette.axis(.q)),
          (neighbor.row - start.row, Palette.axis(.r)),
        ])
    }
    return diagram
  }
}
