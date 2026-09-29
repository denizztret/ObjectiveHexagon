/// One of the six diagonal directions, in the order used by the guide.
///
/// A diagonal step changes one cube coordinate by 2 and the other two by 1 the
/// other way, so it reaches a hex two steps away. Diagonal `i` lies between the
/// directions `i` and `i + 1`: its vector is the sum of theirs, and the hex it
/// reaches is adjacent to both of those neighbors. The raw value is the diagonal
/// index 0...5 of the guide; case names give the cube axis that changes by 2.
public enum HexDiagonal: Int, CaseIterable, Hashable, Sendable, Codable {

  /// Index 0: `Hex(q: 2, r: -1)`, the step `+2q`.
  case plusQ = 0
  /// Index 1: `Hex(q: 1, r: -2)`, the step `-2r`.
  case minusR = 1
  /// Index 2: `Hex(q: -1, r: -1)`, the step `+2s`.
  case plusS = 2
  /// Index 3: `Hex(q: -2, r: 1)`, the step `-2q`.
  case minusQ = 3
  /// Index 4: `Hex(q: -1, r: 2)`, the step `+2r`.
  case plusR = 4
  /// Index 5: `Hex(q: 1, r: 1)`, the step `-2s`.
  case minusS = 5

  /// The step of this diagonal.
  public var vector: Hex {
    switch self {
    case .plusQ: Hex(q: 2, r: -1)
    case .minusR: Hex(q: 1, r: -2)
    case .plusS: Hex(q: -1, r: -1)
    case .minusQ: Hex(q: -2, r: 1)
    case .plusR: Hex(q: -1, r: 2)
    case .minusS: Hex(q: 1, r: 1)
    }
  }
}

extension Hex {

  /// Returns the hex one diagonal step away in the given diagonal direction.
  public func diagonalNeighbor(_ diagonal: HexDiagonal) -> Hex {
    self + diagonal.vector
  }

  /// The six diagonal neighbors, in the order of the guide's diagonal indices.
  public var diagonalNeighbors: [Hex] {
    HexDiagonal.allCases.map(diagonalNeighbor)
  }
}
