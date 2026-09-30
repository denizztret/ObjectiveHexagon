import HexagonKit
import HexagonKitUI
import SwiftUI

/// Fits a diagram into a view and draws it on a canvas. Every point comes from
/// the layout: `path(of:)`, `center(of:)`, `corner(of:at:)` and `frame(of:)`.
enum Painter {

  /// The layout that shows the cells of a diagram centered in a view, with
  /// cells as large as fit, up to `largest` points, or `nil` when nothing fits.
  ///
  /// The recipe of the documentation: the bounds of the cells in a layout of
  /// size 1 scale with the size of a layout, so they give both the size that
  /// fits and the origin that moves their middle to the middle of the view.
  static func layout(fitting diagram: Diagram, into view: CGSize, largest: Double) -> HexLayout? {
    let unit = HexLayout(orientation: diagram.orientation, size: Point(x: 1, y: 1))
    guard let cells = unit.bounds(of: diagram.cells) else { return nil }
    let bounds = cells.insetBy(dx: -diagram.padding, dy: -diagram.padding)
    let size = min(
      largest, Double(view.width) / Double(bounds.width),
      Double(view.height) / Double(bounds.height))
    guard size.isFinite, size > 0 else { return nil }
    let origin = Point(
      x: Double(view.width) / 2 - size * Double(bounds.midX),
      y: Double(view.height) / 2 - size * Double(bounds.midY))
    return HexLayout(
      orientation: diagram.orientation, size: Point(x: size, y: size), origin: origin)
  }

  /// Draws the cells, their outlines, the labels and the marks of a diagram.
  static func draw(_ diagram: Diagram, with layout: HexLayout, in context: inout GraphicsContext) {
    let unit = layout.size.x
    for hex in diagram.cells {
      context.fill(layout.path(of: hex), with: .color(diagram.fills[hex] ?? Palette.cell))
    }
    context.stroke(
      layout.path(of: diagram.cells), with: .color(Palette.edge), lineWidth: max(0.5, unit * 0.04))
    for hex in diagram.cells {
      if let label = diagram.labels[hex] {
        context.draw(text(label, unit: unit), at: CGPoint(layout.center(of: hex)))
      }
    }
    for mark in diagram.marks {
      draw(mark, with: layout, in: &context)
    }
  }

  /// Draws one mark; widths and radii are shares of the size of a cell.
  static func draw(_ mark: Mark, with layout: HexLayout, in context: inout GraphicsContext) {
    let unit = layout.size.x
    switch mark {
    case .arrow(let from, let to, let color):
      let (start, end) = (point(from, layout), point(to, layout))
      let (dx, dy) = (end.x - start.x, end.y - start.y)
      let length = (dx * dx + dy * dy).squareRoot()
      guard length > 0 else { return }
      // The head: two strokes back from the tip, each a quarter of a cell long.
      let (ux, uy) = (dx / length, dy / length)
      let (back, side) = (unit * 0.28, unit * 0.14)
      var arrow = Path()
      arrow.move(to: start)
      arrow.addLine(to: end)
      arrow.move(to: CGPoint(x: end.x - back * ux + side * uy, y: end.y - back * uy - side * ux))
      arrow.addLine(to: end)
      arrow.addLine(to: CGPoint(x: end.x - back * ux - side * uy, y: end.y - back * uy + side * ux))
      context.stroke(
        arrow, with: .color(color),
        style: StrokeStyle(lineWidth: max(1, unit * 0.07), lineCap: .round, lineJoin: .round))
    case .line(let spots, let color, let width, let dashed):
      guard let first = spots.first else { return }
      var line = Path()
      line.move(to: point(first, layout))
      for spot in spots.dropFirst() {
        line.addLine(to: point(spot, layout))
      }
      let dash: [CGFloat] = dashed ? [unit * 0.15, unit * 0.1] : []
      context.stroke(
        line, with: .color(color),
        style: StrokeStyle(lineWidth: max(0.5, unit * width), lineCap: .round, dash: dash))
    case .dot(let spot, let color, let radius):
      let center = point(spot, layout)
      let r = max(1.5, unit * radius)
      context.fill(
        Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)),
        with: .color(color))
    case .circle(let spot, let through, let color):
      let (center, edge) = (point(spot, layout), point(through, layout))
      let r =
        ((edge.x - center.x) * (edge.x - center.x) + (edge.y - center.y) * (edge.y - center.y))
        .squareRoot()
      context.stroke(
        Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)),
        with: .color(color), lineWidth: max(1, unit * 0.05))
    case .text(let label, let spot):
      context.draw(text(label, unit: unit), at: point(spot, layout))
    }
  }

  /// The point of a spot in a layout.
  static func point(_ spot: Spot, _ layout: HexLayout) -> CGPoint {
    switch spot {
    case .center(let hex):
      return CGPoint(layout.center(of: hex))
    case .corner(let hex, let index):
      return CGPoint(layout.corner(of: hex, at: index))
    case .axial(let q, let r):
      // The center of zero, plus q steps along the q axis and r along the r axis.
      let origin = layout.center(of: .zero)
      let stepQ = layout.center(of: Hex(q: 1, r: 0))
      let stepR = layout.center(of: Hex(q: 0, r: 1))
      return CGPoint(
        x: origin.x + q * (stepQ.x - origin.x) + r * (stepR.x - origin.x),
        y: origin.y + q * (stepQ.y - origin.y) + r * (stepR.y - origin.y))
    case .frame(let hex, let unit):
      let frame = layout.frame(of: hex)
      return CGPoint(x: frame.minX + unit.x * frame.width, y: frame.minY + unit.y * frame.height)
    case .align(let x, let y):
      return CGPoint(x: point(x, layout).x, y: point(y, layout).y)
    case .scaled(let spot, let origin, let factor):
      let (moved, fixed) = (point(spot, layout), point(origin, layout))
      return CGPoint(
        x: fixed.x + factor * (moved.x - fixed.x), y: fixed.y + factor * (moved.y - fixed.y))
    }
  }

  /// The text of a label with its font sized by the cell.
  static func text(_ label: Label, unit: Double) -> Text {
    var string = AttributedString()
    for run in label.runs {
      var piece = AttributedString(run.text)
      piece.foregroundColor = run.color
      piece.font = .system(size: max(7, unit * label.scale), weight: run.bold ? .bold : .regular)
      string += piece
    }
    return Text(string)
  }
}
