#if canImport(SwiftUI) && _pointerBitWidth(_64)
  import HexagonKit
  import HexagonKitUI
  import SwiftUI
  import Testing

  @Suite("HexLayout paths")
  struct HexLayoutPathTests {

    /// The regression of ObjectiveHexagon, whose pointy outline started one
    /// corner off: the path follows the corners of the core, bit for bit.
    @Test("The path of a hex moves to corner 0, adds lines through corner 5 and closes")
    func pathOfAHexFollowsTheCorners() {
      var mismatches: [String] = []
      for layout in ModelGrid.layouts {
        for hex in ModelGrid.hexes {
          let corners = layout.corners(of: hex)
          let lines = corners.dropFirst().map { PathElement.line($0) }
          let expected = [.move(corners[0])] + lines + [.close]
          if elements(of: layout.path(of: hex)) != expected {
            mismatches.append("\(layout) \(hex)")
          }
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    /// With the y axis pointing down, the shoelace sum of an outline that runs
    /// clockwise on screen is positive.
    @Test("The path starts at the corner of the guide's text and runs clockwise on screen")
    func pathStartsAtCornerZeroAndRunsClockwise() {
      for orientation in Orientation.allCases {
        let layout = HexLayout(orientation: orientation, size: Point(x: 10, y: 10))
        let corners = points(of: layout.path(of: .zero))
        // Pointy: corner 0 is at 30 degrees, below and to the right of the
        // center; flat: at 0 degrees, straight to the right.
        #expect(corners[0].x > 0)
        #expect(orientation == .pointy ? corners[0].y > 0 : corners[0].y == 0)
        var area = 0.0
        for index in 0..<6 {
          let (point, next) = (corners[index], corners[(index + 1) % 6])
          area += point.x * next.y - next.x * point.y
        }
        #expect(area > 0)
      }
    }

    /// Core Graphics computes the rectangle of a path itself, so the right and
    /// bottom edges agree with the frame up to its tolerance.
    @Test("The rectangle of the path of a hex is its frame")
    func rectangleOfThePathIsTheFrame() {
      var mismatches: [String] = []
      for layout in ModelGrid.layouts {
        for hex in ModelGrid.hexes {
          let rectangle = layout.path(of: hex).boundingRect
          let frame = layout.frame(of: hex)
          let center = layout.center(of: hex)
          let right = ulps(
            Double(rectangle.maxX), Double(frame.maxX),
            of: max(abs(center.x), layout.cellWidth))
          let bottom = ulps(
            Double(rectangle.maxY), Double(frame.maxY),
            of: max(abs(center.y), layout.cellHeight))
          if rectangle.minX != frame.minX || rectangle.minY != frame.minY || right > 3
            || bottom > 3
          {
            mismatches.append("\(layout) \(hex): \(right) \(bottom)")
          }
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    @Test("The path of some hexes is one closed subpath per hex, in order")
    func pathOfSomeHexesChainsTheirPaths() {
      let layout = HexLayout(
        orientation: .flat, size: Point(x: 12.5, y: 9), origin: Point(x: -40, y: 90))
      let hexes = Hex(q: 1, r: -2).spiral(radius: 2) + [Hex(q: 1, r: -2)]
      let chained = elements(of: layout.path(of: hexes))
      #expect(chained.count == 7 * hexes.count)
      #expect(chained == hexes.flatMap { elements(of: layout.path(of: $0)) })
    }

    @Test("The path of no hexes is empty")
    func pathOfNoHexesIsEmpty() {
      let layout = HexLayout(orientation: .pointy, size: Point(x: 10, y: 10))
      #expect(layout.path(of: [Hex]()).isEmpty)
      #expect(layout.path(of: Set<Hex>()).isEmpty)
    }

    @Test("The rectangle of the path of some hexes is their bounds")
    func rectangleOfThePathOfSomeHexesIsTheirBounds() {
      for layout in ModelGrid.layouts {
        let hexes = HexShape.hexagon(center: Hex(q: -5, r: 2), radius: 3).cells()
        let rectangle = layout.path(of: hexes).boundingRect
        let bounds = layout.bounds(of: hexes)!
        let centers = hexes.map { layout.center(of: $0) }
        let scaleX = max(centers.map { abs($0.x) }.max()!, layout.cellWidth)
        let scaleY = max(centers.map { abs($0.y) }.max()!, layout.cellHeight)
        #expect(rectangle.minX == bounds.minX && rectangle.minY == bounds.minY)
        #expect(ulps(Double(rectangle.maxX), Double(bounds.maxX), of: scaleX) <= 6)
        #expect(ulps(Double(rectangle.maxY), Double(bounds.maxY), of: scaleY) <= 6)
      }
    }

    /// All subpaths run the same way, so the default non-zero rule fills the
    /// hexes of a ring and leaves its middle empty; a hex that repeats winds
    /// twice, which the even-odd rule leaves empty.
    @Test("Filling the path fills exactly the hexes")
    func fillingThePathFillsTheHexes() {
      let layout = HexLayout(orientation: .pointy, size: Point(x: 10, y: 10))
      let ring = layout.path(of: Hex.zero.ring(radius: 2))
      for hex in Hex.zero.ring(radius: 2) {
        #expect(ring.contains(CGPoint(layout.center(of: hex))))
      }
      #expect(!ring.contains(CGPoint(layout.center(of: .zero))))
      #expect(!ring.contains(CGPoint(layout.center(of: Hex(q: 3, r: 0)))))
      let twice = layout.path(of: [Hex.zero, .zero])
      #expect(twice.contains(.zero))
      #expect(!twice.contains(.zero, eoFill: true))
    }

    /// Outside representable geometry nothing numeric is promised, and Core
    /// Graphics leaves out the points that are not finite; the outlines of the
    /// other hexes are still there.
    @Test("A path with a hex outside representable geometry comes back without a stop")
    func pathOutsideTheRegionHasNoStop() {
      let layout = HexLayout(orientation: .flat, size: Point(x: 1e307, y: 1))
      let path = layout.path(of: [Hex.zero, Hex(q: 100, r: 0)])
      #expect(Array(points(of: path).prefix(6)) == layout.corners(of: .zero))
    }
  }
#endif
