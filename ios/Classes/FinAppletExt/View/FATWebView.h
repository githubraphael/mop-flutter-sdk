//
//  FATWebView.h
//  FinApplet
//
//  Created by Haley on 2019/12/9.
//  Copyright © 2019 finogeeks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FATWebView : UIView

- (instancetype)initWithFrame:(CGRect)frame URL:(NSURL *)URL appletId:(NSString *)appletId;

@end
