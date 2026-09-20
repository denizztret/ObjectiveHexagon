import Foundation
import HexagonKit
import Testing

@Suite("Orientation")
struct OrientationTests {

  @Test("There are exactly two orientations")
  func thereAreTwoOrientations() {
    #expect(Orientation.allCases == [.pointy, .flat])
  }

  @Test("An orientation is encoded as the name of its case")
  func orientationIsEncodedAsAName() throws {
    let json = String(decoding: try JSONEncoder().encode([Orientation.pointy]), as: UTF8.self)
    #expect(json == #"["pointy"]"#)
    #expect(
      try JSONDecoder().decode([Orientation].self, from: Data(#"["flat"]"#.utf8)) == [.flat])
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([Orientation].self, from: Data(#"["sharp"]"#.utf8))
    }
  }
}
