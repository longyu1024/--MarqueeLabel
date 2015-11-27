//
//  UIView+Controller.h
//  Marquee
//
//  Created by WangBin on 15/11/27.
//  Copyright © 2015年 WangBin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Controller)
- (UIViewController *)firstAvailableViewController;
- (id)traverseResponderChainForFirstViewController;
@end
