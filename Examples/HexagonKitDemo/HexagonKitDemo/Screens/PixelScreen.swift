import HexagonKit
import HexagonKitUI
import SwiftUI

/// Hex to pixel and back (`#hex-to-pixel-axial`, `#pixel-to-hex-axial`): the
/// basis vectors of the axes, and a point of the view as a fractional hex.
struct PixelScreen: View {
  enum Part: String, CaseIterable {
    case hexToPixel = "hex-to-pixel"
    case pixelToHex = "pixel-to-hex"
  }

  @State private var part: Part
  @State private var pointer: FractionalHex
  @Environment(DemoSettings.self) private var settings

  init(_ opening: Opening) {
    _part = State(initialValue: opening.part(or: .hexToPixel))
    _pointer = State(initialValue: opening.pointer ?? FractionalHex(q: 2.2, r: 1.2))
  }

  var body: some View {
    let orientation = settings.orientation
    ScreenFrame(caption: caption(orientation)) {
      switch part {
      case .hexToPixel:
        Board(diagram: Self.hexToPixel(orientation))
      case .pixelToHex:
        let diagram = Self.pixelToHex(orientation, pointer: pointer)
        Board(
          diagram: diagram,
          track: { fractional in
            if diagram.hex(holding: fractional) != nil {
              pointer = fractional
            }
          })
      }
    } controls: {
      PartPicker(selection: $part)
      OrientationPicker()
    }
  }

  private func caption(_ orientation: Orientation) -> String {
    switch part {
    case .hexToPixel:
      return orientation == .pointy
        ? "The q axis steps √3 × size to the right; the r axis steps √3/2 × size to the right "
          + "and 3/2 × size down. `center(of:)` adds them up."
        : "The q axis steps 3/2 × size to the right and √3/2 × size down; the r axis steps "
          + "√3 × size down. `center(of:)` adds them up."
    case .pixelToHex:
      let digits = FloatingPointFormatStyle<Double>(locale: Locale(identifier: "en_US"))
        .precision(.fractionLength(2))
      let hex = pointer.rounded()
      return
        "`hex(at:)` gives q = \(pointer.q.formatted(digits)), r = \(pointer.r.formatted(digits)), "
        + "s = \(pointer.s.formatted(digits)); `rounded()` gives the hex \(hex.q), \(hex.r), \(hex.s)."
    }
  }

  /// Four cells and the steps of the axes between their centers.
  static func hexToPixel(_ orientation: Orientation) -> Diagram {
    let cells = [Hex.zero, Hex(q: 1, r: 0), Hex(q: 0, r: 1), Hex(q: 1, r: 1)]
    var labels: [Hex: Label] = [:]
    for hex in cells {
      labels[hex] = .pair(hex.q, hex.r)
    }
    var marks: [Mark] = []
    for (from, to, axis) in [
      (Hex.zero, Hex(q: 1, r: 0), HexAxis.q), (Hex(q: 0, r: 1), Hex(q: 1, r: 1), .q),
      (Hex.zero, Hex(q: 0, r: 1), .r), (Hex(q: 1, r: 0), Hex(q: 1, r: 1), .r),
    ] {
      marks.append(.arrow(.between(from, to, 0.25), .between(from, to, 0.75), Palette.axis(axis)))
    }
    return Diagram(orientation: orientation, cells: cells, labels: labels, marks: marks)
  }

  /// A rectangle of cells, the hex that holds the pointer, the point itself as
  /// a red dot, and its way from the center of hex zero along the q axis and
  /// then along the r axis.
  static func pixelToHex(_ orientation: Orientation, pointer: FractionalHex) -> Diagram {
    let shape =
      orientation == .flat
      ? HexShape.rectangle(columns: 6, rows: 4, in: .oddQ)
      : HexShape.rectangle(columns: 5, rows: 5, in: .oddR)
    var diagram = Diagram(orientation: orientation, cells: shape.cells())
    for hex in diagram.cells {
      diagram.labels[hex] = .pair(hex.q, hex.r)
    }
    diagram.fills[pointer.rounded()] = Palette.pointed
    let alongQ = Spot.axial(pointer.q, 0)
    diagram.marks = [
      .arrow(.center(.zero), alongQ, Palette.axis(.q)),
      .arrow(alongQ, .axial(pointer.q, pointer.r), Palette.axis(.r)),
      .dot(.axial(pointer.q, pointer.r), .red, radius: 0.1),
    ]
    return diagram
  }
}
