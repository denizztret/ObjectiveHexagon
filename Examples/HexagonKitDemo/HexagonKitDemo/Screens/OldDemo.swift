import HexagonKit
import HexagonKitUI
import SwiftUI

/// The board of the old demo of ObjectiveHexagon, which both containers of
/// HexagonKitUI show: `HexCollectionViewLayout` on the collection view screen
/// and `HexGridLayout` on the views screen.
enum OldDemo {
  /// A rectangle of 11 by 9 hexes around zero in even-r coordinates.
  static let shape = HexShape.rectangle(
    origin: OffsetCoordinate(column: -5, row: -4), columns: 11, rows: 9, in: .evenR)

  /// The hexes of the rectangle in the order of a spiral around zero. The old
  /// demo lost the outer ring of its spiral here, and with it some items.
  static let cells: [Hex] = {
    let radius = shape.cells().map(\.length).max() ?? 0
    return Hex.zero.spiral(radius: radius).filter(shape.contains)
  }()

  /// The color of the old demo: each channel from one coordinate, clamped
  /// where the old demo overflowed to white.
  static func color(of hex: Hex) -> Color {
    let channel = { (value: Int) in min(1, Double(abs(200 - value * 100)) / 255) }
    return Color(red: channel(hex.q), green: channel(hex.r), blue: channel(hex.s))
  }
}

/// A cell of the old demo: a `Hexagon` in the color of its hex, with the
/// number of the item and the coordinates of the hex.
struct OldDemoCell: View {
  let hex: Hex
  let number: Int
  let orientation: Orientation

  var body: some View {
    Hexagon(orientation: orientation)
      .fill(OldDemo.color(of: hex))
      .overlay(Hexagon(orientation: orientation).strokeBorder(.white, lineWidth: 3))
      .overlay {
        VStack(spacing: 2) {
          Text("\(number)").font(.headline)
          Text("\(hex.q), \(hex.r), \(hex.s)").font(.caption2)
        }
        .foregroundStyle(.black.opacity(0.7))
      }
  }
}
