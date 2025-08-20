#import "DYYYFilterSettingsView.h"
#import "DYYYUtils.h"

static inline UIColor *DYYYAccentColor(void) {
    return [UIColor colorWithRed:11 / 255.0 green:223 / 255.0 blue:154 / 255.0 alpha:1.0];
}

static inline UIColor *DYYYRedColor(void) {
    return [UIColor colorWithRed:1.0 green:59 / 255.0 blue:48 / 255.0 alpha:1.0];
}

static inline UIColor *DYYYColor(UIColor *darkColor, UIColor *lightColor, BOOL darkMode) {
    return darkMode ? darkColor : lightColor;
}

static const CGFloat kDYYYButtonSize = 25.0;
static const CGFloat kDYYYButtonMargin = 1.0;
static const int kDYYYButtonsPerRow = 10;

@interface DYYYFilterSettingsView ()

@property(nonatomic, strong) UIVisualEffectView *blurView;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIScrollView *charactersScrollView;
@property(nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, strong) UIButton *confirmButton;
@property(nonatomic, strong) UIButton *keywordFilterButton;
@property(nonatomic, strong) UIButton *propFilterButton;
@property(nonatomic, copy) NSString *propName;
@property(nonatomic, strong) UILabel *selectionPreviewLabel;
@property(nonatomic, assign) CGRect originalFrame;
@property(nonatomic, strong) NSString *text;
@property(nonatomic, strong) NSMutableArray<UIButton *> *characterButtons;
@property(nonatomic, assign) NSInteger startIndex;
@property(nonatomic, assign) NSInteger endIndex;
@property(nonatomic, strong) NSMutableString *selectedText;
@property(nonatomic, assign) BOOL isSelecting;
@property(nonatomic, assign) BOOL isDragging;
@property(nonatomic, assign) NSInteger touchDownIndex;
@property(nonatomic, assign) BOOL darkMode;
@property(nonatomic, assign) NSRange selectedRange;

@end

@implementation DYYYFilterSettingsView

- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text propName:(NSString *)propName {
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
        _propName = [propName copy];
        _text = text ?: @"";
        _selectedText = [NSMutableString string];
        _characterButtons = [NSMutableArray array];
        _startIndex = -1;
        _endIndex = -1;
        _isSelecting = NO;
        _isDragging = NO;
        _touchDownIndex = -1;
        _selectedRange = NSMakeRange(NSNotFound, 0);

        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];

        self.darkMode = [DYYYUtils isDarkMode];

        // 创建模糊背景视图
        self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:self.darkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight]];
        self.blurView.frame = self.bounds;
        self.blurView.alpha = self.darkMode ? 0.3 : 0.2;
        [self addSubview:self.blurView];

        // 创建内容视图 - 根据模式设置背景色
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
        CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
        self.contentView.center = CGPointMake(self.frame.size.width / 2, screenHeight / 3);
        self.contentView.backgroundColor = DYYYColor([UIColor colorWithRed:30 / 255.0 green:30 / 255.0 blue:30 / 255.0 alpha:1.0], [UIColor whiteColor], self.darkMode);
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [self addSubview:self.contentView];

        // 主标题 - 根据模式设置文本颜色
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 24)];
        self.titleLabel.text = title ?: @"推荐过滤设置";
        self.titleLabel.textColor =
            DYYYColor([UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:235 / 255.0 alpha:1.0], [UIColor colorWithRed:45 / 255.0 green:47 / 255.0 blue:56 / 255.0 alpha:1.0], self.darkMode);
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        [self.contentView addSubview:self.titleLabel];

        // 添加过滤关键词按钮 - 保持强调色不变
        self.keywordFilterButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.keywordFilterButton.frame = CGRectMake(240, 20, 40, 24);
        [self.keywordFilterButton setImage:[UIImage systemImageNamed:@"line.3.horizontal.decrease.circle"] forState:UIControlStateNormal];
        self.keywordFilterButton.tintColor = DYYYAccentColor();
        [self.keywordFilterButton addTarget:self action:@selector(keywordFilterTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.keywordFilterButton];

        // 选中预览区域 - 根据模式设置背景色
        self.selectionPreviewLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 54, 260, 50)];
        self.selectionPreviewLabel.text = @"请滑动选择文字";
        self.selectionPreviewLabel.textColor = DYYYAccentColor();
        self.selectionPreviewLabel.textAlignment = NSTextAlignmentCenter;
        self.selectionPreviewLabel.numberOfLines = 2;
        self.selectionPreviewLabel.font = [UIFont systemFontOfSize:16];
        self.selectionPreviewLabel.backgroundColor =
            DYYYColor([UIColor colorWithRed:45 / 255.0 green:45 / 255.0 blue:45 / 255.0 alpha:1.0], [UIColor colorWithRed:245 / 255.0 green:245 / 255.0 blue:245 / 255.0 alpha:1.0], self.darkMode);
        self.selectionPreviewLabel.layer.cornerRadius = 8;
        self.selectionPreviewLabel.layer.masksToBounds = YES;
        [self.contentView addSubview:self.selectionPreviewLabel];

        // 字符滚动视图 - 根据模式设置背景色
        self.charactersScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 114, 260, 220)];
        self.charactersScrollView.backgroundColor =
            DYYYColor([UIColor colorWithRed:45 / 255.0 green:45 / 255.0 blue:45 / 255.0 alpha:1.0], [UIColor colorWithRed:245 / 255.0 green:245 / 255.0 blue:245 / 255.0 alpha:1.0], self.darkMode);
        self.charactersScrollView.layer.cornerRadius = 8;
        self.charactersScrollView.bounces = YES;
        self.charactersScrollView.showsVerticalScrollIndicator = YES;
        self.charactersScrollView.showsHorizontalScrollIndicator = NO;
        [self.contentView addSubview:self.charactersScrollView];

        // 创建字符按钮
        [self setupCharacterButtons];

        CGFloat separatorY = CGRectGetMaxY(self.charactersScrollView.frame) + 10;

        if (self.propName.length > 0) {
            self.propFilterButton = [UIButton buttonWithType:UIButtonTypeSystem];
            self.propFilterButton.frame = CGRectMake(20, separatorY, 260, 40);
            self.propFilterButton.backgroundColor =
                DYYYColor([UIColor colorWithRed:45 / 255.0 green:45 / 255.0 blue:45 / 255.0 alpha:1.0], [UIColor colorWithRed:245 / 255.0 green:245 / 255.0 blue:245 / 255.0 alpha:1.0], self.darkMode);
            self.propFilterButton.layer.cornerRadius = 8;
            [self.propFilterButton addTarget:self action:@selector(propFilterTapped) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:self.propFilterButton];
            [self updateFilterPropButton];
            separatorY = CGRectGetMaxY(self.propFilterButton.frame) + 10;
        }

        // 添加内容和按钮之间的分割线 - 根据模式设置颜色
        UIView *contentButtonSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, separatorY, 300, 0.5)];
        contentButtonSeparator.backgroundColor =
            DYYYColor([UIColor colorWithRed:60 / 255.0 green:60 / 255.0 blue:60 / 255.0 alpha:1.0], [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1.0], self.darkMode);
        [self.contentView addSubview:contentButtonSeparator];

        // 按钮容器
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, contentButtonSeparator.frame.origin.y + 0.5, 300, 55.5)];
        [self.contentView addSubview:buttonContainer];

        // 取消按钮 - 根据模式设置文本颜色
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.cancelButton.frame = CGRectMake(0, 0, 149.5, 55.5);
        self.cancelButton.backgroundColor = [UIColor clearColor];
        [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:DYYYColor([UIColor colorWithRed:160 / 255.0 green:160 / 255.0 blue:165 / 255.0 alpha:1.0],
                                                   [UIColor colorWithRed:124 / 255.0 green:124 / 255.0 blue:130 / 255.0 alpha:1.0], self.darkMode)
                                forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:self.cancelButton];

        // 按钮之间的分割线 - 根据模式设置颜色
        UIView *buttonSeparator = [[UIView alloc] initWithFrame:CGRectMake(149.5, 0, 0.5, 55.5)];
        buttonSeparator.backgroundColor =
            DYYYColor([UIColor colorWithRed:60 / 255.0 green:60 / 255.0 blue:60 / 255.0 alpha:1.0], [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1.0], self.darkMode);
        [buttonContainer addSubview:buttonSeparator];

        // 确认按钮 - 根据模式设置文本颜色
        self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.confirmButton.frame = CGRectMake(150, 0, 150, 55.5);
        self.confirmButton.backgroundColor = [UIColor clearColor];
        [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [self.confirmButton setTitleColor:DYYYColor([UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:235 / 255.0 alpha:1.0],
                                                    [UIColor colorWithRed:45 / 255.0 green:47 / 255.0 blue:56 / 255.0 alpha:1.0], self.darkMode)
                                 forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:self.confirmButton];

        // 更新内容视图位置
        CGRect frame = self.contentView.frame;
        frame.size.height = buttonContainer.frame.origin.y + buttonContainer.frame.size.height - 80;
        self.contentView.frame = frame;
        self.contentView.center = CGPointMake(self.frame.size.width / 2, screenHeight / 2);
        self.originalFrame = self.contentView.frame;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text {
    return [self initWithTitle:title text:text propName:nil];
}

- (void)setupCharacterButtons {
    const CGFloat buttonSize = kDYYYButtonSize;
    const CGFloat margin = kDYYYButtonMargin;
    const int buttonsPerRow = kDYYYButtonsPerRow;

    UIColor *buttonBackgroundColor = DYYYColor([UIColor colorWithRed:50 / 255.0 green:50 / 255.0 blue:50 / 255.0 alpha:1.0], [UIColor whiteColor], self.darkMode);
    UIColor *buttonTextColor =
        DYYYColor([UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:235 / 255.0 alpha:1.0], [UIColor colorWithRed:45 / 255.0 green:47 / 255.0 blue:56 / 255.0 alpha:1.0], self.darkMode);
    UIColor *buttonBorderColor =
        DYYYColor([UIColor colorWithRed:70 / 255.0 green:70 / 255.0 blue:70 / 255.0 alpha:1.0], [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1.0], self.darkMode);

    for (NSInteger i = 0; i < self.text.length; i++) {
        NSString *character = [self.text substringWithRange:NSMakeRange(i, 1)];

        NSInteger row = i / buttonsPerRow;
        NSInteger col = i % buttonsPerRow;

        // 创建字符按钮 - 根据模式设置颜色
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(col * (buttonSize + margin), row * (buttonSize + margin), buttonSize, buttonSize);
        button.backgroundColor = buttonBackgroundColor;
        button.layer.cornerRadius = 6;
        button.layer.borderWidth = 1;
        button.layer.borderColor = buttonBorderColor.CGColor;
        [button setTitle:character forState:UIControlStateNormal];
        [button setTitleColor:buttonTextColor forState:UIControlStateNormal];
        button.tag = i;  // 使用tag存储字符索引

        // 添加触摸事件
        [button addTarget:self action:@selector(characterTouchDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self
                      action:@selector(characterTouchMoved:withEvent:)
            forControlEvents:UIControlEventTouchDragInside | UIControlEventTouchDragEnter | UIControlEventTouchDragExit | UIControlEventTouchDragOutside];
        [button addTarget:self action:@selector(characterTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];

        [self.charactersScrollView addSubview:button];
        [self.characterButtons addObject:button];
    }

    NSInteger rows = (self.text.length + buttonsPerRow - 1) / buttonsPerRow;
    CGFloat contentHeight = rows * (buttonSize + margin) + 10;  // 底部增加一点边距
    self.charactersScrollView.contentSize = CGSizeMake(self.charactersScrollView.frame.size.width, MAX(contentHeight, self.charactersScrollView.frame.size.height));
}

#pragma mark - Button Selection Handling

- (void)characterTouchMoved:(UIButton *)sender withEvent:(UIEvent *)event {
    if (!self.isDragging) {
        self.isDragging = YES;

        if (self.selectedRange.location != NSNotFound) {
            self.isSelecting = YES;
            self.startIndex = self.touchDownIndex;
            self.endIndex = self.touchDownIndex;
            [self updateSelectionWithStartIndex:self.startIndex endIndex:self.endIndex];
        }
    }

    if (self.isSelecting) {
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint currentPoint = [touch locationInView:self.charactersScrollView];
        currentPoint.y += self.charactersScrollView.contentOffset.y;

        NSInteger col = floor(currentPoint.x / (kDYYYButtonSize + kDYYYButtonMargin));
        NSInteger row = floor(currentPoint.y / (kDYYYButtonSize + kDYYYButtonMargin));
        NSInteger index = row * kDYYYButtonsPerRow + col;

        if (index >= 0 && index < self.characterButtons.count && index != self.endIndex) {
            self.endIndex = index;
            [self updateSelectionWithStartIndex:self.startIndex endIndex:self.endIndex];
            [self scrollToVisibleButton:self.characterButtons[index]];
        }
    }
}

- (void)characterTouchDown:(UIButton *)sender {
    NSInteger idx = sender.tag;

    self.touchDownIndex = idx;
    self.startIndex = idx;
    self.endIndex = idx;
    self.isDragging = NO;

    if (self.selectedRange.location == NSNotFound) {
        self.isSelecting = YES;
        [self updateSelectionWithStartIndex:self.startIndex endIndex:self.endIndex];
        return;
    }

    NSInteger rangeStart = self.selectedRange.location;
    NSInteger rangeEnd = NSMaxRange(self.selectedRange) - 1;

    if (idx >= rangeStart && idx <= rangeEnd) {
        if (rangeStart == rangeEnd) {
            [self resetSelection];
            return;
        } else if (idx == rangeStart) {
            rangeStart++;
        } else if (idx == rangeEnd) {
            rangeEnd--;
        } else {
            if (idx - rangeStart <= rangeEnd - idx) {
                rangeStart = idx + 1;
            } else {
                rangeEnd = idx - 1;
            }
        }

        if (rangeStart <= rangeEnd) {
            self.isSelecting = YES;
            self.startIndex = rangeStart;
            self.endIndex = rangeEnd;
            [self updateSelectionWithStartIndex:self.startIndex endIndex:self.endIndex];
        } else {
            [self resetSelection];
        }
    } else {
        self.isSelecting = YES;
        if (idx < rangeStart) {
            self.startIndex = idx;
            self.endIndex = rangeEnd;
        } else {
            self.startIndex = rangeStart;
            self.endIndex = idx;
        }
        [self updateSelectionWithStartIndex:self.startIndex endIndex:self.endIndex];
    }
}

// 添加新方法实现自动滚动
- (void)scrollToVisibleButton:(UIButton *)button {
    CGRect buttonFrame = button.frame;
    CGRect visibleRect = self.charactersScrollView.bounds;

    // 向下滚动 - 增加更多边距提前触发滚动
    if (CGRectGetMaxY(buttonFrame) > CGRectGetMaxY(visibleRect) - 30) {
        CGPoint newOffset = CGPointMake(self.charactersScrollView.contentOffset.x, self.charactersScrollView.contentOffset.y + 15);
        // 确保不超过内容范围
        newOffset.y = MIN(newOffset.y, self.charactersScrollView.contentSize.height - self.charactersScrollView.bounds.size.height);
        [self.charactersScrollView setContentOffset:newOffset animated:NO];
    }

    // 向上滚动 - 增加更多边距提前触发滚动
    else if (CGRectGetMinY(buttonFrame) < CGRectGetMinY(visibleRect) + 30) {
        CGPoint newOffset = CGPointMake(self.charactersScrollView.contentOffset.x, self.charactersScrollView.contentOffset.y - 15);
        // 确保不小于零
        newOffset.y = MAX(newOffset.y, 0);
        [self.charactersScrollView setContentOffset:newOffset animated:NO];
    }
}

- (void)characterTouchUp:(UIButton *)sender {
    self.isDragging = NO;
}

// 添加方法重置选择状态
- (void)resetSelection {
    self.isSelecting = NO;
    self.isDragging = NO;
    self.startIndex = -1;
    self.endIndex = -1;
    self.selectedText = [NSMutableString string];
    self.selectedRange = NSMakeRange(NSNotFound, 0);

    UIColor *buttonBackgroundColor = DYYYColor([UIColor colorWithRed:50 / 255.0 green:50 / 255.0 blue:50 / 255.0 alpha:1.0], [UIColor whiteColor], self.darkMode);

    for (UIButton *button in self.characterButtons) {
        button.backgroundColor = buttonBackgroundColor;
    }

    self.selectionPreviewLabel.text = @"请滑动选择文字";
}

- (void)updateSelectionWithStartIndex:(NSInteger)startIdx endIndex:(NSInteger)endIdx {
    NSInteger startIndex = MIN(startIdx, endIdx);
    NSInteger endIndex = MAX(startIdx, endIdx);

    UIColor *buttonBackgroundColor = DYYYColor([UIColor colorWithRed:50 / 255.0 green:50 / 255.0 blue:50 / 255.0 alpha:1.0], [UIColor whiteColor], self.darkMode);

    NSRange newRange = NSMakeRange(startIndex, endIndex - startIndex + 1);
    NSRange oldRange = self.selectedRange.location == NSNotFound ? NSMakeRange(0, 0) : self.selectedRange;

    // 取消旧范围中不再选中的按钮
    NSInteger oldEnd = NSMaxRange(oldRange) - 1;
    for (NSInteger i = oldRange.location; i <= oldEnd; i++) {
        if (i < 0 || i >= self.characterButtons.count)
            continue;
        if (i < newRange.location || i >= NSMaxRange(newRange)) {
            self.characterButtons[i].backgroundColor = buttonBackgroundColor;
        }
    }

    // 选中新范围
    NSMutableString *selection = [NSMutableString string];
    for (NSInteger i = newRange.location; i < NSMaxRange(newRange); i++) {
        if (i < 0 || i >= self.characterButtons.count)
            continue;
        UIButton *button = self.characterButtons[i];
        button.backgroundColor = [DYYYAccentColor() colorWithAlphaComponent:0.2];
        [selection appendString:button.titleLabel.text];
    }

    self.selectedRange = newRange;
    self.selectedText = selection;
    self.selectionPreviewLabel.text = selection.length > 0 ? selection : @"请滑动选择文字";
}

#pragma mark - Show/Dismiss Methods

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];

    [UIView animateWithDuration:0.12
                     animations:^{
                       self.contentView.alpha = 1.0;
                       self.contentView.transform = CGAffineTransformIdentity;
                     }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.1
        animations:^{
          self.contentView.alpha = 0;
          self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
          self.blurView.alpha = 0;
        }
        completion:^(BOOL finished) {
          [self removeFromSuperview];
        }];
}

#pragma mark - Button Actions

// 修改确认和取消方法
- (void)confirmTapped {
    if (self.onConfirm && self.selectedText.length > 0) {
        self.onConfirm([self.selectedText copy]);
    }
    [self resetSelection];  // 重置选择状态
    [self dismiss];
}

- (void)cancelTapped {
    if (self.onCancel) {
        self.onCancel();
    }
    [self resetSelection];  // 重置选择状态
    [self dismiss];
}

// 过滤关键词按钮点击处理
- (void)keywordFilterTapped {
    if (self.onKeywordFilterTap) {
        self.onKeywordFilterTap();
    }
}

- (void)updateFilterPropButton {
    if (!self.propFilterButton)
        return;

    NSString *saved = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterProp"] ?: @"";
    NSArray *array = saved.length > 0 ? [saved componentsSeparatedByString:@","] : @[];
    BOOL exists = [array containsObject:self.propName];

    NSString *title = exists ? @"取消过滤此拍同款" : @"过滤此拍同款";
    UIColor *titleColor = exists ? DYYYRedColor() : DYYYAccentColor();
    [self.propFilterButton setTitle:title forState:UIControlStateNormal];
    [self.propFilterButton setTitleColor:titleColor forState:UIControlStateNormal];
}

- (void)propFilterTapped {
    if (self.propName.length == 0)
        return;
    NSString *saved = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterProp"] ?: @"";
    NSMutableArray *array = saved.length > 0 ? [saved componentsSeparatedByString:@","].mutableCopy : [NSMutableArray array];
    BOOL exists = [array containsObject:self.propName];

    if (exists) {
        [array removeObject:self.propName];
        [DYYYUtils showToast:@"已从过滤列表中移除此拍同款"];
    } else {
        [array addObject:self.propName];
        [DYYYUtils showToast:@"已添加此拍同款到过滤列表"];
    }

    NSString *newString = [array componentsJoinedByString:@","];
    [[NSUserDefaults standardUserDefaults] setObject:newString forKey:@"DYYYFilterProp"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self updateFilterPropButton];
}

@end
