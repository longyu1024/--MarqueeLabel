//
//  UIView+Controller.m
//  Marquee
//
//  Created by WangBin on 15/11/27.
//  Copyright © 2015年 WangBin. All rights reserved.
//

#import "UIView+Controller.h"

@implementation UIView (Controller)

- (id)firstAvailableViewController
{
    // convenience function for casting and to "mask" the recursive function
    return [self traverseResponderChainForFirstViewController];
}

- (id)traverseResponderChainForFirstViewController
{
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder traverseResponderChainForFirstViewController];
    } else {
        return nil;
    }
}
@end
