import HexagonKit
import Testing

@Suite("Hex.fieldOfView")
struct FieldOfViewTests {

  /// The walls of the field-of-view diagram of the guide, on a hexagon of
  /// radius 8 around the observer.
  static let walls: Set<Hex> = [
    Hex(q: 3, r: -3), Hex(q: 2, r: -3), Hex(q: 1, r: -3), Hex(q: -2, r: 0), Hex(q: -3, r: 0),
    Hex(q: -3, r: 2), Hex(q: -4, r: 2), Hex(q: -3, r: 3), Hex(q: -3, r: 4), Hex(q: 0, r: 2),
    Hex(q: 0, r: 3), Hex(q: 0, r: 4), Hex(q: 0, r: 5), Hex(q: 0, r: -3), Hex(q: 0, r: -4),
    Hex(q: 0, r: -5), Hex(q: 0, r: -6), Hex(q: 4, r: 2), Hex(q: 3, r: 3), Hex(q: -5, r: 2),
    Hex(q: -4, r: 0), Hex(q: -5, r: 0), Hex(q: -6, r: 0), Hex(q: -7, r: 0), Hex(q: -8, r: 0),
  ]

  // MARK: The scene of the guide

  /// doc-016, section 3.7: 108 visible hexes, 11 of them walls. The diagram of
  /// the guide shows 104 open hexes instead, with a more permissive test and
  /// walls never visible (deviation 13 of `Conformance.md`).
  @Test("The scene of the guide")
  func sceneOfTheGuide() {
    let visible = Hex.zero.fieldOfView(radius: 8) { Self.walls.contains($0) }
    #expect(visible.count == 108)
    #expect(visible.filter { Self.walls.contains($0) }.count == 11)
    #expect(visible.isSubset(of: Set(Hex.zero.range(radius: 8))))
  }

  /// The line of `lib.py` would show these three hexes; the line of the text
  /// hides them.
  @Test("The scene hides the hexes that only the nudge of lib.py would show")
  func sceneHidesWhatOnlyTheNudgeOfLibWouldShow() {
    let visible = Hex.zero.fieldOfView(radius: 8) { Self.walls.contains($0) }
    #expect(!visible.contains(Hex(q: -6, r: -2)))
    #expect(!visible.contains(Hex(q: -3, r: -1)))
    #expect(!visible.contains(Hex(q: 6, r: 2)))
  }

  /// Visibility is not promised to be mutual, but on the scene of the guide it
  /// is, for every pair of open hexes, with the nudge of the text; with the
  /// nudge of `lib.py` 12 pairs would not be.
  @Test("Visibility on the scene of the guide is mutual")
  func visibilityOnTheSceneIsMutual() {
    let open = Hex.zero.range(radius: 8).filter { !Self.walls.contains($0) }
    var views: [Hex: Set<Hex>] = [:]
    for observer in open {
      views[observer] = observer.fieldOfView(radius: 16) { Self.walls.contains($0) }
    }
    var mismatches: [String] = []
    for first in open {
      for second in open where first != second {
        let there = views[first]?.contains(second) ?? false
        let back = views[second]?.contains(first) ?? false
        if there != back {
          mismatches.append("\(first) <-> \(second)")
        }
      }
    }
    #expect(mismatches.isEmpty, "\(mismatches.prefix(5))")
  }

  /// The line from the origin to `(1, 1)` passes through `(0, 1)`, not `(1, 0)`.
  @Test("A wall hides a hex only when the line passes through it")
  func wallHidesAHexOnlyWhenTheLinePassesThroughIt() {
    let target = Hex(q: 1, r: 1)
    let first: Set<Hex> = [Hex(q: 1, r: 0)]
    let second: Set<Hex> = [Hex(q: 0, r: 1)]
    #expect(Hex.zero.fieldOfView(radius: 2) { first.contains($0) }.contains(target))
    #expect(!Hex.zero.fieldOfView(radius: 2) { second.contains($0) }.contains(target))
    #expect(!Hex.zero.fieldOfView(radius: 2) { first.union(second).contains($0) }.contains(target))
  }

  // MARK: Contract

  @Test("A wall is visible and hides the hexes behind it")
  func wallIsVisibleAndHidesTheHexesBehindIt() {
    let wall = Hex(q: 2, r: 0)
    let visible = Hex.zero.fieldOfView(radius: 4) { $0 == wall }
    #expect(visible.contains(wall))
    #expect(!visible.contains(Hex(q: 3, r: 0)))
    #expect(!visible.contains(Hex(q: 4, r: 0)))
    #expect(visible.contains(Hex(q: 1, r: 0)))
  }

  @Test("A radius of zero yields only the observer, asking about no hex")
  func radiusZeroYieldsOnlyTheObserver() {
    var asked = 0
    let visible = Hex(q: 5, r: -2).fieldOfView(radius: 0) { _ in
      asked += 1
      return true
    }
    #expect(visible == [Hex(q: 5, r: -2)])
    #expect(asked == 0)
  }

  @Test("Without walls every hex of the range is visible")
  func withoutWallsEveryHexIsVisible() {
    let center = Hex(q: -3, r: 8)
    #expect(center.fieldOfView(radius: 6) { _ in false } == Set(center.range(radius: 6)))
  }

  /// Between the observer and its neighbors there is no hex, so nothing can
  /// hide them; the opacity of the observer and of a target is never asked.
  @Test("The observer and its neighbors are always visible")
  func observerAndNeighborsAreAlwaysVisible() {
    let center = Hex(q: 2, r: 2)
    let expected = Set([center] + center.neighbors)
    #expect(center.fieldOfView(radius: 3) { _ in true } == expected)
    #expect(center.fieldOfView(radius: 3) { $0 == center } == Set(center.range(radius: 3)))
  }

  /// The closure is asked about hexes off the map too, and hexes off the map
  /// can be visible; hence the recipe of the documentation: answer `true` off
  /// the map and intersect the result with it.
  @Test("Hexes off the map are asked about and may be visible")
  func hexesOffTheMapAreAskedAboutAndMayBeVisible() {
    let map = HexShape.rectangle(columns: 4, rows: 4, in: .oddR)
    var asked: Set<Hex> = []
    let visible = Hex.zero.fieldOfView(radius: 3) { hex in
      asked.insert(hex)
      return !map.contains(hex)
    }
    #expect(!asked.isSubset(of: Set(map.cells())))
    #expect(!map.contains(Hex(q: -1, r: 0)))
    #expect(visible.contains(Hex(q: -1, r: 0)))
  }
}

#if compiler(>=6.2) && (os(macOS) || os(Linux) || os(Windows))
  /// Exit tests run the closure in a child process and expect it to stop; they
  /// exist from Swift 6.2 on, so older compilers skip this suite.
  @Suite("Hex.fieldOfView preconditions")
  struct FieldOfViewPreconditionTests {

    @Test("A negative radius stops the field of view")
    func negativeRadiusStopsTheFieldOfView() async {
      await #expect(processExitsWith: .failure) {
        _ = Hex.zero.fieldOfView(radius: -1) { _ in false }
      }
    }
  }
#endif
