#if canImport(CoreGraphics) && _pointerBitWidth(_64)
  import CoreGraphics
  import HexagonKit
  import HexagonKitUI
  import Testing

  @Suite("Point bridges")
  struct PointBridgeTests {

    static let points = [
      Point(x: 0, y: -0.0), Point(x: 1.5, y: -2.25), Point(x: 0.1, y: 1e300),
      Point(x: .greatestFiniteMagnitude, y: -.leastNonzeroMagnitude),
    ]

    @Test("A point becomes a CGPoint with the same coordinates and comes back")
    func pointGoesToACGPointAndBack() {
      for point in Self.points {
        let bridged = CGPoint(point)
        // `#expect(cgFloat == double)` fails on equal values: convert first.
        #expect(Double(bridged.x) == point.x)
        #expect(Double(bridged.y) == point.y)
        #expect(Point(bridged) == point)
      }
    }

    @Test("A CGSize becomes a point: the width is x and the height is y")
    func sizeBecomesAPoint() {
      #expect(Point(CGSize(width: 10, height: 14)) == Point(x: 10, y: 14))
      #expect(Point(CGSize(width: 0.1, height: 1e-300)) == Point(x: 0.1, y: 1e-300))
      let layout = HexLayout(orientation: .flat, size: Point(CGSize(width: 12, height: 9)))
      #expect(layout == HexLayout(orientation: .flat, size: Point(x: 12, y: 9)))
    }

    @Test("Values that are not finite pass through without a stop")
    func valuesThatAreNotFinitePassThrough() {
      let bridged = CGPoint(Point(x: .nan, y: -.infinity))
      #expect(bridged.x.isNaN)
      #expect(bridged.y == -.infinity)
      let back = Point(CGPoint(x: CGFloat.infinity, y: CGFloat.nan))
      #expect(back.x == .infinity)
      #expect(back.y.isNaN)
    }
  }
#endif
