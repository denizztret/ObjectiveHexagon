import Testing

@testable import HexagonKit

@Suite("PriorityQueue")
struct PriorityQueueTests {

  @Test("An empty queue gives nothing")
  func emptyQueueGivesNothing() {
    var queue = PriorityQueue<Int>()
    #expect(queue.isEmpty)
    #expect(queue.pop() == nil)
  }

  @Test("Elements come out by priority, equal priorities in the order they went in")
  func elementsComeOutByPriorityThenByOrder() {
    var queue = PriorityQueue<Int>()
    // Priorities from a fixed sequence with many repeats.
    let priorities = (0..<500).map { Double(($0 * 37 + 11) % 23) }
    for (element, priority) in priorities.enumerated() {
      queue.push(element, priority: priority)
    }
    var popped: [Int] = []
    while let element = queue.pop() {
      popped.append(element)
    }
    let expected = priorities.indices.sorted { (priorities[$0], $0) < (priorities[$1], $1) }
    #expect(popped == expected)
    #expect(queue.isEmpty)
  }

  @Test("Pushes and pops can interleave")
  func pushesAndPopsCanInterleave() {
    var queue = PriorityQueue<String>()
    queue.push("c", priority: 3)
    queue.push("a", priority: 1)
    #expect(queue.pop() == "a")
    queue.push("b", priority: 2)
    queue.push("d", priority: 3)
    queue.push("z", priority: 0)
    #expect(queue.pop() == "z")
    #expect(queue.pop() == "b")
    #expect(queue.pop() == "c")
    #expect(queue.pop() == "d")
    #expect(queue.pop() == nil)
  }
}
