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

  /// The forward matrix of the guide takes the axial coordinates of a hex to a
  /// pixel offset: `x = f0 * q + f1 * r`, `y = f2 * q + f3 * r`, before the
  /// offset is scaled by the cell size. This is the `q` term of `x`.
  var f0: Double {
    switch self {
    case .pointy: Self.squareRootOfThree
    case .flat: 3.0 / 2.0
    }
  }

  /// The `r` term of `x`; see ``f0``.
  var f1: Double {
    switch self {
    case .pointy: Self.squareRootOfThree / 2
    case .flat: 0
    }
  }

  /// The `q` term of `y`; see ``f0``.
  var f2: Double {
    switch self {
    case .pointy: 0
    case .flat: Self.squareRootOfThree / 2
    }
  }

  /// The `r` term of `y`; see ``f0``.
  var f3: Double {
    switch self {
    case .pointy: 3.0 / 2.0
    case .flat: Self.squareRootOfThree
    }
  }

  /// The backward matrix of the guide takes a pixel offset already divided by
  /// the cell size back to fractional axial coordinates: `q = b0 * x + b1 * y`,
  /// `r = b2 * x + b3 * y`. This is the `x` term of `q`.
  var b0: Double {
    switch self {
    case .pointy: Self.squareRootOfThree / 3
    case .flat: 2.0 / 3.0
    }
  }

  /// The `y` term of `q`; see ``b0``.
  var b1: Double {
    switch self {
    case .pointy: -1.0 / 3.0
    case .flat: 0
    }
  }

  /// The `x` term of `r`; see ``b0``.
  var b2: Double {
    switch self {
    case .pointy: 0
    case .flat: -1.0 / 3.0
    }
  }

  /// The `y` term of `r`; see ``b0``.
  var b3: Double {
    switch self {
    case .pointy: 2.0 / 3.0
    case .flat: Self.squareRootOfThree / 3
    }
  }
}
