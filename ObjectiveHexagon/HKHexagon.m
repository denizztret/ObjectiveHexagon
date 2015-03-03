//
//  HKHexagon.m
//  ObjectiveHexagon
//
//  Created by Denis Tretyakov on 23.02.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

#import "HKHexagon.h"
#import "HKHexagonGrid.h"

@interface HKHexagon ()

- (CGPoint)localCenter;
- (CGPoint *)localVertices;

@end


@implementation HKHexagon {
    
    CGPoint _localCenter;
    CGPoint *_localVertices;
    
    BOOL _needsLayoutBounds;
    BOOL _needsLayoutCenter;
    BOOL _needsLayoutVertices;
}

@synthesize bounds=_bounds;

/// MARK: - Init

+ (instancetype) hexagonWithCoordinate:(HKHexagonCoordinate3D)coordinate grid:(HKHexagonGrid *)grid {
    return [[HKHexagon alloc] initWithCoordinate:coordinate grid:grid];
}
- (instancetype) initWithCoordinate:(HKHexagonCoordinate3D)coordinate grid:(HKHexagonGrid *)grid {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _grid = grid;
        
        _localVertices = calloc(6, sizeof(*_localVertices));
        
        [self setNeedsLayout];
    }
    return self;
}

- (NSString *)description  {
    return [NSString stringWithFormat:@"Hexagon: %@", self.hashID];
}

- (void)dealloc {
    free(_localVertices);
}

/// MARK: -  Properties

- (NSString *) hashID {
    return NSStringFromHexCoordinate3D(self.coordinate);
}

- (BOOL)valid {
    return self.coordinate.x + self.coordinate.y + self.coordinate.z == 0.0;
}

- (CGRect)frame {
    CGPoint offsetPoint = self.center;
    return CGRectOffset(self.bounds, offsetPoint.x, offsetPoint.y);
}

- (CGRect)bounds {
    if (_needsLayoutBounds) {
        CGFloat minX = MAXFLOAT;
        CGFloat minY = MAXFLOAT;
        CGFloat maxX = -MAXFLOAT;
        CGFloat maxY = -MAXFLOAT;
        
        CGPoint *points = [self localVertices];
        for (NSUInteger i=0; i<6; i++) {
            CGPoint p = points[i];
            if (p.x < minX) { minX = p.x; }
            if (p.y < minY) { minY = p.y; }
            if (p.x > maxX) { maxX = p.x; }
            if (p.y > maxY) { maxY = p.y; }
        }

        _bounds = CGRectMake(minX, minY, fabsf(maxX-minX), fabsf(maxY-minY));
        _needsLayoutBounds = NO;
    }
    return _bounds;
}

- (CGPoint)localCenter {
    if (_needsLayoutCenter) {
        HKHexagonCoordinate2D hex = hexConvertCubeToAxial(self.coordinate);
        CGPoint s = CGPointZero;
        
        if (self.grid.hexOrientation == HKHexagonGridOrientationPointy) {
            s = CGPointMake(SQRT_3 * hex.q + SQRT_3_2 * hex.r, 1.5 * hex.r);
        } else {
            s = CGPointMake(1.5 * hex.q, SQRT_3_2 * hex.q + SQRT_3 * hex.r);
        }
        _localCenter = CGPointMultiply(s, self.grid.hexSize);
        _needsLayoutCenter = NO;
    }
    return _localCenter;
}
- (CGPoint)center {
    CGPoint offsetPoint = self.grid.contentCenter;
    CGPoint localCenter = [self localCenter];
    return CGPointAdd(localCenter, offsetPoint);
}

- (CGPoint *)localVertices {
    if (_needsLayoutVertices) {
        for (NSUInteger i=0; i<6; i++) {
            CGFloat orVal = self.grid.hexOrientation == HKHexagonGridOrientationPointy ? 1 : 0;
            CGFloat angle = 2 * M_PI / 12 * (2 * i - orVal);
            CGFloat x = self.grid.hexSize * cosf(angle);
            CGFloat y = self.grid.hexSize * sinf(angle);
            _localVertices[i] = CGPointMake(x, y);
        }
        _needsLayoutVertices = NO;
    }
    return _localVertices;
}
- (NSArray *)vertices {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:6];
    CGPoint offsetPoint = [self center];
    CGPoint *points = [self localVertices];
    for (NSUInteger i=0; i<6; i++) {
        CGPoint p = CGPointAdd(points[i], offsetPoint);
        [result addObject:[NSValue valueWithCGPoint:p]];
    }
    return result;
}

- (void)setNeedsLayout {
    
    _needsLayoutBounds = YES;
    _needsLayoutCenter = YES;
    _needsLayoutVertices = YES;
}

@end
