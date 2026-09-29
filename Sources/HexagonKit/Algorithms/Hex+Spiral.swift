extension Hex {

  /// Returns this hex followed by the rings of radius 1 through `radius` around it.
  ///
  /// This is the guide's spiral: `[self] + ring(radius: 1) + ... + ring(radius: radius)`,
  /// each ring in the order of ``ring(radius:)``. The outer ring is included,
  /// so there are `1 + 3 * radius * (radius + 1)` hexes, and the hex at position
  /// `i` is `Hex(spiralIndex: i, around: self)`. The whole array is allocated at
  /// once, so a large radius needs a matching amount of memory.
  ///
  /// - Precondition: `radius >= 0`, and the cell count and all cell coordinates
  ///   are representable, as for ``HexShape/hexagon(center:radius:)``.
  public func spiral(radius: Int) -> [Hex] {
    // The shape runs the very check of the hexagon, so the spiral, the range and
    // the field of view refuse the same radii, and it also counts the cells.
    let count = HexShape.hexagon(center: self, radius: radius).count
    var hexes: [Hex] = []
    hexes.reserveCapacity(count)
    hexes.append(self)
    for ringRadius in stride(from: 1, through: radius, by: 1) {
      hexes.append(contentsOf: ring(radius: ringRadius))
    }
    return hexes
  }

  /// Returns the position of this hex in the spiral around a center.
  ///
  /// The center has index 0, and the ring of radius `k >= 1` takes the indices
  /// from `1 + 3 * k * (k - 1)` through `3 * k * (k + 1)` in the order of
  /// ``ring(radius:)``, as in the guide. The position is computed directly, in
  /// constant time, without building the ring.
  ///
  /// The index grows as the square of the distance to the center, and the method
  /// stops on the overflow of `Int` when the index does not fit. It fits for
  /// every hex up to 26754 steps from the center on a 32-bit platform, and for
  /// every hex less than `Hex.coordinateBound` steps from it on a 64-bit one.
  public func spiralIndex(around center: Hex = .zero) -> Int {
    let offset = self - center
    let radius = offset.length
    guard radius > 0 else { return 0 }
    // The ring starts at the corner `radius * direction 4` and runs along the
    // directions 0...5 in turn; `side` is the direction of the segment that holds
    // the hex, `position` its step along that segment. Each segment holds the
    // corner it starts from and leaves out the corner it ends at.
    let side: Int
    let position: Int
    if offset.r == radius && offset.q < 0 {
      (side, position) = (0, offset.q + radius)
    } else if offset.s == -radius && offset.q < radius {
      (side, position) = (1, offset.q)
    } else if offset.q == radius && offset.r > -radius {
      (side, position) = (2, -offset.r)
    } else if offset.r == -radius && offset.q > 0 {
      (side, position) = (3, radius - offset.q)
    } else if offset.s == radius && offset.q > -radius {
      (side, position) = (4, -offset.q)
    } else {
      (side, position) = (5, offset.r)
    }
    return Self.spiralIndex(radius: radius, side: side, position: position)
  }

  /// Creates the hex at a position of the spiral around a center.
  ///
  /// This is the inverse of ``spiralIndex(around:)``:
  /// `Hex(spiralIndex: hex.spiralIndex(around: center), around: center) == hex`.
  /// It takes constant time and does not build the ring.
  ///
  /// - Precondition: `spiralIndex >= 0`.
  public init(spiralIndex: Int, around center: Hex = .zero) {
    precondition(spiralIndex >= 0, "A spiral index cannot be negative.")
    guard spiralIndex > 0 else {
      self = center
      return
    }
    let (radius, side, position) = Self.spiralPlace(of: spiralIndex)
    // The corner where segment `side` starts is `radius` steps along direction
    // `side + 4`; the segment itself runs along direction `side`.
    let corner = HexDirection.allCases[(side + 4) % 6].vector * radius
    let offset = corner + HexDirection.allCases[side].vector * position
    self = offset + center
  }

  /// Returns the spiral index of the hex `position` steps along segment
  /// `side` of the ring of radius `radius >= 1`.
  ///
  /// Every intermediate value stays below the index itself, so the sum stops on
  /// an overflow exactly when the index does not fit. Generic so that tests can
  /// run the arithmetic of a 32-bit platform in `Int32` on any machine.
  static func spiralIndex<T: FixedWidthInteger & SignedInteger>(
    radius: T, side: T, position: T
  ) -> T {
    1 + 3 * radius * (radius - 1) + side * radius + position
  }

  /// Returns the ring, the segment and the step along it of a spiral index
  /// `>= 1`: the inverse of ``spiralIndex(radius:side:position:)``.
  static func spiralPlace<T: FixedWidthInteger & SignedInteger>(
    of index: T
  ) -> (radius: T, side: T, position: T) {
    let radius = spiralRadius(of: index)
    // The ring starts at or before the index, so the difference fits, and it
    // is below `6 * radius`, the size of the ring.
    let steps = index - (1 + 3 * radius * (radius - 1))
    return (radius, steps / radius, steps % radius)
  }

  /// Returns the index of the first hex of the ring of a radius `>= 1`,
  /// `1 + 3 * radius * (radius - 1)`, or `nil` when it does not fit `T`.
  private static func checkedSpiralRingStart<T: FixedWidthInteger & SignedInteger>(
    _ radius: T
  ) -> T? {
    let (triple, tripleOverflow) = radius.multipliedReportingOverflow(by: 3)
    let (product, productOverflow) = triple.multipliedReportingOverflow(by: radius - 1)
    let (start, startOverflow) = product.addingReportingOverflow(1)
    return tripleOverflow || productOverflow || startOverflow ? nil : start
  }

  /// Returns the radius of the ring that holds a spiral index `>= 1`.
  ///
  /// The guide solves `index = 1 + 3 * radius * (radius - 1)` as
  /// `floor((sqrt(12 * index - 3) + 3) / 6)`. That is exact in `Double` only up
  /// to the radius 44739242, and `12 * index` overflows long before the index
  /// does, so the root only gives an estimate here, computed in `Double`, and
  /// exact integer arithmetic moves it to the right ring.
  private static func spiralRadius<T: FixedWidthInteger & SignedInteger>(of index: T) -> T {
    /// Whether the ring of a radius starts after the index; a start that does
    /// not even fit `T` certainly does.
    func ringStartsAfterIndex(_ radius: T) -> Bool {
      guard let start = checkedSpiralRingStart(radius) else { return true }
      return start > index
    }
    let estimate = ((12 * Double(index) - 3).squareRoot() + 3) / 6
    var radius = max(T(estimate.rounded(.down)), 1)
    while ringStartsAfterIndex(radius) {
      radius -= 1
    }
    while !ringStartsAfterIndex(radius + 1) {
      radius += 1
    }
    return radius
  }
}
