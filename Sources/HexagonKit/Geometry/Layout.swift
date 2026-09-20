/// The mapping between hexes and pixels: orientation, cell size along both axes
/// and the pixel position of the origin hex.
public struct Layout: Hashable, Sendable, Codable {

  /// The orientation of the grid.
  public let orientation: Orientation

  /// The cell size along the x and y axes; both components must be finite and positive.
  public let size: Point

  /// The pixel position of `Hex.zero`.
  public let origin: Point

  /// Creates a layout.
  ///
  /// - Precondition: both components of `size` are finite and greater than zero,
  ///   and both components of `origin` are finite.
  public init(orientation: Orientation, size: Point, origin: Point = .zero) {
    if let reason = Self.rejectionReason(size: size, origin: origin) {
      preconditionFailure(reason)
    }
    self.orientation = orientation
    self.size = size
    self.origin = origin
  }

  /// Decodes a layout, failing when the size or the origin is out of range.
  public init(from decoder: any Decoder) throws {
    // The ranges are properties of the value, so they are checked here: the
    // synthesized decoder would accept any numbers and the initializer would trap.
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let orientation = try container.decode(Orientation.self, forKey: .orientation)
    let size = try container.decode(Point.self, forKey: .size)
    let origin = try container.decode(Point.self, forKey: .origin)
    if let reason = Self.rejectionReason(size: size, origin: origin) {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: container.codingPath, debugDescription: reason))
    }
    self.orientation = orientation
    self.size = size
    self.origin = origin
  }

  /// Returns the pixel position of the center of a hex.
  public func center(of hex: Hex) -> Point {
    // Written in the order of the reference: the linear combination first, then
    // the cell size, then the origin. An algebraically equal form differs in the
    // last bits and drifts from the reference fixtures.
    let forward = orientation.forward
    let q = Double(hex.q)
    let r = Double(hex.r)
    return Point(
      x: (forward.m0 * q + forward.m1 * r) * size.x + origin.x,
      y: (forward.m2 * q + forward.m3 * r) * size.y + origin.y)
  }

  /// Returns one corner of a hex, numbered as in the guide's text.
  ///
  /// - Precondition: `index` is in `0...5`.
  public func corner(of hex: Hex, at index: Int) -> Point {
    precondition(0 <= index && index <= 5, "A hex has six corners, numbered 0 through 5.")
    let center = center(of: hex)
    let unit = Self.cornerOffsets(of: orientation)[index]
    return Point(x: center.x + unit.x * size.x, y: center.y + unit.y * size.y)
  }

  /// Returns the six corners of a hex, in corner order.
  public func corners(of hex: Hex) -> [Point] {
    (0...5).map { corner(of: hex, at: $0) }
  }

  /// Returns the fractional hex that contains a pixel position.
  public func hex(at point: Point) -> FractionalHex {
    let backward = orientation.backward
    let x = (point.x - origin.x) / size.x
    let y = (point.y - origin.y) / size.y
    return FractionalHex(
      q: backward.m0 * x + backward.m1 * y,
      r: backward.m2 * x + backward.m3 * y)
  }

  /// The width of one cell, in pixels.
  public var cellWidth: Double {
    switch orientation {
    case .pointy: Orientation.squareRootOfThree * size.x
    case .flat: 2 * size.x
    }
  }

  /// The height of one cell, in pixels.
  public var cellHeight: Double {
    switch orientation {
    case .pointy: 2 * size.y
    case .flat: Orientation.squareRootOfThree * size.y
    }
  }

  /// The horizontal distance between the centers of adjacent columns.
  public var horizontalSpacing: Double {
    switch orientation {
    case .pointy: Orientation.squareRootOfThree * size.x
    case .flat: 3.0 / 2.0 * size.x
    }
  }

  /// The vertical distance between the centers of adjacent rows.
  public var verticalSpacing: Double {
    switch orientation {
    case .pointy: 3.0 / 2.0 * size.y
    case .flat: Orientation.squareRootOfThree * size.y
    }
  }
}

extension Layout {

  /// Returns why the given size and origin do not describe a layout, or `nil`
  /// when they do.
  ///
  /// The initializer and the decoder share this check, so the layouts the
  /// initializer traps on are exactly the ones the decoder rejects.
  private static func rejectionReason(size: Point, origin: Point) -> String? {
    guard size.x.isFinite, size.y.isFinite, size.x > 0, size.y > 0 else {
      return "the cell size must be finite and greater than zero along both axes"
    }
    guard origin.x.isFinite, origin.y.isFinite else {
      return "the origin must be finite along both axes"
    }
    return nil
  }

  /// Half of the square root of three, the only irrational number in the corner table.
  private static let halfSquareRootOfThree = Orientation.squareRootOfThree / 2

  /// The unit offsets of the six corners of a pointy cell from its center, in
  /// corner order. The table follows the guide's text, where corner `i` sits at
  /// `60 * i + 30` degrees, so the corners need no trigonometry.
  private static let pointyCornerOffsets: [Point] = [
    Point(x: halfSquareRootOfThree, y: 0.5),
    Point(x: 0, y: 1),
    Point(x: -halfSquareRootOfThree, y: 0.5),
    Point(x: -halfSquareRootOfThree, y: -0.5),
    Point(x: 0, y: -1),
    Point(x: halfSquareRootOfThree, y: -0.5),
  ]

  /// The unit offsets of the six corners of a flat cell, where corner `i` sits
  /// at `60 * i` degrees; see ``pointyCornerOffsets``.
  private static let flatCornerOffsets: [Point] = [
    Point(x: 1, y: 0),
    Point(x: 0.5, y: halfSquareRootOfThree),
    Point(x: -0.5, y: halfSquareRootOfThree),
    Point(x: -1, y: 0),
    Point(x: -0.5, y: -halfSquareRootOfThree),
    Point(x: 0.5, y: -halfSquareRootOfThree),
  ]

  /// Returns the corner table of an orientation.
  private static func cornerOffsets(of orientation: Orientation) -> [Point] {
    switch orientation {
    case .pointy: pointyCornerOffsets
    case .flat: flatCornerOffsets
    }
  }
}
