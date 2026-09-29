/// A map that keeps one value for every cell of a shape in a flat array.
///
/// This is the guide's array storage: the value of a cell sits at the cell's
/// index in the shape, so reading and writing take constant time and involve
/// no hashing. The shape is fixed when the map is created; the values can
/// change. For maps of arbitrary shape, or with holes, use a `[Hex: Value]`
/// dictionary instead.
///
/// The map allocates one value per cell of the shape at once, and a valid shape
/// may have far more cells than fit in memory; create maps only for shapes of a
/// size you can store.
public struct DenseHexMap<Value> {

  /// The shape whose cells the map holds values for.
  public let shape: HexShape

  /// The values in the index order of the shape: `values[i]` belongs to the
  /// cell `shape.hex(at: i)`, and `values.count == shape.count`.
  public private(set) var values: [Value]

  /// Creates a map that holds the same value for every cell of a shape.
  public init(repeating value: Value, shape: HexShape) {
    self.shape = shape
    values = Array(repeating: value, count: shape.count)
  }

  /// Creates a map that holds, for every cell of a shape, the value the closure
  /// returns for it.
  ///
  /// The closure is called once for each cell, in index order.
  public init(shape: HexShape, _ value: (Hex) -> Value) {
    self.shape = shape
    values = shape.cells().map(value)
  }

  /// Accesses the value of a cell, like a dictionary.
  ///
  /// Reading gives `nil` when the shape does not contain the hex. Writing a
  /// value replaces the value of a cell of the shape. Writing `nil` for a hex
  /// outside the shape does nothing, like removing a key a dictionary does not
  /// have; that is also what an update through optional chaining, such as
  /// `map[hex]? += 1`, amounts to for a hex outside the shape.
  ///
  /// - Precondition: a value is written only for a cell of the shape, and `nil`
  ///   only for a hex outside it: the set of cells never changes.
  public subscript(hex: Hex) -> Value? {
    get {
      shape.index(of: hex).map { values[$0] }
    }
    set {
      // `map[hex]? += 1` calls the setter even when the getter gave `nil`, and
      // then it writes `nil` for a hex outside the shape; that must stay harmless.
      guard let index = shape.index(of: hex) else {
        precondition(newValue == nil, "A value can only be written for a cell of the shape.")
        return
      }
      guard let newValue else {
        preconditionFailure("A cell of the shape cannot be removed from a dense map.")
      }
      values[index] = newValue
    }
  }
}

extension DenseHexMap: Equatable where Value: Equatable {}

extension DenseHexMap: Hashable where Value: Hashable {}

extension DenseHexMap: Sendable where Value: Sendable {}

extension DenseHexMap: Encodable where Value: Encodable {

  /// Encodes the map as its shape and the array of its values in index order.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: DenseHexMapCodingKeys.self)
    try container.encode(shape, forKey: .shape)
    try container.encode(values, forKey: .values)
  }
}

extension DenseHexMap: Decodable where Value: Decodable {

  /// Decodes a map, failing when the number of values differs from the number
  /// of cells of the shape.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: DenseHexMapCodingKeys.self)
    let shape = try container.decode(HexShape.self, forKey: .shape)
    let values = try container.decode([Value].self, forKey: .values)
    // The shape is valid, so its count fits `Int`; comparing it with the values
    // allocates nothing, however large the shape is.
    guard values.count == shape.count else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "the number of values differs from the number of cells of the shape"))
    }
    self.shape = shape
    self.values = values
  }
}

/// The names of the encoded fields of a dense map.
private enum DenseHexMapCodingKeys: String, CodingKey {
  case shape
  case values
}
