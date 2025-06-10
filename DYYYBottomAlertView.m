#import "DYYYBottomAlertView.h"
#import "AwemeHeaders.h"

#import "DYYYUtils.h"

@implementation DYYYBottomAlertView

+ (UIViewController *)showAlertWithTitle:(NSString *)title
                                 message:(NSString *)message
                         cancelButtonText:(NSString *)cancelButtonText
                        confirmButtonText:(NSString *)confirmButtonText
                            cancelAction:(DYYYAlertActionHandler)cancelAction
                           confirmAction:(DYYYAlertActionHandler)confirmAction {
    
    AFDPrivacyHalfScreenViewController *vc = [NSClassFromString(@"AFDPrivacyHalfScreenViewController") new];
    
    if (!cancelButtonText) {
        cancelButtonText = @"取消";
    }
    
    if (!confirmButtonText) {
        confirmButtonText = @"确定";
    }
    
    DYYYAlertActionHandler wrappedCancelAction = ^{
        [self dismissAlertViewController:vc];
        if (cancelAction) {
            cancelAction();
        }
    };
    
    DYYYAlertActionHandler wrappedConfirmAction = ^{
        [self dismissAlertViewController:vc];
        if (confirmAction) {
            confirmAction();
        }
    };
    
    [vc setSlideDismissBlock:^{
        [self dismissAlertViewController:vc];
    }];
    
    [vc setTapDismissBlock:^{
        [self dismissAlertViewController:vc];
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

    UIViewController *topVC = topView(); 
    if (topVC) {
        if ([vc respondsToSelector:@selector(presentOnViewController:)]) {
            [vc presentOnViewController:topVC];
        }
    }
    return vc;
}

+ (void)dismissAlertViewController:(UIViewController *)viewController {
    if (!viewController) return;
    
    if ([NSThread isMainThread]) {
        [viewController dismissViewControllerAnimated:YES completion:nil];
    }
}

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