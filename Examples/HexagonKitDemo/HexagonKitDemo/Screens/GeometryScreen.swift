import HexagonKit
import HexagonKitUI
import SwiftUI

/// Geometry (`#basics`, `#spacing`, `#angles`): the size of a cell, the
/// spacing of the grid, and the angles of the corners.
struct GeometryScreen: View {
  enum Part: String, CaseIterable {
    case sizes
    case spacing
    case angles
  }

  @State private var part: Part
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _part = State(initialValue: opening.part(or: .sizes))
  }

  var body: some View {
    ScreenFrame(caption: caption) {
      switch part {
      case .sizes:
        Pair {
          Board(diagram: Self.sizes(.flat))
        } second: {
          Board(diagram: Self.sizes(.pointy))
        }
      case .spacing:
        Board(diagram: Self.spacing(settings.orientation))
      case .angles:
        Board(diagram: Self.angles(settings.orientation))
      }
    } controls: {
      PartPicker(selection: $part)
      if part != .sizes {
        OrientationPicker()
      }
    }
  }

  private var caption: String {
    switch part {
    case .sizes:
      "The size of a cell is the distance from its center to a corner: the radius of the outer "
        + "circle. The inner circle touches the edges. `frame(of:)` gives the width and the height."
    case .spacing:
      "Centers of neighbors are `horizontalSpacing` and `verticalSpacing` apart; the dashed "
        + "lines divide the width and the height of a cell into quarters."
    case .angles:
      settings.orientation == .pointy
        ? "Corner i of a pointy cell is at 60° × i + 30°, clockwise on screen. The pseudocode "
          + "of the guide starts pointy corners at -30° (deviation 1 of Conformance.md)."
        : "Corner i of a flat cell is at 60° × i, clockwise on screen."
    }
  }

  /// One cell with its outer and inner circles, its size and its rectangle.
  static func sizes(_ orientation: Orientation) -> Diagram {
    let cell = Hex.zero
    let pointy = orientation == .pointy
    var marks: [Mark] = [
      .circle(.center(cell), through: .corner(cell, 0), Palette.ink),
      .circle(.center(cell), through: .between(cell, Hex(q: 1, r: 0), 0.5), Palette.axis(.q)),
      .line([.center(cell), .corner(cell, 0)], Palette.text, width: 0.03, dashed: true),
      .text(
        Label("size", scale: 0.24),
        .align(
          x: .scaled(.corner(cell, 0), from: .center(cell), by: 0.55),
          y: .frame(cell, UnitPoint(x: 0, y: 0.4)))),
      .dot(.center(cell), Palette.text, radius: 0.06),
    ]
    // The width under the cell and the height to the right of it, as arrows
    // from the middle of each side of the rectangle of the cell.
    for end in [0.0, 1.0] {
      marks.append(
        .arrow(
          .frame(cell, UnitPoint(x: 0.5, y: 1.2)), .frame(cell, UnitPoint(x: end, y: 1.2)),
          Palette.axis(.r)))
      marks.append(
        .arrow(
          .frame(cell, UnitPoint(x: 1.15, y: 0.5)), .frame(cell, UnitPoint(x: 1.15, y: end)),
          Palette.axis(.s)))
    }
    marks.append(
      .text(
        Label(pointy ? "width = √3 × size" : "width = 2 × size", scale: 0.2),
        .frame(cell, UnitPoint(x: 0.5, y: 1.36))))
    marks.append(
      .text(
        Label(pointy ? "height =\n2 × size" : "height =\n√3 × size", scale: 0.2),
        .frame(cell, UnitPoint(x: 1.5, y: 0.5))))
    marks.append(
      .text(
        Label(orientation.rawValue, color: Palette.pale, scale: 0.24),
        .frame(cell, UnitPoint(x: 0.5, y: -0.25))))
    return Diagram(
      orientation: orientation, cells: [cell], marks: marks, padding: 1.1)
  }

  /// Four cells with their centers and corners, the spacing between the
  /// centers, and lines every quarter of the width and the height of a cell.
  static func spacing(_ orientation: Orientation) -> Diagram {
    let cells = [Hex.zero, Hex(q: 1, r: 0), Hex(q: 0, r: 1), Hex(q: 1, r: 1)]
    let unit = HexLayout(orientation: orientation, size: Point(x: 1, y: 1))
    let bounds = unit.bounds(of: cells)!
    let frame = unit.frame(of: .zero)
    // How many quarters of a cell the four cells span along each axis.
    let columns = Int((4 * bounds.width / frame.width).rounded())
    let rows = Int((4 * bounds.height / frame.height).rounded())
    let names = ["", "¼", "½", "¾", ""]
    var marks: [Mark] = []
    for k in 0...columns {
      let x = Double(k) / 4
      marks.append(
        .line(
          [
            .frame(.zero, UnitPoint(x: x, y: -0.1)),
            .frame(.zero, UnitPoint(x: x, y: Double(rows) / 4 + 0.1)),
          ], Palette.pale, width: 0.02, dashed: true))
      if (1...4).contains(k) {
        marks.append(
          .text(
            Label("\(names[k])w", color: Palette.pale, scale: 0.22),
            .frame(.zero, UnitPoint(x: x, y: -0.22))))
      }
    }
    for k in 0...rows {
      let y = Double(k) / 4
      marks.append(
        .line(
          [
            .frame(.zero, UnitPoint(x: -0.1, y: y)),
            .frame(.zero, UnitPoint(x: Double(columns) / 4 + 0.1, y: y)),
          ], Palette.pale, width: 0.02, dashed: true))
      if (1...4).contains(k) {
        marks.append(
          .text(
            Label("\(names[k])h", color: Palette.pale, scale: 0.22),
            .frame(.zero, UnitPoint(x: -0.22, y: y))))
      }
    }
    for hex in cells {
      for index in 0..<6 {
        marks.append(.dot(.corner(hex, index), Palette.pale, radius: 0.05))
      }
      marks.append(.dot(.center(hex), Palette.text, radius: 0.07))
    }
    // The horizontal spacing along a row or between columns, the vertical one
    // down to the next row or along a column.
    let across: Spot =
      orientation == .pointy
      ? .center(Hex(q: 1, r: 0)) : .align(x: .center(Hex(q: 1, r: 0)), y: .center(.zero))
    let down: Spot =
      orientation == .pointy
      ? .align(x: .center(.zero), y: .center(Hex(q: 0, r: 1))) : .center(Hex(q: 0, r: 1))
    marks.append(.arrow(.center(.zero), across, Palette.axis(.q)))
    marks.append(.arrow(.center(.zero), down, Palette.axis(.r)))
    marks.append(
      .text(
        Label("horizontal", color: Palette.axis(.q), scale: 0.2),
        .align(
          x: .scaled(across, from: .center(.zero), by: 0.5),
          y: .frame(.zero, UnitPoint(x: 0, y: 0.4))
        )))
    marks.append(
      .text(
        Label("vertical", color: Palette.axis(.r), scale: 0.2),
        .align(
          x: .frame(.zero, UnitPoint(x: 0.25, y: 0)),
          y: .scaled(down, from: .center(.zero), by: 0.5))))
    return Diagram(orientation: orientation, cells: cells, marks: marks, padding: 0.6)
  }

  /// One cell with its corners numbered as `corners(of:)` numbers them and the
  /// angles every 30 degrees around it.
  static func angles(_ orientation: Orientation) -> Diagram {
    let cell = Hex.zero
    let unit = HexLayout(orientation: orientation, size: Point(x: 1, y: 1))
    // The middle of an edge is as far from the center as half the smaller side.
    let apothem = min(unit.cellWidth, unit.cellHeight) / 2
    let first = orientation == .pointy ? 30 : 0
    var marks: [Mark] = []
    for index in 0..<6 {
      let corner = Spot.corner(cell, index)
      let middle = Spot.scaled(corner, from: .corner(cell, (index + 1) % 6), by: 0.5)
      marks.append(.line([.center(cell), corner], Palette.pale, width: 0.02, dashed: true))
      marks.append(.dot(corner, Palette.ink, radius: 0.07))
      marks.append(
        .text(
          Label("\(index)", color: Palette.ink, bold: true, scale: 0.3),
          .scaled(corner, from: .center(cell), by: 0.75)))
      marks.append(
        .text(
          Label("\(first + 60 * index)°", scale: 0.24),
          .scaled(corner, from: .center(cell), by: 1.3)))
      marks.append(
        .text(
          Label("\((first + 60 * index + 30) % 360)°", color: Palette.pale, scale: 0.24),
          .scaled(middle, from: .center(cell), by: 1.3 / apothem)))
    }
    marks.append(.dot(.center(cell), Palette.text, radius: 0.06))
    return Diagram(orientation: orientation, cells: [cell], marks: marks, padding: 0.6)
  }
}
