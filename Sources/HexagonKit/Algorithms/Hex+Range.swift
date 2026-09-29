extension Hex {

  /// Returns every hex within `radius` steps of this hex, this hex included.
  ///
  /// This is the guide's movement range on an open grid. The hexes come row by
  /// row, in the order of `HexShape.hexagon(center: self, radius: radius).cells()`,
  /// and there are `1 + 3 * radius * (radius + 1)` of them. The whole array is
  /// allocated at once, so a large radius needs a matching amount of memory.
  ///
  /// - Precondition: `radius >= 0`, and the cell count and all cell coordinates
  ///   are representable, as for ``HexShape/hexagon(center:radius:)``.
  public func range(radius: Int) -> [Hex] {
    // One implementation for both: the shape checks the radius and lists the rows.
    HexShape.hexagon(center: self, radius: radius).cells()
  }

  /// Returns the hexes that lie within every one of the given ranges.
  ///
  /// Each range is a center and a radius, as in ``range(radius:)``. The result
  /// follows the guide's formula: the bounds of `q`, `r` and `s` of all ranges
  /// are intersected, and the hexes between them are listed row by row, `r`
  /// ascending and `q` ascending within a row. It is empty when the ranges have
  /// no hex in common, and for a single range it equals `range(radius:)` of it.
  /// The work is proportional to the number of ranges plus the number of hexes
  /// returned.
  ///
  /// - Precondition: `ranges` is not empty, every radius is `>= 0`, and all cell
  ///   coordinates of every range are representable.
  public static func intersection(ofRanges ranges: [(center: Hex, radius: Int)]) -> [Hex] {
    precondition(!ranges.isEmpty, "An intersection needs at least one range.")
    for (center, radius) in ranges {
      precondition(radius >= 0, "The radius of a range cannot be negative.")
      precondition(
        HexShape.hexagonStaysInRange(center: center, radius: radius),
        "The cells of a range must stay inside the supported coordinate range.")
    }
    let axialRanges = ranges.map { (q: $0.center.q, r: $0.center.r, radius: $0.radius) }
    guard let bounds = RangeIntersection(ranges: axialRanges) else { return [] }
    var hexes: [Hex] = []
    for r in bounds.rows {
      for q in bounds.columns(inRow: r) {
        hexes.append(Hex(q: q, r: r))
      }
    }
    return hexes
  }
}

/// The rows of an intersection of ranges and the columns of each row, found
/// from the bounds of `q`, `r` and `s` before any hex is listed.
///
/// Every range must lie inside the supported coordinate range, which
/// ``Hex/intersection(ofRanges:)`` checks first. Then every value here is a
/// bound or a sum of two values below `2^30` in magnitude, so it fits 32 bits:
/// the sum of three bounds is never taken, because it overflows a 32-bit `Int`
/// inside the supported range. The type is generic so that tests can run this
/// arithmetic in `Int32` on any machine; the library uses it with `Int`.
struct RangeIntersection<Coordinate: FixedWidthInteger & SignedInteger> {

  /// The rows of the intersection, `r` ascending; none of them is empty.
  let rows: ClosedRange<Coordinate>

  /// The bounds of `q` and `s` over all ranges.
  private let qMin: Coordinate
  private let qMax: Coordinate
  private let sMin: Coordinate
  private let sMax: Coordinate

  /// Intersects ranges given by the axial coordinates of their centers and
  /// their radii, or returns `nil` when they have no hex in common.
  init?(ranges: [(q: Coordinate, r: Coordinate, radius: Coordinate)]) {
    var qMin = Coordinate.min
    var qMax = Coordinate.max
    var rMin = Coordinate.min
    var rMax = Coordinate.max
    var sMin = Coordinate.min
    var sMax = Coordinate.max
    for range in ranges {
      let s = -range.q - range.r
      qMin = max(qMin, range.q - range.radius)
      qMax = min(qMax, range.q + range.radius)
      rMin = max(rMin, range.r - range.radius)
      rMax = min(rMax, range.r + range.radius)
      sMin = max(sMin, s - range.radius)
      sMax = min(sMax, s + range.radius)
    }
    guard qMin <= qMax, rMin <= rMax, sMin <= sMax else { return nil }
    // The rows are narrowed with sums of two bounds only. Every row between
    // these two holds at least one hex, so no row is walked in vain.
    let firstRow = max(rMin, -qMax - sMax)
    let lastRow = min(rMax, -qMin - sMin)
    guard firstRow <= lastRow else { return nil }
    rows = firstRow...lastRow
    self.qMin = qMin
    self.qMax = qMax
    self.sMin = sMin
    self.sMax = sMax
  }

  /// Returns the columns `q` of the hexes of the intersection in a row `r`.
  func columns(inRow r: Coordinate) -> ClosedRange<Coordinate> {
    max(qMin, -r - sMax)...min(qMax, -r - sMin)
  }
}
