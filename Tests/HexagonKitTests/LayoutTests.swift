import Foundation
import HexagonKit
import Testing

/// One row of the corner table of doc-010, section 4: the unit offset of a
/// corner from the center of the cell, before it is scaled by `size`.
struct CornerRow: Sendable, CustomStringConvertible {
  let orientation: Orientation
  let index: Int
  let x: Double
  let y: Double

  var description: String { "\(orientation) corner \(index)" }
}

/// Comparison of pixel values with a relative tolerance. The reference numbers
/// of the guide are written down with six decimals, so an exact comparison is
/// only possible against values the tests compute themselves.
func isClose(_ actual: Double, _ expected: Double, tolerance: Double = 1e-9) -> Bool {
  abs(actual - expected) <= tolerance * max(1.0, abs(actual), abs(expected))
}

@Suite("Layout")
struct LayoutTests {

  static let sqrt3 = 3.0.squareRoot()

  // MARK: Reference values

  /// Reference test `test_layout` of `lib.py` with the pixel values recomputed
  /// from the matrices of doc-008, section 9: flat `(80.0, 213.894192)`,
  /// pointy `(121.602540, 161.0)`.
  @Test("Centers match the numbers of test_layout")
  func centersMatchTheReferenceNumbers() {
    let hex = Hex(q: 3, r: 4)
    let size = Point(x: 10, y: 15)
    let origin = Point(x: 35, y: 71)

    let flat = Layout(orientation: .flat, size: size, origin: origin)
    let flatCenter = flat.center(of: hex)
    #expect(flatCenter.x == 80.0)
    #expect(isClose(flatCenter.y, 213.894_191_624_432_38))

    let pointy = Layout(orientation: .pointy, size: size, origin: origin)
    let pointyCenter = pointy.center(of: hex)
    #expect(isClose(pointyCenter.x, 121.602_540_378_443_85))
    #expect(pointyCenter.y == 161.0)
  }

  /// Reference test `test_layout` of `lib.py`: the round trip.
  @Test("The round trip matches test_layout")
  func roundTripMatchesTheReference() {
    let hex = Hex(q: 3, r: 4)
    let size = Point(x: 10, y: 15)
    let origin = Point(x: 35, y: 71)
    for orientation in Orientation.allCases {
      let layout = Layout(orientation: orientation, size: size, origin: origin)
      #expect(layout.hex(at: layout.center(of: hex)).rounded() == hex)
    }
  }

  // MARK: Fixtures

  @Test("Centers and round trips match the fixture")
  func centersMatchTheFixture() throws {
    let fixture = try Fixture.layouts()
    var mismatches: [String] = []
    for testCase in fixture.cases {
      let orientation: Orientation = testCase.orientation == "pointy" ? .pointy : .flat
      let layout = Layout(
        orientation: orientation,
        size: Point(x: testCase.sizeX, y: testCase.sizeY),
        origin: Point(x: testCase.originX, y: testCase.originY))
      for index in testCase.hexes.indices {
        let hex = Hex(q: testCase.hexes[index][0], r: testCase.hexes[index][1])
        let expected = Point(
          x: testCase.centers[index][0], y: testCase.centers[index][1])
        let center = layout.center(of: hex)
        if center != expected {
          mismatches.append("center \(testCase.orientation) \(hex): \(center) != \(expected)")
        }
        if layout.hex(at: center).rounded() != hex {
          mismatches.append("round trip \(testCase.orientation) \(hex)")
        }
      }
    }
    #expect(fixture.cases.count == 6)
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Corners

  /// The corner table of doc-010, section 4: the variant of the guide's text,
  /// not of `lib.py`. Corner `i` sits at `60 * i` degrees, plus 30 for pointy.
  static let corners: [CornerRow] = [
    CornerRow(orientation: .pointy, index: 0, x: sqrt3 / 2, y: 0.5),
    CornerRow(orientation: .pointy, index: 1, x: 0, y: 1),
    CornerRow(orientation: .pointy, index: 2, x: -sqrt3 / 2, y: 0.5),
    CornerRow(orientation: .pointy, index: 3, x: -sqrt3 / 2, y: -0.5),
    CornerRow(orientation: .pointy, index: 4, x: 0, y: -1),
    CornerRow(orientation: .pointy, index: 5, x: sqrt3 / 2, y: -0.5),
    CornerRow(orientation: .flat, index: 0, x: 1, y: 0),
    CornerRow(orientation: .flat, index: 1, x: 0.5, y: sqrt3 / 2),
    CornerRow(orientation: .flat, index: 2, x: -0.5, y: sqrt3 / 2),
    CornerRow(orientation: .flat, index: 3, x: -1, y: 0),
    CornerRow(orientation: .flat, index: 4, x: -0.5, y: -sqrt3 / 2),
    CornerRow(orientation: .flat, index: 5, x: 0.5, y: -sqrt3 / 2),
  ]

  @Test("Corners match the table of the guide's text", arguments: corners)
  func cornersMatchTheGuideTable(_ row: CornerRow) {
    let layout = Layout(orientation: row.orientation, size: Point(x: 1, y: 1))
    let corner = layout.corner(of: .zero, at: row.index)
    #expect(corner == Point(x: row.x, y: row.y))
  }

  @Test("Corners scale with the size and move with the center")
  func cornersScaleAndMove() {
    let layout = Layout(
      orientation: .pointy, size: Point(x: 10, y: 20), origin: Point(x: 5, y: -7))
    let hex = Hex(q: 2, r: -1)
    let center = layout.center(of: hex)
    let corner = layout.corner(of: hex, at: 1)
    #expect(isClose(corner.x, center.x))
    #expect(isClose(corner.y, center.y + 20))
  }

  @Test("Six corners come back in corner order")
  func sixCornersComeBackInOrder() {
    var mismatches: [String] = []
    for orientation in Orientation.allCases {
      let layout = Layout(
        orientation: orientation, size: Point(x: 3, y: 4), origin: Point(x: -1, y: 2))
      let hex = Hex(q: -2, r: 5)
      let corners = layout.corners(of: hex)
      if corners.count != 6 {
        mismatches.append("count \(orientation)")
      }
      if corners != (0...5).map({ layout.corner(of: hex, at: $0) }) {
        mismatches.append("order \(orientation)")
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// ObjectiveHexagon numbered the corners of a pointy cell with a shift of one
  /// and walked them the other way round (doc-002, error 8). The corner order
  /// is now pinned by the table above; here it is pinned once more by the shape
  /// of the polygon: corner 1 of a pointy cell is the lowest point on screen.
  @Test("Corner one of a pointy cell is its lowest point")
  func cornerOneOfAPointyCellIsTheLowestPoint() {
    let layout = Layout(orientation: .pointy, size: Point(x: 10, y: 10))
    let corners = layout.corners(of: .zero)
    let lowest = corners.max { $0.y < $1.y }
    #expect(lowest == corners[1])
    #expect(corners[1].x == 0)
  }

  // MARK: Sizes and spacings

  @Test("Sizes and spacings match the table of the guide")
  func sizesAndSpacingsMatchTheGuide() {
    let pointy = Layout(orientation: .pointy, size: Point(x: 2, y: 3))
    #expect(pointy.cellWidth == LayoutTests.sqrt3 * 2)
    #expect(pointy.cellHeight == 2 * 3.0)
    #expect(pointy.horizontalSpacing == LayoutTests.sqrt3 * 2)
    #expect(pointy.verticalSpacing == 3.0 / 2.0 * 3)

    let flat = Layout(orientation: .flat, size: Point(x: 2, y: 3))
    #expect(flat.cellWidth == 2 * 2.0)
    #expect(flat.cellHeight == LayoutTests.sqrt3 * 3)
    #expect(flat.horizontalSpacing == 3.0 / 2.0 * 2)
    #expect(flat.verticalSpacing == LayoutTests.sqrt3 * 3)
  }

  @Test("Spacings agree with the distance between the centers of neighbours")
  func spacingsAgreeWithCenterDistances() {
    let pointy = Layout(orientation: .pointy, size: Point(x: 12, y: 9))
    #expect(
      isClose(
        pointy.center(of: Hex(q: 1, r: 0)).x - pointy.center(of: .zero).x,
        pointy.horizontalSpacing))
    #expect(
      isClose(
        pointy.center(of: Hex(q: 0, r: 1)).y - pointy.center(of: .zero).y,
        pointy.verticalSpacing))

    let flat = Layout(orientation: .flat, size: Point(x: 12, y: 9))
    #expect(
      isClose(
        flat.center(of: Hex(q: 1, r: 0)).x - flat.center(of: .zero).x, flat.horizontalSpacing))
    #expect(
      isClose(
        flat.center(of: Hex(q: 0, r: 1)).y - flat.center(of: .zero).y, flat.verticalSpacing))
  }

  // MARK: Properties and limits

  @Test("The round trip survives unequal sizes and a non-zero origin")
  func roundTripSurvivesUnequalSizesAndOrigin() {
    let layout = Layout(
      orientation: .pointy, size: Point(x: 7.5, y: 4.25), origin: Point(x: -1_000.5, y: 2_000.25))
    var mismatches: [String] = []
    for q in -40...40 {
      for r in -40...40 {
        let hex = Hex(q: q, r: r)
        if layout.hex(at: layout.center(of: hex)).rounded() != hex {
          mismatches.append("\(hex)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// doc-010, section 3.10: the guarantee of reversibility holds while
  /// `|origin| / size` stays below `2^32`. Far beyond that the centers of
  /// neighbouring cells collapse onto the same `Double`, and nothing traps:
  /// the result is whatever the arithmetic of `Double` produces.
  @Test("Precision is lost when the origin is huge")
  func precisionIsLostWhenTheOriginIsHuge() {
    let layout = Layout(
      orientation: .pointy, size: Point(x: 1, y: 1), origin: Point(x: 0x1p60, y: 0))
    let center = layout.center(of: Hex(q: 1, r: 0))
    #expect(center == layout.center(of: .zero))
    #expect(center.x == 0x1p60)
    #expect(layout.hex(at: center).rounded() == Hex.zero)
  }

  @Test("A pixel inside a cell rounds to that cell")
  func pixelInsideACellRoundsToThatCell() {
    let layout = Layout(orientation: .flat, size: Point(x: 20, y: 20), origin: Point(x: 3, y: 5))
    var mismatches: [String] = []
    for q in -6...6 {
      for r in -6...6 {
        let hex = Hex(q: q, r: r)
        let center = layout.center(of: hex)
        for offset in [Point(x: 2, y: 0), Point(x: -2, y: 0), Point(x: 0, y: 2)] {
          let probe = Point(x: center.x + offset.x, y: center.y + offset.y)
          if layout.hex(at: probe).rounded() != hex {
            mismatches.append("\(hex) \(offset)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Recipes

  /// doc-001, section 12, row "Hex to pixel: offset, doubled": there is no
  /// direct method, the documented recipe converts the coordinate to a `Hex`
  /// first. The guide gives direct pixel formulas for a grid with one cell size
  /// and the origin at zero, and the recipe has to reproduce all four of them:
  /// odd-r `x = size * sqrt(3) * (column + 0.5 * (row & 1))`, `y = size * 3/2 * row`;
  /// even-r the same with a minus; odd-q `x = size * 3/2 * column`,
  /// `y = size * sqrt(3) * (row + 0.5 * (column & 1))`; even-q with a minus.
  @Test(
    "Recipe: an offset coordinate reaches the pixel through Hex",
    arguments: OffsetSystem.allCases)
  func offsetToPixelRecipe(_ system: OffsetSystem) {
    let size = 17.0
    let sqrt3 = LayoutTests.sqrt3
    let layout = Layout(orientation: system.orientation, size: Point(x: size, y: size))
    var mismatches: [String] = []
    for column in -7...7 {
      for row in -7...7 {
        let coordinate = OffsetCoordinate(column: column, row: row)
        let center = layout.center(of: Hex(coordinate, in: system))
        let expected: Point
        switch system {
        case .oddR:
          expected = Point(
            x: size * sqrt3 * (Double(column) + 0.5 * Double(row & 1)),
            y: size * 1.5 * Double(row))
        case .evenR:
          expected = Point(
            x: size * sqrt3 * (Double(column) - 0.5 * Double(row & 1)),
            y: size * 1.5 * Double(row))
        case .oddQ:
          expected = Point(
            x: size * 1.5 * Double(column),
            y: size * sqrt3 * (Double(row) + 0.5 * Double(column & 1)))
        case .evenQ:
          expected = Point(
            x: size * 1.5 * Double(column),
            y: size * sqrt3 * (Double(row) - 0.5 * Double(column & 1)))
        }
        if !isClose(center.x, expected.x) || !isClose(center.y, expected.y) {
          mismatches.append("\(system) (\(column), \(row)): \(center) != \(expected)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// The same recipe for the doubled systems: doublewidth
  /// `x = size * sqrt(3)/2 * column`, `y = size * 3/2 * row`; doubleheight
  /// `x = size * 3/2 * column`, `y = size * sqrt(3)/2 * row`.
  @Test(
    "Recipe: a doubled coordinate reaches the pixel through Hex",
    arguments: DoubledSystem.allCases)
  func doubledToPixelRecipe(_ system: DoubledSystem) throws {
    let size = 17.0
    let sqrt3 = LayoutTests.sqrt3
    let layout = Layout(orientation: system.orientation, size: Point(x: size, y: size))
    var mismatches: [String] = []
    for column in -8...8 {
      for row in -8...8 where (column + row) % 2 == 0 {
        let coordinate = try #require(DoubledCoordinate(column: column, row: row))
        let center = layout.center(of: Hex(coordinate, in: system))
        let expected: Point
        switch system {
        case .doubleWidth:
          expected = Point(x: size * sqrt3 / 2 * Double(column), y: size * 1.5 * Double(row))
        case .doubleHeight:
          expected = Point(x: size * 1.5 * Double(column), y: size * sqrt3 / 2 * Double(row))
        }
        if !isClose(center.x, expected.x) || !isClose(center.y, expected.y) {
          mismatches.append("\(system) (\(column), \(row)): \(center) != \(expected)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// The shape of an odd-r grid, stated once more in the terms a reader of the
  /// recipe cares about: the columns of a row are one horizontal spacing apart
  /// and the odd rows are shifted right by half of it.
  @Test("Recipe: the odd-r grid is spaced the way the guide draws it")
  func offsetGridIsSpacedAsDrawn() {
    let layout = Layout(orientation: .pointy, size: Point(x: 10, y: 10))
    func center(column: Int, row: Int) -> Point {
      layout.center(of: Hex(OffsetCoordinate(column: column, row: row), in: .oddR))
    }
    #expect(
      isClose(center(column: 1, row: 0).x - center(column: 0, row: 0).x, layout.horizontalSpacing))
    #expect(
      isClose(center(column: 0, row: 1).y - center(column: 0, row: 0).y, layout.verticalSpacing))
    #expect(
      isClose(
        center(column: 0, row: 1).x - center(column: 0, row: 0).x,
        layout.horizontalSpacing / 2))
    #expect(isClose(center(column: 0, row: 2).x - center(column: 0, row: 0).x, 0))
  }

  // MARK: Codable

  @Test("A layout round-trips through JSON")
  func layoutRoundTripsThroughJSON() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let layout = Layout(
      orientation: .flat, size: Point(x: 10, y: 15), origin: Point(x: 35, y: 71))
    let json = String(decoding: try encoder.encode(layout), as: UTF8.self)
    #expect(try JSONDecoder().decode(Layout.self, from: Data(json.utf8)) == layout)
  }

  /// ObjectiveHexagon silently returned `{0, 0, 0}` when the cell size was zero
  /// (doc-002, error 10b). A layout with such a size cannot be decoded.
  @Test("Decoding a layout with a size out of range fails")
  func decodingRejectsASizeOutOfRange() {
    let zeroSize = #"{"orientation":"pointy","origin":{"x":0,"y":0},"size":{"x":0,"y":10}}"#
    let negativeSize = #"{"orientation":"pointy","origin":{"x":0,"y":0},"size":{"x":10,"y":-1}}"#
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Layout.self, from: Data(zeroSize.utf8))
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Layout.self, from: Data(negativeSize.utf8))
    }
  }

  @Test("Decoding a layout with a non-finite origin fails")
  func decodingRejectsANonFiniteOrigin() {
    let json = #"{"orientation":"pointy","origin":{"x":"inf","y":0},"size":{"x":10,"y":10}}"#
    let decoder = JSONDecoder()
    decoder.nonConformingFloatDecodingStrategy = .convertFromString(
      positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
    #expect(throws: DecodingError.self) {
      try decoder.decode(Layout.self, from: Data(json.utf8))
    }
  }
}
