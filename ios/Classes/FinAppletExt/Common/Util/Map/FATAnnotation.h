//
//  FATAnnotation.h
//  AppletDemo
//
//  Created by Haley on 2020/4/17.
//  Copyright © 2020 weidian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FATAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *address;

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end
