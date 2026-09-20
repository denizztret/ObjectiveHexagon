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

/// `n * (n + 1) / 2`, with the even factor halved before the multiplication, so
/// that no intermediate value overflows `Int` on a 32-bit platform.
func triangularNumber(_ n: Int) -> Int {
  n % 2 == 0 ? (n / 2) * (n + 1) : n * ((n + 1) / 2)
}

@Suite("HexShape at the far end of large shapes")
struct HexShapeLargeTests {

  /// The first row, the second, the middle one, the one before last and the last.
  static func probeRows(from first: Int, to last: Int) -> [Int] {
    [first, first + 1, (first + last) / 2, last - 1, last]
  }

  /// Checks the index arithmetic of a shape without ever calling `cells()`: for
  /// a handful of rows it compares the index of the first cell of the row, the
  /// cell at that index, and the last cell of the previous row, which sits one
  /// index to the left. The expected indices are computed here from the row
  /// lengths, so nothing but `count` is taken from the shape itself.
  func checkRows(
    _ shape: HexShape,
    named name: String,
    count: Int,
    rows: [Int],
    firstRow: Int,
    prefix: (Int) -> Int,
    firstCellOfRow: (Int) -> Hex,
    lastCellOfRow: (Int) -> Hex
  ) {
    var mismatches: [String] = []
    if shape.count != count {
      mismatches.append("\(name): count is \(shape.count), expected \(count)")
    }
    for row in rows {
      let index = prefix(row)
      let cell = firstCellOfRow(row)
      if shape.hex(at: index) != cell {
        mismatches.append("\(name) row \(row): hex(at: \(index)) is \(shape.hex(at: index))")
      }
      if shape.index(of: cell) != index {
        let found = String(describing: shape.index(of: cell))
        mismatches.append("\(name) row \(row): index(of: \(cell)) is \(found)")
      }
      if row > firstRow {
        let previous = lastCellOfRow(row - 1)
        if shape.hex(at: index - 1) != previous {
          mismatches.append(
            "\(name) row \(row): hex(at: \(index - 1)) is \(shape.hex(at: index - 1))")
        }
        if shape.index(of: previous) != index - 1 {
          mismatches.append("\(name) row \(row): index of the last cell of the previous row")
        }
      }
    }
    let last = shape.hex(at: count - 1)
    if shape.index(of: last) != count - 1 {
      mismatches.append("\(name): index(of: hex(at: count - 1)) is not count - 1")
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Shapes whose cell count still fits a 32-bit Int

  @Test("A triangle with a corner at the bottom of size 65534")
  func largeTriangleDown() {
    let size = 65_534
    let count = triangularNumber(size + 1)
    checkRows(
      .triangleDown(size: size),
      named: "triangleDown(\(size))",
      count: count,
      rows: HexShapeLargeTests.probeRows(from: 0, to: size),
      firstRow: 0,
      prefix: { count - triangularNumber(size + 1 - $0) },
      firstCellOfRow: { Hex(q: 0, r: $0) },
      lastCellOfRow: { Hex(q: size - $0, r: $0) })
  }

  @Test("A triangle with a corner at the top of size 65534")
  func largeTriangleUp() {
    let size = 65_534
    let count = triangularNumber(size + 1)
    checkRows(
      .triangleUp(size: size),
      named: "triangleUp(\(size))",
      count: count,
      rows: HexShapeLargeTests.probeRows(from: 0, to: size),
      firstRow: 0,
      prefix: { triangularNumber($0) },
      firstCellOfRow: { Hex(q: size - $0, r: $0) },
      lastCellOfRow: { Hex(q: size, r: $0) })
  }

  @Test("A hexagon of radius 26754")
  func largeHexagon() {
    let radius = 26_754
    let count = 1 + 3 * radius * (radius + 1)
    func prefix(_ row: Int) -> Int {
      let i = row + radius
      if i <= radius {
        return i * (radius + 1) + triangularNumber(i - 1)
      }
      let m = 2 * radius + 1 - i
      return count - (m * (radius + 1) + triangularNumber(m - 1))
    }
    checkRows(
      .hexagon(radius: radius),
      named: "hexagon(\(radius))",
      count: count,
      rows: HexShapeLargeTests.probeRows(from: -radius, to: radius),
      firstRow: -radius,
      prefix: prefix,
      firstCellOfRow: { Hex(q: max(-radius, -$0 - radius), r: $0) },
      lastCellOfRow: { Hex(q: min(radius, -$0 + radius), r: $0) })
  }

  @Test("A rectangle of 46340 by 46340")
  func largeRectangle() {
    let side = 46_340
    checkRows(
      .rectangle(columns: side, rows: side, in: .oddR),
      named: "rectangle \(side)x\(side)",
      count: side * side,
      rows: HexShapeLargeTests.probeRows(from: 0, to: side - 1),
      firstRow: 0,
      prefix: { $0 * side },
      firstCellOfRow: { Hex(OffsetCoordinate(column: 0, row: $0), in: .oddR) },
      lastCellOfRow: { Hex(OffsetCoordinate(column: side - 1, row: $0), in: .oddR) })
  }

  // MARK: Shapes near the edge of the supported coordinate range

  #if _pointerBitWidth(_64)
    /// These only exist on a 64-bit platform: their cell counts run into the
    /// hundreds of quadrillions, so the test is compiled for 64-bit targets only
    /// (on a 32-bit target the constants below do not even compile). The sizes
    /// are the largest round numbers whose cells still stay inside the supported
    /// coordinate range: a triangle with a corner at the top reaches
    /// `|s| = 2 * size`, so its size is half the one of the triangle with a
    /// corner at the bottom.
    @Test("Triangles and a hexagon near the edge of the coordinate range")
    func shapesNearTheEdgeOfTheRange() {
      let downSize = 1_000_000_000
      let downCount = triangularNumber(downSize + 1)
      checkRows(
        .triangleDown(size: downSize),
        named: "triangleDown(\(downSize))",
        count: downCount,
        rows: HexShapeLargeTests.probeRows(from: 0, to: downSize),
        firstRow: 0,
        prefix: { downCount - triangularNumber(downSize + 1 - $0) },
        firstCellOfRow: { Hex(q: 0, r: $0) },
        lastCellOfRow: { Hex(q: downSize - $0, r: $0) })

      let upSize = 500_000_000
      let upCount = triangularNumber(upSize + 1)
      checkRows(
        .triangleUp(size: upSize),
        named: "triangleUp(\(upSize))",
        count: upCount,
        rows: HexShapeLargeTests.probeRows(from: 0, to: upSize),
        firstRow: 0,
        prefix: { triangularNumber($0) },
        firstCellOfRow: { Hex(q: upSize - $0, r: $0) },
        lastCellOfRow: { Hex(q: upSize, r: $0) })

      let radius = 500_000_000
      let hexagonCount = 1 + 3 * radius * (radius + 1)
      func prefix(_ row: Int) -> Int {
        let i = row + radius
        if i <= radius {
          return i * (radius + 1) + triangularNumber(i - 1)
        }
        let m = 2 * radius + 1 - i
        return hexagonCount - (m * (radius + 1) + triangularNumber(m - 1))
      }
      checkRows(
        .hexagon(radius: radius),
        named: "hexagon(\(radius))",
        count: hexagonCount,
        rows: HexShapeLargeTests.probeRows(from: -radius, to: radius),
        firstRow: -radius,
        prefix: prefix,
        firstCellOfRow: { Hex(q: max(-radius, -$0 - radius), r: $0) },
        lastCellOfRow: { Hex(q: min(radius, -$0 + radius), r: $0) })
    }
  #endif

  /// Every cell of the shapes above stays inside the guaranteed coordinate
  /// range, so the factories accept them.
  @Test("The large shapes stay inside the supported coordinate range")
  func largeShapesStayInsideTheRange() {
    #expect(65_534 < Hex.coordinateBound)
    #expect(2 * 65_534 < Hex.coordinateBound)
    #expect(26_754 < Hex.coordinateBound)
    #expect(46_340 < Hex.coordinateBound)
    #expect(1_000_000_000 < Hex.coordinateBound)
    #expect(2 * 500_000_000 < Hex.coordinateBound)
    #expect(500_000_000 < Hex.coordinateBound)
  }
}
