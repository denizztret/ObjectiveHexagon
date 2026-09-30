#if canImport(SwiftUI)
  import HexagonKit
  import SwiftUI

  extension HexLayout {

    /// Returns the outline of a hex as a closed path.
    ///
    /// The path moves to corner 0, adds lines to corners 1 through 5 in the
    /// order of `corners(of:)`, and closes; with the y axis pointing down, as in
    /// SwiftUI and UIKit, it runs clockwise on screen. Where the start and the
    /// direction of a path show, as in `trim(from:to:)` or a dash pattern, they
    /// follow this order. The path is in the coordinate space of the layout; its
    /// `cgPath` serves Core Animation and UIKit. Where the geometry is
    /// representable (see <doc:RepresentableGeometry>), its points are the
    /// corners of the core; the method never stops the program.
    public func path(of hex: Hex) -> Path {
      let outline = CGMutablePath()
      addOutline(of: hex, to: outline)
      return Path(outline)
    }

    /// Returns the outlines of some hexes as one path: a closed subpath for each
    /// hex, in the order of the sequence.
    ///
    /// Each subpath is the path `path(of:)` returns for its hex, so all of them
    /// run the same way, and filling the path with the default non-zero rule
    /// fills exactly the hexes. An edge that two hexes share belongs to both
    /// subpaths, and a stroke of the path draws it twice; to draw each hex in its
    /// own color, draw one path per hex. The path of an empty sequence is empty.
    /// Where the geometry is representable (see <doc:RepresentableGeometry>),
    /// every point is a corner of the core; the method never stops the program.
    public func path(of hexes: some Sequence<Hex>) -> Path {
      let outlines = CGMutablePath()
      for hex in hexes {
        addOutline(of: hex, to: outlines)
      }
      return Path(outlines)
    }

    /// Adds the closed outline of a hex to a path, from corner 0 through corner 5.
    ///
    /// The outline goes into a `CGPath`: a `Path` built point by point may keep
    /// its points as `Float` values, and a corner of the core would then lose
    /// its last bits.
    private func addOutline(of hex: Hex, to path: CGMutablePath) {
      let corners = corners(of: hex).map { CGPoint($0) }
      path.move(to: corners[0])
      for corner in corners.dropFirst() {
        path.addLine(to: corner)
      }
      path.closeSubpath()
    }
  }
#endif
