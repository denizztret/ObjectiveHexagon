extension Hex {

  /// Returns a cheapest path from this hex to a goal, or `nil` when the search
  /// finds none.
  ///
  /// This is A* search, as the guide recommends: the neighbors of a hex are its
  /// six adjacent hexes, and the heuristic is the distance to the goal scaled by
  /// `minimumStepCost`. Because no step costs less than that, the heuristic
  /// never overestimates. The path returned has the smallest total cost, the
  /// sum of `cost` over its consecutive pairs, whenever the search adds up its
  /// costs exactly in `Double`: for example, when `minimumStepCost` and every
  /// cost are whole numbers, and no path cost, even with `minimumStepCost` added
  /// for each step still left to the goal, reaches `2^53`. Otherwise the sums
  /// are rounded, and the path is the cheapest only up to that rounding. When
  /// several paths are equally cheap, which one is returned is not specified.
  /// A `minimumStepCost` of zero turns the search into Dijkstra's algorithm.
  ///
  /// Each hex is taken off the queue at most once, and `cost` is asked only
  /// about the steps from those hexes. It may be asked about the same step
  /// several times, and in any order, so it should give the same answer every
  /// time and have no side effects. The search does not call it when
  /// `goal == self`. Its integer arithmetic stays within `Int` as long as this
  /// hex, `goal` and every hex that `cost` lets the search step onto lie in the
  /// supported coordinate range; beyond it the search may stop on an overflow.
  ///
  /// - Parameters:
  ///   - goal: The hex to reach.
  ///   - minimumStepCost: A lower bound of the cost of every step; 1 by default.
  ///     The search relies on it: a step it asks about that costs less stops the
  ///     program, and a cheaper step it never asks about may leave it with a
  ///     costlier path.
  ///   - searchLimit: The largest number of distinct hexes the search may take
  ///     off its queue, the goal included, or `nil` for no limit. Without a
  ///     limit, the search is sure to end only when `cost` confines it to a
  ///     finite area, or when the goal is reachable and `minimumStepCost` is
  ///     above zero; a search for an unreachable goal on an unbounded area goes
  ///     on until memory runs out.
  ///   - cost: The cost of the step from a hex to an adjacent one, or `nil` when
  ///     that step cannot be taken.
  /// - Returns: The hexes of the path, from this hex through `goal`; `[self]`
  ///   when `goal == self`; `nil` when the goal cannot be reached or the search
  ///   limit runs out first.
  /// - Precondition: `minimumStepCost` is finite and `>= 0`; `searchLimit` is
  ///   `nil` or `> 0`; every cost `cost` returns is finite and
  ///   `>= minimumStepCost`; and every sum the search computes stays finite:
  ///   the cost of a path through a step it asks about, and that cost plus
  ///   `minimumStepCost` for each step still left to the goal. Only the steps
  ///   the search asks about are checked, and which ones it asks about is not
  ///   specified.
  public func path(
    to goal: Hex,
    minimumStepCost: Double = 1,
    searchLimit: Int? = nil,
    cost: (_ from: Hex, _ to: Hex) -> Double?
  ) -> [Hex]? {
    precondition(
      minimumStepCost.isFinite && minimumStepCost >= 0,
      "The minimum step cost must be finite and not negative.")
    precondition(searchLimit.map { $0 > 0 } ?? true, "A search limit must be greater than zero.")
    guard goal != self else { return [self] }

    /// The estimated cost of a path through `hex`: the cost of reaching it plus
    /// `minimumStepCost` for each step still left to the goal.
    func priority(of hex: Hex, reachedFor pathCost: Double) -> Double {
      let priority = pathCost + Double(hex.distance(to: goal)) * minimumStepCost
      precondition(priority.isFinite, "The estimated cost of a path must stay finite.")
      return priority
    }

    // `pathCosts` holds the cheapest known cost of every hex put on the queue and
    // `cameFrom` the step it was reached by; a hex that improves its cost goes on
    // the queue again, and the outdated entries are skipped as `taken` ones.
    var pathCosts: [Hex: Double] = [self: 0]
    var cameFrom: [Hex: Hex] = [:]
    var taken: Set<Hex> = []
    var queue = PriorityQueue<Hex>()
    queue.push(self, priority: priority(of: self, reachedFor: 0))
    while let hex = queue.pop() {
      guard !taken.contains(hex) else { continue }
      if let searchLimit, taken.count == searchLimit { return nil }
      if hex == goal { return Self.reconstructedPath(to: goal, cameFrom: cameFrom) }
      taken.insert(hex)
      // Every hex that went on the queue has a known cost; the start has 0.
      let hexCost = pathCosts[hex, default: 0]
      for direction in HexDirection.allCases {
        let next = hex.neighbor(direction)
        guard !taken.contains(next), let stepCost = cost(hex, next) else { continue }
        precondition(
          stepCost.isFinite && stepCost >= minimumStepCost,
          "The cost of a step must be finite and not below the minimum step cost.")
        // Both sums are checked as soon as they are computed, before the new cost
        // is compared with the known one, so a losing candidate cannot hide an
        // infinite sum.
        let nextCost = hexCost + stepCost
        precondition(nextCost.isFinite, "The cost of a path must stay finite.")
        let nextPriority = priority(of: next, reachedFor: nextCost)
        if let known = pathCosts[next], known <= nextCost { continue }
        pathCosts[next] = nextCost
        cameFrom[next] = hex
        queue.push(next, priority: nextPriority)
      }
    }
    return nil
  }

  /// Returns the path that ends at `goal`, walking the steps back to the start.
  private static func reconstructedPath(to goal: Hex, cameFrom: [Hex: Hex]) -> [Hex] {
    var path = [goal]
    while let previous = cameFrom[path[path.count - 1]] {
      path.append(previous)
    }
    return path.reversed()
  }
}
