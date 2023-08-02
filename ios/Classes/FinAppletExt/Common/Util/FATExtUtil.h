//
//  FATExtUtil.h
//  FinAppletExt
//
//  Created by Haley on 2021/1/25.
//  Copyright © 2021 finogeeks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>

@interface FATExtUtil : NSObject

+ (NSString *)tmpDirWithAppletId:(NSString *)appletId;

+ (NSString *)fat_md5WithBytes:(char *)bytes length:(NSUInteger)length;

+ (NSString *)jsonStringFromDict:(NSDictionary *)dict;

+ (NSString *)jsonStringFromArray:(NSArray *)array;

+ (NSString *)signFromDict:(NSDictionary *)dict;

+ (NSString *)realPathForFINFile:(NSString *)finfile appId:(NSString *)appId;

/// 获取音频文件时长
/// @param fileURL 文件url（必须为AVURLAsset可解码的文件格式，如 .caf .aac .wav .mp3 等）
+ (float)durtaionWithFileURL:(NSURL *)fileURL;

/// 获取音频文件大小
/// @param fileURL 文件url
+ (long long)fileSizeWithFileURL:(NSURL *)fileURL;

/// 获取userId
+ (NSString *)currentUserId;

/**
 返回是否设置了产品标识。
 */
+ (BOOL)currentProductIdentificationIsEmpty;

/**
 返回设置了的产品标识。
 */
+ (NSString *)currentProductIdentification;

+ (NSString *)getAppName;

+ (void)getNearbyPlacesByCategory:(NSString *)category coordinates:(CLLocationCoordinate2D)coordinates radius:(NSInteger)radius token:(NSString *)token completion:(void (^)(NSDictionary *))completion;

+ (NSArray *)convertPlaceDictToArray:(NSDictionary*)dict;
@end
