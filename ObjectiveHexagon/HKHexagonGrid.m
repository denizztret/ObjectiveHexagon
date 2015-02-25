//
//  HKHexagonGrid.m
//  ObjectiveHexagon
//
//  Created by Denis Tretyakov on 23.02.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

#import "HKHexagonGrid.h"
#import "HKHexagon.h"

NSString *HKHexagonGridMapStorageName(HKHexagonGridMapStorage map) {
    switch (map) {
        case HKHexagonGridMapStorageHexagon:    return @"Hexagon Map";
        case HKHexagonGridMapStorageTriangle:   return @"Triangle Map";
        case HKHexagonGridMapStorageRectangle:  return @"Rectangle Map";
        case HKHexagonGridMapStorageRhombus:    return @"Rhombus Map";
        case HKHexagonGridMapStorageUnknown:    return @"Unknown Map";
        default:return nil;
    }
}

@interface HKHexagonGrid ()
@property (nonatomic, strong) NSDictionary *hexes;
- (void)addPoints:(NSArray *)points;
@end

@implementation HKHexagonGrid

/// MARK: - Init Methods

- (instancetype)initWithPoints:(NSArray *)points {
    self = [super init];
    if (self) {
        
        self.mapStorage = HKHexagonGridMapStorageUnknown;
        self.hexOrientation = HKHexagonGridOrientationFlat;
        self.hexSize = 0.0;
        self.screenCenter = CGPointZero;
        
        [self addPoints:points];
    }
    return self;
}
- (instancetype)initWithPoints:(NSArray *)points orientation:(HKHexagonGridOrientation)orientation map:(HKHexagonGridMapStorage)map {
    self = [super init];
    if (self) {
        
        self.mapStorage = map;
        self.hexOrientation = orientation;
        self.hexSize = 0.0;
        self.screenCenter = CGPointZero;
        
        [self addPoints:points];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"HexagonGrid: {%lu hexes at %@}", self.hexes.count, HKHexagonGridMapStorageName(self.mapStorage)];
}

/// MARK: -  Properties

- (NSUInteger)mapSize {
    return self.hexes.count;
}

- (CGFloat)hexWidth {
    switch (self.hexOrientation) {
        case HKHexagonGridOrientationFlat: return self.hexSize * 2.0;
        case HKHexagonGridOrientationPointy: return self.hexHeight * SQRT_3_2;
    }
}

- (CGFloat)hexHeight {
    switch (self.hexOrientation) {
        case HKHexagonGridOrientationFlat: return self.hexWidth * SQRT_3_2;
        case HKHexagonGridOrientationPointy: return self.hexSize * 2.0;
    }
}

- (CGFloat)hexHorizontalDistance {
    switch (self.hexOrientation) {
        case HKHexagonGridOrientationFlat: return self.hexWidth * 3 / 4;
        case HKHexagonGridOrientationPointy: return self.hexWidth;
    }
}

- (CGFloat)hexVerticalDistance {
    switch (self.hexOrientation) {
        case HKHexagonGridOrientationFlat: return self.hexHeight;
        case HKHexagonGridOrientationPointy: return self.hexHeight * 3 / 4;
    }
}

- (CGRect)bounds {
    CGPoint offsetPoint = CGPointMake(-self.frame.origin.x, -self.frame.origin.y);
    offsetPoint = CGPointAdd(offsetPoint, self.screenCenter);
    return CGRectOffset(self.frame, offsetPoint.x, offsetPoint.y);
}

- (CGRect)frame {
    return [self frameOfShapes:self.hexes.allValues];
}

- (CGSize)contentSize {
    return self.bounds.size;
}

/// MARK: - Public Methods

- (HKHexagon *)shapeByHash:(NSString *)hash {
    return self.hexes[hash];
}

- (HKHexagon *)shapeAtScreenPoint:(CGPoint)point offset:(CGPoint)offset {
    HKHexagonCoordinate3D p = [self pointAtScreenPoint:CGPointSubtract(point, offset)];
    return [self shapeByHash:NSStringFromHexCoordinate3D(p)];
}

- (HKHexagon *)shapeAtScreenPoint:(CGPoint)point {
    CGPoint offsetPoint = CGPointZero;//CGPointMake(-self.frame.origin.x, -self.frame.origin.y);
    return [self shapeAtScreenPoint:point offset:offsetPoint];
}

- (HKHexagonCoordinate3D)pointAtScreenPoint:(CGPoint)point {
    if (self.hexSize == 0.0) { return hex3DMake(0, 0, 0); }
    CGPoint sc = CGPointMultiply(point, 1.0/self.hexSize);
    CGFloat q = 0.0;
    CGFloat r = 0.0;
    if (self.hexOrientation == HKHexagonGridOrientationPointy) {
        q = SQRT_3_3 * sc.x + -1/3 * sc.y;
        r = 2/3 * sc.y;
    } else {
        q = 2/3 * sc.x;
        r = -1/3 * sc.x + SQRT_3_3 * sc.y;
    }
    HKHexagonCoordinate3D p = hex3DMake(q, -q-r, r);
    return hex3DRound(p);
}

- (NSArray *)pointsAtRing:(NSUInteger)ring withCenter:(HKHexagonCoordinate3D)center {
    HKHexagonCoordinate3D d = hex3DDirection(4);
    HKHexagonCoordinate3D m = hex3DMultiply(d, ring);
    HKHexagonCoordinate3D a = hex3DAdd(m, center);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSUInteger i=0; i<6; i++) {
        for (NSUInteger j=0; j<ring; j++) {
            [result addObject:[NSValue valueWithHKHexagonCoordinate3D:a]];
            a = hex3DNeighbor(a, i);
        }
    }
    
    if (ring == 0) { [result addObject:[NSValue valueWithHKHexagonCoordinate3D:a]]; }
    
    return result;
}

- (NSArray *)pointsAtRing:(NSUInteger)ring {
    return [self pointsAtRing:ring withCenter:hex3DZero];
}

- (NSArray *)shapesAtRing:(NSUInteger)ring withCenter:(HKHexagonCoordinate3D)center {
    NSMutableArray *result = [NSMutableArray array];
    NSArray *points = [self pointsAtRing:ring withCenter:center];
    for (NSValue *value in points) {
        HKHexagonCoordinate3D p = [value HKHexagonCoordinate3DValue];
        HKHexagon *hex = [self shapeByHash:NSStringFromHexCoordinate3D(p)];
        if (hex) { [result addObject:hex]; }
    }
    return result;
}

- (NSArray *)shapesAtRing:(NSUInteger)ring {
    return [self shapesAtRing:ring withCenter:hex3DZero];
}

/// MARK: - Private Methods

- (void)addPoints:(NSArray *)points {
    NSMutableDictionary *hexes = [NSMutableDictionary dictionaryWithCapacity:points.count];
    for (NSValue *value in points) {
        HKHexagonCoordinate3D p = [value HKHexagonCoordinate3DValue];
        HKHexagon *hex = [HKHexagon hexagonWithCoordinate:p grid:self];
        hexes[hex.hash] = hex;
    }
    self.hexes = [NSDictionary dictionaryWithDictionary:hexes];
}

- (CGRect)frameOfShapes:(NSArray *)shapes {
    
    CGFloat minX = MAXFLOAT;
    CGFloat minY = MAXFLOAT;
    CGFloat maxX = -MAXFLOAT;
    CGFloat maxY = -MAXFLOAT;
    
    for (HKHexagon *hex in shapes) {
        if (hex.center.x < minX) { minX = hex.center.x; }
        if (hex.center.y < minY) { minY = hex.center.y; }
        if (hex.center.x > maxX) { maxX = hex.center.x; }
        if (hex.center.y > maxY) { maxY = hex.center.y; }
    }
    
    minX -= self.hexWidth / 2.0;
    minY -= self.hexHeight / 2.0;
    maxX += self.hexWidth / 2.0;
    maxY += self.hexHeight / 2.0;
    
    return CGRectMake(minX, minY, fabs(maxX-minX), fabs(maxY-minY));
}

/// MARK: - Generate Map

+ (NSArray *)generateHexagonalMap:(NSInteger)size {
    NSMutableArray *hexes = [NSMutableArray array];
    for (NSInteger x=-size; x<=size; x++) {
        for (NSInteger y=-size; y<=size; y++) {
            NSInteger z = -x-y;
            if (ABS(x) <= size && ABS(y) <= size && ABS(z) <= size) {
                HKHexagonCoordinate3D point = hex3DMake(x, y, z);
                NSValue *value = [NSValue valueWithHKHexagonCoordinate3D:point];
                [hexes addObject:value];
            }
        }
    }
    return hexes;
}
+ (NSArray *)generateTriangularMap:(NSInteger)size {
    NSMutableArray *hexes = [NSMutableArray array];
    for (NSInteger k=0; k<=size; k++) {
        for (NSInteger i=0; i<=k; i++) {
            HKHexagonCoordinate3D point = hex3DMake(i, -k, k-i);
            NSValue *value = [NSValue valueWithHKHexagonCoordinate3D:point];
            [hexes addObject:value];
        }
    }
    return hexes;
}
+ (NSArray *)generateRectangularMap:(HKHexagonGridRectParameters)rect
                            convert:(HKHexagonCoordinate3D (^) (HKHexagonCoordinate2D p))handler {
    NSMutableArray *hexes = [NSMutableArray array];
    for (NSInteger q=rect.minQ; q<=rect.maxQ; q++) {
        for (NSInteger r=rect.minR; r<=rect.maxR; r++) {
            HKHexagonCoordinate2D p = hex2DMake(q, r);
            HKHexagonCoordinate3D point = handler(p);
            NSValue *value = [NSValue valueWithHKHexagonCoordinate3D:point];
            [hexes addObject:value];
        }
    }
    return hexes;
}

@end
