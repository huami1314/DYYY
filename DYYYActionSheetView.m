#import "DYYYActionSheetView.h"

@implementation DYYYActionItem
+ (instancetype)itemWithTitle:(NSString *)title handler:(DYYYActionHandler)handler {
    DYYYActionItem *item = [[DYYYActionItem alloc] init];
    item.title = title;
    item.handler = handler;
    return item;
}
@end

@interface DYYYActionSheetView ()
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSArray<DYYYActionItem *> *items;
@property (nonatomic, strong) NSMutableArray<UIButton *> *actionButtons;
@end

@implementation DYYYActionSheetView

+ (instancetype)showWithTitle:(NSString *)title items:(NSArray<DYYYActionItem *> *)items {
    DYYYActionSheetView *sheetView = [[DYYYActionSheetView alloc] initWithTitle:title items:items];
    [sheetView show];
    return sheetView;
}

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<DYYYActionItem *> *)items {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self = [super initWithFrame:window.bounds];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _items = items;
        _actionButtons = [NSMutableArray array];
        
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
        _sheetView = [[UIView alloc] init];
        if (@available(iOS 13.0, *)) {
            _sheetView.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            _sheetView.backgroundColor = [UIColor whiteColor];
        }
        _sheetView.layer.cornerRadius = 16.0;
        _sheetView.layer.masksToBounds = YES;
        [self addSubview:_sheetView];
        
        CGFloat padding = 24.0; 
        CGFloat buttonHeight = 30.0;
        CGFloat titleHeight = title.length > 0 ? 50.0 : 0;
        CGFloat totalContentHeight = titleHeight + (buttonHeight + padding) * items.count + buttonHeight + bottomSafeAreaHeight + padding;
        
        // 设置弹窗的大小和位置
        CGFloat sheetWidth = self.bounds.size.width;
        _sheetView.frame = CGRectMake(0, self.bounds.size.height, sheetWidth, totalContentHeight);
        
        // 创建标题
        if (title.length > 0) {
            _titleLabel = [[UILabel alloc] init];
            _titleLabel.text = title;
            _titleLabel.textAlignment = NSTextAlignmentCenter;
            _titleLabel.font = [UIFont boldSystemFontOfSize:16];  // 字体也稍微小一点
            _titleLabel.frame = CGRectMake(padding, padding, sheetWidth - padding * 2, titleHeight - padding);
            [_sheetView addSubview:_titleLabel];
        }
        
        CGFloat yOffset = titleHeight + padding/2;  // 减小顶部按钮的间距
        for (int i = 0; i < items.count; i++) {
            DYYYActionItem *item = items[i];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:item.title forState:UIControlStateNormal];
            button.tag = i;
            [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
            // 修改为白色极简风格
            button.backgroundColor = [UIColor whiteColor];
            button.layer.cornerRadius = 6.0;  // 更小的圆角
            [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            button.frame = CGRectMake(padding, yOffset, sheetWidth - padding * 2, buttonHeight);
            [_sheetView addSubview:button];
            [_actionButtons addObject:button];
            
            yOffset += buttonHeight + padding/2;  // 按钮之间的距离减小
        }
        
        // 添加取消按钮
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        cancelButton.backgroundColor = [UIColor whiteColor];
        cancelButton.layer.cornerRadius = 8.0;
        [cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        cancelButton.frame = CGRectMake(padding, yOffset, sheetWidth - padding * 2, buttonHeight);
        [_sheetView addSubview:cancelButton];
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
        self.sheetView.frame = CGRectMake(0, self.bounds.size.height - self.sheetView.frame.size.height, self.sheetView.frame.size.width, self.sheetView.frame.size.height);
    } completion:nil];
}

- (void)dismiss {
    [UIView animateWithDuration:0.2 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
        self.containerView.alpha = 0.0;
        self.sheetView.frame = CGRectMake(0, self.bounds.size.height, self.sheetView.frame.size.width, self.sheetView.frame.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    [self dismiss];
}

- (void)buttonTapped:(UIButton *)button {
    NSInteger index = button.tag;
    if (index >= 0 && index < self.items.count) {
        DYYYActionItem *item = self.items[index];
        if (item.handler) {
            item.handler();
        }
    }
    [self dismiss];
}

@end