#import "DYYYFilterSettingsView.h"
#import "DYYYManager.h"

@interface DYYYFilterSettingsView ()

@property(nonatomic, strong) UIVisualEffectView *blurView;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIScrollView *charactersScrollView;
@property(nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, strong) UIButton *confirmButton;
@property(nonatomic, strong) UIButton *keywordFilterButton;
@property(nonatomic, strong) UILabel *selectionPreviewLabel;
@property(nonatomic, assign) CGRect originalFrame;
@property(nonatomic, strong) NSString *text;
@property(nonatomic, strong) NSMutableArray<UIButton *> *characterButtons;
@property(nonatomic, assign) NSInteger startIndex;
@property(nonatomic, assign) NSInteger endIndex;
@property(nonatomic, strong) NSMutableString *selectedText;
@property(nonatomic, assign) BOOL isSelecting;

@end

@implementation DYYYFilterSettingsView

- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text {
  if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
    _text = text ?: @"";
    _selectedText = [NSMutableString string];
    _characterButtons = [NSMutableArray array];
    _startIndex = -1;
    _endIndex = -1;
    _isSelecting = NO;
    
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];

    BOOL isDarkMode = [DYYYManager isDarkMode];

    // 创建模糊背景视图
    self.blurView = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:isDarkMode
                                          ? UIBlurEffectStyleDark
                                          : UIBlurEffectStyleLight]];
    self.blurView.frame = self.bounds;
    self.blurView.alpha = isDarkMode ? 0.3 : 0.2;
    [self addSubview:self.blurView];

    // 创建内容视图 - 根据模式设置背景色
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
    CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
    self.contentView.center = CGPointMake(self.frame.size.width / 2, screenHeight / 3);
    self.contentView.backgroundColor = isDarkMode ?
        [UIColor colorWithRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1.0] :
        [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.alpha = 0;
    self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [self addSubview:self.contentView];

    // 主标题 - 根据模式设置文本颜色
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 24)];
    self.titleLabel.text = title ?: @"推荐过滤设置";
    self.titleLabel.textColor = isDarkMode ?
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] :
        [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    [self.contentView addSubview:self.titleLabel];

    // 添加过滤关键词按钮 - 保持强调色不变
    self.keywordFilterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.keywordFilterButton.frame = CGRectMake(240, 20, 40, 24);
    [self.keywordFilterButton setImage:[UIImage systemImageNamed:@"line.3.horizontal.decrease.circle"] forState:UIControlStateNormal];
    self.keywordFilterButton.tintColor = [UIColor colorWithRed:11/255.0 green:223/255.0 blue:154/255.0 alpha:1.0]; // #0BDF9A 保持不变
    [self.keywordFilterButton addTarget:self action:@selector(keywordFilterTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.keywordFilterButton];

    // 选中预览区域 - 根据模式设置背景色
    self.selectionPreviewLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 54, 260, 50)];
    self.selectionPreviewLabel.text = @"请滑动选择文字";
    self.selectionPreviewLabel.textColor = [UIColor colorWithRed:11/255.0 green:223/255.0 blue:154/255.0 alpha:1.0]; // 保持强调色不变
    self.selectionPreviewLabel.textAlignment = NSTextAlignmentCenter;
    self.selectionPreviewLabel.numberOfLines = 2;
    self.selectionPreviewLabel.font = [UIFont systemFontOfSize:16];
    self.selectionPreviewLabel.backgroundColor = isDarkMode ?
        [UIColor colorWithRed:45/255.0 green:45/255.0 blue:45/255.0 alpha:1.0] :
        [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0];
    self.selectionPreviewLabel.layer.cornerRadius = 8;
    self.selectionPreviewLabel.layer.masksToBounds = YES;
    [self.contentView addSubview:self.selectionPreviewLabel];

    // 字符滚动视图 - 根据模式设置背景色
    self.charactersScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 114, 260, 220)];
    self.charactersScrollView.backgroundColor = isDarkMode ?
        [UIColor colorWithRed:45/255.0 green:45/255.0 blue:45/255.0 alpha:1.0] :
        [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0];
    self.charactersScrollView.layer.cornerRadius = 8;
    self.charactersScrollView.bounces = YES;
    self.charactersScrollView.showsVerticalScrollIndicator = YES;
    self.charactersScrollView.showsHorizontalScrollIndicator = NO;
    [self.contentView addSubview:self.charactersScrollView];

    // 创建字符按钮
    [self setupCharacterButtons];

    // 添加内容和按钮之间的分割线 - 根据模式设置颜色
    UIView *contentButtonSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 344, 300, 0.5)];
    contentButtonSeparator.backgroundColor = isDarkMode ?
        [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] :
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    [self.contentView addSubview:contentButtonSeparator];

    // 按钮容器
    UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, contentButtonSeparator.frame.origin.y + 0.5, 300, 55.5)];
    [self.contentView addSubview:buttonContainer];

    // 取消按钮 - 根据模式设置文本颜色
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.frame = CGRectMake(0, 0, 149.5, 55.5);
    self.cancelButton.backgroundColor = [UIColor clearColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:isDarkMode ?
        [UIColor colorWithRed:160/255.0 green:160/255.0 blue:165/255.0 alpha:1.0] :
        [UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0]
        forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:self.cancelButton];

    // 按钮之间的分割线 - 根据模式设置颜色
    UIView *buttonSeparator = [[UIView alloc] initWithFrame:CGRectMake(149.5, 0, 0.5, 55.5)];
    buttonSeparator.backgroundColor = isDarkMode ?
        [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] :
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    [buttonContainer addSubview:buttonSeparator];

    // 确认按钮 - 根据模式设置文本颜色
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.confirmButton.frame = CGRectMake(150, 0, 150, 55.5);
    self.confirmButton.backgroundColor = [UIColor clearColor];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:isDarkMode ?
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] :
        [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0]
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

- (void)setupCharacterButtons {
  const CGFloat buttonSize = 25.0;
  const CGFloat margin = 1.0;
  const int buttonsPerRow = 10;
  
  int row = 0;
  int col = 0;
  
  BOOL isDarkMode = [DYYYManager isDarkMode];
  UIColor *buttonBackgroundColor = isDarkMode ?
      [UIColor colorWithRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:1.0] :
      [UIColor whiteColor];
  UIColor *buttonTextColor = isDarkMode ?
      [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] :
      [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
  UIColor *buttonBorderColor = isDarkMode ?
      [UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0] :
      [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
  
  for (NSInteger i = 0; i < self.text.length; i++) {
    NSString *character = [self.text substringWithRange:NSMakeRange(i, 1)];
    
    // 创建字符按钮 - 根据模式设置颜色
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(col * (buttonSize + margin), row * (buttonSize + margin), buttonSize, buttonSize);
    button.backgroundColor = buttonBackgroundColor;
    button.layer.cornerRadius = 6;
    button.layer.borderWidth = 1;
    button.layer.borderColor = buttonBorderColor.CGColor;
    [button setTitle:character forState:UIControlStateNormal];
    [button setTitleColor:buttonTextColor forState:UIControlStateNormal];
    button.tag = i; // 使用tag存储字符索引
    
    // 添加触摸事件
    [button addTarget:self action:@selector(characterTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(characterTouchMoved:withEvent:) forControlEvents:UIControlEventTouchDragInside | UIControlEventTouchDragEnter | UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(characterTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    
    [self.charactersScrollView addSubview:button];
    [self.characterButtons addObject:button];
    
    // 更新行列位置
    col++;
    if (col >= buttonsPerRow) {
      col = 0;
      row++;
    }
  }
  
  // 设置滚动视图的内容大小
  CGFloat contentHeight = (row + (col > 0 ? 1 : 0)) * (buttonSize + margin) + 10; // 底部增加一点边距
  self.charactersScrollView.contentSize = CGSizeMake(self.charactersScrollView.frame.size.width, MAX(contentHeight, self.charactersScrollView.frame.size.height));
}

#pragma mark - Button Selection Handling

- (void)characterTouchMoved:(UIButton *)sender withEvent:(UIEvent *)event {
    // 确保已经开始选择
    if (self.isSelecting) {
        // 获取当前触摸点
        UITouch *touch = [[event touchesForView:sender] anyObject];
        CGPoint currentPoint = [touch locationInView:self.charactersScrollView];
        
        // 查找当前触摸点下的按钮
        for (UIButton *button in self.characterButtons) {
            if (CGRectContainsPoint(button.frame, currentPoint)) {
                // 如果找到按钮，更新结束索引
                NSInteger buttonTag = button.tag;
                if (buttonTag != self.endIndex) {
                    self.endIndex = buttonTag;
                    [self updateSelectionWithStartIndex:self.startIndex endIndex:self.endIndex];
                    
                    // 自动滚动到可见区域
                    [self scrollToVisibleButton:button];
                }
                break;
            }
        }
    }
}

- (void)characterTouchDown:(UIButton *)sender {
    NSInteger buttonTag = sender.tag;
    
    // 检查是否已有选择
    if (self.isSelecting && self.startIndex != -1 && self.endIndex != -1) {
        NSInteger startIndex = MIN(self.startIndex, self.endIndex);
        NSInteger endIndex = MAX(self.startIndex, self.endIndex);
        
        // 1. 检查是否点击了已选中的字符
        if (buttonTag >= startIndex && buttonTag <= endIndex) {
            // 2. 处理点击已选中字符的情况
            if (buttonTag == startIndex && buttonTag == endIndex) {
                // 点击的是唯一选中的字符，取消整个选择
                [self resetSelection];
                return;
            } else if (buttonTag == startIndex) {
                // 点击的是选择范围的第一个字符
                self.startIndex = startIndex + 1;
            } else if (buttonTag == endIndex) {
                // 点击的是选择范围的最后一个字符
                self.endIndex = endIndex - 1;
            } else {
                // 点击的是选择范围中间的字符
                // 选择较短的那一边进行调整
                if (buttonTag - startIndex <= endIndex - buttonTag) {
                    // 左侧部分较短，保留右侧部分
                    self.startIndex = buttonTag + 1;
                } else {
                    // 右侧部分较短，保留左侧部分
                    self.endIndex = buttonTag - 1;
                }
            }
            
            // 更新选择范围
            if (self.startIndex > self.endIndex) {
                // 如果结果是无效的选择范围，则重置选择
                [self resetSelection];
            } else {
                [self updateSelectionWithStartIndex:self.startIndex endIndex:self.endIndex];
            }
            return;
        }
    }
    
    // 原有的处理逻辑
    if (!self.isSelecting || (self.startIndex == -1 && self.endIndex == -1)) {
        self.isSelecting = YES;
        self.startIndex = buttonTag;
        self.endIndex = buttonTag;
    } else {
        // 已有选择，扩展选择范围
        self.endIndex = buttonTag;
    }
    
    [self updateSelectionWithStartIndex:self.startIndex endIndex:self.endIndex];
}

// 添加新方法实现自动滚动
- (void)scrollToVisibleButton:(UIButton *)button {
    CGRect buttonFrame = button.frame;
    CGRect visibleRect = self.charactersScrollView.bounds;
    
    // 向下滚动 - 增加更多边距提前触发滚动
    if (CGRectGetMaxY(buttonFrame) > CGRectGetMaxY(visibleRect) - 30) {
        CGPoint newOffset = CGPointMake(self.charactersScrollView.contentOffset.x,
                                      self.charactersScrollView.contentOffset.y + 15);
        // 确保不超过内容范围
        newOffset.y = MIN(newOffset.y, self.charactersScrollView.contentSize.height - self.charactersScrollView.bounds.size.height);
        [self.charactersScrollView setContentOffset:newOffset animated:NO];
    }
    
    // 向上滚动 - 增加更多边距提前触发滚动
    else if (CGRectGetMinY(buttonFrame) < CGRectGetMinY(visibleRect) + 30) {
        CGPoint newOffset = CGPointMake(self.charactersScrollView.contentOffset.x,
                                      self.charactersScrollView.contentOffset.y - 15);
        // 确保不小于零
        newOffset.y = MAX(newOffset.y, 0);
        [self.charactersScrollView setContentOffset:newOffset animated:NO];
    }
}

- (void)characterTouchUp:(UIButton *)sender {
    // 不再重置isSelecting状态，这样可以保持选择状态以便单击扩展选择
}

// 添加方法重置选择状态
- (void)resetSelection {
    self.isSelecting = NO;
    self.startIndex = -1;
    self.endIndex = -1;
    self.selectedText = [NSMutableString string];
    
    BOOL isDarkMode = [DYYYManager isDarkMode];
    UIColor *buttonBackgroundColor = isDarkMode ?
        [UIColor colorWithRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:1.0] :
        [UIColor whiteColor];
    
    for (UIButton *button in self.characterButtons) {
        button.backgroundColor = buttonBackgroundColor;
    }
    
    self.selectionPreviewLabel.text = @"请滑动选择文字";
}

- (void)updateSelectionWithStartIndex:(NSInteger)startIdx endIndex:(NSInteger)endIdx {
  // 确保有效的开始和结束索引
  NSInteger startIndex = MIN(startIdx, endIdx);
  NSInteger endIndex = MAX(startIdx, endIdx);
  
  BOOL isDarkMode = [DYYYManager isDarkMode];
  UIColor *buttonBackgroundColor = isDarkMode ?
      [UIColor colorWithRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:1.0] :
      [UIColor whiteColor];
  
  // 清除所有按钮选中状态
  for (UIButton *button in self.characterButtons) {
    button.backgroundColor = buttonBackgroundColor;
  }
  
  // 设置选中范围内按钮的状态
  NSMutableString *selection = [NSMutableString string];
  for (NSInteger i = startIndex; i <= endIndex; i++) {
    if (i < self.characterButtons.count) {
      UIButton *button = self.characterButtons[i];
      button.backgroundColor = [UIColor colorWithRed:11/255.0 green:223/255.0 blue:154/255.0 alpha:0.2]; // 浅绿色背景，保持一致
      [selection appendString:button.titleLabel.text];
    }
  }
  
  // 更新选中文本和预览标签
  self.selectedText = selection;
  if (selection.length > 0) {
    self.selectionPreviewLabel.text = selection;
  } else {
    self.selectionPreviewLabel.text = @"请滑动选择文字";
  }
}

#pragma mark - Show/Dismiss Methods

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

#pragma mark - Button Actions

// 修改确认和取消方法
- (void)confirmTapped {
    if (self.onConfirm && self.selectedText.length > 0) {
        self.onConfirm([self.selectedText copy]);
    }
    [self resetSelection]; // 重置选择状态
    [self dismiss];
}

- (void)cancelTapped {
    if (self.onCancel) {
        self.onCancel();
    }
    [self resetSelection]; // 重置选择状态
    [self dismiss];
}

// 过滤关键词按钮点击处理
- (void)keywordFilterTapped {
    if (self.onKeywordFilterTap) {
        self.onKeywordFilterTap();
    }
}

@end
