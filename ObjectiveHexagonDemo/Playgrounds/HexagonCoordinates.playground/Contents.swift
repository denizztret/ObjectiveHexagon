// Playground - noun: a place where people can play

import UIKit
import Foundation
import ObjectiveHexagonKit

// MARK: - Hexagon Coordinate 2D

let h1 = HKHexagonCoordinate2D(q: -1, r: 0)
let h2 = hex2DMake(0, 2)

NSStringFromHexCoordinate2D(h2)

// MARK: - Hexagon Coordinate 3D

let c1 = HKHexagonCoordinate3D(x: -1, y: 1, z: 0)
let c2 = hex3DMake(0, -2, 2)

var c3: HKHexagonCoordinate3D!
c3 = hex3DAdd(c1, c2)
c3 = hex3DSubtract(c1, c2)
c3 = hex3DMultiply(c2, 2.0)
c3 = hex3DScale(c2, 2.0)

c3 = hex3DRotateLeft(c2)
c3 = hex3DRotateRight(c2)

c3 = hex3DRound(c1)
c3 = hex3DRound(c2)

hex3DEquals(c1, c2)
hex3DEquals(c3, c3)

let len = hex3DLength(c2)
let dis = hex3DDistance(c1, c2)

NSStringFromHexCoordinate3D(c2)

// MARK: - Convert Hexagons

c3 = hexConvertAxialToCube(h2)
c3 = hexConvertEvenQToCube(h2)
c3 = hexConvertEvenRToCube(h2)
c3 = hexConvertOddQToCube(h2)
c3 = hexConvertOddRToCube(h2)

var h3: HKHexagonCoordinate2D!

h3 = hexConvertCubeToAxial(c2)
h3 = hexConvertCubeToEvenQ(c2)
h3 = hexConvertCubeToEvenR(c2)
h3 = hexConvertCubeToOddQ(c2)
h3 = hexConvertCubeToOddR(c2)

// MARK: - NSValue Category

let vc = NSValue(hkHexagonCoordinate3D: c3)
vc?.hkHexagonCoordinate3DValue()

let vh = NSValue(hkHexagonCoordinate2D: h3)
vh?.hkHexagonCoordinate2DValue()

// MARK: - Hexagon Obj

let p1 = hex3DMake(-1, 1, 0)
let hex1 = HKHexagon(coordinate: p1, grid: nil)
hex1?.hash
hex1?.valid
