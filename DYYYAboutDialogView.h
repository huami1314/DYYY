#import <UIKit/UIKit.h>

// 自定义关于弹窗类
@interface DYYYAboutDialogView : UIView
@property(nonatomic, strong) UIVisualEffectView *blurView;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UITextView *messageTextView;
@property(nonatomic, strong) UIButton *confirmButton;
@property(nonatomic, copy) void (^onConfirm)(void);

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;
- (void)show;
- (void)dismiss;
- (void)confirmTapped;
@end
