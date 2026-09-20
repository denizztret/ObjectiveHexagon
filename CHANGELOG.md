# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0-alpha.1]

The first release of the Swift rewrite. The library is now a Swift Package
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
- `HexShape`: the hexagon, both triangles and the rectangle in any offset
  system, each with a stable cell order and constant-time indexing.
- `Codable` conformance for every value type, with validation where a type has
  an invariant.
- `Documentation/Conformance.md`: the checklist against the guide, the
  deliberate deviations and the bugs of the Objective-C library that the new API
  makes impossible.
- `Scripts/reference/lib.py`: a pinned copy of the reference implementation of
  the guide (CC0) with its checksum, and `Scripts/generate-fixtures.py`, which
  produces the reference fixtures of the test suite from it.
- `Snippets/`: compiled examples, shown on the documentation landing page.
  `Scripts/build-docs.sh` builds the DocC archive from them, and
  `Scripts/snippets-to-markdown.py` writes the same examples as plain Markdown.
- Continuous integration on Linux with Swift 6.0, 6.1 and 6.2, and on macOS with
  the minimum and the current Xcode.

### Removed

- The Objective-C sources, the demo application and the CocoaPods podspec. They
  remain available under the 0.3.0 tag.

[Unreleased]: https://github.com/denizztret/ObjectiveHexagon/compare/1.0.0-alpha.1...HEAD
[1.0.0-alpha.1]: https://github.com/denizztret/ObjectiveHexagon/releases/tag/1.0.0-alpha.1
