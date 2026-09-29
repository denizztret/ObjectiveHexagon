// snippet.hide
import HexagonKit

// snippet.show
// snippet.neighborhood
// Diagonal neighbors, reflections and spiral coordinates.
let hex = Hex(q: 1, r: -3)
print(hex.diagonalNeighbor(.plusQ))  // Hex(q: 3, r: -4)
print(hex.reflected(across: .q))  // Hex(q: 1, r: 2)
print(hex.spiralIndex(), Hex(spiralIndex: 25))  // 30 Hex(q: 3, r: 0)
// snippet.end

// snippet.lines
// A line between two cells, and every cell within a number of steps.
let start = Hex(q: 0, r: 0)
let target = Hex(q: 4, r: -2)
print(start.line(to: target).count)  // 5
print(start.range(radius: 2).count)  // 19
// snippet.end

// snippet.obstacles
// A wall between the start and the target: moving around it, seeing past it,
// and the cheapest path. The closures may be asked about a cell more than
// once, so they only answer and change nothing.
let wall: Set<Hex> = [Hex(q: 2, r: -2), Hex(q: 2, r: -1), Hex(q: 2, r: 0), Hex(q: 2, r: 1)]
let moves = start.reachable(steps: 6) { !wall.contains($0) }
print(moves[target] ?? -1)  // 6
let visible = start.fieldOfView(radius: 4) { wall.contains($0) }
print(visible.contains(Hex(q: 2, r: -1)), visible.contains(target))  // true false
let path = start.path(to: target) { _, next in wall.contains(next) ? nil : 1 }
print(path?.count ?? 0)  // 7
// snippet.end

// snippet.storage
// A value for every cell of a shape, kept in a flat array.
let shape = HexShape.parallelogram(columns: 4, rows: 3)
var heights = DenseHexMap(repeating: 0, shape: shape)
heights[Hex(q: 2, r: 1)] = 5
heights[Hex(q: 2, r: 1)]? += 1
heights[Hex(q: 9, r: 9)]? += 1  // off the shape: nothing happens
print(heights.values)  // [0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0]
// snippet.end

// snippet.wraparound
// A map whose edges wrap around: a step off one side comes back on the other.
let world = WrappedHexagon(radius: 2)
print(world.wrap(Hex(q: 3, r: 0)))  // Hex(q: -2, r: 2)
// snippet.end
