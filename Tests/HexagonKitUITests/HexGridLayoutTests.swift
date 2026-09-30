#if canImport(SwiftUI) && _pointerBitWidth(_64)
  import HexagonKit
  @testable import HexagonKitUI
  import SwiftUI
  import Testing

  /// The frames the views of a board take, in the coordinate space of the
  /// board. `ImageRenderer` lays the board out without a window or an
  /// application, and every view records its frame while it does.
  @MainActor
  final class FrameRecorder {
    var frames: [String: CGRect] = [:]
  }

  /// A view that records its frame in the coordinate space of the board.
  struct RecordedView: View {
    let name: String
    let recorder: FrameRecorder

    var body: some View {
      GeometryReader { proxy in
        let frame = proxy.frame(in: .named("board"))
        let _ = MainActor.assumeIsolated { recorder.frames[name] = frame }
        Color.clear
      }
    }
  }

  /// A board of recorded views, one per element of `hexes`: a view without a
  /// hex for `nil`, with a smallest size of 4 by 3 points.
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  struct RecordedBoard: View {
    let layout: HexLayout
    let hexes: [Hex?]
    let recorder: FrameRecorder

    var body: some View {
      HexGridLayout(layout: layout) {
        ForEach(hexes.indices, id: \.self) { index in
          if let hex = hexes[index] {
            RecordedView(name: "\(index)", recorder: recorder).hexCell(hex)
          } else {
            RecordedView(name: "\(index)", recorder: recorder)
              .frame(minWidth: 4, idealWidth: 20, minHeight: 3, idealHeight: 20)
          }
        }
      }
      .background(RecordedView(name: "board", recorder: recorder))
      .coordinateSpace(name: "board")
      // Away from the corner of its parent, the board gets bounds that do not
      // start at zero.
      .padding(EdgeInsets(top: 13, leading: 7, bottom: 0, trailing: 0))
    }
  }

  @Suite("HexGridLayout")
  @MainActor
  struct HexGridLayoutTests {

    static let layouts = [
      HexLayout(orientation: .pointy, size: Point(x: 10, y: 14), origin: Point(x: 35, y: 71)),
      HexLayout(orientation: .flat, size: Point(x: 12.5, y: 9), origin: Point(x: -40, y: 90)),
      HexLayout(orientation: .flat, size: Point(x: 0.1, y: 3.7)),
    ]

    static let hexes: [Hex?] = HexShape.hexagon(center: Hex(q: -3, r: 1), radius: 2).cells()

    /// Returns the frames of the views of a board, keyed by the index of each
    /// view, and the frame of the board under the key `board`.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func layOut(
      _ layout: HexLayout, _ hexes: [Hex?], proposal: ProposedViewSize = .unspecified
    ) -> [String: CGRect] {
      let recorder = FrameRecorder()
      let renderer = ImageRenderer(
        content: RecordedBoard(layout: layout, hexes: hexes, recorder: recorder))
      renderer.proposedSize = proposal
      _ = renderer.cgImage
      return recorder.frames
    }

    /// SwiftUI places a view by its center and size, so its frame comes back
    /// within a few units in the last place of the placement.
    @Test("Each view sits on the frame of its hex")
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func eachViewSitsOnItsHex() throws {
      for layout in Self.layouts {
        let frames = layOut(layout, Self.hexes)
        let placement = layout.placement(of: Self.hexes)
        let cell = max(layout.cellWidth, layout.cellHeight)
        for (index, expected) in placement.frames.enumerated() {
          let frame = try #require(frames["\(index)"])
          let expected = try #require(expected)
          for (actual, target) in [
            (frame.minX, expected.minX), (frame.minY, expected.minY),
            (frame.maxX, expected.maxX), (frame.maxY, expected.maxY),
          ] {
            #expect(ulps(Double(actual), Double(target), of: max(abs(target), cell)) <= 4)
          }
        }
      }
    }

    @Test("The board takes the size of the placement, whatever is proposed")
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func boardTakesTheSizeOfThePlacement() {
      let layout = Self.layouts[1]
      let size = layout.placement(of: Self.hexes).size
      let proposals: [ProposedViewSize] = [
        .unspecified, .zero, .infinity, ProposedViewSize(width: 10, height: 1000),
        ProposedViewSize(width: nil, height: 5),
      ]
      for proposal in proposals {
        #expect(
          layOut(layout, Self.hexes, proposal: proposal)["board"]
            == CGRect(origin: .zero, size: size))
      }
    }

    @Test("A view without a hex sits in the top leading corner with its smallest size")
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func viewWithoutAHexSitsInTheCorner() {
      let layout = Self.layouts[0]
      let frames = layOut(layout, Self.hexes + [nil])
      #expect(frames["\(Self.hexes.count)"] == CGRect(x: 0, y: 0, width: 4, height: 3))
      #expect(frames["board"]?.size == layout.placement(of: Self.hexes).size)
    }

    @Test("Views on the same hex overlap")
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func viewsOnTheSameHexOverlap() {
      let frames = layOut(Self.layouts[0], [Hex(q: 1, r: 0), .zero, Hex(q: 1, r: 0)])
      #expect(frames["0"] != nil && frames["0"] == frames["2"])
      #expect(frames["0"] != frames["1"])
    }

    /// With the centers of the layout itself, the hexes of this board would
    /// collapse onto one point: `1e20 + 0` and `1e20 + 1.5` are the same number.
    @Test("A large origin does not move the views")
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func largeOriginDoesNotMoveTheViews() {
      let size = Point(x: 1, y: 1)
      let far = HexLayout(orientation: .flat, size: size, origin: Point(x: 1e20, y: 0))
      let near = HexLayout(orientation: .flat, size: size)
      let hexes: [Hex?] = [.zero, Hex(q: 1, r: 0)]
      #expect(layOut(far, hexes) == layOut(near, hexes))
      #expect(layOut(far, hexes)["1"]?.minX == 1.5)
    }

    @Test("A board without hexes has no size")
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func boardWithoutHexesHasNoSize() {
      let frames = layOut(Self.layouts[0], [nil])
      #expect(frames["board"]?.size == .zero)
    }

    @Test("Outside the container a hex changes nothing")
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func hexOutsideTheContainerChangesNothing() {
      let recorder = FrameRecorder()
      let content = VStack {
        RecordedView(name: "view", recorder: recorder).frame(width: 30, height: 20)
          .hexCell(Hex(q: 3, r: -1))
      }
      .coordinateSpace(name: "board")
      _ = ImageRenderer(content: content).cgImage
      #expect(recorder.frames["view"] == CGRect(x: 0, y: 0, width: 30, height: 20))
    }
  }
#endif
