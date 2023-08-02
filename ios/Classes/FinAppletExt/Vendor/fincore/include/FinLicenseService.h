//
//  FinLicenseService.h
//  fincore
//
//  Created by gordanyang on 2021/8/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FinLicenseService : NSObject

@property (nonatomic, strong) NSLock *checkLock;

#pragma mark - encode/decode

- (NSString *)fin_decodeAppKey:(NSString *)encryptText;
- (NSDictionary *)fin_getSDKKeyInfo;

- (NSString *)fin_decodeAppKeyBySM4:(NSString *)appKey;
- (NSDictionary *)fin_getSDKKeyInfoBySM3;

- (NSString *)fin_messageDigest:(NSString *)message;
- (NSString *)fin_messageDigest_sha256:(NSString *)message;

- (NSData *)fin_encodeAESContent:(NSData *)content;
- (NSData *)fin_decodeAESContent:(NSData *)content;
- (NSData *)fin_encodeSMContent:(NSData *)content;
- (NSData *)fin_decodeSMContent:(NSData *)content;

@end

NS_ASSUME_NONNULL_END
