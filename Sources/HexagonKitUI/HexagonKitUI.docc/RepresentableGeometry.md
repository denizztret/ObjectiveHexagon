# Representable Geometry

Where the numeric promises of HexagonKitUI hold, and what happens elsewhere.

## Overview

The precision and finiteness that the documentation of HexagonKitUI promises hold
where the geometry is representable. The geometry of a call is representable
when both of the following are true:

- `CGFloat` is `Double`, as it is on every 64-bit platform;
- no value the call computes overflows `Double`: the centers and the corners of
  the hexes, `cellWidth` and `cellHeight`, the edges of a rectangle such as
  `minX + width`, the distance between the extreme centers plus the size of a
  cell, and the middle and the inset sides of the rectangle a ``Hexagon`` is
  drawn in.

A layout on a screen is far inside this region: a value approaches the limit of
`Double`, about 1.8e308, only with a cell size hundreds of orders of magnitude
larger than a screen.

Outside the region nothing numeric is promised: no tolerance holds, and the
results of the value bridges – the rectangles and paths of a `HexLayout`, the
point conversions and ``Hexagon`` – need not be finite. Those bridges never stop
the program; their results follow IEEE 754 and may hold infinities or NaN.

Being outside the region is not an error in itself. The containers
``HexGridLayout`` and ``HexCollectionViewLayout`` stop the program only when
their placement is not finite as `CGFloat` values: the size, the rectangles of
the hexes, and the edges `maxX` and `maxY` that `CGFloat` arithmetic computes
from them. They must not hand such values to SwiftUI or UIKit. Any other
placement works, inside the region or not.

On 32-bit watchOS devices `CGFloat` is `Float`, so every layout there lies
outside the region by its first condition, and an ordinary layout still works.
The bridges compute in `Double` as everywhere else and round each result to the
nearest `Float`; a value whose magnitude reaches `Float.greatestFiniteMagnitude`
plus half of its `ulp` becomes infinite. None of the tolerances of the
documentation applies there.
