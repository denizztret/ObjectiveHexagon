/// A column and row pair in one of the offset coordinate systems.
///
/// The value carries no system of its own; every conversion names the system.
public struct OffsetCoordinate: Hashable, Sendable, Codable {

  /// The column index.
  public let column: Int

  /// The row index.
  public let row: Int

  /// Creates an offset coordinate from a column and a row.
  public init(column: Int, row: Int) {
    self.column = column
    self.row = row
  }

  /// Creates the offset coordinate of a hex in the given system.
  public init(_ hex: Hex, in system: OffsetSystem) {
    if system.isRowSystem {
      self.init(column: hex.q + system.shift(ofLine: hex.r), row: hex.r)
    } else {
      self.init(column: hex.q, row: hex.r + system.shift(ofLine: hex.q))
    }
  }

  /// Returns the adjacent coordinate in the given direction, read in the given system.
  public func neighbor(_ direction: HexDirection, in system: OffsetSystem) -> OffsetCoordinate {
    let line = system.isRowSystem ? row : column
    // The tables are written for the `odd` systems; the `even` ones shift the
    // other half of the lines, so they read the same table with the parity flipped.
    let parity = (line & 1) ^ (system.shiftsEvenLines ? 1 : 0)
    let steps = system.isRowSystem ? Self.rowSystemSteps : Self.columnSystemSteps
    let step = steps[parity][direction.rawValue]
    return OffsetCoordinate(column: column + step.column, row: row + step.row)
  }

  /// Returns the six adjacent coordinates, in the order of the direction indices.
  public func neighbors(in system: OffsetSystem) -> [OffsetCoordinate] {
    HexDirection.allCases.map { neighbor($0, in: system) }
  }
}

extension OffsetCoordinate {

  /// The steps to the six adjacent coordinates of the `oddR` system, by the
  /// parity of the row and then by the direction index 0...5.
  private static let rowSystemSteps: [[(column: Int, row: Int)]] = [
    [(1, 0), (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1)],
    [(1, 0), (1, -1), (0, -1), (-1, 0), (0, 1), (1, 1)],
  ]

  /// The steps to the six adjacent coordinates of the `oddQ` system, by the
  /// parity of the column and then by the direction index 0...5.
  private static let columnSystemSteps: [[(column: Int, row: Int)]] = [
    [(1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (0, 1)],
    [(1, 1), (1, 0), (0, -1), (-1, 0), (-1, 1), (0, 1)],
  ]
}

extension Hex {

  /// Creates the hex of an offset coordinate read in the given system.
  public init(_ coordinate: OffsetCoordinate, in system: OffsetSystem) {
    if system.isRowSystem {
      self.init(q: coordinate.column - system.shift(ofLine: coordinate.row), r: coordinate.row)
    } else {
      self.init(q: coordinate.column, r: coordinate.row - system.shift(ofLine: coordinate.column))
    }
  }
}
