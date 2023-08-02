//
//  FATExtFileManager.h
//  FinAppletExt
//
//  Created by Haley on 2020/8/17.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FATExtFileManager : NSObject

/**
 工程根目录路径

 @return 工程根目录路径
 */
+ (NSString *)projectRootAppsDirPath;

/**
 获取当前小程序根目录
 */
+ (NSString *)appRootDirPath:(NSString *)appId;

/**
 获取当前小程序临时存储目录
 */
+ (NSString *)appTempDirPath:(NSString *)appId;

@end
