import HexagonKit
import Observation

/// The settings every screen shares. Everything else, such as the map of a
/// diagram, its walls and the hex under the pointer, belongs to its screen, as
/// each diagram of the guide has its own.
@MainActor
@Observable
final class DemoSettings {
  /// The orientation of the diagrams that let the reader choose one; a single
  /// toggle switches all of them, as in the guide.
  var orientation = Orientation.pointy

  /// The largest size of a cell in points; a board shrinks its cells until the
  /// whole map fits into its view.
  var cellSize = 60.0
}
