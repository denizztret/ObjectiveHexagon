import Foundation
import HexagonKit
import Testing

@Suite("DenseHexMap")
struct DenseHexMapTests {

  static let shape = HexShape.parallelogram(columns: 3, rows: 2)
  static let inside = Hex(q: 1, r: 1)
  static let outside = Hex(q: 9, r: 9)

  // MARK: Creation

  @Test("A map made with one value holds it for every cell")
  func mapWithOneValueHoldsItForEveryCell() {
    let map = DenseHexMap(repeating: 7, shape: Self.shape)
    #expect(map.shape == Self.shape)
    #expect(map.values == [7, 7, 7, 7, 7, 7])
    #expect(Self.shape.cells().allSatisfy { map[$0] == 7 })
  }

  @Test("The closure is called once for each cell, in index order")
  func closureIsCalledOnceForEachCellInIndexOrder() {
    var calls: [Hex] = []
    let map = DenseHexMap(shape: Self.shape) { hex in
      calls.append(hex)
      return hex.length
    }
    #expect(calls == Self.shape.cells())
    #expect(map.values == Self.shape.cells().map { $0.length })
  }

  /// Accepts a map of `Int` values and nothing else, so the type of its
  /// argument is checked by the compiler.
  static func cellCount(of map: DenseHexMap<Int>) -> Int {
    map.values.count
  }

  /// A regression of the plan of stage 3: while the repeated value came last,
  /// in `init(shape:repeating:)`, Swift matched a trailing closure of several
  /// statements with it whenever the body alone fixed the type of the closure,
  /// as passing the cell to an array of `Hex` does, and the map stored the
  /// closure in every cell. The type of `map` is inferred from its initializer
  /// alone, so this only compiles when the closure makes the values.
  @Test("A trailing closure of several statements makes a map of its values")
  func trailingClosureOfSeveralStatementsMakesAMapOfValues() {
    var visited: [Hex] = []
    let map = DenseHexMap(shape: Self.shape) { hex in
      visited.append(hex)
      return hex.q * 10 + hex.r
    }
    #expect(Self.cellCount(of: map) == 6)
    #expect(visited.count == 6)
    #expect(map[Hex(q: 2, r: 1)] == 21)
  }

  /// One indexing for every kind of shape: `values[i]` belongs to `hex(at: i)`.
  @Test("Values follow the index order of every kind of shape", arguments: HexShapeTests.shapes)
  func valuesFollowTheIndexOrder(_ named: NamedShape) {
    let map = DenseHexMap(shape: named.shape) { $0 }
    #expect(map.values.count == named.shape.count)
    var mismatches: [String] = []
    for index in 0..<named.shape.count {
      let hex = named.shape.hex(at: index)
      if map.values[index] != hex || map[hex] != hex {
        mismatches.append("\(index)")
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: The subscript, doc-016, section 3.10

  @Test("Reading gives the value of a cell and nil off the shape")
  func readingGivesTheValueOfACell() {
    let map = DenseHexMap(shape: Self.shape) { $0.q * 10 + $0.r }
    #expect(map[Self.inside] == 11)
    #expect(map[Self.outside] == nil)
  }

  @Test("Writing a value replaces the value of a cell")
  func writingAValueReplacesTheValueOfACell() {
    var map = DenseHexMap(repeating: 1, shape: Self.shape)
    map[Self.inside] = 5
    #expect(map[Self.inside] == 5)
    #expect(map.values == [1, 1, 1, 1, 5, 1])
  }

  @Test("An update through optional chaining changes a cell of the shape")
  func optionalChainingChangesACell() {
    var map = DenseHexMap(repeating: 1, shape: Self.shape)
    map[Self.inside]? += 1
    #expect(map[Self.inside] == 2)
  }

  /// `map[hex]? += 1` calls the setter with `nil` for a hex off the shape; that
  /// must do nothing, like removing a key a dictionary does not have.
  @Test("Optional chaining and writing nil off the shape do nothing")
  func optionalChainingAndNilOffTheShapeDoNothing() {
    var map = DenseHexMap(repeating: 1, shape: Self.shape)
    map[Self.outside]? += 1
    map[Self.outside] = nil
    #expect(map.values == [1, 1, 1, 1, 1, 1])
  }

  @Test("An empty shape reads nil and ignores nil")
  func emptyShapeReadsNilAndIgnoresNil() {
    var map = DenseHexMap(repeating: 1, shape: .rectangle(columns: 0, rows: 5, in: .oddR))
    #expect(map[Self.inside] == nil)
    map[Self.inside]? += 1
    map[Self.inside] = nil
    #expect(map.values.isEmpty)
  }

  // MARK: Conformances

  @Test("Maps compare by shape and values")
  func mapsCompareByShapeAndValues() {
    let map = DenseHexMap(repeating: 1, shape: Self.shape)
    var changed = map
    changed[Self.inside] = 2
    #expect(map == DenseHexMap(repeating: 1, shape: Self.shape))
    #expect(map != changed)
    #expect(Set([map, map, changed]).count == 2)
    // One cell described by two kinds of shape: two different shapes.
    let hexagon = DenseHexMap(repeating: 1, shape: .hexagon(radius: 0))
    let single = DenseHexMap(repeating: 1, shape: .parallelogram(columns: 1, rows: 1))
    #expect(hexagon.values == single.values)
    #expect(hexagon != single)
  }

  @Test("A map encodes as its shape and its values")
  func mapEncodesAsItsShapeAndItsValues() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let map = DenseHexMap(repeating: 4, shape: .parallelogram(columns: 2, rows: 1))
    let json = String(decoding: try encoder.encode(map), as: UTF8.self)
    #expect(
      json
        == #"{"shape":{"columns":2,"kind":"parallelogram","origin":{"q":0,"r":0},"rows":1},"values":[4,4]}"#
    )
  }

  @Test("A map survives a round trip through JSON")
  func mapSurvivesARoundTrip() throws {
    let map = DenseHexMap(shape: .hexagon(center: Hex(q: 2, r: -1), radius: 2)) {
      "\($0.q),\($0.r)"
    }
    let back = try JSONDecoder().decode(DenseHexMap<String>.self, from: JSONEncoder().encode(map))
    #expect(back == map)
  }

  /// The count is compared before anything is built, so a huge shape with a
  /// short array costs nothing.
  @Test("Decoding fails when the number of values differs from the cell count")
  func decodingRejectsAWrongNumberOfValues() {
    let short =
      #"{"shape":{"columns":2,"kind":"parallelogram","origin":{"q":0,"r":0},"rows":2},"values":[1,2,3]}"#
    let huge = #"{"shape":{"center":{"q":0,"r":0},"kind":"hexagon","radius":20000},"values":[1]}"#
    for json in [short, huge] {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(DenseHexMap<Int>.self, from: Data(json.utf8))
      }
    }
  }

  @Test("A map of sendable, codable and hashable values is all three")
  func conformancesFollowTheValues() {
    func requiresValueSemantics<T: Codable & Hashable & Sendable>(_: T) -> Bool { true }
    #expect(requiresValueSemantics(DenseHexMap(repeating: 0, shape: Self.shape)))
  }
}

#if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
  /// Exit tests run the closure in a child process and expect it to stop; they
  /// exist from Swift 6.2 on, so older compilers skip this suite.
  @Suite("DenseHexMap preconditions")
  struct DenseHexMapPreconditionTests {

    @Test("Writing nil for a cell of the shape stops")
    func writingNilForACellStops() async {
      await #expect(processExitsWith: .failure) {
        var map = DenseHexMap(repeating: 1, shape: .parallelogram(columns: 3, rows: 2))
        map[Hex(q: 1, r: 1)] = nil
      }
    }

    @Test("Writing a value off the shape stops")
    func writingAValueOffTheShapeStops() async {
      await #expect(processExitsWith: .failure) {
        var map = DenseHexMap(repeating: 1, shape: .parallelogram(columns: 3, rows: 2))
        map[Hex(q: 9, r: 9)] = 5
      }
    }

    @Test("Writing a value into an empty shape stops")
    func writingIntoAnEmptyShapeStops() async {
      await #expect(processExitsWith: .failure) {
        var map = DenseHexMap(repeating: 1, shape: .rectangle(columns: 0, rows: 5, in: .oddR))
        map[Hex(q: 1, r: 1)] = 5
      }
    }
  }
#endif
