# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

The Swift rewrite, not tagged yet. The library is now a Swift Package
Manager package named HexagonKit; the Objective-C library it grew from is
finished and stays available under the 0.3.0 tag.

### Added

- `HexagonKit`, the core module, which depends on the Swift standard library
  only: no Foundation, no CoreGraphics, no trigonometry.
- `Hex`: a cell in axial coordinates with a derived third cube coordinate,
  componentwise arithmetic, `length`, `distance(to:)`, `neighbor(_:)`,
  `neighbors`, `rotated(by:around:)` and `ring(radius:)`.
- `HexDirection`: the six directions in the order of the guide, with compass
  synonyms in `HexDirection.Pointy` and `HexDirection.Flat`.
- `FractionalHex`: a fractional cube coordinate with `lerp(to:t:)` and
  `rounded()`, which reproduce the reference implementation bit for bit.
- `OffsetSystem` and `OffsetCoordinate`: the four offset systems of the guide,
  with conversions and direct neighbors.
- `DoubledSystem` and `DoubledCoordinate`: the two doubled systems, with the
  even-sum invariant enforced at creation and at decoding.
- `Point`, `Orientation` and `Layout`: hex to pixel, pixel to hex, corners, cell
  sizes and grid spacings, with a size along each axis and a free origin.
- `HexShape`: the hexagon, both triangles, the rectangle in any offset system
  and the parallelogram, each with a stable cell order and constant-time
  indexing.
- `HexDiagonal` with `Hex.diagonalNeighbor(_:)` and `Hex.diagonalNeighbors`;
  `HexAxis` with `Hex.reflected(across:around:)`.
- The algorithms of the guide as methods of `Hex`: `line(to:)`,
  `range(radius:)`, `intersection(ofRanges:)`, `reachable(steps:isPassable:)`,
  `spiral(radius:)`, `spiralIndex(around:)` and `init(spiralIndex:around:)`,
  `fieldOfView(radius:isOpaque:)`, and A* in
  `path(to:minimumStepCost:searchLimit:cost:)`.
- `DenseHexMap`: one value per cell of a shape in a flat array, read and written
  like a dictionary.
- `WrappedHexagon`: a hexagonal map whose edges wrap around, with a
  constant-time `wrap(_:)` for any cell of the supported range.
- `Codable` conformance for every value type, with validation where a type has
  an invariant.
- `Documentation/Conformance.md`: the checklist against the guide, the
  deliberate deviations and the bugs of the Objective-C library that the new API
  makes impossible.
- `Scripts/reference/lib.py`: a pinned copy of the reference implementation of
  the guide (CC0) with its checksum, and `Scripts/generate-fixtures.py`, which
  produces the reference fixtures of the test suite from it, the lines with the
  nudge of the guide's text included.
- `Snippets/`: compiled examples, shown on the documentation landing page.
  `Scripts/build-docs.sh` builds the DocC archive from them, and
  `Scripts/snippets-to-markdown.py` writes the same examples as plain Markdown.
- Continuous integration on Linux with Swift 6.0, 6.1 and 6.2, and on macOS with
  the minimum and the current Xcode.

### Removed

- The Objective-C sources, the demo application and the CocoaPods podspec. They
  remain available under the 0.3.0 tag.

[Unreleased]: https://github.com/denizztret/ObjectiveHexagon/compare/0.3.0...HEAD
