/// One of the four offset coordinate systems of the guide.
///
/// The system is not part of a coordinate value: it is given at every conversion,
/// so the same ``OffsetCoordinate`` can be read in any system deliberately.
public enum OffsetSystem: String, CaseIterable, Hashable, Sendable, Codable {

  /// Odd rows shifted right; used with pointy-top grids.
  case oddR

  /// Even rows shifted right; used with pointy-top grids.
  case evenR

  /// Odd columns shifted down; used with flat-top grids.
  case oddQ

  /// Even columns shifted down; used with flat-top grids.
  case evenQ

  /// The grid orientation this system is meant for.
  public var orientation: Orientation {
    switch self {
    case .oddR, .evenR: .pointy
    case .oddQ, .evenQ: .flat
    }
  }
}

extension OffsetSystem {

  /// Whether the system shifts the even rows or columns rather than the odd ones.
  var shiftsEvenLines: Bool {
    self == .evenR || self == .evenQ
  }

  /// Whether the system shifts whole rows (the `r` systems) rather than whole
  /// columns (the `q` systems).
  var isRowSystem: Bool {
    self == .oddR || self == .evenR
  }

  /// The sign of the shift, as the guide's `EVEN` and `ODD` constants: `+1` for
  /// the `even` systems, `-1` for the `odd` ones.
  var offset: Int {
    shiftsEvenLines ? 1 : -1
  }

  /// Returns by how much the line with the given index is shifted: half of the
  /// index, corrected for the lines this system shifts.
  ///
  /// The sum under the division is always even, so the truncating division of
  /// Swift gives the same result as the flooring division of the reference.
  func shift(ofLine line: Int) -> Int {
    (line + offset * (line & 1)) / 2
  }
}
