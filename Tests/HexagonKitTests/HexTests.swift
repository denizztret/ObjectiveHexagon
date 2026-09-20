import Foundation
import HexagonKit
import Testing

@Suite("Hex")
struct HexTests {

  // MARK: Reference values

  /// Reference test `test_hex_arithmetic` of `lib.py`.
  @Test("Addition matches test_hex_arithmetic")
  func additionMatchesTheReference() {
    #expect(Hex(q: 1, r: -3) + Hex(q: 3, r: -7) == Hex(q: 4, r: -10))
  }

  /// Reference test `test_hex_arithmetic` of `lib.py`.
  @Test("Subtraction matches test_hex_arithmetic")
  func subtractionMatchesTheReference() {
    #expect(Hex(q: 1, r: -3) - Hex(q: 3, r: -7) == Hex(q: -2, r: 4))
  }

  /// `hex_scale` of `lib.py`; the reference tests do not cover it directly.
  @Test("Scaling multiplies every component")
  func scalingIsComponentwise() {
    #expect(Hex(q: 1, r: -3) * 3 == Hex(q: 3, r: -9))
    #expect((Hex(q: 1, r: -3) * 3).s == 6)
    #expect(Hex(q: 1, r: -3) * 0 == Hex.zero)
    #expect(Hex(q: 1, r: -3) * -2 == Hex(q: -2, r: 6))
  }

  /// Reference test `test_hex_distance` of `lib.py`.
  @Test("Distance and length match test_hex_distance")
  func distanceMatchesTheReference() {
    #expect(Hex(q: 3, r: -7).distance(to: Hex.zero) == 7)
    #expect(Hex(q: 3, r: -7).length == 7)
    #expect(Hex.zero.distance(to: Hex(q: 3, r: -7)) == 7)
  }

  /// Reference test `test_hex_neighbor` of `lib.py`: direction index 2.
  @Test("Neighbor matches test_hex_neighbor")
  func neighborMatchesTheReference() {
    #expect(Hex(q: 1, r: -2).neighbor(.plusSMinusR) == Hex(q: 1, r: -3))
  }

  /// Reference test `test_hex_rotate_right` of `lib.py`.
  @Test("One clockwise step matches test_hex_rotate_right")
  func clockwiseRotationMatchesTheReference() {
    #expect(Hex(q: 1, r: -3).rotated(by: 1) == Hex(q: 3, r: -2))
  }

  /// Reference test `test_hex_rotate_left` of `lib.py`.
  @Test("One counterclockwise step matches test_hex_rotate_left")
  func counterclockwiseRotationMatchesTheReference() {
    #expect(Hex(q: 1, r: -3).rotated(by: -1) == Hex(q: -2, r: -1))
  }

  /// Values of `ring(1)` around the origin, doc-008 section 10.
  @Test("Ring of radius one matches the guide")
  func ringOfRadiusOneMatchesTheGuide() {
    let expected = [
      Hex(q: -1, r: 1), Hex(q: 0, r: 1), Hex(q: 1, r: 0),
      Hex(q: 1, r: -1), Hex(q: 0, r: -1), Hex(q: -1, r: 0),
    ]
    #expect(Hex.zero.ring(radius: 1) == expected)
  }

  /// Values of `ring(2)` around the origin, doc-008 section 10.
  @Test("Ring of radius two matches the guide")
  func ringOfRadiusTwoMatchesTheGuide() {
    let expected = [
      Hex(q: -2, r: 2), Hex(q: -1, r: 2), Hex(q: 0, r: 2), Hex(q: 1, r: 1),
      Hex(q: 2, r: 0), Hex(q: 2, r: -1), Hex(q: 2, r: -2), Hex(q: 1, r: -2),
      Hex(q: 0, r: -2), Hex(q: -1, r: -1), Hex(q: -2, r: 0), Hex(q: -2, r: 1),
    ]
    #expect(Hex.zero.ring(radius: 2) == expected)
  }

  // MARK: Construction and the cube invariant

  @Test("The third cube component is derived from the first two")
  func thirdComponentIsDerived() {
    #expect(Hex(q: 1, r: -3).s == 2)
    #expect(Hex.zero == Hex(q: 0, r: 0))
    #expect(Hex.zero.s == 0)
    #expect(Hex.coordinateBound == 1 << 30)
  }

  @Test("The cube initializer rejects triples that do not sum to zero")
  func cubeInitializerChecksTheSum() {
    #expect(Hex(q: 1, r: -3, s: 2) == Hex(q: 1, r: -3))
    #expect(Hex(q: 1, r: -3, s: 3) == nil)
    #expect(Hex(q: 0, r: 0, s: 0) == Hex.zero)
    #expect(Hex(q: 0, r: 0, s: 1) == nil)
  }

  // MARK: Properties

  @Test("Length agrees with the reference formula on small values")
  func lengthAgreesWithTheReferenceFormula() {
    var mismatches: [String] = []
    for q in -8...8 {
      for r in -8...8 {
        let hex = Hex(q: q, r: r)
        let referenceFormula = (abs(q) + abs(r) + abs(-q - r)) / 2
        if hex.length != referenceFormula {
          mismatches.append("q=\(q) r=\(r): \(hex.length) != \(referenceFormula)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Distance is symmetric and satisfies the triangle inequality")
  func distanceIsAMetric() {
    let hexes = (-5...5).flatMap { q in (-5...5).map { r in Hex(q: q, r: r) } }
    var mismatches: [String] = []
    for a in hexes {
      for b in hexes {
        if a.distance(to: b) != b.distance(to: a) {
          mismatches.append("symmetry \(a) \(b)")
        }
        if (a == b) != (a.distance(to: b) == 0) {
          mismatches.append("identity \(a) \(b)")
        }
      }
    }
    let corners = [Hex.zero, Hex(q: 4, r: -2), Hex(q: -3, r: 5), Hex(q: 2, r: 2)]
    for a in corners {
      for b in corners {
        for c in hexes where a.distance(to: c) > a.distance(to: b) + b.distance(to: c) {
          mismatches.append("triangle \(a) \(b) \(c)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// The boundary pair of the guaranteed coordinate range: the distance is
  /// representable, the reference form `(|dq| + |dr| + |ds|) / 2` is not,
  /// because the sum of the three absolute differences reaches `4 * 2^30`.
  @Test("The distance of the boundary pair stays representable")
  func boundaryPairDistanceIsRepresentable() {
    let bound = Hex.coordinateBound
    let east = Hex(q: bound - 1, r: 0)
    let west = Hex(q: -(bound - 1), r: 0)
    #expect(east.length == bound - 1)
    #expect(east.distance(to: west) == (bound - 1) * 2)
    #expect(west.distance(to: east) == (bound - 1) * 2)
  }

  @Test("Neighbors follow the order of the direction indices")
  func neighborsFollowDirectionOrder() {
    let center = Hex(q: 2, r: -5)
    #expect(center.neighbors.count == 6)
    #expect(center.neighbors == HexDirection.allCases.map { center.neighbor($0) })
    #expect(center.neighbors.allSatisfy { $0.distance(to: center) == 1 })
    #expect(Set(center.neighbors).count == 6)
  }

  @Test("Rotation depends only on the step count modulo six")
  func rotationIsPeriodic() {
    let hex = Hex(q: 4, r: -9)
    let center = Hex(q: -3, r: 2)
    var mismatches: [String] = []
    for steps in -13...13 {
      let reduced = ((steps % 6) + 6) % 6
      if hex.rotated(by: steps, around: center) != hex.rotated(by: reduced, around: center) {
        mismatches.append("steps=\(steps)")
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
    #expect(hex.rotated(by: 0, around: center) == hex)
    #expect(hex.rotated(by: 6, around: center) == hex)
    #expect(hex.rotated(by: 600_000, around: center) == hex)
    #expect(hex.rotated(by: -600_000, around: center) == hex)
  }

  @Test("Rotation keeps the center fixed and preserves the distance to it")
  func rotationPreservesTheDistanceToTheCenter() {
    let center = Hex(q: -3, r: 2)
    #expect(center.rotated(by: 1, around: center) == center)
    #expect(center.rotated(by: 4, around: center) == center)
    var mismatches: [String] = []
    for q in -4...4 {
      for r in -4...4 {
        let hex = Hex(q: q, r: r)
        for steps in 0...5 {
          let rotated = hex.rotated(by: steps, around: center)
          if rotated.distance(to: center) != hex.distance(to: center) {
            mismatches.append("q=\(q) r=\(r) steps=\(steps)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("Rotation around the origin is the default")
  func rotationAroundTheOriginIsTheDefault() {
    #expect(Hex(q: 1, r: -3).rotated(by: 1) == Hex(q: 1, r: -3).rotated(by: 1, around: .zero))
  }

  @Test("A ring of radius zero is the center itself")
  func ringOfRadiusZeroIsTheCenter() {
    #expect(Hex(q: 2, r: -5).ring(radius: 0) == [Hex(q: 2, r: -5)])
    #expect(Hex.zero.ring(radius: 0) == [Hex.zero])
  }

  @Test("A ring has six times the radius cells, all at that distance")
  func ringHasSixTimesRadiusCells() {
    var mismatches: [String] = []
    for center in [Hex.zero, Hex(q: 7, r: -13)] {
      for radius in 1...12 {
        let ring = center.ring(radius: radius)
        if ring.count != 6 * radius {
          mismatches.append("count \(center) \(radius): \(ring.count)")
        }
        if Set(ring).count != ring.count {
          mismatches.append("duplicates \(center) \(radius)")
        }
        if ring.contains(where: { $0.distance(to: center) != radius }) {
          mismatches.append("distance \(center) \(radius)")
        }
        for index in ring.indices {
          let next = ring[(index + 1) % ring.count]
          if ring[index].distance(to: next) != 1 {
            mismatches.append("adjacency \(center) \(radius) \(index)")
          }
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  @Test("A ring starts at direction index four times the radius")
  func ringStartsAtDirectionFour() {
    var mismatches: [String] = []
    for center in [Hex.zero, Hex(q: -4, r: 6)] {
      for radius in 1...8 {
        let expected = center + HexDirection.plusRMinusQ.vector * radius
        if center.ring(radius: radius).first != expected {
          mismatches.append("\(center) \(radius)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Regressions of the Objective-C library

  /// ObjectiveHexagon looked cells up by the string form of the coordinate, and
  /// `hexConvertAxialToCube` produced `-0` at the origin, so the central cell of
  /// every map was unreachable (doc-002, error 1).
  @Test("The central cell is found when hexes are used as dictionary keys")
  func centralCellIsReachableThroughAHexKey() {
    var map: [Hex: Int] = [:]
    for (index, hex) in ([Hex.zero] + Hex.zero.ring(radius: 1)).enumerated() {
      map[hex] = index
    }
    #expect(map[Hex.zero] == 0)
    #expect(map[Hex(q: 0, r: 0)] == 0)
    #expect(map.count == 7)
  }

  /// ObjectiveHexagon had two names for the same scaling operation
  /// (`hex3DMultiply` and `hex3DScale`, doc-002 error 6); there is one now.
  @Test("Scaling by one is the identity")
  func scalingByOneIsTheIdentity() {
    #expect(Hex(q: 5, r: -2) * 1 == Hex(q: 5, r: -2))
  }

  // MARK: Codable

  @Test("Encoding keeps only the two stored axial coordinates")
  func encodingKeepsOnlyQAndR() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let json = String(decoding: try encoder.encode(Hex(q: 1, r: -3)), as: UTF8.self)
    #expect(json == #"{"q":1,"r":-3}"#)
  }

  @Test("Decoding restores the hex")
  func decodingRestoresTheHex() throws {
    let hex = try JSONDecoder().decode(Hex.self, from: Data(#"{"q":1,"r":-3}"#.utf8))
    #expect(hex == Hex(q: 1, r: -3))
    #expect(hex.s == 2)
  }
}
