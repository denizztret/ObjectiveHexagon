import Testing

@testable import HexagonKit

@Suite("Hex.spiral and spiral coordinates")
struct SpiralTests {

  // MARK: Spiral

  @Test("The spirals of radius zero, one and two match the guide")
  func spiralsMatchTheGuide() {
    #expect(Hex.zero.spiral(radius: 0) == [.zero])
    let first = [
      Hex.zero, Hex(q: -1, r: 1), Hex(q: 0, r: 1), Hex(q: 1, r: 0), Hex(q: 1, r: -1),
      Hex(q: 0, r: -1), Hex(q: -1, r: 0),
    ]
    #expect(Hex.zero.spiral(radius: 1) == first)
    let second = [
      Hex(q: -2, r: 2), Hex(q: -1, r: 2), Hex(q: 0, r: 2), Hex(q: 1, r: 1), Hex(q: 2, r: 0),
      Hex(q: 2, r: -1), Hex(q: 2, r: -2), Hex(q: 1, r: -2), Hex(q: 0, r: -2), Hex(q: -1, r: -1),
      Hex(q: -2, r: 0), Hex(q: -2, r: 1),
    ]
    #expect(Hex.zero.spiral(radius: 2) == first + second)
  }

  @Test("A spiral around another center matches the guide")
  func spiralAroundAnotherCenterMatchesTheGuide() {
    let expected = [
      Hex(q: 1, r: -2), Hex(q: 0, r: -1), Hex(q: 1, r: -1), Hex(q: 2, r: -2), Hex(q: 2, r: -3),
      Hex(q: 1, r: -3), Hex(q: 0, r: -2),
    ]
    #expect(Hex(q: 1, r: -2).spiral(radius: 1) == expected)
  }

  /// ObjectiveHexagon's `hexesBySpirals()` dropped the outer ring (doc-002).
  @Test("A spiral includes its outer ring")
  func spiralIncludesItsOuterRing() {
    let center = Hex(q: 4, r: -1)
    #expect((0...5).map { center.spiral(radius: $0).count } == [1, 7, 19, 37, 61, 91])
    for radius in 1...6 {
      let spiral = center.spiral(radius: radius)
      #expect(Array(spiral.suffix(6 * radius)) == center.ring(radius: radius))
    }
  }

  @Test("A spiral holds the cells of the range, in the order of the rings")
  func spiralHoldsTheCellsOfTheRange() {
    for center in [Hex.zero, Hex(q: -7, r: 3)] {
      for radius in 0...7 {
        let spiral = center.spiral(radius: radius)
        #expect(Set(spiral) == Set(center.range(radius: radius)))
        #expect(spiral.count == center.range(radius: radius).count)
        #expect(spiral == (0...radius).flatMap { center.ring(radius: $0) })
      }
    }
  }

  // MARK: Spiral coordinates

  /// The table of the guide's spiral coordinates, from index 0 to 19.
  static let firstIndices: [Hex] = [
    Hex(q: 0, r: 0), Hex(q: -1, r: 1), Hex(q: 0, r: 1), Hex(q: 1, r: 0), Hex(q: 1, r: -1),
    Hex(q: 0, r: -1), Hex(q: -1, r: 0), Hex(q: -2, r: 2), Hex(q: -1, r: 2), Hex(q: 0, r: 2),
    Hex(q: 1, r: 1), Hex(q: 2, r: 0), Hex(q: 2, r: -1), Hex(q: 2, r: -2), Hex(q: 1, r: -2),
    Hex(q: 0, r: -2), Hex(q: -1, r: -1), Hex(q: -2, r: 0), Hex(q: -2, r: 1), Hex(q: -3, r: 3),
  ]

  @Test("Spiral coordinates match the table of the guide")
  func spiralCoordinatesMatchTheGuide() {
    for (index, hex) in Self.firstIndices.enumerated() {
      #expect(hex.spiralIndex() == index)
      #expect(Hex(spiralIndex: index) == hex)
    }
    #expect(Hex(q: 3, r: 0).spiralIndex() == 25)
    #expect(Hex(spiralIndex: 25) == Hex(q: 3, r: 0))
  }

  /// The guide's formulas break at index 0; the center has index 0 here.
  @Test("The center has index zero and each ring starts at its corner")
  func ringsStartWhereTheGuideSays() {
    let center = Hex(q: -2, r: 5)
    #expect(center.spiralIndex(around: center) == 0)
    #expect(Hex(spiralIndex: 0, around: center) == center)
    let starts = (1...6).map { 1 + 3 * $0 * ($0 - 1) }
    #expect([0] + starts == [0, 1, 7, 19, 37, 61, 91])
    for radius in 1...9 {
      let corner = center + HexDirection.plusRMinusQ.vector * radius
      #expect(corner.spiralIndex(around: center) == 1 + 3 * radius * (radius - 1))
      #expect(
        Hex(spiralIndex: 3 * radius * (radius + 1), around: center)
          == center.ring(radius: radius).last)
    }
  }

  @Test("The spiral and the spiral coordinates agree")
  func spiralAndCoordinatesAgree() {
    var mismatches: [String] = []
    for center in [Hex.zero, Hex(q: 9, r: -4)] {
      for (index, hex) in center.spiral(radius: 12).enumerated() {
        if Hex(spiralIndex: index, around: center) != hex {
          mismatches.append("hex of \(index) around \(center)")
        }
        if hex.spiralIndex(around: center) != index {
          mismatches.append("index of \(hex) around \(center)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("The origin is the default center")
  func originIsTheDefaultCenter() {
    #expect(Hex(q: 2, r: -7).spiralIndex() == Hex(q: 2, r: -7).spiralIndex(around: .zero))
    #expect(Hex(spiralIndex: 40) == Hex(spiralIndex: 40, around: .zero))
  }

  /// The largest ring whose indices all fit a 32-bit `Int`, and the first
  /// index of the next ring; both fit a 32-bit `Int` themselves.
  @Test("The indices at the edge of a 32-bit Int round trip")
  func indicesAtTheEdgeOfA32BitIntRoundTrip() {
    let last = Hex(spiralIndex: 2_147_409_810)
    #expect(last.length == 26_754)
    #expect(last.spiralIndex() == 2_147_409_810)
    let next = Hex(spiralIndex: 2_147_409_811)
    #expect(next == HexDirection.plusRMinusQ.vector * 26_755)
    #expect(next.spiralIndex() == 2_147_409_811)
  }

  /// The largest index there is: its hex lies far outside the supported range
  /// on a 64-bit platform, but it still converts without an overflow.
  @Test("The largest index converts in both directions")
  func largestIndexConvertsInBothDirections() {
    #expect(Hex(spiralIndex: Int.max).spiralIndex() == Int.max)
    #expect(Hex(spiralIndex: Int.max - 1).spiralIndex() == Int.max - 1)
    let center = Hex(q: 1_073_741_823, r: -5)
    #expect(Hex(spiralIndex: Int.max, around: center).spiralIndex(around: center) == Int.max)
  }

  // MARK: The arithmetic of a 32-bit platform

  /// The index arithmetic run in `Int32`: every index of the ring 26754 fits,
  /// the ring 26755 starts at `2 147 409 811`, and the largest index converts
  /// back and forth, with the same ring, segment and step as in `Int`.
  @Test("Spiral indices at the edge of 32 bits convert in Int32")
  func spiralIndicesAtTheEdgeOf32Bits() {
    #expect(Hex.spiralIndex(radius: Int32(26_754), side: 5, position: 26_753) == 2_147_409_810)
    let indices: [Int32] = [
      1, 6, 7, 18, 19, 2_147_409_810, 2_147_409_811, Int32.max - 1, Int32.max,
    ]
    for index in indices {
      let narrow = Hex.spiralPlace(of: index)
      let wide = Hex.spiralPlace(of: Int(index))
      #expect(Int(narrow.radius) == wide.radius)
      #expect(Int(narrow.side) == wide.side)
      #expect(Int(narrow.position) == wide.position)
      #expect(
        Hex.spiralIndex(radius: narrow.radius, side: narrow.side, position: narrow.position)
          == index)
    }
    #expect(Hex.spiralPlace(of: Int32.max) == (radius: 26_755, side: 2, position: 20_326))
  }

  #if _pointerBitWidth(_64)
    /// The guide's radius formula is exact in `Double` only up to the radius
    /// 44739242: one index before the ring 44739243 it answers 44739243. The
    /// ring start of the radius 506166751 is where `12 * index` overflows a
    /// 64-bit `Int`. Neither matters here, the root only gives an estimate.
    @Test("Rings beyond the precision of the guide's formula")
    func ringsBeyondThePrecisionOfTheFormula() {
      let checks: [(index: Int, radius: Int)] = [
        (6_004_799_189_985_967, 44_739_242),
        (6_004_799_458_421_418, 44_739_242),
        (6_004_799_458_421_419, 44_739_243),
        (768_614_334_898_187_250, 506_166_749),
        (768_614_334_898_187_251, 506_166_750),
        (768_614_337_935_187_751, 506_166_751),
      ]
      for check in checks {
        let hex = Hex(spiralIndex: check.index)
        #expect(hex.length == check.radius)
        #expect(hex.spiralIndex() == check.index)
      }
      let corner = HexDirection.plusRMinusQ.vector * 44_739_243
      #expect(Hex(spiralIndex: 6_004_799_458_421_419) == corner)
    }

    /// The whole supported range around the origin: its farthest ring ends at
    /// `3 * (2^30 - 1) * 2^30`.
    @Test("Spiral coordinates at the edge of the coordinate range")
    func spiralCoordinatesAtTheEdgeOfTheRange() {
      let radius = Hex.coordinateBound - 1
      #expect(Hex(q: radius, r: 0).spiralIndex() == 3_458_764_506_304_348_165)
      #expect(Hex(spiralIndex: 3_458_764_506_304_348_165) == Hex(q: radius, r: 0))
      #expect(Hex(spiralIndex: 3_458_764_510_599_315_456) == Hex(q: -radius, r: radius - 1))
      #expect(Hex(q: -radius, r: radius - 1).spiralIndex() == 3_458_764_510_599_315_456)
      #expect(Hex(spiralIndex: Int.max) == Hex(q: -247_585_342, r: -1_505_827_714))
    }
  #endif
}

#if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
  /// Exit tests run the closure in a child process and expect it to stop; they
  /// exist from Swift 6.2 on, so older compilers skip this suite.
  @Suite("Hex.spiral preconditions")
  struct SpiralPreconditionTests {

    @Test("A negative radius stops the spiral")
    func negativeRadiusStopsTheSpiral() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.spiral(radius: -1)
      }
    }

    @Test("A spiral that leaves the supported coordinate range stops")
    func spiralBeyondTheCoordinateRangeStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex(q: 0, r: -1_073_741_823).spiral(radius: 1)
      }
    }

    @Test("A negative spiral index stops")
    func negativeIndexStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex(spiralIndex: -1)
      }
    }

    /// In `Int32`, the index of the last hex of the ring 26755 does not fit.
    @Test("An index beyond 32 bits stops on the overflow in Int32")
    func indexBeyond32BitsStopsInInt32() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.spiralIndex(radius: Int32(26_755), side: 5, position: 26_754)
      }
    }

    /// Two hexes at opposite edges of the range are `2^31 - 2` steps apart, and
    /// the index of that ring does not fit `Int` even on a 64-bit platform.
    @Test("An index that does not fit Int stops on the overflow")
    func indexThatDoesNotFitStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex(q: 1_073_741_823, r: 0).spiralIndex(around: Hex(q: -1_073_741_823, r: 0))
      }
    }
  }
#endif
