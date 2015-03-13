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

@property (nonatomic, assign) CGFloat hexWidth;
@property (nonatomic, assign) CGFloat hexHeight;
@property (nonatomic, assign) CGFloat hexHorizontalDistance;
@property (nonatomic, assign) CGFloat hexVerticalDistance;

@end


@implementation HKHexagonGrid {
    
    BOOL _needsLayout;
    CGFloat _inverseHexSize;
}

@synthesize hexSize=_hexSize, hexOrientation=_hexOrientation;

/// MARK: - Init Methods

+ (instancetype)gridWithPoints:(NSArray *)points {
    return [[HKHexagonGrid alloc] initWithPoints:points];
}
- (instancetype)initWithPoints:(NSArray *)points {
    self = [self initWithPoints:points
                        hexSize:0.0
                    orientation:HKHexagonGridOrientationPointy
                            map:HKHexagonGridMapStorageUnknown];
    return self;
}
- (instancetype)initWithPoints:(NSArray *)points
                       hexSize:(CGFloat)hexSize
                   orientation:(HKHexagonGridOrientation)orientation
                           map:(HKHexagonGridMapStorage)map {
    self = [super init];
    if (self) {
        
        _mapStorage = map;
        _hexSize = hexSize;
        _hexOrientation = orientation;
        
        [self addPoints:points];
        
        _needsLayout = YES;
        [self setNeedsLayout];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"HexagonGrid: {%lu hexes at %@}", (unsigned long)self.hexes.count, HKHexagonGridMapStorageName(self.mapStorage)];
}

/// MARK: -  Properties

- (void)setHexSize:(CGFloat)hexSize {
    if (self.hexSize != hexSize) {
        _hexSize = hexSize;
        _inverseHexSize = 1.0 / _hexSize;
        
        _needsLayout = YES;
        [self setNeedsLayout];
    }
}

- (void)setHexOrientation:(HKHexagonGridOrientation)hexOrientation {
    if (self.hexOrientation != hexOrientation) {
        _hexOrientation = hexOrientation;
        
        _needsLayout = YES;
        [self setNeedsLayout];
    }
}

- (NSUInteger)mapSize {
    return self.hexes.count;
}

- (CGFloat)hexWidth {
    switch (_hexOrientation) {
        case HKHexagonGridOrientationFlat: return _hexSize * 2.0;
        case HKHexagonGridOrientationPointy: return _hexSize * SQRT_3;
    }
}

- (CGFloat)hexHeight {
    switch (self.hexOrientation) {
        case HKHexagonGridOrientationFlat: return _hexSize * SQRT_3;
        case HKHexagonGridOrientationPointy: return _hexSize * 2.0;
    }
}

- (CGFloat)hexHorizontalDistance {
    switch (self.hexOrientation) {
        case HKHexagonGridOrientationFlat: return _hexSize * DIV_3_2;
        case HKHexagonGridOrientationPointy: return _hexSize * SQRT_3;
    }
}

- (CGFloat)hexVerticalDistance {
    switch (self.hexOrientation) {
        case HKHexagonGridOrientationFlat: return _hexSize * SQRT_3;
        case HKHexagonGridOrientationPointy: return _hexSize * DIV_3_2;
    }
}

- (CGSize)contentSize {
    return _bounds.size;
}

- (CGRect)contentFrame {
    return CGRectOffset(_bounds, _contentCenter.x, _contentCenter.y);
}

/// MARK: - Other Methods

- (void)addPoints:(NSArray *)points {
    
    NSMutableDictionary *hexes = [NSMutableDictionary dictionaryWithCapacity:points.count];
    for (NSValue *value in points) {
        HKHexagonCoordinate3D p = [value HKHexagonCoordinate3DValue];
        HKHexagon *hex = [HKHexagon hexagonWithCoordinate:p grid:self];
        hexes[hex.hashID] = hex;
    }
    self.hexes = [NSDictionary dictionaryWithDictionary:hexes];
}

- (CGPoint)centerOfShape:(HKHexagon *)shape {
    
    HKHexagonCoordinate2D hex = hexConvertCubeToAxial(shape.coordinate);
    CGPoint s = CGPointZero;
    
    if (self.hexOrientation == HKHexagonGridOrientationPointy) {
        s = CGPointMake(SQRT_3 * hex.q + SQRT_3_2 * hex.r, DIV_3_2 * hex.r);
    } else {
        s = CGPointMake(DIV_3_2 * hex.q, SQRT_3_2 * hex.q + SQRT_3 * hex.r);
    }
    
    s = CGPointMultiply(s, self.hexSize);
    return s;
}

- (CGRect)boundsOfShapes:(NSArray *)shapes {

    CGFloat minX = MAXFLOAT;
    CGFloat minY = MAXFLOAT;
    CGFloat maxX = -MAXFLOAT;
    CGFloat maxY = -MAXFLOAT;
    
    for (HKHexagon *hex in shapes) {
        CGPoint center = hex.center;
        if (center.x < minX) { minX = center.x; }
        if (center.y < minY) { minY = center.y; }
        if (center.x > maxX) { maxX = center.x; }
        if (center.y > maxY) { maxY = center.y; }
    }
    
    CGFloat halfWidth = self.hexWidth / 2.0;
    CGFloat halfHeight = self.hexHeight / 2.0;
    
    minX -= halfWidth;
    minY -= halfHeight;
    maxX += halfWidth;
    maxY += halfHeight;
    
    return CGRectMake(minX, minY, fabsf(maxX-minX), fabsf(maxY-minY));
}

- (CGRect)boundsOfShapes:(NSArray *)shapes contentCenter:(CGPoint)center {
    CGRect rect = [self boundsOfShapes:shapes];
    CGPoint offset = CGPointSubtract(center, _contentCenter);
    return CGRectOffset(rect, offset.x, offset.y);
}


- (void)setNeedsLayout {
    
    if (_needsLayout) {
        
        [self.hexes enumerateKeysAndObjectsUsingBlock:^(NSString *hashID, HKHexagon *hex, BOOL *stop) {
            [hex setNeedsLayout];
        }];
        
        [self hexWidth];
        [self hexHeight];
        [self hexHorizontalDistance];
        [self hexVerticalDistance];
        
        _contentCenter = CGPointMake(-_bounds.origin.x, -_bounds.origin.y);
        _bounds = [self boundsOfShapes:self.hexes.allValues contentCenter:_contentCenter];
        
        _needsLayout = NO;
    }
}

@end

@implementation HKHexagonGrid (GetShapes)

/// MARK: - Public Methods

- (HKHexagon *)shapeByHashID:(NSString *)hashID {
    return self.hexes[hashID];
}

- (HKHexagon *)shapeAtScreenPoint:(CGPoint)point offset:(CGPoint)offset {
    HKHexagonCoordinate3D p = [self pointAtScreenPoint:CGPointSubtract(point, offset)];
    return [self shapeByHashID:NSStringFromHexCoordinate3D(p)];
}

- (HKHexagon *)shapeAtScreenPoint:(CGPoint)point {
    return [self shapeAtScreenPoint:point offset:CGPointZero];
}

- (HKHexagonCoordinate3D)pointAtScreenPoint:(CGPoint)point {
    if (self.hexSize == 0.0) { return hex3DMake(0, 0, 0); }
    CGPoint sc = CGPointMultiply(point, _inverseHexSize);
    CGFloat q = 0.0;
    CGFloat r = 0.0;
    if (self.hexOrientation == HKHexagonGridOrientationPointy) {
        q = sc.x * SQRT_3_3 - sc.y * DIV_1_3;
        r = sc.y * DIV_2_3;
    } else {
        q = sc.x * DIV_2_3;
        r = sc.y * SQRT_3_3 - sc.x * DIV_1_3;
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
        HKHexagon *hex = [self shapeByHashID:NSStringFromHexCoordinate3D(p)];
        if (hex) { [result addObject:hex]; }
    }
    return result;
}

- (NSArray *)shapesAtRing:(NSUInteger)ring {
    return [self shapesAtRing:ring withCenter:hex3DZero];
}

@end

@implementation HKHexagonGrid (MapStorage)

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