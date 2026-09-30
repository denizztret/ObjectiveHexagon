import SwiftUI

/// A screen of the demo: a section of the guide, in the order of the guide.
/// The raw value names the screen in the launch argument `-screen`.
enum Page: String, CaseIterable, Identifiable {
  case geometry
  case coordinates
  case neighbors
  case distances
  case rotation
  case rings
  case pixel

  var id: Self { self }

  /// The title in the list of screens, and the place in the guide of the
  /// diagrams the screen reproduces, relative to the main page of the guide.
  var entry: (title: String, link: String?) {
    switch self {
    case .geometry: ("Geometry", "#basics")
    case .coordinates: ("Coordinate systems", "#coordinates")
    case .neighbors: ("Neighbors", "#neighbors")
    case .distances: ("Distances", "#distances")
    case .rotation: ("Rotation and reflection", "#rotation")
    case .rings: ("Rings", "#rings")
    case .pixel: ("Hex to pixel and back", "#hex-to-pixel")
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
    case .rotation: RotationScreen(opening)
    case .rings: RingsScreen(opening)
    case .pixel: PixelScreen(opening)
    }
  }
}
