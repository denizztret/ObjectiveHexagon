#if canImport(CoreGraphics) && _pointerBitWidth(_64)
  import CoreGraphics
  import HexagonKit
  import HexagonKitUI
  import Testing

  @Suite("HexLayout rectangles and points")
  struct HexLayoutRectTests {

    static let sqrt3 = 3.0.squareRoot()

    // MARK: frame(of:)

    /// The left and top edges and the size are exact; the right and bottom
    /// edges, which `CGRect` adds up, and the middle stay within three units in
    /// the last place of the larger of the center and the cell.
    @Test("The frame of a hex bounds its corners")
    func frameBoundsTheCorners() {
      var mismatches: [String] = []
      for layout in ModelGrid.layouts {
        for hex in ModelGrid.hexes {
          let frame = layout.frame(of: hex)
          let corners = layout.corners(of: hex)
          let center = layout.center(of: hex)
          let xs = corners.map { $0.x }
          let ys = corners.map { $0.y }
          if Double(frame.minX) != xs.min()! || Double(frame.minY) != ys.min()! {
            mismatches.append("left or top \(layout) \(hex)")
          }
          if Double(frame.width) != layout.cellWidth || Double(frame.height) != layout.cellHeight {
            mismatches.append("size \(layout) \(hex)")
          }
          let scaleX = max(abs(center.x), layout.cellWidth)
          let scaleY = max(abs(center.y), layout.cellHeight)
          let edges = [
            ulps(Double(frame.maxX), xs.max()!, of: scaleX),
            ulps(Double(frame.maxY), ys.max()!, of: scaleY),
            ulps(Double(frame.midX), center.x, of: scaleX),
            ulps(Double(frame.midY), center.y, of: scaleY),
          ]
          if edges.contains(where: { $0 > 3 }) {
            mismatches.append("edges \(edges) \(layout) \(hex)")
          }
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    /// With a subnormal size, halving the width of a cell is no longer exact,
    /// so the documentation promises the exact left edge only above about 1e-300.
    @Test("A subnormal size is the expected exception to the exact left edge")
    func subnormalSizeIsTheExpectedException() {
      let tiny = Double.leastNonzeroMagnitude
      let layout = HexLayout(orientation: .pointy, size: Point(x: 3 * tiny, y: 1))
      #expect(Double(layout.frame(of: .zero).minX) == -2 * tiny)
      #expect(layout.corners(of: .zero).map { $0.x }.min()! == -3 * tiny)
    }

    @Test("An infinite center gives infinities and NaN, not a stop")
    func infiniteCenterGivesInfinities() {
      let layout = HexLayout(orientation: .flat, size: Point(x: 1e307, y: 1))
      let far = Hex(q: 100, r: 0)
      #expect(layout.cellWidth.isFinite)
      #expect(layout.frame(of: far).minX == .infinity)
      #expect(layout.bounds(of: [far])!.width.isNaN)
    }

    // MARK: bounds(of:)

    @Test("No hexes have no bounds")
    func noHexesHaveNoBounds() {
      let layout = HexLayout(orientation: .pointy, size: Point(x: 10, y: 14))
      #expect(layout.bounds(of: [Hex]()) == nil)
      #expect(layout.bounds(of: Set<Hex>()) == nil)
      #expect(layout.bounds(of: HexShape.rectangle(columns: 0, rows: 3, in: .oddQ)) == nil)
      #expect(layout.bounds(of: HexShape.parallelogram(columns: 4, rows: 0)) == nil)
    }

    @Test("The bounds of a single hex are its frame")
    func boundsOfOneHexAreItsFrame() {
      var mismatches: [String] = []
      for layout in ModelGrid.layouts {
        for hex in ModelGrid.hexes where layout.bounds(of: [hex]) != layout.frame(of: hex) {
          mismatches.append("\(layout) \(hex)")
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    /// The left and top edges are the smallest ones of the frames; the right and
    /// bottom edges stay within six units in the last place of the largest of
    /// the extreme centers and the cell. Every layout of the grid has an origin
    /// and most have unequal sizes: the bounds and the frames share one
    /// coordinate space.
    @Test("The bounds of some hexes contain exactly their frames")
    func boundsContainTheFrames() {
      var mismatches: [String] = []
      for layout in ModelGrid.layouts {
        var sets = [ModelGrid.hexes]
        for anchor in ModelGrid.anchors {
          sets += ModelGrid.near.map { [anchor, $0] }
        }
        for hexes in sets {
          let bounds = layout.bounds(of: hexes)!
          let frames = hexes.map { layout.frame(of: $0) }
          let centers = hexes.map { layout.center(of: $0) }
          if bounds.minX != frames.map({ $0.minX }).min()!
            || bounds.minY != frames.map({ $0.minY }).min()!
          {
            mismatches.append("left or top \(layout) \(hexes.prefix(2))")
          }
          let scaleX = max(centers.map { abs($0.x) }.max()!, layout.cellWidth)
          let scaleY = max(centers.map { abs($0.y) }.max()!, layout.cellHeight)
          let right = ulps(
            Double(bounds.maxX), Double(frames.map { $0.maxX }.max()!), of: scaleX)
          let bottom = ulps(
            Double(bounds.maxY), Double(frames.map { $0.maxY }.max()!), of: scaleY)
          if right > 6 || bottom > 6 {
            mismatches.append("right \(right) bottom \(bottom) \(layout) \(hexes.prefix(2))")
          }
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    @Test("The order and the repeats of the hexes do not change the bounds")
    func orderAndRepeatsDoNotChangeTheBounds() {
      let hexes = HexShape.hexagon(center: Hex(q: 3, r: -7), radius: 4).cells()
      for layout in ModelGrid.layouts {
        let bounds = layout.bounds(of: hexes)
        #expect(layout.bounds(of: hexes.reversed()) == bounds)
        #expect(layout.bounds(of: hexes + hexes.reversed() + hexes) == bounds)
        #expect(layout.bounds(of: Set(hexes)) == bounds)
      }
    }

    @Test("The bounds of a shape are the bounds of its cells")
    func boundsOfAShapeAreTheBoundsOfItsCells() {
      let shapes: [HexShape] = [
        .hexagon(center: Hex(q: -4, r: 9), radius: 5),
        .triangleDown(origin: Hex(q: 2, r: 2), size: 6),
        .triangleUp(origin: Hex(q: -3, r: 0), size: 7),
        .parallelogram(origin: Hex(q: 5, r: -8), columns: 6, rows: 3),
      ]
      let rectangles = OffsetSystem.allCases.map {
        HexShape.rectangle(
          origin: OffsetCoordinate(column: -2, row: 3), columns: 5, rows: 4, in: $0)
      }
      for layout in ModelGrid.layouts {
        for shape in shapes + rectangles {
          #expect(layout.bounds(of: shape) == layout.bounds(of: shape.cells()))
        }
      }
    }

    /// The counterexample of the review of the documentation: the right edge is
    /// 36 units in the last place of its own value away from that of the frame,
    /// but only 1.125 of the largest center, well within six.
    @Test("The right edge of the review example is within the tolerance")
    func rightEdgeOfTheReviewExample() {
      let layout = HexLayout(orientation: .flat, size: Point(x: 0.001, y: 1))
      let hexes = [Hex(q: -19, r: 0), Hex(q: -1, r: 0)]
      let bounds = layout.bounds(of: hexes)!
      let right = hexes.map { layout.frame(of: $0).maxX }.max()!
      let scale = max(abs(layout.center(of: hexes[0]).x), layout.cellWidth)
      #expect(Double(bounds.maxX) == -0.000_500_000_000_000_003_9)
      #expect(Double(right) == -0.0005)
      let error = ulps(Double(bounds.maxX), Double(right), of: scale)
      #expect(error > 1 && error <= 6)
    }

    /// Outside representable geometry the rectangles follow IEEE 754: here the
    /// frames are finite, but the extent of the centers plus a cell is not.
    @Test("Bounds whose extent overflows are infinite, not a stop")
    func boundsWhoseExtentOverflows() {
      let layout = HexLayout(orientation: .flat, size: Point(x: 1.7e307, y: 1))
      let hexes = [Hex(q: -3, r: 0), Hex(q: 3, r: 0)]
      for hex in hexes {
        let frame = layout.frame(of: hex)
        #expect(frame.minX.isFinite && frame.width.isFinite)
      }
      #expect(layout.bounds(of: hexes)!.width == .infinity)
    }

    /// Outside representable geometry the promise on the right edge does not
    /// hold: the corners, the center and the cell are finite, and so are the
    /// stored left edge and width, but their sum is not.
    @Test("A finite frame can have an infinite right edge outside the region")
    func finiteFrameWithAnInfiniteRightEdge() {
      let layout = HexLayout(
        orientation: .flat, size: Point(x: 2.327_264_322_512_603e307, y: 1),
        origin: Point(x: 1.564_966_702_611_055_4e308, y: 0))
      let frame = layout.frame(of: .zero)
      #expect(layout.corners(of: .zero).map { $0.x }.max()! == .greatestFiniteMagnitude)
      #expect(Double(frame.minX) == 1.332_240_270_359_795_2e308)
      #expect(Double(frame.width) == 4.654_528_645_025_206e307)
      #expect(frame.maxX == .infinity)
    }

    // MARK: hex(at:)

    @Test("A point of a view gives the fractional hex of the core, bit for bit")
    func pointOfAViewGivesTheFractionalHexOfTheCore() {
      var mismatches: [String] = []
      for layout in ModelGrid.layouts {
        for hex in ModelGrid.near {
          for point in [layout.center(of: hex)] + layout.corners(of: hex) {
            let fromView = layout.hex(at: CGPoint(x: point.x, y: point.y))
            if fromView != layout.hex(at: point) {
              mismatches.append("\(layout) \(point)")
            }
          }
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    /// With an origin and unequal sizes: one coordinate space for the rectangles
    /// and for the points.
    @Test("A center and the points near it go back to their hex")
    func centerAndNearPointsGoBackToTheirHex() {
      let layouts = [
        HexLayout(orientation: .pointy, size: Point(x: 10, y: 14), origin: Point(x: 35, y: 71)),
        HexLayout(orientation: .flat, size: Point(x: 12.5, y: 9), origin: Point(x: -40, y: 90)),
      ]
      let steps = [(0.0, 0.0), (2, 0), (-2, 0), (0, 2), (0, -2), (1.4, 1.4), (-1.4, 1.4)]
      var mismatches: [String] = []
      for layout in layouts {
        for hex in HexShape.hexagon(center: Hex(q: 2, r: -5), radius: 6).cells() {
          let center = CGPoint(layout.center(of: hex))
          for (dx, dy) in steps {
            let point = CGPoint(x: center.x + dx, y: center.y + dy)
            if layout.hex(at: point).rounded() != hex {
              mismatches.append("\(layout.orientation) \(hex) \(dx) \(dy)")
            }
          }
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    @Test("The middle of an edge goes to one of the two hexes that share it")
    func middleOfAnEdgeGoesToOneOfItsHexes() {
      let layout = HexLayout(
        orientation: .flat, size: Point(x: 12.5, y: 9), origin: Point(x: -40, y: 90))
      var mismatches: [String] = []
      for hex in HexShape.hexagon(radius: 3).cells() {
        let corners = layout.corners(of: hex)
        for index in 0..<6 {
          let (a, b) = (corners[index], corners[(index + 1) % 6])
          let middle = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
          let found = layout.hex(at: middle).rounded()
          // The hex across the edge is the neighbor whose center is as far
          // from the middle of the edge as the center of this hex.
          let across = hex.neighbors.min { first, second in
            distance(layout.center(of: first), middle) < distance(layout.center(of: second), middle)
          }!
          if found != hex && found != across {
            mismatches.append("\(hex) edge \(index): \(found)")
          }
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    @Test("A point that is not a number gives NaN, not a stop")
    func pointThatIsNotANumberGivesNaN() {
      let layout = HexLayout(orientation: .pointy, size: Point(x: 10, y: 10))
      let fractional = layout.hex(at: CGPoint(x: CGFloat.nan, y: 3))
      #expect(fractional.q.isNaN && fractional.s.isNaN)
    }

    // MARK: Scenes: the layout examples of the guide's implementation page

    @Test("Layout examples: the frame is one cell at every size and orientation")
    func layoutExamplesFrameIsOneCell() {
      let examples = [
        HexLayout(orientation: .pointy, size: Point(x: 25, y: 25)),
        HexLayout(orientation: .flat, size: Point(x: 25, y: 25)),
        HexLayout(orientation: .pointy, size: Point(x: 10, y: 10)),
        HexLayout(orientation: .pointy, size: Point(x: 50, y: 50)),
      ]
      for layout in examples {
        for hex in HexShape.hexagon(radius: 2).cells() {
          let frame = layout.frame(of: hex)
          #expect(Double(frame.width) == layout.cellWidth)
          #expect(Double(frame.height) == layout.cellHeight)
        }
      }
    }

    /// Multiplying by two is exact, so the bounds of the same hexes at twice
    /// the size are twice the bounds, bit for bit.
    @Test("Layout examples: twice the size gives twice the bounds")
    func layoutExamplesTwiceTheSize() {
      let cells = HexShape.hexagon(radius: 2)
      for orientation in Orientation.allCases {
        let small = HexLayout(orientation: orientation, size: Point(x: 25, y: 25)).bounds(
          of: cells)!
        let large = HexLayout(orientation: orientation, size: Point(x: 50, y: 50)).bounds(
          of: cells)!
        #expect(large.minX == 2 * small.minX && large.minY == 2 * small.minY)
        #expect(large.width == 2 * small.width && large.height == 2 * small.height)
      }
    }

    /// A cell sized for a sprite of 100 by 100 points with its first cell at
    /// `(50, 50)` fills the rectangle of the sprite.
    @Test("Layout examples: a cell sized for a 100 by 100 sprite")
    func layoutExamplesSprite() {
      let sprites = [
        HexLayout(
          orientation: .flat, size: Point(x: 50, y: 100 / Self.sqrt3), origin: Point(x: 50, y: 50)),
        HexLayout(
          orientation: .pointy, size: Point(x: 100 / Self.sqrt3, y: 50), origin: Point(x: 50, y: 50)
        ),
      ]
      for layout in sprites {
        let frame = layout.frame(of: .zero)
        for (actual, expected) in [
          (frame.minX, 0.0), (frame.minY, 0), (frame.width, 100), (frame.height, 100),
        ] {
          #expect(abs(Double(actual) - expected) <= 1e-12)
        }
      }
    }

    @Test("Layout examples: an origin that puts the first cell in the top left corner")
    func layoutExamplesTopLeftOrigin() {
      let size = Point(x: 25, y: 18)
      let corners = [
        HexLayout(
          orientation: .flat, size: size, origin: Point(x: size.x, y: size.y * Self.sqrt3 / 2)),
        HexLayout(
          orientation: .pointy, size: size, origin: Point(x: size.x * Self.sqrt3 / 2, y: size.y)),
      ]
      for layout in corners {
        let frame = layout.frame(of: .zero)
        #expect(abs(Double(frame.minX)) <= 1e-12 && abs(Double(frame.minY)) <= 1e-12)
      }
    }

    // MARK: Scenes: the sandboxes of the old demo

    /// The sandbox `HexagonShape` of ObjectiveHexagon: the bounds of the ring of
    /// radius 1 of a pointy layout of size 25, around zero and around another hex.
    @Test("Old sandbox: the bounds of a ring")
    func oldSandboxBoundsOfARing() {
      let layout = HexLayout(orientation: .pointy, size: Point(x: 25, y: 25))
      let around = Hex(q: 1, r: -2)
      #expect(layout.center(of: around) == Point(x: 0, y: -75))
      let expected = [-37.5 * Self.sqrt3, -62.5, 75 * Self.sqrt3, 125]
      for (center, shift) in [(Hex.zero, 0.0), (around, -75)] {
        let bounds = layout.bounds(of: center.ring(radius: 1))!
        let actual = [bounds.minX, bounds.minY - shift, bounds.width, bounds.height]
        for (value, target) in zip(actual, expected) {
          #expect(abs(Double(value) - target) <= 1e-12 * abs(target))
        }
      }
    }

    /// The sandbox `HexagonGrid` of ObjectiveHexagon, checked against every
    /// corner of the shape instead of the frames.
    @Test("Old sandbox: the bounds of a rectangle against all its corners")
    func oldSandboxBoundsOfARectangle() {
      let layout = HexLayout(orientation: .flat, size: Point(x: 25, y: 25))
      let shape = HexShape.rectangle(
        origin: OffsetCoordinate(column: -2, row: 0), columns: 5, rows: 4, in: .evenQ)
      let bounds = layout.bounds(of: shape)!
      let corners = shape.cells().flatMap { layout.corners(of: $0) }
      let centers = shape.cells().map { layout.center(of: $0) }
      #expect(Double(bounds.minX) == corners.map { $0.x }.min()!)
      #expect(Double(bounds.minY) == corners.map { $0.y }.min()!)
      let scaleX = max(centers.map { abs($0.x) }.max()!, layout.cellWidth)
      let scaleY = max(centers.map { abs($0.y) }.max()!, layout.cellHeight)
      #expect(ulps(Double(bounds.maxX), corners.map { $0.x }.max()!, of: scaleX) <= 6)
      #expect(ulps(Double(bounds.maxY), corners.map { $0.y }.max()!, of: scaleY) <= 6)
    }

    /// The sandbox `TwoCentredGrid` of ObjectiveHexagon as a recipe: the bounds
    /// of a layout with a zero origin give the origin that centers a board on a
    /// point.
    @Test("Old sandbox: two boards centered on one point")
    func oldSandboxTwoCenteredBoards() {
      let target = Point(x: 160, y: 120)
      let boards = [
        HexShape.rectangle(columns: 7, rows: 5, in: .evenR), HexShape.hexagon(radius: 3),
      ]
      for shape in boards {
        let unit = HexLayout(orientation: .pointy, size: Point(x: 20, y: 20))
        let bounds = unit.bounds(of: shape)!
        let centered = HexLayout(
          orientation: .pointy, size: unit.size,
          origin: Point(x: target.x - Double(bounds.midX), y: target.y - Double(bounds.midY)))
        let moved = centered.bounds(of: shape)!
        #expect(abs(Double(moved.midX) - target.x) <= 1e-12 * target.x)
        #expect(abs(Double(moved.midY) - target.y) <= 1e-12 * target.y)
      }
    }
  }

  /// The distance between a point of the layout and a point of a view.
  private func distance(_ point: Point, _ other: CGPoint) -> Double {
    let (dx, dy) = (point.x - Double(other.x), point.y - Double(other.y))
    return (dx * dx + dy * dy).squareRoot()
  }
#endif
