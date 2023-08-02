//
//  FATExtMapManager.h
//  FinAppletExt
//
//  Created by 王兆耀 on 2021/11/18.
//

#import <Foundation/Foundation.h>
#import "FATExtPrivateConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface FATExtMapManager : NSObject
@property (nonatomic, copy) NSString *pageId;
@property (nonatomic, strong) Class mapClass;
@property (nonatomic, strong) NSString *googleMapApiKey;
@property (nonatomic, strong) NSString *placesApiKey;
+ (instancetype)shareInstance;

@property (nonatomic, strong) NSMutableDictionary *dataDic;


@end

NS_ASSUME_NONNULL_END
