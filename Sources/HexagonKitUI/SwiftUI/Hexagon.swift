#if canImport(SwiftUI)
  import HexagonKit
  import SwiftUI

  /// A hexagonal cell that fills the rectangle it is drawn in.
  ///
  /// The hexagon is the cell `Hex.zero` of the `HexLayout` of the same
  /// orientation whose ``HexagonKit/HexLayout/frame(of:)`` is the rectangle, so
  /// it touches all four sides of the rectangle. In a rectangle with the
  /// proportions of a regular cell, `cellWidth` by `cellHeight` of a layout with
  /// equal `size.x` and `size.y`, it is a regular hexagon; in any other rectangle
  /// it is stretched along one axis, as `Rectangle` and `Ellipse` are. Where the
  /// geometry is representable (see <doc:RepresentableGeometry>), the hexagon
  /// drawn in `frame(of: hex)` of any layout of the same orientation matches the
  /// cell of that layout, also when `size.x` and `size.y` differ, up to a few
  /// units in the last place of the larger of the coordinates of a corner and
  /// the size of the cell.
  ///
  /// The outline starts at corner 0 and runs through the corners in the order
  /// of `HexLayout.corners(of:)`, clockwise on screen, and it is not mirrored in
  /// a right-to-left layout. A rectangle without area, or with a coordinate that
  /// is not finite, gives an empty path whatever the inset: the rectangle is
  /// checked before the inset is applied. An inset that leaves no area gives an
  /// empty path too, and the shape never stops the program.
  ///
  /// ``inset(by:)`` moves every edge of a regular hexagon inwards by the same
  /// distance, so `strokeBorder(_:lineWidth:)` keeps the whole stroke inside the
  /// cell. In a stretched hexagon only the two edges parallel to a side of the
  /// rectangle move by exactly that distance; the four slanted ones move by a
  /// different one.
  public struct Hexagon: InsettableShape, Sendable {

    /// The orientation of the hexagon.
    public var orientation: Orientation

    /// The distance by which the edges of a regular hexagon move inwards; a
    /// negative value moves them outwards.
    public var inset: CGFloat

    /// Creates a hexagon that fills its rectangle, with its edges moved inwards
    /// by `inset`.
    public init(orientation: Orientation, inset: CGFloat = 0) {
      self.orientation = orientation
      self.inset = inset
    }

    /// Returns the outline of the hexagon in a rectangle.
    public func path(in rect: CGRect) -> Path {
      let (x, y) = (Double(rect.minX), Double(rect.minY))
      let (width, height) = (Double(rect.width), Double(rect.height))
      // The rectangle first, so that a negative inset cannot give area to a
      // rectangle without any.
      guard x.isFinite, y.isFinite, width.isFinite, height.isFinite, width > 0, height > 0
      else { return Path() }
      // A layout whose size is 1 gives the proportions of a cell; the ratio of
      // its sides turns an inset of the edges into an inset of the rectangle.
      let unit = HexLayout(orientation: orientation, size: Point(x: 1, y: 1))
      let amount = Double(inset)
      let (dx, dy) =
        switch orientation {
        case .pointy: (amount, amount * unit.cellHeight / unit.cellWidth)
        case .flat: (amount * unit.cellWidth / unit.cellHeight, amount)
        }
      let size = Point(
        x: (width - 2 * dx) / unit.cellWidth, y: (height - 2 * dy) / unit.cellHeight)
      let center = Point(x: x + width / 2, y: y + height / 2)
      // Then what the layout requires: a tiny or overflowing rectangle, or an
      // inset that leaves no area, gives an empty path instead of a stop.
      guard size.x.isFinite, size.y.isFinite, size.x > 0, size.y > 0,
        center.x.isFinite, center.y.isFinite
      else { return Path() }
      return HexLayout(orientation: orientation, size: size, origin: center).path(of: .zero)
    }

    /// Returns the hexagon with its edges moved inwards by `amount` more.
    public func inset(by amount: CGFloat) -> Hexagon {
      Hexagon(orientation: orientation, inset: inset + amount)
    }

    /// The inset, so that a change of it animates.
    public var animatableData: CGFloat {
      get { inset }
      set { inset = newValue }
    }

    /// Always `.fixed`: the corners keep their order in a right-to-left layout.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public var layoutDirectionBehavior: LayoutDirectionBehavior {
      .fixed
    }
  }
#endif
