/// A column and row pair in one of the doubled coordinate systems.
///
/// In both systems `column + row` is always even; a pair that breaks the rule
/// does not denote a hex and cannot be created.
public struct DoubledCoordinate: Hashable, Sendable, Codable {

  /// The column index.
  public let column: Int

  /// The row index.
  public let row: Int

  /// Creates a doubled coordinate, or `nil` when `column + row` is odd.
  public init?(column: Int, row: Int) {
    guard Self.hasEvenSum(column, row) else { return nil }
    self.init(unchecked: column, row)
  }

  /// Creates the doubled coordinate of a hex in the given system.
  public init(_ hex: Hex, in system: DoubledSystem) {
    // Doubling one axis and adding the other keeps the sum even, so a coordinate
    // made from a hex never breaks the invariant and needs no check.
    switch system {
    case .doubleWidth: self.init(unchecked: 2 * hex.q + hex.r, hex.r)
    case .doubleHeight: self.init(unchecked: hex.q, 2 * hex.r + hex.q)
    }
  }

  /// Decodes a doubled coordinate, failing when `column + row` is odd.
  public init(from decoder: any Decoder) throws {
    // The invariant is a property of the value, so it is checked here: the
    // synthesized decoder would accept any pair.
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let column = try container.decode(Int.self, forKey: .column)
    let row = try container.decode(Int.self, forKey: .row)
    guard Self.hasEvenSum(column, row) else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "column + row must be even in a doubled coordinate"))
    }
    self.init(unchecked: column, row)
  }

  /// Returns whether `column + row` is even. The parity is read from the low
  /// bits of the two components, so the sum itself is never computed and a pair
  /// whose sum does not fit `Int` is judged rather than trapped on.
  private static func hasEvenSum(_ column: Int, _ row: Int) -> Bool {
    (column ^ row) & 1 == 0
  }

  /// Creates a doubled coordinate without checking the even-sum invariant.
  private init(unchecked column: Int, _ row: Int) {
    self.column = column
    self.row = row
  }

  /// Returns the adjacent coordinate in the given direction, read in the given system.
  public func neighbor(_ direction: HexDirection, in system: DoubledSystem) -> DoubledCoordinate {
    let steps = system == .doubleWidth ? Self.doubleWidthSteps : Self.doubleHeightSteps
    let step = steps[direction.rawValue]
    // Every step changes the sum by an even number, so the neighbour is a hex too.
    return DoubledCoordinate(unchecked: column + step.column, row + step.row)
  }

  /// Returns the six adjacent coordinates, in the order of the direction indices.
  public func neighbors(in system: DoubledSystem) -> [DoubledCoordinate] {
    HexDirection.allCases.map { neighbor($0, in: system) }
  }
}

extension DoubledCoordinate {

  /// The steps to the six adjacent coordinates of the `doubleWidth` system, by
  /// the direction index 0...5. Doubled systems do not depend on parity.
  private static let doubleWidthSteps: [(column: Int, row: Int)] = [
    (2, 0), (1, -1), (-1, -1), (-2, 0), (-1, 1), (1, 1),
  ]

  /// The steps to the six adjacent coordinates of the `doubleHeight` system, by
  /// the direction index 0...5.
  private static let doubleHeightSteps: [(column: Int, row: Int)] = [
    (1, 1), (1, -1), (0, -2), (-1, -1), (-1, 1), (0, 2),
  ]
}

extension Hex {

  /// Creates the hex of a doubled coordinate read in the given system.
  public init(_ coordinate: DoubledCoordinate, in system: DoubledSystem) {
    // The difference under the division is even by the invariant, so the
    // truncating division of Swift gives the same result as the flooring
    // division of the reference.
    switch system {
    case .doubleWidth:
      self.init(q: (coordinate.column - coordinate.row) / 2, r: coordinate.row)
    case .doubleHeight:
      self.init(q: coordinate.column, r: (coordinate.row - coordinate.column) / 2)
    }
  }
}
