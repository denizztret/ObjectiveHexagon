import HexagonKit
import Testing

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

  @Test("A parallelogram of 46340 by 46340")
  func largeParallelogram() {
    let side = 46_340
    let origin = Hex(q: -20_000, r: 7)
    checkRows(
      .parallelogram(origin: origin, columns: side, rows: side),
      named: "parallelogram \(side)x\(side)",
      count: side * side,
      rows: HexShapeLargeTests.probeRows(from: 0, to: side - 1),
      firstRow: 0,
      prefix: { $0 * side },
      firstCellOfRow: { origin + Hex(q: 0, r: $0) },
      lastCellOfRow: { origin + Hex(q: side - 1, r: $0) })
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

    /// A parallelogram whose `s` falls by `2^30 - 2` from its first cell to its
    /// last: the largest square one that starts at the origin.
    @Test("A parallelogram near the edge of the coordinate range")
    func parallelogramNearTheEdgeOfTheRange() {
      let side = 1 << 29
      checkRows(
        .parallelogram(columns: side, rows: side),
        named: "parallelogram \(side)x\(side)",
        count: side * side,
        rows: HexShapeLargeTests.probeRows(from: 0, to: side - 1),
        firstRow: 0,
        prefix: { $0 * side },
        firstCellOfRow: { Hex(q: 0, r: $0) },
        lastCellOfRow: { Hex(q: side - 1, r: $0) })
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
    #expect(20_000 + 46_340 < Hex.coordinateBound)
    #expect(2 * ((1 << 29) - 1) < Hex.coordinateBound)
  }
}
