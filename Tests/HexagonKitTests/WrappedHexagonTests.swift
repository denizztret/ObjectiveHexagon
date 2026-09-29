import Foundation
import Testing

@testable import HexagonKit

@Suite("WrappedHexagon")
struct WrappedHexagonTests {

  /// The guide's rule, step by step: subtract the mirror center closest to the
  /// hex until the hex is back on the map. Ties go to the first mirror center
  /// in order; the cell reached does not depend on them.
  static func guideWrap(_ hex: Hex, in map: WrappedHexagon) -> Hex {
    var hex = hex
    while hex.distance(to: map.center) > map.radius {
      var nearest = map.mirrorCenters[0]
      for mirror in map.mirrorCenters
      where hex.distance(to: map.center + mirror) < hex.distance(to: map.center + nearest) {
        nearest = mirror
      }
      hex = hex - nearest
    }
    return hex
  }

  // MARK: Mirror centers

  @Test("Mirror centers match the table of the guide")
  func mirrorCentersMatchTheGuide() {
    #expect(
      WrappedHexagon(radius: 0).mirrorCenters == [
        Hex(q: 1, r: 0), Hex(q: 0, r: 1), Hex(q: -1, r: 1),
        Hex(q: -1, r: 0), Hex(q: 0, r: -1), Hex(q: 1, r: -1),
      ])
    #expect(
      WrappedHexagon(radius: 1).mirrorCenters == [
        Hex(q: 3, r: -1), Hex(q: 1, r: 2), Hex(q: -2, r: 3),
        Hex(q: -3, r: 1), Hex(q: -1, r: -2), Hex(q: 2, r: -3),
      ])
    #expect(
      WrappedHexagon(radius: 2).mirrorCenters == [
        Hex(q: 5, r: -2), Hex(q: 2, r: 3), Hex(q: -3, r: 5),
        Hex(q: -5, r: 2), Hex(q: -2, r: -3), Hex(q: 3, r: -5),
      ])
    #expect(
      WrappedHexagon(radius: 3).mirrorCenters == [
        Hex(q: 7, r: -3), Hex(q: 3, r: 4), Hex(q: -4, r: 7),
        Hex(q: -7, r: 3), Hex(q: -3, r: -4), Hex(q: 4, r: -7),
      ])
  }

  @Test("Each mirror center is the previous one rotated clockwise, 2N + 1 steps away")
  func mirrorCentersAreRotationsOfTheFirst() {
    for radius in 0...9 {
      let centers = WrappedHexagon(center: Hex(q: 4, r: -1), radius: radius).mirrorCenters
      #expect(centers[0] == Hex(q: 2 * radius + 1, r: -radius))
      #expect(centers.allSatisfy { $0.length == 2 * radius + 1 })
      for index in 1..<6 {
        #expect(centers[index] == centers[index - 1].rotated(by: 1))
      }
    }
  }

  // MARK: Wrapping

  /// The reference values of the map of radius 2.
  @Test("Hexes off the map of radius two wrap as in the guide")
  func hexesWrapAsInTheGuide() {
    let map = WrappedHexagon(radius: 2)
    let expected: [(Hex, Hex)] = [
      (Hex(q: 3, r: 0), Hex(q: -2, r: 2)), (Hex(q: 0, r: -3), Hex(q: 2, r: 0)),
      (Hex(q: -3, r: 3), Hex(q: 0, r: -2)), (Hex(q: 3, r: -1), Hex(q: -2, r: 1)),
      (Hex(q: 2, r: 1), Hex(q: 0, r: -2)), (Hex(q: -1, r: -2), Hex(q: 1, r: 1)),
      (Hex(q: 5, r: -2), Hex(q: 0, r: 0)), (Hex(q: 4, r: -2), Hex(q: -1, r: 0)),
      (Hex(q: 6, r: -6), Hex(q: -2, r: 1)), (Hex(q: -7, r: 3), Hex(q: -2, r: 1)),
      (Hex(q: 10, r: 0), Hex(q: -2, r: 1)),
    ]
    for (hex, cell) in expected {
      #expect(map.wrap(hex) == cell)
    }
  }

  @Test("The neighbors of an edge cell wrap to the other side")
  func neighborsOfAnEdgeCellWrap() {
    let map = WrappedHexagon(radius: 2)
    #expect(
      Hex(q: 2, r: 0).neighbors.map(map.wrap) == [
        Hex(q: -2, r: 2), Hex(q: -2, r: 1), Hex(q: 2, r: -1),
        Hex(q: 1, r: 0), Hex(q: 1, r: 1), Hex(q: 0, r: -2),
      ])
  }

  @Test("The formula agrees with the guide's rule of mirror centers")
  func formulaAgreesWithTheGuideRule() {
    var mismatches: [String] = []
    for radius in 0...5 {
      for center in [Hex.zero, Hex(q: 7, r: -3)] {
        let map = WrappedHexagon(center: center, radius: radius)
        for offset in HexShape.hexagon(radius: 4 * radius + 6).cells() {
          let hex = center + offset
          if map.wrap(hex) != Self.guideWrap(hex, in: map) {
            mismatches.append("radius \(radius) center \(center) hex \(hex)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("A cell of the map wraps to itself, and wrapping twice changes nothing")
  func cellsWrapToThemselves() {
    let map = WrappedHexagon(center: Hex(q: -2, r: 5), radius: 3)
    #expect(map.shape.cells().allSatisfy { map.wrap($0) == $0 })
    for offset in HexShape.hexagon(radius: 12).cells() {
      let hex = map.center + offset
      #expect(map.wrap(map.wrap(hex)) == map.wrap(hex))
      #expect(map.mirrorCenters.allSatisfy { map.wrap(hex + $0) == map.wrap(hex) })
    }
  }

  @Test("A map of one cell wraps every hex to its center")
  func mapOfOneCellWrapsEveryHexToItsCenter() {
    let map = WrappedHexagon(center: Hex(q: 3, r: 3), radius: 0)
    #expect(map.wrap(Hex(q: 3, r: 3)) == Hex(q: 3, r: 3))
    #expect(map.wrap(Hex(q: -1_073_741_823, r: 0)) == Hex(q: 3, r: 3))
  }

  /// doc-016, section 3.11: the result lies on the map and stays the same for
  /// hexes anywhere in the supported range, for the largest map whose cell
  /// count fits a 32-bit `Int` and for small ones.
  @Test("Hexes at the edges of the coordinate range wrap onto the map")
  func hexesAtTheEdgesOfTheRangeWrap() {
    let bound = Hex.coordinateBound - 1
    let far = [
      Hex(q: bound, r: 0), Hex(q: -bound, r: bound), Hex(q: 0, r: -bound),
      Hex(q: bound, r: -bound), Hex(q: -bound, r: 0), Hex(q: 123_456_789, r: -987_654_321),
    ]
    let maps = [
      WrappedHexagon(radius: 26_754),
      WrappedHexagon(center: Hex(q: bound - 26_754, r: 0), radius: 26_754),
      WrappedHexagon(center: Hex(q: -5, r: 9), radius: 7),
      WrappedHexagon(radius: 1),
    ]
    var mismatches: [String] = []
    for map in maps {
      for hex in far {
        let cell = map.wrap(hex)
        if cell.distance(to: map.center) > map.radius || map.wrap(cell) != cell {
          mismatches.append("\(map.radius) \(hex) -> \(cell)")
        }
        // A mirror center that points back towards the origin keeps the
        // shifted hex inside the supported range.
        let moved = hex + map.mirrorCenters[hex.q > 0 ? 3 : 0]
        if moved.length < Hex.coordinateBound && map.wrap(moved) != cell {
          mismatches.append("mirror \(map.radius) \(hex)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  #if _pointerBitWidth(_64)
    /// The largest map around the origin, whose cell count is `3.46 * 10^18`.
    @Test("The largest map wraps hexes at the edge of the range")
    func largestMapWrapsHexesAtTheEdge() {
      let map = WrappedHexagon(radius: Hex.coordinateBound - 1)
      let edge = Hex(q: Hex.coordinateBound - 1, r: -5)
      #expect(map.wrap(edge) == edge)
      #expect(map.wrap(Hex(q: 1, r: -2)) == Hex(q: 1, r: -2))
      #expect(map.mirrorCenters[0] == Hex(q: 2_147_483_647, r: -1_073_741_823))
    }
  #endif

  // MARK: The arithmetic of a 32-bit platform

  /// The formula run in `Int32` against the same formula in `Int`: maps up to
  /// the largest one whose cell count fits 32 bits, centers at the edges of the
  /// supported coordinate range, and hexes at its extremes. In 32 bits the
  /// products of the shift and a coordinate need the double width, and the
  /// offsets from a far center approach `2^31`.
  @Test("Wrapping in 32 bits gives the cells that 64 bits give")
  func wrappingIn32BitsMatches64Bits() {
    let limit = Hex.coordinateBound - 1
    let extremes = [-limit, -limit / 2, -1, 0, 1, limit / 2, limit]
    var mismatches: [String] = []
    var cases = 0
    for radius in [1, 2, 7, 100, 1000, 26_753, 26_754] {
      let reach = limit - radius
      let centers = [
        Hex.zero, Hex(q: reach, r: -reach), Hex(q: -reach, r: reach), Hex(q: 0, r: -reach),
        Hex(q: reach / 2, r: reach / 2 - 5),
      ]
      for center in centers {
        for q in extremes {
          for r in extremes where abs(q + r) <= limit {
            let dq = q - center.q
            let dr = r - center.r
            let wide = WrappedHexagon.wrappedOffset(q: dq, r: dr, radius: radius)
            let narrow = WrappedHexagon.wrappedOffset(
              q: Int32(dq), r: Int32(dr), radius: Int32(radius))
            cases += 1
            if Int(narrow.q) != wide.q || Int(narrow.r) != wide.r {
              mismatches.append("radius \(radius) center \(center) hex (\(q), \(r))")
            }
            if Hex(q: wide.q, r: wide.r).length > radius {
              mismatches.append("off the map: radius \(radius) center \(center) hex (\(q), \(r))")
            }
          }
        }
      }
    }
    #expect(cases == 7 * 5 * 39)
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  #if _pointerBitWidth(_64)
    /// The quotient in double width, with products beyond 64 bits: on a 32-bit
    /// platform the formula needs exactly this for the largest maps. The cases
    /// cover a negative dividend with and without a remainder, a carry from the
    /// low half into the high one, and a borrow the other way.
    @Test("The floored quotient in double width")
    func flooredQuotientInDoubleWidth() {
      #expect(
        WrappedHexagon.flooredQuotient(
          3_000_000_000, times: 4_000_000_000, plus: 7, dividedBy: 10_000_000_000)
          == 1_200_000_000)
      #expect(
        WrappedHexagon.flooredQuotient(
          -3_000_000_000, times: 4_000_000_000, plus: 7, dividedBy: 10_000_000_000)
          == -1_200_000_000)
      #expect(
        WrappedHexagon.flooredQuotient(
          -3_000_000_000, times: 4_000_000_000, plus: -7, dividedBy: 10_000_000_000)
          == -1_200_000_001)
      #expect(
        WrappedHexagon.flooredQuotient(
          4_294_967_295, times: 4_294_967_297, plus: 1, dividedBy: 8_589_934_592)
          == 2_147_483_648)
      #expect(
        WrappedHexagon.flooredQuotient(
          4_294_967_296, times: 4_294_967_296, plus: -1, dividedBy: 4_294_967_295)
          == 4_294_967_297)
    }
  #endif

  // MARK: Shape and storage

  @Test("The shape is the hexagon of the map, and it indexes dense storage")
  func shapeIsTheHexagonOfTheMap() {
    let map = WrappedHexagon(center: Hex(q: 1, r: -1), radius: 2)
    #expect(map.shape == HexShape.hexagon(center: Hex(q: 1, r: -1), radius: 2))
    var visits = DenseHexMap(repeating: 0, shape: map.shape)
    for offset in HexShape.hexagon(radius: 9).cells() {
      visits[map.wrap(map.center + offset)]? += 1
    }
    #expect(visits.values.reduce(0, +) == HexShape.hexagon(radius: 9).count)
    #expect(visits.values.allSatisfy { $0 > 0 })
  }

  // MARK: Codable

  @Test("A wrapped map encodes as its center and radius")
  func encodingKeepsTheCenterAndTheRadius() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let json = String(
      decoding: try encoder.encode(WrappedHexagon(center: Hex(q: 1, r: -2), radius: 3)),
      as: UTF8.self)
    #expect(json == #"{"center":{"q":1,"r":-2},"radius":3}"#)
    let back = try JSONDecoder().decode(WrappedHexagon.self, from: Data(json.utf8))
    #expect(back == WrappedHexagon(center: Hex(q: 1, r: -2), radius: 3))
  }

  @Test("Decoding a radius out of range fails")
  func decodingRejectsARadiusOutOfRange() {
    let negative = #"{"center":{"q":0,"r":0},"radius":-1}"#
    let huge = #"{"center":{"q":0,"r":0},"radius":2000000000}"#
    let offCenter = #"{"center":{"q":1073741823,"r":0},"radius":1}"#
    for json in [negative, huge, offCenter] {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(WrappedHexagon.self, from: Data(json.utf8))
      }
    }
  }
}

#if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
  /// Exit tests run the closure in a child process and expect it to stop; they
  /// exist from Swift 6.2 on, so older compilers skip this suite.
  @Suite("WrappedHexagon preconditions")
  struct WrappedHexagonPreconditionTests {

    @Test("A negative radius stops the initializer")
    func negativeRadiusStops() async {
      await #expect(processExitsWith: .failure) {
        _ = WrappedHexagon(radius: -1)
      }
    }

    @Test("A map whose cells leave the supported range stops the initializer")
    func cellsBeyondTheRangeStop() async {
      await #expect(processExitsWith: .failure) {
        _ = WrappedHexagon(center: Hex(q: 1_073_741_823, r: 0), radius: 1)
      }
    }
  }
#endif
