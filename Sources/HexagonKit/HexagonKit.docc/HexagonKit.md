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

## Algorithms

The algorithms of the guide are methods of ``Hex``. Each returns a finished
value: an array in a fixed order where the order means something, a set or a
dictionary where it does not. Walls, opacity and step costs come in as closures,
which may be asked about the same cell several times and in any order, so they
should only answer.

@Snippet(path: "HexagonKit/Snippets/Algorithms", slice: "neighborhood")

@Snippet(path: "HexagonKit/Snippets/Algorithms", slice: "lines")

@Snippet(path: "HexagonKit/Snippets/Algorithms", slice: "obstacles")

A map shape numbers its cells, so ``DenseHexMap`` keeps one value per cell in a
flat array, and ``WrappedHexagon`` joins the opposite edges of a hexagonal map.

@Snippet(path: "HexagonKit/Snippets/Algorithms", slice: "storage")

@Snippet(path: "HexagonKit/Snippets/Algorithms", slice: "wraparound")

## Topics

### Coordinates

- ``Hex``
- ``FractionalHex``
- ``HexDirection``
- ``HexDiagonal``
- ``HexAxis``
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
- ``DenseHexMap``
- ``WrappedHexagon``
