/*
 * Create and draw two Grids (Rectungled and Hexagonal) and centred second grid to content center of first grid
*/

import UIKit
import Foundation
import QuartzCore
import XCPlayground
import ObjectiveHexagonKit

// MARK: - Create View

let view1 = UIView()
view1.frame = CGRectMake(0,0,400,500)
view1.backgroundColor = UIColor.lightGrayColor()
let centerPoint1 = CGPointMake(CGRectGetMidX(view1.bounds)+50, CGRectGetMidY(view1.bounds)+50)

let view2 = UIView()
view2.bounds = CGRectMake(0,0,300,300)
view2.center = CGPoint(x: 200, y: 200)
view2.backgroundColor = UIColor.grayColor()
let centerPoint2 = CGPointMake(CGRectGetMidX(view2.bounds), CGRectGetMidY(view2.bounds))

view1.addSubview(view2)

// MARK: - Show View

XCPShowView("mainView", view1)


// MARK: - First Grid

let rect = HKHexagonGridRectParameters(minQ: -1, maxQ: 2, minR: -1, maxR: 2)

var grid1: HKHexagonGrid!
if let map = HKHexagonGrid.generateRectangularMap(rect, convert: { (p) -> HKHexagonCoordinate3D in
//    return hexConvertOddRToCube(p)
//    return hexConvertOddQToCube(p)
    return hexConvertEvenRToCube(p)
//    return hexConvertEvenToCube(p)
//    return hexConvertAxialToCube(p)
}) {
    grid1 = HKHexagonGrid(points: map, hexSize: 20, orientation: .Pointy, map: .Rectangle)
}


// MARK: - Second Grid

var grid2: HKHexagonGrid!
if let map = HKHexagonGrid.generateHexagonalMap(3) {
    grid2 = HKHexagonGrid(points: map, hexSize: 20, orientation: .Pointy, map:.Hexagon)
}

let offset = CGPoint(x: grid1.center.x-grid2.center.x, y: grid1.center.y-grid2.center.y)
grid2.center = centerPoint2


// MARK: - Draw

let hexes2 = Array(grid2.hexes.values) as [HKHexagon]
for hex in hexes2 {
    view2.DebugDrawPoly(hex.unwrappedVertices(), name: "vertices2\(hex.hashID)", lineWidth: 1, strokeColor: UIColor.lightGrayColor())
}
//view2.DebugDrawPoint(grid2.contentCenter, name: "contentCenter2", lineWidth: 1, strokeColor: UIColor.blackColor(), diameter: 15)
view2.DebugDrawRect(grid2.frame, name: "frame2", lineWidth: 1, strokeColor: UIColor.blueColor())
view2.DebugDrawPoint(grid2.center, name: "cview2center", lineWidth: 1, strokeColor: UIColor.lightGrayColor(), diameter: 15)


grid1.center = CGPoint(x: grid2.contentCenter.x + offset.x, y: grid2.contentCenter.y + offset.y)
let hexes = Array(grid1!.hexes.values) as [HKHexagon]
for hex in hexes {
    view2.DebugDrawPoly(hex.unwrappedVertices(), name: "vertices\(hex.hashID)", lineWidth: 1, strokeColor: UIColor.greenColor())
}
//view2.DebugDrawPoint(grid1.contentCenter, name: "contentCenter1", lineWidth: 1, strokeColor: UIColor.blackColor(), diameter: 15)
view2.DebugDrawRect(grid1.frame, name: "frame", lineWidth: 1, strokeColor: UIColor.blueColor())
view2.DebugDrawPoint(grid1.center, name: "cview1center", lineWidth: 1, strokeColor: UIColor.greenColor(), diameter: 15)

