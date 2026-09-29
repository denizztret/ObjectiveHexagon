import HexagonKit
import Testing

@Suite("Hex.reachable")
struct ReachableTests {

  /// The walls of the movement-range and pathfinding diagrams of the guide.
  static let walls: Set<Hex> = [
    Hex(q: 2, r: -1), Hex(q: 2, r: 0), Hex(q: 0, r: 2), Hex(q: -1, r: 2), Hex(q: -1, r: 1),
    Hex(q: 1, r: -1), Hex(q: 1, r: 2), Hex(q: 1, r: -3), Hex(q: 0, r: -2), Hex(q: -1, r: -1),
    Hex(q: 2, r: 1), Hex(q: -2, r: 1), Hex(q: -3, r: 2), Hex(q: -4, r: 3), Hex(q: -5, r: 4),
  ]

  static func isPassable(_ hex: Hex) -> Bool {
    !walls.contains(hex)
  }

  // MARK: The scene of the guide

  @Test("Four steps through the scene of the guide")
  func fourStepsThroughTheScene() {
    let moves = Hex.zero.reachable(steps: 4, isPassable: Self.isPassable)
    #expect(moves.count == 23)
    #expect((0...4).map { step in moves.values.filter { $0 == step }.count } == [1, 4, 3, 5, 10])
    let third: Set<Hex> = [
      Hex(q: 2, r: -2), Hex(q: 2, r: -3), Hex(q: -2, r: -1), Hex(q: -3, r: 0), Hex(q: -3, r: 1),
    ]
    let fourth: Set<Hex> = [
      Hex(q: 3, r: -2), Hex(q: 3, r: -3), Hex(q: 3, r: -4), Hex(q: 2, r: -4), Hex(q: -1, r: -2),
      Hex(q: -2, r: -2), Hex(q: -3, r: -1), Hex(q: -4, r: 0), Hex(q: -4, r: 1), Hex(q: -4, r: 2),
    ]
    #expect(Set(moves.filter { $0.value == 3 }.keys) == third)
    #expect(Set(moves.filter { $0.value == 4 }.keys) == fourth)
  }

  @Test("One and two steps through the scene of the guide")
  func oneAndTwoStepsThroughTheScene() {
    let one = Hex.zero.reachable(steps: 1, isPassable: Self.isPassable)
    #expect(
      one == [
        .zero: 0, Hex(q: 1, r: 0): 1, Hex(q: 0, r: -1): 1, Hex(q: -1, r: 0): 1, Hex(q: 0, r: 1): 1,
      ])
    let two = Hex.zero.reachable(steps: 2, isPassable: Self.isPassable)
    #expect(two.count == 8)
    #expect(two[Hex(q: 1, r: 1)] == 2)
    #expect(two[Hex(q: 1, r: -2)] == 2)
    #expect(two[Hex(q: -2, r: 0)] == 2)
  }

  /// Open hexes within four steps that the walls put out of reach.
  @Test("Open hexes behind the walls are out of reach")
  func openHexesBehindTheWallsAreOutOfReach() {
    let moves = Hex.zero.reachable(steps: 4, isPassable: Self.isPassable)
    let unreachable = [
      Hex(q: -4, r: 4), Hex(q: -3, r: 3), Hex(q: -3, r: 4), Hex(q: -2, r: 2), Hex(q: -2, r: 3),
      Hex(q: -2, r: 4), Hex(q: -1, r: -3), Hex(q: -1, r: 3), Hex(q: -1, r: 4), Hex(q: 0, r: -4),
      Hex(q: 0, r: -3), Hex(q: 0, r: 3), Hex(q: 0, r: 4), Hex(q: 1, r: -4), Hex(q: 1, r: 3),
      Hex(q: 2, r: 2), Hex(q: 3, r: -1), Hex(q: 3, r: 0), Hex(q: 3, r: 1), Hex(q: 4, r: -4),
      Hex(q: 4, r: -3), Hex(q: 4, r: -2), Hex(q: 4, r: -1), Hex(q: 4, r: 0),
    ]
    #expect(unreachable.allSatisfy { moves[$0] == nil && Self.isPassable($0) })
    #expect(unreachable.allSatisfy { $0.length <= 4 })
  }

  /// As in the guide's pseudocode, the start is never checked.
  @Test("A start on a wall is still in the result, and the search goes on")
  func startOnAWallIsStillInTheResult() {
    let start = Hex(q: 2, r: -1)
    let moves = start.reachable(steps: 2, isPassable: Self.isPassable)
    #expect(moves.count == 15)
    #expect(moves[start] == 0)
  }

  // MARK: Contract

  @Test("Zero steps give the start alone, without asking about any hex")
  func zeroStepsGiveTheStartAlone() {
    var asked = 0
    let moves = Hex(q: 3, r: -7).reachable(steps: 0) { _ in
      asked += 1
      return true
    }
    #expect(moves == [Hex(q: 3, r: -7): 0])
    #expect(asked == 0)
  }

  @Test("Without obstacles the keys are the range and the values the distances")
  func withoutObstaclesTheKeysAreTheRange() {
    for start in [Hex.zero, Hex(q: -5, r: 9)] {
      for steps in 0...6 {
        let moves = start.reachable(steps: steps) { _ in true }
        #expect(Set(moves.keys) == Set(start.range(radius: steps)))
        #expect(moves.allSatisfy { $0.value == $0.key.distance(to: start) })
      }
    }
  }

  @Test("Only the hexes the search steps onto are asked about, never the start")
  func onlyTheHexesSteppedOntoAreAskedAbout() {
    let start = Hex(q: 1, r: 1)
    var asked: [Hex] = []
    let moves = start.reachable(steps: 3) { hex in
      asked.append(hex)
      return !Self.walls.contains(hex)
    }
    #expect(!asked.contains(start))
    #expect(asked.allSatisfy { $0.distance(to: start) <= 3 })
    #expect(moves.keys.allSatisfy { $0 == start || asked.contains($0) })
  }

  /// An enclosed start ends the search as soon as a fringe comes out empty,
  /// however many steps are allowed.
  @Test("An enclosed start ends the search early")
  func enclosedStartEndsTheSearchEarly() {
    #expect(Hex.zero.reachable(steps: Int.max) { _ in false } == [.zero: 0])
    let pocket = Hex.zero.reachable(steps: Int.max) { $0.length <= 2 }
    #expect(pocket.count == 19)
    #expect(pocket.allSatisfy { $0.value == $0.key.length })
  }

  /// doc-016, section 3.5: at the edge of the coordinate range the flood fill
  /// still works where `range(radius:)` stops on its precondition.
  @Test("A flood fill at the edge of the coordinate range")
  func floodFillAtTheEdgeOfTheRange() {
    let start = Hex(q: 1_073_741_823, r: 0)
    let moves = start.reachable(steps: 1) { _ in true }
    #expect(moves.count == 7)
    #expect(moves[start] == 0)
    #expect(start.neighbors.allSatisfy { moves[$0] == 1 })
  }
}

#if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
  /// Exit tests run the closure in a child process and expect it to stop; they
  /// exist from Swift 6.2 on, so older compilers skip this suite.
  @Suite("Hex.reachable preconditions")
  struct ReachablePreconditionTests {

    @Test("A negative number of steps stops the search")
    func negativeStepsStopTheSearch() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.reachable(steps: -1) { _ in true }
      }
    }
  }
#endif
