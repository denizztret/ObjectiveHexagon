import Foundation
import HexagonKit

/// How the demo opens, from its launch arguments; the screenshot script of the
/// project opens every screen this way.
///
/// - `-screen <page>` or `-screen <page>/<diagram>`, such as `-screen line` or
///   `-screen rings/spiral`: the screen; without it the demo opens on the list.
/// - `-pointer <q>,<r>`, such as `-pointer -6,3` or `-pointer 2.2,1.2`: the hex,
///   or the fractional hex, under the pointer when the screen opens.
/// - `-walls on`: a drag paints walls from the start, on the screens with walls.
///
/// The arguments are read from the process itself: a value such as `-6,3`
/// starts with a minus sign, which the argument domain of `UserDefaults` would
/// take for the name of another argument.
struct Launch {
  let page: Page?
  let opening: Opening

  /// The launch arguments of this process.
  static let current = Launch(arguments: ProcessInfo.processInfo.arguments)

  init(arguments: [String]) {
    func value(of name: String) -> String? {
      guard let index = arguments.firstIndex(of: name), index + 1 < arguments.count else {
        return nil
      }
      return arguments[index + 1]
    }
    let names = value(of: "-screen")?.split(separator: "/", maxSplits: 1).map(String.init) ?? []
    let point = value(of: "-pointer")?.split(separator: ",").compactMap { Double($0) } ?? []
    page = names.first.flatMap(Page.init(rawValue:))
    opening = Opening(
      part: names.count > 1 ? names[1] : nil,
      pointer: point.count == 2 ? FractionalHex(q: point[0], r: point[1]) : nil,
      paintsWalls: value(of: "-walls") == "on")
  }

  /// How a page opens: as the launch arguments say when they name this page,
  /// in its own default state otherwise.
  func opening(of page: Page) -> Opening {
    page == self.page ? opening : Opening()
  }
}

/// The state a screen opens in, instead of its default one.
struct Opening {
  /// The name of a diagram of the screen.
  var part: String?

  /// The fractional hex under the pointer.
  var pointer: FractionalHex?

  /// Whether a drag paints walls.
  var paintsWalls = false

  /// The diagram the launch argument names, or `fallback` when it names none
  /// of the diagrams of the screen.
  func part<Part: RawRepresentable>(or fallback: Part) -> Part where Part.RawValue == String {
    part.flatMap(Part.init(rawValue:)) ?? fallback
  }

  /// The hex under the pointer, when the launch argument names a whole hex.
  var hex: Hex? {
    guard let pointer, pointer.q.rounded() == pointer.q, pointer.r.rounded() == pointer.r,
      abs(pointer.q) < 1e6, abs(pointer.r) < 1e6
    else { return nil }
    return pointer.rounded()
  }
}
