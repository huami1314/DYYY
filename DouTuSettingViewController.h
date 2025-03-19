#import <UIKit/UIViewController.h>

@class CContactMgr, NSString;

@interface DouTuSettingViewController : UIViewController
{
    id _tableViewManager;
    CContactMgr *_conontact;
    NSString *_version;
}

- (void)addfollowAouthorSection;
- (void)followAouthor;

@property(retain, nonatomic) CContactMgr *conontact; // @synthesize conontact=_conontact;

@end