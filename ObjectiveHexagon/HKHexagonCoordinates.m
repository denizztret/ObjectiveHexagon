//
//  HKHexagonCoordinates.m
//  ObjectiveHexagon
//
//  Created by Denis Tretyakov on 24.02.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

#import "HKHexagonCoordinates.h"

#pragma mark - Hexagon Coordinate 2D

const HKHexagonCoordinate2D hex2DZero = (HKHexagonCoordinate2D) { 0.0f, 0.0f };

HKHexagonCoordinate2D hexConvertCubeToAxial(HKHexagonCoordinate3D point) {
    return hex2DMake(point.x, point.z);
}
HKHexagonCoordinate2D hexConvertCubeToEvenQ(HKHexagonCoordinate3D point) {
    int x = (int)point.x; int z = (int)point.z;
    return hex2DMake(x, z + ((x + (x & 1)) >> 1));
}
HKHexagonCoordinate2D hexConvertCubeToEvenR(HKHexagonCoordinate3D point) {
    int x = (int)point.x; int z = (int)point.z;
    return hex2DMake(x + ((z + (z & 1)) >> 1), z);
}
HKHexagonCoordinate2D hexConvertCubeToOddQ(HKHexagonCoordinate3D point) {
    int x = (int)point.x; int z = (int)point.z;
    return hex2DMake(x, z + ((x - (x & 1)) >> 1));
}
HKHexagonCoordinate2D hexConvertCubeToOddR(HKHexagonCoordinate3D point) {
    int x = (int)point.x; int z = (int)point.z;
    return hex2DMake(x + ((z - (z & 1)) >> 1), z);
}

NSString *NSStringFromHexCoordinate2D(HKHexagonCoordinate2D point) {
    return [NSString stringWithFormat:@"{%.0f, %.0f}", point.q, point.r];
}

#pragma mark - Hexagon Coordinate 3D

HKHexagonCoordinate3D hex3DAdd(HKHexagonCoordinate3D point1, HKHexagonCoordinate3D point2) {
    return hex3DMake(point1.x + point2.x, point1.y + point2.y, point1.z + point2.z);
}
HKHexagonCoordinate3D hex3DSubtract(HKHexagonCoordinate3D point1, HKHexagonCoordinate3D point2) {
    return hex3DMake(point1.x - point2.x, point1.y - point2.y, point1.z - point2.z);
}
HKHexagonCoordinate3D hex3DMultiply(HKHexagonCoordinate3D point, CGFloat k) {
    return hex3DMake(point.x * k, point.y * k, point.z * k);
}
HKHexagonCoordinate3D hex3DScale(HKHexagonCoordinate3D point, CGFloat f) {
    return hex3DMake(point.x * f, point.y * f, point.z * f);
}

HKHexagonCoordinate3D hex3DRotateLeft(HKHexagonCoordinate3D point) {
    return hex3DMake(-point.y, -point.z, -point.x);
}
HKHexagonCoordinate3D hex3DRotateRight(HKHexagonCoordinate3D point) {
    return hex3DMake(-point.z, -point.x, -point.y);
}

HKHexagonCoordinate3D hex3DRound(HKHexagonCoordinate3D point) {
    CGFloat rx = roundf(point.x);
    CGFloat ry = roundf(point.y);
    CGFloat rz = roundf(point.z);
    
    CGFloat x_diff = fabs(rx - point.x);
    CGFloat y_diff = fabs(ry - point.y);
    CGFloat z_diff = fabs(rz - point.z);
    
    if      (x_diff > y_diff && x_diff > z_diff)    { rx = -ry-rz; }
    else if (y_diff > z_diff)                       { ry = -rx-rz; }
    else                                            { rz = -rx-ry; }
    
    rx = fabs(rx) == 0 ? 0 : rx;
    ry = fabs(ry) == 0 ? 0 : ry;
    rz = fabs(rz) == 0 ? 0 : rz;
    
    return hex3DMake(rx, ry, rz);
}

CGFloat hex3DLength(HKHexagonCoordinate3D point) {
    
    CGFloat v[3] = { point.x, point.y, point.z };
    CGFloat len = 0.0f;
    
    for (NSUInteger i=0; i<3; i++) {
        CGFloat el = fabsf(v[i]);
        if (el > len) { len = el; }
    }
    
    return len;
}
CGFloat hex3DDistance(HKHexagonCoordinate3D point1, HKHexagonCoordinate3D point2) {
    return (fabsf(point1.x - point2.x) + fabsf(point1.y - point2.y) + fabsf(point1.z - point2.z)) / 2.0;
}

BOOL hex3DEquals(HKHexagonCoordinate3D lhs, HKHexagonCoordinate3D rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
}

const HKHexagonCoordinate3D hex3DZero = (HKHexagonCoordinate3D) { 0.0f, 0.0f, 0.0f };
const HKHexagonCoordinate3D hex3DDirections[] = {
    (HKHexagonCoordinate3D) {1, -1, 0},
    (HKHexagonCoordinate3D) {1, 0, -1},
    (HKHexagonCoordinate3D) {0, 1, -1},
    (HKHexagonCoordinate3D) {-1, 1, 0},
    (HKHexagonCoordinate3D) {-1, 0, 1},
    (HKHexagonCoordinate3D) {0, -1, 1}
};

HKHexagonCoordinate3D hex3DDirection(NSUInteger direction) {
    return hex3DDirections[direction];
}
HKHexagonCoordinate3D hex3DNeighbor(HKHexagonCoordinate3D p, NSUInteger direction) {
    return hex3DAdd(p, hex3DDirection(direction));
}

HKHexagonCoordinate3D hexConvertAxialToCube(HKHexagonCoordinate2D point) {
    return hex3DMake(point.q, -point.r-point.q, point.r);
}
HKHexagonCoordinate3D hexConvertEvenQToCube(HKHexagonCoordinate2D point) {
    int q = (int)point.q; int r = (int)point.r;
    int x = q; int z = r - ((q + (q & 1)) >> 1);
    return hex3DMake(x, -x-z, z);
}
HKHexagonCoordinate3D hexConvertEvenRToCube(HKHexagonCoordinate2D point) {
    int q = (int)point.q; int r = (int)point.r;
    int z = r; int x = q - ((r + (r & 1)) >> 1);
    return hex3DMake(x, -x-z, z);
}
HKHexagonCoordinate3D hexConvertOddQToCube(HKHexagonCoordinate2D point) {
    int q = (int)point.q; int r = (int)point.r;
    int x = q; int z = r - ((q - (q & 1)) >> 1);
    return hex3DMake(x, -x-z, z);
}
HKHexagonCoordinate3D hexConvertOddRToCube(HKHexagonCoordinate2D point) {
    int q = (int)point.q; int r = (int)point.r;
    int z = r; int x = q - ((r - (r & 1)) >> 1);
    return hex3DMake(x, -x-z, z);
}

NSString *NSStringFromHexCoordinate3D(HKHexagonCoordinate3D point) {
    return [NSString stringWithFormat:@"{%.0f, %.0f, %.0f}", point.x, point.y, point.z];
}

// TODO: create func makeLine

#pragma mark - NSValue Category

@implementation NSValue (HKHexagonCoordinate)

+ (instancetype) valueWithHKHexagonCoordinate2D:(HKHexagonCoordinate2D)point {
    return [NSValue value:&point withObjCType:@encode(HKHexagonCoordinate2D)];
}
+ (instancetype) valueWithHKHexagonCoordinate3D:(HKHexagonCoordinate3D)point {
    return [NSValue value:&point withObjCType:@encode(HKHexagonCoordinate3D)];
}

- (HKHexagonCoordinate2D) HKHexagonCoordinate2DValue {
    HKHexagonCoordinate2D point = hex2DZero;
    [self getValue:&point];
    return point;
}
- (HKHexagonCoordinate3D) HKHexagonCoordinate3DValue {
    HKHexagonCoordinate3D point = hex3DZero;
    [self getValue:&point];
    return point;
}

@end

@implementation NSValue (CCValue)

+ (NSValue *)valueWithCGPoint:(CGPoint)point {
    return [NSValue value:&point withObjCType:@encode(CGPoint)];
}

- (CGPoint)CGPointValue {
    CGPoint pt = CGPointZero;
    [self getValue:&pt];
    return pt;
}

@end
