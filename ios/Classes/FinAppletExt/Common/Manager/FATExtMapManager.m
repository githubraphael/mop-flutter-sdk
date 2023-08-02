//
//  FATExtMapManager.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2021/11/18.
//

#import "FATExtMapManager.h"
#import <FinApplet/FinApplet.h>
#import "FATMapViewDelegate.h"
#import "FATMapView.h"

static FATExtMapManager *instance = nil;

@implementation FATExtMapManager

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FATExtMapManager alloc] init];
    });
    
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dataDic = [[NSMutableDictionary alloc] init];
        self.mapClass = FATMapView.class;
    }
    return self;
}

@end
