import HexagonKit
import HexagonKitUI
import SwiftUI

/// Views on a grid: the board of the collection view screen as SwiftUI views
/// in `HexGridLayout`, on every platform. Each view is a `Hexagon` that fills
/// the rectangle of its hex, `frame(of:)`.
struct ViewsScreen: View {
  @Environment(DemoSettings.self) private var settings

  var body: some View {
    let size = settings.cellSize
    let layout = HexLayout(orientation: settings.orientation, size: Point(x: size, y: size))
    ScreenFrame(
      caption: "\(OldDemo.cells.count) views for the \(OldDemo.shape.count) hexes of the "
        + "rectangle, numbered in the order of `spiral(radius:)`, each placed by `hexCell(_:)`. "
        + "`HexGridLayout` takes the size of their bounds; scroll to see them all."
    ) {
      ScrollView([.horizontal, .vertical]) {
        HexGridLayout(layout: layout) {
          ForEach(Array(OldDemo.cells.enumerated()), id: \.offset) { number, hex in
            OldDemoCell(hex: hex, number: number, orientation: layout.orientation)
              .hexCell(hex)
          }
        }
        .padding()
      }
      .defaultScrollAnchor(.center)
      .background(Palette.page)
    } controls: {
      OrientationPicker()
    }
  }
}
