//
//  FATAnnotation.m
//  AppletDemo
//
//  Created by Haley on 2020/4/17.
//  Copyright © 2020 weidian. All rights reserved.
//

#import "FATAnnotation.h"

@implementation FATAnnotation

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [super init]) {
        self.coordinate = coordinate;
    }
    return self;
}

@end
