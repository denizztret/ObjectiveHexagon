import SwiftUI

/// The list of screens beside the screen that is open.
struct ContentView: View {
  let launch: Launch
  @State private var page: Page?
  @State private var column: NavigationSplitViewColumn

  init(launch: Launch) {
    self.launch = launch
    _page = State(initialValue: launch.page)
    // A phone shows one column: the screen of the launch argument, or the list.
    _column = State(initialValue: launch.page == nil ? .sidebar : .detail)
  }

  var body: some View {
    NavigationSplitView(preferredCompactColumn: $column) {
      List(Page.allCases, selection: $page) { page in
        Text(page.entry.title)
      }
      .navigationTitle("HexagonKit")
    } detail: {
      if let page {
        page.screen(launch.opening(of: page))
          .id(page)
          .navigationTitle(page.entry.title)
          #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
          #endif
          .toolbar {
            if let guide = page.guide {
              Link("Guide", destination: guide)
            }
          }
      } else {
        Text("Choose a section of the guide.")
          .foregroundStyle(.secondary)
      }
    }
  }
}
