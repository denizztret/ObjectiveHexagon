/// A map shape: the set of hexes a map is made of, with a stable cell order.
///
/// Every shape numbers its cells from `0` to `count - 1` row by row, so a cell
/// and its index convert to each other in constant time. Shapes are created with
/// the static factory methods, which validate their parameters; the storage is
/// private, so new kinds of shapes can be added without breaking clients.
public struct HexShape: Hashable, Sendable, Codable {

  /// The kind of a shape and the parameters it was created with. The type is
  /// private, so the set of kinds is not part of the API; `Hashable` and
  /// `Sendable` of the shape are synthesized from it.
  private enum Storage: Hashable, Sendable {
    case hexagon(center: Hex, radius: Int)
    case triangleDown(origin: Hex, size: Int)
    case triangleUp(origin: Hex, size: Int)
    case rectangle(origin: OffsetCoordinate, columns: Int, rows: Int, system: OffsetSystem)
  }

  /// The kind and the parameters of this shape.
  private let storage: Storage

  /// Creates a shape from parameters that must already describe one.
  private init(_ storage: Storage) {
    if let reason = Self.rejectionReason(of: storage) {
      preconditionFailure(reason)
    }
    self.storage = storage
  }

  /// Returns the hexagon of all hexes within `radius` steps of `center`.
  ///
  /// - Precondition: `radius >= 0`, and the cell count and all cell coordinates
  ///   are representable.
  public static func hexagon(center: Hex = .zero, radius: Int) -> HexShape {
    HexShape(.hexagon(center: center, radius: radius))
  }

  /// Returns the triangle with a corner at the bottom: `0 <= q`, `0 <= r`,
  /// `q + r <= size`, relative to `origin`.
  ///
  /// - Precondition: `size >= 0`, and the cell count and all cell coordinates
  ///   are representable.
  public static func triangleDown(origin: Hex = .zero, size: Int) -> HexShape {
    HexShape(.triangleDown(origin: origin, size: size))
  }

  /// Returns the triangle with a corner at the top: `0 <= r <= size`,
  /// `size - r <= q <= size`, relative to `origin`.
  ///
  /// - Precondition: `size >= 0`, and the cell count and all cell coordinates
  ///   are representable.
  public static func triangleUp(origin: Hex = .zero, size: Int) -> HexShape {
    HexShape(.triangleUp(origin: origin, size: size))
  }

  /// Returns the `columns` by `rows` rectangle of offset coordinates read in the
  /// given system, starting at `origin`.
  ///
  /// - Precondition: `columns >= 0`, `rows >= 0`, and the cell count and all cell
  ///   coordinates are representable.
  public static func rectangle(
    origin: OffsetCoordinate = OffsetCoordinate(column: 0, row: 0),
    columns: Int,
    rows: Int,
    in system: OffsetSystem
  ) -> HexShape {
    HexShape(.rectangle(origin: origin, columns: columns, rows: rows, system: system))
  }

  /// Decodes a shape, failing when a parameter is out of range.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let storage: Storage
    switch try container.decode(Kind.self, forKey: .kind) {
    case .hexagon:
      let center = try container.decode(Hex.self, forKey: .center)
      let radius = try container.decode(Int.self, forKey: .radius)
      storage = .hexagon(center: center, radius: radius)
    case .triangleDown:
      let origin = try container.decode(Hex.self, forKey: .origin)
      let size = try container.decode(Int.self, forKey: .size)
      storage = .triangleDown(origin: origin, size: size)
    case .triangleUp:
      let origin = try container.decode(Hex.self, forKey: .origin)
      let size = try container.decode(Int.self, forKey: .size)
      storage = .triangleUp(origin: origin, size: size)
    case .rectangle:
      let origin = try container.decode(OffsetCoordinate.self, forKey: .origin)
      let columns = try container.decode(Int.self, forKey: .columns)
      let rows = try container.decode(Int.self, forKey: .rows)
      let system = try container.decode(OffsetSystem.self, forKey: .system)
      storage = .rectangle(origin: origin, columns: columns, rows: rows, system: system)
    }
    // The very check the factories run, thrown instead of trapping: encoded data
    // comes from outside, so a decoder rejects it rather than stopping the process.
    if let reason = Self.rejectionReason(of: storage) {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: container.codingPath, debugDescription: reason))
    }
    self.storage = storage
  }

  /// Encodes the shape as its kind and parameters.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch storage {
    case .hexagon(let center, let radius):
      try container.encode(Kind.hexagon, forKey: .kind)
      try container.encode(center, forKey: .center)
      try container.encode(radius, forKey: .radius)
    case .triangleDown(let origin, let size):
      try container.encode(Kind.triangleDown, forKey: .kind)
      try container.encode(origin, forKey: .origin)
      try container.encode(size, forKey: .size)
    case .triangleUp(let origin, let size):
      try container.encode(Kind.triangleUp, forKey: .kind)
      try container.encode(origin, forKey: .origin)
      try container.encode(size, forKey: .size)
    case .rectangle(let origin, let columns, let rows, let system):
      try container.encode(Kind.rectangle, forKey: .kind)
      try container.encode(origin, forKey: .origin)
      try container.encode(columns, forKey: .columns)
      try container.encode(rows, forKey: .rows)
      try container.encode(system, forKey: .system)
    }
  }

  /// The number of cells in the shape.
  public var count: Int {
    // Every shape is validated when it is created, so none of these overflows.
    switch storage {
    case .hexagon(_, let radius): 1 + 3 * radius * (radius + 1)
    case .triangleDown(_, let size), .triangleUp(_, let size): Self.triangularNumber(size + 1)
    case .rectangle(_, let columns, let rows, _): columns * rows
    }
  }

  /// Returns whether the shape contains a hex.
  public func contains(_ hex: Hex) -> Bool {
    index(of: hex) != nil
  }

  /// Returns all cells of the shape, in index order.
  public func cells() -> [Hex] {
    // An empty rectangle may still have an enormous number of rows or columns,
    // and walking them would take forever to produce nothing.
    guard count > 0 else { return [] }
    var cells: [Hex] = []
    cells.reserveCapacity(count)
    switch storage {
    case .hexagon(let center, let radius):
      for row in -radius...radius {
        let start = Self.hexagonRowStart(row: row, radius: radius)
        for column in start...Self.hexagonRowEnd(row: row, radius: radius) {
          cells.append(Hex(q: column, r: row) + center)
        }
      }
    case .triangleDown(let origin, let size):
      for row in 0...size {
        for column in 0...(size - row) {
          cells.append(Hex(q: column, r: row) + origin)
        }
      }
    case .triangleUp(let origin, let size):
      for row in 0...size {
        for column in (size - row)...size {
          cells.append(Hex(q: column, r: row) + origin)
        }
      }
    case .rectangle(let origin, let columns, let rows, let system):
      for row in 0..<rows {
        for column in 0..<columns {
          let offset = OffsetCoordinate(column: origin.column + column, row: origin.row + row)
          cells.append(Hex(offset, in: system))
        }
      }
    }
    return cells
  }

  /// Returns the index of a hex, or `nil` when the shape does not contain it.
  public func index(of hex: Hex) -> Int? {
    // A hex outside the supported coordinate range is a cell of no valid shape,
    // and the arithmetic below counts on that range, so it is refused up front.
    guard Self.isRepresentable(hex) else { return nil }
    switch storage {
    case .hexagon(let center, let radius):
      guard hex.distance(to: center) <= radius else { return nil }
      let row = hex.r - center.r
      let column = hex.q - center.q
      return Self.hexagonRowPrefix(row: row, radius: radius, count: count)
        + (column - Self.hexagonRowStart(row: row, radius: radius))
    case .triangleDown(let origin, let size):
      let row = hex.r - origin.r
      let column = hex.q - origin.q
      guard 0 <= row, row <= size, 0 <= column, column <= size - row else { return nil }
      return Self.triangleDownRowPrefix(row: row, size: size, count: count) + column
    case .triangleUp(let origin, let size):
      let row = hex.r - origin.r
      let column = hex.q - origin.q
      guard 0 <= row, row <= size, size - row <= column, column <= size else { return nil }
      return Self.triangularNumber(row) + (column - (size - row))
    case .rectangle(let origin, let columns, let rows, let system):
      let offset = OffsetCoordinate(hex, in: system)
      guard let column = Self.checkedDifference(offset.column, origin.column),
        let row = Self.checkedDifference(offset.row, origin.row)
      else { return nil }
      guard 0 <= column, column < columns, 0 <= row, row < rows else { return nil }
      return row * columns + column
    }
  }

  /// Returns the cell at an index.
  ///
  /// - Precondition: `index` is in `0..<count`.
  public func hex(at index: Int) -> Hex {
    let count = self.count
    precondition(0 <= index && index < count, "The index of a cell must lie in 0..<count.")
    switch storage {
    case .hexagon(let center, let radius):
      let row = Self.hexagonRow(containing: index, radius: radius, count: count)
      let column = index - Self.hexagonRowPrefix(row: row, radius: radius, count: count)
      let q = Self.hexagonRowStart(row: row, radius: radius) + column
      return Hex(q: q, r: row) + center
    case .triangleDown(let origin, let size):
      let row = Self.triangleDownRow(containing: index, size: size, count: count)
      let column = index - Self.triangleDownRowPrefix(row: row, size: size, count: count)
      return Hex(q: column, r: row) + origin
    case .triangleUp(let origin, let size):
      let row = Self.triangleUpRow(containing: index, size: size)
      let column = index - Self.triangularNumber(row)
      return Hex(q: size - row + column, r: row) + origin
    case .rectangle(let origin, let columns, _, let system):
      let offset = OffsetCoordinate(
        column: origin.column + index % columns, row: origin.row + index / columns)
      return Hex(offset, in: system)
    }
  }
}

extension HexShape {

  /// The reason a shape whose cells cannot be counted in `Int` is refused.
  private static let unrepresentableCount = "the number of cells of the shape does not fit Int"

  /// The reason a shape whose cells leave the coordinate range is refused.
  private static let unrepresentableCoordinates =
    "the cells of the shape leave the supported coordinate range"

  /// Returns why the given parameters do not describe a shape, or `nil` when
  /// they do.
  ///
  /// The factories and the decoder share this check, so the shapes a factory
  /// traps on are exactly the ones the decoder rejects.
  private static func rejectionReason(of storage: Storage) -> String? {
    switch storage {
    case .hexagon(let center, let radius):
      guard radius >= 0 else { return "the radius of a hexagon cannot be negative" }
      guard checkedHexagonCellCount(radius: radius) != nil else { return unrepresentableCount }
      // The hexagon reaches `center ± radius` along each of the three axes.
      guard isRepresentable(center),
        isRepresentable(center.q, offsetBy: radius),
        isRepresentable(center.q, offsetBy: -radius),
        isRepresentable(center.r, offsetBy: radius),
        isRepresentable(center.r, offsetBy: -radius),
        isRepresentable(center.s, offsetBy: radius),
        isRepresentable(center.s, offsetBy: -radius)
      else { return unrepresentableCoordinates }
      return nil
    case .triangleDown(let origin, let size):
      guard size >= 0 else { return "the size of a triangle cannot be negative" }
      guard checkedTriangleCellCount(size: size) != nil else { return unrepresentableCount }
      // Its cells run over `0...size` along `q` and `r`, and over `-size...0` along `s`.
      guard isRepresentable(origin),
        isRepresentable(origin.q, offsetBy: size),
        isRepresentable(origin.r, offsetBy: size),
        isRepresentable(origin.s, offsetBy: -size)
      else { return unrepresentableCoordinates }
      return nil
    case .triangleUp(let origin, let size):
      guard size >= 0 else { return "the size of a triangle cannot be negative" }
      guard checkedTriangleCellCount(size: size) != nil else { return unrepresentableCount }
      guard let doubleSize = checkedProduct(size, 2) else { return unrepresentableCoordinates }
      // The origin is not a cell of this triangle, but both of its axial
      // coordinates are reached by cells, while `s` runs over `-2 * size...-size`.
      guard isRepresentable(origin.q), isRepresentable(origin.r),
        isRepresentable(origin.q, offsetBy: size),
        isRepresentable(origin.r, offsetBy: size),
        isRepresentable(origin.s, offsetBy: -size),
        isRepresentable(origin.s, offsetBy: -doubleSize)
      else { return unrepresentableCoordinates }
      return nil
    case .rectangle(let origin, let columns, let rows, let system):
      guard columns >= 0 else { return "a rectangle cannot have a negative number of columns" }
      guard rows >= 0 else { return "a rectangle cannot have a negative number of rows" }
      guard let count = checkedProduct(columns, rows) else { return unrepresentableCount }
      // An empty rectangle has no cells, so there is nothing left to place.
      guard count > 0 else { return nil }
      guard rectangleStaysInRange(origin: origin, columns: columns, rows: rows, system: system)
      else { return unrepresentableCoordinates }
      return nil
    }
  }

  /// The names of the encoded fields: the kind of the shape and the parameters
  /// of its factory, under the very names the factory gives them.
  private enum CodingKeys: String, CodingKey {
    case kind
    case center
    case origin
    case radius
    case size
    case columns
    case rows
    case system
  }

  /// The encoded name of a kind of shape. Decoding any other name fails, so the
  /// kinds of a newer version are refused rather than misread.
  private enum Kind: String, Codable {
    case hexagon
    case triangleDown
    case triangleUp
    case rectangle
  }
}
