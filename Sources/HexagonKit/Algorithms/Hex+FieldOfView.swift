extension Hex {

  /// Returns the hexes visible from this hex within `radius` steps.
  ///
  /// This is the simple method the guide recommends: a line, as drawn by
  /// ``line(to:)``, goes from this hex to every hex of ``range(radius:)``, and
  /// the target is visible when no hex strictly between the two ends of its
  /// line is opaque. An opaque hex is therefore visible itself and hides the
  /// hexes whose lines pass through it. The observer is always visible; neither
  /// its own opacity nor that of a target is consulted for that target's line. A
  /// radius of zero yields only the observer.
  ///
  /// Visibility is not promised to be mutual. It is mutual for two hexes whose
  /// lines to each other pass through the same hexes, and ``line(to:)`` does
  /// not promise that either.
  ///
  /// Every hex within `radius` is a target, whether or not it belongs to your
  /// map, and lines may cross hexes outside the map; `isOpaque` is asked about
  /// those too. Answer `true` where lines must not pass, and intersect the
  /// result with the map when only its cells matter. `isOpaque` may be called
  /// several times for the same hex, and in any order, so it should give the
  /// same answer every time and have no side effects.
  ///
  /// The work grows as the cube of the radius: there are about `3 * radius * radius`
  /// targets, and each line has up to `radius + 1` hexes.
  ///
  /// - Precondition: `radius >= 0`, and the cell count and all cell coordinates
  ///   are representable, as for ``HexShape/hexagon(center:radius:)``.
  public func fieldOfView(radius: Int, isOpaque: (Hex) -> Bool) -> Set<Hex> {
    var visible: Set<Hex> = []
    for target in range(radius: radius) {
      // The hexes strictly between the ends are the samples `1..<distance`; a
      // stride, unlike a range, stays empty when the target is the observer.
      let line = LineSamples(from: self, to: target)
      let isHidden = stride(from: 1, to: line.distance, by: 1).contains {
        isOpaque(line.hex(at: $0))
      }
      if !isHidden {
        visible.insert(target)
      }
    }
    return visible
  }
}
