#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 自定义确认关闭弹窗类
 * 用于显示一个带倒计时的确认关闭弹窗
 */
@interface DYYYConfirmCloseView : UIView

@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, assign) NSInteger countdown;
@property (nonatomic, strong) NSTimer *countdownTimer;

/**
 * 初始化确认关闭弹窗
 * @param title 弹窗标题
 * @param message 弹窗消息内容
 * @return 确认关闭弹窗实例
 */
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;

/**
 * 显示弹窗
 */
- (void)show;

/**
 * 关闭弹窗
 */
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
