//
//  PhizLanguageData.h
//  FinDemo
//
//  Created by stewen on 2023/8/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhizLanguageData : NSObject

@property (nonatomic, copy) NSString *languageCode;
@property (nonatomic, copy) NSString *countryCode;

+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
