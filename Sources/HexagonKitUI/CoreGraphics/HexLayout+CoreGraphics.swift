#if canImport(CoreGraphics)
  import CoreGraphics
  import HexagonKit

  extension HexLayout {

    /// Returns the rectangle that bounds the six corners of a hex.
    ///
    /// The rectangle is in the coordinate space of the layout, the space of
    /// `center(of:)`. Its center is the center of the hex, and its size is
    /// `cellWidth` by `cellHeight` for every hex. Where the geometry is
    /// representable (see <doc:RepresentableGeometry>) and both components of
    /// `size` are above about 1e-300, `minX` and `minY` are exactly the smallest
    /// coordinates of the corners, and `width` and `height` are exactly
    /// `cellWidth` and `cellHeight`; `maxX` and `maxY`, which `CGRect` computes
    /// as sums, may differ from the largest coordinates of the corners by up to
    /// three units in the last place of the larger of the center and the size of
    /// a cell. The method never stops the program; outside that region the
    /// rectangle follows IEEE 754 and may hold infinities or NaN.
    ///
    /// The rectangles of adjacent hexes overlap, so a point may lie in two of
    /// them. To find the hex under a point, use ``hex(at:)``.
    public func frame(of hex: Hex) -> CGRect {
      // Half of a cell is exact in binary, so the left and top edges land on the
      // corners of the core; no array of corners is built.
      let center = center(of: hex)
      return CGRect(
        x: center.x - cellWidth / 2, y: center.y - cellHeight / 2,
        width: cellWidth, height: cellHeight)
    }

    /// Returns the smallest rectangle that contains the rectangles of some hexes,
    /// or `nil` when there are none.
    ///
    /// The rectangle is in the coordinate space of the layout, and its width and
    /// height are the distance between the extreme centers plus the size of a
    /// cell. Where the geometry is representable (see
    /// <doc:RepresentableGeometry>), it is ``frame(of:)`` for a single hex, its
    /// `minX` and `minY` are exactly the smallest `minX` and `minY` of the
    /// rectangles of the hexes, and its right and bottom edges may differ from
    /// the extreme edges of those rectangles by up to six units in the last
    /// place of the largest of the extreme centers and the size of a cell.
    /// Hexes that repeat change nothing. The method never stops the program;
    /// outside that region the rectangle may hold infinities or NaN.
    ///
    /// The sequence is walked once; the work is proportional to its length.
    public func bounds(of hexes: some Sequence<Hex>) -> CGRect? {
      var remaining = hexes.makeIterator()
      guard let first = remaining.next() else { return nil }
      let start = center(of: first)
      var (minX, minY, maxX, maxY) = (start.x, start.y, start.x, start.y)
      while let hex = remaining.next() {
        let center = center(of: hex)
        minX = min(minX, center.x)
        minY = min(minY, center.y)
        maxX = max(maxX, center.x)
        maxY = max(maxY, center.y)
      }
      // The size is the extent of the centers plus a cell, not a difference of
      // edges: the bounds of a single hex are then its frame bit for bit.
      return CGRect(
        x: minX - cellWidth / 2, y: minY - cellHeight / 2,
        width: (maxX - minX) + cellWidth, height: (maxY - minY) + cellHeight)
    }

    /// Returns the smallest rectangle that contains the rectangles of the cells
    /// of a shape, or `nil` when the shape has no cells.
    ///
    /// The result is the same as `bounds(of: shape.cells())`, with the same
    /// guarantees and never a stop, but the cells are visited by index with
    /// `hex(at:)`, and no array of cells is built. The work is proportional to
    /// `count`: about three million cells for a hexagon of radius 1000.
    public func bounds(of shape: HexShape) -> CGRect? {
      bounds(of: (0..<shape.count).lazy.map(shape.hex(at:)))
    }

    /// Returns the fractional hex that contains a point of the layout, such as
    /// the location of a tap in the view that draws it.
    ///
    /// The point is converted to a `Point` exactly, and the result is that of
    /// `hex(at:)` for it. Call `rounded()` on the result to get the hex; a point
    /// on an edge or a corner goes to one of the hexes that meet there, as
    /// `rounded()` decides. This method never stops the program, but `rounded()`
    /// does when a component is not finite or lies outside the supported range,
    /// which a point that is not finite, or a point far away from the cells of a
    /// tiny layout, can reach.
    public func hex(at point: CGPoint) -> FractionalHex {
      hex(at: Point(point))
    }
  }
#endif
