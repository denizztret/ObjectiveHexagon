# Conformance to the Red Blob Games guide

HexagonKit implements the guide to hexagonal grids by Amit Patel:
<https://www.redblobgames.com/grids/hexagons/> and its implementation notes at
<https://www.redblobgames.com/grids/hexagons/implementation.html>.

Version 1.0 covers the guide and nothing beyond it. This document is the
checklist: it lists every section of the guide, how HexagonKit covers it, and
which test proves it. A section counts as covered in one of three ways:

- **API** – there is a type or a method that implements the section, plus a test;
- **composition** – the section is solved by combining existing methods (usually
  "convert to `Hex`, do the work there, and convert back"); the recipe is written
  down in `Snippets/CoordinateRecipes.swift` and shown on the documentation
  landing page, and a test checks it against the formulas of the guide;
- **explanation** – the section needs no code; the documentation links to the guide.

Rows marked `planned` belong to later stages; the names in their "Type or
method" column are provisional until the API of that stage is settled.

A pinned copy of the reference implementation of the guide lives in
`Scripts/reference/lib.py` (CC0) with its checksum. Tests refer to the guide's
test functions by name, never by line number. `Scripts/generate-fixtures.py`
runs that copy and writes the large reference fixtures into
`Tests/HexagonKitTests/Fixtures/`.

## Coverage

| Guide section | How | Type or method | Stage | Test |
|---|---|---|---|---|
| Geometry: size and spacing | API | `Layout.cellWidth`, `.cellHeight`, `.horizontalSpacing`, `.verticalSpacing` | 2 | `LayoutTests.sizesAndSpacingsMatchTheGuide`, `LayoutTests.spacingsAgreeWithCenterDistances` |
| Geometry: corner angles | API | `Layout.corner(of:at:)`, `Layout.corners(of:)` | 2 | `LayoutTests.cornersMatchTheGuideTable`, `LayoutTests.sixCornersComeBackInOrder` |
| Coordinates: cube and axial | API | `Hex` | 2 | `HexTests.additionMatchesTheReference`, `HexTests.subtractionMatchesTheReference`, `HexTests.thirdComponentIsDerived`, `HexTests.cubeInitializerChecksTheSum` |
| Coordinates: offset | API | `OffsetCoordinate`, `OffsetSystem` | 2 | `OffsetCoordinateTests.cubeToOffsetMatchesTheReference`, `OffsetCoordinateTests.conversionsMatchTheFixture` |
| Coordinates: doubled | API | `DoubledCoordinate`, `DoubledSystem` | 2 | `DoubledCoordinateTests.cubeToDoubledMatchesTheReference`, `DoubledCoordinateTests.conversionsMatchTheFixture` |
| Coordinate conversion | API | `OffsetCoordinate.init(_:in:)`, `DoubledCoordinate.init(_:in:)`, `Hex.init(_:in:)` | 2 | `OffsetCoordinateTests.roundTripsMatchTheReference`, `DoubledCoordinateTests.roundTripsMatchTheReference` |
| Neighbors: cube and axial | API | `Hex.neighbor(_:)`, `Hex.neighbors`, `HexDirection` | 2 | `HexTests.neighborMatchesTheReference`, `HexTests.neighborsFollowDirectionOrder`, `HexDirectionTests.vectorMatchesTheTable` |
| Neighbors: offset and doubled | API | `OffsetCoordinate.neighbor(_:in:)`, `DoubledCoordinate.neighbor(_:in:)` | 2 | `OffsetCoordinateTests.neighborsMatchTheGuideTables`, `DoubledCoordinateTests.neighborsMatchTheGuideTables` |
| Neighbors: diagonals | API | `Hex.diagonalNeighbors` | 3 | planned |
| Distances: cube and axial | API | `Hex.distance(to:)`, `Hex.length` | 2 | `HexTests.distanceMatchesTheReference`, `HexTests.lengthAgreesWithTheReferenceFormula`, `HexTests.distanceIsAMetric` |
| Distances: offset and doubled | composition | recipe: convert to `Hex`, then `Hex.distance(to:)`; written down in `Snippets/CoordinateRecipes.swift`, slice `distance` | 2 | `DoubledCoordinateTests.distanceRecipeMatchesTheGuideFormulas`, `OffsetCoordinateTests.distanceRecipeMatchesTheStepCount` |
| Line drawing | API | `Hex.line(to:)` | 3 | planned |
| Movement range | API | `Hex.range(_:)` | 3 | planned |
| Intersecting ranges | API | `Hex.intersection(ofRanges:)` | 3 | planned |
| Obstacles | API | `Hex.reachable(steps:isPassable:)` | 3 | planned |
| Rotation | API | `Hex.rotated(by:around:)` | 2 | `HexTests.clockwiseRotationMatchesTheReference`, `HexTests.counterclockwiseRotationMatchesTheReference`, `HexTests.rotationIsPeriodic` |
| Reflection | API | `Hex.reflected(across:)` | 3 | planned |
| Rings | API | `Hex.ring(radius:)` | 2 | `HexTests.ringOfRadiusOneMatchesTheGuide`, `HexTests.ringOfRadiusTwoMatchesTheGuide`, `HexTests.ringHasSixTimesRadiusCells` |
| Spiral rings | API | `Hex.spiral(radius:)` | 3 | planned |
| Spiral coordinates | API | `Hex.spiralIndex`, `Hex.init(spiralIndex:)` | 3 | planned |
| Conversions: offset to doubled | composition | recipe: convert through `Hex`; written down in `Snippets/CoordinateRecipes.swift`, slice `bridge` | 2 | `DoubledCoordinateTests.bridgeRecipeMatchesTheReferenceFormulas` |
| Field of view | API | `Hex.fieldOfView(radius:isOpaque:)` | 3 | planned |
| Hex to pixel | API | `Layout.center(of:)` | 2 | `LayoutTests.centersMatchTheReferenceNumbers`, `LayoutTests.centersMatchTheFixture` |
| Hex to pixel: offset and doubled | composition | recipe: convert to `Hex`, then `Layout.center(of:)`; written down in `Snippets/CoordinateRecipes.swift`, slice `pixel` | 2 | `LayoutTests.offsetToPixelRecipe`, `LayoutTests.doubledToPixelRecipe`, `LayoutTests.offsetGridIsSpacedAsDrawn` |
| Pixel to hex | API | `Layout.hex(at:)` | 2 | `LayoutTests.roundTripMatchesTheReference`, `LayoutTests.pixelInsideACellRoundsToThatCell` |
| Rounding | API | `FractionalHex.rounded()` | 2 | `FractionalHexTests.midpointCaseOfTheReference`, `FractionalHexTests.exactHalvesRoundAwayFromZero`, `FractionalHexTests.roundingMatchesTheFixtureOnBoundaryPoints` |
| Map storage: shapes | API | `HexShape.hexagon`, `.triangleDown`, `.triangleUp`, `.rectangle` | 2 | `HexShapeTests.membershipMatchesTheDefiningInequalities`, `HexShapeTests.cellAndIndexAreMutuallyInverse` |
| Map storage: parallelogram | API | `HexShape.parallelogram` | 3 | planned |
| Map storage: arrays | API | `DenseHexMap` | 3 | planned |
| Wraparound maps | API | `WrappedHexagon.wrap(_:)` | 3 | planned |
| Pathfinding | API | `Hex.path(to:minimumStepCost:searchLimit:cost:)` | 3 | planned |
| Bridges to CoreGraphics, SwiftUI and UIKit | API | `HexagonKitUI` | 4 | planned |

## Reference tests of the guide

`lib.py` ships nineteen test functions. Stage 2 covers all of them except the
two that belong to stage 3.

| Reference test | Covered by |
|---|---|
| `test_hex_arithmetic` | `HexTests.additionMatchesTheReference`, `HexTests.subtractionMatchesTheReference` |
| `test_hex_direction` | `HexDirectionTests.directionTwoMatchesTheReference` |
| `test_hex_neighbor` | `HexTests.neighborMatchesTheReference` |
| `test_hex_diagonal` | stage 3 |
| `test_hex_distance` | `HexTests.distanceMatchesTheReference` |
| `test_hex_rotate_right` | `HexTests.clockwiseRotationMatchesTheReference` |
| `test_hex_rotate_left` | `HexTests.counterclockwiseRotationMatchesTheReference` |
| `test_hex_round` | `FractionalHexTests.midpointCaseOfTheReference`, `FractionalHexTests.nearHalfwayCasesOfTheReference`, `FractionalHexTests.weightedCasesOfTheReference` |
| `test_hex_linedraw` | stage 3 |
| `test_layout` | `LayoutTests.centersMatchTheReferenceNumbers`, `LayoutTests.roundTripMatchesTheReference` |
| `test_offset_roundtrip` | `OffsetCoordinateTests.roundTripsMatchTheReference` |
| `test_offset_from_cube` | `OffsetCoordinateTests.cubeToOffsetMatchesTheReference` |
| `test_offset_to_cube` | `OffsetCoordinateTests.offsetToCubeMatchesTheReference` |
| `test_offset_to_doubled` | `DoubledCoordinateTests.bridgeRecipeMatchesTheReferenceFormulas` |
| `test_offset_from_doubled` | an empty stub in the reference; covered by the round trip of the same recipe |
| `test_doubled_roundtrip` | `DoubledCoordinateTests.roundTripsMatchTheReference` |
| `test_doubled_from_cube` | `DoubledCoordinateTests.cubeToDoubledMatchesTheReference` |
| `test_doubled_to_cube` | `DoubledCoordinateTests.doubledToCubeMatchesTheReference` |
| `test_all` | the suites above, run together |

## Deliberate deviations from the reference implementation

The guide is not consistent with itself in a few places, and some of its ports
disagree with each other. Every choice HexagonKit made is listed here.

1. **Corner order.** The generated `lib.py` walks the corners counterclockwise
   on screen; the text of the guide walks them clockwise, corner `i` at
   `60 * i` degrees plus 30 for pointy. HexagonKit follows the text. The set of
   corners is the same in both; only the numbering differs.
2. **Halves in rounding.** The ports of the guide round exact halves in three
   incompatible ways: to even (Python, C#), up (JavaScript, TypeScript, Lua) and
   away from zero (C++, Rust). HexagonKit rounds away from zero, so it agrees
   with the C++ and Rust ports. The reference tests do not cover halves at all.
3. **Distance through a maximum.** The reference computes
   `(|q| + |r| + |s|) / 2`. HexagonKit computes `max(|q|, |r|, |s|)`. The values
   are the same, but the sum of three absolute differences reaches `4 * 2^30`
   and overflows a 32-bit `Int` inside the supported coordinate range, which
   real watchOS devices have.
4. **Index of the triangle with a corner at the top.** The guide writes the
   position in a row as `q - N + 1 + r`; with the same `N` that is off by one.
   HexagonKit uses `q - (N - r)`, so the full index is `r(r + 1)/2 + q - N + r`.
5. **`column` instead of `col`.** The reference names the fields of an offset
   and a doubled coordinate `col` and `row`. HexagonKit spells the first one
   out, as the Swift API Design Guidelines ask.
6. **No trigonometry.** Corner offsets are the constants `0`, `+-0.5`, `+-1` and
   `+-sqrt(3)/2`, where `sqrt(3)` is `3.0.squareRoot()`. They are identical on
   every platform, while `cos` and `sin` may differ in the last bit.
7. **Cell order in shape generators.** The guide lists the cells of a map shape
   with the outer loop over `q`. HexagonKit lists them row by row, which is the
   order the dense array storage of stage 3 needs. The sets are the same.
8. **A ring of radius zero.** The `cube_ring` of the guide does not work at a
   radius of zero, as its author notes. `Hex.ring(radius: 0)` returns the center
   itself.

## Bugs of ObjectiveHexagon that the API makes impossible

ObjectiveHexagon 0.3.0 is the final Objective-C release of this library. The
survey of its core found the following. Where a bug disappears together with the
mechanism that caused it, there is no artificial test for it; the table says so.

| Bug of the Objective-C library | How it is closed |
|---|---|
| `hexConvertAxialToCube` produced a negative zero, so a lookup for the central cell missed | `Hex` is integral and is its own dictionary key. Test: `HexTests.centralCellIsReachableThroughAHexKey` |
| `hexesBySpirals()` dropped the outer ring | The spiral belongs to stage 3, but `ring(radius:)` already pins the cell count and the first cell. Test: `HexTests.ringHasSixTimesRadiusCells` |
| `valid` compared a sum of `CGFloat` with zero using `==` | There is no validity check at all: `Hex` holds the invariant by construction and `FractionalHex` is a separate type. Fixed by design |
| `fabsf`, `roundf`, `cosf`, `sinf` applied to `double` values | The core uses `Double` only, rounds with `rounded(.toNearestOrAwayFromZero)` and has no trigonometry. Test: `FractionalHexTests.roundingKeepsDoublePrecision` |
| A category on `NSValue` duplicated UIKit and read past its buffer | Foundation and Objective-C are banned in the core. Fixed by design |
| `hex3DMultiply` and `hex3DScale` were two names for one operation | One operator `*`. Test: `HexTests.scalingByOneIsTheIdentity` |
| `boundsOfShapes:` returned garbage for an empty array | The core has no such operation; `HexagonKitUI` will return an optional. Fixed by design |
| Corner numbering for pointy cells was shifted by one and walked backwards | The corner order is pinned by a table. Tests: `LayoutTests.cornersMatchTheGuideTable`, `LayoutTests.cornerOneOfAPointyCellIsTheLowestPoint` |
| Ties in rounding were resolved on `x` and then `y` instead of `q` and then `r` | `FractionalHex.rounded()` follows the guide. Tests: `FractionalHexTests.tiesAreResolvedTowardsSThenR`, `FractionalHexTests.tieOrderFollowsTheGuide` |
| A `switch` over an enumeration had neither a `default` nor a final `return` | All enumerations are closed, so every `switch` is exhaustive. Fixed by design |
| A cell size of zero silently produced `{0, 0, 0}` | `Layout` requires a finite positive size on both axes. Test: `LayoutTests.decodingRejectsASizeOutOfRange` |
| A cell key was the coordinate formatted with `%.0f` | The key is a `Hex`, by `Hashable`. Fixed by design |
| Constants were truncated literals, off by about 1e-14 | `sqrt(3)` is computed as `3.0.squareRoot()`. Fixed by design |
| A weak reference to the grid made the geometry silently zero | `Layout` is a value. Fixed by design |
| `[HKHexagon alloc]` instead of `[self alloc]` | Value types, no inheritance. Fixed by design |
