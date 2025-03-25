#import <UIKit/UIKit.h>

typedef void (^DYYYActionHandler)(void);

@interface DYYYActionItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) DYYYActionHandler handler;
+ (instancetype)itemWithTitle:(NSString *)title handler:(DYYYActionHandler)handler;
@end

@interface DYYYActionSheetView : UIView
+ (instancetype)showWithTitle:(NSString *)title items:(NSArray<DYYYActionItem *> *)items;
- (void)dismiss;
@end
