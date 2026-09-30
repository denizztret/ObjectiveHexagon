import HexagonKit

/// The walls of the diagrams of the guide, the same as in the tests of
/// HexagonKit.
enum GuideWalls {
  /// The movement-range and pathfinding diagrams: a hexagon of radius 5.
  static let movement: Set<Hex> = [
    Hex(q: 2, r: -1), Hex(q: 2, r: 0), Hex(q: 0, r: 2), Hex(q: -1, r: 2), Hex(q: -1, r: 1),
    Hex(q: 1, r: -1), Hex(q: 1, r: 2), Hex(q: 1, r: -3), Hex(q: 0, r: -2), Hex(q: -1, r: -1),
    Hex(q: 2, r: 1), Hex(q: -2, r: 1), Hex(q: -3, r: 2), Hex(q: -4, r: 3), Hex(q: -5, r: 4),
  ]

  /// The field-of-view diagram: a hexagon of radius 8.
  static let fieldOfView: Set<Hex> = [
    Hex(q: 3, r: -3), Hex(q: 2, r: -3), Hex(q: 1, r: -3), Hex(q: -2, r: 0), Hex(q: -3, r: 0),
    Hex(q: -3, r: 2), Hex(q: -4, r: 2), Hex(q: -3, r: 3), Hex(q: -3, r: 4), Hex(q: 0, r: 2),
    Hex(q: 0, r: 3), Hex(q: 0, r: 4), Hex(q: 0, r: 5), Hex(q: 0, r: -3), Hex(q: 0, r: -4),
    Hex(q: 0, r: -5), Hex(q: 0, r: -6), Hex(q: 4, r: 2), Hex(q: 3, r: 3), Hex(q: -5, r: 2),
    Hex(q: -4, r: 0), Hex(q: -5, r: 0), Hex(q: -6, r: 0), Hex(q: -7, r: 0), Hex(q: -8, r: 0),
  ]
}
