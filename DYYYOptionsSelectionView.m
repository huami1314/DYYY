#import "DYYYOptionsSelectionView.h"

@implementation DYYYOptionsSelectionView

- (instancetype)initWithTitle:(NSString *)title options:(NSArray<NSString *> *)options {
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
        self.options = options;
        self.optionButtons = [NSMutableArray array];
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        
        // 创建模糊效果视图
        self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        self.blurView.frame = self.bounds;
        self.blurView.alpha = 0.2;
        [self addSubview:self.blurView];

        CGFloat titleHeight = 60;
        CGFloat optionHeight = 50;
        CGFloat separatorHeight = 0.5;
        CGFloat bottomPadding = 0; 
        CGFloat contentHeight = titleHeight + (options.count * optionHeight) + (options.count * separatorHeight) + optionHeight + separatorHeight + bottomPadding;
        
        // 内容视图 - 纯白背景
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, contentHeight)];
        self.contentView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [self addSubview:self.contentView];
        
        // 标题 - 颜色为 #2d2f38
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 30)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0]; // #2d2f38
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        [self.contentView addSubview:self.titleLabel];
        
        // 添加标题和选项之间的分割线
        UIView *titleSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, titleHeight, 300, separatorHeight)];
        titleSeparator.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [self.contentView addSubview:titleSeparator];
        
        // 选项按钮 - 确保垂直排列且不重叠
        CGFloat currentY = titleHeight + separatorHeight;
        for (NSInteger i = 0; i < options.count; i++) {
            UIButton *optionButton = [UIButton buttonWithType:UIButtonTypeSystem];
            optionButton.frame = CGRectMake(0, currentY, 300, optionHeight);
            optionButton.backgroundColor = [UIColor clearColor];
            [optionButton setTitle:options[i] forState:UIControlStateNormal];
            [optionButton setTitleColor:[UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0] forState:UIControlStateNormal]; // #2d2f38
            optionButton.tag = i;
            [optionButton addTarget:self action:@selector(optionTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:optionButton];
            [self.optionButtons addObject:optionButton];
            
            currentY += optionHeight;
            
            // 添加选项之间的分割线
            if (i < options.count - 1) {
                UIView *optionSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, currentY, 300, separatorHeight)];
                optionSeparator.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
                [self.contentView addSubview:optionSeparator];
                currentY += separatorHeight;
            }
        }
        
        // 添加选项和取消按钮之间的分割线
        UIView *cancelSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, currentY, 300, separatorHeight)];
        cancelSeparator.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [self.contentView addSubview:cancelSeparator];
        currentY += separatorHeight;
        
        // 取消按钮 - 颜色为 #7c7c82
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.cancelButton.frame = CGRectMake(0, currentY, 300, optionHeight);
        self.cancelButton.backgroundColor = [UIColor clearColor];
        [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0] forState:UIControlStateNormal]; // #7c7c82
        [self.cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.cancelButton];
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

- (void)optionTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (self.onSelect && index < self.options.count) {
        self.onSelect(index, self.options[index]);
    }
    [self dismiss];
}

- (void)cancelTapped {
    [self dismiss];
}

@end
