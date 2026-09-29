import Foundation
import Testing

@testable import HexagonKit

/// One line with the hexes it must pass through.
struct LineRow: Sendable, CustomStringConvertible {
  let from: Hex
  let to: Hex
  let expected: [Hex]

  var description: String { "\(from) -> \(to)" }
}

@Suite("Hex.line")
struct LineTests {

  // MARK: Reference values

  /// Reference test `test_hex_linedraw` of `lib.py`. It passes with the nudge of
  /// `lib.py` and with the nudge of the guide's text alike.
  @Test("The line matches test_hex_linedraw")
  func lineMatchesTheReference() {
    let expected = [
      Hex(q: 0, r: 0), Hex(q: 0, r: -1), Hex(q: 0, r: -2),
      Hex(q: 1, r: -3), Hex(q: 1, r: -4), Hex(q: 1, r: -5),
    ]
    #expect(Hex.zero.line(to: Hex(q: 1, r: -5)) == expected)
  }

  /// Lines computed by the model of the guide's line with the nudge of its text,
  /// `(1e-6, 2e-6, -3e-6)`, in the order of operations of the implementation
  /// page. The lines along an edge between two hexes differ from `lib.py`.
  static let table: [LineRow] = [
    LineRow(from: .zero, to: Hex(q: 1, r: 0), expected: [.zero, Hex(q: 1, r: 0)]),
    LineRow(
      from: .zero, to: Hex(q: 2, r: -1),
      expected: [.zero, Hex(q: 1, r: 0), Hex(q: 2, r: -1)]),
    LineRow(
      from: .zero, to: Hex(q: 1, r: 1),
      expected: [.zero, Hex(q: 0, r: 1), Hex(q: 1, r: 1)]),
    LineRow(
      from: .zero, to: Hex(q: -1, r: 2),
      expected: [.zero, Hex(q: 0, r: 1), Hex(q: -1, r: 2)]),
    LineRow(
      from: .zero, to: Hex(q: 2, r: 2),
      expected: [.zero, Hex(q: 0, r: 1), Hex(q: 1, r: 1), Hex(q: 1, r: 2), Hex(q: 2, r: 2)]),
    LineRow(
      from: Hex(q: 1, r: 1), to: Hex(q: -1, r: -1),
      expected: [
        Hex(q: 1, r: 1), Hex(q: 0, r: 1), .zero, Hex(q: -1, r: 0), Hex(q: -1, r: -1),
      ]),
    LineRow(
      from: .zero, to: Hex(q: 4, r: -2),
      expected: [.zero, Hex(q: 1, r: 0), Hex(q: 2, r: -1), Hex(q: 3, r: -1), Hex(q: 4, r: -2)]),
    LineRow(
      from: Hex(q: -5, r: 0), to: Hex(q: 5, r: -5),
      expected: [
        Hex(q: -5, r: 0), Hex(q: -4, r: 0), Hex(q: -3, r: -1), Hex(q: -2, r: -1),
        Hex(q: -1, r: -2), Hex(q: 0, r: -2), Hex(q: 1, r: -3), Hex(q: 2, r: -3),
        Hex(q: 3, r: -4), Hex(q: 4, r: -4), Hex(q: 5, r: -5),
      ]),
    LineRow(
      from: Hex(q: -6, r: 0), to: Hex(q: -1, r: 5),
      expected: [
        Hex(q: -6, r: 0), Hex(q: -6, r: 1), Hex(q: -5, r: 1), Hex(q: -5, r: 2),
        Hex(q: -4, r: 2), Hex(q: -4, r: 3), Hex(q: -3, r: 3), Hex(q: -3, r: 4),
        Hex(q: -2, r: 4), Hex(q: -2, r: 5), Hex(q: -1, r: 5),
      ]),
    LineRow(
      from: .zero, to: Hex(q: 3, r: 0),
      expected: [.zero, Hex(q: 1, r: 0), Hex(q: 2, r: 0), Hex(q: 3, r: 0)]),
  ]

  @Test("Lines match the model of the guide", arguments: table)
  func lineMatchesTheModel(_ row: LineRow) {
    #expect(row.from.line(to: row.to) == row.expected)
  }

  /// Deviation 9 of `Conformance.md`: along the edge between `(1, 0)` and
  /// `(0, 1)` the nudge of `lib.py` goes through `(1, 0)` and the nudge of the
  /// guide's text, which HexagonKit follows, through `(0, 1)`.
  @Test("The line follows the nudge of the guide's text, not that of lib.py")
  func lineFollowsTheNudgeOfTheText() {
    #expect(Hex.zero.line(to: Hex(q: 1, r: 1))[1] == Hex(q: 0, r: 1))
  }

  // MARK: Contract

  @Test("A line from a hex to itself is that hex alone")
  func lineToItselfIsTheHexAlone() {
    #expect(Hex.zero.line(to: .zero) == [.zero])
    #expect(Hex(q: 3, r: -1).line(to: Hex(q: 3, r: -1)) == [Hex(q: 3, r: -1)])
  }

  @Test("A line to a neighbor is the two hexes")
  func lineToANeighborIsTheTwoHexes() {
    let center = Hex(q: -2, r: 7)
    for neighbor in center.neighbors {
      #expect(center.line(to: neighbor) == [center, neighbor])
    }
  }

  @Test("A line has distance plus one hexes and runs from end to end")
  func lineRunsFromEndToEnd() {
    let starts = [Hex.zero, Hex(q: 7, r: -3), Hex(q: -40, r: 25)]
    var mismatches: [String] = []
    for start in starts {
      for offset in HexShape.hexagon(radius: 9).cells() {
        let end = start + offset * 3
        let line = start.line(to: end)
        if line.count != start.distance(to: end) + 1 {
          mismatches.append("count \(start) -> \(end)")
        }
        if line.first != start || line.last != end {
          mismatches.append("ends \(start) -> \(end)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// doc-016, section 3.3: the ends are exact for any two hexes of the supported
  /// range. The samples are taken one by one, so no long line is built.
  @Test("The ends of lines between the corners of the coordinate range are exact")
  func endsAreExactAtTheCornersOfTheRange() {
    let bound = Hex.coordinateBound - 1
    let corners = [
      Hex(q: bound, r: 0), Hex(q: 0, r: bound), Hex(q: -bound, r: bound),
      Hex(q: -bound, r: 0), Hex(q: 0, r: -bound), Hex(q: bound, r: -bound),
      Hex(q: 1, r: -2), Hex(q: bound - 7, r: -3),
    ]
    var mismatches: [String] = []
    for start in corners {
      for end in corners {
        let samples = LineSamples(from: start, to: end)
        if samples.distance != start.distance(to: end) {
          mismatches.append("distance \(start) -> \(end)")
        }
        if samples.hex(at: 0) != start || samples.hex(at: samples.distance) != end {
          mismatches.append("ends \(start) -> \(end)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Fixture

  /// Every line of the hexagon of radius 6 that the nudge of `lib.py` would
  /// draw differently; the generator draws them in the order of operations of
  /// the reference with the nudge of the guide's text.
  @Test("Lines where the two nudges disagree match the fixture")
  func linesMatchTheFixture() throws {
    let fixture = try Fixture.lines()
    var mismatches: [String] = []
    for row in fixture.lines {
      let from = Hex(q: row[0], r: row[1])
      let to = Hex(q: row[2], r: row[3])
      let expected = stride(from: 4, to: row.count, by: 2).map { Hex(q: row[$0], r: row[$0 + 1]) }
      if from.line(to: to) != expected {
        mismatches.append("\(from) -> \(to)")
      }
    }
    #expect(fixture.lines.count == 1447)
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// Samples of lines millions of steps long, anywhere in the supported range.
  /// Most of them sit where the last bits of the arithmetic decide the hex: an
  /// implementation that computes `t` as `i / N`, interpolates as
  /// `a + (b - a) * t`, derives `s`, or nudges after the interpolation fails here.
  @Test("Samples of long lines match the fixture bit for bit")
  func samplesMatchTheFixture() throws {
    let fixture = try Fixture.lines()
    var mismatches: [String] = []
    for row in fixture.samples {
      let samples = LineSamples(from: Hex(q: row[0], r: row[1]), to: Hex(q: row[2], r: row[3]))
      let hex = samples.hex(at: row[4])
      if hex != Hex(q: row[5], r: row[6]) {
        mismatches.append("\(row) -> \(hex)")
      }
    }
    #expect(fixture.samples.count == 500)
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Regressions, not promises

  /// Adjacency and symmetry are not part of the contract (doc-016, section 3.3),
  /// but they hold on every short line checked; this pins that down on all
  /// 47089 ordered pairs of the hexagon of radius 8.
  @Test("Short lines are connected and do not depend on their direction")
  func shortLinesAreConnectedAndSymmetric() {
    let cells = HexShape.hexagon(radius: 8).cells()
    var mismatches: [String] = []
    for start in cells {
      for end in cells {
        let line = start.line(to: end)
        if zip(line, line.dropFirst()).contains(where: { $0.distance(to: $1) != 1 }) {
          mismatches.append("gap \(start) -> \(end)")
        }
        if end.line(to: start) != line.reversed() {
          mismatches.append("asymmetry \(start) -> \(end)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// The counterexample of the second review of doc-016: on the line from the
  /// origin to `(1_000_000_000, -1)` two consecutive hexes are two steps apart,
  /// which is why the documentation does not promise adjacency.
  @Test("Consecutive hexes of a very long line can be two steps apart")
  func consecutiveHexesOfAVeryLongLineCanBeApart() {
    let samples = LineSamples(from: .zero, to: Hex(q: 1_000_000_000, r: -1))
    let first = samples.hex(at: 500_002_477)
    let second = samples.hex(at: 500_002_478)
    #expect(first == Hex(q: 500_002_477, r: -1))
    #expect(second == Hex(q: 500_002_478, r: 0))
    #expect(first.distance(to: second) == 2)
  }

  /// The counterexample of the review of doc-010, drawn with the nudge of the
  /// guide's text: this sample lands one hex away from the one `lib.py` draws,
  /// `(173927, -203026)`, which `FractionalHexTests.interpolationCounterexample`
  /// checks with the nudge of `lib.py`.
  @Test("The line of the doc-010 counterexample follows the nudge of the text")
  func lineOfTheInterpolationCounterexample() {
    let samples = LineSamples(
      from: Hex(q: 173_927, r: 796_971), to: Hex(q: 173_928, r: -1_203_029))
    #expect(samples.distance == 2_000_000)
    #expect(samples.hex(at: 999_997) == Hex(q: 173_928, r: -203_026))
  }
}
