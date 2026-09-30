#if canImport(CoreGraphics) && _pointerBitWidth(_64)
  import CoreGraphics
  import HexagonKit
  @testable import HexagonKitUI
  import Testing

  /// The one placement both containers share, tested with numbers where it can
  /// be tested without SwiftUI or UIKit.
  @Suite("Placement of the containers")
  struct PlacementTests {

    @Test("Every hex gets a frame, and a missing hex gets none")
    func everyHexGetsAFrame() {
      let layout = HexLayout(
        orientation: .flat, size: Point(x: 10, y: 10), origin: Point(x: -40, y: 90))
      let placement = layout.placement(of: [Hex(q: -2, r: 0), nil, Hex(q: 1, r: 1), nil])
      #expect(placement.frames.count == 4)
      #expect(placement.frames.map { $0 == nil } == [false, true, false, true])
    }

    @Test("Without a hex the size is zero and there are no frames")
    func withoutAHexTheSizeIsZero() {
      let layout = HexLayout(orientation: .pointy, size: Point(x: 10, y: 10))
      #expect(layout.placement(of: []).size == .zero)
      let placement = layout.placement(of: [nil, nil])
      #expect(placement.size == .zero)
      #expect(placement.frames.allSatisfy { $0 == nil })
    }

    /// The frames are those of a layout with a zero origin, moved by the
    /// smallest center with one subtraction: the placement starts at zero
    /// exactly and no frame reaches past the size.
    @Test("The placement starts at zero and fits its size")
    func placementStartsAtZeroAndFitsItsSize() {
      var mismatches: [String] = []
      for layout in ModelGrid.layouts {
        let placement = layout.placement(of: ModelGrid.hexes)
        let base = HexLayout(orientation: layout.orientation, size: layout.size)
        let centers = ModelGrid.hexes.map { base.center(of: $0) }
        let lowest = Point(x: centers.map { $0.x }.min()!, y: centers.map { $0.y }.min()!)
        let frames = placement.frames.compactMap { $0 }
        for (frame, center) in zip(frames, centers) {
          let expected = CGRect(
            x: center.x - lowest.x, y: center.y - lowest.y,
            width: base.cellWidth, height: base.cellHeight)
          if frame != expected {
            mismatches.append("frame \(layout) \(center)")
          }
          if frame.maxX > placement.size.width || frame.maxY > placement.size.height {
            mismatches.append("past the size \(layout) \(center)")
          }
        }
        if frames.map({ $0.minX }).min() != 0 || frames.map({ $0.minY }).min() != 0 {
          mismatches.append("start \(layout)")
        }
        if placement.size != base.bounds(of: ModelGrid.hexes)!.size {
          mismatches.append("size \(layout)")
        }
      }
      #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    }

    @Test("The origin of the layout does not move the placement")
    func originDoesNotMoveThePlacement() {
      for layout in ModelGrid.layouts {
        let base = HexLayout(orientation: layout.orientation, size: layout.size)
        let placement = layout.placement(of: ModelGrid.hexes)
        let zero = base.placement(of: ModelGrid.hexes)
        #expect(placement.size == zero.size && placement.frames == zero.frames)
      }
    }

    /// The counterexample of the review: with the centers of the layout itself,
    /// `1e20 + 0` and `1e20 + 1.5` round to the same number, and the two hexes
    /// would collapse.
    @Test("A large origin does not collapse the placement")
    func largeOriginDoesNotCollapseThePlacement() {
      let layout = HexLayout(
        orientation: .flat, size: Point(x: 1, y: 1), origin: Point(x: 1e20, y: 0))
      let placement = layout.placement(of: [.zero, Hex(q: 1, r: 0)])
      #expect(placement.frames.map { $0?.minX } == [0, 1.5])
      #expect(Double(placement.size.width) == 3.5)
    }

    @Test("Hexes that repeat share a frame")
    func hexesThatRepeatShareAFrame() {
      let layout = HexLayout(orientation: .pointy, size: Point(x: 10, y: 14))
      let placement = layout.placement(of: [Hex(q: 1, r: 1), .zero, Hex(q: 1, r: 1)])
      #expect(placement.frames[0] == placement.frames[2])
      #expect(placement.frames[0] != placement.frames[1])
    }

    // MARK: The arithmetic of 32-bit watchOS devices

    /// Returns the placement of some hexes as numbers of the core, the way
    /// `placement(of:)` hands them to the check.
    static func unconverted(
      _ layout: HexLayout, _ hexes: [Hex]
    ) -> (size: Point, origins: [Point], cell: Point) {
      let placement = layout.placement(of: hexes)
      return (
        Point(placement.size), placement.frames.map { Point($0!.origin) },
        Point(x: layout.cellWidth, y: layout.cellHeight)
      )
    }

    /// The counterexample of the third review: in `Float` the width of the
    /// container rounds down to the largest finite value, and the origin and
    /// the width of the second frame are finite, but their sum is not. Only a
    /// check of the edges after the conversion catches it.
    @Test("An edge that overflows Float stops the placement on a watch")
    func edgeThatOverflowsFloat() {
      let layout = HexLayout(orientation: .flat, size: Point(x: 4.253_529_459_746_670_3e37, y: 1))
      let (size, origins, cell) = Self.unconverted(layout, [.zero, Hex(q: 4, r: 0)])
      #expect(Float(size.x) == .greatestFiniteMagnitude)
      #expect(Float(origins[1].x).isFinite && Float(cell.x).isFinite)
      #expect(
        !HexLayout.placementIsFinite(size: size, origins: origins, cell: cell, in: Float.self))
      #expect(
        HexLayout.placementIsFinite(size: size, origins: origins, cell: cell, in: Double.self))
    }

    @Test("A placement finite in Double can overflow Float")
    func placementFiniteInDoubleCanOverflowFloat() {
      let layout = HexLayout(orientation: .pointy, size: Point(x: 1e38, y: 1e38))
      let (size, origins, cell) = Self.unconverted(layout, [.zero, Hex(q: 3, r: 0)])
      #expect(
        !HexLayout.placementIsFinite(size: size, origins: origins, cell: cell, in: Float.self))
      #expect(
        HexLayout.placementIsFinite(size: size, origins: origins, cell: cell, in: Double.self))
    }

    /// Every layout on a watch lies outside representable geometry, which is not
    /// a stop: an ordinary board places there as anywhere else.
    @Test("An ordinary board places on a watch")
    func ordinaryBoardPlacesOnAWatch() {
      let layout = HexLayout(orientation: .flat, size: Point(x: 30, y: 30))
      for hexes in [[Hex.zero], HexShape.hexagon(radius: 3).cells()] {
        let (size, origins, cell) = Self.unconverted(layout, hexes)
        #expect(
          HexLayout.placementIsFinite(size: size, origins: origins, cell: cell, in: Float.self))
      }
    }
  }

  #if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
    /// Exit tests run the closure in a child process and expect it to stop; they
    /// exist from Swift 6.2 on, so older compilers skip this suite.
    @Suite("Placement preconditions")
    struct PlacementPreconditionTests {

      @Test("An infinite center stops the placement")
      func infiniteCenterStops() async {
        await #expect(processExitsWith: .failure) {
          _ = HexLayout(orientation: .flat, size: Point(x: 1e307, y: 1))
            .placement(of: [Hex(q: 100, r: 0)])
        }
      }

      @Test("An infinite center next to a finite one stops the placement")
      func infiniteCenterNextToAFiniteOneStops() async {
        await #expect(processExitsWith: .failure) {
          _ = HexLayout(orientation: .flat, size: Point(x: 1e307, y: 1))
            .placement(of: [.zero, Hex(q: 100, r: 0)])
        }
      }

      /// Finite frames whose extent plus a cell overflows: the size of the
      /// container is not finite.
      @Test("An extent that overflows stops the placement")
      func extentThatOverflowsStops() async {
        await #expect(processExitsWith: .failure) {
          _ = HexLayout(orientation: .flat, size: Point(x: 1.7e307, y: 1))
            .placement(of: [Hex(q: -3, r: 0), Hex(q: 3, r: 0)])
        }
      }
    }
  #endif
#endif
