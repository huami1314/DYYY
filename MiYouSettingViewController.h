#import <UIKit/UIViewController.h>

//#import <MiYou/UIImagePickerControllerDelegate-Protocol.h>
//#import <MiYou/UINavigationControllerDelegate-Protocol.h>

@class NSString;

@interface MiYouSettingViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
}

// 关注公众号或作者的功能
- (void)followAouthor;

@end