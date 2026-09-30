// snippet.hide
#if canImport(SwiftUI)
  import HexagonKit
  import HexagonKitUI
  import SwiftUI

  // snippet.show
  // snippet.bridge
  // A cell as a rectangle, a board as one rectangle, and a tap back to a cell.
  let layout = HexLayout(orientation: .pointy, size: Point(x: 20, y: 20))
  let cell = layout.frame(of: Hex(q: 1, r: -1))
  let board = layout.bounds(of: HexShape.hexagon(radius: 2))
  let tapped = layout.hex(at: CGPoint(x: 30, y: 12)).rounded()
  print(cell.height, board?.height ?? 0, tapped)  // 40.0 160.0 Hex(q: 1, r: 0)
  // snippet.end

  // snippet.canvas
  // A board drawn on a Canvas: a filled path and a label for each cell, and one
  // path for all the outlines.
  struct CanvasBoard: View {
    let layout: HexLayout
    let cells: [Hex]

    var body: some View {
      Canvas { context, _ in
        for hex in cells {
          context.fill(layout.path(of: hex), with: .color(.orange))
          context.draw(Text("\(hex.q), \(hex.r)"), at: CGPoint(layout.center(of: hex)))
        }
        context.stroke(layout.path(of: cells), with: .color(.gray))
      }
    }
  }
  // snippet.end

  // snippet.grid
  // A board of views, one on each cell, each drawn with a border inside it.
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  struct ViewBoard: View {
    let layout = HexLayout(orientation: .flat, size: Point(x: 30, y: 30))
    let cells = Hex.zero.spiral(radius: 2)

    var body: some View {
      HexGridLayout(layout: layout) {
        ForEach(cells, id: \.self) { hex in
          Hexagon(orientation: layout.orientation)
            .strokeBorder(.blue, lineWidth: 2)
            .overlay(Text("\(hex.spiralIndex())"))
            .hexCell(hex)
        }
      }
    }
  }
// snippet.end
// snippet.hide
#endif
