#import <UIKit/UIKit.h>

typedef void (^DYYYAlertActionHandler)(void);

@interface DYYYBottomAlertView : UIView

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                      cancelAction:(DYYYAlertActionHandler)cancelAction
                     confirmAction:(DYYYAlertActionHandler)confirmAction;
- (void)dismiss;

@end
