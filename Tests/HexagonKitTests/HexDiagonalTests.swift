import Foundation
import HexagonKit
import Testing

/// One row of the diagonal table: `hex_diagonals` of `lib.py`, in index order.
struct DiagonalRow: Sendable, CustomStringConvertible {
  let diagonal: HexDiagonal
  let index: Int
  let q: Int
  let r: Int
  let s: Int

  var description: String { "index \(index)" }
}

@Suite("HexDiagonal")
struct HexDiagonalTests {

  static let table: [DiagonalRow] = [
    DiagonalRow(diagonal: .plusQ, index: 0, q: 2, r: -1, s: -1),
    DiagonalRow(diagonal: .minusR, index: 1, q: 1, r: -2, s: 1),
    DiagonalRow(diagonal: .plusS, index: 2, q: -1, r: -1, s: 2),
    DiagonalRow(diagonal: .minusQ, index: 3, q: -2, r: 1, s: 1),
    DiagonalRow(diagonal: .plusR, index: 4, q: -1, r: 2, s: -1),
    DiagonalRow(diagonal: .minusS, index: 5, q: 1, r: 1, s: -2),
  ]

  // MARK: Reference values

  /// Reference test `test_hex_diagonal` of `lib.py`: diagonal index 3.
  @Test("Diagonal neighbor matches test_hex_diagonal")
  func diagonalNeighborMatchesTheReference() {
    #expect(Hex(q: 1, r: -2).diagonalNeighbor(.minusQ) == Hex(q: -1, r: -1))
  }

  @Test("Vectors match hex_diagonals of the reference", arguments: table)
  func vectorMatchesTheTable(_ row: DiagonalRow) {
    #expect(row.diagonal.vector == Hex(q: row.q, r: row.r))
    #expect(row.diagonal.vector.s == row.s)
  }

  /// The six diagonal neighbors of the hex of `test_hex_diagonal`, computed
  /// with `hex_diagonal_neighbor` of `lib.py`.
  @Test("All six diagonal neighbors of the reference hex")
  func allDiagonalNeighborsOfTheReferenceHex() {
    let expected = [
      Hex(q: 3, r: -3), Hex(q: 2, r: -4), Hex(q: 0, r: -3),
      Hex(q: -1, r: -1), Hex(q: 0, r: 0), Hex(q: 2, r: -1),
    ]
    #expect(Hex(q: 1, r: -2).diagonalNeighbors == expected)
  }

  // MARK: Index and order

  @Test("Raw values are the diagonal indices of the guide", arguments: table)
  func rawValueIsTheGuideIndex(_ row: DiagonalRow) {
    #expect(row.diagonal.rawValue == row.index)
    #expect(HexDiagonal(rawValue: row.index) == row.diagonal)
  }

  @Test("There are exactly six diagonals, in index order")
  func allCasesAreInIndexOrder() {
    #expect(HexDiagonal.allCases.count == 6)
    #expect(HexDiagonal.allCases.map(\.rawValue) == [0, 1, 2, 3, 4, 5])
    #expect(HexDiagonal(rawValue: -1) == nil)
    #expect(HexDiagonal(rawValue: 6) == nil)
  }

  @Test("Diagonal neighbors follow the order of the diagonal indices")
  func diagonalNeighborsFollowTheIndexOrder() {
    let center = Hex(q: -4, r: 7)
    #expect(center.diagonalNeighbors == HexDiagonal.allCases.map { center.diagonalNeighbor($0) })
    #expect(Hex.zero.diagonalNeighbors == HexDiagonal.allCases.map(\.vector))
  }

  // MARK: Geometry

  /// Diagonal `i` lies between the directions `i` and `i + 1`.
  @Test("A diagonal is the sum of two neighboring directions", arguments: table)
  func diagonalIsTheSumOfTwoDirections(_ row: DiagonalRow) throws {
    let first = try #require(HexDirection(rawValue: row.index))
    let second = try #require(HexDirection(rawValue: (row.index + 1) % 6))
    #expect(row.diagonal.vector == first.vector + second.vector)
  }

  @Test("A diagonal step reaches a hex two steps away, next to both directions")
  func diagonalStepIsTwoStepsAway() throws {
    let center = Hex(q: 3, r: -8)
    var mismatches: [String] = []
    for diagonal in HexDiagonal.allCases {
      let reached = center.diagonalNeighbor(diagonal)
      if reached.distance(to: center) != 2 || diagonal.vector.length != 2 {
        mismatches.append("distance \(diagonal)")
      }
      let first = try #require(HexDirection(rawValue: diagonal.rawValue))
      let second = try #require(HexDirection(rawValue: (diagonal.rawValue + 1) % 6))
      if reached.distance(to: center.neighbor(first)) != 1
        || reached.distance(to: center.neighbor(second)) != 1
      {
        mismatches.append("adjacency \(diagonal)")
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// `hex_rotate_left` of the reference is one counterclockwise step.
  @Test("The next diagonal is the previous one rotated counterclockwise")
  func nextDiagonalIsRotatedCounterclockwise() throws {
    for diagonal in HexDiagonal.allCases {
      let next = try #require(HexDiagonal(rawValue: (diagonal.rawValue + 1) % 6))
      #expect(diagonal.vector.rotated(by: -1) == next.vector)
    }
  }

  /// The case names say which cube coordinate changes by 2, and in which way.
  @Test("Case names give the coordinate that changes by two")
  func caseNamesGiveTheCoordinateThatChangesByTwo() {
    #expect(HexDiagonal.plusQ.vector.q == 2)
    #expect(HexDiagonal.minusR.vector.r == -2)
    #expect(HexDiagonal.plusS.vector.s == 2)
    #expect(HexDiagonal.minusQ.vector.q == -2)
    #expect(HexDiagonal.plusR.vector.r == 2)
    #expect(HexDiagonal.minusS.vector.s == -2)
  }

  /// Near the edge of the supported coordinate range the step still fits `Int`.
  @Test("Diagonal neighbors at the edge of the coordinate range")
  func diagonalNeighborsAtTheEdgeOfTheRange() {
    let edge = Hex(q: Hex.coordinateBound - 1, r: 0)
    #expect(edge.diagonalNeighbor(.plusQ) == Hex(q: Hex.coordinateBound + 1, r: -1))
    #expect(edge.diagonalNeighbor(.minusQ) == Hex(q: Hex.coordinateBound - 3, r: 1))
  }

  // MARK: Codable

  @Test("Encoding uses the diagonal index")
  func encodingUsesTheIndex() throws {
    let json = String(decoding: try JSONEncoder().encode([HexDiagonal.minusQ]), as: UTF8.self)
    #expect(json == "[3]")
  }

  @Test("Decoding an index outside zero to five fails")
  func decodingRejectsAnIndexOutsideTheRange() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([HexDiagonal].self, from: Data("[6]".utf8))
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([HexDiagonal].self, from: Data("[-1]".utf8))
    }
  }
}
