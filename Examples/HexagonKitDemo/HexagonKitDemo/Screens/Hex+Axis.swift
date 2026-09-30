import HexagonKit

extension Hex {
  /// The coordinate along an axis: `q`, `r` or `s`.
  subscript(axis: HexAxis) -> Int {
    switch axis {
    case .q: q
    case .r: r
    case .s: s
    }
  }
}
