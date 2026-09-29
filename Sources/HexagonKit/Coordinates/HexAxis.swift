/// One of the three cube axes of the grid.
///
/// A reflection keeps the coordinate of the axis it is named after; see
/// ``Hex/reflected(across:around:)``.
public enum HexAxis: String, CaseIterable, Hashable, Sendable, Codable {

  /// The axis of the cube coordinate `q`.
  case q
  /// The axis of the cube coordinate `r`.
  case r
  /// The axis of the cube coordinate `s`.
  case s
}

extension Hex {

  /// Returns the hex reflected across an axis through a center.
  ///
  /// As in the guide, the reflection keeps the coordinate of the axis and swaps
  /// the other two, all taken relative to `center`: across `.q` the offset
  /// `(q, r, s)` becomes `(q, s, r)`, across `.r` it becomes `(s, r, q)`, and
  /// across `.s` it becomes `(r, q, s)`. The line of the reflection runs through
  /// `center` along the two diagonals that change the kept coordinate by 2; for
  /// `.q` these are ``HexDiagonal/plusQ`` and ``HexDiagonal/minusQ``. Reflecting
  /// twice across the same axis returns the original hex.
  ///
  /// The guide reaches its other three reflections by negating these: relative
  /// to `center` that is `(self - center).reflected(across: axis) * -1 + center`.
  public func reflected(across axis: HexAxis, around center: Hex = .zero) -> Hex {
    // Subtract the center, reflect, add the center back, as the guide does.
    let offset = self - center
    let reflected: Hex
    switch axis {
    case .q: reflected = Hex(q: offset.q, r: offset.s)
    case .r: reflected = Hex(q: offset.s, r: offset.r)
    case .s: reflected = Hex(q: offset.r, r: offset.q)
    }
    return reflected + center
  }
}
