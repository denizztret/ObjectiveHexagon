# ``HexagonKit``

Hexagonal grid math on the Swift standard library alone.

## Overview

HexagonKit follows the Red Blob Games guide to hexagonal grids. Cells are stored
in axial coordinates, the third cube coordinate is derived, and every conversion
names the coordinate system it reads.

@Snippet(path: "HexagonKit/Snippets/HexBasics")

## Recipes

Where the guide gives no direct algorithm, HexagonKit gives no method either:
convert to ``Hex``, do the work there, and convert back. Distances between
offset or doubled coordinates, the bridge between the two families, and the
pixel position of an offset or a doubled cell all follow this shape.

@Snippet(path: "HexagonKit/Snippets/CoordinateRecipes", slice: "distance")

@Snippet(path: "HexagonKit/Snippets/CoordinateRecipes", slice: "bridge")

@Snippet(path: "HexagonKit/Snippets/CoordinateRecipes", slice: "pixel")

## Topics

### Coordinates

- ``Hex``
- ``FractionalHex``
- ``HexDirection``
- ``OffsetSystem``
- ``OffsetCoordinate``
- ``DoubledSystem``
- ``DoubledCoordinate``

### Geometry

- ``Point``
- ``Orientation``
- ``Layout``

### Maps

- ``HexShape``
