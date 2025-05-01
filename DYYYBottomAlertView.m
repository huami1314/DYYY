#import "DYYYBottomAlertView.h"
#import "AwemeHeaders.h"

#import "DYYYUtils.h"

@implementation DYYYBottomAlertView

// 自定义方法，支持同时自定义取消和确认按钮文本
+ (UIViewController *)showAlertWithTitle:(NSString *)title
                                 message:(NSString *)message
                         cancelButtonText:(NSString *)cancelButtonText
                        confirmButtonText:(NSString *)confirmButtonText
                            cancelAction:(DYYYAlertActionHandler)cancelAction
                           confirmAction:(DYYYAlertActionHandler)confirmAction {
    
    AFDPrivacyHalfScreenViewController *vc = [NSClassFromString(@"AFDPrivacyHalfScreenViewController") new];
    
    // 使用默认值处理空参数
    if (!cancelButtonText) {
        cancelButtonText = @"取消";
    }
    
    if (!confirmButtonText) {
        confirmButtonText = @"确定";
    }
    
    DYYYAlertActionHandler wrappedCancelAction = nil;
    if (cancelAction) {
        wrappedCancelAction = ^{
            [self dismissAlertViewController:vc];
            cancelAction();
        };
    } else {
        wrappedCancelAction = ^{
            [self dismissAlertViewController:vc];
        };
    }
    
    DYYYAlertActionHandler wrappedConfirmAction = nil;
    if (confirmAction) {
        wrappedConfirmAction = ^{
            [self dismissAlertViewController:vc];
            confirmAction();
        };
    } else {
        wrappedConfirmAction = ^{
            [self dismissAlertViewController:vc];
        };
    }
    
    // 设置滑动关闭和点击关闭的处理
    [vc setSlideDismissBlock:^{
        [self dismissAlertViewController:vc];
    }];
    
    [vc setTapDismissBlock:^{
        [self dismissAlertViewController:vc];
    }];
    
    // 设置关闭后的回调
    [vc setAfterDismissBlock:^{
        if (vc.view.superview) {
            [self dismissAlertViewController:vc];
        }
    }];
    
    [vc configWithImageView:nil 
                  lockImage:nil 
           defaultLockState:NO 
            titleLabelText:title 
          contentLabelText:message 
      leftCancelButtonText:cancelButtonText 
    rightConfirmButtonText:confirmButtonText 
       rightBtnClickedBlock:wrappedConfirmAction
      leftButtonClickedBlock:wrappedCancelAction];
    
    // 设置圆角
    [vc setCornerRadius:16.0];
    [vc setOnlyTopCornerClips:YES];
    
    [vc setUseCardUIStyle:YES];

    // 使用 keyWindow 直接添加视图
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [vc.view setFrame:window.bounds];
    [window addSubview:vc.view];
    
    // 将视图控制器作为子视图控制器添加到根视图控制器
    UIViewController *topVC = topView();
    [topVC addChildViewController:vc];
    [vc didMoveToParentViewController:topVC];
    
    return vc;
}

// 添加用于移除弹窗的辅助方法
+ (void)dismissAlertViewController:(UIViewController *)viewController {
    if (!viewController) return;
    
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

// 原始方法保持不变，维持向后兼容性
+ (UIViewController *)showAlertWithTitle:(NSString *)title
                                 message:(NSString *)message
                            cancelAction:(DYYYAlertActionHandler)cancelAction
                           confirmAction:(DYYYAlertActionHandler)confirmAction {
    return [self showAlertWithTitle:title 
                            message:message 
                    cancelButtonText:@"取消" 
                   confirmButtonText:@"确定" 
                        cancelAction:cancelAction 
                       confirmAction:confirmAction];
}

@end