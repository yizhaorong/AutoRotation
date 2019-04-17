//
//  ARViewController.m
//  AutoRotation
//
//  Created by yizhaorong on 04/17/2019.
//  Copyright (c) 2019 yizhaorong. All rights reserved.
//

#import "ARViewController.h"
#import <AutoRotation/AutoRotation.h>

@interface ARViewController ()

@end

@implementation ARViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
    button.frame = CGRectMake(100, 100, 100, 44);
    button.backgroundColor = [UIColor redColor];
    [button addTarget:self action:@selector(alertAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)alertAction:(id)sender {
    UIAlertController *alertControler = [UIAlertController alertControllerWithTitle:@"alert" message:@"body" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertControler animated:YES completion:nil];
}

- (UIInterfaceOrientationMask)ar_supportedRotations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
