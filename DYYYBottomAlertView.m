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
    
    [vc configWithImageView:nil 
                  lockImage:nil 
           defaultLockState:NO 
            titleLabelText:title 
          contentLabelText:message 
      leftCancelButtonText:cancelButtonText 
    rightConfirmButtonText:confirmButtonText 
       rightBtnClickedBlock:confirmAction  // 直接传入回调，而不是nil
      leftButtonClickedBlock:cancelAction];  // 直接传入回调，而不是nil
    
    // 设置圆角
    [vc setCornerRadius:16.0];
    [vc setOnlyTopCornerClips:YES];
    
    [vc setUseCardUIStyle:YES];

    UIViewController *topVC = topView();
    [topVC presentViewController:vc animated:NO completion:nil];
    
    return vc;
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
