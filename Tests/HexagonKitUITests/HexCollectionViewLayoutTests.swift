#if canImport(UIKit) && !os(watchOS)
  import HexagonKit
  @testable import HexagonKitUI
  import Testing
  import UIKit

  /// A data source of plain cells. The layout never asks it anything, so the
  /// tests use one that knows nothing about hexes.
  @MainActor
  final class PlainDataSource: NSObject, UICollectionViewDataSource {
    var count: Int

    init(count: Int) {
      self.count = count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
      -> Int
    {
      section == 0 ? count : 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
      -> UICollectionViewCell
    {
      collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    }
  }

  /// A collection view of 400 by 400 points with a layout and a data source of
  /// as many items as the layout has cells. The collection view holds its data
  /// source weakly, so this object keeps it.
  @MainActor
  final class CollectionStand {
    let view: UICollectionView
    let dataSource: PlainDataSource

    init(_ collectionLayout: HexCollectionViewLayout) {
      view = UICollectionView(
        frame: CGRect(x: 0, y: 0, width: 400, height: 400), collectionViewLayout: collectionLayout)
      view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
      dataSource = PlainDataSource(count: collectionLayout.cells.count)
      view.dataSource = dataSource
      view.layoutIfNeeded()
    }

    /// Whether every item of section 0 shows a cell on its frame. UIKit keeps
    /// the frame of a view as its center and its bounds, so the frame of a cell
    /// comes back within a unit in the last place of the larger of the
    /// coordinate and the cell.
    func cellsSit(on frames: [CGRect?]) -> Bool {
      frames.enumerated().allSatisfy { item, frame in
        guard let frame, let cell = view.cellForItem(at: IndexPath(item: item, section: 0)) else {
          return false
        }
        let size = Double(max(frame.width, frame.height))
        return [
          (cell.frame.minX, frame.minX), (cell.frame.minY, frame.minY),
          (cell.frame.width, frame.width), (cell.frame.height, frame.height),
        ].allSatisfy { ulps(Double($0), Double($1), of: max(abs(Double($1)), size)) <= 1 }
      }
    }
  }

  @Suite("HexCollectionViewLayout")
  @MainActor
  struct HexCollectionViewLayoutTests {

    static let layout = HexLayout(
      orientation: .pointy, size: Point(x: 10, y: 12), origin: Point(x: 50, y: -30))

    /// A spiral, the order of the old demo, with its outer ring.
    static let cells = Hex.zero.spiral(radius: 3)

    /// Returns a layout that has prepared its attributes.
    func prepared(_ layout: HexLayout, _ cells: [Hex]) -> HexCollectionViewLayout {
      let collectionLayout = HexCollectionViewLayout(layout: layout, cells: cells)
      collectionLayout.prepare()
      return collectionLayout
    }

    /// Returns the attributes of every item of section 0.
    func attributes(of collectionLayout: HexCollectionViewLayout, count: Int)
      -> [UICollectionViewLayoutAttributes?]
    {
      (0..<count).map {
        collectionLayout.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))
      }
    }

    // MARK: A layout on its own

    @Test("Each item gets the frame of the placement of its hex")
    func eachItemGetsTheFrameOfItsHex() throws {
      let collectionLayout = prepared(Self.layout, Self.cells)
      let placement = Self.layout.placement(of: Self.cells)
      for (item, frame) in placement.frames.enumerated() {
        let attributes = try #require(
          collectionLayout.layoutAttributesForItem(at: IndexPath(item: item, section: 0)))
        #expect(attributes.frame == frame)
        #expect(attributes.indexPath == IndexPath(item: item, section: 0))
        #expect(attributes.representedElementCategory == .cell)
      }
    }

    @Test("Preparing again gives equal attributes")
    func preparingAgainGivesEqualAttributes() {
      let collectionLayout = prepared(Self.layout, Self.cells)
      let first = attributes(of: collectionLayout, count: Self.cells.count).map { $0?.frame }
      collectionLayout.prepare()
      let second = attributes(of: collectionLayout, count: Self.cells.count).map { $0?.frame }
      #expect(first == second)
    }

    @Test("Other sections and items past the cells have no attributes")
    func otherItemsHaveNoAttributes() {
      let collectionLayout = prepared(Self.layout, Self.cells)
      let count = Self.cells.count
      #expect(
        collectionLayout.layoutAttributesForItem(at: IndexPath(item: count, section: 0)) == nil)
      #expect(collectionLayout.layoutAttributesForItem(at: IndexPath(item: 0, section: 1)) == nil)
    }

    @Test("A layout without cells has no size and no attributes")
    func layoutWithoutCellsHasNoSize() {
      let collectionLayout = prepared(Self.layout, [])
      #expect(collectionLayout.collectionViewContentSize == .zero)
      #expect(
        collectionLayout.layoutAttributesForElements(
          in: CGRect(x: -1e6, y: -1e6, width: 2e6, height: 2e6))?.isEmpty == true)
    }

    /// The old layout took the size of its whole grid; this one takes the size
    /// of the hexes it shows.
    @Test("The content size is the size of the bounds of the cells")
    func contentSizeIsTheBoundsOfTheCells() {
      let shown = Array(Self.cells.prefix(7))
      let collectionLayout = prepared(Self.layout, shown)
      let base = HexLayout(orientation: Self.layout.orientation, size: Self.layout.size)
      #expect(collectionLayout.collectionViewContentSize == base.bounds(of: shown)!.size)
    }

    /// Rectangles of every kind, among them thin strips at the seams of the
    /// rows, where the frames of two rows overlap: the answer is exactly the
    /// items whose frames intersect the rectangle, by their top edges and then
    /// by their numbers.
    @Test("The attributes in a rectangle are the items whose frames intersect it, in order")
    func attributesInARectangle() {
      let collectionLayout = prepared(Self.layout, Self.cells + Self.cells.prefix(3))
      let all = attributes(of: collectionLayout, count: Self.cells.count + 3).compactMap { $0 }
      let size = collectionLayout.collectionViewContentSize
      let rowHeight = CGFloat(Self.layout.verticalSpacing)
      var rectangles = [
        CGRect.zero, CGRect(x: -100, y: -100, width: 10, height: 10),
        CGRect(x: 20, y: 15, width: 30, height: 25), CGRect(origin: .zero, size: size),
        CGRect(x: -5, y: -5, width: size.width + 10, height: size.height + 10),
        CGRect.null, CGRect.infinite, CGRect(x: 40, y: 40, width: -20, height: -30),
      ]
      for row in 0..<8 {
        let seam = CGFloat(row) * rowHeight + CGFloat(Self.layout.cellHeight) / 4
        rectangles.append(CGRect(x: 0, y: seam, width: size.width, height: 0.5))
        rectangles.append(CGRect(x: 10, y: seam - 3, width: 1, height: 6))
      }
      for rect in rectangles {
        let expected = all.filter { $0.frame.intersects(rect) }
          .sorted { ($0.frame.minY, $0.indexPath.item) < ($1.frame.minY, $1.indexPath.item) }
        let found = collectionLayout.layoutAttributesForElements(in: rect) ?? []
        #expect(found.map(\.indexPath) == expected.map(\.indexPath), "\(rect)")
      }
    }

    /// Setting either property invalidates the layout, and the next prepare
    /// computes every item again; a hex that repeats gives its items one frame.
    @Test("New cells or a new layout give new attributes after the next prepare")
    func updatesGiveNewAttributes() {
      let collectionLayout = prepared(Self.layout, Self.cells)
      let cells = [Hex(q: 2, r: -1), Hex(q: -3, r: 3), Hex(q: 2, r: -1), .zero]
      collectionLayout.cells = cells
      collectionLayout.prepare()
      let placement = Self.layout.placement(of: cells)
      #expect(
        attributes(of: collectionLayout, count: cells.count).map { $0?.frame } == placement.frames)
      #expect(
        collectionLayout.layoutAttributesForItem(at: IndexPath(item: cells.count, section: 0))
          == nil)
      let flat = HexLayout(orientation: .flat, size: Point(x: 7, y: 9), origin: Point(x: -3, y: 8))
      collectionLayout.layout = flat
      collectionLayout.prepare()
      #expect(
        attributes(of: collectionLayout, count: cells.count).map { $0?.frame }
          == flat.placement(of: cells).frames)
      #expect(collectionLayout.collectionViewContentSize == flat.placement(of: cells).size)
    }

    @Test("The origin of the layout does not move the items")
    func originDoesNotMoveTheItems() {
      let near = HexLayout(orientation: .flat, size: Point(x: 1, y: 1))
      let far = HexLayout(orientation: .flat, size: Point(x: 1, y: 1), origin: Point(x: 1e20, y: 0))
      let cells = [Hex.zero, Hex(q: 1, r: 0)]
      let nearFrames = attributes(of: prepared(near, cells), count: 2).map { $0?.frame }
      let farFrames = attributes(of: prepared(far, cells), count: 2).map { $0?.frame }
      #expect(nearFrames == farFrames)
      #expect(farFrames[1]?.minX == 1.5)
    }

    @Test("A change of the bounds never invalidates the layout")
    func changeOfTheBoundsNeverInvalidates() {
      let collectionLayout = prepared(Self.layout, Self.cells)
      for bounds in [
        CGRect(x: 0, y: 40, width: 320, height: 480), CGRect(x: 0, y: 0, width: 480, height: 320),
        CGRect.zero,
      ] {
        #expect(!collectionLayout.shouldInvalidateLayout(forBoundsChange: bounds))
      }
    }

    // MARK: With a collection view

    /// A collection view lays out without a window and without a host
    /// application; its data source is not a view controller.
    @Test("A collection view shows its cells on the frames of the items")
    func collectionViewShowsTheCells() {
      let collectionLayout = HexCollectionViewLayout(layout: Self.layout, cells: Self.cells)
      let stand = CollectionStand(collectionLayout)
      #expect(stand.view.visibleCells.count == Self.cells.count)
      #expect(stand.cellsSit(on: Self.layout.placement(of: Self.cells).frames))
      collectionLayout.cells = Array(Self.cells.reversed().prefix(10))
      stand.dataSource.count = 10
      stand.view.reloadData()
      stand.view.layoutIfNeeded()
      #expect(stand.view.visibleCells.count == 10)
      #expect(stand.cellsSit(on: Self.layout.placement(of: collectionLayout.cells).frames))
    }

    /// Setting a property invalidates the layout by itself: the next layout
    /// pass of the collection view prepares it again and moves the cells,
    /// without a reload. A pass over a layout that is not invalidated keeps
    /// the old attributes.
    @Test("A new layout moves the cells at the next layout pass")
    func newLayoutMovesTheCells() {
      let collectionLayout = HexCollectionViewLayout(layout: Self.layout, cells: Self.cells)
      let stand = CollectionStand(collectionLayout)
      let flat = HexLayout(orientation: .flat, size: Point(x: 9, y: 7))
      collectionLayout.layout = flat
      stand.view.setNeedsLayout()
      stand.view.layoutIfNeeded()
      #expect(stand.cellsSit(on: flat.placement(of: Self.cells).frames))
    }

    /// The same for the hexes: new hexes for the same items invalidate the
    /// layout by themselves, so the next layout pass moves the cells, without a
    /// reload and without a call to `prepare()` from outside.
    @Test("New cells move the cells at the next layout pass")
    func newCellsMoveTheCells() {
      let collectionLayout = HexCollectionViewLayout(layout: Self.layout, cells: Self.cells)
      let stand = CollectionStand(collectionLayout)
      let reordered = Array(Self.cells.reversed())
      collectionLayout.cells = reordered
      stand.view.setNeedsLayout()
      stand.view.layoutIfNeeded()
      #expect(stand.cellsSit(on: Self.layout.placement(of: reordered).frames))
    }

    /// The frames of neighbors overlap, so a point near the corner of a frame
    /// may belong to another item. The recipe of the documentation goes back
    /// to a layout with a zero origin and finds the hex whose outline holds
    /// the point.
    @Test("The hit recipe of the documentation finds the hex under a point")
    func hitRecipeFindsTheHexUnderAPoint() {
      let collectionLayout = prepared(Self.layout, Self.cells)
      let base = HexLayout(orientation: Self.layout.orientation, size: Self.layout.size)
      let bounds = base.bounds(of: Self.cells)!
      var points: [CGPoint] = []
      for frame in Self.layout.placement(of: Self.cells).frames.compactMap({ $0 }) {
        for (x, y) in [
          (frame.minX, frame.minY), (frame.maxX, frame.minY), (frame.minX, frame.maxY),
        ] {
          points.append(CGPoint(x: x + 0.5, y: y + 0.5))
          points.append(CGPoint(x: x - 0.5, y: y - 0.5))
        }
      }
      for point in points {
        let hex = base.hex(at: CGPoint(x: point.x + bounds.minX, y: point.y + bounds.minY))
          .rounded()
        let outlines = Self.cells.filter {
          base.path(of: $0).offsetBy(dx: -bounds.minX, dy: -bounds.minY).contains(point)
        }
        if Self.cells.contains(hex) {
          #expect(outlines == [hex], "\(point)")
        } else {
          #expect(outlines.isEmpty, "\(point)")
        }
      }
      #expect(collectionLayout.collectionViewContentSize == bounds.size)
    }
  }
#endif
