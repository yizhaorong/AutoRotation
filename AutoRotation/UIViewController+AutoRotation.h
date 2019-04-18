//
//  UIViewController+Rotation.h
//  OperationsDemo
//
//  Created by 昭荣伊 on 2019/3/6.
//  Copyright © 2019 昭荣伊. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (AutoRotation)

// 当前方向
@property (nonatomic, assign) UIInterfaceOrientationMask ar_orientationMask;
// 是否子控制器
@property (nonatomic, assign) BOOL ar_isChildController;
/// 支持的方向
- (UIInterfaceOrientationMask)ar_supportedOrientations;
/// 转到指定方向
- (void)ar_turnToOrientation:(UIInterfaceOrientationMask)orientation;
/// 转为竖屏
- (void)ar_turnToPortrait;
/// 转为横屏
- (void)ar_turnToLandscape;
/// 添加特殊处理Controller，用于处理如 AlertContoller 等情况
+ (void)ar_addSpecialControllers:(NSArray<NSString *> *)controllers;
/// 移除特殊处理Controller
+ (void)ar_removeSpecialControllers:(NSArray<NSString *> *)controllers;

@end

