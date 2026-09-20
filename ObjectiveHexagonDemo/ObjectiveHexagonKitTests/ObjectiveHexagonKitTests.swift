//
//  ObjectiveHexagonKitTests.swift
//  ObjectiveHexagonKitTests
//
//  Created by Denis Tretyakov on 18.03.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

import XCTest
import ObjectiveHexagonKit

class ObjectiveHexagonKitTests: XCTestCase {

    /// The grid looks cells up by the string form of the coordinate,
    /// so a negative zero ("-0") would make the central cell unreachable.
    func testAxialToCubeOfOriginHasNoNegativeZero() {
        let cube = hexConvertAxialToCube(HKHexagonCoordinate2D(q: 0, r: 0))
        XCTAssertEqual(NSStringFromHexCoordinate3D(cube), "{0, 0, 0}")
    }

    func testCentralCellIsFoundThroughAxialConversion() {
        let points = HKHexagonGrid.generateHexagonalMap(1)
        let grid: HKHexagonGrid = HKHexagonGrid(points: points, hexSize: 10, orientation: .pointy, map: .hexagon)
        let center = hexConvertAxialToCube(HKHexagonCoordinate2D(q: 0, r: 0))
        XCTAssertNotNil(grid.shape(byHashID: NSStringFromHexCoordinate3D(center)))
    }

    /// 2.49999995 is below one half and must round down. In single precision
    /// the value becomes exactly 2.5 and lands in the neighbouring cell.
    func testRoundKeepsDoublePrecision() {
        let rounded = hex3DRound(HKHexagonCoordinate3D(x: 2.49999995, y: -2.49999995, z: 0))
        XCTAssertEqual(NSStringFromHexCoordinate3D(rounded), "{2, -2, 0}")
    }
}
