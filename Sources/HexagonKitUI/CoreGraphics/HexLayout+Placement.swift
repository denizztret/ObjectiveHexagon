#if canImport(CoreGraphics)
  import CoreGraphics
  import HexagonKit

  extension HexLayout {

    /// Returns the frames of some hexes in a layout with the same orientation
    /// and size and a zero origin, moved so that the bounds of all of them start
    /// at the zero point, and the size of those bounds.
    ///
    /// Internal: the one placement `HexGridLayout` and `HexCollectionViewLayout`
    /// share, tested with numbers on every platform. The frame of `hexes[i]` is
    /// `frames[i]`; a `nil` hex gets a `nil` frame and does not count towards the
    /// bounds. Without any hex the size is `.zero`.
    ///
    /// - Precondition: the size, every frame and the edges `maxX` and `maxY` of
    ///   every frame are finite as `CGFloat` values. The check runs after the
    ///   conversion, on the edges as `CGFloat` computes them, so it also catches
    ///   an overflow of `Float` on 32-bit watchOS devices, even where the stored
    ///   components are finite and only their sum is not.
    func placement(of hexes: [Hex?]) -> (size: CGSize, frames: [CGRect?]) {
      // A large origin would round the centers of nearby hexes together, so
      // the positions come from a layout whose origin is zero.
      let base = HexLayout(orientation: orientation, size: size)
      let centers = hexes.map { hex in hex.map { base.center(of: $0) } }
      let placed = centers.compactMap { $0 }
      guard let first = placed.first else {
        return (.zero, hexes.map { _ in nil })
      }
      var (minX, minY, maxX, maxY) = (first.x, first.y, first.x, first.y)
      for center in placed.dropFirst() {
        minX = min(minX, center.x)
        minY = min(minY, center.y)
        maxX = max(maxX, center.x)
        maxY = max(maxY, center.y)
      }
      let cell = Point(x: base.cellWidth, y: base.cellHeight)
      let size = Point(x: (maxX - minX) + cell.x, y: (maxY - minY) + cell.y)
      // One subtraction per coordinate: rounding is monotonic, so the smallest
      // origin is exactly zero and no frame reaches past the size.
      let origins = centers.map { center in
        center.map { Point(x: $0.x - minX, y: $0.y - minY) }
      }
      precondition(
        Self.placementIsFinite(
          size: size, origins: origins.compactMap { $0 }, cell: cell, in: CGFloat.NativeType.self),
        "The placement of the hexes overflows CGFloat: the size of the layout is too large.")
      let frames = origins.map { origin in
        origin.map { CGRect(x: $0.x, y: $0.y, width: cell.x, height: cell.y) }
      }
      return (CGSize(width: size.x, height: size.y), frames)
    }

    /// Returns whether a placement computed in `Double` is finite once it is
    /// converted to `Scalar`: the size, the cell, the origin of every frame and
    /// the edges that `Scalar` arithmetic adds up from them.
    ///
    /// Internal: `placement(of:)` passes the `NativeType` of `CGFloat`, which is
    /// `Float` on 32-bit watchOS devices, and the tests pass `Float` as well, so
    /// the arithmetic of those devices runs on every machine.
    static func placementIsFinite<Scalar: BinaryFloatingPoint>(
      size: Point, origins: [Point], cell: Point, in scalar: Scalar.Type
    ) -> Bool {
      let (width, height) = (Scalar(cell.x), Scalar(cell.y))
      guard Scalar(size.x).isFinite, Scalar(size.y).isFinite, width.isFinite, height.isFinite
      else { return false }
      return origins.allSatisfy { origin in
        let (x, y) = (Scalar(origin.x), Scalar(origin.y))
        return x.isFinite && y.isFinite && (x + width).isFinite && (y + height).isFinite
      }
    }
  }
#endif
