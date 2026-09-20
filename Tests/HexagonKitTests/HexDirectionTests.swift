import Foundation
import HexagonKit
import Testing

/// One row of the direction table of doc-010, section 4.
struct DirectionRow: Sendable, CustomStringConvertible {
  let direction: HexDirection
  let index: Int
  let q: Int
  let r: Int
  let pointy: HexDirection
  let flat: HexDirection

  var description: String { "index \(index)" }
}

@Suite("HexDirection")
struct HexDirectionTests {

  static let table: [DirectionRow] = [
    DirectionRow(
      direction: .plusQMinusS, index: 0, q: 1, r: 0,
      pointy: HexDirection.Pointy.east, flat: HexDirection.Flat.southeast),
    DirectionRow(
      direction: .plusQMinusR, index: 1, q: 1, r: -1,
      pointy: HexDirection.Pointy.northeast, flat: HexDirection.Flat.northeast),
    DirectionRow(
      direction: .plusSMinusR, index: 2, q: 0, r: -1,
      pointy: HexDirection.Pointy.northwest, flat: HexDirection.Flat.north),
    DirectionRow(
      direction: .plusSMinusQ, index: 3, q: -1, r: 0,
      pointy: HexDirection.Pointy.west, flat: HexDirection.Flat.northwest),
    DirectionRow(
      direction: .plusRMinusQ, index: 4, q: -1, r: 1,
      pointy: HexDirection.Pointy.southwest, flat: HexDirection.Flat.southwest),
    DirectionRow(
      direction: .plusRMinusS, index: 5, q: 0, r: 1,
      pointy: HexDirection.Pointy.southeast, flat: HexDirection.Flat.south),
  ]

  @Test("Raw values are the direction indices of the guide", arguments: table)
  func rawValueIsTheGuideIndex(_ row: DirectionRow) {
    #expect(row.direction.rawValue == row.index)
    #expect(HexDirection(rawValue: row.index) == row.direction)
  }

  @Test("Unit vectors match the direction table", arguments: table)
  func vectorMatchesTheTable(_ row: DirectionRow) {
    #expect(row.direction.vector == Hex(q: row.q, r: row.r))
    #expect(row.direction.vector.length == 1)
  }

  @Test("Compass synonyms name the same six values", arguments: table)
  func compassNamesMatchTheTable(_ row: DirectionRow) {
    #expect(row.pointy == row.direction)
    #expect(row.flat == row.direction)
  }

  /// Reference test `test_hex_direction` of `lib.py`.
  @Test("Direction index two matches test_hex_direction")
  func directionTwoMatchesTheReference() {
    #expect(HexDirection.plusSMinusR.vector == Hex(q: 0, r: -1))
    #expect(HexDirection.plusSMinusR.vector.s == 1)
  }

  @Test("There are exactly six directions, in index order")
  func allCasesAreInIndexOrder() {
    #expect(HexDirection.allCases.count == 6)
    #expect(HexDirection.allCases.map(\.rawValue) == [0, 1, 2, 3, 4, 5])
  }

  @Test("An index outside zero to five is not representable")
  func outOfRangeIndexIsNotRepresentable() {
    #expect(HexDirection(rawValue: -1) == nil)
    #expect(HexDirection(rawValue: 6) == nil)
  }

  @Test("Opposite directions cancel out")
  func oppositeDirectionsCancelOut() {
    var mismatches: [String] = []
    for direction in HexDirection.allCases {
      let opposite = HexDirection(rawValue: (direction.rawValue + 3) % 6)
      if direction.vector + opposite!.vector != Hex.zero {
        mismatches.append("\(direction)")
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// One clockwise step on screen moves from index `i` to index `i - 1`,
  /// because the direction indices run counterclockwise on screen.
  @Test("Rotation walks the direction table")
  func rotationWalksTheDirectionTable() {
    var mismatches: [String] = []
    for direction in HexDirection.allCases {
      let next = HexDirection(rawValue: (direction.rawValue + 5) % 6)!
      if direction.vector.rotated(by: 1) != next.vector {
        mismatches.append("\(direction)")
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("The same value carries both compass names on the two orientations")
  func northeastIsSharedByBothOrientations() {
    #expect(HexDirection.Pointy.northeast == HexDirection.Flat.northeast)
    #expect(HexDirection.Pointy.southwest == HexDirection.Flat.southwest)
  }

  @Test("Encoding uses the direction index")
  func encodingUsesTheIndex() throws {
    let json = String(
      decoding: try JSONEncoder().encode([HexDirection.plusSMinusR]), as: UTF8.self)
    #expect(json == "[2]")
  }

  @Test("Decoding an index outside zero to five fails")
  func decodingRejectsAnIndexOutsideTheRange() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([HexDirection].self, from: Data("[6]".utf8))
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([HexDirection].self, from: Data("[-1]".utf8))
    }
  }
}
