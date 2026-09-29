import Foundation
import HexagonKit
import Testing

@Suite("HexShape.parallelogram")
struct HexShapeParallelogramTests {

  /// `makeRhombusShape(3, 2)` of the guide's diagrams, row by row.
  @Test("A parallelogram is listed row by row, as the guide's rhombus")
  func parallelogramIsListedRowByRow() {
    let expected = [
      Hex(q: 0, r: 0), Hex(q: 1, r: 0), Hex(q: 2, r: 0),
      Hex(q: 0, r: 1), Hex(q: 1, r: 1), Hex(q: 2, r: 1),
    ]
    #expect(HexShape.parallelogram(columns: 3, rows: 2).cells() == expected)
  }

  @Test("An origin shifts every cell of the parallelogram")
  func originShiftsEveryCell() {
    let origin = Hex(q: -7, r: 4)
    #expect(
      HexShape.parallelogram(origin: origin, columns: 4, rows: 3).cells()
        == HexShape.parallelogram(columns: 4, rows: 3).cells().map { $0 + origin })
  }

  @Test("A parallelogram has columns times rows cells")
  func cellCountIsColumnsTimesRows() {
    for columns in 0...6 {
      for rows in 0...6 {
        #expect(HexShape.parallelogram(columns: columns, rows: rows).count == columns * rows)
      }
    }
  }

  @Test("A cell sits at row times columns plus column")
  func cellSitsAtRowTimesColumnsPlusColumn() {
    let origin = Hex(q: 3, r: -9)
    let shape = HexShape.parallelogram(origin: origin, columns: 5, rows: 4)
    for row in 0..<4 {
      for column in 0..<5 {
        let hex = origin + Hex(q: column, r: row)
        #expect(shape.index(of: hex) == row * 5 + column)
        #expect(shape.hex(at: row * 5 + column) == hex)
      }
    }
  }

  @Test("Membership matches the defining inequalities")
  func membershipMatchesTheDefiningInequalities() {
    let origin = Hex(q: -2, r: 1)
    let shape = HexShape.parallelogram(origin: origin, columns: 5, rows: 3)
    var mismatches: [String] = []
    for q in -12...12 {
      for r in -12...12 {
        let hex = Hex(q: q, r: r)
        let column = q - origin.q
        let row = r - origin.r
        if shape.contains(hex) != (0 <= column && column < 5 && 0 <= row && row < 3) {
          mismatches.append("\(hex)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("The sides run along the directions plusQMinusS and plusRMinusS")
  func sidesRunAlongTwoDirections() {
    let shape = HexShape.parallelogram(origin: Hex(q: 1, r: 1), columns: 4, rows: 3)
    for row in 0..<3 {
      for column in 0..<3 {
        let index = row * 4 + column
        #expect(shape.hex(at: index + 1) - shape.hex(at: index) == HexDirection.plusQMinusS.vector)
      }
    }
    #expect(shape.hex(at: 4) - shape.hex(at: 0) == HexDirection.plusRMinusS.vector)
  }

  /// The guide loops over `(q, r)`, `(s, q)` or `(r, s)`; the other two pairs
  /// give the same shape, turned around the origin by 120 and 240 degrees.
  @Test("The other two pairs of axes of the guide are the same shape rotated")
  func otherPairsOfAxesAreTheSameShapeRotated() {
    let cells = HexShape.parallelogram(columns: 3, rows: 2).cells()
    let sq: Set<Hex> = [
      Hex(q: 0, r: 0), Hex(q: 1, r: -1), Hex(q: 0, r: -1),
      Hex(q: 1, r: -2), Hex(q: 0, r: -2), Hex(q: 1, r: -3),
    ]
    let rs: Set<Hex> = [
      Hex(q: 0, r: 0), Hex(q: -1, r: 0), Hex(q: -1, r: 1),
      Hex(q: -2, r: 1), Hex(q: -2, r: 2), Hex(q: -3, r: 2),
    ]
    #expect(Set(cells.map { $0.rotated(by: -2) }) == sq)
    #expect(Set(cells.map { $0.rotated(by: -4) }) == rs)
  }

  /// An empty parallelogram may start anywhere, even where `hex - origin`
  /// would overflow; it has no cells, so every hex gets `nil` at once.
  @Test("An empty parallelogram accepts any origin")
  func emptyParallelogramAcceptsAnyOrigin() throws {
    let shape = HexShape.parallelogram(origin: Hex(q: Int.min, r: 0), columns: 0, rows: 5)
    #expect(shape.count == 0)
    #expect(shape.cells().isEmpty)
    #expect(shape.index(of: .zero) == nil)
    #expect(!shape.contains(Hex(q: 1_073_741_823, r: 0)))
    let back = try JSONDecoder().decode(HexShape.self, from: JSONEncoder().encode(shape))
    #expect(back == shape)
  }

  // MARK: Codable

  @Test("A parallelogram encodes as its kind and its factory parameters")
  func encodingNamesTheKindAndTheParameters() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let json = String(
      decoding: try encoder.encode(
        HexShape.parallelogram(origin: Hex(q: -1, r: 2), columns: 3, rows: 2)),
      as: UTF8.self)
    #expect(json == #"{"columns":3,"kind":"parallelogram","origin":{"q":-1,"r":2},"rows":2}"#)
  }

  @Test("Decoding a parallelogram with a negative side fails")
  func decodingRejectsANegativeSide() {
    let negativeColumns = #"{"columns":-1,"kind":"parallelogram","origin":{"q":0,"r":0},"rows":2}"#
    let negativeRows = #"{"columns":3,"kind":"parallelogram","origin":{"q":0,"r":0},"rows":-2}"#
    for json in [negativeColumns, negativeRows] {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(HexShape.self, from: Data(json.utf8))
      }
    }
  }

  /// `s` falls along both sides: this one reaches `s = -2^30`, one past the
  /// supported range, although `q` and `r` stay inside it.
  @Test("Decoding a parallelogram whose cells leave the supported range fails")
  func decodingRejectsCoordinatesOutOfRange() {
    let farS =
      #"{"columns":536870913,"kind":"parallelogram","origin":{"q":0,"r":0},"rows":536870913}"#
    let farQ = #"{"columns":2,"kind":"parallelogram","origin":{"q":1073741823,"r":0},"rows":1}"#
    let hugeSides =
      #"{"columns":9223372036854775807,"kind":"parallelogram","origin":{"q":0,"r":0},"rows":1}"#
    for json in [farS, farQ, hugeSides] {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(HexShape.self, from: Data(json.utf8))
      }
    }
    // The largest square parallelogram at the origin: its count, 2^58, fits
    // only a 64-bit `Int`.
    #if _pointerBitWidth(_64)
      let largest =
        #"{"columns":536870912,"kind":"parallelogram","origin":{"q":0,"r":0},"rows":536870912}"#
      #expect(throws: Never.self) {
        try JSONDecoder().decode(HexShape.self, from: Data(largest.utf8))
      }
    #endif
  }
}

#if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
  /// Exit tests run the closure in a child process and expect it to stop; they
  /// exist from Swift 6.2 on, so older compilers skip this suite.
  @Suite("HexShape.parallelogram preconditions")
  struct HexShapeParallelogramPreconditionTests {

    @Test("A negative number of columns stops the factory")
    func negativeColumnsStop() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.parallelogram(columns: -1, rows: 2)
      }
    }

    @Test("A parallelogram whose cells leave the supported range stops the factory")
    func cellsBeyondTheRangeStop() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.parallelogram(origin: Hex(q: 1_073_741_823, r: 0), columns: 2, rows: 1)
      }
    }
  }
#endif
