#import "DYYYCustomInputView.h"
#import "DYYYManager.h"

@implementation DYYYCustomInputView

- (instancetype)initWithTitle:(NSString *)title defaultText:(NSString *)defaultText placeholder:(NSString *)placeholder {
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
        self.defaultText = defaultText;
        self.placeholderText = placeholder;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        
        BOOL isDarkMode = [DYYYManager isDarkMode];
        
        self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight]];
        self.blurView.frame = self.bounds;
        self.blurView.alpha = isDarkMode ? 0.3 : 0.2;
        [self addSubview:self.blurView];
        
        // 创建内容视图 - 根据模式设置背景色
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 180)];
        CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
        self.contentView.center = CGPointMake(self.frame.size.width / 2, screenHeight / 3);
        self.originalFrame = self.contentView.frame;
        self.contentView.backgroundColor = isDarkMode ? [UIColor colorWithRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1.0] : [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [self addSubview:self.contentView];
        
        // 主标题 - 根据模式设置颜色
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 24)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = isDarkMode ? [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] : [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        [self.contentView addSubview:self.titleLabel];
        
        // 输入框 - 根据模式设置背景和文字颜色
        self.inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 64, 260, 40)];
        self.inputTextField.backgroundColor = isDarkMode ? [UIColor colorWithRed:45/255.0 green:45/255.0 blue:45/255.0 alpha:1.0] : [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0];
        self.inputTextField.textColor = isDarkMode ? [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] : [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
        
        // 使用自定义占位符文本，根据模式设置占位符颜色
        NSString *placeholderString = placeholder.length > 0 ? placeholder : @"请输入内容";
        UIColor *placeholderColor = isDarkMode ? [UIColor colorWithRed:160/255.0 green:160/255.0 blue:165/255.0 alpha:1.0] : [UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0];
        self.inputTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderString 
                                                                                    attributes:@{NSForegroundColorAttributeName: placeholderColor}];
        
        self.inputTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
        self.inputTextField.leftViewMode = UITextFieldViewModeAlways;
        self.inputTextField.layer.cornerRadius = 8;
        self.inputTextField.tintColor = [UIColor colorWithRed:11/255.0 green:223/255.0 blue:154/255.0 alpha:1.0]; // #0BDF9A 强调色保持不变
        self.inputTextField.delegate = self;
        self.inputTextField.returnKeyType = UIReturnKeyDone;
        self.inputTextField.keyboardAppearance = isDarkMode ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
        
        // 设置默认文本
        if (defaultText && defaultText.length > 0) {
            self.inputTextField.text = defaultText;
        }
        
        [self.contentView addSubview:self.inputTextField];
        
        // 添加内容和按钮之间的分割线，根据模式设置颜色
        UIView *contentButtonSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 124, 300, 0.5)];
        contentButtonSeparator.backgroundColor = isDarkMode ? [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] : [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [self.contentView addSubview:contentButtonSeparator];
        
        // 按钮容器
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 124.5, 300, 55.5)];
        [self.contentView addSubview:buttonContainer];
        
        // 取消按钮 - 根据模式设置颜色
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.cancelButton.frame = CGRectMake(0, 0, 149.5, 55.5);
        self.cancelButton.backgroundColor = [UIColor clearColor];
        [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        UIColor *cancelColor = isDarkMode ? [UIColor colorWithRed:160/255.0 green:160/255.0 blue:165/255.0 alpha:1.0] : [UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0];
        [self.cancelButton setTitleColor:cancelColor forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:self.cancelButton];
        
        // 按钮之间的分割线，根据模式设置颜色
        UIView *buttonSeparator = [[UIView alloc] initWithFrame:CGRectMake(149.5, 0, 0.5, 55.5)];
        buttonSeparator.backgroundColor = isDarkMode ? [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] : [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [buttonContainer addSubview:buttonSeparator];
        
        // 确认按钮 - 根据模式设置颜色
        self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.confirmButton.frame = CGRectMake(150, 0, 150, 55.5);
        self.confirmButton.backgroundColor = [UIColor clearColor];
        [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        UIColor *confirmColor = isDarkMode ? [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] : [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
        [self.confirmButton setTitleColor:confirmColor forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:self.confirmButton];
        
        // 注册键盘通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title defaultText:(NSString *)defaultText {
    return [self initWithTitle:title defaultText:defaultText placeholder:nil];
}

- (instancetype)initWithTitle:(NSString *)title {
    return [self initWithTitle:title defaultText:nil placeholder:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

// 键盘即将显示
- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat keyboardHeight = keyboardSize.height;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat screenHeight = screenBounds.size.height;

    CGFloat contentViewBottom = self.contentView.frame.origin.y + self.contentView.frame.size.height;
    CGFloat bottomDistance = screenHeight - contentViewBottom;
    
    if (bottomDistance < keyboardHeight + 20) {
        CGFloat offsetY = keyboardHeight + 20 - bottomDistance;
        
        [UIView animateWithDuration:0.12 animations:^{
            CGRect newFrame = self.contentView.frame;
            newFrame.origin.y -= offsetY;
            self.contentView.frame = newFrame;
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [UIView animateWithDuration:0.1 animations:^{
        self.contentView.frame = self.originalFrame;
    }];
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    [UIView animateWithDuration:0.12 animations:^{
        self.contentView.alpha = 1.0;
        self.contentView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self.inputTextField becomeFirstResponder];
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.1 animations:^{
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.blurView.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)confirmTapped {
    if (self.onConfirm) {
        self.onConfirm(self.inputTextField.text);
    }
    [self dismiss];
}

- (void)cancelTapped {
    if (self.onCancel) {
        self.onCancel();
    }
    [self dismiss];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self confirmTapped];
    return YES;
}

@end
