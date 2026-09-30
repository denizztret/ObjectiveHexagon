#if canImport(SwiftUI) && _pointerBitWidth(_64)
  import HexagonKit
  import HexagonKitUI
  import SwiftUI

  /// One element of a path, with its point as a point of the core.
  enum PathElement: Equatable {
    case move(Point)
    case line(Point)
    case close
    case curve
  }

  /// Returns the elements of a path in order.
  func elements(of path: Path) -> [PathElement] {
    var elements: [PathElement] = []
    // A path is not a sequence: its elements come only through `forEach`.
    // swift-format-ignore: ReplaceForEachWithForLoop
    path.forEach { element in
      switch element {
      case .move(let point): elements.append(.move(Point(point)))
      case .line(let point): elements.append(.line(Point(point)))
      case .closeSubpath: elements.append(.close)
      case .quadCurve, .curve: elements.append(.curve)
      }
    }
    return elements
  }

  /// Returns the points of the elements of a path that have one.
  func points(of path: Path) -> [Point] {
    elements(of: path).compactMap { element in
      switch element {
      case .move(let point), .line(let point): point
      case .close, .curve: nil
      }
    }
  }
#endif
