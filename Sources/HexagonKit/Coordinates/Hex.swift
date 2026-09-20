/// A hex cell on the grid, stored in axial coordinates.
///
/// The cube coordinate `s` is derived as `-q - r`, so the cube invariant
/// `q + r + s == 0` holds by construction and cannot be violated.
/// Coordinates are supported while `|q|`, `|r|` and `|s|` stay below ``coordinateBound``.
public struct Hex: Hashable, Sendable, Codable {

  /// The first axial coordinate; the cube axis `q`.
  public let q: Int

  /// The second axial coordinate; the cube axis `r`.
  public let r: Int

  /// The third cube coordinate, derived as `-q - r`.
  public var s: Int { -q - r }

  /// The hex at the origin of the coordinate system.
  public static let zero = Hex(q: 0, r: 0)

  /// The exclusive bound of the supported coordinate range: `1 << 30`.
  public static let coordinateBound = 1 << 30

  /// Creates a hex from its axial coordinates.
  public init(q: Int, r: Int) {
    self.q = q
    self.r = r
  }

  /// Creates a hex from cube coordinates, or `nil` when `q + r + s != 0`.
  public init?(q: Int, r: Int, s: Int) {
    guard q + r + s == 0 else { return nil }
    self.init(q: q, r: r)
  }

  /// Returns the componentwise sum of two hexes.
  public static func + (lhs: Hex, rhs: Hex) -> Hex {
    Hex(q: lhs.q + rhs.q, r: lhs.r + rhs.r)
  }

  /// Returns the componentwise difference of two hexes.
  public static func - (lhs: Hex, rhs: Hex) -> Hex {
    Hex(q: lhs.q - rhs.q, r: lhs.r - rhs.r)
  }

  /// Returns the hex scaled by an integer factor.
  public static func * (hex: Hex, factor: Int) -> Hex {
    Hex(q: hex.q * factor, r: hex.r * factor)
  }

  /// The distance from the origin, in steps.
  // The guide gives this as `(|q| + |r| + |s|) / 2`; the equal form below is used
  // instead because the sum of the three magnitudes overflows a 32-bit `Int`
  // inside the supported coordinate range.
  public var length: Int {
    max(abs(q), abs(r), abs(s))
  }

  /// Returns the distance to another hex, in steps.
  public func distance(to other: Hex) -> Int {
    max(abs(q - other.q), abs(r - other.r), abs(s - other.s))
  }

  /// Returns the adjacent hex in the given direction.
  public func neighbor(_ direction: HexDirection) -> Hex {
    self + direction.vector
  }

  /// The six adjacent hexes, in the order of the guide's direction indices.
  public var neighbors: [Hex] {
    HexDirection.allCases.map(neighbor)
  }

  /// Returns the hex rotated around a center by whole steps of 60 degrees.
  ///
  /// Positive steps rotate clockwise on screen, negative steps counterclockwise.
  public func rotated(by steps: Int, around center: Hex = .zero) -> Hex {
    var offset = self - center
    for _ in 0..<(((steps % 6) + 6) % 6) {
      offset = Hex(q: -offset.r, r: -offset.s)
    }
    return offset + center
  }

  /// Returns the ring of hexes at exactly the given distance from this hex.
  ///
  /// The ring starts at `self + HexDirection.plusRMinusQ.vector * radius` and takes
  /// `radius` steps along each of the directions 0...5 in turn, which is
  /// counterclockwise on screen; a radius of zero yields `[self]`.
  public func ring(radius: Int) -> [Hex] {
    precondition(radius >= 0, "The radius of a ring cannot be negative.")
    guard radius > 0 else { return [self] }
    var ring: [Hex] = []
    ring.reserveCapacity(6 * radius)
    var hex = self + HexDirection.plusRMinusQ.vector * radius
    for direction in HexDirection.allCases {
      for _ in 0..<radius {
        ring.append(hex)
        hex = hex.neighbor(direction)
      }
    }
    return ring
  }
}
