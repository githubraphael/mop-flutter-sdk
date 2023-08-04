//
//  PhizLanguageData.m
//  FinDemo
//
//  Created by stewen on 2023/8/4.
//

#import "PhizLanguageData.h"

@implementation PhizLanguageData

+ (instancetype)sharedInstance {
    static PhizLanguageData *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        //sharedInstance.languageCode = @"en"; // Set default language code
        //sharedInstance.countryCode = @"US";
    });
    return sharedInstance;
}

@end