#import <UIKit/UIKit.h>

typedef void (^DYYYAlertActionHandler)(void);

@interface DYYYBottomAlertView : UIView

+ (UIViewController *)showAlertWithTitle:(NSString *)title
                                 message:(NSString *)message
                            cancelAction:(DYYYAlertActionHandler)cancelAction
                           confirmAction:(DYYYAlertActionHandler)confirmAction;
- (void)dismiss;

@end