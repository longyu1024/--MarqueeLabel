//
//  MarqueeLabel.h
//  Marquee
//
//  Created by WangBin on 15/11/26.
//  Copyright © 2015年 WangBin. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifndef IBInspectable
#define IBInspectable
#endif

@interface MarqueeLabel : UILabel

- (instancetype)initWithFrame:(CGRect)frame duration:(NSTimeInterval)duration;

@property (nonatomic,assign) IBInspectable CGFloat duration;

- (void)start;
- (void)pause;
@end
