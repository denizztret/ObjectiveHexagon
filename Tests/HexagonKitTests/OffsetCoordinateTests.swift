import Foundation
import HexagonKit
import Testing

/// One row of the reference tests `test_offset_from_cube` and
/// `test_offset_to_cube` of `lib.py`.
struct OffsetReferenceRow: Sendable, CustomStringConvertible {
  let system: OffsetSystem
  let q: Int
  let r: Int
  let column: Int
  let row: Int

  var description: String { "\(system) (\(q), \(r)) <-> (\(column), \(row))" }
}

/// The neighbour tables of doc-008, section 7. The outer index is the parity of
/// the row (`r` systems) or of the column (`q` systems): `0` is even, `1` odd.
/// The inner index is the direction index `0...5`.
func offsetNeighborTable(for system: OffsetSystem) -> [[(column: Int, row: Int)]] {
  switch system {
  case .oddR:
    return [
      [(1, 0), (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1)],
      [(1, 0), (1, -1), (0, -1), (-1, 0), (0, 1), (1, 1)],
    ]
  case .evenR:
    return [
      [(1, 0), (1, -1), (0, -1), (-1, 0), (0, 1), (1, 1)],
      [(1, 0), (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1)],
    ]
  case .oddQ:
    return [
      [(1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (0, 1)],
      [(1, 1), (1, 0), (0, -1), (-1, 0), (-1, 1), (0, 1)],
    ]
  case .evenQ:
    return [
      [(1, 1), (1, 0), (0, -1), (-1, 0), (-1, 1), (0, 1)],
      [(1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (0, 1)],
    ]
  }
}

@Suite("OffsetCoordinate")
struct OffsetCoordinateTests {

  // MARK: Reference values

  /// Reference tests `test_offset_from_cube` and `test_offset_to_cube`.
  static let referenceRows: [OffsetReferenceRow] = [
    OffsetReferenceRow(system: .oddR, q: -3, r: 2, column: -2, row: 2),
    OffsetReferenceRow(system: .oddR, q: 2, r: -1, column: 1, row: -1),
    OffsetReferenceRow(system: .evenR, q: -3, r: 2, column: -2, row: 2),
    OffsetReferenceRow(system: .evenR, q: 2, r: -1, column: 2, row: -1),
    OffsetReferenceRow(system: .oddQ, q: -2, r: 3, column: -2, row: 2),
    OffsetReferenceRow(system: .oddQ, q: -1, r: -1, column: -1, row: -2),
    OffsetReferenceRow(system: .evenQ, q: -2, r: 3, column: -2, row: 2),
    OffsetReferenceRow(system: .evenQ, q: -1, r: -1, column: -1, row: -1),
  ]

  @Test("Cube to offset matches test_offset_from_cube", arguments: referenceRows)
  func cubeToOffsetMatchesTheReference(_ testCase: OffsetReferenceRow) {
    let coordinate = OffsetCoordinate(Hex(q: testCase.q, r: testCase.r), in: testCase.system)
    #expect(coordinate == OffsetCoordinate(column: testCase.column, row: testCase.row))
  }

  @Test("Offset to cube matches test_offset_to_cube", arguments: referenceRows)
  func offsetToCubeMatchesTheReference(_ testCase: OffsetReferenceRow) {
    let coordinate = OffsetCoordinate(column: testCase.column, row: testCase.row)
    #expect(Hex(coordinate, in: testCase.system) == Hex(q: testCase.q, r: testCase.r))
  }

  /// Reference test `test_offset_roundtrip` of `lib.py`, both directions,
  /// over the same range of values.
  @Test("Round trips match test_offset_roundtrip", arguments: OffsetSystem.allCases)
  func roundTripsMatchTheReference(_ system: OffsetSystem) {
    var mismatches: [String] = []
    for q in -2...2 {
      for r in -2...2 {
        let hex = Hex(q: q, r: r)
        if Hex(OffsetCoordinate(hex, in: system), in: system) != hex {
          mismatches.append("cube \(hex)")
        }
      }
    }
    for column in -2...2 {
      for row in -2...2 {
        let coordinate = OffsetCoordinate(column: column, row: row)
        if OffsetCoordinate(Hex(coordinate, in: system), in: system) != coordinate {
          mismatches.append("offset \(coordinate)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Fixtures

  @Test("Conversions match the fixture for -50...50", arguments: OffsetSystem.allCases)
  func conversionsMatchTheFixture(_ system: OffsetSystem) throws {
    let fixture = try Fixture.conversions()
    let columnIndex: Int
    switch system {
    case .oddR: columnIndex = 2
    case .evenR: columnIndex = 4
    case .oddQ: columnIndex = 6
    case .evenQ: columnIndex = 8
    }
    #expect(fixture.columns[columnIndex] == "\(system.rawValue).column")
    #expect(fixture.columns[columnIndex + 1] == "\(system.rawValue).row")
    var mismatches: [String] = []
    for row in fixture.rows {
      let hex = Hex(q: row[0], r: row[1])
      let expected = OffsetCoordinate(column: row[columnIndex], row: row[columnIndex + 1])
      let actual = OffsetCoordinate(hex, in: system)
      if actual != expected {
        mismatches.append("\(hex) -> \(actual), expected \(expected)")
      }
      if Hex(expected, in: system) != hex {
        mismatches.append("back \(expected) -> \(Hex(expected, in: system))")
      }
    }
    #expect(fixture.rows.count == 101 * 101)
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Neighbours

  @Test("Neighbours match the tables of the guide", arguments: OffsetSystem.allCases)
  func neighborsMatchTheGuideTables(_ system: OffsetSystem) {
    let table = offsetNeighborTable(for: system)
    var mismatches: [String] = []
    for column in -8...8 {
      for row in -8...8 {
        let coordinate = OffsetCoordinate(column: column, row: row)
        let parity = (system == .oddR || system == .evenR) ? (row & 1) : (column & 1)
        for direction in HexDirection.allCases {
          let delta = table[parity][direction.rawValue]
          let expected = OffsetCoordinate(
            column: column + delta.column, row: row + delta.row)
          if coordinate.neighbor(direction, in: system) != expected {
            mismatches.append("\(system) \(coordinate) \(direction)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Neighbours agree with the path through Hex", arguments: OffsetSystem.allCases)
  func neighborsAgreeWithTheCubePath(_ system: OffsetSystem) {
    var mismatches: [String] = []
    for column in -8...8 {
      for row in -8...8 {
        let coordinate = OffsetCoordinate(column: column, row: row)
        let hex = Hex(coordinate, in: system)
        for direction in HexDirection.allCases {
          let viaCube = OffsetCoordinate(hex.neighbor(direction), in: system)
          if coordinate.neighbor(direction, in: system) != viaCube {
            mismatches.append("\(system) \(coordinate) \(direction)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Six neighbours come back in direction order", arguments: OffsetSystem.allCases)
  func neighborsComeBackInDirectionOrder(_ system: OffsetSystem) {
    let coordinate = OffsetCoordinate(column: 3, row: -4)
    let neighbors = coordinate.neighbors(in: system)
    #expect(neighbors.count == 6)
    #expect(neighbors == HexDirection.allCases.map { coordinate.neighbor($0, in: system) })
    #expect(Set(neighbors).count == 6)
  }

  // MARK: Systems

  @Test("Each system names the grid orientation it is meant for")
  func systemsNameTheirOrientation() {
    #expect(OffsetSystem.oddR.orientation == .pointy)
    #expect(OffsetSystem.evenR.orientation == .pointy)
    #expect(OffsetSystem.oddQ.orientation == .flat)
    #expect(OffsetSystem.evenQ.orientation == .flat)
    #expect(OffsetSystem.allCases.count == 4)
  }

  /// The guide gives no direct distance formula for offset systems, so the
  /// documented recipe converts to `Hex` first. The recipe has to agree with
  /// the step count on the grid.
  @Test("Recipe: the distance of adjacent offset cells is one step")
  func distanceRecipeMatchesTheStepCount() {
    var mismatches: [String] = []
    for system in OffsetSystem.allCases {
      for column in -6...6 {
        for row in -6...6 {
          let coordinate = OffsetCoordinate(column: column, row: row)
          let hex = Hex(coordinate, in: system)
          for neighbor in coordinate.neighbors(in: system) {
            if hex.distance(to: Hex(neighbor, in: system)) != 1 {
              mismatches.append("\(system) \(coordinate) \(neighbor)")
            }
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Codable

  @Test("Encoding keeps the column and the row")
  func encodingKeepsColumnAndRow() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let value = OffsetCoordinate(column: 2, row: -3)
    let json = String(decoding: try encoder.encode(value), as: UTF8.self)
    #expect(json == #"{"column":2,"row":-3}"#)
    #expect(try JSONDecoder().decode(OffsetCoordinate.self, from: Data(json.utf8)) == value)
  }

  @Test("A system is encoded as the name of its case")
  func systemIsEncodedAsAName() throws {
    let json = String(decoding: try JSONEncoder().encode([OffsetSystem.oddR]), as: UTF8.self)
    #expect(json == #"["oddR"]"#)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([OffsetSystem].self, from: Data(#"["oddX"]"#.utf8))
    }
  }
}
