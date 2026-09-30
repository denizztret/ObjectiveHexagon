import HexagonKit
import HexagonKitUI
import SwiftUI

/// The board every screen draws on: one canvas for the whole diagram. The
/// pointer goes back to a hex with `hex(at:)` and `rounded()`, and counts only
/// over the cells of the map, as in the guide.
struct Board: View {
  let diagram: Diagram

  /// Called with the hex of the map under the pointer or the finger.
  let point: (Hex) -> Void

  /// Called with the fractional hex under the pointer or the finger, on the
  /// map or off it.
  let track: (FractionalHex) -> Void

  /// When set, a drag paints walls instead of pointing: the first hex of the
  /// drag decides whether it adds walls or clears them.
  let walls: Binding<Set<Hex>>?

  /// Hexes that are never walls, such as the start of a search: a drag over
  /// them changes nothing, and a drag that starts on them lets the next hex
  /// decide what it does.
  let alwaysOpen: Set<Hex>

  @Environment(DemoSettings.self) private var settings
  @State private var addsWalls: Bool?

  init(
    diagram: Diagram, point: @escaping (Hex) -> Void = { _ in },
    track: @escaping (FractionalHex) -> Void = { _ in }, walls: Binding<Set<Hex>>? = nil,
    alwaysOpen: Set<Hex> = []
  ) {
    self.diagram = diagram
    self.point = point
    self.track = track
    self.walls = walls
    self.alwaysOpen = alwaysOpen
  }

  var body: some View {
    GeometryReader { proxy in
      let layout = Painter.layout(
        fitting: diagram, into: proxy.size, largest: settings.cellSize)
      Canvas { context, _ in
        if let layout {
          Painter.draw(diagram, with: layout, in: &context)
        }
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in handle(value.location, in: layout, dragging: true) }
          .onEnded { _ in addsWalls = nil }
      )
      .onContinuousHover { phase in
        if case .active(let location) = phase {
          handle(location, in: layout, dragging: false)
        }
      }
    }
    .background(Palette.page)
  }

  private func handle(_ location: CGPoint, in layout: HexLayout?, dragging: Bool) {
    guard let layout else { return }
    let fractional = layout.hex(at: location)
    track(fractional)
    guard let hex = diagram.hex(holding: fractional) else { return }
    if dragging, let walls {
      guard !alwaysOpen.contains(hex) else { return }
      let adds = addsWalls ?? !walls.wrappedValue.contains(hex)
      addsWalls = adds
      if adds {
        walls.wrappedValue.insert(hex)
      } else {
        walls.wrappedValue.remove(hex)
      }
    } else {
      point(hex)
    }
  }
}
