/*
 * Create and draw Grid with Rectungled Map of Hexagones
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
view2.bounds = CGRectMake(0,0,250,300)
view2.center = centerPoint1
view2.backgroundColor = UIColor.grayColor()
let centerPoint2 = CGPointMake(CGRectGetMidX(view2.bounds), CGRectGetMidY(view2.bounds))

view1.addSubview(view2)

XCPShowView("mainView", view1)


// MARK: - Create Grid

let rect = HKHexagonGridRectParameters(minQ: -2, maxQ: 2, minR: 0, maxR: 3)

var grid: HKHexagonGrid!
if let map = HKHexagonGrid.generateRectangularMap(rect, convert: { (p) -> HKHexagonCoordinate3D in
//    return hexConvertOddRToCube(p)
//    return hexConvertOddQToCube(p)
//    return hexConvertEvenRToCube(p)
    return hexConvertEvenQToCube(p)
//    return hexConvertAxialToCube(p)
}) {
    grid = HKHexagonGrid(points: map, hexSize: 25, orientation: .Flat, map: .Rectangle)
}


let hexWidth = grid.hexWidth
let hexHeight = grid.hexHeight
let hexHorizontalDistance = grid.hexHorizontalDistance
let hexVerticalDistance = grid.hexVerticalDistance

let contentBounds = grid.contentBounds
let contentSize = grid.contentSize
let contentCenter = grid.contentCenter

var frame = grid.frame
var center = grid.center
var position = grid.position


// MARK: - Debug Draw

view2.DebugDrawRect(contentBounds, name: "contentBounds", lineWidth: 1, strokeColor: UIColor.blackColor())
view2.DebugDrawPoint(contentCenter, name: "contentCenter", lineWidth: 1, strokeColor: UIColor.blackColor(), diameter: 15)


// MARK: Set Grid Position/Center
grid.center = centerPoint2
//grid.center = CGPoint(x: 80, y: 90)
//grid.position = CGPointZero


frame = grid.frame
center = grid.center
position = grid.position


let hexes = Array(grid.hexes.values) as [HKHexagon]
for hex in hexes {
    view2.DebugDrawPoly(hex.unwrappedVertices(), name: "vertices\(hex.hashID)", lineWidth: 1, strokeColor: UIColor.greenColor())
}


let lt = CGPoint(x: CGRectGetMinX(frame), y: CGRectGetMinY(frame))
let rt = CGPoint(x: CGRectGetMaxX(frame), y: CGRectGetMinY(frame))
let lb = CGPoint(x: CGRectGetMinX(frame), y: CGRectGetMaxY(frame))
let rb = CGPoint(x: CGRectGetMaxX(frame), y: CGRectGetMaxY(frame))
view2.DebugDrawPoly([lt, rb], name: "diag1", lineWidth: 1, strokeColor: UIColor.blueColor())
view2.DebugDrawPoly([rt, lb], name: "diag2", lineWidth: 1, strokeColor: UIColor.blueColor())
view2.DebugDrawRect(frame, name: "frame", lineWidth: 1, strokeColor: UIColor.blueColor())
view2.DebugDrawPoint(grid.center, name: "center", lineWidth: 1, strokeColor: UIColor.blueColor(), diameter: 15)

