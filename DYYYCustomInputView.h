#import <UIKit/UIKit.h>
#import "DYYYManager.h"

// 自定义文本输入视图
@interface DYYYCustomInputView : UIView <UITextFieldDelegate>
@property(nonatomic, strong) UIVisualEffectView *blurView;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UITextField *inputTextField;
@property(nonatomic, strong) UIButton *confirmButton;
@property(nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, copy) void (^onConfirm)(NSString *text);
@property(nonatomic, copy) void (^onCancel)(void);
@property(nonatomic, assign) CGRect originalFrame;
@property(nonatomic, copy) NSString *defaultText;
@property(nonatomic, copy) NSString *placeholderText;

- (instancetype)initWithTitle:(NSString *)title defaultText:(NSString *)defaultText;
- (instancetype)initWithTitle:(NSString *)title defaultText:(NSString *)defaultText placeholder:(NSString *)placeholder;
- (instancetype)initWithTitle:(NSString *)title;
- (void)show;
- (void)dismiss;
@end
