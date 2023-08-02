//
//  FATExtHelper.m
//  FinAppletExt
//
//  Created by Haley on 2020/8/19.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATExtHelper.h"

@implementation FATExtHelper

+ (UIImage *)fat_ext_imageFromBundleWithName:(NSString *)imageName {
    NSString *bundleResourcePath = [NSBundle bundleForClass:[FATExtHelper class]].resourcePath;
    NSString *assetPath = [bundleResourcePath stringByAppendingPathComponent:@"FinAppletExt.bundle"];
    NSBundle *assetBundle = [NSBundle bundleWithPath:assetPath];
    NSString *path = [[assetBundle bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", imageName]];
    return [UIImage imageWithContentsOfFile:path];
}

@end
