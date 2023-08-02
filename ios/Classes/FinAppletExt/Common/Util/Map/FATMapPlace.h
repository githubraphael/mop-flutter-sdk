//
//  FATMapPlace.h
//  AppletDemo
//
//  Created by Haley on 2020/4/17.
//  Copyright © 2020 weidian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLPlacemark.h>

@interface FATMapPlace : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *address;

//@property (nonatomic, strong) CLPlacemark *placemark;
@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, assign) BOOL selected;

@end
