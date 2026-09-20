/// A point in pixel space, owned by the core module.
///
/// The x axis points right and the y axis points down, as in the guide.
/// Bridges to `CGPoint` and `CGSize` live in `HexagonKitUI`.
///
/// Equality and hashing follow the semantics of `Double`: `0.0` equals `-0.0`,
/// and a `NaN` is not equal to itself, so a point holding a `NaN` is unusable
/// as a dictionary key.
public struct Point: Hashable, Sendable, Codable {

  /// The horizontal coordinate.
  public let x: Double

  /// The vertical coordinate.
  public let y: Double

  /// The point at the origin.
  public static let zero = Point(x: 0, y: 0)

  /// Creates a point from its components.
  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }
}
