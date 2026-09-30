# ``HexagonKitUI``

Bridges from HexagonKit to Core Graphics, SwiftUI and UIKit.

## Overview

The module adds no geometry of its own: every point, rectangle and path comes
from the `HexLayout` of HexagonKit. A cell has the rectangle
``HexagonKit/HexLayout/frame(of:)``, a point of a view goes back to a hex with
``HexagonKit/HexLayout/hex(at:)``, and ``Hexagon`` draws one cell in any
rectangle. ``HexGridLayout`` places SwiftUI views on hexes, and
``HexCollectionViewLayout`` places the items of a collection view.

The layout works in a coordinate space whose y axis points down, as SwiftUI and
UIKit have it. Its numeric promises hold where the geometry is representable,
see <doc:RepresentableGeometry>. HexagonKitUI does not re-export the core:
import both modules.

@Snippet(path: "HexagonKitUI/Snippets/Drawing", slice: "bridge")

## Drawing a board

A `Canvas` needs only the paths of the cells and their centers.

@Snippet(path: "HexagonKitUI/Snippets/Drawing", slice: "canvas")

A board of views puts each view on its hex. ``Hexagon`` fills the rectangle a
view gets, which is the rectangle of its cell.

@Snippet(path: "HexagonKitUI/Snippets/Drawing", slice: "grid")

A collection view takes its items from a list of hexes in item order. To change
them, give the layout its new hexes together with the data source.

```swift
let collectionLayout = HexCollectionViewLayout(layout: layout, cells: cells)
let collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionLayout)

collectionLayout.cells = newCells
collectionView.reloadData()
```

## Topics

### Essentials

- <doc:RepresentableGeometry>

### SwiftUI

- ``Hexagon``
- ``HexGridLayout``

### UIKit

- ``HexCollectionViewLayout``
