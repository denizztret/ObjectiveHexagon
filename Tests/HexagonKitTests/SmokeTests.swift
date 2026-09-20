import Testing

@Suite("Package skeleton")
struct SmokeTests {

  /// The width of `Int` decides whether the guaranteed coordinate range of the
  /// library fits: real watchOS devices are 32-bit, their simulator is not.
  @Test("The test target builds and runs on a supported integer width")
  func integerWidthIsSupported() {
    #expect(Int.bitWidth == 64 || Int.bitWidth == 32)
  }
}
