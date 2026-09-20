/// The orientation of the grid.
public enum Orientation: String, CaseIterable, Hashable, Sendable, Codable {

  /// Hexes with a corner at the top; rows run horizontally.
  case pointy

  /// Hexes with a flat edge at the top; columns run vertically.
  case flat
}

extension Orientation {

  /// The square root of three, the only irrational number the geometry of the
  /// grid needs; the guide writes it as `sqrt(3)`.
  static let squareRootOfThree = 3.0.squareRoot()

  /// One of the two-by-two matrices of the guide, in its order: `m0` and `m1`
  /// are the terms of the first output, `m2` and `m3` those of the second.
  struct Matrix {
    let m0: Double
    let m1: Double
    let m2: Double
    let m3: Double
  }

  /// The forward matrix of the guide, its `f0` through `f3`. It takes the axial
  /// coordinates of a hex to a pixel offset: `x = m0 * q + m1 * r` and
  /// `y = m2 * q + m3 * r`, before the offset is scaled by the cell size.
  var forward: Matrix {
    switch self {
    case .pointy:
      Matrix(m0: Self.squareRootOfThree, m1: Self.squareRootOfThree / 2, m2: 0, m3: 3.0 / 2.0)
    case .flat:
      Matrix(m0: 3.0 / 2.0, m1: 0, m2: Self.squareRootOfThree / 2, m3: Self.squareRootOfThree)
    }
  }

  /// The backward matrix of the guide, its `b0` through `b3`. It takes a pixel
  /// offset already divided by the cell size back to fractional axial
  /// coordinates: `q = m0 * x + m1 * y` and `r = m2 * x + m3 * y`.
  var backward: Matrix {
    switch self {
    case .pointy:
      Matrix(m0: Self.squareRootOfThree / 3, m1: -1.0 / 3.0, m2: 0, m3: 2.0 / 3.0)
    case .flat:
      Matrix(m0: 2.0 / 3.0, m1: 0, m2: -1.0 / 3.0, m3: Self.squareRootOfThree / 3)
    }
  }
}
