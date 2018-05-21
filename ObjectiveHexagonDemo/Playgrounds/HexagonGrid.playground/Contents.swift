/*
 * Create and draw Grid with Rectungled Map of Hexagones
*/

import UIKit
import Foundation
import QuartzCore
import PlaygroundSupport
import ObjectiveHexagonKit

// MARK: - Create View

let view1 = UIView()
view1.frame = CGRect(x: 0, y: 0, width: 400, height: 500)
view1.backgroundColor = UIColor.lightGray
let centerPoint1 = CGPoint(x: view1.bounds.midX+50, y: view1.bounds.midY+50)

let view2 = UIView()
view2.bounds = CGRect(x: 0, y: 0, width: 250, height: 300)
view2.center = centerPoint1
view2.backgroundColor = UIColor.gray
let centerPoint2 = CGPoint(x: view2.bounds.midX, y: view2.bounds.midY)

view1.addSubview(view2)

PlaygroundPage.current.liveView = view1


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
	grid = HKHexagonGrid(points: map, hexSize: 25, orientation: .flat, map: .rectangle)
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

view2.DebugDrawRect(contentBounds, name: "contentBounds", lineWidth: 1, strokeColor: UIColor.black)
view2.DebugDrawPoint(contentCenter, name: "contentCenter", lineWidth: 1, strokeColor: UIColor.black, diameter: 15)


// MARK: Set Grid Position/Center
grid.center = centerPoint2
//grid.center = CGPoint(x: 80, y: 90)
//grid.position = CGPointZero


frame = grid.frame
center = grid.center
position = grid.position


let hexes = Array(grid.hexes.values) as! [HKHexagon]
for hex in hexes {
	view2.DebugDrawPoly(hex.unwrappedVertices(), name: "vertices\(hex.hashID)", lineWidth: 1, strokeColor: UIColor.green)
}


let lt = CGPoint(x: frame.minX, y: frame.minY)
let rt = CGPoint(x: frame.maxX, y: frame.minY)
let lb = CGPoint(x: frame.minX, y: frame.maxX)
let rb = CGPoint(x: frame.maxX, y: frame.maxY)
view2.DebugDrawPoly([lt, rb], name: "diag1", lineWidth: 1, strokeColor: UIColor.blue)
view2.DebugDrawPoly([rt, lb], name: "diag2", lineWidth: 1, strokeColor: UIColor.blue)
view2.DebugDrawRect(frame, name: "frame", lineWidth: 1, strokeColor: UIColor.blue)
view2.DebugDrawPoint(grid.center, name: "center", lineWidth: 1, strokeColor: UIColor.blue, diameter: 15)

