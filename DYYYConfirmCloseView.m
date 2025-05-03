#import <UIKit/UIKit.h>
#import "DYYYManager.h"

// 自定义确认关闭弹窗类
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

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;
- (void)show;
- (void)dismiss;
@end

@implementation DYYYConfirmCloseView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message {
    self = [super initWithFrame:UIScreen.mainScreen.bounds];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        
        // 创建模糊效果
        BOOL isDarkMode = [DYYYManager isDarkMode];
        
        self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight]];
        self.blurView.frame = self.bounds;
        self.blurView.alpha = isDarkMode ? 0.3 : 0.2;
        [self addSubview:self.blurView];
        
        // 内容容器 - 根据模式设置背景色
        CGFloat contentWidth = MIN(300, self.bounds.size.width - 40);
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentWidth, 200)];
        CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
        self.contentView.center = CGPointMake(self.frame.size.width / 2, screenHeight / 2);
        self.contentView.backgroundColor = isDarkMode ? 
            [UIColor colorWithRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1.0] : 
            [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.masksToBounds = YES;
        [self addSubview:self.contentView];
        
        // 标题 - 根据模式设置颜色
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, contentWidth - 40, 30)];
        self.titleLabel.text = title;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.textColor = isDarkMode ? 
            [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] : 
            [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        [self.contentView addSubview:self.titleLabel];
        
        // 消息 - 根据模式设置颜色
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, contentWidth - 40, 60)];
        self.messageLabel.text = message;
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.textColor = isDarkMode ? 
            [UIColor colorWithRed:180/255.0 green:180/255.0 blue:185/255.0 alpha:1.0] : 
            [UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0];
        self.messageLabel.font = [UIFont systemFontOfSize:15];
        self.messageLabel.numberOfLines = 0;
        [self.contentView addSubview:self.messageLabel];
        
        // 倒计时标签 - 强调色保持不变
        self.countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, contentWidth - 40, 30)];
        self.countdownLabel.textAlignment = NSTextAlignmentCenter;
        self.countdownLabel.textColor = [UIColor colorWithRed:11/255.0 green:223/255.0 blue:154/255.0 alpha:1.0]; // #0BDF9A
        self.countdownLabel.font = [UIFont boldSystemFontOfSize:16];
        self.countdown = 5;
        self.countdownLabel.text = [NSString stringWithFormat:@"%ld 秒后自动关闭", (long)self.countdown];
        [self.contentView addSubview:self.countdownLabel];
        
        // 添加内容和按钮之间的分割线 - 根据模式设置颜色
        UIView *contentButtonSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 160, contentWidth, 0.5)];
        contentButtonSeparator.backgroundColor = isDarkMode ? 
            [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] : 
            [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [self.contentView addSubview:contentButtonSeparator];
        
        // 按钮容器
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 160.5, contentWidth, 55.5)];
        [self.contentView addSubview:buttonContainer];
        
        // 取消按钮 - 根据模式设置颜色
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.cancelButton.frame = CGRectMake(0, 0, contentWidth/2 - 0.5, 55.5);
        self.cancelButton.backgroundColor = [UIColor clearColor];
        [self.cancelButton setTitle:@"取消关闭" forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:isDarkMode ? 
            [UIColor colorWithRed:160/255.0 green:160/255.0 blue:165/255.0 alpha:1.0] : 
            [UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0] 
            forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:self.cancelButton];
        
        // 按钮之间的分割线 - 根据模式设置颜色
        UIView *buttonSeparator = [[UIView alloc] initWithFrame:CGRectMake(contentWidth/2 - 0.25, 0, 0.5, 55.5)];
        buttonSeparator.backgroundColor = isDarkMode ? 
            [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] : 
            [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [buttonContainer addSubview:buttonSeparator];
        
        // 确认按钮 - 根据模式设置颜色
        self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.confirmButton.frame = CGRectMake(contentWidth/2, 0, contentWidth/2, 55.5);
        self.confirmButton.backgroundColor = [UIColor clearColor];
        [self.confirmButton setTitle:@"关闭抖音" forState:UIControlStateNormal];
        [self.confirmButton setTitleColor:isDarkMode ? 
            [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] : 
            [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0] 
            forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:self.confirmButton];
        
        // 调整内容视图高度
        CGRect frame = self.contentView.frame;
        frame.size.height = 216; // 更新高度以适应新布局
        self.contentView.frame = frame;
        
        // 初始状态
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    }
    return self;
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    [UIView animateWithDuration:0.12 animations:^{
        self.alpha = 1;
        self.contentView.alpha = 1.0;
        self.contentView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        // 开始倒计时
        self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                              target:self
                                                            selector:@selector(updateCountdown)
                                                            userInfo:nil
                                                             repeats:YES];
    }];
}

- (void)updateCountdown {
    self.countdown--;
    self.countdownLabel.text = [NSString stringWithFormat:@"%ld 秒后自动关闭", (long)self.countdown];
    
    if (self.countdown <= 0) {
        [self.countdownTimer invalidate];
        [self confirmTapped];
    }
}

- (void)dismiss {
    [self.countdownTimer invalidate];
    
    [UIView animateWithDuration:0.1 animations:^{
        self.alpha = 0;
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)cancelTapped {
    [self dismiss];
}

- (void)confirmTapped {
    [self dismiss];
    // 延迟执行关闭
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

@end
