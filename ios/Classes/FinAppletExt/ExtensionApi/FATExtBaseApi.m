//
//  FATExtBaseApi.m
//  FinAppletExtension
//
//  Created by Haley on 2020/8/11.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATExtBaseApi.h"
#import <objc/runtime.h>

@implementation FATExtBaseApi
- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    //默认实现，子类重写！！！
    if (cancel) {
        cancel(nil);
    }

    if (success) {
        success(@{});
    }

    if (failure) {
        failure(nil);
    }
}

/**
 同步api，子类重写
 */
- (NSString *)setupSyncApi {
    return nil;
}

+ (id<FATApiProtocol>)fat_apiWithApiClass:(NSString *)apiClassName params:(NSDictionary *)params {
    if (!apiClassName) {
        return nil;
    }
    Class apiClass = NSClassFromString(apiClassName);
    if (!apiClass) {
        return nil;
    }
    id apiObj = [[apiClass alloc]init];
    if (![apiObj conformsToProtocol:@protocol(FATApiProtocol)]) {
        return nil;
    }
    id<FATApiProtocol> api = (id<FATApiProtocol>)apiObj;
    NSString *apiName = @"";
    //分离出事件名
    NSArray *apiNameArray = [apiClassName componentsSeparatedByString:@"_"];
    if (apiNameArray && apiNameArray.count > 1) {
        apiName = apiNameArray[1];
    }
    [self setAPiObjectProperty:api command:apiName params:params];
    return api;
}

+ (void)setAPiObjectProperty:(id<FATApiProtocol>) api command:(NSString *)command params:(NSDictionary *)param {
    if (![api isKindOfClass:NSObject.class]) {
        return;
    }
    NSObject *apiObj = (NSObject *)api;
    [apiObj setValue:command forKey:@"command"];
    [apiObj setValue:param forKey:@"param"];
    //postMessage事件传过来的params是NSString
    if ([param isKindOfClass:NSDictionary.class]) {
        for (NSString *datakey in param.allKeys) {
            NSString *propertyKey = datakey;
            @autoreleasepool {
                objc_property_t property = class_getProperty([apiObj class], [propertyKey UTF8String]);
                if (!property) {
                    continue;
                }

                id value = [param objectForKey:datakey];
                id safetyValue = [self parseFromKeyValue:value];

                if (!safetyValue) continue;

                NSString *propertyType = [NSString stringWithUTF8String:property_copyAttributeValue(property, "T")];
                propertyType = [propertyType stringByReplacingOccurrencesOfString:@"@" withString:@""];
                propertyType = [propertyType stringByReplacingOccurrencesOfString:@"\\" withString:@""];
                propertyType = [propertyType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                //NSLog(@"propertyType:%@,value是：%@", propertyType,value);

                //只检校以下几种类型，可变类型我们一般用不着，故不检校
                if (
                    [propertyType isEqualToString:@"NSString"] ||
                    [propertyType isEqualToString:@"NSArray"] ||
                    [propertyType isEqualToString:@"NSDictionary"]) {
                    if (![safetyValue isKindOfClass:NSClassFromString(propertyType)]) {
                        continue;
                    }
                }

                //NSNumber类型和基本类型统一处理为string，也不需要检校了
                //其他类型不检校
                [apiObj setValue:safetyValue forKey:propertyKey];
            }
        }
    }
}

//+ (id)parseFromKeyValue:(id)value {
//    //值无效
//    if ([value isKindOfClass:[NSNull class]]) {
//        return nil;
//    }
//
//    if ([value isKindOfClass:[NSNumber class]]) { //统一处理为字符串
//        value = [NSString stringWithFormat:@"%@", value];
//    }
//
//    return value;
//}

//// 作空值过滤处理-任意对象
+ (id)parseFromKeyValue:(id)value {
    //值无效
    if ([value isKindOfClass:[NSNull class]]) {
        return nil;
    }

    if ([value isKindOfClass:[NSNumber class]]) { //统一处理为字符串
        value = [NSString stringWithFormat:@"%@", value];
    } else if ([value isKindOfClass:[NSArray class]]) { //数组
        value = [self parseFromArray:value];
    } else if ([value isKindOfClass:[NSDictionary class]]) { //字典
        value = [self parseFromDictionary:value];
    }

    return value;
}

// 作空值过滤处理-字典对象
+ (NSDictionary *)parseFromDictionary:(NSDictionary *)container {
    if ([container isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *result = [NSMutableDictionary new];
        for (id key in container.allKeys) {
            @autoreleasepool {
                id value = container[key];

                id safetyValue = [self parseFromKeyValue:value];
                if (!safetyValue) {
                    safetyValue = @"";
                }
                [result setObject:safetyValue forKey:key];
            }
        }
        return result;
    }
    return container;
}

// 作空值过滤处理-数组对象
+ (NSArray *)parseFromArray:(NSArray *)container {
    if ([container isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray new];
        for (int i = 0; i < container.count; i++) {
            @autoreleasepool {
                id value = container[i];

                id safetyValue = [self parseFromKeyValue:value];
                if (!safetyValue) {
                    safetyValue = @"";
                }

                [result addObject:safetyValue];
            }
        }

        return result;
    }

    return container;
}

@end
