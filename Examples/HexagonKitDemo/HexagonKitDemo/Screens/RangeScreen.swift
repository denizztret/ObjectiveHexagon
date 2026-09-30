import HexagonKit
import HexagonKitUI
import SwiftUI

/// Movement range (`#range-coordinate`, `#range-intersection`): the hexes
/// within a distance, and the hexes two ranges share.
struct RangeScreen: View {
  enum Part: String, CaseIterable {
    case range
    case intersection
  }

  /// The center of the fixed range of the intersection diagram.
  static let fixed = Hex(q: -4, r: 4)

  @State private var part: Part
  @State private var rangePointer: Hex
  @State private var intersectionPointer: Hex
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _part = State(initialValue: opening.part.flatMap(Part.init(rawValue:)) ?? .range)
    _rangePointer = State(initialValue: opening.hex ?? Hex(q: 3, r: 0))
    _intersectionPointer = State(initialValue: opening.hex ?? Hex(q: 1, r: 0))
  }

  var body: some View {
    ScreenFrame(caption: caption) {
      switch part {
      case .range:
        Board(diagram: Self.range(settings.orientation, pointer: rangePointer)) {
          rangePointer = $0
        }
      case .intersection:
        Board(diagram: Self.intersection(settings.orientation, pointer: intersectionPointer)) {
          intersectionPointer = $0
        }
      }
    } controls: {
      PartPicker(selection: $part)
      OrientationPicker()
    }
  }

  private var caption: String {
    switch part {
    case .range:
      let radius = rangePointer.length
      return "`range(radius: \(radius))` is every hex with -\(radius) ≤ q, r, s ≤ +\(radius): "
        + "\(Hex.zero.range(radius: radius).count) hexes between the six lines."
    case .intersection:
      let shared = Hex.intersection(ofRanges: [(intersectionPointer, 3), (Self.fixed, 3)])
      return "`intersection(ofRanges:)` of two ranges of radius 3 intersects the bounds of q, r "
        + "and s: \(shared.count) hexes, in green."
    }
  }

  /// A hexagon of radius 5 with the range out to the hex under the pointer
  /// and the six lines that bound it.
  static func range(_ orientation: Orientation, pointer: Hex) -> Diagram {
    let radius = pointer.length
    let inside = Set(Hex.zero.range(radius: radius))
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 5), padding: 1.3)
    for hex in diagram.cells {
      diagram.labels[hex] = .cube(hex, scale: 0.26)
      if !inside.contains(hex) {
        diagram.fills[hex] = Palette.shadow
      }
    }
    diagram.fills[pointer] = Palette.pointed
    guard radius > 0 else { return diagram }
    // Each line runs through the centers of the hexes of the map on the edge
    // of the range. Its label sits one step beyond one end: the last hex for
    // q and the first for r and s, so that no two labels meet.
    for axis in HexAxis.allCases {
      for bound in [-radius, radius] {
        let edge = diagram.cells.filter { $0[axis] == bound }
        guard let first = edge.first, let last = edge.last, edge.count > 1 else { continue }
        let name = "\(axis) \(bound < 0 ? "≥" : "≤") \(bound < 0 ? "-" : "+")\(radius)"
        let beyond =
          axis == .q ? Double(edge.count) / Double(edge.count - 1) : -1 / Double(edge.count - 1)
        diagram.marks.append(
          .line([.center(first), .center(last)], Palette.axis(axis).opacity(0.6), width: 0.05))
        diagram.marks.append(
          .text(
            Label(name, color: Palette.axis(axis), bold: true, scale: 0.3),
            .between(first, last, beyond)))
      }
    }
    return diagram
  }

  /// A hexagon of radius 7 with a range around the hex under the pointer, a
  /// fixed one, and the hexes they share.
  static func intersection(_ orientation: Orientation, pointer: Hex) -> Diagram {
    var diagram = Diagram(orientation: orientation, cells: Hex.zero.range(radius: 7))
    for hex in pointer.range(radius: 3) {
      diagram.fills[hex] = Palette.chosen
    }
    for hex in fixed.range(radius: 3) {
      diagram.fills[hex] = .hsl(270, 0.4, 0.86)
    }
    for hex in Hex.intersection(ofRanges: [(pointer, 3), (fixed, 3)]) {
      diagram.fills[hex] = .hsl(120, 0.4, 0.8)
    }
    diagram.fills[pointer] = .hsl(200, 0.5, 0.6)
    diagram.fills[fixed] = .hsl(270, 0.35, 0.65)
    return diagram
  }
}
