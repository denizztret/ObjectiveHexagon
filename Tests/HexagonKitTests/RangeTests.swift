import Testing

@testable import HexagonKit

@Suite("Hex.range and Hex.intersection")
struct RangeTests {

  // MARK: Movement range

  /// The range of radius 1 of the guide, listed row by row as `HexShape` lists
  /// a hexagon (deviation 7 of `Conformance.md`).
  @Test("A range of radius one is listed row by row")
  func rangeOfRadiusOneIsListedRowByRow() {
    let expected = [
      Hex(q: 0, r: -1), Hex(q: 1, r: -1),
      Hex(q: -1, r: 0), Hex(q: 0, r: 0), Hex(q: 1, r: 0),
      Hex(q: -1, r: 1), Hex(q: 0, r: 1),
    ]
    #expect(Hex.zero.range(radius: 1) == expected)
  }

  /// The guide lists the range around `(2, -1, -1)` with the outer loop over
  /// `q`; the set is the same.
  @Test("A range around another center holds the cells of the guide")
  func rangeAroundAnotherCenterHoldsTheCellsOfTheGuide() {
    let guide: Set<Hex> = [
      Hex(q: 1, r: -1), Hex(q: 1, r: 0), Hex(q: 2, r: -2), Hex(q: 2, r: -1),
      Hex(q: 2, r: 0), Hex(q: 3, r: -2), Hex(q: 3, r: -1),
    ]
    let range = Hex(q: 2, r: -1).range(radius: 1)
    #expect(Set(range) == guide)
    #expect(range.count == guide.count)
  }

  @Test("A range has one plus three times radius times radius plus one cells")
  func rangeCountsMatchTheGuide() {
    #expect((0...5).map { Hex.zero.range(radius: $0).count } == [1, 7, 19, 37, 61, 91])
    #expect(Hex(q: 4, r: -9).range(radius: 0) == [Hex(q: 4, r: -9)])
  }

  @Test("A range is the hexagon shape around its center, in the same order")
  func rangeIsTheHexagonShape() {
    for center in [Hex.zero, Hex(q: 7, r: -3), Hex(q: -12, r: 20)] {
      for radius in 0...6 {
        #expect(
          center.range(radius: radius)
            == HexShape.hexagon(center: center, radius: radius).cells())
      }
    }
  }

  @Test("A range holds exactly the hexes within the radius")
  func rangeHoldsExactlyTheHexesWithinTheRadius() {
    let center = Hex(q: 3, r: -5)
    let range = Set(center.range(radius: 4))
    var mismatches: [String] = []
    for q in -10...10 {
      for r in -10...10 {
        let hex = center + Hex(q: q, r: r)
        if range.contains(hex) != (hex.distance(to: center) <= 4) {
          mismatches.append("\(hex)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Intersection of ranges

  /// The example of the guide's diagram, both of radius 3, listed row by row.
  @Test("The intersection of the diagram's example")
  func intersectionOfTheDiagramExample() {
    let expected = [
      Hex(q: -2, r: 1), Hex(q: -1, r: 1),
      Hex(q: -2, r: 2), Hex(q: -1, r: 2),
      Hex(q: -2, r: 3), Hex(q: -1, r: 3),
    ]
    #expect(
      Hex.intersection(ofRanges: [(Hex(q: -4, r: 4), 3), (Hex(q: 1, r: 0), 3)]) == expected)
  }

  @Test("Intersections of the reference values, row by row")
  func intersectionsOfTheReferenceValues() {
    #expect(
      Hex.intersection(ofRanges: [(.zero, 2), (Hex(q: 3, r: -1), 2)]) == [
        Hex(q: 2, r: -2), Hex(q: 1, r: -1), Hex(q: 2, r: -1),
        Hex(q: 1, r: 0), Hex(q: 2, r: 0), Hex(q: 1, r: 1),
      ])
    #expect(Hex.intersection(ofRanges: [(.zero, 1), (Hex(q: 2, r: 0), 1)]) == [Hex(q: 1, r: 0)])
    #expect(Hex.intersection(ofRanges: [(.zero, 1), (Hex(q: 3, r: 0), 1)]).isEmpty)
    #expect(
      Hex.intersection(ofRanges: [(.zero, 2), (Hex(q: 2, r: 0), 2), (Hex(q: 0, r: 2), 2)]) == [
        Hex(q: 0, r: 0), Hex(q: 1, r: 0), Hex(q: 2, r: 0),
        Hex(q: 0, r: 1), Hex(q: 1, r: 1),
        Hex(q: 0, r: 2),
      ])
    #expect(
      Hex.intersection(ofRanges: [(Hex(q: 5, r: -5), 0), (Hex(q: 5, r: -5), 0)]) == [
        Hex(q: 5, r: -5)
      ])
  }

  @Test("The labels of the ranges may be spelled out or left out")
  func labelsMayBeSpelledOutOrLeftOut() {
    let a = Hex(q: 1, r: 1)
    let b = Hex(q: 2, r: 0)
    let spelled = Hex.intersection(ofRanges: [(center: a, radius: 3), (center: b, radius: 2)])
    #expect(spelled == Hex.intersection(ofRanges: [(center: a, radius: 3), (b, 2)]))
    #expect(spelled == Hex.intersection(ofRanges: [(a, 3), (b, 2)]))
  }

  @Test("The intersection of a single range is that range")
  func intersectionOfASingleRangeIsThatRange() {
    for center in [Hex.zero, Hex(q: -6, r: 2)] {
      for radius in 0...5 {
        #expect(
          Hex.intersection(ofRanges: [(center, radius)]) == center.range(radius: radius))
      }
    }
  }

  /// The guide's formula with a radius per range, against a scan of the
  /// defining inequalities, for every pair and some triples of small ranges.
  @Test("Intersections of ranges of different radii match a scan")
  func intersectionsMatchAScan() {
    let centers = [
      Hex.zero, Hex(q: 2, r: -1), Hex(q: -3, r: 1), Hex(q: 1, r: 3), Hex(q: 4, r: -4),
    ]
    var sets: [[(center: Hex, radius: Int)]] = []
    for first in centers {
      for second in centers {
        for (firstRadius, secondRadius) in [(0, 2), (1, 1), (2, 3), (3, 1), (4, 4)] {
          sets.append([(first, firstRadius), (second, secondRadius)])
          sets.append([(first, firstRadius), (second, secondRadius), (Hex(q: 1, r: 0), 3)])
        }
      }
    }
    var mismatches: [String] = []
    for ranges in sets {
      var expected: [Hex] = []
      for r in -12...12 {
        for q in -12...12 {
          let hex = Hex(q: q, r: r)
          if ranges.allSatisfy({ hex.distance(to: $0.center) <= $0.radius }) {
            expected.append(hex)
          }
        }
      }
      if Hex.intersection(ofRanges: ranges) != expected {
        mismatches.append("\(ranges)")
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// doc-016, section 3.4: a range of the largest radius around the origin and
  /// a small range at its edge give a few hexes, and the huge range is never
  /// listed.
  @Test("A huge range intersected with a small one at its edge")
  func hugeRangeIntersectedWithASmallOne() {
    let largest = Hex.coordinateBound - 1
    #expect(
      Hex.intersection(ofRanges: [(.zero, largest), (Hex(q: 1_073_741_822, r: -1_073_741_819), 1)])
        == [
          Hex(q: 1_073_741_822, r: -1_073_741_820), Hex(q: 1_073_741_823, r: -1_073_741_820),
          Hex(q: 1_073_741_821, r: -1_073_741_819), Hex(q: 1_073_741_822, r: -1_073_741_819),
          Hex(q: 1_073_741_823, r: -1_073_741_819), Hex(q: 1_073_741_821, r: -1_073_741_818),
          Hex(q: 1_073_741_822, r: -1_073_741_818),
        ])
    #expect(
      Hex.intersection(ofRanges: [(.zero, largest), (Hex(q: 5, r: -3), 1)])
        == Hex(q: 5, r: -3).range(radius: 1))
  }

  // MARK: The arithmetic of a 32-bit platform

  /// The example of the review of doc-016, run in `Int32`: the sum of the
  /// three lower bounds of this range is `-2 147 483 649`, beyond 32 bits, and
  /// a formula that took it would stop here on the overflow. The pairwise sums
  /// stay inside.
  @Test("The bounds of the review example fit 32 bits")
  func boundsOfTheReviewExampleFit32Bits() throws {
    let bounds = try #require(RangeIntersection<Int32>(ranges: [(q: 0, r: 0, radius: 715_827_883)]))
    #expect(bounds.rows == -715_827_883...715_827_883)
    #expect(bounds.columns(inRow: -715_827_883) == 0...715_827_883)
    #expect(bounds.columns(inRow: 0) == -715_827_883...715_827_883)
    #expect(bounds.columns(inRow: 715_827_883) == -715_827_883...0)
  }

  /// The largest range and the edge of the supported coordinate range, in
  /// `Int32`: here a pairwise sum reaches `2^31 - 2`.
  @Test("The bounds of the largest ranges fit 32 bits")
  func boundsOfTheLargestRangesFit32Bits() throws {
    let largest: Int32 = 1_073_741_823
    let whole = try #require(RangeIntersection<Int32>(ranges: [(q: 0, r: 0, radius: largest)]))
    #expect(whole.rows == -largest...largest)
    #expect(whole.columns(inRow: -largest) == 0...largest)
    #expect(whole.columns(inRow: largest) == -largest...0)
    let edge = try #require(
      RangeIntersection<Int32>(ranges: [
        (q: 0, r: 0, radius: largest), (q: 1_073_741_822, r: -1_073_741_819, radius: 1),
      ]))
    #expect(edge.rows == -1_073_741_820...(-1_073_741_818))
    #expect(edge.columns(inRow: -1_073_741_820) == 1_073_741_822...1_073_741_823)
    #expect(edge.columns(inRow: -1_073_741_819) == 1_073_741_821...1_073_741_823)
    #expect(edge.columns(inRow: -1_073_741_818) == 1_073_741_821...1_073_741_822)
    let opposite = try #require(
      RangeIntersection<Int32>(ranges: [
        (q: 536_870_911, r: 0, radius: 536_870_912), (q: -536_870_911, r: 0, radius: 536_870_912),
      ]))
    #expect(opposite.rows == -2...2)
    #expect(opposite.columns(inRow: -2) == 1...1)
    #expect(opposite.columns(inRow: 0) == -1...1)
    #expect(opposite.columns(inRow: 2) == -1...(-1))
  }

  /// Pairs of ranges centered on the edges of the supported coordinate range,
  /// with the largest, the smallest and a middle radius each: `Int32` finds the
  /// same rows and columns as `Int`.
  @Test("Ranges at the edges of the coordinate range give the same bounds in 32 bits")
  func rangesAtTheEdgesGiveTheSameBoundsIn32Bits() {
    let limit = Hex.coordinateBound - 1
    let values = [-limit, -limit / 2, 0, limit / 2, limit]
    var centers: [Hex] = []
    for q in values {
      for r in values where abs(q + r) <= limit {
        centers.append(Hex(q: q, r: r))
      }
    }
    func radii(_ center: Hex) -> [Int] {
      let largest = limit - center.length
      return [largest, 0, largest / 2]
    }
    var mismatches: [String] = []
    for first in centers {
      for second in centers {
        for (firstRadius, secondRadius) in zip(radii(first), radii(second)) {
          let wide = RangeIntersection<Int>(ranges: [
            (q: first.q, r: first.r, radius: firstRadius),
            (q: second.q, r: second.r, radius: secondRadius),
          ])
          let narrow = RangeIntersection<Int32>(ranges: [
            (q: Int32(first.q), r: Int32(first.r), radius: Int32(firstRadius)),
            (q: Int32(second.q), r: Int32(second.r), radius: Int32(secondRadius)),
          ])
          guard let wide, let narrow else {
            if (wide == nil) != (narrow == nil) {
              mismatches.append("\(first) \(second): empty in one width only")
            }
            continue
          }
          let rows = [
            wide.rows.lowerBound, (wide.rows.lowerBound + wide.rows.upperBound) / 2,
            wide.rows.upperBound,
          ]
          if Int(narrow.rows.lowerBound) != wide.rows.lowerBound
            || Int(narrow.rows.upperBound) != wide.rows.upperBound
          {
            mismatches.append("\(first) \(second): rows")
          }
          for row in rows {
            let wideColumns = wide.columns(inRow: row)
            let narrowColumns = narrow.columns(inRow: Int32(row))
            if Int(narrowColumns.lowerBound) != wideColumns.lowerBound
              || Int(narrowColumns.upperBound) != wideColumns.upperBound
            {
              mismatches.append("\(first) \(second): row \(row)")
            }
          }
        }
      }
    }
    #expect(centers.count == 19)
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// The example of the review: the sum of the three lower bounds of this
  /// range is `-2 147 483 649`, beyond a 32-bit `Int`. The rows are narrowed
  /// with sums of two bounds instead.
  @Test("The range of the review example intersected at its edge")
  func reviewExampleIntersectedAtItsEdge() {
    #expect(
      Hex.intersection(ofRanges: [(.zero, 715_827_883), (Hex(q: 715_827_883, r: 0), 1)]) == [
        Hex(q: 715_827_883, r: -1), Hex(q: 715_827_882, r: 0),
        Hex(q: 715_827_883, r: 0), Hex(q: 715_827_882, r: 1),
      ])
  }
}

#if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
  /// Exit tests run the closure in a child process and expect it to stop; they
  /// exist from Swift 6.2 on, so older compilers skip this suite.
  @Suite("Hex.range and Hex.intersection preconditions")
  struct RangePreconditionTests {

    @Test("A negative radius stops the range")
    func negativeRadiusStopsTheRange() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.range(radius: -1)
      }
    }

    /// The range of radius 1 around this hex reaches `q = 2^30`; `reachable`
    /// covers the same hexes without stopping, see `ReachableTests`.
    @Test("A range that leaves the supported coordinate range stops")
    func rangeBeyondTheCoordinateRangeStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex(q: 1_073_741_823, r: 0).range(radius: 1)
      }
    }

    @Test("An intersection of no ranges stops")
    func intersectionOfNoRangesStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.intersection(ofRanges: [])
      }
    }

    @Test("An intersection with a negative radius stops")
    func intersectionWithANegativeRadiusStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.intersection(ofRanges: [(.zero, 2), (Hex(q: 1, r: 0), -1)])
      }
    }

    @Test("An intersection with a range beyond the coordinate range stops")
    func intersectionBeyondTheCoordinateRangeStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.intersection(ofRanges: [(.zero, 2), (Hex(q: 1_073_741_823, r: 0), 1)])
      }
    }
  }
#endif
