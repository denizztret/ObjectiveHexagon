// snippet.hide
import HexagonKit

// snippet.show
// The guide gives direct formulas only where they are worth a method of their
// own. Everything else is a recipe: convert to `Hex`, do the work there, and
// convert back. These are the three recipes the library documents.

// snippet.distance
// Distance between two offset coordinates, and between two doubled ones.
let fromOffset = OffsetCoordinate(column: 1, row: -2)
let toOffset = OffsetCoordinate(column: 4, row: 3)
let offsetDistance = Hex(fromOffset, in: .oddR).distance(to: Hex(toOffset, in: .oddR))
print(offsetDistance)

let fromDoubled = DoubledCoordinate(column: 2, row: 0)!
let toDoubled = DoubledCoordinate(column: 7, row: 3)!
let doubledDistance = Hex(fromDoubled, in: .doubleWidth)
  .distance(to: Hex(toDoubled, in: .doubleWidth))
print(doubledDistance)
// snippet.end

// snippet.bridge
// From an offset coordinate to a doubled one, and back.
let offset = OffsetCoordinate(column: 3, row: -1)
let doubled = DoubledCoordinate(Hex(offset, in: .oddR), in: .doubleWidth)
let backAgain = OffsetCoordinate(Hex(doubled, in: .doubleWidth), in: .oddR)
print(doubled.column, doubled.row, backAgain == offset)
// snippet.end

// snippet.pixel
// From an offset or a doubled coordinate to a pixel position.
let layout = Layout(orientation: .pointy, size: Point(x: 20, y: 20))
let offsetCenter = layout.center(of: Hex(offset, in: .oddR))
let doubledCenter = layout.center(of: Hex(doubled, in: .doubleWidth))
print(offsetCenter.x, offsetCenter.y)
print(doubledCenter.x, doubledCenter.y)
// snippet.end
