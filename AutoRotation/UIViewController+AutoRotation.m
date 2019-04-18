
//
//  UIViewController+Rotation.m
//  OperationsDemo
//
//  Created by 昭荣伊 on 2019/3/6.
//  Copyright © 2019 昭荣伊. All rights reserved.
//

#import "UIViewController+AutoRotation.h"
#import <objc/runtime.h>

/// 方法交换
static inline void ar_exchangeMethod(Class originCls, SEL originSelector, Class targetCls, SEL targetSelector) {
    Method originalMethod = class_getInstanceMethod(targetCls, originSelector);
    Method swizzledMethod = class_getInstanceMethod(targetCls, targetSelector);
    BOOL success = class_addMethod(originCls,
                                   originSelector,
                                   method_getImplementation(swizzledMethod),
                                   method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(originCls,
                            targetSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static NSMutableSet<NSString *> *kSpecialControllers;

@implementation UIViewController (AutoRotation)

+ (void)load {
    kSpecialControllers = [NSMutableSet setWithArray:@[@"UIInputWindowController", @"UIApplicationRotationFollowingController", @"UIAlertController"]];
    ar_exchangeMethod(self, @selector(viewWillAppear:), self, @selector(ar_viewWillAppear:));
    ar_exchangeMethod(self, @selector(ar_supportedOrientations), self, @selector(_ar_supportedOrientations));
    ar_exchangeMethod(self, @selector(dismissViewControllerAnimated:completion:), self, @selector(ar_dismissViewControllerAnimated:completion:));
    ar_exchangeMethod(self, @selector(addChildViewController:), self, @selector(ar_addChildViewController:));
}

- (void)ar_viewWillAppear:(BOOL)animated {
    if (!self.ar_isChildController) {
        UIInterfaceOrientationMask mask = [self ar_supportedOrientations];
        [UIViewController setOrientation:mask];
    } else {
        NSLog(@"ar log: %@ ignoreRotations", NSStringFromClass(self.class));
    }
    
    [self ar_viewWillAppear:animated];
}

- (void)ar_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    void (^block)(void) = ^{
        if (completion) {
            completion();
        }
        [[UIViewController ar_currentViewController] ar_turnToOrientation:[UIViewController windowTopViewControllerOrientationMask]];
    };
    [self ar_dismissViewControllerAnimated:flag completion:block];
}

- (void)ar_addChildViewController:(UIViewController *)childController {
    childController.ar_isChildController = YES;
    [self ar_addChildViewController:childController];
}

- (UIInterfaceOrientationMask)ar_supportedOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientationMask)_ar_supportedOrientations {
    [UIViewController fixedControllerOrientationWithController:self];
    NSInteger mask = (NSInteger)self.ar_orientationMask;
    if (mask == 0) {
        return [self _ar_supportedOrientations];
    } else {
        return self.ar_orientationMask;
    }
}

- (void)ar_turnToOrientation:(UIInterfaceOrientationMask)orientation {
    self.ar_orientationMask = orientation;
    [UIViewController setOrientation:orientation];
}

- (void)ar_turnToPortrait {
    [self ar_turnToOrientation:UIInterfaceOrientationMaskPortrait];
}

- (void)ar_turnToLandscape {
    [self ar_turnToOrientation:UIInterfaceOrientationMaskLandscape];
}

#pragma mark - Setters And Getters

- (void)setAr_orientationMask:(UIInterfaceOrientationMask)ar_orientationMask {
    objc_setAssociatedObject(self, @selector(ar_orientationMask), @(ar_orientationMask), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIInterfaceOrientationMask)ar_orientationMask {
    return (UIInterfaceOrientationMask)[objc_getAssociatedObject(self, @selector(ar_orientationMask)) integerValue];
}

- (void)setAr_isChildController:(BOOL)ar_isChildController {
    objc_setAssociatedObject(self, @selector(ar_isChildController), @(ar_isChildController), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)ar_isChildController {
    return [objc_getAssociatedObject(self, @selector(ar_isChildController)) boolValue];
}

#pragma mark - 特殊 Controller 处理
+ (void)ar_addSpecialControllers:(NSArray<NSString *> *)controllers {
    [kSpecialControllers addObjectsFromArray:controllers];
}

+ (void)ar_removeSpecialControllers:(NSArray<NSString *> *)controllers {
    for (NSString *name in controllers) {
        [kSpecialControllers removeObject:name];
    }
}

#pragma mark - 方向处理
+ (BOOL)setOrientation:(UIInterfaceOrientationMask)orientation {
    UIInterfaceOrientation interfaceOrientation = [self getOrientationWithOrientationMask:orientation];
    UIInterfaceOrientation currentOrientation = [UIViewController currentOrientation];
    if (currentOrientation == interfaceOrientation) {
        return NO;
    }
    NSLog(@"ar log: interfaceOrientation:%ld", interfaceOrientation);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation animated:NO];
#pragma clang diagnostic pop
    [[UIDevice currentDevice] setValue:@(interfaceOrientation) forKey:@"orientation"];
    return YES;
}

+ (UIInterfaceOrientation)currentOrientation {
    // 设备方向(优先级高)
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    // statusBar方向(优先级低)
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 当前方向
    UIInterfaceOrientation currentOrientation = UIInterfaceOrientationPortrait;
    // 平放的时候取状态栏方向，否则取设备方向
    if ((deviceOrientation) == UIDeviceOrientationFaceUp || (deviceOrientation) == UIDeviceOrientationFaceDown) { // UIDeviceOrientationIsFlat
        currentOrientation = statusBarOrientation;
    } else {
        currentOrientation = (UIInterfaceOrientation)deviceOrientation;
    }
    return currentOrientation;
}

+ (UIInterfaceOrientation)getOrientationWithOrientationMask:(UIInterfaceOrientationMask)orientation {
    // 当前方向
    UIInterfaceOrientation currentOrientation = [UIViewController currentOrientation];
    UIInterfaceOrientation targetOrientation = UIInterfaceOrientationPortrait;
    
    if (orientation == UIInterfaceOrientationMaskAllButUpsideDown) {
        // 支持三个方向
        if (UIInterfaceOrientationIsPortrait(currentOrientation)) {
            targetOrientation = UIInterfaceOrientationPortrait;
        } else {
            if (currentOrientation == UIInterfaceOrientationLandscapeLeft ||
                currentOrientation == UIInterfaceOrientationPortraitUpsideDown) {
                targetOrientation = UIInterfaceOrientationLandscapeLeft;
            } else {
                targetOrientation = UIInterfaceOrientationLandscapeRight;
            }
        }
    } else if (orientation  == UIInterfaceOrientationMaskLandscape) {
        // 支持双横向
        if (currentOrientation == UIInterfaceOrientationLandscapeLeft ||
            currentOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            targetOrientation = UIInterfaceOrientationLandscapeLeft;
        } else {
            targetOrientation = UIInterfaceOrientationLandscapeRight;
        }
    } else if (orientation  == (UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait)) {
        // 支持右向和纵向
        if (UIInterfaceOrientationIsPortrait(currentOrientation)) {
            targetOrientation = UIInterfaceOrientationPortrait;
        } else {
            targetOrientation = UIInterfaceOrientationLandscapeRight;
        }
    } else if (orientation == (UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskPortrait)) {
        // 支持左向和纵向
        if (UIInterfaceOrientationIsPortrait(currentOrientation)) {
            targetOrientation = UIInterfaceOrientationPortrait;
        } else {
            targetOrientation = UIInterfaceOrientationLandscapeLeft;
        }
    } else if (orientation  == UIInterfaceOrientationMaskLandscapeRight) {
        // 支持右向
        targetOrientation = UIInterfaceOrientationLandscapeRight;
    } else if (orientation  == UIInterfaceOrientationMaskLandscapeLeft) {
        // 支持左向
        targetOrientation = UIInterfaceOrientationLandscapeLeft;
    } else {
        // 纵向
        targetOrientation = UIInterfaceOrientationPortrait;
    }
    return targetOrientation;
}

+ (void)fixedControllerOrientationWithController:(UIViewController *)controller {
    // 特殊的 Controller
    if ([kSpecialControllers containsObject: NSStringFromClass(controller.class)]) {
        UIInterfaceOrientationMask mask = [UIViewController windowTopViewControllerOrientationMask];
        controller.ar_orientationMask = mask;
    }
}

#pragma mark - Controller 处理
+ (UIInterfaceOrientationMask)windowTopViewControllerOrientationMask {
    UIInterfaceOrientationMask mask = UIInterfaceOrientationMaskPortrait;
    UIViewController *ctrl = nil;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    // 排队键盘等其它窗口，找到真实的 View 窗口
    if (![@"UIWindow" isEqualToString:NSStringFromClass(keyWindow.class)]) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if ([@"UIWindow" isEqualToString:NSStringFromClass(window.class)]) {
                keyWindow = window;
                break;
            }
        }
    }
    ctrl = [UIViewController ar_topViewControllerForWindow:keyWindow];
    // 处理特殊的 Controller
    if (ctrl && [kSpecialControllers containsObject:NSStringFromClass(ctrl.class)]) {
        // 找到弹出特殊 Controller 的类
        while ([kSpecialControllers containsObject:NSStringFromClass(ctrl.class)] && ctrl.presentingViewController) {
            ctrl = ctrl.presentingViewController;
        }
        // 获取真实的 Controller
        while ([ctrl isKindOfClass:UINavigationController.class] ||
               [ctrl isKindOfClass:UITabBarController.class]) {
            if ([ctrl isKindOfClass:UINavigationController.class]) {
                ctrl = [(UINavigationController *)ctrl topViewController];
            } else if ([ctrl isKindOfClass:UITabBarController.class]) {
                ctrl = [(UITabBarController *)ctrl selectedViewController];
            }
        }
        // 获取真实需要处理的 Controller
        if (ctrl && ![kSpecialControllers containsObject:NSStringFromClass(ctrl.class)]) {
            mask = [ctrl ar_supportedOrientations];
        }
    } else if (ctrl) {
        mask = [ctrl ar_supportedOrientations];
    }
    return mask;
}

+ (UIViewController *)ar_currentViewController {
    UIWindow *keyWindow =  [UIApplication sharedApplication].keyWindow;
    return [self ar_topViewControllerForWindow:keyWindow];
}

+ (UIViewController *)ar_topViewControllerForWindow:(UIWindow *)window {
    UIViewController *rootViewController = window.rootViewController;
    rootViewController = [self ar_topViewController:rootViewController];
    while (rootViewController.presentedViewController) {
        rootViewController = [self ar_topViewController:rootViewController.presentedViewController];
    }
    return rootViewController;
}

/**
 获取顶部VC
 
 @param viewController 当前 VC
 @return 顶部 VC
 */
+ (UIViewController *)ar_topViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return [self ar_topViewController:[(UINavigationController *)viewController topViewController]];
    } else if ([viewController isKindOfClass:[UITabBarController class]]) {
        return [self ar_topViewController:[(UITabBarController *)viewController selectedViewController]];
    } else {
        return viewController;
    }
}

@end

@implementation UIResponder(AutoRotation)

+ (void)load {
    ar_exchangeMethod(self, @selector(application:supportedInterfaceOrientationsForWindow:), self, @selector(ar_application:supportedInterfaceOrientationsForWindow:));
}

- (UIInterfaceOrientationMask)ar_application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    UIInterfaceOrientationMask mask = [UIViewController windowTopViewControllerOrientationMask];
    [UIViewController setOrientation:mask];
    return mask;
}

@end


