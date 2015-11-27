//
//  MarqueeLabel.m
//  Marquee
//
//  Created by WangBin on 15/11/26.
//  Copyright © 2015年 WangBin. All rights reserved.
//

#import "MarqueeLabel.h"
#import "UIView+Controller.h"

NSString *const kMarqueeLabelAnimationCompletionBlock = @"MarqueeLabelAnimationCompletionBlock";

@interface MarqueeLabel()
@property (nonatomic, strong) UILabel *marqueeLabel;
@property (nonatomic, assign, readwrite) BOOL isPaused;
@end

@implementation MarqueeLabel

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame duration:7];
}

-(instancetype)initWithFrame:(CGRect)frame duration:(NSTimeInterval)duration
{
    if (self = [super initWithFrame:frame]) {
        [self setUpMarqueeLabel];
        _duration = duration;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUpMarqueeLabel];
        if (self.duration == 0) {
            self.duration = 7.0;
        }
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    NSArray *properties = @[@"baselineAdjustment", @"enabled", @"highlighted", @"highlightedTextColor",
                            @"minimumFontSize", @"textAlignment",
                            @"userInteractionEnabled", @"adjustsFontSizeToFitWidth",
                            @"lineBreakMode", @"numberOfLines"];
    
    self.marqueeLabel.text = super.text;
    self.marqueeLabel.font = super.font;
    self.marqueeLabel.textColor = super.textColor;
    self.marqueeLabel.backgroundColor = (super.backgroundColor == nil ? [UIColor clearColor] : super.backgroundColor);
    self.marqueeLabel.shadowColor = super.shadowColor;
    self.marqueeLabel.shadowOffset = super.shadowOffset;
    for (NSString *property in properties) {
        id val = [super valueForKey:property];
        [self.marqueeLabel setValue:val forKey:property];
    }
}

#pragma mark - layer
+ (Class)layerClass {
    return [CAReplicatorLayer class];
}

- (CAReplicatorLayer *)repliLayer {
    return (CAReplicatorLayer *)self.layer;
}

#pragma mark - life state
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateMarqueeLabel];
}

- (void)didMoveToWindow {
    if (self.window) {
        [self updateMarqueeLabel];
    }
}

- (void)setUpMarqueeLabel
{
    if (!_marqueeLabel) {
        self.clipsToBounds = YES;
        self.numberOfLines = 1;
        
        _marqueeLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _marqueeLabel.layer.anchorPoint = CGPointMake(0.0f, 0.0f);
        
        [self addSubview:_marqueeLabel];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartLabel) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shutdownLabel) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
}

#pragma mark - on/off
- (void)start
{
    @synchronized(self) {
        if (_isPaused) {
            CFTimeInterval labelPausedTime = self.marqueeLabel.layer.timeOffset;
            self.marqueeLabel.layer.speed = 1.0;
            self.marqueeLabel.layer.timeOffset = 0.0;
            self.marqueeLabel.layer.beginTime = 0.0;
            self.marqueeLabel.layer.beginTime = [self.marqueeLabel.layer convertTime:CACurrentMediaTime() fromLayer:nil] - labelPausedTime;

            CFTimeInterval gradientPauseTime = self.layer.mask.timeOffset;
            self.layer.mask.speed = 1.0;
            self.layer.mask.timeOffset = 0.0;
            self.layer.mask.beginTime = 0.0;
            self.layer.mask.beginTime = [self.layer.mask convertTime:CACurrentMediaTime() fromLayer:nil] - gradientPauseTime;
            _isPaused = NO;
        }
    }
}

- (void)pause
{
    @synchronized(self) {
        if (!_isPaused) {
            
            CFTimeInterval labelPauseTime = [self.marqueeLabel.layer convertTime:CACurrentMediaTime() fromLayer:nil];
            self.marqueeLabel.layer.speed = 0.0;
            self.marqueeLabel.layer.timeOffset = labelPauseTime;
            
            CFTimeInterval gradientPauseTime = [self.layer.mask convertTime:CACurrentMediaTime() fromLayer:nil];
            self.layer.mask.speed = 0.0;
            self.layer.mask.timeOffset = gradientPauseTime;
            
            _isPaused = YES;
        }
    }
}

- (void)restartLabel {
    [self scroll];
}

- (void)shutdownLabel {
    [self.layer.mask removeAllAnimations];
    [self.marqueeLabel.layer removeAllAnimations];
}

#pragma mark - update marqueeLabel

- (void)updateMarqueeLabel
{
    if (self.window) {
        if (!self.marqueeLabel.text || !self.superview) {
            return;
        }
        CGSize realTextSize = [self marqueeLabelSize];
        if (![self labelShouldScroll]) {
            self.marqueeLabel.textAlignment = [super textAlignment];
            self.marqueeLabel.lineBreakMode = [super lineBreakMode];
            
            CGRect labelFrame = CGRectIntegral(CGRectMake(0, 0.0f, self.bounds.size.width, self.bounds.size.height));
            self.marqueeLabel.frame = CGRectIntegral(labelFrame);
            self.repliLayer.instanceCount = 1;

            return;
        }
        
        [self.marqueeLabel setLineBreakMode:NSLineBreakByClipping];
        CGRect labelFrame = CGRectMake(0, 0.0f, realTextSize.width, self.bounds.size.height);

        self.marqueeLabel.frame = CGRectIntegral(labelFrame);
        self.repliLayer.instanceCount = 2;//拷贝两份marqueeLabel
        self.repliLayer.instanceTransform = CATransform3DMakeTranslation(self.marqueeLabel.frame.size.width, 0.0, 0.0);//两份拷贝的marqueeLabel，默认是重叠在一起的，通过转换将两个marqueeLabel水平间距拉开
        
        [self scroll];
    }
}

- (void)scroll
{
    if (![self labelReadyForScroll]) {
        return;
    }
    [self.layer.mask removeAllAnimations];
    [self.marqueeLabel.layer removeAllAnimations];
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:(self.duration)];
    
    void(^completionBlock)(BOOL finished);
    
    completionBlock = ^(BOOL finished) {
        if (!finished) {
            
            return;
        }
        if (self.window && ![self.marqueeLabel.layer animationForKey:@"position"]) {
            if ([self labelShouldScroll]) {
                [self scroll];
            }
        }
    };

    CGPoint homeOrigin = self.marqueeLabel.frame.origin;
    CGPoint awayOrigin = CGPointMake(-CGRectGetMaxX(self.marqueeLabel.frame), homeOrigin.y);
    NSArray *values = @[[NSValue valueWithCGPoint:homeOrigin],
                        [NSValue valueWithCGPoint:homeOrigin],
                        [NSValue valueWithCGPoint:awayOrigin]];
    
    CAKeyframeAnimation *awayAnim = [self keyFrameAnimationForProperty:@"position" values:values];
    [awayAnim setValue:completionBlock forKey:kMarqueeLabelAnimationCompletionBlock];
    
    [self.marqueeLabel.layer addAnimation:awayAnim forKey:@"position"];
    
    [CATransaction commit];
}

- (CAKeyframeAnimation *)keyFrameAnimationForProperty:(NSString *)property
                                               values:(NSArray *)values
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:property];
    CAMediaTimingFunction *timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    animation.keyTimes = @[@(0.0),@(0.0), @(1.0)];
    
    animation.timingFunctions = @[timingFunction,timingFunction];
    animation.values = values;
    animation.delegate = self;
    
    return animation;
}

#pragma mark - animation delegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    void(^completionBlock)(BOOL finished);
    completionBlock = [anim valueForKey:kMarqueeLabelAnimationCompletionBlock];
    if (completionBlock) {
        completionBlock(flag);
    }
}

#pragma mark - marqueeLabel setter/getter

- (UIView *)viewForBaselineLayout {
    return self.marqueeLabel;
}

- (NSString *)text {
    return self.marqueeLabel.text;
}

- (void)setText:(NSString *)text {
    if ([text isEqualToString:self.marqueeLabel.text]) {
        return;
    }
    self.marqueeLabel.text = text;
    super.text = text;
    
    [self updateMarqueeLabel];
}

- (NSAttributedString *)attributedText {
    return self.marqueeLabel.attributedText;
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if ([attributedText isEqualToAttributedString:self.marqueeLabel.attributedText]) {
        return;
    }
    self.marqueeLabel.attributedText = attributedText;
    super.attributedText = attributedText;
    [self updateMarqueeLabel];
}

- (UIFont *)font {
    return self.marqueeLabel.font;
}

- (void)setFont:(UIFont *)font {
    if ([font isEqual:self.marqueeLabel.font]) {
        return;
    }
    self.marqueeLabel.font = font;
    super.font = font;
    [self updateMarqueeLabel];
}

- (UIColor *)textColor {
    return self.marqueeLabel.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    self.marqueeLabel.textColor = textColor;
    super.textColor = textColor;
}

- (UIColor *)backgroundColor {
    return self.marqueeLabel.backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.marqueeLabel.backgroundColor = backgroundColor;
    super.backgroundColor = backgroundColor;
}

- (UIColor *)shadowColor {
    return self.marqueeLabel.shadowColor;
}

- (void)setShadowColor:(UIColor *)shadowColor {
    self.marqueeLabel.shadowColor = shadowColor;
    super.shadowColor = shadowColor;
}

- (CGSize)shadowOffset {
    return self.marqueeLabel.shadowOffset;
}

- (void)setShadowOffset:(CGSize)shadowOffset {
    self.marqueeLabel.shadowOffset = shadowOffset;
    super.shadowOffset = shadowOffset;
}

- (UIColor *)highlightedTextColor {
    return self.marqueeLabel.highlightedTextColor;
}

- (void)setHighlightedTextColor:(UIColor *)highlightedTextColor {
    self.marqueeLabel.highlightedTextColor = highlightedTextColor;
    super.highlightedTextColor = highlightedTextColor;
}

- (BOOL)isHighlighted {
    return self.marqueeLabel.isHighlighted;
}

- (void)setHighlighted:(BOOL)highlighted {
    self.marqueeLabel.highlighted = highlighted;
    super.highlighted = highlighted;
}

- (BOOL)isEnabled {
    return self.marqueeLabel.isEnabled;
}

- (void)setEnabled:(BOOL)enabled {
    self.marqueeLabel.enabled = enabled;
    super.enabled = enabled;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines {
    [super setNumberOfLines:1];
}

- (void)setAdjustsFontSizeToFitWidth:(BOOL)adjustsFontSizeToFitWidth {
    [super setAdjustsFontSizeToFitWidth:NO];
}

- (void)setMinimumFontSize:(CGFloat)minimumFontSize {
    [super setMinimumFontSize:0.0];
}

- (UIBaselineAdjustment)baselineAdjustment {
    return self.marqueeLabel.baselineAdjustment;
}

- (void)setBaselineAdjustment:(UIBaselineAdjustment)baselineAdjustment {
    self.marqueeLabel.baselineAdjustment = baselineAdjustment;
    super.baselineAdjustment = baselineAdjustment;
}

- (CGSize)intrinsicContentSize {
    return self.marqueeLabel.intrinsicContentSize;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [self.marqueeLabel sizeThatFits:size];
    return fitSize;
}

- (void)setAdjustsLetterSpacingToFitWidth:(BOOL)adjustsLetterSpacingToFitWidth {
    [super setAdjustsLetterSpacingToFitWidth:NO];
}

- (void)setMinimumScaleFactor:(CGFloat)minimumScaleFactor {
    [super setMinimumScaleFactor:0.0f];
}

#pragma mark - Helpers

- (CGSize)marqueeLabelSize
{
    CGSize realTextSize = [self.marqueeLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    realTextSize.height = CGRectGetHeight(self.bounds);
    return realTextSize;
}

- (BOOL)labelShouldScroll
{
    CGSize realTextSize = [self marqueeLabelSize];
    BOOL labelShouldScroll = realTextSize.width > self.bounds.size.width;
    return labelShouldScroll;
}

- (BOOL)labelReadyForScroll {
    if (!self.superview) {
        return NO;
    }
    
    if (!self.window) {
        return NO;
    }
    
    UIViewController *viewController = [self firstAvailableViewController];
    if (!viewController.isViewLoaded) {
        return NO;
    }
    
    return YES;
}

@end