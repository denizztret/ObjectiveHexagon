// The inputs and the unit of tolerance the numeric tests share. The tolerances
// of HexagonKitUI hold where the geometry is representable, which needs
// `CGFloat` to be `Double`, so these tests exist only on 64-bit platforms.
#if canImport(CoreGraphics) && _pointerBitWidth(_64)
  import HexagonKit

  /// The grid of the numeric model the tolerances of HexagonKitUI were derived
  /// on: 64 layouts, each with the same hexes near zero and far away.
  enum ModelGrid {

    /// Both orientations, eight sizes, among them unequal and tiny ones, and
    /// four origins, among them a large one.
    static let layouts: [HexLayout] = Orientation.allCases.flatMap { orientation in
      sizes.flatMap { size in
        origins.map { HexLayout(orientation: orientation, size: size, origin: $0) }
      }
    }

    static let sizes = [
      Point(x: 10, y: 10), Point(x: 10, y: 14), Point(x: 0.1, y: 3.7), Point(x: 1e-3, y: 1e3),
      Point(x: 123.456, y: 7.89), Point(x: 25, y: 25), Point(x: 100 / 3.0.squareRoot(), y: 50),
      Point(x: 0.001, y: 1),
    ]

    static let origins = [
      Point(x: 0, y: 0), Point(x: 35, y: 71), Point(x: -1e6, y: 3e5), Point(x: 0.1, y: -0.3),
    ]

    /// The hexagon of radius 20 around zero.
    static let near = HexShape.hexagon(radius: 20).cells()

    /// Hexes far from zero, up to `2^29`.
    static let far = [
      Hex(q: 1 << 29, r: 0), Hex(q: -(1 << 29), r: 1 << 29), Hex(q: 1_000_003, r: -7),
      Hex(q: -123_457, r: 98_765),
    ]

    /// Every hex of the grid: 1265 of them.
    static let hexes = near + far

    /// The hexes the bounds of pairs are anchored on.
    static let anchors = [Hex(q: -19, r: 0), Hex.zero, Hex(q: 20, r: -20)]
  }

  /// The difference of two values in units of the last place of a magnitude.
  func ulps(_ a: Double, _ b: Double, of magnitude: Double) -> Double {
    a == b ? 0 : abs(a - b) / abs(magnitude).ulp
  }
#endif
