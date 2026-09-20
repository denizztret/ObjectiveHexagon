/// One of the two doubled coordinate systems of the guide.
public enum DoubledSystem: String, CaseIterable, Hashable, Sendable, Codable {

  /// Columns doubled; used with pointy-top grids (the guide's `rdoubled`).
  case doubleWidth

  /// Rows doubled; used with flat-top grids (the guide's `qdoubled`).
  case doubleHeight

  /// The grid orientation this system is meant for.
  public var orientation: Orientation {
    switch self {
    case .doubleWidth: .pointy
    case .doubleHeight: .flat
    }
  }
}
