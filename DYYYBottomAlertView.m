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
    
    if (!vc) return nil;

    if (!cancelButtonText) {
        cancelButtonText = @"取消";
    }
    
    if (!confirmButtonText) {
        confirmButtonText = @"确定";
    }
    
    __weak typeof(vc) weakVC = vc;

    DYYYAlertActionHandler wrappedCancelAction = ^{
        if (cancelAction) cancelAction();
        if (weakVC) [self dismissAlertViewController:weakVC];
    };
    
    vc.closeButtonClickedBlock = ^{
        if (cancelAction) cancelAction();
    };

    vc.slideDismissBlock = ^{
        if (cancelAction) cancelAction();
    };
    
    vc.tapDismissBlock = ^{
        if (cancelAction) cancelAction();
    };
    
    DYYYAlertActionHandler wrappedConfirmAction = ^{
        if (confirmAction) confirmAction();
        if (weakVC) [self dismissAlertViewController:weakVC];
    };
    
    [vc configWithImageView:nil 
                  lockImage:nil 
           defaultLockState:NO 
            titleLabelText:title 
          contentLabelText:message 
      leftCancelButtonText:cancelButtonText 
    rightConfirmButtonText:confirmButtonText 
       rightBtnClickedBlock:wrappedConfirmAction
      leftButtonClickedBlock:wrappedCancelAction];
    
    [vc setUseCardUIStyle:YES];

    UIViewController *topVC = topView(); 
    if (topVC
        && [vc respondsToSelector:@selector(presentOnViewController:)]
	    && !topVC.presentedViewController
	    && ![topVC isBeingPresented]
	    && ![topVC isBeingDismissed]) {
            [vc presentOnViewController:topVC];
    } else {
        return nil; 
    }
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

+ (UIViewController *)showAlertWithTitle:(NSString *)title
                                 message:(NSString *)message
                               avatarURL:(NSString *)avatarURL
                            cancelAction:(DYYYAlertActionHandler)cancelAction
                           confirmAction:(DYYYAlertActionHandler)confirmAction {
    return [self showAlertWithTitle:title
                            message:message
                          avatarURL:avatarURL
                    cancelButtonText:@"取消"
                   confirmButtonText:@"确定"
                        cancelAction:cancelAction
                       confirmAction:confirmAction];
}

+ (UIViewController *)showAlertWithTitle:(NSString *)title
                                 message:(NSString *)message
                               avatarURL:(NSString *)avatarURL
                         cancelButtonText:(NSString *)cancelButtonText
                        confirmButtonText:(NSString *)confirmButtonText
                            cancelAction:(DYYYAlertActionHandler)cancelAction
                           confirmAction:(DYYYAlertActionHandler)confirmAction {
    
    AFDPrivacyHalfScreenViewController *vc = [NSClassFromString(@"AFDPrivacyHalfScreenViewController") new];
    
    if (!vc) return nil;

    if (!cancelButtonText) {
        cancelButtonText = @"取消";
    }
    
    if (!confirmButtonText) {
        confirmButtonText = @"确定";
    }
    
    UIImageView *imageView = nil;
    if (avatarURL.length > 0) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [imageView.widthAnchor constraintEqualToConstant:60].active = YES;
        [imageView.heightAnchor constraintEqualToConstant:60].active = YES;
        imageView.layer.cornerRadius = 30;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.masksToBounds = YES;
        imageView.clipsToBounds = YES;
        
        // 设置默认占位图
        imageView.image = [UIImage imageNamed:@"AppIcon60x60"];
        
        // 异步加载网络图片
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:avatarURL]];
            if (imageData) {
                UIImage *image = [UIImage imageWithData:imageData];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        imageView.image = image;
                    });
                }
            }
        });
    }
    
    __weak typeof(vc) weakVC = vc;

    DYYYAlertActionHandler wrappedCancelAction = ^{
        if (cancelAction) cancelAction();
        if (weakVC) [self dismissAlertViewController:weakVC];
    };
    
    vc.closeButtonClickedBlock = ^{
        if (cancelAction) cancelAction();
    };

    vc.slideDismissBlock = ^{
        if (cancelAction) cancelAction();
    };
    
    vc.tapDismissBlock = ^{
        if (cancelAction) cancelAction();
    };
    
    DYYYAlertActionHandler wrappedConfirmAction = ^{
        if (confirmAction) confirmAction();
        if (weakVC) [self dismissAlertViewController:weakVC];
    };
    
    [vc configWithImageView:imageView
                  lockImage:nil
           defaultLockState:NO
            titleLabelText:title
          contentLabelText:message
      leftCancelButtonText:cancelButtonText
    rightConfirmButtonText:confirmButtonText
       rightBtnClickedBlock:wrappedConfirmAction
      leftButtonClickedBlock:wrappedCancelAction];
    
    [vc setCornerRadius:11];
    [vc setOnlyTopCornerClips:YES];
    
    UIViewController *topVC = topView();
    if (topVC
        && [vc respondsToSelector:@selector(presentOnViewController:)]
	    && !topVC.presentedViewController
	    && ![topVC isBeingPresented]
	    && ![topVC isBeingDismissed]) {
            [vc presentOnViewController:topVC];
    } else {
        return nil; 
    }
    
    return vc;
}

+ (void)dismissAlertViewController:(UIViewController *)viewController {
    if (!viewController || !viewController.presentingViewController) {
        return;
    }
    if ([NSThread isMainThread]) {
        [viewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [viewController dismissViewControllerAnimated:YES completion:nil];
        });
    }
}
@end