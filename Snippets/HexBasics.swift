// snippet.hide
import HexagonKit

// snippet.show
// A cell, its neighbour and the distance between them.
let origin = Hex(q: 0, r: 0)
let target = Hex(q: 2, r: -1)
print(origin.distance(to: target))  // 2

// The pixel position of a cell on a pointy-top grid.
let layout = Layout(orientation: .pointy, size: Point(x: 20, y: 20))
let center = layout.center(of: target)
print(center.x, center.y)

// The same cell read as an odd-r offset coordinate.
let offset = OffsetCoordinate(target, in: .oddR)
print(offset.column, offset.row)
