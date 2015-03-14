//
//  HKHexagonGrid.h
//  ObjectiveHexagon
//
//  Created by Denis Tretyakov on 23.02.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "HKHexagonCoordinates.h"

@class HKHexagon;

typedef NS_ENUM(NSUInteger, HKHexagonGridOrientation) {
    HKHexagonGridOrientationFlat = 0,
    HKHexagonGridOrientationPointy
};

typedef NS_ENUM(NSUInteger, HKHexagonGridMapStorage) {
    HKHexagonGridMapStorageHexagon = 0,
    HKHexagonGridMapStorageTriangle,
    HKHexagonGridMapStorageRectangle,
    HKHexagonGridMapStorageRhombus,
    HKHexagonGridMapStorageUnknown
};

typedef struct {
    NSInteger minQ;
    NSInteger maxQ;
    NSInteger minR;
    NSInteger maxR;
} HKHexagonGridRectParameters;

@interface HKHexagonGrid : NSObject

@property (nonatomic, assign) HKHexagonGridOrientation hexOrientation;
@property (nonatomic, assign) HKHexagonGridMapStorage mapStorage;
@property (nonatomic, readonly) NSUInteger mapSize;
@property (nonatomic, readonly) NSDictionary *hexes;

@property (nonatomic, assign) CGFloat hexSize;
@property (nonatomic, readonly) CGFloat hexWidth;
@property (nonatomic, readonly) CGFloat hexHeight;
@property (nonatomic, readonly) CGFloat hexHorizontalDistance;
@property (nonatomic, readonly) CGFloat hexVerticalDistance;

@property (nonatomic, readonly) CGRect contentBounds;
@property (nonatomic, readonly) CGSize contentSize;
@property (nonatomic, readonly) CGPoint contentCenter;

@property (nonatomic, readonly) CGRect frame;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) CGPoint position;

+ (instancetype)gridWithPoints:(NSArray *)points;
- (instancetype)initWithPoints:(NSArray *)points;
- (instancetype)initWithPoints:(NSArray *)points
                       hexSize:(CGFloat)hexSize
                   orientation:(HKHexagonGridOrientation)orientation
                           map:(HKHexagonGridMapStorage)map;


- (CGRect)boundsOfShapes:(NSArray *)shapes;

- (void)setNeedsLayout;

@end

@interface HKHexagonGrid (GetShapes)

- (HKHexagon *)shapeByHashID:(NSString *)hashID;

- (HKHexagon *)shapeAtScreenPoint:(CGPoint)point offset:(CGPoint)offset;
- (HKHexagon *)shapeAtScreenPoint:(CGPoint)point;

- (HKHexagonCoordinate3D)pointAtScreenPoint:(CGPoint)point;

- (NSArray *)pointsAtRing:(NSUInteger)ring withCenter:(HKHexagonCoordinate3D)center;
- (NSArray *)pointsAtRing:(NSUInteger)ring;
- (NSArray *)shapesAtRing:(NSUInteger)ring withCenter:(HKHexagonCoordinate3D)center;
- (NSArray *)shapesAtRing:(NSUInteger)ring;

@end

@interface HKHexagonGrid (MapStorage)

+ (NSArray *)generateHexagonalMap:(NSInteger)size;
+ (NSArray *)generateTriangularMap:(NSInteger)size;
+ (NSArray *)generateRectangularMap:(HKHexagonGridRectParameters)rect
                            convert:(HKHexagonCoordinate3D (^) (HKHexagonCoordinate2D p))handler;

@end
/*
 ALIASES:
 shape = hexagon
 point = coordinate
 */
