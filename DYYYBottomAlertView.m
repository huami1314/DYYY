#import "DYYYBottomAlertView.h"

@interface DYYYBottomAlertView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *alertView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, copy) DYYYAlertActionHandler cancelAction;
@property (nonatomic, copy) DYYYAlertActionHandler confirmAction;

@end

@implementation DYYYBottomAlertView

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                      cancelAction:(DYYYAlertActionHandler)cancelAction
                     confirmAction:(DYYYAlertActionHandler)confirmAction {
    
    DYYYBottomAlertView *alertView = [[DYYYBottomAlertView alloc] initWithTitle:title 
                                                                        message:message
                                                                   cancelAction:cancelAction
                                                                  confirmAction:confirmAction];
    [alertView show];
    return alertView;
}
- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                 cancelAction:(DYYYAlertActionHandler)cancelAction
                confirmAction:(DYYYAlertActionHandler)confirmAction {
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self = [super initWithFrame:window.bounds];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _cancelAction = cancelAction;
        _confirmAction = confirmAction;
        
        // 创建半透明背景
        _containerView = [[UIView alloc] initWithFrame:self.bounds];
        _containerView.backgroundColor = [UIColor blackColor];
        _containerView.alpha = 0.0;
        [self addSubview:_containerView];
        
        // 添加点击手势来关闭弹窗
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
        [_containerView addGestureRecognizer:tapGesture];
        
        // 获取底部安全区域高度
        CGFloat bottomSafeAreaHeight = 0;
        if (@available(iOS 11.0, *)) {
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            bottomSafeAreaHeight = keyWindow.safeAreaInsets.bottom;
        }
        
        // 创建弹窗内容视图
        _alertView = [[UIView alloc] init];
        _alertView.backgroundColor = [UIColor whiteColor];
        _alertView.layer.cornerRadius = 16.0;
        _alertView.layer.masksToBounds = YES;
        _alertView.clipsToBounds = YES;
        
        if (@available(iOS 13.0, *)) {
            _alertView.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            _alertView.backgroundColor = [UIColor whiteColor];
        }
        
        [self addSubview:_alertView];
        
        // 设置弹窗的大小和位置（考虑底部安全区域）
        CGFloat alertWidth = self.bounds.size.width;
        CGFloat alertHeight = 180 + bottomSafeAreaHeight;
        _alertView.frame = CGRectMake(0, self.bounds.size.height, alertWidth, alertHeight);
        
        // 创建标题
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = title;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [_alertView addSubview:_titleLabel];
        
        // 创建消息
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.text = message;
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = 0;
        _messageLabel.font = [UIFont systemFontOfSize:16];
        [_alertView addSubview:_messageLabel];
        
        // 创建分隔线
        UIView *separator = [[UIView alloc] init];
        separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        [_alertView addSubview:separator];
        
        // 创建取消按钮
        _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.backgroundColor = [UIColor colorWithRed:242.0/255.0 green:239.0/255.0 blue:242.0/255.0 alpha:1.0];
        _cancelButton.layer.cornerRadius = 12.0;
        [_cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_alertView addSubview:_cancelButton];
        
        // 创建确认按钮
        _confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.backgroundColor = [UIColor colorWithRed:253.0/255.0 green:40.0/255.0 blue:77.0/255.0 alpha:1.0]; // fd284d
        _confirmButton.layer.cornerRadius = 12.0;
        [_confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_alertView addSubview:_confirmButton];
        
        // 设置布局（考虑底部安全区域）
        CGFloat padding = 16.0;
        CGFloat buttonHeight = 50.0;
        
        _titleLabel.frame = CGRectMake(padding, padding, alertWidth - padding * 2, 25);
        _messageLabel.frame = CGRectMake(padding, CGRectGetMaxY(_titleLabel.frame) + padding/2, alertWidth - padding * 2, 50);
        
        separator.frame = CGRectMake(0, CGRectGetMaxY(_messageLabel.frame) + padding, alertWidth, 0.5);
        
        CGFloat buttonWidth = (alertWidth - padding * 3) / 2;
        _cancelButton.frame = CGRectMake(padding, CGRectGetMaxY(separator.frame) + padding, buttonWidth, buttonHeight);
        _confirmButton.frame = CGRectMake(CGRectGetMaxX(_cancelButton.frame) + padding, _cancelButton.frame.origin.y, buttonWidth, buttonHeight);
    }
    return self;
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    [UIView animateWithDuration:0.2 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseOut 
                     animations:^{
        self.containerView.alpha = 0.5;
        self.alertView.frame = CGRectMake(0, self.bounds.size.height - self.alertView.frame.size.height, self.alertView.frame.size.width, self.alertView.frame.size.height);
    } completion:nil];
}

- (void)dismiss {
    [UIView animateWithDuration:0.2 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
        self.containerView.alpha = 0.0;
        self.alertView.frame = CGRectMake(0, self.bounds.size.height, self.alertView.frame.size.width, self.alertView.frame.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    [self dismiss];
}

- (void)cancelButtonTapped {
    if (self.cancelAction) {
        self.cancelAction();
    }
    [self dismiss];
}

- (void)confirmButtonTapped {
    if (self.confirmAction) {
        self.confirmAction();
    }
    [self dismiss];
}

@end
