import SwiftUI

/// A screen of the demo: a section of the guide, in the order of the guide.
/// The raw value names the screen in the launch argument `-screen`.
enum Page: String, CaseIterable, Identifiable {
  case geometry
  case coordinates
  case neighbors
  case distances
  case line
  case range
  case obstacles
  case rotation
  case rings
  case fieldOfView = "field-of-view"
  case pixel
  case shapes
  case wraparound
  case pathfinding
  case views
  #if os(iOS)
    case collection
  #endif

  var id: Self { self }

  /// The title in the list of screens, and the place in the guide of the
  /// diagrams the screen reproduces, relative to the main page of the guide.
  var entry: (title: String, link: String?) {
    switch self {
    case .geometry: ("Geometry", "#basics")
    case .coordinates: ("Coordinate systems", "#coordinates")
    case .neighbors: ("Neighbors", "#neighbors")
    case .distances: ("Distances", "#distances")
    case .line: ("Line drawing", "#line-drawing")
    case .range: ("Movement range", "#range")
    case .obstacles: ("Obstacles", "#range-obstacles")
    case .rotation: ("Rotation and reflection", "#rotation")
    case .rings: ("Rings", "#rings")
    case .fieldOfView: ("Field of view", "#field-of-view")
    case .pixel: ("Hex to pixel and back", "#hex-to-pixel")
    case .shapes: ("Map shapes", "implementation.html#shape-parallelogram")
    case .wraparound: ("Wraparound maps", "#wraparound")
    case .pathfinding: ("Pathfinding", "#pathfinding")
    case .views: ("Views on a grid", nil)
    #if os(iOS)
      case .collection: ("Collection view", nil)
    #endif
    }
  }

  /// The section of the guide, when the screen reproduces one.
  var guide: URL? {
    entry.link.flatMap { URL(string: "https://www.redblobgames.com/grids/hexagons/\($0)") }
  }

  /// The screen, in the state the launch arguments give it.
  @MainActor @ViewBuilder
  func screen(_ opening: Opening) -> some View {
    switch self {
    case .geometry: GeometryScreen(opening)
    case .coordinates: CoordinatesScreen(opening)
    case .neighbors: NeighborsScreen(opening)
    case .distances: DistancesScreen(opening)
    case .line: LineScreen(opening)
    case .range: RangeScreen(opening)
    case .obstacles: ObstaclesScreen(opening)
    case .rotation: RotationScreen(opening)
    case .rings: RingsScreen(opening)
    case .fieldOfView: FieldOfViewScreen(opening)
    case .pixel: PixelScreen(opening)
    case .shapes: ShapesScreen(opening)
    case .wraparound: WraparoundScreen(opening)
    case .pathfinding: PathfindingScreen(opening)
    case .views: ViewsScreen()
    #if os(iOS)
      case .collection: CollectionScreen()
    #endif
    }
  }
}
