//
//  FATExtNavigationController.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2022/10/28.
//  Copyright © 2022 finogeeks. All rights reserved.
//

#import "FATExtNavigationController.h"

@interface FATExtNavigationController ()

@end

@implementation FATExtNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

//支持旋转
- (BOOL)shouldAutorotate {
    return NO;
}

//支持的方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
