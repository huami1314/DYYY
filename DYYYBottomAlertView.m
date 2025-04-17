#import "DYYYBottomAlertView.h"
#import "AwemeHeaders.h"

@implementation DYYYBottomAlertView

+ (UIViewController *)showAlertWithTitle:(NSString *)title
                                 message:(NSString *)message
                            cancelAction:(DYYYAlertActionHandler)cancelAction
                           confirmAction:(DYYYAlertActionHandler)confirmAction {
    
    AFDPrivacyHalfScreenViewController *vc = [NSClassFromString(@"AFDPrivacyHalfScreenViewController") new];
    
    [vc configWithImageView:nil 
                  lockImage:nil 
           defaultLockState:NO 
            titleLabelText:title 
          contentLabelText:message 
      leftCancelButtonText:@"取消" 
    rightConfirmButtonText:@"确定" 
       rightBtnClickedBlock:nil 
      leftButtonClickedBlock:nil];
    
    // 设置点击事件
    vc.rightBtnClickedBlock = confirmAction;
    vc.leftButtonClickedBlock = cancelAction;
    
    // 设置圆角
    [vc setCornerRadius:16.0];
    [vc setOnlyTopCornerClips:YES];
    
    // 使用 keyWindow 直接添加视图，而不是模态呈现
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [vc.view setFrame:window.bounds];
    [window addSubview:vc.view];
    
    // 将视图控制器作为子视图控制器添加到根视图控制器
    UIViewController *rootVC = window.rootViewController;
    [rootVC addChildViewController:vc];
    [vc didMoveToParentViewController:rootVC];
    
    return vc;
}

// 修改 dismiss 方法的实现以适应新的显示方式
- (void)dismiss {
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)responder;
            [vc willMoveToParentViewController:nil];
            [vc.view removeFromSuperview];
            [vc removeFromParentViewController];
            break;
        }
    }
}

@end