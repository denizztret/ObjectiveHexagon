/// A hexagon-shaped map whose edges wrap around: a step off one side comes back
/// on the opposite side.
///
/// As in the guide, the map has six mirror centers around its own center, and a
/// hex off the map stands for the cell of the map it reaches by subtracting
/// mirror centers until it is back on the map. ``wrap(_:)`` finds that cell in
/// constant time for any hex of the supported coordinate range.
public struct WrappedHexagon: Hashable, Sendable, Codable {

  /// The center of the map.
  public let center: Hex

  /// The radius of the map: every cell is within `radius` steps of `center`.
  public let radius: Int

  /// Creates a wrapped map with the cells of a hexagon.
  ///
  /// - Precondition: `radius >= 0`, and the cell count and all cell coordinates
  ///   are representable, as for ``HexShape/hexagon(center:radius:)``.
  public init(center: Hex = .zero, radius: Int) {
    if let reason = HexShape.hexagonRejectionReason(center: center, radius: radius) {
      preconditionFailure(reason)
    }
    self.center = center
    self.radius = radius
  }

  /// Decodes a wrapped map, failing when the radius is out of range.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let center = try container.decode(Hex.self, forKey: .center)
    let radius = try container.decode(Int.self, forKey: .radius)
    // The very check of the initializer and of `HexShape.hexagon`, thrown
    // instead of trapping: encoded data comes from outside.
    if let reason = HexShape.hexagonRejectionReason(center: center, radius: radius) {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: container.codingPath, debugDescription: reason))
    }
    self.center = center
    self.radius = radius
  }

  /// The cells of the map: `HexShape.hexagon(center: center, radius: radius)`.
  public var shape: HexShape {
    HexShape.hexagon(center: center, radius: radius)
  }

  /// The six mirror centers of the map, relative to its center.
  ///
  /// The first is `Hex(q: 2 * radius + 1, r: -radius)`, and each next one is the
  /// previous one rotated by one step clockwise, as in the guide. Shifting a hex
  /// by any of them does not change the cell it wraps to.
  public var mirrorCenters: [Hex] {
    let first = Hex(q: 2 * radius + 1, r: -radius)
    return (0..<6).map { first.rotated(by: $0) }
  }

  /// Returns the cell of the map that a hex stands for.
  ///
  /// A cell of the map returns itself. Any other hex returns the one cell of the
  /// map it differs from by a sum of mirror centers, the same cell the guide's
  /// rule of subtracting the nearest mirror center reaches. The result does not
  /// depend on the distance of the hex from the map, and it does not overflow
  /// `Int` for any hex of the supported coordinate range, on 32-bit platforms
  /// too.
  public func wrap(_ hex: Hex) -> Hex {
    let offset = Self.wrappedOffset(q: hex.q - center.q, r: hex.r - center.r, radius: radius)
    return Hex(q: offset.q, r: offset.r) + center
  }

  /// Returns the offset from the center of a map of radius `n` that the
  /// offset `(q, r)` wraps to.
  ///
  /// Generic so that tests can run the arithmetic of a 32-bit platform in
  /// `Int32` on any machine; the map itself uses it with `Int`.
  static func wrappedOffset<T: FixedWidthInteger & SignedInteger>(
    q: T, r: T, radius n: T
  ) -> (q: T, r: T) {
    // The mirror centers span a lattice of index `area`, the cell count of the
    // map, and that lattice holds `area * Z^2`, so reducing `q` and `r` modulo
    // `area` keeps the cell; it also keeps the values below small. A map of one
    // cell needs no special case: with `area == 1` every offset reduces to zero.
    let area = 1 + 3 * n * (n + 1)
    let q = centeredRemainder(q, modulo: area)
    let r = centeredRemainder(r, modulo: area)
    let s = -q - r
    // The hexmod representation of Sander Evers, which the guide links to: the
    // "large hex" `(x, y, z)` holding the offset, whose center is subtracted.
    let shift = 3 * n + 2
    let x = flooredQuotient(shift, times: q, plus: r, dividedBy: area)
    let y = flooredQuotient(shift, times: r, plus: s, dividedBy: area)
    let z = flooredQuotient(shift, times: s, plus: q, dividedBy: area)
    let largeQ = flooredQuotient(1 + x - y, dividedBy: 3)
    let largeR = flooredQuotient(1 + y - z, dividedBy: 3)
    let largeS = -largeQ - largeR
    let centerQ = largeQ * (n + 1) - n * largeS
    let centerR = largeR * (n + 1) - n * largeQ
    return (q - centerQ, r - centerR)
  }

  /// Returns the remainder of `value` modulo `modulus > 0` in the range
  /// `(-modulus / 2, modulus / 2]`.
  private static func centeredRemainder<T: FixedWidthInteger & SignedInteger>(
    _ value: T, modulo modulus: T
  ) -> T {
    let remainder = value % modulus
    let nonNegative = remainder < 0 ? remainder + modulus : remainder
    return nonNegative > modulus / 2 ? nonNegative - modulus : nonNegative
  }

  /// Returns `a / b` rounded down, for `b > 0`.
  private static func flooredQuotient<T: FixedWidthInteger & SignedInteger>(
    _ a: T, dividedBy b: T
  ) -> T {
    let (quotient, remainder) = a.quotientAndRemainder(dividingBy: b)
    return remainder < 0 ? quotient - 1 : quotient
  }

  /// Returns `(a * b + c) / d` rounded down, for `d > 0`, with the product and
  /// the sum taken in double width: on a 32-bit platform the product of the
  /// shift and a coordinate does not fit `Int`, while the quotient always does.
  static func flooredQuotient<T: FixedWidthInteger & SignedInteger>(
    _ a: T, times b: T, plus c: T, dividedBy d: T
  ) -> T {
    let product = a.multipliedFullWidth(by: b)
    // `c` in double width is its bit pattern with the sign extended into the
    // high half; the carry of the low halves moves into the high one.
    let (low, carry) = product.low.addingReportingOverflow(T.Magnitude(truncatingIfNeeded: c))
    let high = product.high &+ (c < 0 ? -1 : 0) &+ (carry ? 1 : 0)
    let (quotient, remainder) = d.dividingFullWidth((high: high, low: low))
    return remainder < 0 ? quotient - 1 : quotient
  }
}
