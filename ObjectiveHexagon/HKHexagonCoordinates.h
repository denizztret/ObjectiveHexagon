//
//  HKHexagonCoordinates.h
//  ObjectiveHexagon
//
//  Created by Denis Tretyakov on 24.02.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#define SQRT_3      1.732050807568877   //(sqrtf(3.0))
#define SQRT_3_2    0.86602540378444    //(sqrtf(3.0)/2.0)
#define SQRT_3_3    0.57735026918963    //(sqrtf(3.0)/3.0)
#define DIV_1_3     0.33333333333333    //(1.0/3.0)
#define DIV_2_3     0.66666666666667    //(2.0/3.0)
#define DIV_3_2     1.5                 //(3.0/2.0)

typedef struct {
    CGFloat q;
    CGFloat r;
} HKHexagonCoordinate2D;

typedef struct {
    CGFloat x;
    CGFloat y;
    CGFloat z;
} HKHexagonCoordinate3D;

#pragma mark - Hexagon Coordinate 2D

CG_INLINE HKHexagonCoordinate2D hex2DMake(CGFloat q, CGFloat r) {
    return (HKHexagonCoordinate2D) { q, r };
}

CG_EXTERN const HKHexagonCoordinate2D hex2DZero;

CG_EXTERN HKHexagonCoordinate2D hexConvertCubeToAxial(HKHexagonCoordinate3D point);
CG_EXTERN HKHexagonCoordinate2D hexConvertCubeToEvenQ(HKHexagonCoordinate3D point);
CG_EXTERN HKHexagonCoordinate2D hexConvertCubeToEvenR(HKHexagonCoordinate3D point);
CG_EXTERN HKHexagonCoordinate2D hexConvertCubeToOddQ(HKHexagonCoordinate3D point);
CG_EXTERN HKHexagonCoordinate2D hexConvertCubeToOddR(HKHexagonCoordinate3D point);

CG_EXTERN NSString *NSStringFromHexCoordinate2D(HKHexagonCoordinate2D point);


#pragma mark - Hexagon Coordinate 3D

CG_INLINE HKHexagonCoordinate3D hex3DMake(CGFloat x, CGFloat y, CGFloat z) {
    return (HKHexagonCoordinate3D) { x, y, z };
}

CG_EXTERN HKHexagonCoordinate3D hex3DAdd(HKHexagonCoordinate3D point1, HKHexagonCoordinate3D point2);
CG_EXTERN HKHexagonCoordinate3D hex3DSubtract(HKHexagonCoordinate3D point1, HKHexagonCoordinate3D point2);
CG_EXTERN HKHexagonCoordinate3D hex3DMultiply(HKHexagonCoordinate3D point, CGFloat k);
CG_EXTERN HKHexagonCoordinate3D hex3DScale(HKHexagonCoordinate3D point, CGFloat f);

CG_EXTERN HKHexagonCoordinate3D hex3DRotateLeft(HKHexagonCoordinate3D point);
CG_EXTERN HKHexagonCoordinate3D hex3DRotateRight(HKHexagonCoordinate3D point);

CG_EXTERN HKHexagonCoordinate3D hex3DRound(HKHexagonCoordinate3D point);

CG_EXTERN CGFloat hex3DLength(HKHexagonCoordinate3D point);
CG_EXTERN CGFloat hex3DDistance(HKHexagonCoordinate3D point1, HKHexagonCoordinate3D point2);

CG_EXTERN BOOL hex3DEquals(HKHexagonCoordinate3D lhs, HKHexagonCoordinate3D rhs);

CG_EXTERN const HKHexagonCoordinate3D hex3DZero;
CG_EXTERN const HKHexagonCoordinate3D hex3DDirections[6];

CG_EXTERN HKHexagonCoordinate3D hex3DDirection(NSUInteger direction);
CG_EXTERN HKHexagonCoordinate3D hex3DNeighbor(HKHexagonCoordinate3D p, NSUInteger direction);

CG_EXTERN HKHexagonCoordinate3D hexConvertAxialToCube(HKHexagonCoordinate2D point);
CG_EXTERN HKHexagonCoordinate3D hexConvertEvenQToCube(HKHexagonCoordinate2D point);
CG_EXTERN HKHexagonCoordinate3D hexConvertEvenRToCube(HKHexagonCoordinate2D point);
CG_EXTERN HKHexagonCoordinate3D hexConvertOddQToCube(HKHexagonCoordinate2D point);
CG_EXTERN HKHexagonCoordinate3D hexConvertOddRToCube(HKHexagonCoordinate2D point);

CG_EXTERN NSString *NSStringFromHexCoordinate3D(HKHexagonCoordinate3D point);


#pragma mark - CGPoint Extensions

CG_INLINE CGPoint CGPointAdd(const CGPoint v1, const CGPoint v2) {
    return CGPointMake(v1.x + v2.x, v1.y + v2.y);
}
CG_INLINE CGPoint CGPointSubtract(const CGPoint v1, const CGPoint v2) {
    return CGPointMake(v1.x - v2.x, v1.y - v2.y);
}
CG_INLINE CGPoint CGPointMultiply(const CGPoint v, const CGFloat s) {
    return CGPointMake(v.x*s, v.y*s);
}


#pragma mark - NSValue Category

@interface NSValue (HKHexagonCoordinate)

+ (instancetype) valueWithHKHexagonCoordinate2D:(HKHexagonCoordinate2D)point;
+ (instancetype) valueWithHKHexagonCoordinate3D:(HKHexagonCoordinate3D)point;

- (HKHexagonCoordinate2D) HKHexagonCoordinate2DValue;
- (HKHexagonCoordinate3D) HKHexagonCoordinate3DValue;

@end

@interface NSValue (CGPoint)

+ (NSValue *)valueWithCGPoint:(CGPoint)point;

- (CGPoint)CGPointValue;

@end
