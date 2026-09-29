import HexagonKit
import Testing

/// A table of step costs, as the examples of doc-016, section 8, give them:
/// every step not in the table cannot be taken.
struct StepCosts: Sendable {
  let steps: [[Hex]: Double]

  func cost(from: Hex, to: Hex) -> Double? {
    steps[[from, to]]
  }

  func total(of path: [Hex]) -> Double {
    zip(path, path.dropFirst()).reduce(0) { $0 + (steps[[$1.0, $1.1]] ?? .nan) }
  }
}

@Suite("Hex.path")
struct PathTests {

  /// The walls of the pathfinding diagram of the guide; everything farther than
  /// 5 steps from the origin is a wall as well.
  static let walls: Set<Hex> = ReachableTests.walls

  static func unitCost(from: Hex, to: Hex) -> Double? {
    walls.contains(to) || to.length > 5 ? nil : 1
  }

  /// Checks that a path is a real one: from `start` to `goal`, one step at a
  /// time, and only through steps `cost` allows.
  static func isAPath(
    _ path: [Hex], from start: Hex, to goal: Hex, cost: (Hex, Hex) -> Double?
  ) -> Bool {
    path.first == start && path.last == goal
      && zip(path, path.dropFirst()).allSatisfy { $0.distance(to: $1) == 1 && cost($0, $1) != nil }
  }

  // MARK: The scene of the guide

  @Test("Path costs through the scene of the guide")
  func pathCostsThroughTheScene() throws {
    let goals: [(goal: Hex, cost: Int)] = [
      (Hex(q: 4, r: 0), 7), (Hex(q: -4, r: 4), 14), (Hex(q: 0, r: 4), 10),
      (Hex(q: 3, r: -1), 5), (Hex(q: -2, r: -2), 4), (Hex.zero, 0),
    ]
    for (goal, cost) in goals {
      let path = try #require(Hex.zero.path(to: goal, cost: Self.unitCost))
      #expect(path.count - 1 == cost)
      #expect(Self.isAPath(path, from: .zero, to: goal, cost: Self.unitCost))
    }
  }

  /// With unit costs the cheapest path is the shortest one, which a
  /// breadth-first search finds independently.
  @Test("With unit costs every open hex is reached as fast as a breadth-first search does")
  func unitCostsMatchABreadthFirstSearch() throws {
    var moves: [Hex: Int] = [.zero: 0]
    var fringe = [Hex.zero]
    while !fringe.isEmpty {
      var next: [Hex] = []
      for hex in fringe {
        for neighbor in hex.neighbors
        where moves[neighbor] == nil && Self.unitCost(from: hex, to: neighbor) != nil {
          moves[neighbor] = (moves[hex] ?? 0) + 1
          next.append(neighbor)
        }
      }
      fringe = next
    }
    #expect(moves.count == 76)
    var mismatches: [String] = []
    for (goal, steps) in moves {
      let path = Hex.zero.path(to: goal, cost: Self.unitCost)
      if path?.count != steps + 1 {
        mismatches.append("\(goal): \(String(describing: path?.count)) != \(steps + 1)")
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Optimality against an independent search

  /// A made-up map: a hexagon of radius 4 with a few walls and a cost for every
  /// step, the same on every run.
  static func weightedCost(_ costs: ClosedRange<Int>) -> (Hex, Hex) -> Double? {
    { from, to in
      guard to.length <= 4, (to.q * 3 + to.r * 5 + 70) % 7 != 0 else { return nil }
      let mix = abs(from.q * 7 + from.r * 13 + to.q * 17 + to.r * 29 + from.q * to.r)
      return Double(costs.lowerBound + mix % (costs.count))
    }
  }

  /// Dijkstra's algorithm over whole numbers, with no heuristic and no queue:
  /// the cheapest cost from `start` to every hex it reaches.
  static func cheapestCosts(from start: Hex, cost: (Hex, Hex) -> Double?) -> [Hex: Int] {
    var settled: [Hex: Int] = [:]
    var tentative: [Hex: Int] = [start: 0]
    while let (hex, total) = tentative.min(by: {
      ($0.value, $0.key.q, $0.key.r) < ($1.value, $1.key.q, $1.key.r)
    }) {
      tentative[hex] = nil
      settled[hex] = total
      for neighbor in hex.neighbors where settled[neighbor] == nil {
        guard let step = cost(hex, neighbor) else { continue }
        let candidate = total + Int(step)
        if candidate < tentative[neighbor] ?? Int.max {
          tentative[neighbor] = candidate
        }
      }
    }
    return settled
  }

  @Test(
    "A* finds a cheapest path on weighted maps",
    arguments: [(1...9, 1.0), (2...9, 2.0), (0...9, 0.0)])
  func aStarFindsACheapestPath(costs: ClosedRange<Int>, minimumStepCost: Double) {
    let cost = Self.weightedCost(costs)
    let starts = [Hex.zero, Hex(q: 3, r: -1), Hex(q: -2, r: 4), Hex(q: 1, r: 2)]
    var mismatches: [String] = []
    for start in starts {
      let cheapest = Self.cheapestCosts(from: start, cost: cost)
      for goal in Hex.zero.range(radius: 4) {
        let path = start.path(to: goal, minimumStepCost: minimumStepCost, cost: cost)
        guard let expected = cheapest[goal] else {
          if path != nil {
            mismatches.append("\(start) -> \(goal): found a path to an unreachable hex")
          }
          continue
        }
        guard let path, Self.isAPath(path, from: start, to: goal, cost: cost) else {
          mismatches.append("\(start) -> \(goal): no valid path")
          continue
        }
        let total = zip(path, path.dropFirst()).reduce(0) { $0 + Int(cost($1.0, $1.1) ?? 0) }
        if total != expected {
          mismatches.append("\(start) -> \(goal): \(total) != \(expected)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  // MARK: Contract

  @Test("A path to the start itself is the start, without asking about any step")
  func pathToItselfIsTheStart() {
    var asked = 0
    let path = Hex(q: 2, r: 2).path(to: Hex(q: 2, r: 2), searchLimit: 1) { _, _ in
      asked += 1
      return 1
    }
    #expect(path == [Hex(q: 2, r: 2)])
    #expect(asked == 0)
  }

  @Test("An unreachable goal on a bounded map gives nil")
  func unreachableGoalGivesNil() {
    #expect(Hex.zero.path(to: Hex(q: 6, r: 0), cost: Self.unitCost) == nil)
    let enclosed = Hex(q: 3, r: 0)
    #expect(
      Hex.zero.path(to: enclosed) { _, to in to.length > 5 || to == Hex(q: 2, r: 0) ? nil : 1 }
        != nil)
    let walledIn = Set(enclosed.neighbors)
    #expect(
      Hex.zero.path(to: enclosed) { _, to in to.length > 5 || walledIn.contains(to) ? nil : 1 }
        == nil)
  }

  /// doc-016, section 3.8: on an open grid the straight line of length 5 takes
  /// exactly 6 hexes off the queue, the goal included.
  @Test("The search limit counts the hexes taken off the queue, the goal included")
  func searchLimitCountsTheHexesTakenOffTheQueue() {
    let goal = Hex(q: 5, r: 0)
    let path = Hex.zero.path(to: goal, searchLimit: 6) { _, _ in 1 }
    #expect(path == (0...5).map { Hex(q: $0, r: 0) })
    #expect(Hex.zero.path(to: goal, searchLimit: 5) { _, _ in 1 } == nil)
  }

  @Test("Each hex is taken off the queue at most once")
  func eachHexIsTakenOffTheQueueAtMostOnce() {
    var froms: [Hex] = []
    let cost = Self.weightedCost(1...9)
    _ = Hex(q: -3, r: 1).path(to: Hex(q: 4, r: -2)) { from, to in
      froms.append(from)
      return cost(from, to)
    }
    var runs: [Hex: Int] = [:]
    for (index, from) in froms.enumerated() where index == 0 || froms[index - 1] != from {
      runs[from, default: 0] += 1
    }
    #expect(runs.values.allSatisfy { $0 == 1 })
  }

  @Test("A minimum step cost of zero turns the search into Dijkstra's algorithm")
  func zeroMinimumStepCostIsDijkstra() throws {
    for goal in [Hex(q: 4, r: 0), Hex(q: -4, r: 4), Hex(q: 0, r: 4)] {
      let astar = try #require(Hex.zero.path(to: goal, cost: Self.unitCost))
      let dijkstra = try #require(Hex.zero.path(to: goal, minimumStepCost: 0, cost: Self.unitCost))
      #expect(astar.count == dijkstra.count)
    }
    let free = Hex.zero.path(to: Hex(q: 3, r: 0), minimumStepCost: 0) { _, _ in -0.0 }
    #expect(free?.first == .zero && free?.last == Hex(q: 3, r: 0))
  }

  // MARK: Regressions of the review

  /// The counterexample of the review of doc-016: the returned path is the
  /// exact optimum, `L + 2`, yet its sum in `Double` is larger than that of
  /// the other route, whose ones vanish in rounding. The documentation
  /// promises the cheapest path only when the sums are exact.
  @Test("Inexact sums: the exact optimum may have the larger sum in Double")
  func inexactSumsKeepTheExactOptimum() throws {
    let large = 9_007_199_254_740_992.0
    let table = StepCosts(steps: [
      [Hex(q: 0, r: 0), Hex(q: 1, r: 0)]: large,
      [Hex(q: 1, r: 0), Hex(q: 1, r: 1)]: 1,
      [Hex(q: 1, r: 1), Hex(q: 1, r: 2)]: 1,
      [Hex(q: 1, r: 2), Hex(q: 0, r: 3)]: 1,
      [Hex(q: 0, r: 0), Hex(q: 0, r: 1)]: 1,
      [Hex(q: 0, r: 1), Hex(q: 0, r: 2)]: 1,
      [Hex(q: 0, r: 2), Hex(q: 0, r: 3)]: large,
    ])
    let path = try #require(Hex.zero.path(to: Hex(q: 0, r: 3), cost: table.cost))
    #expect(path == [Hex(q: 0, r: 0), Hex(q: 0, r: 1), Hex(q: 0, r: 2), Hex(q: 0, r: 3)])
    let other = [
      Hex(q: 0, r: 0), Hex(q: 1, r: 0), Hex(q: 1, r: 1), Hex(q: 1, r: 2), Hex(q: 0, r: 3),
    ]
    #expect(table.total(of: path) == large + 2)
    #expect(table.total(of: other) == large)
  }

  /// A minimum step cost above the real minimum: the goal comes off the queue
  /// before the cheap step is ever asked about, so the search returns the
  /// costlier path without stopping.
  @Test("An overstated minimum step cost can return a costlier path")
  func overstatedMinimumStepCostCanReturnACostlierPath() throws {
    let table = StepCosts(steps: [
      [Hex(q: 0, r: 0), Hex(q: 1, r: 0)]: 5,
      [Hex(q: 1, r: 0), Hex(q: 2, r: 0)]: 5,
      [Hex(q: 0, r: 0), Hex(q: 0, r: 1)]: 5,
      [Hex(q: 0, r: 1), Hex(q: 1, r: 1)]: 1,
      [Hex(q: 1, r: 1), Hex(q: 2, r: 0)]: 1,
    ])
    let path = try #require(
      Hex.zero.path(to: Hex(q: 2, r: 0), minimumStepCost: 5, cost: table.cost))
    #expect(table.total(of: path) == 10)
    #expect(
      table.total(of: [Hex(q: 0, r: 0), Hex(q: 0, r: 1), Hex(q: 1, r: 1), Hex(q: 2, r: 0)]) == 7)
  }
}

/// The example of the third review: the search computes an infinite sum for the
/// step from `(0, 1)` to `(1, 1)`, which loses to the other route.
func infiniteSumCost(from: Hex, to: Hex) -> Double? {
  StepCosts(steps: [
    [Hex(q: 0, r: 0), Hex(q: 1, r: 0)]: 1,
    [Hex(q: 1, r: 0), Hex(q: 1, r: 1)]: 1.5e308,
    [Hex(q: 0, r: 0), Hex(q: 0, r: 1)]: 1e308,
    [Hex(q: 0, r: 1), Hex(q: 1, r: 1)]: 1e308,
  ]).cost(from: from, to: to)
}

#if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
  /// Exit tests run the closure in a child process and expect it to stop; they
  /// exist from Swift 6.2 on, so older compilers skip this suite.
  @Suite("Hex.path preconditions")
  struct PathPreconditionTests {

    @Test("A minimum step cost that is not a number stops the search")
    func minimumStepCostNaNStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 3, r: 0), minimumStepCost: .nan) { _, _ in 1 }
      }
    }

    @Test("An infinite minimum step cost stops the search")
    func infiniteMinimumStepCostStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 3, r: 0), minimumStepCost: .infinity) { _, _ in 1 }
      }
    }

    @Test("A negative minimum step cost stops the search")
    func negativeMinimumStepCostStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 3, r: 0), minimumStepCost: -1) { _, _ in 1 }
      }
    }

    @Test("A search limit of zero stops the search")
    func zeroSearchLimitStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 3, r: 0), searchLimit: 0) { _, _ in 1 }
      }
    }

    @Test("A step cost that is not a number stops the search")
    func stepCostNaNStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 3, r: 0)) { _, _ in .nan }
      }
    }

    @Test("An infinite step cost stops the search")
    func infiniteStepCostStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 3, r: 0)) { _, _ in .infinity }
      }
    }

    @Test("A negative step cost stops the search")
    func negativeStepCostStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 3, r: 0), minimumStepCost: 0) { _, _ in -1 }
      }
    }

    @Test("A step cheaper than the minimum step cost stops the search")
    func stepBelowTheMinimumStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 3, r: 0), minimumStepCost: 2) { _, _ in 1 }
      }
    }

    @Test("A path cost that overflows to infinity stops the search")
    func infinitePathCostStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 3, r: 0)) { _, _ in 1e308 }
      }
    }

    @Test("An infinite sum on a losing candidate stops the search")
    func infiniteSumOnALosingCandidateStops() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 1, r: 1), minimumStepCost: 0, cost: infiniteSumCost)
      }
    }

    /// The priority of the start alone is `10^9 * 10^300`, beyond `Double`.
    @Test("An infinite estimate stops the search at the start")
    func infiniteEstimateStopsAtTheStart() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.path(to: Hex(q: 1_000_000_000, r: 0), minimumStepCost: 1e300) { _, _ in 1e300 }
      }
    }
  }
#endif
