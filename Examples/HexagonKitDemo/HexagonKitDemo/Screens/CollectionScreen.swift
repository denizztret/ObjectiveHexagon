#if os(iOS)
  import HexagonKit
  import HexagonKitUI
  import SwiftUI
  import UIKit

  /// The screen of the old demo of ObjectiveHexagon: a collection view with a
  /// colored hexagonal cell on every hex of a rectangle, in the order of a
  /// spiral. `HexCollectionViewLayout` places the items; each cell is the
  /// `Hexagon` of `OldDemoCell`, hosted with `UIHostingConfiguration`.
  struct CollectionScreen: View {
    @Environment(DemoSettings.self) private var settings

    var body: some View {
      let size = settings.cellSize
      ScreenFrame(
        caption: "\(OldDemo.cells.count) items for the \(OldDemo.shape.count) hexes of the "
          + "rectangle, numbered in the order of `spiral(radius:)`. A new size or orientation "
          + "is a new `HexLayout` of the collection view layout."
      ) {
        CollectionBoard(
          layout: HexLayout(orientation: settings.orientation, size: Point(x: size, y: size)),
          cells: OldDemo.cells)
      } controls: {
        OrientationPicker()
      }
    }
  }

  /// A collection view whose layout puts item `i` on `cells[i]`.
  struct CollectionBoard: UIViewRepresentable {
    let layout: HexLayout
    let cells: [Hex]

    func makeCoordinator() -> HexDataSource {
      HexDataSource(cells: cells, orientation: layout.orientation)
    }

    func makeUIView(context: Context) -> UICollectionView {
      let view = CenteredCollectionView(
        frame: .zero, collectionViewLayout: HexCollectionViewLayout(layout: layout, cells: cells))
      view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: HexDataSource.cell)
      view.dataSource = context.coordinator
      view.backgroundColor = .white
      return view
    }

    /// A new layout invalidates the collection view layout by itself, and the
    /// collection view moves its cells at the next layout pass; the cells are
    /// drawn again only when the orientation of their hexagons changes.
    func updateUIView(_ view: UICollectionView, context: Context) {
      guard let collectionLayout = view.collectionViewLayout as? HexCollectionViewLayout,
        collectionLayout.layout != layout
      else { return }
      collectionLayout.layout = layout
      if context.coordinator.orientation != layout.orientation {
        context.coordinator.orientation = layout.orientation
        view.reloadData()
      }
    }
  }

  /// One item per hex, each cell an `OldDemoCell`.
  @MainActor
  final class HexDataSource: NSObject, UICollectionViewDataSource {
    static let cell = "hex"
    let cells: [Hex]
    var orientation: Orientation

    init(cells: [Hex], orientation: Orientation) {
      self.cells = cells
      self.orientation = orientation
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
      -> Int
    {
      cells.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
      -> UICollectionViewCell
    {
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: Self.cell, for: indexPath)
      let (hex, orientation) = (cells[indexPath.item], orientation)
      cell.contentConfiguration = UIHostingConfiguration {
        OldDemoCell(hex: hex, number: indexPath.item, orientation: orientation)
      }
      .margins(.all, 0)
      return cell
    }
  }

  /// A collection view that scrolls its first item to the middle once, as the
  /// old demo did.
  final class CenteredCollectionView: UICollectionView {
    private var centered = false

    override func layoutSubviews() {
      super.layoutSubviews()
      if !centered, bounds.width > 0, numberOfItems(inSection: 0) > 0 {
        centered = true
        scrollToItem(
          at: IndexPath(item: 0, section: 0), at: [.centeredVertically, .centeredHorizontally],
          animated: false)
      }
    }
  }
#endif
