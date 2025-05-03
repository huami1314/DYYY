#import "DYYYAboutDialogView.h"
#import "DYYYManager.h"

@implementation DYYYAboutDialogView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message {
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        
        // 判断当前深色/浅色模式
        BOOL isDarkMode = [DYYYManager isDarkMode];
        
        // 创建模糊效果视图 - 根据模式调整效果样式
        self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight]];
        self.blurView.frame = self.bounds;
        self.blurView.alpha = isDarkMode ? 0.3 : 0.2;
        [self addSubview:self.blurView];
        
        // 计算文本高度，动态调整弹窗高度
        UIFont *messageFont = [UIFont systemFontOfSize:14];
        CGSize constraintSize = CGSizeMake(260, CGFLOAT_MAX);
        NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:message attributes:@{NSFontAttributeName: messageFont}];
        CGRect textRect = [attributedMessage boundingRectWithSize:constraintSize 
                                                         options:NSStringDrawingUsesLineFragmentOrigin 
                                                         context:nil];
        
        CGFloat textHeight = textRect.size.height;
        CGFloat maxTextHeight = 280; 
        CGFloat titleHeight = 44; 
        CGFloat buttonHeight = 58; 
        CGFloat buttonPadding = 18;
        CGFloat actualTextHeight = MIN(textHeight, maxTextHeight);
        CGFloat contentHeight = titleHeight + actualTextHeight + buttonHeight + buttonPadding;
        BOOL needsScrolling = textHeight > maxTextHeight;
        
        // 创建内容视图 - 根据模式选择背景色
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, contentHeight)];
        self.contentView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        self.contentView.backgroundColor = isDarkMode ? [UIColor colorWithRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1.0] : [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [self addSubview:self.contentView];
        
        // 标题 - 根据模式调整文本颜色
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 24)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = isDarkMode ? [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] : [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        [self.contentView addSubview:self.titleLabel];
        
        // 消息内容 - 适配深色模式
        self.messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, 54, 260, actualTextHeight)];
        self.messageTextView.backgroundColor = [UIColor clearColor];
        self.messageTextView.textAlignment = NSTextAlignmentCenter;
        self.messageTextView.font = messageFont;
        self.messageTextView.editable = NO;
        self.messageTextView.scrollEnabled = needsScrolling;
        self.messageTextView.showsVerticalScrollIndicator = needsScrolling;
        self.messageTextView.dataDetectorTypes = UIDataDetectorTypeLink;
        self.messageTextView.transform = CGAffineTransformMakeScale(1.05, 1.05);
        self.messageTextView.selectable = YES;
        
        // 创建段落样式并设置居中对齐
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:message];
        [attributedString addAttribute:NSParagraphStyleAttributeName 
                                 value:paragraphStyle 
                                 range:NSMakeRange(0, message.length)];
        
        // 根据模式设置整体文本颜色
        UIColor *messageTextColor = isDarkMode ? [UIColor colorWithRed:180/255.0 green:180/255.0 blue:185/255.0 alpha:1.0] : [UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0];
        [attributedString addAttribute:NSForegroundColorAttributeName 
                                 value:messageTextColor
                                 range:NSMakeRange(0, message.length)];
                                 
        // 保持链接设置
        NSRange telegramRange = [message rangeOfString:@"Telegram @vita_app"];
        if (telegramRange.location != NSNotFound) {
            [attributedString addAttribute:NSLinkAttributeName 
                                     value:@"https://t.me/vita_app" 
                                     range:telegramRange];
        }
        
        NSRange githubRange = [message rangeOfString:@"仓库地址 Wtrwx/DYYY"];
        if (githubRange.location != NSNotFound) {
            [attributedString addAttribute:NSLinkAttributeName 
                                     value:@"https://github.com/Wtrwx/DYYY" 
                                     range:githubRange];
        }

        NSRange huamiGithubRange = [message rangeOfString:@"开源地址 huami1314/DYYY"];
        if (huamiGithubRange.location != NSNotFound) {
            [attributedString addAttribute:NSLinkAttributeName 
                                     value:@"https://github.com/huami1314/DYYY" 
                                     range:huamiGithubRange];
        }
        NSRange huamiTGGroup = [message rangeOfString:@"Telegram @huamidev"];
        if (huamiTGGroup.location != NSNotFound) {
            [attributedString addAttribute:NSLinkAttributeName 
                                     value:@"https://t.me/huamidev" 
                                     range:huamiTGGroup];
        }
        self.messageTextView.attributedText = attributedString;
        
        // 设置链接颜色
        self.messageTextView.linkTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:11/255.0 green:223/255.0 blue:154/255.0 alpha:1.0], // #0BDF9A 链接颜色保持不变
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
        };
        
        [self.contentView addSubview:self.messageTextView];
        
        // 添加内容和按钮之间的分割线，调整位置和颜色
        UIView *contentButtonSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, contentHeight - buttonHeight, 300, 0.5)];
        contentButtonSeparator.backgroundColor = isDarkMode ? [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] : [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [self.contentView addSubview:contentButtonSeparator];
        
        // 确认按钮 - 根据模式调整颜色
        self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.confirmButton.frame = CGRectMake(0, contentHeight - buttonHeight + 0.5, 300, 53); 
        self.confirmButton.backgroundColor = [UIColor clearColor];
        [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        UIColor *confirmButtonColor = isDarkMode ? [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] : [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
        [self.confirmButton setTitleColor:confirmButtonColor forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.confirmButton];
        
        self.messageTextView.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    [UIView animateWithDuration:0.12 animations:^{
        self.contentView.alpha = 1.0;
        self.contentView.transform = CGAffineTransformIdentity;
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
        self.onConfirm();
    }
    [self dismiss];
}

@end
