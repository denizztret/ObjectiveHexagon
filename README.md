# HexagonKit

Hexagonal grid math for Swift, built on the standard library alone.

HexagonKit is a rewrite of ObjectiveHexagon in pure Swift, distributed through
Swift Package Manager. It follows the guide to hexagonal grids by Amit Patel at
[Red Blob Games](https://www.redblobgames.com/grids/hexagons/): the same terms,
the same algorithms, and the reference tests of the guide ported one to one.

## Status

**Alpha.** The core is in place: coordinates in six systems, directions,
neighbors, distance, rotation, rings, rounding, the hex-to-pixel layout and
three map shapes. Algorithms such as lines, ranges, field of view and
pathfinding, the `HexagonKitUI` module and the documentation articles are still
to come. This is a pre-release: the API may still change before 1.0.

## Requirements

- Swift 6.0 or newer, Swift 6 language mode
- iOS 15, macOS 12, tvOS 15, watchOS 8, visionOS 1, or Linux
- No dependencies

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/denizztret/ObjectiveHexagon.git", from: "1.0.0-alpha.1")
]
```

and the library to your target:

```swift
.target(name: "MyApp", dependencies: [.product(name: "HexagonKit", package: "ObjectiveHexagon")])
```

To follow the development branch instead of a release, depend on it by name:

```swift
.package(url: "https://github.com/denizztret/ObjectiveHexagon.git", branch: "master")
```

In Xcode: File > Add Package Dependencies, paste the repository URL, and pick
the version rule.

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
let layout = Layout(orientation: .pointy, size: Point(x: 20, y: 20))
let center = layout.center(of: b)
print(layout.hex(at: center).rounded() == b)   // true

// The same cell read in an offset system, and in a doubled one.
print(OffsetCoordinate(b, in: .oddR))
print(DoubledCoordinate(b, in: .doubleWidth))

// A map shape numbers its cells, so they can be stored in an array.
let map = HexShape.hexagon(radius: 3)
print(map.count, map.index(of: b) as Any)
```

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
object was replaced by the value type `Layout`.

## Acknowledgements

- Amit Patel, for the [hexagonal grids guide](https://www.redblobgames.com/grids/hexagons/)
  and its reference implementations, released under CC0. This library would be a
  much poorer thing without them.
- James Terry, Kaz Yoshikawa and Brian Manning, whose work reached
  ObjectiveHexagon through pull request #1 and made release 0.3.0 possible.

## License

MIT. See [LICENSE](LICENSE).
