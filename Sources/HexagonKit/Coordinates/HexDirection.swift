/// One of the six directions to an adjacent hex, in the order used by the guide.
///
/// The raw value is the direction index 0...5 of the guide, so it can be stored
/// and compared across implementations. Case names describe the cube axes the
/// step changes; compass names depend on the orientation and live in
/// ``HexDirection/Pointy`` and ``HexDirection/Flat``.
public enum HexDirection: Int, CaseIterable, Hashable, Sendable, Codable {

  /// Index 0: `Hex(q: 1, r: 0)`, the step `+q -s`.
  case plusQMinusS = 0
  /// Index 1: `Hex(q: 1, r: -1)`, the step `+q -r`.
  case plusQMinusR = 1
  /// Index 2: `Hex(q: 0, r: -1)`, the step `+s -r`.
  case plusSMinusR = 2
  /// Index 3: `Hex(q: -1, r: 0)`, the step `+s -q`.
  case plusSMinusQ = 3
  /// Index 4: `Hex(q: -1, r: 1)`, the step `+r -q`.
  case plusRMinusQ = 4
  /// Index 5: `Hex(q: 0, r: 1)`, the step `+r -s`.
  case plusRMinusS = 5

  /// The unit step of this direction.
  public var vector: Hex {
    switch self {
    case .plusQMinusS: Hex(q: 1, r: 0)
    case .plusQMinusR: Hex(q: 1, r: -1)
    case .plusSMinusR: Hex(q: 0, r: -1)
    case .plusSMinusQ: Hex(q: -1, r: 0)
    case .plusRMinusQ: Hex(q: -1, r: 1)
    case .plusRMinusS: Hex(q: 0, r: 1)
    }
  }
}

extension HexDirection {

  /// Compass names of the directions on a pointy-top grid.
  public enum Pointy {
    /// Index 0, pointing right.
    public static let east = HexDirection.plusQMinusS
    /// Index 1.
    public static let northeast = HexDirection.plusQMinusR
    /// Index 2.
    public static let northwest = HexDirection.plusSMinusR
    /// Index 3, pointing left.
    public static let west = HexDirection.plusSMinusQ
    /// Index 4.
    public static let southwest = HexDirection.plusRMinusQ
    /// Index 5.
    public static let southeast = HexDirection.plusRMinusS
  }

  /// Compass names of the directions on a flat-top grid.
  public enum Flat {
    /// Index 0.
    public static let southeast = HexDirection.plusQMinusS
    /// Index 1.
    public static let northeast = HexDirection.plusQMinusR
    /// Index 2, pointing straight up.
    public static let north = HexDirection.plusSMinusR
    /// Index 3.
    public static let northwest = HexDirection.plusSMinusQ
    /// Index 4.
    public static let southwest = HexDirection.plusRMinusQ
    /// Index 5, pointing straight down.
    public static let south = HexDirection.plusRMinusS
  }
}
