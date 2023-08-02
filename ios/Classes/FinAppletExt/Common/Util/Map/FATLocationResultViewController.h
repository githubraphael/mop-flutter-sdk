//
//  FATLocationResultViewController.h
//  AppletDemo
//
//  Created by Haley on 2020/4/17.
//  Copyright © 2020 weidian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <FinApplet/FinApplet.h>

#import "FATMapPlace.h"

@protocol FATLocationResultDelegate <NSObject>

- (void)selectedLocationWithLocation:(FATMapPlace *)place;

@end

@interface FATLocationResultViewController : FATUIViewController <UISearchResultsUpdating>

@property (nonatomic, assign) MKCoordinateRegion region;
@property (nonatomic, weak) id<FATLocationResultDelegate> delegate;
@property (nonatomic, assign) NSInteger searchBarHeight;

@end
