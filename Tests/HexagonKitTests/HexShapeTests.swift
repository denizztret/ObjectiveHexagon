import Foundation
import HexagonKit
import Testing

/// A named shape, so a failure says which one broke.
struct NamedShape: Sendable, CustomStringConvertible {
  let name: String
  let shape: HexShape

  var description: String { name }
}

@Suite("HexShape")
struct HexShapeTests {

  /// Every shape of stage 2, including negative origins and all four offset
  /// systems of the rectangle.
  static let shapes: [NamedShape] = [
    NamedShape(name: "hexagon 0", shape: .hexagon(radius: 0)),
    NamedShape(name: "hexagon 3", shape: .hexagon(radius: 3)),
    NamedShape(
      name: "hexagon 4 off center", shape: .hexagon(center: Hex(q: -7, r: 11), radius: 4)),
    NamedShape(name: "triangleDown 0", shape: .triangleDown(size: 0)),
    NamedShape(name: "triangleDown 4", shape: .triangleDown(size: 4)),
    NamedShape(
      name: "triangleDown 3 shifted", shape: .triangleDown(origin: Hex(q: -5, r: -6), size: 3)),
    NamedShape(name: "triangleUp 0", shape: .triangleUp(size: 0)),
    NamedShape(name: "triangleUp 4", shape: .triangleUp(size: 4)),
    NamedShape(
      name: "triangleUp 3 shifted", shape: .triangleUp(origin: Hex(q: -5, r: -6), size: 3)),
    NamedShape(name: "rectangle oddR", shape: .rectangle(columns: 5, rows: 4, in: .oddR)),
    NamedShape(name: "rectangle evenR", shape: .rectangle(columns: 5, rows: 4, in: .evenR)),
    NamedShape(name: "rectangle oddQ", shape: .rectangle(columns: 5, rows: 4, in: .oddQ)),
    NamedShape(name: "rectangle evenQ", shape: .rectangle(columns: 5, rows: 4, in: .evenQ)),
    NamedShape(
      name: "rectangle oddR negative origin",
      shape: .rectangle(
        origin: OffsetCoordinate(column: -4, row: -3), columns: 5, rows: 4, in: .oddR)),
    NamedShape(
      name: "rectangle evenQ negative origin",
      shape: .rectangle(
        origin: OffsetCoordinate(column: -4, row: -3), columns: 5, rows: 4, in: .evenQ)),
    NamedShape(name: "rectangle empty", shape: .rectangle(columns: 0, rows: 4, in: .oddR)),
  ]

  // MARK: Cell order

  @Test("A hexagon of radius one is listed row by row")
  func hexagonOfRadiusOneIsListedRowByRow() {
    let expected = [
      Hex(q: 0, r: -1), Hex(q: 1, r: -1),
      Hex(q: -1, r: 0), Hex(q: 0, r: 0), Hex(q: 1, r: 0),
      Hex(q: -1, r: 1), Hex(q: 0, r: 1),
    ]
    #expect(HexShape.hexagon(radius: 1).cells() == expected)
  }

  @Test("A hexagon of radius two is listed row by row")
  func hexagonOfRadiusTwoIsListedRowByRow() {
    let expected = [
      Hex(q: 0, r: -2), Hex(q: 1, r: -2), Hex(q: 2, r: -2),
      Hex(q: -1, r: -1), Hex(q: 0, r: -1), Hex(q: 1, r: -1), Hex(q: 2, r: -1),
      Hex(q: -2, r: 0), Hex(q: -1, r: 0), Hex(q: 0, r: 0), Hex(q: 1, r: 0), Hex(q: 2, r: 0),
      Hex(q: -2, r: 1), Hex(q: -1, r: 1), Hex(q: 0, r: 1), Hex(q: 1, r: 1),
      Hex(q: -2, r: 2), Hex(q: -1, r: 2), Hex(q: 0, r: 2),
    ]
    #expect(HexShape.hexagon(radius: 2).cells() == expected)
  }

  @Test("A triangle with a corner at the bottom is listed row by row")
  func triangleDownIsListedRowByRow() {
    let expected = [
      Hex(q: 0, r: 0), Hex(q: 1, r: 0), Hex(q: 2, r: 0),
      Hex(q: 0, r: 1), Hex(q: 1, r: 1),
      Hex(q: 0, r: 2),
    ]
    #expect(HexShape.triangleDown(size: 2).cells() == expected)
  }

  @Test("A triangle with a corner at the top is listed row by row")
  func triangleUpIsListedRowByRow() {
    let expected = [
      Hex(q: 2, r: 0),
      Hex(q: 1, r: 1), Hex(q: 2, r: 1),
      Hex(q: 0, r: 2), Hex(q: 1, r: 2), Hex(q: 2, r: 2),
    ]
    #expect(HexShape.triangleUp(size: 2).cells() == expected)
  }

  @Test("A rectangle is listed row by row in its offset system")
  func rectangleIsListedRowByRow() {
    let shape = HexShape.rectangle(columns: 3, rows: 2, in: .oddR)
    let expected = [
      Hex(OffsetCoordinate(column: 0, row: 0), in: .oddR),
      Hex(OffsetCoordinate(column: 1, row: 0), in: .oddR),
      Hex(OffsetCoordinate(column: 2, row: 0), in: .oddR),
      Hex(OffsetCoordinate(column: 0, row: 1), in: .oddR),
      Hex(OffsetCoordinate(column: 1, row: 1), in: .oddR),
      Hex(OffsetCoordinate(column: 2, row: 1), in: .oddR),
    ]
    #expect(shape.cells() == expected)
  }

  @Test("An origin shifts every cell of the shape")
  func originShiftsEveryCell() {
    let origin = Hex(q: -5, r: -6)
    let shifted = HexShape.triangleDown(origin: origin, size: 3).cells()
    let base = HexShape.triangleDown(size: 3).cells()
    #expect(shifted == base.map { $0 + origin })
    let center = Hex(q: 4, r: -9)
    #expect(
      HexShape.hexagon(center: center, radius: 2).cells()
        == HexShape.hexagon(radius: 2).cells().map { $0 + center })
  }

  // MARK: Counts

  @Test("Cell counts match the formulas of the guide")
  func cellCountsMatchTheFormulas() {
    var mismatches: [String] = []
    for radius in 0...8 {
      if HexShape.hexagon(radius: radius).count != 1 + 3 * radius * (radius + 1) {
        mismatches.append("hexagon \(radius)")
      }
    }
    for size in 0...8 {
      let expected = (size + 1) * (size + 2) / 2
      if HexShape.triangleDown(size: size).count != expected {
        mismatches.append("triangleDown \(size)")
      }
      if HexShape.triangleUp(size: size).count != expected {
        mismatches.append("triangleUp \(size)")
      }
    }
    for columns in 0...6 {
      for rows in 0...6 {
        let shape = HexShape.rectangle(columns: columns, rows: rows, in: .evenQ)
        if shape.count != columns * rows {
          mismatches.append("rectangle \(columns)x\(rows)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Degenerate shapes are allowed")
  func degenerateShapesAreAllowed() {
    #expect(HexShape.hexagon(radius: 0).cells() == [Hex.zero])
    #expect(HexShape.triangleDown(size: 0).cells() == [Hex.zero])
    #expect(HexShape.triangleUp(size: 0).cells() == [Hex.zero])
    #expect(HexShape.rectangle(columns: 0, rows: 4, in: .oddR).count == 0)
    #expect(HexShape.rectangle(columns: 0, rows: 4, in: .oddR).cells().isEmpty)
    #expect(HexShape.rectangle(columns: 4, rows: 0, in: .oddR).count == 0)
  }

  /// An empty rectangle may be arbitrarily long on its other side; listing its
  /// cells must not walk the rows.
  @Test("An empty rectangle lists no cells without walking its rows")
  func emptyRectangleListsNoCellsAtOnce() {
    #expect(HexShape.rectangle(columns: 0, rows: Int.max, in: .oddR).cells().isEmpty)
    #expect(HexShape.rectangle(columns: Int.max, rows: 0, in: .evenQ).cells().isEmpty)
  }

  // MARK: Indexing

  @Test("A cell and its index convert to each other", arguments: shapes)
  func cellAndIndexAreMutuallyInverse(_ named: NamedShape) {
    let shape = named.shape
    let cells = shape.cells()
    var mismatches: [String] = []
    if cells.count != shape.count {
      mismatches.append("cells().count != count")
    }
    if Set(cells).count != cells.count {
      mismatches.append("duplicate cells")
    }
    for index in 0..<shape.count {
      let hex = shape.hex(at: index)
      if cells[index] != hex {
        mismatches.append("cells()[\(index)] != hex(at:)")
      }
      let found = shape.index(of: hex)
      if found != index {
        mismatches.append("index(of:) of cell \(index) is \(String(describing: found))")
      }
      if shape.contains(hex) == false {
        mismatches.append("contains() of cell \(index)")
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Cells outside the shape have no index", arguments: shapes)
  func cellsOutsideTheShapeHaveNoIndex(_ named: NamedShape) {
    let shape = named.shape
    let cells = Set(shape.cells())
    var mismatches: [String] = []
    for q in -14...14 {
      for r in -14...14 {
        let hex = Hex(q: q, r: r)
        let inside = cells.contains(hex)
        if shape.contains(hex) != inside {
          mismatches.append("contains \(hex)")
        }
        if (shape.index(of: hex) != nil) != inside {
          mismatches.append("index \(hex)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// ObjectiveHexagon generated the same sets of cells as the guide
  /// (doc-002, section 2), but built them by looping; the closed-form index has
  /// to produce the very same sets. The old library is gone from the working
  /// tree, so the independent criterion is a brute-force scan of the defining
  /// inequalities of the guide.
  @Test("Shape membership matches the defining inequalities of the guide")
  func membershipMatchesTheDefiningInequalities() {
    let radius = 4
    let hexagon = HexShape.hexagon(radius: radius)
    let triangleDown = HexShape.triangleDown(size: radius)
    let triangleUp = HexShape.triangleUp(size: radius)
    let rectangle = HexShape.rectangle(columns: 5, rows: 4, in: .oddR)
    var mismatches: [String] = []
    for q in -12...12 {
      for r in -12...12 {
        let hex = Hex(q: q, r: r)
        if hexagon.contains(hex) != (hex.length <= radius) {
          mismatches.append("hexagon \(hex)")
        }
        if triangleDown.contains(hex) != (q >= 0 && r >= 0 && q + r <= radius) {
          mismatches.append("triangleDown \(hex)")
        }
        if triangleUp.contains(hex) != (r >= 0 && r <= radius && q >= radius - r && q <= radius) {
          mismatches.append("triangleUp \(hex)")
        }
        let offset = OffsetCoordinate(hex, in: .oddR)
        let insideRectangle =
          offset.column >= 0 && offset.column < 5 && offset.row >= 0 && offset.row < 4
        if rectangle.contains(hex) != insideRectangle {
          mismatches.append("rectangle \(hex)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Codable

  @Test("Every kind encodes as its name and its factory parameters")
  func encodingNamesTheKindAndTheParameters() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    func json(_ shape: HexShape) throws -> String {
      String(decoding: try encoder.encode(shape), as: UTF8.self)
    }
    #expect(
      try json(.hexagon(center: Hex(q: 1, r: -2), radius: 2))
        == #"{"center":{"q":1,"r":-2},"kind":"hexagon","radius":2}"#)
    #expect(
      try json(.triangleDown(size: 3))
        == #"{"kind":"triangleDown","origin":{"q":0,"r":0},"size":3}"#)
    #expect(
      try json(.triangleUp(origin: Hex(q: -1, r: 4), size: 3))
        == #"{"kind":"triangleUp","origin":{"q":-1,"r":4},"size":3}"#)
    #expect(
      try json(.rectangle(columns: 3, rows: 2, in: .oddR))
        == #"{"columns":3,"kind":"rectangle","origin":{"column":0,"row":0},"rows":2,"system":"oddR"}"#
    )
  }

  @Test("Every shape survives a round trip through JSON", arguments: shapes)
  func shapeSurvivesARoundTrip(_ named: NamedShape) throws {
    let data = try JSONEncoder().encode(named.shape)
    let back = try JSONDecoder().decode(HexShape.self, from: data)
    #expect(back == named.shape)
    #expect(back.cells() == named.shape.cells())
  }

  @Test("Decoding an unknown kind fails")
  func decodingRejectsAnUnknownKind() {
    let json = #"{"kind":"rhombus","origin":{"q":0,"r":0},"size":3}"#
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(HexShape.self, from: Data(json.utf8))
    }
  }

  @Test("Decoding a negative parameter fails")
  func decodingRejectsANegativeParameter() {
    let negativeRadius = #"{"center":{"q":0,"r":0},"kind":"hexagon","radius":-1}"#
    let negativeSize = #"{"kind":"triangleDown","origin":{"q":0,"r":0},"size":-2}"#
    let negativeColumns =
      #"{"columns":-1,"kind":"rectangle","origin":{"column":0,"row":0},"rows":2,"system":"oddR"}"#
    for json in [negativeRadius, negativeSize, negativeColumns] {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(HexShape.self, from: Data(json.utf8))
      }
    }
  }

  @Test("Decoding a shape whose cells leave the supported range fails")
  func decodingRejectsCoordinatesOutOfRange() {
    let hugeHexagon = #"{"center":{"q":0,"r":0},"kind":"hexagon","radius":2000000000}"#
    let hugeRectangle =
      #"""
      {"columns":2000000000,"kind":"rectangle","origin":{"column":0,"row":0},"rows":2000000000,"system":"oddR"}
      """#
    for json in [hugeHexagon, hugeRectangle] {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(HexShape.self, from: Data(json.utf8))
      }
    }
  }

  /// The cell count of a hexagon of radius 30000 is 2 700 090 001, which does
  /// not fit a 32-bit `Int`; on a 64-bit platform the same shape is valid. The
  /// branch is chosen at compile time: a run-time check would not help, because
  /// the compiler rejects the overflowing constant even in a branch that never
  /// runs on a 32-bit platform.
  @Test("A cell count that does not fit Int is rejected")
  func decodingRejectsAnUnrepresentableCellCount() throws {
    let json = #"{"center":{"q":0,"r":0},"kind":"hexagon","radius":30000}"#
    #if _pointerBitWidth(_64)
      let shape = try JSONDecoder().decode(HexShape.self, from: Data(json.utf8))
      #expect(shape.count == 1 + 3 * 30000 * 30001)
    #else
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(HexShape.self, from: Data(json.utf8))
      }
    #endif
  }
}

#if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
  /// Exit tests run the closure in a child process and expect it to stop; they
  /// exist from Swift 6.2 on, so older compilers skip this suite. The largest
  /// sizes break the cell count; the others break a sign or the coordinates.
  @Suite("HexShape preconditions")
  struct HexShapePreconditionTests {

    @Test("A negative radius stops the hexagon")
    func negativeRadiusStopsTheHexagon() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.hexagon(radius: -1)
      }
    }

    @Test("A hexagon whose cell count does not fit Int stops")
    func hexagonCountBeyondIntStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.hexagon(radius: Int.max)
      }
    }

    @Test("A hexagon whose cells leave the supported range stops")
    func hexagonBeyondTheRangeStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.hexagon(center: Hex(q: 1_073_741_823, r: 0), radius: 1)
      }
    }

    @Test("A negative size stops the triangle with a corner at the bottom")
    func negativeSizeStopsTriangleDown() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.triangleDown(size: -1)
      }
    }

    @Test("A triangle with a corner at the bottom whose cell count does not fit Int stops")
    func triangleDownCountBeyondIntStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.triangleDown(size: Int.max)
      }
    }

    @Test("A triangle with a corner at the bottom beyond the supported range stops")
    func triangleDownBeyondTheRangeStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.triangleDown(origin: Hex(q: 1_073_741_823, r: 0), size: 1)
      }
    }

    @Test("A negative size stops the triangle with a corner at the top")
    func negativeSizeStopsTriangleUp() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.triangleUp(size: -1)
      }
    }

    @Test("A triangle with a corner at the top whose cell count does not fit Int stops")
    func triangleUpCountBeyondIntStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.triangleUp(size: Int.max)
      }
    }

    /// Its far corner has `s = -2 * size`, beyond the range, while `q` and `r`
    /// stay inside it.
    @Test("A triangle with a corner at the top beyond the supported range stops")
    func triangleUpBeyondTheRangeStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.triangleUp(size: 600_000_000)
      }
    }

    @Test("A negative number of columns stops the rectangle")
    func negativeColumnsStopTheRectangle() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.rectangle(columns: -1, rows: 2, in: .oddR)
      }
    }

    @Test("A negative number of rows stops the rectangle")
    func negativeRowsStopTheRectangle() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.rectangle(columns: 2, rows: -1, in: .evenQ)
      }
    }

    @Test("A rectangle whose cell count does not fit Int stops")
    func rectangleCountBeyondIntStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.rectangle(columns: Int.max, rows: 2, in: .oddR)
      }
    }

    @Test("A rectangle whose cells leave the supported range stops")
    func rectangleBeyondTheRangeStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.rectangle(columns: 2_000_000_000, rows: 1, in: .evenR)
      }
    }

    @Test("A negative cell index stops")
    func negativeCellIndexStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.hexagon(radius: 2).hex(at: -1)
      }
    }

    @Test("A cell index equal to the count stops")
    func cellIndexEqualToTheCountStops() async {
      await #expect(processExitsWith: .failure) {
        _ = HexShape.hexagon(radius: 2).hex(at: 19)
      }
    }
  }
#endif
