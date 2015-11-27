//
//  ViewController.m
//  Marquee
//
//  Created by WangBin on 15/11/26.
//  Copyright © 2015年 WangBin. All rights reserved.
//

#import "ViewController.h"
#import "MarqueeLabel.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet MarqueeLabel *ml;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)pause:(id)sender {
    [_ml pause];
}

- (IBAction)start:(id)sender {
    [_ml start];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
