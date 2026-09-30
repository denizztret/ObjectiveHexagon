# HexagonKit

Hexagonal grid math for Swift, built on the standard library alone.

HexagonKit is a rewrite of ObjectiveHexagon in pure Swift, distributed through
Swift Package Manager. It follows the guide to hexagonal grids by Amit Patel at
[Red Blob Games](https://www.redblobgames.com/grids/hexagons/): the same terms,
the same algorithms, and the reference tests of the guide ported one to one.

## Status

**Alpha.** The core and the algorithms of the guide are in place: coordinates
in six systems, directions and diagonals, distance, rotation and reflection,
rings and spirals, rounding, the hex-to-pixel layout, map shapes, lines,
movement ranges with and without obstacles, field of view, pathfinding, dense
storage and wraparound maps. The `HexagonKitUI` module bridges them to Core
Graphics, SwiftUI and UIKit, and a demo application draws the diagrams of the
guide with it. The documentation articles are still to come. This is a
pre-release: the API may still change
before 1.0, and there is no tagged version yet. The first one will be tagged
once the repository has been renamed to HexagonKit, so that the package name in
your manifest stays put.

## Requirements

- Swift 6.0 or newer, Swift 6 language mode
- iOS 15, macOS 12, tvOS 15, watchOS 8, visionOS 1, or Linux
- No dependencies

`HexagonKitUI` has the same requirements. `HexGridLayout` needs iOS 16, macOS
13, tvOS 16 or watchOS 9, `HexCollectionViewLayout` exists on iOS, tvOS and
visionOS, and on Linux the module is empty.

## Installation

Until the first version is tagged, depend on the development branch. Add the
package to `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/denizztret/ObjectiveHexagon.git", branch: "master")
]
```

and the libraries to your target; `HexagonKitUI` is needed only for drawing:

```swift
.target(
  name: "MyApp",
  dependencies: [
    .product(name: "HexagonKit", package: "ObjectiveHexagon"),
    .product(name: "HexagonKitUI", package: "ObjectiveHexagon"),
  ])
```

In Xcode: File > Add Package Dependencies, paste the repository URL, and pick
the `master` branch.

## A first look

```swift
import HexagonKit

// Cells are stored in axial coordinates; the third cube coordinate is derived.
let a = Hex(q: 0, r: 0)
let b = Hex(q: 2, r: -1)
print(a.distance(to: b))          // 2
print(a.neighbor(.plusQMinusS))   // the cell to the east on a pointy-top grid

// A ring of cells at exactly two steps.
print(a.ring(radius: 2).count)    // 12

// From a cell to a pixel and back.
let layout = HexLayout(orientation: .pointy, size: Point(x: 20, y: 20))
let center = layout.center(of: b)
print(layout.hex(at: center).rounded() == b)   // true

// The same cell read in an offset system, and in a doubled one.
print(OffsetCoordinate(b, in: .oddR))
print(DoubledCoordinate(b, in: .doubleWidth))

// A map shape numbers its cells, so they can be stored in an array.
let map = HexShape.hexagon(radius: 3)
print(map.count, map.index(of: b) as Any)

// The algorithms of the guide are methods of a cell.
print(a.line(to: b).count)        // 3
let walls: Set<Hex> = [Hex(q: 1, r: 0)]
print(a.path(to: b) { _, next in walls.contains(next) ? nil : 1 }?.count ?? 0)   // 3
```

## Drawing with HexagonKitUI

`HexagonKitUI` has no geometry of its own: every point, rectangle and path
comes from the `HexLayout` of the core, in the coordinate space of SwiftUI and
UIKit, whose y axis points down. Import both modules.

```swift
import HexagonKit
import HexagonKitUI
import SwiftUI

// A board on a canvas; a tap selects the hex under the finger.
@available(iOS 17.0, macOS 14.0, *)
struct Board: View {
  let layout = HexLayout(
    orientation: .pointy, size: Point(x: 24, y: 24), origin: Point(x: 200, y: 200))
  let cells = HexShape.hexagon(radius: 3).cells()
  @State private var selected: Hex?

  var body: some View {
    Canvas { context, _ in
      for hex in cells {
        context.fill(layout.path(of: hex), with: .color(hex == selected ? .yellow : .white))
      }
      context.stroke(layout.path(of: cells), with: .color(.gray))
    }
    .frame(width: 400, height: 400)
    .onTapGesture { location in
      let hex = layout.hex(at: location).rounded()
      selected = cells.contains(hex) ? hex : nil
    }
  }
}
```

`Hexagon` draws one cell in any rectangle, `HexGridLayout` places SwiftUI views
on hexes, and `HexCollectionViewLayout` places the items of a collection view.
`layout.frame(of:)` and `layout.bounds(of:)` give the rectangles of a cell and of
a board.

## The demo

`Examples/HexagonKitDemo` is a SwiftUI application for iOS 17 and macOS 14 that
draws the diagrams of the guide with HexagonKit and HexagonKitUI: geometry,
coordinate systems, neighbors, distances, lines, movement ranges, obstacles,
rotation and reflection, rings and spirals, field of view, hex to pixel and
back, map shapes, wraparound maps and pathfinding. The board of the Objective-C
demo is there twice: as SwiftUI views in `HexGridLayout` on every platform, and
on iOS as the collection view it was. Open `Examples/HexagonKitDemo/HexagonKitDemo.xcodeproj`
in Xcode 16 or newer and run the `HexagonKitDemo` scheme. The launch argument
`-screen` opens a screen directly, such as `-screen line` or `-screen rings/spiral`.

`Documentation/Conformance.md` lists every section of the guide, how HexagonKit
covers it and which test proves it, together with the handful of deliberate
deviations from the reference implementation.

## The Objective-C version

ObjectiveHexagon, the Objective-C library this project grew from, is finished.
Its last release is tagged
[0.3.0](https://github.com/denizztret/ObjectiveHexagon/tree/0.3.0); it is still
available through CocoaPods from that tag, and it receives no further changes.
The Objective-C sources were removed from the main branch after the tag was
made. HexagonKit is not source compatible with it: the axes are named `q`, `r`
and `s` as the guide names them now, coordinates are integral, and the grid
object was replaced by the value type `HexLayout`. The collection view layout of
the Objective-C demo became `HexCollectionViewLayout` of `HexagonKitUI`.

## Acknowledgements

- Amit Patel, for the [hexagonal grids guide](https://www.redblobgames.com/grids/hexagons/)
  and its reference implementations, released under CC0. This library would be a
  much poorer thing without them.
- James Terry, Kaz Yoshikawa and Brian Manning, whose work reached
  ObjectiveHexagon through pull request #1 and made release 0.3.0 possible.

## License

MIT. See [LICENSE](LICENSE).
