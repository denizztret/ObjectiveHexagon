/// The orientation of the grid.
public enum Orientation: String, CaseIterable, Hashable, Sendable, Codable {

  /// Hexes with a corner at the top; rows run horizontally.
  case pointy

  /// Hexes with a flat edge at the top; columns run vertically.
  case flat
}
