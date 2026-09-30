#if canImport(SwiftUI)
  import HexagonKit
  import SwiftUI

  /// A container that places each of its subviews on a hex of a layout.
  ///
  /// Give every subview its hex with `hexCell(_:)`. The container proposes to a
  /// subview the size of ``HexagonKit/HexLayout/frame(of:)`` of its hex and puts
  /// the center of the subview on the center of the hex, so a ``Hexagon`` in the
  /// subview fills the cell. Subviews may come in any order; subviews on the
  /// same hex overlap.
  ///
  /// Positions are computed as if the `origin` of the layout were zero. The
  /// container takes the size of `bounds(of:)` of the hexes of its subviews in
  /// such a layout, whatever size is proposed to it, and no size when no
  /// subview has a hex. The hexes are shifted so that this rectangle starts at
  /// the top leading corner of the container: the `origin` of the layout does
  /// not move them, and hexes with negative coordinates stay inside. The size of
  /// a cell is the `size` of the layout, not a share of the proposal; to fit a
  /// board into a view, compute the layout from the size of the view.
  ///
  /// A subview without a hex is placed at the top leading corner of the
  /// container with a zero proposal, where it takes its smallest size; it does
  /// not change the size of the container.
  ///
  /// - Precondition: the placement is finite as `CGFloat` values: the size of
  ///   the container and the rectangle of every hex, together with the edges
  ///   `maxX` and `maxY` that `CGFloat` arithmetic computes from them. On 32-bit
  ///   watchOS devices those are `Float` values, which overflow near 3.4e38;
  ///   see <doc:RepresentableGeometry>. Only a `size` far beyond any screen
  ///   breaks it, such as a flat layout whose `size.x` is `1e307` with a hex
  ///   100 columns away.
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public struct HexGridLayout: Layout, Sendable {

    /// The mapping between hexes and positions in the container.
    public var layout: HexLayout

    /// Creates a container that places its subviews on the hexes of a layout.
    public init(layout: HexLayout) {
      self.layout = layout
    }

    /// Returns the size of the rectangle that bounds the hexes of the subviews,
    /// whatever the proposal.
    ///
    /// - Precondition: the placement is finite, as the type describes.
    public func sizeThatFits(
      proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) -> CGSize {
      layout.placement(of: subviews.map { $0[HexCellKey.self] }).size
    }

    /// Places each subview on its hex.
    ///
    /// - Precondition: the placement is finite, as the type describes.
    public func placeSubviews(
      in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
      let frames = layout.placement(of: subviews.map { $0[HexCellKey.self] }).frames
      for (subview, frame) in zip(subviews, frames) {
        if let frame {
          subview.place(
            at: CGPoint(x: bounds.minX + frame.midX, y: bounds.minY + frame.midY),
            anchor: .center, proposal: ProposedViewSize(frame.size))
        } else {
          subview.place(at: bounds.origin, anchor: .topLeading, proposal: .zero)
        }
      }
    }
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  extension View {

    /// Puts this view on a hex of the enclosing ``HexGridLayout``.
    ///
    /// Outside a ``HexGridLayout`` the hex has no effect.
    public func hexCell(_ hex: Hex) -> some View {
      layoutValue(key: HexCellKey.self, value: hex)
    }
  }

  /// The hex of a subview of `HexGridLayout`.
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  struct HexCellKey: LayoutValueKey {
    static let defaultValue: Hex? = nil
  }
#endif
