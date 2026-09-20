import HexagonKitUI
import Testing

@Suite("HexagonKitUI placeholder")
struct HexagonKitUISmokeTests {

  /// `HexagonKitUI` is an empty placeholder until stage 4; this test only proves
  /// that the module and its test target build and run on every platform.
  @Test("The placeholder module builds and its test target runs")
  func placeholderModuleBuilds() {
    #expect(Int.bitWidth >= 32)
  }
}
