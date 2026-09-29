import Foundation
import HexagonKit
import Testing

@Suite("HexAxis and reflections")
struct HexAxisTests {

  // MARK: Reference values

  /// The example of the guide's diagram, computed with the formulas `reflectQ`,
  /// `reflectR` and `reflectS` of the guide.
  @Test("Reflections of the diagram's hex match the guide")
  func reflectionsOfTheDiagramHexMatchTheGuide() {
    let hex = Hex(q: -1, r: -3)
    #expect(hex.reflected(across: .q) == Hex(q: -1, r: 4))
    #expect(hex.reflected(across: .r) == Hex(q: 4, r: -3))
    #expect(hex.reflected(across: .s) == Hex(q: -3, r: -1))
  }

  @Test("Reflections of a second hex match the guide")
  func reflectionsOfASecondHexMatchTheGuide() {
    let hex = Hex(q: 1, r: -3)
    #expect(hex.reflected(across: .q) == Hex(q: 1, r: 2))
    #expect(hex.reflected(across: .r) == Hex(q: 2, r: -3))
    #expect(hex.reflected(across: .s) == Hex(q: -3, r: 1))
  }

  /// "Subtract the reference point, perform the reflection, then add the
  /// reference point back."
  @Test("A reflection through a center other than the origin")
  func reflectionAroundACenter() {
    #expect(Hex(q: 3, r: 0).reflected(across: .q, around: Hex(q: 2, r: -1)) == Hex(q: 3, r: -3))
  }

  /// The other three reflections of the guide negate the first three, all
  /// relative to the center; the recipe of the documentation comment.
  @Test("The negated reflections follow the recipe")
  func negatedReflectionsFollowTheRecipe() {
    let hex = Hex(q: -1, r: -3)
    #expect(hex.reflected(across: .q) * -1 == Hex(q: 1, r: -4))
    #expect(hex.reflected(across: .r) * -1 == Hex(q: -4, r: 3))
    #expect(hex.reflected(across: .s) * -1 == Hex(q: 3, r: 1))
    let center = Hex(q: 2, r: -1)
    let negated = (hex - center).reflected(across: .q) * -1 + center
    #expect(negated.distance(to: center) == hex.distance(to: center))
    #expect((negated - center).q == -(hex - center).q)
  }

  // MARK: Properties

  @Test("Reflecting twice returns the original hex")
  func reflectionIsAnInvolution() {
    let centers = [Hex.zero, Hex(q: 5, r: -2), Hex(q: -3, r: 7)]
    var mismatches: [String] = []
    for axis in HexAxis.allCases {
      for center in centers {
        for q in -6...6 {
          for r in -6...6 {
            let hex = Hex(q: q, r: r)
            let twice = hex.reflected(across: axis, around: center)
              .reflected(across: axis, around: center)
            if twice != hex {
              mismatches.append("\(axis) \(center) \(hex)")
            }
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("A reflection keeps the distance to the center")
  func reflectionKeepsTheDistanceToTheCenter() {
    let center = Hex(q: -4, r: 1)
    var mismatches: [String] = []
    for axis in HexAxis.allCases {
      for q in -6...6 {
        for r in -6...6 {
          let hex = Hex(q: q, r: r)
          let reflected = hex.reflected(across: axis, around: center)
          if reflected.distance(to: center) != hex.distance(to: center) {
            mismatches.append("\(axis) \(hex)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// The axis `q` of the guide is the line `r = s` through the diagonals 0 and
  /// 3, not the line `q = 0`; likewise for `r` and `s`.
  @Test("The fixed hexes lie on the line through two opposite diagonals")
  func fixedHexesLieOnTheLineOfTwoDiagonals() {
    let lines: [(HexAxis, HexDiagonal, HexDiagonal)] = [
      (.q, .plusQ, .minusQ),
      (.r, .minusR, .plusR),
      (.s, .plusS, .minusS),
    ]
    let center = Hex(q: 2, r: -5)
    var mismatches: [String] = []
    for (axis, first, second) in lines {
      for q in -6...6 {
        for r in -6...6 {
          let offset = Hex(q: q, r: r)
          let hex = offset + center
          let isFixed = hex.reflected(across: axis, around: center) == hex
          let isOnTheLine: Bool
          switch axis {
          case .q: isOnTheLine = offset.r == offset.s
          case .r: isOnTheLine = offset.q == offset.s
          case .s: isOnTheLine = offset.q == offset.r
          }
          if isFixed != isOnTheLine {
            mismatches.append("\(axis) \(offset)")
          }
        }
      }
      for step in 1...4 {
        for diagonal in [first, second] {
          let hex = center + diagonal.vector * step
          if hex.reflected(across: axis, around: center) != hex {
            mismatches.append("\(axis) \(diagonal) \(step)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("The origin is the default center")
  func originIsTheDefaultCenter() {
    for axis in HexAxis.allCases {
      #expect(
        Hex(q: 4, r: -9).reflected(across: axis)
          == Hex(q: 4, r: -9).reflected(across: axis, around: .zero))
    }
  }

  /// The reflected hex stays inside the range when the hex and the center do and
  /// the center is the origin: the offsets only trade places.
  @Test("Reflections at the edge of the coordinate range")
  func reflectionsAtTheEdgeOfTheRange() {
    let bound = Hex.coordinateBound
    let edge = Hex(q: bound - 1, r: -(bound - 1))
    #expect(edge.reflected(across: .q) == Hex(q: bound - 1, r: 0))
    #expect(edge.reflected(across: .r) == Hex(q: 0, r: -(bound - 1)))
    #expect(edge.reflected(across: .s) == Hex(q: -(bound - 1), r: bound - 1))
  }

  // MARK: HexAxis

  @Test("There are three axes, encoded by name")
  func axesAreEncodedByName() throws {
    #expect(HexAxis.allCases == [.q, .r, .s])
    let json = String(decoding: try JSONEncoder().encode(HexAxis.allCases), as: UTF8.self)
    #expect(json == #"["q","r","s"]"#)
    let decoded = try JSONDecoder().decode([HexAxis].self, from: Data(#"["s","q"]"#.utf8))
    #expect(decoded == [.s, .q])
  }

  @Test("Decoding an unknown axis fails")
  func decodingRejectsAnUnknownAxis() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([HexAxis].self, from: Data(#"["x"]"#.utf8))
    }
  }
}
