#import "DYYYCustomInputView.h"

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
        
        // 创建内容视图 - 改为纯白背景
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 180)];
        CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
        self.contentView.center = CGPointMake(self.frame.size.width / 2, screenHeight / 3);
        self.originalFrame = self.contentView.frame;
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [self addSubview:self.contentView];
        
        // 主标题 - 颜色改为 #2d2f38
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 24)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0]; // #2d2f38
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        [self.contentView addSubview:self.titleLabel];
        
        // 输入框 - 背景和文字颜色修改，设置光标颜色为 #0BDF9A
        self.inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 64, 260, 40)];
        self.inputTextField.backgroundColor = [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0];
        self.inputTextField.textColor = [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0]; // #2d2f38
        
        // 使用自定义占位符文本
        NSString *placeholderString = placeholder.length > 0 ? placeholder : @"请输入内容";
        self.inputTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderString 
                                                                                    attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0]}]; // #7c7c82
        
        self.inputTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
        self.inputTextField.leftViewMode = UITextFieldViewModeAlways;
        self.inputTextField.layer.cornerRadius = 8;
        self.inputTextField.tintColor = [UIColor colorWithRed:11/255.0 green:223/255.0 blue:154/255.0 alpha:1.0]; // #0BDF9A
        self.inputTextField.delegate = self;
        self.inputTextField.returnKeyType = UIReturnKeyDone;
        
        // 设置默认文本
        if (defaultText && defaultText.length > 0) {
            self.inputTextField.text = defaultText;
        }
        
        [self.contentView addSubview:self.inputTextField];
        
        // 添加内容和按钮之间的分割线
        UIView *contentButtonSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 124, 300, 0.5)];
        contentButtonSeparator.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [self.contentView addSubview:contentButtonSeparator];
        
        // 按钮容器
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 124.5, 300, 55.5)];
        [self.contentView addSubview:buttonContainer];
        
        // 取消按钮 - 颜色为 #7c7c82
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.cancelButton.frame = CGRectMake(0, 0, 149.5, 55.5);
        self.cancelButton.backgroundColor = [UIColor clearColor];
        [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0] forState:UIControlStateNormal];  // #7c7c82
        [self.cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:self.cancelButton];
        
        // 按钮之间的分割线
        UIView *buttonSeparator = [[UIView alloc] initWithFrame:CGRectMake(149.5, 0, 0.5, 55.5)];
        buttonSeparator.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [buttonContainer addSubview:buttonSeparator];
        
        // 确认按钮 - 颜色为 #2d2f38
        self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.confirmButton.frame = CGRectMake(150, 0, 150, 55.5);
        self.confirmButton.backgroundColor = [UIColor clearColor];
        [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [self.confirmButton setTitleColor:[UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0] forState:UIControlStateNormal];  // #2d2f38
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
