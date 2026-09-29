/// A binary min-heap: elements come out in the order of their priorities, and
/// elements of equal priority in the order they went in.
///
/// The standard library has no priority queue, and the core takes no
/// dependencies, so the pathfinding keeps its own.
struct PriorityQueue<Element> {

  /// One element with its priority and the number of pushes before it.
  private struct Entry {
    let priority: Double
    let order: Int
    let element: Element

    /// Returns whether this entry comes out before another one.
    func precedes(_ other: Entry) -> Bool {
      priority < other.priority || (priority == other.priority && order < other.order)
    }
  }

  /// The heap: every entry precedes both of its children.
  private var entries: [Entry] = []

  /// The number of pushes so far, which breaks ties between equal priorities.
  private var pushes = 0

  /// Whether the queue holds no element.
  var isEmpty: Bool { entries.isEmpty }

  /// Adds an element with a priority.
  mutating func push(_ element: Element, priority: Double) {
    entries.append(Entry(priority: priority, order: pushes, element: element))
    pushes += 1
    var child = entries.count - 1
    while child > 0 {
      let parent = (child - 1) / 2
      guard entries[child].precedes(entries[parent]) else { break }
      entries.swapAt(child, parent)
      child = parent
    }
  }

  /// Removes and returns the element that comes out first, or `nil` when the
  /// queue is empty.
  mutating func pop() -> Element? {
    guard !entries.isEmpty else { return nil }
    entries.swapAt(0, entries.count - 1)
    let top = entries.removeLast()
    var parent = 0
    while true {
      let left = 2 * parent + 1
      let right = left + 1
      var first = parent
      if left < entries.count && entries[left].precedes(entries[first]) {
        first = left
      }
      if right < entries.count && entries[right].precedes(entries[first]) {
        first = right
      }
      guard first != parent else { break }
      entries.swapAt(parent, first)
      parent = first
    }
    return top.element
  }
}
