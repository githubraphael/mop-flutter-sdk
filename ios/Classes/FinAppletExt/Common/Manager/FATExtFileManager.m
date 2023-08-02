//
//  FATExtFileManager.m
//  FinAppletExt
//
//  Created by Haley on 2020/8/17.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATExtFileManager.h"
#import "FATExtUtil.h"

#import <FinApplet/FinApplet.h>

static NSString *FATEXT_PROJECT_ROOT = @"FinChatRoot";
static NSString *FATEXT_PROJECT_ROOT_App = @"app";
static NSString *FATEXT_PROJECT_ROOT_Framework = @"framework";

@implementation FATExtFileManager

+ (NSString *)projectRootDirPath {
    NSString *rootPath;
    if ([FATExtUtil currentProductIdentificationIsEmpty]) {
        rootPath = [NSTemporaryDirectory() stringByAppendingPathComponent:FATEXT_PROJECT_ROOT];
    } else {
        rootPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[FATExtUtil currentProductIdentification]];
    }
    return rootPath;
}

+ (NSString *)projectRootAppsDirPath {
    NSString *rootPath = [[FATExtFileManager projectRootDirPath] stringByAppendingFormat:@"/%@", FATEXT_PROJECT_ROOT_App];

    return rootPath;
}

/**
 获取当前小程序根路径
 
 @return 获取当前小程序根路径
 */
+ (NSString *)appRootDirPath:(NSString *)appId {
    NSString *rootPath = [FATExtFileManager projectRootAppsDirPath];
    NSString *appDirPath = [rootPath stringByAppendingPathComponent:appId];
    return appDirPath;
}

/**
 小程序临时存储目录

 @return NSString *
 */
+ (NSString *)appTempDirPath:(NSString *)appId {
    NSString *currtUserId = [FATExtUtil currentUserId];
    NSString *tempFileCachePath = [[FATExtFileManager appRootDirPath:appId] stringByAppendingPathComponent:[currtUserId fat_md5String]];
    tempFileCachePath = [tempFileCachePath stringByAppendingPathComponent:@"Temp"];

    return tempFileCachePath;
}

@end
