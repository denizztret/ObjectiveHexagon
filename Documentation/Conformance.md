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

A pinned copy of the reference implementation of the guide lives in
`Scripts/reference/lib.py` (CC0) with its checksum. Tests refer to the guide's
test functions by name, never by line number. `Scripts/generate-fixtures.py`
runs that copy and writes the large reference fixtures into
`Tests/HexagonKitTests/Fixtures/`.

## Coverage

| Guide section | How | Type or method | Stage | Test |
|---|---|---|---|---|
| Geometry: size and spacing | API | `HexLayout.cellWidth`, `.cellHeight`, `.horizontalSpacing`, `.verticalSpacing` | 2 | `HexLayoutTests.sizesAndSpacingsMatchTheGuide`, `HexLayoutTests.spacingsAgreeWithCenterDistances` |
| Geometry: corner angles | API | `HexLayout.corner(of:at:)`, `HexLayout.corners(of:)` | 2 | `HexLayoutTests.cornersMatchTheGuideTable`, `HexLayoutTests.sixCornersComeBackInOrder` |
| Drawing a hex | API | `HexLayout.path(of:)`, `Hexagon` (HexagonKitUI) | 4 | `HexLayoutPathTests.pathOfAHexFollowsTheCorners`, `HexLayoutPathTests.pathStartsAtCornerZeroAndRunsClockwise`, `HexagonTests.hexagonInTheFrameOfACellMatchesTheCell` |
| Coordinates: cube and axial | API | `Hex` | 2 | `HexTests.additionMatchesTheReference`, `HexTests.subtractionMatchesTheReference`, `HexTests.thirdComponentIsDerived`, `HexTests.cubeInitializerChecksTheSum` |
| Coordinates: offset | API | `OffsetCoordinate`, `OffsetSystem` | 2 | `OffsetCoordinateTests.cubeToOffsetMatchesTheReference`, `OffsetCoordinateTests.conversionsMatchTheFixture` |
| Coordinates: doubled | API | `DoubledCoordinate`, `DoubledSystem` | 2 | `DoubledCoordinateTests.cubeToDoubledMatchesTheReference`, `DoubledCoordinateTests.conversionsMatchTheFixture` |
| Coordinate conversion | API | `OffsetCoordinate.init(_:in:)`, `DoubledCoordinate.init(_:in:)`, `Hex.init(_:in:)` | 2 | `OffsetCoordinateTests.roundTripsMatchTheReference`, `DoubledCoordinateTests.roundTripsMatchTheReference` |
| Neighbors: cube and axial | API | `Hex.neighbor(_:)`, `Hex.neighbors`, `HexDirection` | 2 | `HexTests.neighborMatchesTheReference`, `HexTests.neighborsFollowDirectionOrder`, `HexDirectionTests.vectorMatchesTheTable` |
| Neighbors: offset and doubled | API | `OffsetCoordinate.neighbor(_:in:)`, `DoubledCoordinate.neighbor(_:in:)` | 2 | `OffsetCoordinateTests.neighborsMatchTheGuideTables`, `DoubledCoordinateTests.neighborsMatchTheGuideTables` |
| Neighbors: diagonals | API | `HexDiagonal`, `Hex.diagonalNeighbor(_:)`, `Hex.diagonalNeighbors` | 3 | `HexDiagonalTests.diagonalNeighborMatchesTheReference`, `HexDiagonalTests.vectorMatchesTheTable`, `HexDiagonalTests.diagonalIsTheSumOfTwoDirections` |
| Distances: cube and axial | API | `Hex.distance(to:)`, `Hex.length` | 2 | `HexTests.distanceMatchesTheReference`, `HexTests.lengthAgreesWithTheReferenceFormula`, `HexTests.distanceIsAMetric` |
| Distances: offset and doubled | composition | recipe: convert to `Hex`, then `Hex.distance(to:)`; written down in `Snippets/CoordinateRecipes.swift`, slice `distance` | 2 | `DoubledCoordinateTests.distanceRecipeMatchesTheGuideFormulas`, `OffsetCoordinateTests.distanceRecipeMatchesTheStepCount` |
| Line drawing | API | `Hex.line(to:)` | 3 | `LineTests.lineMatchesTheReference`, `LineTests.lineMatchesTheModel`, `LineTests.linesMatchTheFixture`, `LineTests.samplesMatchTheFixture` |
| Movement range | API | `Hex.range(radius:)` | 3 | `RangeTests.rangeOfRadiusOneIsListedRowByRow`, `RangeTests.rangeHoldsExactlyTheHexesWithinTheRadius` |
| Intersecting ranges | API | `Hex.intersection(ofRanges:)` | 3 | `RangeTests.intersectionOfTheDiagramExample`, `RangeTests.intersectionsMatchAScan` |
| Obstacles | API | `Hex.reachable(steps:isPassable:)` | 3 | `ReachableTests.fourStepsThroughTheScene`, `ReachableTests.withoutObstaclesTheKeysAreTheRange` |
| Rotation | API | `Hex.rotated(by:around:)` | 2 | `HexTests.clockwiseRotationMatchesTheReference`, `HexTests.counterclockwiseRotationMatchesTheReference`, `HexTests.rotationIsPeriodic` |
| Reflection | API and composition | `HexAxis`, `Hex.reflected(across:around:)`; the three negated reflections: recipe `(hex - center).reflected(across: axis) * -1 + center` | 3 | `HexAxisTests.reflectionsOfTheDiagramHexMatchTheGuide`, `HexAxisTests.negatedReflectionsFollowTheRecipe`, `HexAxisTests.fixedHexesLieOnTheLineOfTwoDiagonals` |
| Rings | API | `Hex.ring(radius:)` | 2 | `HexTests.ringOfRadiusOneMatchesTheGuide`, `HexTests.ringOfRadiusTwoMatchesTheGuide`, `HexTests.ringHasSixTimesRadiusCells` |
| Spiral rings | API | `Hex.spiral(radius:)` | 3 | `SpiralTests.spiralsMatchTheGuide`, `SpiralTests.spiralIncludesItsOuterRing` |
| Spiral coordinates | API | `Hex.spiralIndex(around:)`, `Hex.init(spiralIndex:around:)` | 3 | `SpiralTests.spiralCoordinatesMatchTheGuide`, `SpiralTests.spiralAndCoordinatesAgree` |
| Conversions: offset to doubled | composition | recipe: convert through `Hex`; written down in `Snippets/CoordinateRecipes.swift`, slice `bridge` | 2 | `DoubledCoordinateTests.bridgeRecipeMatchesTheReferenceFormulas` |
| Field of view | API | `Hex.fieldOfView(radius:isOpaque:)` | 3 | `FieldOfViewTests.sceneOfTheGuide`, `FieldOfViewTests.wallHidesAHexOnlyWhenTheLinePassesThroughIt` |
| Hex to pixel | API | `HexLayout.center(of:)` | 2 | `HexLayoutTests.centersMatchTheReferenceNumbers`, `HexLayoutTests.centersMatchTheFixture` |
| Hex to pixel: offset and doubled | composition | recipe: convert to `Hex`, then `HexLayout.center(of:)`; written down in `Snippets/CoordinateRecipes.swift`, slice `pixel` | 2 | `HexLayoutTests.offsetToPixelRecipe`, `HexLayoutTests.doubledToPixelRecipe`, `HexLayoutTests.offsetGridIsSpacedAsDrawn` |
| Pixel to hex | API | `HexLayout.hex(at:)`; a point of a view: `HexLayout.hex(at:)` with a `CGPoint` (HexagonKitUI) | 2, 4 | `HexLayoutTests.roundTripMatchesTheReference`, `HexLayoutTests.pixelInsideACellRoundsToThatCell`, `HexLayoutRectTests.pointOfAViewGivesTheFractionalHexOfTheCore` |
| Layout examples (implementation page) | API | `HexLayout`, `HexLayout.frame(of:)` (HexagonKitUI); the example with the y axis up: deviation 17 | 2, 4 | `HexLayoutRectTests.layoutExamplesFrameIsOneCell`, `HexLayoutRectTests.layoutExamplesTwiceTheSize`, `HexLayoutRectTests.layoutExamplesSprite`, `HexLayoutRectTests.layoutExamplesTopLeftOrigin` |
| Rounding | API | `FractionalHex.rounded()` | 2 | `FractionalHexTests.midpointCaseOfTheReference`, `FractionalHexTests.exactHalvesRoundAwayFromZero`, `FractionalHexTests.roundingMatchesTheFixtureOnBoundaryPoints` |
| Map storage: shapes | API | `HexShape.hexagon`, `.triangleDown`, `.triangleUp`, `.rectangle` | 2 | `HexShapeTests.membershipMatchesTheDefiningInequalities`, `HexShapeTests.cellAndIndexAreMutuallyInverse` |
| Map storage: parallelogram | API | `HexShape.parallelogram(origin:columns:rows:)` | 3 | `HexShapeParallelogramTests.parallelogramIsListedRowByRow`, `HexShapeTests.cellAndIndexAreMutuallyInverse` |
| Map storage: arrays | API | `DenseHexMap` | 3 | `DenseHexMapTests.valuesFollowTheIndexOrder`, `DenseHexMapTests.optionalChainingAndNilOffTheShapeDoNothing` |
| Wraparound maps: hexagon | API | `WrappedHexagon`, `WrappedHexagon.wrap(_:)` | 3 | `WrappedHexagonTests.hexesWrapAsInTheGuide`, `WrappedHexagonTests.formulaAgreesWithTheGuideRule` |
| Wraparound maps: rectangle | explanation | the guide gives no formula; wrap the offset column and row | 3 | – |
| Pathfinding | API | `Hex.path(to:minimumStepCost:searchLimit:cost:)` | 3 | `PathTests.pathCostsThroughTheScene`, `PathTests.aStarFindsACheapestPath` |

## HexagonKitUI

`HexagonKitUI` is an agreed addition beyond the guide. It implements two things
of the guide directly, "Drawing a hex" and the "Layout examples" of the
implementation page, which the table above lists; the rest bridges the core to
Core Graphics, SwiftUI and UIKit without geometry of its own. The demo
application `Examples/HexagonKitDemo` draws the diagrams of the guide with it.

| Addition | Type or method | Test |
|---|---|---|
| Points and sizes of Core Graphics | `CGPoint(_:)`, `Point(_:)` | `PointBridgeTests.pointGoesToACGPointAndBack`, `PointBridgeTests.sizeBecomesAPoint` |
| The rectangle of a hex | `HexLayout.frame(of:)` | `HexLayoutRectTests.frameBoundsTheCorners` |
| The rectangle of some hexes or of a shape | `HexLayout.bounds(of:)` | `HexLayoutRectTests.boundsContainTheFrames`, `HexLayoutRectTests.boundsOfAShapeAreTheBoundsOfItsCells`, `HexLayoutRectTests.noHexesHaveNoBounds` |
| The outline of some hexes | `HexLayout.path(of:)` for a sequence | `HexLayoutPathTests.pathOfSomeHexesChainsTheirPaths`, `HexLayoutPathTests.fillingThePathFillsTheHexes` |
| Views on hexes | `HexGridLayout`, `View.hexCell(_:)` | `HexGridLayoutTests.eachViewSitsOnItsHex`, `HexGridLayoutTests.boardTakesTheSizeOfThePlacement` |
| Items of a collection view on hexes | `HexCollectionViewLayout` | `HexCollectionViewLayoutTests.eachItemGetsTheFrameOfItsHex`, `HexCollectionViewLayoutTests.attributesInARectangle` |
| A placement both containers share, finite as `CGFloat` values | internal | `PlacementTests.placementStartsAtZeroAndFitsItsSize`, `PlacementPreconditionTests.extentThatOverflowsStops` |

## Reference tests of the guide

`lib.py` ships nineteen test functions. All nineteen are covered.

| Reference test | Covered by |
|---|---|
| `test_hex_arithmetic` | `HexTests.additionMatchesTheReference`, `HexTests.subtractionMatchesTheReference` |
| `test_hex_direction` | `HexDirectionTests.directionTwoMatchesTheReference` |
| `test_hex_neighbor` | `HexTests.neighborMatchesTheReference` |
| `test_hex_diagonal` | `HexDiagonalTests.diagonalNeighborMatchesTheReference` |
| `test_hex_distance` | `HexTests.distanceMatchesTheReference` |
| `test_hex_rotate_right` | `HexTests.clockwiseRotationMatchesTheReference` |
| `test_hex_rotate_left` | `HexTests.counterclockwiseRotationMatchesTheReference` |
| `test_hex_round` | `FractionalHexTests.midpointCaseOfTheReference`, `FractionalHexTests.nearHalfwayCasesOfTheReference`, `FractionalHexTests.weightedCasesOfTheReference` |
| `test_hex_linedraw` | `LineTests.lineMatchesTheReference` |
| `test_layout` | `HexLayoutTests.centersMatchTheReferenceNumbers`, `HexLayoutTests.roundTripMatchesTheReference` |
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

   The guide has a third numbering too. The pseudocode of its section on
   angles computes `angle_deg = 60 * i - 30` for pointy cells, so its corner 0
   sits at -30 degrees, which is 330 degrees on screen, and its corner `i` is
   corner `(i + 5) % 6` of HexagonKit; both walk clockwise. For flat cells it
   agrees with HexagonKit. ObjectiveHexagon numbered pointy corners this way.
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
7. **Cell order in shape generators and ranges.** The guide lists the cells of
   a map shape, a movement range and an intersection of ranges with the outer
   loop over `q`. HexagonKit lists them row by row, which is the order the dense
   array storage needs. The sets are the same.
8. **A ring of radius zero.** The `cube_ring` of the guide does not work at a
   radius of zero, as its author notes. `Hex.ring(radius: 0)` returns the center
   itself.
9. **Nudge of the line ends.** `lib.py` and the implementation page nudge both
   ends of a line by `(1e-6, 1e-6, -2e-6)`; the text of the guide recommends
   `(1e-6, 2e-6, -3e-6)`, and HexagonKit follows the text. The nudge of `lib.py`
   moves `q` and `r` alike, so it does not break ties between them: on the
   hexagon of radius 6, 1734 of the 16129 ordered pairs of cells depend on the
   last bit of floating point there, and 104 lines differ from their reverses;
   the nudge of the text leaves neither on that hexagon. The two nudges draw
   different lines for 1447 of those pairs; `test_hex_linedraw` passes with
   both. The large line fixtures are generated with the nudge of the text. With
   either nudge, rounding in floating point can leave two consecutive cells of a
   very long line with large coordinates two steps apart, so HexagonKit does
   not promise that consecutive cells of a line are adjacent.
10. **A line from a cell to itself.** The text of the guide divides by the
    distance, which is zero there; HexagonKit uses `max(N, 1)` as the
    implementation page does, so the line is the cell alone.
11. **Movement with obstacles counts the moves.** The guide returns the set of
    cells it visited; HexagonKit returns each reached cell with the fewest moves
    that reach it, which is the index of its fringe in the guide's code.
12. **Spiral coordinates.** The guide's formulas break at index 0, find the
    index of a cell by searching its ring, and compute the radius of an index as
    `floor((sqrt(12 * index - 3) + 3) / 6)`, which is exact in `Double` only up
    to radius 44739242 and overflows 64-bit integers inside the supported
    coordinate range. HexagonKit gives the center index 0, converts in both
    directions in constant time with exact integer arithmetic, and takes any
    center.
13. **Field of view.** The guide calls a cell visible when the line to it
    "doesn't hit any walls"; its interactive diagram uses a more permissive test
    and never shows walls as visible. HexagonKit takes the plain reading: a cell
    is visible when no cell strictly between the two ends of the line is opaque,
    so walls are visible and hide what is behind them.
14. **Pathfinding.** The guide points to its A* tutorial and suggests scaling
    the distance by the cost of a step; its diagram runs a breadth-first search.
    HexagonKit runs A* with the heuristic `distance * minimumStepCost` and an
    optional limit on the cells it expands. Among equally cheap paths, which one
    is returned is not specified.
15. **Wraparound in constant time.** The guide precomputes a table of the cells
    just off the map; HexagonKit computes the cell of the map for any cell with
    an integer formula (the hexmod representation by Sander Evers, which the
    guide links to). It agrees with the guide's rule of subtracting the nearest
    mirror center.
16. **Parallelograms on the axes `q` and `r`.** The guide's loop may run over any
    two of the three axes; HexagonKit offers the pair `q` and `r`, the one the
    guide's array storage uses, with rows along `r`. The other two pairs give the
    same shape rotated by 120 and 240 degrees.
17. **The y axis points down.** The guide flips the y axis with a negative size,
    `Point(25, -25)`, for spaces whose y axis grows upwards. `HexLayout` requires
    a positive size, and HexagonKitUI works in the coordinate space of SwiftUI
    and UIKit, where the y axis points down. To draw in a space whose y axis
    grows upwards, flip that space; the corners then run counterclockwise on
    screen, and the compass names of `HexDirection.Pointy` and
    `HexDirection.Flat` swap north and south. Test:
    `HexLayoutPreconditionTests.negativeHeightStops`.

## Bugs of ObjectiveHexagon that the API makes impossible

ObjectiveHexagon 0.3.0 is the final Objective-C release of this library. The
survey of its core found the following. Where a bug disappears together with the
mechanism that caused it, there is no artificial test for it; the table says so.

| Bug of the Objective-C library | How it is closed |
|---|---|
| `hexConvertAxialToCube` produced a negative zero, so a lookup for the central cell missed | `Hex` is integral and is its own dictionary key. Test: `HexTests.centralCellIsReachableThroughAHexKey` |
| `hexesBySpirals()` dropped the outer ring | `Hex.spiral(radius:)` ends with the outer ring and has `1 + 3 * radius * (radius + 1)` cells. Test: `SpiralTests.spiralIncludesItsOuterRing` |
| `valid` compared a sum of `CGFloat` with zero using `==` | There is no validity check at all: `Hex` holds the invariant by construction and `FractionalHex` is a separate type. Fixed by design |
| `fabsf`, `roundf`, `cosf`, `sinf` applied to `double` values | The core uses `Double` only, rounds with `rounded(.toNearestOrAwayFromZero)` and has no trigonometry. Test: `FractionalHexTests.roundingKeepsDoublePrecision` |
| A category on `NSValue` duplicated UIKit and read past its buffer | Foundation and Objective-C are banned in the core. Fixed by design |
| `hex3DMultiply` and `hex3DScale` were two names for one operation | One operator `*`. Test: `HexTests.scalingByOneIsTheIdentity` |
| `boundsOfShapes:` returned garbage for an empty array | `HexLayout.bounds(of:)` of HexagonKitUI returns `nil` for no hexes. Test: `HexLayoutRectTests.noHexesHaveNoBounds` |
| Corner numbering for pointy cells started at -30 degrees, one corner off from HexagonKit, as in the pseudocode of the guide's section on angles (deviation 1) | The corner order is pinned by a table. Tests: `HexLayoutTests.cornersMatchTheGuideTable`, `HexLayoutTests.cornerOneOfAPointyCellIsTheLowestPoint` |
| Ties in rounding were resolved on `x` and then `y` instead of `q` and then `r` | `FractionalHex.rounded()` follows the guide. Tests: `FractionalHexTests.tiesAreResolvedTowardsSThenR`, `FractionalHexTests.tieOrderFollowsTheGuide` |
| A `switch` over an enumeration had neither a `default` nor a final `return` | All enumerations are closed, so every `switch` is exhaustive. Fixed by design |
| A cell size of zero silently produced `{0, 0, 0}` | `HexLayout` requires a finite positive size on both axes. Test: `HexLayoutTests.decodingRejectsASizeOutOfRange` |
| A cell key was the coordinate formatted with `%.0f` | The key is a `Hex`, by `Hashable`. Fixed by design |
| Constants were truncated literals, off by about 1e-14 | `sqrt(3)` is computed as `3.0.squareRoot()`. Fixed by design |
| A weak reference to the grid made the geometry silently zero | `HexLayout` is a value. Fixed by design |
| `[HKHexagon alloc]` instead of `[self alloc]` | Value types, no inheritance. Fixed by design |

## The collection view layout of the old demo

The Objective-C library kept its collection view layout in the demo
application. `HexCollectionViewLayout` replaces it, and its tests run on the iOS
simulator.

| Flaw of the old layout | How it is closed |
|---|---|
| An empty grid gave a content size of garbage | The content size of no cells is zero. Test: `HexCollectionViewLayoutTests.layoutWithoutCellsHasNoSize` |
| The layout cast its data source to the view controller of the demo | The layout reads only `layout` and `cells`. Test: `HexCollectionViewLayoutTests.collectionViewShowsTheCells` |
| `layoutAttributesForItem(at:)` built new attributes on every call instead of reading its cache | Tests: `HexCollectionViewLayoutTests.eachItemGetsTheFrameOfItsHex`, `HexCollectionViewLayoutTests.preparingAgainGivesEqualAttributes` |
| `layoutAttributesForElements(in:)` scanned every item and returned them in no stable order | A binary search over the items sorted by their top edges. Test: `HexCollectionViewLayoutTests.attributesInARectangle` |
| `shouldInvalidateLayout(forBoundsChange:)` always returned `true`, so every frame of scrolling invalidated the layout | The geometry does not depend on the bounds. Test: `HexCollectionViewLayoutTests.changeOfTheBoundsNeverInvalidates` |
| The cache was rebuilt only after batch updates, and `prepare()` wrote into the model | Setting `cells` or `layout` invalidates the layout. Tests: `HexCollectionViewLayoutTests.updatesGiveNewAttributes`, `HexCollectionViewLayoutTests.newLayoutMovesTheCells` |
| Hexes that repeated collapsed under one string key | Items on the same hex share a frame. Tests: `HexCollectionViewLayoutTests.updatesGiveNewAttributes`, `PlacementTests.hexesThatRepeatShareAFrame` |
| The content size was that of the whole grid, not of the items shown | Test: `HexCollectionViewLayoutTests.contentSizeIsTheBoundsOfTheCells` |
| A tap near the corner of a frame could hit either of two overlapping items | The documentation gives the recipe through `hex(at:)`. Test: `HexCollectionViewLayoutTests.hitRecipeFindsTheHexUnderAPoint` |
