/*
 * Create and draw Grid with Hexagonal Map
 * Select and draw bounds of shapes at rings
 * Select and draw center point of custom shape
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
let centerPoint1 = CGPointMake(CGRectGetMidX(view1.bounds), CGRectGetMidY(view1.bounds))

let view2 = UIView()
view2.bounds = CGRectMake(0,0,350,300)
view2.center = centerPoint1
view2.backgroundColor = UIColor.grayColor()
let centerPoint2 = CGPointMake(CGRectGetMidX(view2.bounds), CGRectGetMidY(view2.bounds))

view1.addSubview(view2)

XCPShowView("mainView", view1)


// MARK: - Create Grid

var grid: HKHexagonGrid!
if let map = HKHexagonGrid.generateHexagonalMap(3) {
    grid = HKHexagonGrid(points: map, hexSize: 25, orientation: .Pointy, map:.Hexagon)
}

grid.center = centerPoint2


// MARK: - 1. Draw Grid

let hexes = Array(grid.hexes.values) as [HKHexagon]
for hex in hexes {
    view2.DebugDrawPoly(hex.unwrappedVertices(), name: "vertices2\(hex.hashID)", lineWidth: 1, strokeColor: UIColor.greenColor())

//    // Draw Hexes Centers
//    view2.DebugDrawPoint(hex.center, name: "center\(hex.hashID)", lineWidth: 1, strokeColor: UIColor.blueColor())

//    // Draw Hexes Frames
//    view2.DebugDrawRect(hex.frame, name: "bounds\(hex.hashID)", lineWidth: 1, strokeColor: UIColor.blackColor())
}


// MARK: 2. Draw Bounds of shapes at rings

let hexes1 = grid.shapesAtRing(1) as [HKHexagon]
var rect1 = grid.boundsOfShapes(hexes1, centerPoint: centerPoint2)
view2.DebugDrawRect(rect1, name: "FrameRound1", lineWidth: 1, strokeColor: UIColor.blackColor())

let p = hex3DMake(1, -2, 1)
let hexes2 = grid.shapesAtRing(1, withCenter: p) as [HKHexagon]
let rect2 = grid.boundsOfShapes(hexes2, centerPoint: centerPoint2)
view2.DebugDrawRect(rect2, name: "FrameRound2", lineWidth: 1, strokeColor: UIColor.blackColor())


// MARK: 3. Draw center of custom shape

let hash = "{-3, 2, 1}"
let hex2 = grid.shapeByHashID(hash)
view2.DebugDrawPoint(hex2.center, name: "center\(hex2.hashID)", lineWidth: 1, strokeColor: UIColor.blueColor())

