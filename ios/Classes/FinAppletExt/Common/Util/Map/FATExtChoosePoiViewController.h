//
//  FATExtChoosePoiViewController.h
//  FinAppletExt
//
//  Created by 王兆耀 on 2021/12/8.
//

#import <UIKit/UIKit.h>
#import <FinApplet/FinApplet.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SureBlock)(NSDictionary *locationInfo);

@interface FATExtChoosePoiViewController : FATUIViewController

@property (nonatomic, copy) dispatch_block_t cancelBlock;
@property (nonatomic, copy) SureBlock sureBlock;

@end

NS_ASSUME_NONNULL_END
