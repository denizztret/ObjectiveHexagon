/// A hex coordinate with fractional components, produced by pixel-to-hex
/// conversion and by interpolation.
///
/// Unlike ``Hex``, it stores all three cube components, exactly as the guide's
/// reference implementation does, so interpolation and rounding reproduce the
/// reference results bit for bit.
///
/// Equality and hashing follow the semantics of `Double`: `0.0` equals `-0.0`,
/// and a `NaN` is not equal to itself, so a value holding a `NaN` is unusable
/// as a dictionary key.
public struct FractionalHex: Hashable, Sendable, Codable {

  /// The cube coordinate `q`.
  public let q: Double

  /// The cube coordinate `r`.
  public let r: Double

  /// The cube coordinate `s`.
  public let s: Double

  /// Creates a fractional hex from axial coordinates; `s` is set to `-q - r`.
  public init(q: Double, r: Double) {
    self.init(q: q, r: r, s: -q - r)
  }

  /// Creates a fractional hex from three cube components, without checking their sum.
  public init(q: Double, r: Double, s: Double) {
    self.q = q
    self.r = r
    self.s = s
  }

  /// Creates a fractional hex from an integer hex.
  public init(_ hex: Hex) {
    self.init(q: Double(hex.q), r: Double(hex.r), s: Double(hex.s))
  }

  /// Returns the nearest hex, resolving ties the way the guide does.
  public func rounded() -> Hex {
    precondition(
      q.isFinite && r.isFinite && s.isFinite,
      "A fractional hex can only be rounded when all three components are finite.")
    let bound = Double(Hex.coordinateBound)
    precondition(
      abs(q) <= bound && abs(r) <= bound && abs(s) <= bound,
      "A fractional hex can only be rounded inside the supported coordinate range.")
    // Halves go away from zero, which is what the C++ and Rust ports of the
    // guide do; the comparisons below are strict, so equal errors recompute `s`.
    var qi = Int(q.rounded(.toNearestOrAwayFromZero))
    var ri = Int(r.rounded(.toNearestOrAwayFromZero))
    let si = Int(s.rounded(.toNearestOrAwayFromZero))
    let qDiff = abs(Double(qi) - q)
    let rDiff = abs(Double(ri) - r)
    let sDiff = abs(Double(si) - s)
    if qDiff > rDiff && qDiff > sDiff {
      qi = -ri - si
    } else if rDiff > sDiff {
      ri = -qi - si
    }
    // The remaining branch of the guide recomputes `s`, which ``Hex`` derives
    // from `q` and `r`, so there is nothing left to do.
    return Hex(q: qi, r: ri)
  }

  /// Returns the linear interpolation ("lerp") towards another fractional hex.
  ///
  /// Each of the three components is computed independently as
  /// `self * (1 - t) + other * t`, as in the guide.
  public func lerp(to other: FractionalHex, t: Double) -> FractionalHex {
    // Written exactly as the reference does: an algebraically equal form such as
    // `q + (other.q - q) * t` differs in the last bit and drifts from it.
    FractionalHex(
      q: q * (1.0 - t) + other.q * t,
      r: r * (1.0 - t) + other.r * t,
      s: s * (1.0 - t) + other.s * t)
  }
}
