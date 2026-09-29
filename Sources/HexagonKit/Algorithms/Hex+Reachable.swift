extension Hex {

  /// Returns every hex reachable from this hex in at most `steps` moves, each
  /// move to an adjacent passable hex, with the fewest moves that reach it.
  ///
  /// This is the guide's movement range with obstacles: a breadth-first flood
  /// fill limited by distance. This hex is always in the result with 0 moves,
  /// whether it is passable or not; `isPassable` is asked only about the hexes
  /// the search steps onto. Without obstacles, and whenever `range(radius: steps)`
  /// meets its own precondition, the keys are exactly the hexes of that range.
  ///
  /// `isPassable` may be called several times for the same hex, and in any
  /// order, so it should give the same answer every time and have no side
  /// effects. The search never leaves the range of `steps`, so it ends even on
  /// an unbounded grid. The dictionary has no particular order.
  ///
  /// - Precondition: `steps >= 0`.
  public func reachable(steps: Int, isPassable: (Hex) -> Bool) -> [Hex: Int] {
    precondition(steps >= 0, "The number of steps cannot be negative.")
    var moves: [Hex: Int] = [self: 0]
    // `fringe` holds the hexes first reached with `move - 1` moves, as the
    // guide's `fringes[k - 1]`. The neighbors of the last fringe are never
    // computed, so no coordinate goes further than `steps` from this hex.
    var fringe = [self]
    var move = 1
    // An empty fringe ends the search early: an enclosed start must not spin
    // through a huge number of steps.
    while move <= steps && !fringe.isEmpty {
      var next: [Hex] = []
      for hex in fringe {
        for direction in HexDirection.allCases {
          let neighbor = hex.neighbor(direction)
          if moves[neighbor] == nil && isPassable(neighbor) {
            moves[neighbor] = move
            next.append(neighbor)
          }
        }
      }
      fringe = next
      move += 1
    }
    return moves
  }
}
