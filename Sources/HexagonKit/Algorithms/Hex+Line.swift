extension Hex {

  /// Returns the hexes on the straight line from this hex to another, both ends
  /// included.
  ///
  /// As in the guide, the line takes `N + 1` evenly spaced samples, where `N` is
  /// the distance between the two hexes, and rounds each one with
  /// ``FractionalHex/rounded()``. Both ends are first nudged by
  /// `(1e-6, 2e-6, -3e-6)`, the offset the text of the guide recommends to push
  /// samples off the edges between hexes.
  ///
  /// The line has `distance(to: other) + 1` hexes, starts with this hex and ends
  /// with `other`; a line from a hex to itself is `[self]`. Consecutive hexes
  /// are not promised to be adjacent: on long lines with large coordinates, the
  /// rounding of `Double` can put two of them two steps apart. The line may also
  /// leave out a hex that the segment between the centers only grazes. The whole
  /// array is allocated at once.
  public func line(to other: Hex) -> [Hex] {
    let samples = LineSamples(from: self, to: other)
    return (0...samples.distance).map(samples.hex(at:))
  }
}

/// The samples of the line between two hexes, each rounded on its own.
///
/// ``Hex/line(to:)`` and the field of view both draw their lines here, so they
/// agree bit for bit, and one sample of a line far too long for an array can
/// still be computed.
struct LineSamples {

  /// The distance between the two ends; the samples are numbered `0...distance`.
  let distance: Int

  /// The first end, nudged.
  private let start: FractionalHex

  /// The last end, nudged.
  private let end: FractionalHex

  /// The step of the interpolation parameter between two samples.
  private let step: Double

  /// Prepares the samples of the line from one hex to another.
  init(from start: Hex, to end: Hex) {
    distance = start.distance(to: end)
    self.start = Self.nudged(start)
    self.end = Self.nudged(end)
    // `max` keeps a line from a hex to itself away from a division by zero, as
    // on the implementation page of the guide.
    step = 1.0 / Double(max(distance, 1))
  }

  /// Returns the sample at `index`, rounded to a hex.
  func hex(at index: Int) -> Hex {
    // The parameter is `step * index`, not `index / distance`: the two differ in
    // the last bit, and the fixtures follow this order of operations.
    start.lerp(to: end, t: step * Double(index)).rounded()
  }

  /// Returns a hex nudged by the offset the text of the guide recommends.
  private static func nudged(_ hex: Hex) -> FractionalHex {
    FractionalHex(q: Double(hex.q) + 1e-6, r: Double(hex.r) + 2e-6, s: Double(hex.s) - 3e-6)
  }
}
