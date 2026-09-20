import Foundation
import Testing

/// Reference fixtures generated from the pinned `Scripts/reference/lib.py`
/// by `Scripts/generate-fixtures.py`.
enum Fixture {

  /// Cube coordinates and their offset and doubled readings, for `q` and `r`
  /// in `-range...range`. `columns` names the meaning of each entry of a row.
  struct Conversions: Decodable {
    let columns: [String]
    let range: Int
    let rows: [[Int]]
    let source: String
    let sourceSHA256: String
  }

  /// Grid rounding. A row is `[qNumerator, rNumerator, hex.q, hex.r]`, where the
  /// fractional coordinates are `qNumerator / denominator` and
  /// `rNumerator / denominator`. `interior` holds the points every port of the
  /// guide rounds the same way; `boundary` holds the points where at least one
  /// component lands on an exact half and the ports disagree.
  struct Rounding: Decodable {
    let boundary: [[Int]]
    let columns: [String]
    let denominator: Int
    let interior: [[Int]]
    let range: Int
    let rule: String
    let source: String
    let sourceSHA256: String
  }

  /// Hex centers in pixels for several layouts, and the round trip back.
  struct Layouts: Decodable {
    struct Case: Decodable {
      let centers: [[Double]]
      let hexes: [[Int]]
      let orientation: String
      let originX: Double
      let originY: Double
      let sizeX: Double
      let sizeY: Double
    }
    let cases: [Case]
    let range: Int
    let source: String
    let sourceSHA256: String
  }

  enum LoadingError: Error {
    case fileNotFound(String)
  }

  static func load<Value: Decodable>(_ type: Value.Type, named name: String) throws -> Value {
    guard
      let url = Bundle.module.url(
        forResource: name, withExtension: "json", subdirectory: "Fixtures")
    else {
      throw LoadingError.fileNotFound(name)
    }
    return try JSONDecoder().decode(Value.self, from: Data(contentsOf: url))
  }

  static func conversions() throws -> Conversions {
    try load(Conversions.self, named: "conversions")
  }

  static func rounding() throws -> Rounding {
    try load(Rounding.self, named: "rounding")
  }

  static func layouts() throws -> Layouts {
    try load(Layouts.self, named: "layout")
  }
}

@Suite("Fixtures")
struct FixtureLoadingTests {

  @Test("The conversion fixture loads and has the expected shape")
  func conversionFixtureLoads() throws {
    let fixture = try Fixture.conversions()
    #expect(fixture.range == 50)
    #expect(fixture.rows.count == 101 * 101)
    #expect(fixture.columns.count == 14)
    #expect(fixture.columns[0] == "q")
    #expect(fixture.columns[1] == "r")
    #expect(fixture.columns[2] == "oddR.column")
    #expect(fixture.columns[3] == "oddR.row")
    #expect(fixture.columns[4] == "evenR.column")
    #expect(fixture.columns[5] == "evenR.row")
    #expect(fixture.columns[6] == "oddQ.column")
    #expect(fixture.columns[7] == "oddQ.row")
    #expect(fixture.columns[8] == "evenQ.column")
    #expect(fixture.columns[9] == "evenQ.row")
    #expect(fixture.columns[10] == "doubleWidth.column")
    #expect(fixture.columns[11] == "doubleWidth.row")
    #expect(fixture.columns[12] == "doubleHeight.column")
    #expect(fixture.columns[13] == "doubleHeight.row")
    #expect(fixture.rows.allSatisfy { $0.count == 14 })
  }

  @Test("The rounding fixture loads and splits interior from boundary points")
  func roundingFixtureLoads() throws {
    let fixture = try Fixture.rounding()
    #expect(fixture.denominator == 12)
    #expect(fixture.range == 3)
    #expect(fixture.rule == "nearest, halves away from zero")
    #expect(fixture.interior.count + fixture.boundary.count == 73 * 73)
    #expect(fixture.interior.isEmpty == false)
    #expect(fixture.boundary.isEmpty == false)
    #expect(fixture.interior.allSatisfy { $0.count == 4 })
    #expect(fixture.boundary.allSatisfy { $0.count == 4 })
  }

  @Test("The layout fixture loads and covers both orientations")
  func layoutFixtureLoads() throws {
    let fixture = try Fixture.layouts()
    #expect(fixture.range == 15)
    #expect(fixture.cases.count == 6)
    #expect(fixture.cases.contains { $0.orientation == "pointy" })
    #expect(fixture.cases.contains { $0.orientation == "flat" })
    #expect(fixture.cases.allSatisfy { $0.hexes.count == 31 * 31 })
    #expect(fixture.cases.allSatisfy { $0.centers.count == $0.hexes.count })
  }

  @Test("Every fixture names the same pinned reference file")
  func fixturesShareTheSameSource() throws {
    let conversions = try Fixture.conversions()
    let rounding = try Fixture.rounding()
    let layouts = try Fixture.layouts()
    #expect(conversions.source == "Scripts/reference/lib.py")
    #expect(rounding.source == conversions.source)
    #expect(layouts.source == conversions.source)
    #expect(rounding.sourceSHA256 == conversions.sourceSHA256)
    #expect(layouts.sourceSHA256 == conversions.sourceSHA256)
  }
}
