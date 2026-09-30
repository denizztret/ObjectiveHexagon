#if canImport(UIKit) && !os(watchOS)
  import HexagonKit
  import UIKit

  /// A collection view layout that puts each item of section 0 on a hex.
  ///
  /// Positions are computed as if the `origin` of the layout were zero. Item
  /// `i` of section 0 gets the rectangle of `cells[i]`,
  /// ``HexagonKit/HexLayout/frame(of:)`` of such a layout, shifted so that
  /// `bounds(of: cells)` of it starts at the top left corner of the content: the
  /// `origin` of the layout does not move the items, and hexes with negative
  /// coordinates can be scrolled to. The content size is the size of those
  /// bounds, and `.zero` when `cells` is empty. A hex may appear in `cells` more
  /// than once; its items then share a frame.
  ///
  /// The layout reads only `layout` and `cells`, never the data source, so keep
  /// the number of items of section 0 equal to `cells.count` and leave the
  /// other sections empty. Setting either property invalidates the layout, and
  /// the next ``prepare()`` computes the attributes of every item again. The
  /// geometry does not depend on the bounds of the collection view, so neither
  /// scrolling nor a change of size invalidates it.
  ///
  /// The frames of adjacent hexes overlap, so a point in the overlap lies in the
  /// frames of two items. To find the item under a point of the content exactly,
  /// take a layout with the same orientation and size and a zero origin, add the
  /// origin of its `bounds(of: cells)` to the point, round its `hex(at:)` of the
  /// sum, and look the hex up in `cells`.
  @MainActor
  public final class HexCollectionViewLayout: UICollectionViewLayout {

    /// The mapping between hexes and positions; setting it invalidates the layout.
    public var layout: HexLayout {
      didSet { invalidateLayout() }
    }

    /// The hex of each item of section 0, in item order; setting it invalidates
    /// the layout.
    public var cells: [Hex] {
      didSet { invalidateLayout() }
    }

    /// The attributes of every item, in item order, from the last `prepare()`.
    private var attributes: [UICollectionViewLayoutAttributes] = []

    /// The item numbers in the order of the top edges of their frames.
    private var itemsByTop: [Int] = []

    /// The size of the content, from the last `prepare()`.
    private var contentSize = CGSize.zero

    /// Creates a layout that puts item `i` of section 0 on `cells[i]`.
    public init(layout: HexLayout, cells: [Hex]) {
      self.layout = layout
      self.cells = cells
      super.init()
    }

    /// Unavailable: the layout is created in code, with its hexes.
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
      fatalError("init(coder:) is not supported")
    }

    /// Computes the attributes of every item from `layout` and `cells`.
    ///
    /// The frames are also sorted by their top edges here, so the work grows as
    /// `n log n` in the number of items. The collection view calls this method
    /// after every invalidation, before it asks for attributes.
    ///
    /// - Precondition: the content size and the frames of all items, together
    ///   with the edges `maxX` and `maxY` that `CGFloat` arithmetic computes
    ///   from them, are finite as `CGFloat` values; see
    ///   <doc:RepresentableGeometry>. Only a `size` far beyond any screen breaks
    ///   it, such as a flat layout whose `size.x` is `1e307` with a hex 100
    ///   columns away.
    public override func prepare() {
      super.prepare()
      let placement = layout.placement(of: cells)
      contentSize = placement.size
      // Every hex of `cells` has a frame.
      attributes = placement.frames.compactMap { $0 }.enumerated().map { item, frame in
        let attributes = UICollectionViewLayoutAttributes(
          forCellWith: IndexPath(item: item, section: 0))
        attributes.frame = frame
        return attributes
      }
      let tops = attributes.map(\.frame.minY)
      itemsByTop = tops.indices.sorted { (tops[$0], $0) < (tops[$1], $1) }
    }

    /// The size of the rectangle that bounds the hexes of all items, or `.zero`
    /// when there are none.
    public override var collectionViewContentSize: CGSize {
      contentSize
    }

    /// Returns the attributes of every item whose frame intersects a rectangle
    /// of the content, as `CGRect.intersects(_:)` decides.
    ///
    /// The attributes come in the order of the top edges of their frames, and of
    /// the items where those are equal. A binary search finds the items whose
    /// frames overlap the rectangle vertically, so the work grows with the
    /// logarithm of the number of items plus the number of those items.
    public override func layoutAttributesForElements(in rect: CGRect)
      -> [UICollectionViewLayoutAttributes]?
    {
      // All frames have the same height, so their bottom edges come in the same
      // order as their tops: the first candidate is the first frame whose bottom
      // edge reaches the rectangle, and the last one starts below it.
      var low = 0
      var high = itemsByTop.count
      while low < high {
        let middle = (low + high) / 2
        if attributes[itemsByTop[middle]].frame.maxY < rect.minY {
          low = middle + 1
        } else {
          high = middle
        }
      }
      var found: [UICollectionViewLayoutAttributes] = []
      for item in itemsByTop[low...] {
        let frame = attributes[item].frame
        if frame.minY > rect.maxY { break }
        if frame.intersects(rect) { found.append(attributes[item]) }
      }
      return found
    }

    /// Returns the attributes of an item of section 0, or `nil` for an item
    /// without a hex and for any other section.
    public override func layoutAttributesForItem(at indexPath: IndexPath)
      -> UICollectionViewLayoutAttributes?
    {
      guard indexPath.section == 0, attributes.indices.contains(indexPath.item) else { return nil }
      return attributes[indexPath.item]
    }

    /// Returns `false`: the geometry does not depend on the bounds of the
    /// collection view.
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
      false
    }
  }
#endif
