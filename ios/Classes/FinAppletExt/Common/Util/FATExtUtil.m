//
//  FATExtUtil.m
//  FinAppletExt
//
//  Created by Haley on 2021/1/25.
//  Copyright © 2021 finogeeks. All rights reserved.
//

#import "FATExtUtil.h"
#import "FATExtFileManager.h"
#import "FATExtMapManager.h"
#import "fincore.h"
#import "FATMapPlace.h"

#import <FinApplet/FinApplet.h>
#import <CommonCrypto/CommonDigest.h>

#define FAT_EXT_FILE_SCHEMA @"finfile://"

@implementation FATExtUtil

+ (NSString *)tmpDirWithAppletId:(NSString *)appletId {
    if (!appletId) {
        return nil;
    }

    NSString *cacheDir = [FATExtFileManager appTempDirPath:appletId];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL flag = YES;
    if (![fileManager fileExistsAtPath:cacheDir isDirectory:&flag]) {
        [fileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return cacheDir;
}

+ (NSString *)fat_md5WithBytes:(char *)bytes length:(NSUInteger)length {
    unsigned char result[16];
    CC_MD5(bytes, (CC_LONG)length, result);
    return [NSString stringWithFormat:
                         @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                         result[0], result[1], result[2], result[3],
                         result[4], result[5], result[6], result[7],
                         result[8], result[9], result[10], result[11],
                         result[12], result[13], result[14], result[15]];
}

+ (NSString *)jsonStringFromDict:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    if (!data) {
        return nil;
    }

    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return jsonString;
}

+ (NSString *)jsonStringFromArray:(NSArray *)array {
    if (!array || ![array isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:nil];
    if (!data) {
        return nil;
    }

    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return jsonString;
}

+ (NSString *)signFromDict:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *keys = [dict allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch]; //正序
    }];

    NSString *plainText = @"";
    for (NSString *key in sortedKeys) {
        NSString *and = [plainText isEqualToString:@""] ? @"" : @"&";
        NSString *value = [dict valueForKey:key];
        //        if ([value isKindOfClass:[NSDictionary class]]) {
        //            NSDictionary *dictValue = (NSDictionary *)value;
        //            value = [FATExtUtil jsonStringFromDict:dictValue];
        //        } else if ([key isKindOfClass:[NSArray class]]) {
        //            NSArray *arrayValue = (NSArray *)value;
        //            value = [FATExtUtil jsonStringFromArray:arrayValue];
        //        }
        if ([key isEqualToString:@"sign"]) {
            continue;
        }
        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
            NSString *append = [NSString stringWithFormat:@"%@%@=%@", and, key, value];
            plainText = [plainText stringByAppendingString:append];
        }
    }
//    NSLog(@"扩展：%@", plainText);
    NSString *digest = [[[SDKCoreClient sharedInstance].finoLicenseService fin_messageDigest:plainText] uppercaseString];
    NSData *data = [digest dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encodeData = [[SDKCoreClient sharedInstance].finoLicenseService fin_encodeSMContent:data];
    NSString *sign = [[NSString alloc] initWithData:encodeData encoding:NSUTF8StringEncoding];
//    NSLog(@"扩展sign：%@", sign);

    return sign;
}

/// 获取音频文件时长
/// @param fileURL 文件url（必须为AVURLAsset可解码的文件格式，如 .caf .aac .wav .mp3 等）
+ (float)durtaionWithFileURL:(NSURL *)fileURL {
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey : @(YES)};
    AVURLAsset *recordAsset = [AVURLAsset URLAssetWithURL:fileURL options:options];
    // 录音的时长，单位ms
    CMTime durationTime = recordAsset.duration;
    durationTime.value = durationTime.value;
    float seconds = CMTimeGetSeconds(durationTime);
    float duration = seconds * 1000;
    return duration;
}

/// 获取音频文件大小
/// @param fileURL 文件url
+ (long long)fileSizeWithFileURL:(NSURL *)fileURL {
    // 录音文件的大小，单位Byte
    NSFileManager *manager = [NSFileManager defaultManager];
    long long fileSize = [[manager attributesOfItemAtPath:fileURL.path error:nil] fileSize];
    return fileSize;
}

+ (NSString *)currentUserId {
    NSString *currentUserId = [FATClient sharedClient].config.currentUserId;
    NSString *productIdentification = [FATClient sharedClient].config.productIdentification;
    if (!currentUserId || currentUserId.length == 0) {
        if ([NSString fat_isEmptyWithString:productIdentification]) {
            currentUserId = @"finclip_default";
        } else {
            currentUserId = productIdentification;
        }
    }
    return currentUserId;
}

+ (BOOL)currentProductIdentificationIsEmpty {
    NSString *productIdentification = [FATClient sharedClient].config.productIdentification;
    return [NSString fat_isEmptyWithString:productIdentification];
}

+ (NSString *)currentProductIdentification {
    NSString *productIdentification = [FATClient sharedClient].config.productIdentification;
    return productIdentification;
}

+ (NSString *)getAppName {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDict valueForKey:@"CFBundleDisplayName"];
    if (!appName) appName = [infoDict valueForKey:@"CFBundleName"];
    if (!appName) appName = [infoDict valueForKey:@"CFBundleExecutable"];
    return appName;
}

+ (void)getNearbyPlacesByCategory:(NSString *)category coordinates:(CLLocationCoordinate2D)coordinates radius:(NSInteger)radius token:(NSString *)token
                       completion:(void (^)(NSDictionary *))completion {
    NSURL *url = [NSURL URLWithString:[self searchApiHost]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    if (token && [token length] > 0) {
        NSDictionary *parameters = @{
            @"key" : [FATExtMapManager shareInstance].googleMapApiKey,
            @"pagetoken" : token
        };
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSMutableArray *queryItems = [NSMutableArray array];
        for (NSString *key in parameters) {
            NSString *value = [NSString stringWithFormat:@"%@", parameters[key]];
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
        }
        urlComponents.queryItems = queryItems;
        request.URL = urlComponents.URL;
    } else {
        NSDictionary *parameters = @{
            @"key" : [FATExtMapManager shareInstance].placesApiKey,
            @"radius" : @(radius),
            @"location" : [NSString stringWithFormat:@"%f,%f", coordinates.latitude, coordinates.longitude],
            @"type" : [category lowercaseString]
        };
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSMutableArray *queryItems = [NSMutableArray array];
        for (NSString *key in parameters) {
            NSString *value = [NSString stringWithFormat:@"%@", parameters[key]];
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
        }
        urlComponents.queryItems = queryItems;
        request.URL = urlComponents.URL;
    }
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
            completion(nil);
            return;
        }
        
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                NSLog(@"Error: %@", jsonError);
                completion(nil);
            } else {
                completion(json);
            }
        } else {
            completion(nil);
        }
    }];
    
    [task resume];
}

+ (NSArray *)convertPlaceDictToArray:(NSDictionary*)dict{
    NSMutableArray *placeArrayM = [NSMutableArray array];
    for (NSDictionary *dictItem in [dict objectForKey:@"results"]) {
        FATMapPlace *place = [[FATMapPlace alloc] init];
        place.name = dictItem[@"name"];
        place.address = dictItem[@"vicinity"];
        FATMapPlace *mark = [[FATMapPlace alloc] init];
        NSDictionary *dict = dictItem[@"geometry"];
        mark.name = dictItem[@"name"];
        mark.address = dictItem[@"vicinity"];
        double lat = [dict[@"location"][@"lat"] doubleValue];
        double lng = [dict[@"location"][@"lng"] doubleValue];
        place.location = [[CLLocation alloc] initWithLatitude:lat longitude:lng] ;
        [placeArrayM addObject:place];
    }
    return placeArrayM;
}

+ (NSArray *)getCategories {
    NSArray *list = @[@"Places",@"Bakery", @"Doctor", @"School", @"Taxi_stand", @"Hair_care", @"Restaurant", @"Pharmacy", @"Atm", @"Gym", @"Store", @"Spa"];
    return list;
}

+ (NSString *)searchApiHost {
    return @"https://maps.googleapis.com/maps/api/place/nearbysearch/json";
}

+ (NSString *)googlePhotosHost {
    return @"https://maps.googleapis.com/maps/api/place/photo";
}

+ (NSString *)googlePlaceDetailsHost {
    return @"https://maps.googleapis.com/maps/api/place/details/json";
}


@end
