//
//  FATLocationManager.h
//  FinApplet
//
//  Created by Haley on 2020/4/7.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface FATLocationManager : NSObject

@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, strong) CLPlacemark *placemark;

+ (instancetype)manager;

- (void)updateLocation;

@end
