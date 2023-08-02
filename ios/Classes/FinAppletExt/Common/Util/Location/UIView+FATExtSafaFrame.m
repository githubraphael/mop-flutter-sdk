//
//  UIView+FATExtSafaFrame.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2023/5/25.
//  Copyright © 2023 finogeeks. All rights reserved.
//

#import "UIView+FATExtSafaFrame.h"
#import <objc/runtime.h>

@implementation UIView (FATExtSafaFrame)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method method1 = class_getInstanceMethod(self.class, @selector(setFrame:));
        Method method2 = class_getInstanceMethod(self.class, @selector(fatSafe_setFrame:));
        method_exchangeImplementations(method1, method2);
        Method method3 = class_getInstanceMethod(self.class, @selector(setCenter:));
        Method method4 = class_getInstanceMethod(self.class, @selector(fatSafe_setCenter:));
        method_exchangeImplementations(method3, method4);
    });
}

- (void)fatSafe_setFrame:(CGRect)frame{
  
    CGRect unitFrame = frame;
    
    if(isnan(unitFrame.origin.x)){
        return;
    }
    if(isnan(unitFrame.origin.y)){
        return;
    }
    if(isnan(unitFrame.size.width)){
        return;
    }
    if(isnan(unitFrame.size.height)){
        return;
    }
    
    @try {
        [self fatSafe_setFrame:unitFrame];
    } @catch (NSException *exception) {
        
    } @finally {
    }
}

- (void)fatSafe_setCenter:(CGPoint)center{
    
    CGPoint unitCenter = center;
    
    if(isnan(unitCenter.x)){
        return;
    }
    if(isnan(unitCenter.y)){
        return;
    }
    
    @try {
        [self fatSafe_setCenter:unitCenter];
    } @catch (NSException *exception) {
        
    } @finally {
    }
}

@end
