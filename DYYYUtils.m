#import "DYYYUtils.h"

@implementation DYYYUtils

+ (UIViewController *)topView {
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    return topViewController;
}

@end

UIViewController *topView(void) {
    return [DYYYUtils topView];
}