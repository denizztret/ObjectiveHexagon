#if canImport(CoreGraphics)
  import CoreGraphics
  import HexagonKit

  extension CGPoint {

    /// Creates a point with the coordinates of a point of HexagonKit.
    ///
    /// Where `CGFloat` is `Double`, the coordinates are copied exactly. On
    /// 32-bit watchOS devices `CGFloat` is `Float`: there each coordinate is
    /// rounded to the nearest `Float`, and one whose magnitude reaches
    /// `Float.greatestFiniteMagnitude` plus half of its `ulp` becomes infinite.
    public init(_ point: Point) {
      self.init(x: point.x, y: point.y)
    }
  }

  extension Point {

    /// Creates a point with the coordinates of a Core Graphics point.
    ///
    /// The conversion is exact on every platform.
    public init(_ point: CGPoint) {
      self.init(x: Double(point.x), y: Double(point.y))
    }

    /// Creates a point from a size: `x` is the width and `y` is the height.
    ///
    /// Use it to pass a `CGSize` as the `size` of a `HexLayout`. That size is the
    /// size of the guide, the distance from the center of a cell to its corners
    /// along each axis, not the width and height of the cell. The conversion is
    /// exact on every platform.
    public init(_ size: CGSize) {
      self.init(x: Double(size.width), y: Double(size.height))
    }
  }
#endif
