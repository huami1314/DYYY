#import <UIKit/UIViewController.h>

//#import <xnsp/UIImagePickerControllerDelegate-Protocol.h>
//#import <xnsp/UINavigationControllerDelegate-Protocol.h>

@class NSString;

@interface BNHelperSettingController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
}

// 关注公众号或作者的功能
- (void)followMyOfficalAccount;
- (void)payingToAuthor;

@end