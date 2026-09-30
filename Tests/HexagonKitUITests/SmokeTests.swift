import HexagonKitUI
import Testing

@Suite("HexagonKitUI on every platform")
struct HexagonKitUISmokeTests {

  /// Every other suite of this target needs Core Graphics, SwiftUI or UIKit.
  /// On Linux the module is empty, and this test only proves that the module
  /// and its test target build and run there too.
  @Test("The module and its test target build and run on every platform")
  func moduleBuildsEverywhere() {
    #expect(Int.bitWidth >= 32)
  }
}
