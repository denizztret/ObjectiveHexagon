import Foundation
import HexagonKit
import Testing

@Suite("Point")
struct PointTests {

  @Test("A point stores its two components")
  func pointStoresItsComponents() {
    let point = Point(x: 1.5, y: -2.25)
    #expect(point.x == 1.5)
    #expect(point.y == -2.25)
    #expect(Point.zero == Point(x: 0, y: 0))
  }

  @Test("Equality follows the semantics of Double")
  func equalityFollowsDoubleSemantics() {
    #expect(Point(x: 0.0, y: -0.0) == Point(x: -0.0, y: 0.0))
    let notANumber = Point(x: .nan, y: 0)
    #expect(notANumber != notANumber)
  }

  @Test("A point round-trips through JSON as x and y")
  func pointRoundTripsThroughJSON() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let point = Point(x: 1.5, y: -2.25)
    let json = String(decoding: try encoder.encode(point), as: UTF8.self)
    #expect(json == #"{"x":1.5,"y":-2.25}"#)
    #expect(try JSONDecoder().decode(Point.self, from: Data(json.utf8)) == point)
  }
}
