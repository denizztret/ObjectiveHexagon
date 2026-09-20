import Foundation
import HexagonKit
import Testing

/// One row of the "exact halves" table of doc-008, section 2, column C++/Rust.
struct HalfRoundingRow: Sendable, CustomStringConvertible {
  let q: Double
  let r: Double
  let s: Double
  let expected: Hex

  var description: String { "(\(q), \(r), \(s))" }
}

@Suite("FractionalHex")
struct FractionalHexTests {

  // MARK: Reference values

  /// Reference test `test_hex_round`, case 1: the midpoint of the segment
  /// from `(0, 0, 0)` to `(10, -20, 10)` rounds to `(5, -10, 5)`.
  @Test("The midpoint case of test_hex_round")
  func midpointCaseOfTheReference() {
    let a = FractionalHex(q: 0, r: 0, s: 0)
    let b = FractionalHex(q: 10, r: -20, s: 10)
    #expect(a.lerp(to: b, t: 0.5).rounded() == Hex(q: 5, r: -10))
  }

  /// Reference test `test_hex_round`, cases 2 and 3.
  @Test("Interpolation just below and just above the halfway point")
  func nearHalfwayCasesOfTheReference() {
    let a = FractionalHex(q: 0, r: 0, s: 0)
    let b = FractionalHex(q: 1, r: -1, s: 0)
    #expect(a.lerp(to: b, t: 0.499).rounded() == a.rounded())
    #expect(a.lerp(to: b, t: 0.501).rounded() == b.rounded())
    #expect(a.rounded() == Hex.zero)
    #expect(b.rounded() == Hex(q: 1, r: -1))
  }

  /// Reference test `test_hex_round`, cases 4 and 5: weighted combinations of
  /// three neighbouring cells.
  @Test("Weighted combinations of three cells")
  func weightedCasesOfTheReference() {
    let a = FractionalHex(q: 0, r: 0, s: 0)
    let b = FractionalHex(q: 1, r: -1, s: 0)
    let c = FractionalHex(q: 0, r: -1, s: 1)
    let first = FractionalHex(
      q: a.q * 0.4 + b.q * 0.3 + c.q * 0.3,
      r: a.r * 0.4 + b.r * 0.3 + c.r * 0.3,
      s: a.s * 0.4 + b.s * 0.3 + c.s * 0.3)
    let second = FractionalHex(
      q: a.q * 0.3 + b.q * 0.3 + c.q * 0.4,
      r: a.r * 0.3 + b.r * 0.3 + c.r * 0.4,
      s: a.s * 0.3 + b.s * 0.3 + c.s * 0.4)
    #expect(first.rounded() == a.rounded())
    #expect(second.rounded() == c.rounded())
  }

  // MARK: The rule for halves

  /// doc-008, section 2: the ports of the guide disagree on exact halves.
  /// HexagonKit rounds halves away from zero, which is the C++/Rust column.
  static let halves: [HalfRoundingRow] = [
    HalfRoundingRow(q: 0.5, r: -1.0, s: 0.5, expected: Hex(q: 1, r: -1)),
    HalfRoundingRow(q: -0.5, r: -0.5, s: 1.0, expected: Hex(q: -1, r: 0)),
    HalfRoundingRow(q: -1.5, r: 3.0, s: -1.5, expected: Hex(q: -2, r: 3)),
    HalfRoundingRow(q: 0.0, r: -0.5, s: 0.5, expected: Hex(q: 0, r: -1)),
    HalfRoundingRow(q: 2.5, r: -2.5, s: 0.0, expected: Hex(q: 3, r: -3)),
    HalfRoundingRow(q: -2.5, r: 2.5, s: 0.0, expected: Hex(q: -3, r: 3)),
    HalfRoundingRow(q: 1.5, r: -3.0, s: 1.5, expected: Hex(q: 2, r: -3)),
    HalfRoundingRow(q: 1.5, r: 1.5, s: -3.0, expected: Hex(q: 2, r: 1)),
    HalfRoundingRow(q: 3.5, r: -1.5, s: -2.0, expected: Hex(q: 4, r: -2)),
  ]

  @Test("Exact halves round away from zero", arguments: halves)
  func exactHalvesRoundAwayFromZero(_ row: HalfRoundingRow) {
    #expect(FractionalHex(q: row.q, r: row.r, s: row.s).rounded() == row.expected)
  }

  /// doc-008, section 3: the comparisons are strict, so `s` is recomputed when
  /// the errors of `r` and `s` are equal, and `r` only when its error is
  /// strictly larger than the error of `s`.
  @Test("Ties are resolved towards s, then r")
  func tiesAreResolvedTowardsSThenR() {
    #expect(FractionalHex(q: 0.5, r: 0.5, s: -1.0).rounded() == Hex(q: 1, r: 0))
    #expect(FractionalHex(q: 0.0, r: 0.4, s: -0.4).rounded() == Hex(q: 0, r: 0))
    #expect(FractionalHex(q: 0.3, r: -0.6, s: 0.3).rounded() == Hex(q: 0, r: 0))
    #expect(FractionalHex(q: 0.3, r: -0.7, s: 0.4).rounded() == Hex(q: 0, r: -1))
  }

  // MARK: Fixtures

  @Test("Rounding matches the fixture on interior points")
  func roundingMatchesTheFixtureOnInteriorPoints() throws {
    let fixture = try Fixture.rounding()
    let denominator = Double(fixture.denominator)
    var mismatches: [String] = []
    for row in fixture.interior {
      let fractional = FractionalHex(
        q: Double(row[0]) / denominator, r: Double(row[1]) / denominator)
      let rounded = fractional.rounded()
      if rounded != Hex(q: row[2], r: row[3]) {
        mismatches.append("\(row) -> \(rounded)")
      }
    }
    #expect(fixture.interior.count > 4000)
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Rounding matches the fixture on boundary points")
  func roundingMatchesTheFixtureOnBoundaryPoints() throws {
    let fixture = try Fixture.rounding()
    let denominator = Double(fixture.denominator)
    var mismatches: [String] = []
    for row in fixture.boundary {
      let fractional = FractionalHex(
        q: Double(row[0]) / denominator, r: Double(row[1]) / denominator)
      let rounded = fractional.rounded()
      if rounded != Hex(q: row[2], r: row[3]) {
        mismatches.append("\(row) -> \(rounded)")
      }
    }
    #expect(fixture.boundary.count > 1000)
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Three stored components

  /// The counterexample found in the review of doc-010: with a derived `s` the
  /// interpolation of the line of stage 3 moves one cell away from the
  /// reference. The nudge and the step are those of `hex_linedraw` in `lib.py`:
  /// both ends are shifted by `(+1e-6, +1e-6, -2e-6)` and the parameter is
  /// `(1 / N) * i`, not `i / N`: the two differ in the last bit and only the
  /// first reproduces the reference.
  @Test("The interpolation counterexample of the review")
  func interpolationCounterexample() {
    let a = Hex(q: 173_927, r: 796_971)
    let b = Hex(q: 173_928, r: -1_203_029)
    let steps = 2_000_000
    #expect(a.distance(to: b) == steps)
    let nudgedA = FractionalHex(
      q: Double(a.q) + 1e-6, r: Double(a.r) + 1e-6, s: Double(a.s) - 2e-6)
    let nudgedB = FractionalHex(
      q: Double(b.q) + 1e-6, r: Double(b.r) + 1e-6, s: Double(b.s) - 2e-6)
    let t = (1.0 / Double(steps)) * 999_997.0
    #expect(nudgedA.lerp(to: nudgedB, t: t).rounded() == Hex(q: 173_927, r: -203_026))
  }

  @Test("Interpolation is componentwise and keeps the third component")
  func interpolationIsComponentwise() {
    let a = FractionalHex(q: 1, r: 2, s: 3)
    let b = FractionalHex(q: 3, r: 4, s: 5)
    let middle = a.lerp(to: b, t: 0.5)
    #expect(middle.q == 2)
    #expect(middle.r == 3)
    #expect(middle.s == 4)
  }

  @Test("Interpolation extrapolates outside zero to one")
  func interpolationExtrapolates() {
    let a = FractionalHex(q: 0, r: 0, s: 0)
    let b = FractionalHex(q: 2, r: -2, s: 0)
    let outside = a.lerp(to: b, t: 2.0)
    #expect(outside.q == 4)
    #expect(outside.r == -4)
    #expect(outside.s == 0)
    let before = a.lerp(to: b, t: -1.0)
    #expect(before.q == -2)
    #expect(before.r == 2)
  }

  @Test("The axial initializer derives the third component")
  func axialInitializerDerivesTheThirdComponent() {
    #expect(FractionalHex(q: 1.5, r: -0.25).s == -1.25)
    #expect(FractionalHex(Hex(q: 1, r: -3)).s == 2.0)
    #expect(FractionalHex(Hex(q: 1, r: -3)).q == 1.0)
    #expect(FractionalHex(Hex(q: 1, r: -3)).r == -3.0)
  }

  @Test("The cube initializer stores the triple as given")
  func cubeInitializerStoresTheTripleAsGiven() {
    let inconsistent = FractionalHex(q: 1, r: 1, s: 1)
    #expect(inconsistent.q == 1)
    #expect(inconsistent.r == 1)
    #expect(inconsistent.s == 1)
    #expect(inconsistent.rounded() == Hex(q: 1, r: 1))
  }

  // MARK: Properties

  @Test("An integer hex survives the round trip through the fractional type")
  func integerHexSurvivesTheRoundTrip() {
    var mismatches: [String] = []
    for q in -20...20 {
      for r in -20...20 {
        let hex = Hex(q: q, r: r)
        if FractionalHex(hex).rounded() != hex {
          mismatches.append("\(hex)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Rounding never moves further than one step away")
  func roundingStaysWithinOneStep() {
    var mismatches: [String] = []
    for q in -24...24 {
      for r in -24...24 {
        let fractional = FractionalHex(q: Double(q) / 8.0, r: Double(r) / 8.0)
        let rounded = fractional.rounded()
        let error = max(
          abs(Double(rounded.q) - fractional.q),
          abs(Double(rounded.r) - fractional.r),
          abs(Double(rounded.s) - fractional.s))
        if error > 1.0 {
          mismatches.append("q=\(q) r=\(r) error=\(error)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Equality follows the semantics of Double")
  func equalityFollowsDoubleSemantics() {
    #expect(FractionalHex(q: 0.0, r: -0.0, s: 0.0) == FractionalHex(q: -0.0, r: 0.0, s: 0.0))
    let notANumber = FractionalHex(q: .nan, r: 0, s: 0)
    #expect(notANumber != notANumber)
  }

  // MARK: Regressions of the Objective-C library

  /// ObjectiveHexagon resolved ties on `x` and then `y`, while the guide and
  /// HexagonKit resolve them on `q` and then `r` (doc-002, error 9). The
  /// example from the survey: the old code answered `(-3, 0, 3)`.
  @Test("Ties are resolved the way the guide does, not the way the old library did")
  func tieOrderFollowsTheGuide() {
    #expect(FractionalHex(q: -3.0, r: 0.5, s: 2.5).rounded() == Hex(q: -3, r: 1))
  }

  /// ObjectiveHexagon rounded through `roundf`, so a `double` of `2.49999995`
  /// became exactly `2.5` in single precision and landed in the next cell
  /// (doc-002, error 4).
  @Test("Rounding keeps double precision")
  func roundingKeepsDoublePrecision() {
    #expect(FractionalHex(q: 2.499_999_95, r: -2.499_999_95, s: 0).rounded() == Hex(q: 2, r: -2))
  }

  // MARK: Codable

  @Test("Encoding keeps all three cube components")
  func encodingKeepsAllThreeComponents() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let value = FractionalHex(q: 1, r: -3, s: 2)
    let json = String(decoding: try encoder.encode(value), as: UTF8.self)
    #expect(json == #"{"q":1,"r":-3,"s":2}"#)
    let back = try JSONDecoder().decode(FractionalHex.self, from: Data(json.utf8))
    #expect(back == value)
  }
}
