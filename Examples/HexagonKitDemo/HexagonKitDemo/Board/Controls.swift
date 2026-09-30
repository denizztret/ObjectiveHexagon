import HexagonKit
import SwiftUI

/// The frame of every screen: the boards, then a caption and the controls of
/// the screen, and the size of the cells every screen shares.
struct ScreenFrame<Boards: View, Controls: View>: View {
  let caption: String
  let boards: Boards
  let controls: Controls
  @Environment(DemoSettings.self) private var settings

  init(
    caption: String, @ViewBuilder boards: () -> Boards, @ViewBuilder controls: () -> Controls
  ) {
    self.caption = caption
    self.boards = boards()
    self.controls = controls()
  }

  var body: some View {
    @Bindable var settings = settings
    VStack(spacing: 0) {
      boards
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      VStack(alignment: .leading, spacing: 10) {
        Text(LocalizedStringKey(caption))
          .font(.callout)
          .fixedSize(horizontal: false, vertical: true)
        controls
        HStack {
          Text("Cell size")
          Slider(value: $settings.cellSize, in: 16...120)
        }
        .font(.callout)
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.bar)
    }
  }
}

/// A choice between a few values, each with its name: segments for up to four
/// values, a menu for more.
struct Choice<Value: Hashable & Sendable>: View {
  let title: String
  let values: [Value]
  @Binding var selection: Value
  let name: (Value) -> String

  var body: some View {
    let picker = Picker(title, selection: $selection) {
      ForEach(values, id: \.self) { value in
        Text(name(value)).tag(value)
      }
    }
    if values.count > 4 {
      picker.pickerStyle(.menu)
    } else {
      picker.pickerStyle(.segmented)
    }
  }
}

/// A choice between the diagrams of a screen; the raw value of a diagram names
/// it in the launch argument, such as `spiral` in `rings/spiral`, and reads as
/// its title: `spiral-coordinates` is `Spiral coordinates`.
struct PartPicker<Part: CaseIterable & Hashable & RawRepresentable & Sendable>: View
where Part.RawValue == String {
  @Binding var selection: Part

  var body: some View {
    Choice(title: "Diagram", values: Array(Part.allCases), selection: $selection) { part in
      let words = part.rawValue.replacingOccurrences(of: "-", with: " ")
      return words.prefix(1).uppercased() + words.dropFirst()
    }
  }
}

/// A choice between the offset or the doubled coordinate systems, by the names
/// of the guide.
struct SystemPicker<System: CaseIterable & Hashable & RawRepresentable & Sendable>: View
where System.RawValue == String {
  @Binding var selection: System

  var body: some View {
    Choice(title: "System", values: Array(System.allCases), selection: $selection) {
      Self.name($0)
    }
  }

  /// `oddR` reads `odd-r`, `doubleWidth` reads `double-width`.
  static func name(_ system: System) -> String {
    system.rawValue.map { $0.isUppercase ? "-" + $0.lowercased() : String($0) }.joined()
  }
}

/// The toggle of the guide between flat and pointy cells, shared by every
/// screen that has one.
struct OrientationPicker: View {
  @Environment(DemoSettings.self) private var settings

  var body: some View {
    @Bindable var settings = settings
    Choice(title: "Orientation", values: Orientation.allCases, selection: $settings.orientation) {
      $0.rawValue.capitalized
    }
  }
}

/// What a drag does on a board with walls: point at hexes or paint walls.
struct WallsToggle: View {
  @Binding var paints: Bool

  var body: some View {
    Toggle("Drag to toggle walls", isOn: $paints)
  }
}

/// Two boards side by side in a wide view, one above the other in a tall one.
struct Pair<First: View, Second: View>: View {
  @ViewBuilder var first: First
  @ViewBuilder var second: Second

  var body: some View {
    GeometryReader { proxy in
      let stack =
        proxy.size.width >= proxy.size.height
        ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
      stack {
        first
        second
      }
    }
  }
}
