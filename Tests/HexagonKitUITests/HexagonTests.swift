#if canImport(SwiftUI) && _pointerBitWidth(_64)
  import HexagonKit
  import HexagonKitUI
  import SwiftUI
  import Testing

  @Suite("Hexagon")
  struct HexagonTests {

    /// Up to eight units in the last place of the larger of the coordinate of
    /// the corner and the cell everywhere, and, for the corners within 100
    /// cells of zero, up to 1e-12 of the cell: the shape of a stretched cell is
    /// the cell of the layout.
    @Test("A hexagon in the frame of a cell has the corners of that cell")
    func hexagonInTheFrameOfACellMatchesTheCell() {
      var mismatches: [String] = []
      for layout in ModelGrid.layouts {
        let cell = max(layout.cellWidth, layout.cellHeight)
        for hex in ModelGrid.hexes {
          let shape = points(
            of: Hexagon(orientation: layout.orientation).path(in: layout.frame(of: hex)))
          let corners = layout.corners(of: hex)
          guard shape.count == 6 else {
            mismatches.append("no hexagon \(layout) \(hex)")
            continue
          }
          var largest = 0.0
          var largestCoordinate = 0.0
          for (point, corner) in zip(shape, corners) {
            let error = max(
              ulps(point.x, corner.x, of: max(abs(corner.x), cell)),
              ulps(point.y, corner.y, of: max(abs(corner.y), cell)))
            largest = max(largest, error)
            largestCoordinate = max(largestCoordinate, abs(corner.x), abs(corner.y))
          }
          let relative =
            zip(shape, corners).map { max(abs($0.x - $1.x), abs($0.y - $1.y)) }.max()! / cell
          if largest > 8 || (largestCoordinate <= 100 * cell && relative > 1e-12) {
            mismatches.append("\(largest) ulp, \(relative) of the cell: \(layout) \(hex)")
          }
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    /// The example of the review, where the error relative to the cell is the
    /// largest the model found near zero: it stays within both tolerances. Only
    /// the bounds are promised; a more exact computation passes too.
    @Test("The hexagon of the review example is within the tolerance")
    func hexagonOfTheReviewExample() {
      let layout = HexLayout(
        orientation: .flat, size: Point(x: 0.1, y: 3.7), origin: Point(x: 0.1, y: -0.3))
      let hex = Hex(q: -1, r: -19)
      let shape = points(of: Hexagon(orientation: .flat).path(in: layout.frame(of: hex)))
      let corners = layout.corners(of: hex)
      let cell = max(layout.cellWidth, layout.cellHeight)
      #expect(shape.count == 6)
      for (point, corner) in zip(shape, corners) {
        #expect(ulps(point.x, corner.x, of: max(abs(corner.x), cell)) <= 8)
        #expect(ulps(point.y, corner.y, of: max(abs(corner.y), cell)) <= 8)
      }
      let error = zip(shape, corners).map { max(abs($0.x - $1.x), abs($0.y - $1.y)) }.max()!
      #expect(error / cell <= 1e-12)
    }

    /// The distance from the center of a regular hexagon to each of its six
    /// edges is the apothem less the inset, negative insets included.
    @Test("An inset moves every edge of a regular hexagon by the same distance")
    func insetMovesEveryEdgeOfARegularHexagon() {
      for orientation in Orientation.allCases {
        for side in [10.0, 0.37, 250] {
          let layout = HexLayout(orientation: orientation, size: Point(x: side, y: side))
          let apothem = min(layout.cellWidth, layout.cellHeight) / 2
          for inset in [0.05 * side, 0.1 * side, 0.25 * side, -0.15 * side] {
            let corners = points(
              of: Hexagon(orientation: orientation, inset: inset).path(in: layout.frame(of: .zero)))
            for index in 0..<6 {
              let edge = distance(
                from: .zero, toLineThrough: corners[index], corners[(index + 1) % 6])
              #expect(abs(edge - (apothem - inset)) <= 1e-14 * apothem)
            }
          }
        }
      }
    }

    /// Pointy: the vertical edges from corner 2 to 3 and from 5 to 0; flat: the
    /// horizontal edges from corner 1 to 2 and from 4 to 5.
    @Test("An inset moves the two edges of a stretched hexagon along its sides")
    func insetMovesTheParallelEdgesOfAStretchedHexagon() {
      for orientation in Orientation.allCases {
        let edges = orientation == .pointy ? [(2, 3), (5, 0)] : [(1, 2), (4, 5)]
        for side in [10.0, 0.37, 250] {
          let layout = HexLayout(orientation: orientation, size: Point(x: side, y: side * 1.7))
          let frame = layout.frame(of: .zero)
          let half = Double(orientation == .pointy ? frame.width : frame.height) / 2
          for inset in [0.05 * side, 0.1 * side, 0.25 * side, -0.15 * side] {
            let corners = points(
              of: Hexagon(orientation: orientation, inset: inset).path(in: frame))
            for (first, second) in edges {
              let edge = distance(from: .zero, toLineThrough: corners[first], corners[second])
              #expect(abs(edge - (half - inset)) <= 1e-14 * half)
            }
          }
        }
      }
    }

    @Test("Insets add up, and the inset is what animates")
    func insetsAddUp() {
      let rect = CGRect(x: 3, y: -4, width: 40, height: 30)
      for orientation in Orientation.allCases {
        let twice = Hexagon(orientation: orientation, inset: 1.5).inset(by: 2.25)
        #expect(twice.inset == 3.75)
        #expect(
          elements(of: twice.path(in: rect))
            == elements(of: Hexagon(orientation: orientation, inset: 3.75).path(in: rect)))
        var animated = Hexagon(orientation: orientation)
        animated.animatableData = 2
        #expect(animated.inset == 2 && animated.animatableData == 2)
      }
    }

    /// A rectangle without area stays empty whatever the inset; so do an inset
    /// that leaves no area and rectangles whose size or middle overflows. The
    /// smallest positive width is a real rectangle: divided by the width of a
    /// unit pointy cell it stays positive, but halved for a flat one it rounds
    /// to zero.
    @Test(
      "Rectangles without area give an empty path, not a stop",
      arguments: [
        (Orientation.pointy, CGRect.zero, 0.0, true),
        (.pointy, CGRect(x: 0, y: 0, width: 10, height: 0), 0, true),
        (.flat, CGRect(x: 0, y: 0, width: 0, height: 10), 0, true),
        (.pointy, CGRect(x: CGFloat.infinity, y: 0, width: 10, height: 10), 0, true),
        (.flat, CGRect(x: 0, y: 0, width: CGFloat.nan, height: 10), 0, true),
        (.pointy, CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 10), 0, true),
        (.flat, CGRect(x: 1e308, y: 0, width: 1.7e308, height: 10), 0, true),
        (.pointy, CGRect(x: 0, y: 0, width: 5e-324, height: 10), 0, false),
        (.flat, CGRect(x: 0, y: 0, width: 5e-324, height: 10), 0, true),
        (.flat, CGRect.zero, -1, true),
        (.pointy, CGRect(x: 0, y: 0, width: 10, height: 0), -5, true),
        (.flat, CGRect(x: 0, y: 0, width: 40, height: 40), 30, true),
        (.pointy, CGRect.null, 0, true),
      ])
    func rectanglesWithoutAreaGiveAnEmptyPath(
      orientation: Orientation, rect: CGRect, inset: CGFloat, empty: Bool
    ) {
      #expect(Hexagon(orientation: orientation, inset: inset).path(in: rect).isEmpty == empty)
    }

    @Test("The hexagon touches the four sides of its rectangle")
    func hexagonTouchesItsRectangle() {
      let rects = [
        CGRect(x: 0, y: 0, width: 100, height: 100), CGRect(x: -7, y: 12.5, width: 30, height: 80),
        CGRect(x: 1e3, y: -2e3, width: 0.5, height: 0.25),
      ]
      for orientation in Orientation.allCases {
        for rect in rects {
          let drawn = Hexagon(orientation: orientation).path(in: rect).boundingRect
          for (actual, expected) in [
            (drawn.minX, rect.minX), (drawn.minY, rect.minY), (drawn.maxX, rect.maxX),
            (drawn.maxY, rect.maxY),
          ] {
            #expect(abs(actual - expected) <= 1e-12 * max(rect.width, rect.height))
          }
        }
      }
    }

    @Test("The outline starts at corner 0 and follows the corners of the core")
    func outlineStartsAtCornerZero() {
      for orientation in Orientation.allCases {
        let layout = HexLayout(orientation: orientation, size: Point(x: 10, y: 14))
        let outline = elements(
          of: Hexagon(orientation: orientation).path(in: layout.frame(of: .zero)))
        #expect(outline.count == 7 && outline.last == .close)
        let corners = layout.corners(of: .zero)
        for (point, corner) in zip(
          points(of: Hexagon(orientation: orientation).path(in: layout.frame(of: .zero))), corners)
        {
          #expect(abs(point.x - corner.x) <= 1e-12 && abs(point.y - corner.y) <= 1e-12)
        }
      }
    }

    @Test("The corners keep their order in a right-to-left layout")
    func cornersKeepTheirOrderRightToLeft() {
      if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
        #expect(Hexagon(orientation: .pointy).layoutDirectionBehavior == .fixed)
        #expect(Hexagon(orientation: .flat, inset: 2).layoutDirectionBehavior == .fixed)
      }
    }
  }

  /// The distance from a point to the line through two points.
  private func distance(from point: Point, toLineThrough a: Point, _ b: Point) -> Double {
    let (dx, dy) = (b.x - a.x, b.y - a.y)
    return abs(dy * (point.x - a.x) - dx * (point.y - a.y)) / (dx * dx + dy * dy).squareRoot()
  }
#endif
