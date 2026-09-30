import SwiftUI

/// The diagrams of the guide to hexagonal grids by Red Blob Games, drawn with
/// HexagonKit and HexagonKitUI.
@main
struct HexagonKitDemoApp: App {
  @State private var settings = DemoSettings()

  var body: some Scene {
    WindowGroup {
      ContentView(launch: .current)
        .environment(settings)
    }
  }
}
