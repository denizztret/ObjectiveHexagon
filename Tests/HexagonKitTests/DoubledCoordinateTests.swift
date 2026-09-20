import Foundation
import HexagonKit
import Testing

/// The neighbour tables of doc-008, section 7. Doubled systems do not depend on
/// parity, so there is one row of six deltas per system.
func doubledNeighborTable(for system: DoubledSystem) -> [(column: Int, row: Int)] {
  switch system {
  case .doubleWidth:
    return [(2, 0), (1, -1), (-1, -1), (-2, 0), (-1, 1), (1, 1)]
  case .doubleHeight:
    return [(1, 1), (1, -1), (0, -2), (-1, -1), (-1, 1), (0, 2)]
  }
}

@Suite("DoubledCoordinate")
struct DoubledCoordinateTests {

  // MARK: Reference values

  /// Reference test `test_doubled_from_cube` of `lib.py`.
  @Test("Cube to doubled matches test_doubled_from_cube")
  func cubeToDoubledMatchesTheReference() {
    let hex = Hex(q: 1, r: 2)
    #expect(DoubledCoordinate(hex, in: .doubleHeight) == DoubledCoordinate(column: 1, row: 5))
    #expect(DoubledCoordinate(hex, in: .doubleWidth) == DoubledCoordinate(column: 4, row: 2))
  }

  /// Reference test `test_doubled_to_cube` of `lib.py`.
  @Test("Doubled to cube matches test_doubled_to_cube")
  func doubledToCubeMatchesTheReference() throws {
    let tall = try #require(DoubledCoordinate(column: 1, row: 5))
    let wide = try #require(DoubledCoordinate(column: 4, row: 2))
    #expect(Hex(tall, in: .doubleHeight) == Hex(q: 1, r: 2))
    #expect(Hex(wide, in: .doubleWidth) == Hex(q: 1, r: 2))
  }

  /// Reference test `test_doubled_roundtrip` of `lib.py`, both directions,
  /// over the same range of values and the same even-sum constructions.
  @Test("Round trips match test_doubled_roundtrip", arguments: DoubledSystem.allCases)
  func roundTripsMatchTheReference(_ system: DoubledSystem) throws {
    var mismatches: [String] = []
    for q in -2...2 {
      for r in -2...2 {
        let hex = Hex(q: q, r: r)
        if Hex(DoubledCoordinate(hex, in: system), in: system) != hex {
          mismatches.append("cube \(hex)")
        }
      }
    }
    for column in -2...2 {
      for row in -2...2 {
        let coordinate: DoubledCoordinate
        switch system {
        case .doubleHeight:
          coordinate = try #require(DoubledCoordinate(column: column, row: row * 2 + (column & 1)))
        case .doubleWidth:
          coordinate = try #require(DoubledCoordinate(column: column * 2 + (row & 1), row: row))
        }
        if DoubledCoordinate(Hex(coordinate, in: system), in: system) != coordinate {
          mismatches.append("doubled \(coordinate)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Fixtures

  @Test("Conversions match the fixture for -50...50", arguments: DoubledSystem.allCases)
  func conversionsMatchTheFixture(_ system: DoubledSystem) throws {
    let fixture = try Fixture.conversions()
    let columnIndex = system == .doubleWidth ? 10 : 12
    #expect(fixture.columns[columnIndex] == "\(system.rawValue).column")
    #expect(fixture.columns[columnIndex + 1] == "\(system.rawValue).row")
    var mismatches: [String] = []
    for row in fixture.rows {
      let hex = Hex(q: row[0], r: row[1])
      let actual = DoubledCoordinate(hex, in: system)
      if actual.column != row[columnIndex] || actual.row != row[columnIndex + 1] {
        mismatches.append("\(hex) -> \(actual)")
      }
      if Hex(actual, in: system) != hex {
        mismatches.append("back \(actual)")
      }
    }
    #expect(fixture.rows.count == 101 * 101)
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: The even-sum invariant

  @Test("A pair with an odd sum is not a hex")
  func oddSumIsNotAHex() {
    #expect(DoubledCoordinate(column: 1, row: 0) == nil)
    #expect(DoubledCoordinate(column: 0, row: -1) == nil)
    #expect(DoubledCoordinate(column: 1, row: 1) != nil)
    #expect(DoubledCoordinate(column: -3, row: 1) != nil)
    #expect(DoubledCoordinate(column: 0, row: 0) != nil)
  }

  @Test("Conversion from a hex always produces an even sum")
  func conversionAlwaysProducesAnEvenSum() {
    var mismatches: [String] = []
    for system in DoubledSystem.allCases {
      for q in -12...12 {
        for r in -12...12 {
          let coordinate = DoubledCoordinate(Hex(q: q, r: r), in: system)
          if (coordinate.column + coordinate.row) % 2 != 0 {
            mismatches.append("\(system) \(q) \(r)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Decoding a pair with an odd sum fails")
  func decodingRejectsAnOddSum() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let value = try #require(DoubledCoordinate(column: 4, row: 2))
    let json = String(decoding: try encoder.encode(value), as: UTF8.self)
    #expect(json == #"{"column":4,"row":2}"#)
    #expect(try JSONDecoder().decode(DoubledCoordinate.self, from: Data(json.utf8)) == value)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(
        DoubledCoordinate.self, from: Data(#"{"column":4,"row":3}"#.utf8))
    }
  }

  // MARK: Neighbours

  @Test("Neighbours match the tables of the guide", arguments: DoubledSystem.allCases)
  func neighborsMatchTheGuideTables(_ system: DoubledSystem) throws {
    let table = doubledNeighborTable(for: system)
    var mismatches: [String] = []
    for column in -8...8 {
      for row in -8...8 where (column + row) % 2 == 0 {
        let coordinate = try #require(DoubledCoordinate(column: column, row: row))
        for direction in HexDirection.allCases {
          let delta = table[direction.rawValue]
          let neighbor = coordinate.neighbor(direction, in: system)
          if neighbor.column != column + delta.column || neighbor.row != row + delta.row {
            mismatches.append("\(system) \(coordinate) \(direction)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Neighbours agree with the path through Hex", arguments: DoubledSystem.allCases)
  func neighborsAgreeWithTheCubePath(_ system: DoubledSystem) throws {
    var mismatches: [String] = []
    for column in -8...8 {
      for row in -8...8 where (column + row) % 2 == 0 {
        let coordinate = try #require(DoubledCoordinate(column: column, row: row))
        let hex = Hex(coordinate, in: system)
        for direction in HexDirection.allCases {
          let viaCube = DoubledCoordinate(hex.neighbor(direction), in: system)
          if coordinate.neighbor(direction, in: system) != viaCube {
            mismatches.append("\(system) \(coordinate) \(direction)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Six neighbours come back in direction order", arguments: DoubledSystem.allCases)
  func neighborsComeBackInDirectionOrder(_ system: DoubledSystem) throws {
    let coordinate = try #require(DoubledCoordinate(column: 3, row: -5))
    let neighbors = coordinate.neighbors(in: system)
    #expect(neighbors.count == 6)
    #expect(neighbors == HexDirection.allCases.map { coordinate.neighbor($0, in: system) })
    #expect(neighbors.allSatisfy { ($0.column + $0.row) % 2 == 0 })
    #expect(Set(neighbors).count == 6)
  }

  // MARK: Systems

  @Test("Each system names the grid orientation it is meant for")
  func systemsNameTheirOrientation() {
    #expect(DoubledSystem.doubleWidth.orientation == .pointy)
    #expect(DoubledSystem.doubleHeight.orientation == .flat)
    #expect(DoubledSystem.allCases.count == 2)
  }

  @Test("A system is encoded as the name of its case")
  func systemIsEncodedAsAName() throws {
    let json = String(
      decoding: try JSONEncoder().encode([DoubledSystem.doubleWidth]), as: UTF8.self)
    #expect(json == #"["doubleWidth"]"#)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([DoubledSystem].self, from: Data(#"["rdoubled"]"#.utf8))
    }
  }

  // MARK: Recipes

  /// doc-008, section 7: the guide gives direct distance formulas for the
  /// doubled systems. HexagonKit has no method for them; the documented recipe
  /// converts to `Hex`, and this test checks the recipe against those formulas.
  @Test("Recipe: doubled distance agrees with the formulas of the guide")
  func distanceRecipeMatchesTheGuideFormulas() throws {
    var mismatches: [String] = []
    for q1 in -6...6 {
      for r1 in -6...6 {
        for q2 in -6...6 {
          for r2 in -6...6 {
            let a = Hex(q: q1, r: r1)
            let b = Hex(q: q2, r: r2)
            let distance = a.distance(to: b)

            let wideA = DoubledCoordinate(a, in: .doubleWidth)
            let wideB = DoubledCoordinate(b, in: .doubleWidth)
            let wideColumns = abs(wideA.column - wideB.column)
            let wideRows = abs(wideA.row - wideB.row)
            if wideRows + max(0, (wideColumns - wideRows) / 2) != distance {
              mismatches.append("doubleWidth \(a) \(b)")
            }

            let tallA = DoubledCoordinate(a, in: .doubleHeight)
            let tallB = DoubledCoordinate(b, in: .doubleHeight)
            let tallColumns = abs(tallA.column - tallB.column)
            let tallRows = abs(tallA.row - tallB.row)
            if tallColumns + max(0, (tallRows - tallColumns) / 2) != distance {
              mismatches.append("doubleHeight \(a) \(b)")
            }
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// Reference test `test_offset_to_doubled` of `lib.py`. HexagonKit has no
  /// bridge methods between the offset and the doubled systems; the documented
  /// recipe goes through `Hex`, and this test checks it against the direct
  /// formulas of the reference. `offset` is `+1` for the even systems and `-1`
  /// for the odd ones; the expression under the division is always even, so the
  /// truncating division of Swift agrees with the flooring division of Python.
  @Test("Recipe: the bridge to doubled agrees with test_offset_to_doubled")
  func bridgeRecipeMatchesTheReferenceFormulas() throws {
    var mismatches: [String] = []
    for system in OffsetSystem.allCases {
      let offset = (system == .evenR || system == .evenQ) ? 1 : -1
      let doubled: DoubledSystem =
        (system == .oddR || system == .evenR) ? .doubleWidth : .doubleHeight
      for column in -8...8 {
        for row in -8...8 {
          let coordinate = OffsetCoordinate(column: column, row: row)
          let viaHex = DoubledCoordinate(Hex(coordinate, in: system), in: doubled)
          let direct: (column: Int, row: Int)
          switch doubled {
          case .doubleHeight:
            direct = (column, 2 * row - offset * (column & 1))
          case .doubleWidth:
            direct = (2 * column - offset * (row & 1), row)
          }
          if viaHex.column != direct.column || viaHex.row != direct.row {
            mismatches.append("to \(system) \(coordinate)")
          }

          let back = OffsetCoordinate(Hex(viaHex, in: doubled), in: system)
          let directBack: OffsetCoordinate
          switch doubled {
          case .doubleHeight:
            directBack = OffsetCoordinate(
              column: viaHex.column, row: (viaHex.row + offset * (viaHex.column & 1)) / 2)
          case .doubleWidth:
            directBack = OffsetCoordinate(
              column: (viaHex.column + offset * (viaHex.row & 1)) / 2, row: viaHex.row)
          }
          if back != directBack || back != coordinate {
            mismatches.append("from \(system) \(coordinate)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }
}
