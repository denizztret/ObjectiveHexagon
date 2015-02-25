//
//  HKHexagon.h
//  ObjectiveHexagon
//
//  Created by Denis Tretyakov on 23.02.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "HKHexagonCoordinates.h"

@class HKHexagonGrid;

@interface HKHexagon : NSObject

@property (nonatomic, assign) HKHexagonCoordinate3D coordinate;
@property (nonatomic, weak) HKHexagonGrid *grid;
@property (nonatomic, readonly) NSString *hash;
@property (nonatomic, readonly) BOOL valid;

@property (nonatomic, readonly) CGRect frame;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) CGPoint center;
@property (nonatomic, readonly) NSArray *vertices;

+ (instancetype) hexagonWithCoordinate:(HKHexagonCoordinate3D)coordinate grid:(HKHexagonGrid *)grid;
- (instancetype) initWithCoordinate:(HKHexagonCoordinate3D)coordinate grid:(HKHexagonGrid *)grid;

@end
