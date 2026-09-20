extension HexShape {

  /// Returns whether a single cube coordinate is inside the supported range.
  static func isRepresentable(_ coordinate: Int) -> Bool {
    -Hex.coordinateBound < coordinate && coordinate < Hex.coordinateBound
  }

  /// Returns whether all three cube coordinates of a hex are inside the range.
  ///
  /// The derived coordinate is read last on purpose: `s` only fits `Int` once
  /// `q` and `r` are known to be small.
  static func isRepresentable(_ hex: Hex) -> Bool {
    isRepresentable(hex.q) && isRepresentable(hex.r) && isRepresentable(hex.s)
  }

  /// Returns whether `coordinate + delta` is inside the range, counting a sum
  /// that overflows `Int` as being outside it.
  static func isRepresentable(_ coordinate: Int, offsetBy delta: Int) -> Bool {
    let (sum, overflow) = coordinate.addingReportingOverflow(delta)
    return !overflow && isRepresentable(sum)
  }

  /// Returns whether every cell of a rectangle of at least one cell stays inside
  /// the supported coordinate range.
  ///
  /// One index of an offset coordinate is a cube coordinate of its hex, and the
  /// other differs from a cube coordinate by half of the first one; a rectangle
  /// reaching past the limits below therefore has cells out of range, and within
  /// those limits the conversion itself cannot overflow. Every cube coordinate
  /// is monotone in both indices, so the extreme values are all reached at the
  /// four corner cells.
  static func rectangleStaysInRange(
    origin: OffsetCoordinate, columns: Int, rows: Int, system: OffsetSystem
  ) -> Bool {
    let lineLimit = Hex.coordinateBound - 1
    let crossLimit = lineLimit + Hex.coordinateBound / 2
    let columnLimit = system.isRowSystem ? crossLimit : lineLimit
    let rowLimit = system.isRowSystem ? lineLimit : crossLimit
    let (lastColumn, columnOverflow) = origin.column.addingReportingOverflow(columns - 1)
    let (lastRow, rowOverflow) = origin.row.addingReportingOverflow(rows - 1)
    guard !columnOverflow, !rowOverflow else { return false }
    guard -columnLimit <= origin.column, lastColumn <= columnLimit,
      -rowLimit <= origin.row, lastRow <= rowLimit
    else { return false }
    let corners = [
      OffsetCoordinate(column: origin.column, row: origin.row),
      OffsetCoordinate(column: lastColumn, row: origin.row),
      OffsetCoordinate(column: origin.column, row: lastRow),
      OffsetCoordinate(column: lastColumn, row: lastRow),
    ]
    return corners.allSatisfy { isRepresentable(Hex($0, in: system)) }
  }

  /// Returns `1 + 3 * radius * (radius + 1)`, or `nil` when it does not fit `Int`.
  static func checkedHexagonCellCount(radius: Int) -> Int? {
    let (triple, tripleOverflow) = radius.multipliedReportingOverflow(by: 3)
    guard !tripleOverflow else { return nil }
    let (next, nextOverflow) = radius.addingReportingOverflow(1)
    guard !nextOverflow else { return nil }
    let (product, productOverflow) = triple.multipliedReportingOverflow(by: next)
    guard !productOverflow else { return nil }
    let (count, countOverflow) = product.addingReportingOverflow(1)
    return countOverflow ? nil : count
  }

  /// Returns `triangularNumber(size + 1)`, or `nil` when it does not fit `Int`.
  static func checkedTriangleCellCount(size: Int) -> Int? {
    let (rows, overflow) = size.addingReportingOverflow(1)
    guard !overflow else { return nil }
    return checkedTriangularNumber(rows)
  }

  /// Returns `n * (n + 1) / 2` for `n >= 0`, or `nil` when it does not fit `Int`.
  static func checkedTriangularNumber(_ n: Int) -> Int? {
    let (next, overflow) = n.addingReportingOverflow(1)
    guard !overflow else { return nil }
    let (product, productOverflow) =
      n % 2 == 0
      ? (n / 2).multipliedReportingOverflow(by: next)
      : n.multipliedReportingOverflow(by: next / 2)
    return productOverflow ? nil : product
  }

  /// Returns `n * (n + 1) / 2`, with the even factor halved before the
  /// multiplication, so that no intermediate value overflows `Int` on a 32-bit
  /// platform. `triangularNumber(-1)` is `0`, the length of an empty prefix.
  static func triangularNumber(_ n: Int) -> Int {
    n % 2 == 0 ? (n / 2) * (n + 1) : n * ((n + 1) / 2)
  }
}

extension HexShape {

  /// Returns the smallest `q` of a row of a hexagon, relative to its center.
  static func hexagonRowStart(row: Int, radius: Int) -> Int {
    max(-radius, -row - radius)
  }

  /// Returns the largest `q` of a row of a hexagon, relative to its center.
  static func hexagonRowEnd(row: Int, radius: Int) -> Int {
    min(radius, -row + radius)
  }

  /// Returns the number of cells of a hexagon in the rows above `row`, where
  /// `row` runs from `-radius` to `radius + 1`.
  ///
  /// The rows of the upper half hold `radius + 1`, `radius + 2` and so on cells,
  /// and the lower half mirrors them. The upper half is summed from the top and
  /// the lower one from the bottom, so that no intermediate value exceeds `count`.
  static func hexagonRowPrefix(row: Int, radius: Int, count: Int) -> Int {
    let i = row + radius
    if i <= radius {
      return i * (radius + 1) + triangularNumber(i - 1)
    }
    let m = 2 * radius + 1 - i
    return count - (m * (radius + 1) + triangularNumber(m - 1))
  }

  /// Returns the row of a hexagon that holds the cell at `index`.
  static func hexagonRow(containing index: Int, radius: Int, count: Int) -> Int {
    // The prefix of the row `i` of the upper half is `i * radius + triangularNumber(i)`,
    // so the row is the positive root of a quadratic; the lower half is the same
    // sum taken from the bottom, over the `m` rows the index leaves behind. The
    // expression under the root is built in `Double`: in `Int` it would overflow
    // on a 32-bit platform long before the index does.
    let width = 2 * Double(radius) + 1
    var row: Int
    if index < hexagonRowPrefix(row: 0, radius: radius, count: count) {
      let i = ((width * width + 8 * Double(index)).squareRoot() - width) / 2
      row = Int(i.rounded(.down)) - radius
    } else {
      let m = ((width * width + 8 * Double(count - index)).squareRoot() - width) / 2
      row = radius + 1 - Int(m.rounded(.up))
    }
    return corrected(
      min(max(row, -radius), radius), from: -radius, to: radius, holding: index,
      prefix: { hexagonRowPrefix(row: $0, radius: radius, count: count) })
  }

  /// Returns the number of cells of a triangle with a corner at the bottom in
  /// the rows above `row`, where `row` runs from `0` to `size + 1`.
  ///
  /// The rows are counted from the bottom, where they are short, so that no
  /// intermediate value exceeds `count`.
  static func triangleDownRowPrefix(row: Int, size: Int, count: Int) -> Int {
    count - triangularNumber(size + 1 - row)
  }

  /// Returns the row of a triangle with a corner at the bottom that holds the
  /// cell at `index`.
  static func triangleDownRow(containing index: Int, size: Int, count: Int) -> Int {
    // The rows from this one down hold `count - index` cells or more, and the
    // smallest triangular number that reaches that tail says how many rows those
    // are; the row itself is what they leave out.
    let tail = 8 * Double(count - index) + 1
    let rows = Int(((tail.squareRoot() - 1) / 2).rounded(.up))
    return corrected(
      min(max(size + 1 - rows, 0), size), from: 0, to: size, holding: index,
      prefix: { triangleDownRowPrefix(row: $0, size: size, count: count) })
  }

  /// Returns the row of a triangle with a corner at the top that holds the cell
  /// at `index`. The rows above it hold `triangularNumber(row)` cells.
  static func triangleUpRow(containing index: Int, size: Int) -> Int {
    let estimate = ((8 * Double(index) + 1).squareRoot() - 1) / 2
    let row = Int(estimate.rounded(.down))
    return corrected(
      min(max(row, 0), size), from: 0, to: size, holding: index, prefix: triangularNumber)
  }

  /// Returns the row that really holds `index`, starting from an estimate.
  ///
  /// The correction is what makes the square root above safe: beyond `2 ^ 53` a
  /// `Double` no longer holds every `Int`, so an estimate right at the edge of a
  /// row can land one row off. Every step here is exact integer arithmetic.
  private static func corrected(
    _ estimate: Int, from first: Int, to last: Int, holding index: Int, prefix: (Int) -> Int
  ) -> Int {
    var row = estimate
    while row > first && prefix(row) > index {
      row -= 1
    }
    while row < last && prefix(row + 1) <= index {
      row += 1
    }
    return row
  }
}
