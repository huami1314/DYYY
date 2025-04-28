#import "DYYYManager.h"
#import <UIKit/UIKit.h>
#import <signal.h>

@interface HideUIButton : UIButton
@property(nonatomic, assign) BOOL isElementsHidden;
@property(nonatomic, assign) BOOL isLocked;
@property(nonatomic, assign) BOOL isPositionLocked; // 位置锁定状态
@property(nonatomic, strong) NSMutableArray *hiddenViewsList;
@property(nonatomic, strong) NSTimer *checkTimer;
@property(nonatomic, strong) NSTimer *fadeTimer;
@property(nonatomic, strong) NSTimer *reattachTimer; // 重新吸附的定时器
@property(nonatomic, assign) NSTimeInterval lastCheckTime;
@property(nonatomic, assign) NSTimeInterval lastTouchTime; // 最后触摸时间
@property(nonatomic, assign) BOOL isStickToEdge; // 是否吸附在边缘
@property(nonatomic, assign) BOOL wasStickToEdge; // 展开前是否吸附在边缘
@property(nonatomic, assign) BOOL isLeftEdge; // 是否在左边缘
@property(nonatomic, assign) CGFloat originalWidth; // 原始宽度
@property(nonatomic, assign) CGFloat originalHeight; // 原始高度
@property(nonatomic, assign) CGFloat edgeWidth; // 边缘显示宽度
@property(nonatomic, strong) UIView *stickIndicatorView; // 吸附状态指示器
@property(nonatomic, strong) UILabel *arrowLabel; // 箭头标签，便于直接引用

- (void)resetFadeTimer;
- (void)hideUIElements;
- (void)safeResetState;
- (void)cleanupHiddenViews;
- (void)stickToEdge:(BOOL)leftEdge animated:(BOOL)animated;
- (void)expandFromEdge:(BOOL)animated;
- (void)resetReattachTimer;
- (void)updateLastTouchTime;
- (void)togglePositionLock;
- (void)handleIndicatorTap:(UITapGestureRecognizer *)gesture;
@end

static HideUIButton *hideButton;
static BOOL isAppInTransition = NO;
static NSArray *targetClassNames;
static NSCache *classCache;

#pragma mark - Helper Functions
static void findViewsOfClassHelper(UIView *view, Class viewClass, NSMutableArray *result) {
    if ([view isKindOfClass:viewClass]) [result addObject:view];
    for (UIView *subview in view.subviews) findViewsOfClassHelper(subview, viewClass, result);
}

static UIWindow *getKeyWindow() {
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) return window;
    }
    return nil;
}

static void forceResetAllUIElements() {
    UIWindow *window = getKeyWindow();
    if (!window) return;
    
    for (NSString *className in targetClassNames) {
        Class viewClass = NSClassFromString(className);
        if (!viewClass) continue;
        
        NSMutableArray *views = [NSMutableArray new];
        findViewsOfClassHelper(window, viewClass, views);
        
        // 添加淡入动画效果
        [UIView animateWithDuration:0.25 animations:^{
            for (UIView *view in views) view.alpha = 1.0;
        }];
    }
}

static void initTargetClassNames() {
    targetClassNames = @[
        @"AWEHPTopBarCTAContainer", @"AWEHPDiscoverFeedEntranceView",
        @"AWELeftSideBarEntranceView", @"DUXBadge",
        @"AWEBaseElementView", @"AWEElementStackView",
        @"AWEPlayInteractionDescriptionLabel", @"AWEUserNameLabel",
        @"AWEStoryProgressSlideView", @"AWEStoryProgressContainerView",
        @"ACCEditTagStickerView", @"AWEFeedTemplateAnchorView",
        @"AWESearchFeedTagView", @"AWEPlayInteractionSearchAnchorView",
        @"AFDRecommendToFriendTagView", @"AWELandscapeFeedEntryView",
        @"AWEFeedAnchorContainerView", @"AFDAIbumFolioView"
    ];
    
    // 初始化类缓存提高性能
    classCache = [[NSCache alloc] init];
    for (NSString *className in targetClassNames) {
        Class viewClass = NSClassFromString(className);
        if (viewClass) {
            [classCache setObject:viewClass forKey:className];
        }
    }
}

#pragma mark - HideUIButton Implementation
@implementation HideUIButton
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // 记录原始尺寸
        _originalWidth = frame.size.width;
        _originalHeight = frame.size.height;
        _edgeWidth = 20; // 调整边缘显示宽度
        _isStickToEdge = NO;
        _wasStickToEdge = NO;
        _isPositionLocked = NO; // 默认不锁定位置
        _lastTouchTime = [[NSDate date] timeIntervalSince1970];
        
        // 视觉配置
        self.layer.cornerRadius = 24;
        self.clipsToBounds = NO;
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
        
        // 添加描边
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
        
        // 阴影效果
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowRadius = 6;
        self.layer.masksToBounds = NO;
        
        // 指示器视图初始化为nil，会在需要时创建
        self.stickIndicatorView = nil;
        self.arrowLabel = nil;
        
        // 系统图标配置
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightMedium];
            UIImage *hideImage = [[UIImage systemImageNamed:@"eye.slash"] imageByApplyingSymbolConfiguration:config];
            UIImage *showImage = [[UIImage systemImageNamed:@"eye"] imageByApplyingSymbolConfiguration:config];
            [self setImage:hideImage forState:UIControlStateNormal];
            [self setImage:showImage forState:UIControlStateSelected];
        } else {
            // 兼容iOS 13以下版本
            [self setTitle:@"隐" forState:UIControlStateNormal];
            [self setTitle:@"显" forState:UIControlStateSelected];
            self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        }
        
        self.tintColor = UIColor.whiteColor;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        // 状态初始化
        _isElementsHidden = NO;
        _hiddenViewsList = [NSMutableArray new];
        _lastCheckTime = 0;
        [self loadLockState];
        [self loadPositionLockState];
        
        // 手势识别
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] 
            initWithTarget:self action:@selector(handlePan:)];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] 
            initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.5;
        [self addGestureRecognizer:pan];
        [self addGestureRecognizer:longPress];
        [self addTarget:self action:@selector(handleTap) 
            forControlEvents:UIControlEventTouchUpInside];
        
        // 定时器
        [self startPeriodicCheck];
        [self resetFadeTimer];
        [self resetReattachTimer];
        
        // 添加清理通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(cleanupHiddenViews)
                                                   name:UIApplicationDidReceiveMemoryWarningNotification
                                                 object:nil];
                                                 
        // 从上次位置加载是否已吸附到边缘的状态
        BOOL wasStickToEdge = [NSUserDefaults.standardUserDefaults boolForKey:@"DYYYHideUIButtonStickToEdge"];
        BOOL wasLeftEdge = [NSUserDefaults.standardUserDefaults boolForKey:@"DYYYHideUIButtonIsLeftEdge"];
        if (wasStickToEdge) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self stickToEdge:wasLeftEdge animated:NO];
            });
        }
    }
    return self;
}

- (void)updateVisualIndicators {
    // 更新位置锁定状态的视觉提示
    if (self.isPositionLocked) {
        self.layer.borderWidth = 1.5;
    } else {
        self.layer.borderWidth = 1.0;
    }
    
    // 显示/隐藏主图标和吸附指示器
    if (self.isStickToEdge) {
        // 1. 隐藏主图标
        if (@available(iOS 13.0, *)) {
            [self setImage:nil forState:UIControlStateNormal];
            [self setImage:nil forState:UIControlStateSelected];
        } else {
            [self setTitle:@"" forState:UIControlStateNormal];
            [self setTitle:@"" forState:UIControlStateSelected];
        }
        
        // 2. 完全隐藏按钮背景和边框
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderWidth = 0;
        self.layer.shadowOpacity = 0;
        
        // 3. 移除旧的指示器
        if (self.stickIndicatorView) {
            [self.stickIndicatorView removeFromSuperview];
            self.stickIndicatorView = nil;
        }
        
        // 4. 创建最简单的指示器视图 - 纯色背景，无任何特效
        CGFloat indicatorHeight = self.originalHeight;
        CGFloat indicatorWidth = self.edgeWidth;
        
        // 计算位置
        CGRect indicatorFrame;
        if (self.isLeftEdge) {
            indicatorFrame = CGRectMake(
                self.originalWidth - indicatorWidth,
                0,
                indicatorWidth,
                indicatorHeight
            );
        } else {
            indicatorFrame = CGRectMake(
                0,
                0,
                indicatorWidth,
                indicatorHeight
            );
        }
        
        // 创建最简单的指示器视图
        UIView *indicatorView = [[UIView alloc] initWithFrame:indicatorFrame];
        indicatorView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.9];
        
        // 只设置一侧圆角
        UIRectCorner corners;
        if (self.isLeftEdge) {
            corners = UIRectCornerTopRight | UIRectCornerBottomRight;
        } else {
            corners = UIRectCornerTopLeft | UIRectCornerBottomLeft;
        }
        
        // 使用贝塞尔路径创建形状
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:indicatorView.bounds
                                                       byRoundingCorners:corners
                                                             cornerRadii:CGSizeMake(8, 8)];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = indicatorView.bounds;
        maskLayer.path = maskPath.CGPath;
        indicatorView.layer.mask = maskLayer;
        
        // 添加边框 - 单独图层
        CAShapeLayer *borderLayer = [CAShapeLayer layer];
        borderLayer.frame = indicatorView.bounds;
        borderLayer.path = maskPath.CGPath;
        borderLayer.fillColor = [UIColor clearColor].CGColor;
        borderLayer.strokeColor = [UIColor whiteColor].CGColor;
        borderLayer.lineWidth = 1.0;
        [indicatorView.layer addSublayer:borderLayer];
        
        // 添加箭头按钮
        UIButton *arrowButton = [UIButton buttonWithType:UIButtonTypeCustom];
        arrowButton.frame = CGRectMake(0, 0, indicatorWidth * 0.8, indicatorWidth * 0.8);
        arrowButton.center = CGPointMake(indicatorWidth / 2, indicatorHeight / 2);
        arrowButton.tintColor = [UIColor whiteColor];
        
        // 设置箭头图标
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightSemibold];
            UIImage *arrowImage;
            if (self.isLeftEdge) {
                arrowImage = [[UIImage systemImageNamed:@"chevron.right"] imageWithConfiguration:config];
            } else {
                arrowImage = [[UIImage systemImageNamed:@"chevron.left"] imageWithConfiguration:config];
            }
            [arrowButton setImage:arrowImage forState:UIControlStateNormal];
        } else {
            // 手动设置箭头文本
            arrowButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
            [arrowButton setTitle:(self.isLeftEdge ? @">" : @"<") forState:UIControlStateNormal];
        }
        
        [arrowButton addTarget:self action:@selector(handleArrowButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [indicatorView addSubview:arrowButton];
        
        // 添加点击手势到整个指示器
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIndicatorTap:)];
        [indicatorView addGestureRecognizer:tapGesture];
        
        self.stickIndicatorView = indicatorView;
        [self addSubview:indicatorView];
        
        // 设置2秒后降低透明度的定时器
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reduceIndicatorOpacity) object:nil];
        [self performSelector:@selector(reduceIndicatorOpacity) withObject:nil afterDelay:2.0];
    } else {
        // 非吸附状态
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
        self.layer.borderWidth = self.isPositionLocked ? 1.5 : 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
        self.layer.shadowOpacity = 0.5;
        
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightMedium];
            UIImage *hideImage = [[UIImage systemImageNamed:@"eye.slash"] imageByApplyingSymbolConfiguration:config];
            UIImage *showImage = [[UIImage systemImageNamed:@"eye"] imageByApplyingSymbolConfiguration:config];
            [self setImage:hideImage forState:UIControlStateNormal];
            [self setImage:showImage forState:UIControlStateSelected];
        } else {
            [self setTitle:@"隐" forState:UIControlStateNormal];
            [self setTitle:@"显" forState:UIControlStateSelected];
        }
        
        // 移除指示器
        if (self.stickIndicatorView) {
            [self.stickIndicatorView removeFromSuperview];
            self.stickIndicatorView = nil;
        }
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reduceIndicatorOpacity) object:nil];
    }
}

- (void)handleArrowButtonTap:(UIButton *)sender {
    [self handleIndicatorTap:nil];
}

- (void)handleIndicatorTap:(UITapGestureRecognizer *)gesture {
    if (isAppInTransition) return;
    
    [self updateLastTouchTime];
    
    // 恢复透明度
    if (self.stickIndicatorView) {
        self.stickIndicatorView.alpha = 1.0;
    }
    
    // 添加点击反馈效果
    [UIView animateWithDuration:0.15 animations:^{
        self.stickIndicatorView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            self.stickIndicatorView.transform = CGAffineTransformIdentity;
        }];
    }];
    
    // 无论是否锁定位置，都允许展开
    if (self.isStickToEdge) {
        self.wasStickToEdge = YES;
        [self expandFromEdge:YES];
        
        // 触感反馈
        if (@available(iOS 10.0, *)) {
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [generator prepare];
            [generator impactOccurred];
        }
    }
}

// 降低指示器透明度的方法
- (void)reduceIndicatorOpacity {
    if (self.isStickToEdge && self.stickIndicatorView) {
        [UIView animateWithDuration:0.5 animations:^{
            self.stickIndicatorView.alpha = 0.3;
        }];
    }
}

- (void)stickToEdge:(BOOL)leftEdge animated:(BOOL)animated {
    // 如果处于锁定状态，不执行吸附
    if (self.isLocked) return;
    
    // 记录状态
    self.isStickToEdge = YES;
    self.wasStickToEdge = YES;
    self.isLeftEdge = leftEdge;
    
    // 确定目标位置和尺寸
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    CGFloat targetX, targetY;
    
    // 调整为完全贴合屏幕边缘
    if (leftEdge) {
        targetX = -self.originalWidth + self.edgeWidth; // 左侧贴合，只露出指示器部分
    } else {
        targetX = screenBounds.size.width - self.edgeWidth; // 右侧贴合，只露出指示器部分
    }
    
    // 保持Y轴位置不变，但确保在屏幕范围内
    CGFloat minY = self.originalHeight/2 + 30; // 顶部安全区域
    CGFloat maxY = screenBounds.size.height - self.originalHeight/2 - 30; // 底部安全区域
    targetY = MIN(MAX(self.center.y, minY), maxY);
    
    // 创建新的frame
    CGRect newFrame = CGRectMake(
        targetX, 
        targetY - self.originalHeight/2,  // 根据center.y计算顶部坐标
        self.originalWidth, 
        self.originalHeight
    );
    
    // 确保在更新视觉指示器之前先清除主按钮的图标
    if (@available(iOS 13.0, *)) {
        [self setImage:nil forState:UIControlStateNormal];
        [self setImage:nil forState:UIControlStateSelected];
    } else {
        [self setTitle:@"" forState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateSelected];
    }
    
    // 先更新frame，确保视觉指示器位置正确
    self.frame = newFrame;
    
    // 然后更新视觉指示器
    [self updateVisualIndicators];
    
    // 根据动画标志决定是否动画过渡
    if (animated) {
        // 重置初始位置，然后执行动画
        CGRect originalFrame = self.frame;
        self.frame = CGRectOffset(originalFrame, leftEdge ? 20 : -20, 0);
        
        [UIView animateWithDuration:0.3
                             delay:0
            usingSpringWithDamping:0.7
             initialSpringVelocity:0.5
                           options:UIViewAnimationOptionCurveEaseOut
                        animations:^{
                            self.frame = newFrame;
                            self.alpha = 0.98; // 保持较高的可见度
                        } completion:^(BOOL finished) {
                            // 确保完成后视觉状态正确
                            [self updateVisualIndicators];
                        }];
    } else {
        // 直接设置最终状态
        self.frame = newFrame;
        self.alpha = 0.98;
    }
    
    // 保存状态到UserDefaults
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"DYYYHideUIButtonStickToEdge"];
    [NSUserDefaults.standardUserDefaults setBool:leftEdge forKey:@"DYYYHideUIButtonIsLeftEdge"];
    
    // 重设定时器，贴边后不自动隐藏
    [self.fadeTimer invalidate];
}

- (void)updateLastTouchTime {
    self.lastTouchTime = [[NSDate date] timeIntervalSince1970];
    [self resetReattachTimer];
    
    // 如果是吸附状态，重置透明度和定时器
    if (self.isStickToEdge && self.stickIndicatorView) {
        self.stickIndicatorView.alpha = 1.0;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reduceIndicatorOpacity) object:nil];
        [self performSelector:@selector(reduceIndicatorOpacity) withObject:nil afterDelay:2.0];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    // 如果按钮位置已锁定，不允许拖动
    if (self.isLocked || self.isPositionLocked) return;
    
    [self updateLastTouchTime];
    [self resetFadeTimer];
    
    // 获取移动距离
    CGPoint translation = [gesture translationInView:self.superview];
    
    // 如果当前吸附在边缘，先展开
    if (self.isStickToEdge && gesture.state == UIGestureRecognizerStateBegan) {
        self.wasStickToEdge = YES;
        [self expandFromEdge:YES];
    }
    
    // 添加拖动动画效果
    if (gesture.state == UIGestureRecognizerStateBegan && !self.isStickToEdge) {
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeScale(1.05, 1.05);
        }];
    }
    
    // 移动按钮
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    // 处理拖动结束
    if (gesture.state == UIGestureRecognizerStateEnded) {
        // 获取屏幕边界
        CGRect screenBounds = UIScreen.mainScreen.bounds;
        CGFloat minX = self.frame.size.width / 2;
        CGFloat maxX = screenBounds.size.width - minX;
        CGFloat minY = self.frame.size.height / 2 + 20; // 避开状态栏
        CGFloat maxY = screenBounds.size.height - minY - 20; // 避开底部可能的控制栏
        
        // 检测是否需要吸附到边缘
        CGFloat edgeThreshold = 40; // 靠近边缘的阈值
        BOOL shouldStickToEdge = NO;
        BOOL isLeftEdge = NO;
        
        // 检测是否靠近左右边缘
        if (self.center.x < edgeThreshold + minX) {
            shouldStickToEdge = YES;
            isLeftEdge = YES;
        } else if (self.center.x > maxX - edgeThreshold) {
            shouldStickToEdge = YES;
            isLeftEdge = NO;
        }
        
        // 根据位置决定是吸附还是自由放置
        if (shouldStickToEdge) {
            // 吸附到边缘
            [self stickToEdge:isLeftEdge animated:YES];
        } else {
            // 非吸附状态，确保在屏幕内
            CGPoint newCenter = CGPointMake(
                MIN(MAX(self.center.x, minX), maxX),
                MIN(MAX(self.center.y, minY), maxY)
            );
            
            // 自由位置动画
            [UIView animateWithDuration:0.2 animations:^{
                self.center = newCenter;
                self.transform = CGAffineTransformIdentity;
            }];
            
            // 保存位置状态
            [NSUserDefaults.standardUserDefaults setObject:NSStringFromCGPoint(newCenter) 
                forKey:@"DYYYHideUIButtonPosition"];
            [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"DYYYHideUIButtonStickToEdge"];
            
            // 更新视觉提示
            [self updateVisualIndicators];
        }
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    
    [self updateLastTouchTime];
    
    // 切换位置锁定状态
    [self togglePositionLock];
}

// 切换位置锁定状态
- (void)togglePositionLock {
    self.isPositionLocked = !self.isPositionLocked;
    [self savePositionLockState];
    [self updateVisualIndicators];
    
    // 效果反馈
    [UIView animateWithDuration:0.15 animations:^{
        self.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];
    
    // 显示状态提示
    NSString *message = self.isPositionLocked ? @"位置已锁定" : @"位置已解锁";
    [DYYYManager showToast:message];
    
    // 触感反馈
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
}

- (void)handleTap {
    if (isAppInTransition) return;
    
    [self updateLastTouchTime];
    
    // 如果处于边缘状态，先展开
    if (self.isStickToEdge) {
        self.wasStickToEdge = YES;
        [self expandFromEdge:YES];
        return;
    }
    
    // 切换状态
    self.isElementsHidden = !self.isElementsHidden;
    self.selected = self.isElementsHidden;
    [self resetFadeTimer];
    
    // 点击动画效果
    [UIView animateWithDuration:0.15 animations:^{
        self.transform = CGAffineTransformMakeScale(1.15, 1.15);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            // 如果之前是吸附状态，等操作完成后自动回到吸附状态
            // 位置锁定不应该影响自动吸附
            if (self.wasStickToEdge) {
                [self performAutoReattach];
            }
        }];
    }];
    
    // 处理UI元素
    if (self.isElementsHidden) {
        [self hideUIElements];
    } else {
        forceResetAllUIElements();
        [_hiddenViewsList removeAllObjects];
    }
    
    // 触感反馈
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
}

- (void)performAutoReattach {
    // 确保没有被锁定(只检查按钮锁定状态，不检查位置锁定)并且当前不在边缘状态
    if (self.isLocked || self.isStickToEdge) return;
    
    // 自动吸附回边缘，检查当前的位置决定左右
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    BOOL shouldStickToLeft = self.center.x < screenBounds.size.width / 2;
    
    // 延迟0.8秒后自动吸附，缩短延迟时间
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 再次检查状态，确保此时仍应该执行吸附
        if (!self.isStickToEdge && !self.isLocked && self.wasStickToEdge) {
            [self stickToEdge:shouldStickToLeft animated:YES];
        }
    });
}

- (void)hideUIElements {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - self.lastCheckTime < 0.3) return; // 限制检查频率
    self.lastCheckTime = currentTime;
    
    [self cleanupHiddenViews]; // 清理无效的视图引用
    
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (!window.isUserInteractionEnabled || window.alpha < 0.1) continue;
        
        for (NSString *className in targetClassNames) {
            Class viewClass = [classCache objectForKey:className] ?: NSClassFromString(className);
            if (!viewClass) continue;
            
            NSMutableArray *views = [NSMutableArray new];
            findViewsOfClassHelper(window, viewClass, views);
            
            for (UIView *view in views) {
                if ([self shouldHideView:view ofClass:className]) {
                    // 添加淡出动画
                    if (view.alpha > 0.1) {
                        [UIView animateWithDuration:0.25 animations:^{
                            view.alpha = 0.0;
                        }];
                        [self.hiddenViewsList addObject:view];
                    }
                }
            }
        }
    }
}

- (BOOL)shouldHideView:(UIView *)view ofClass:(NSString *)className {
    if ([className isEqual:@"AWELeftSideBarEntranceView"]) {
        UIResponder *responder = view.nextResponder;
        while (responder && ![responder isKindOfClass:NSClassFromString(@"AWEFeedContainerViewController")]) {
            responder = responder.nextResponder;
        }
        return responder != nil;
    }
    return YES;
}

- (void)cleanupHiddenViews {
    @synchronized (self) {
        NSMutableArray *validViews = [NSMutableArray new];
        for (UIView *view in self.hiddenViewsList) {
            if (view && view.window) {
                [validViews addObject:view];
            }
        }
        self.hiddenViewsList = validViews;
    }
}

#pragma mark - 边缘吸附相关方法
- (void)expandFromEdge:(BOOL)animated {
    // 即使位置锁定，也允许临时展开
    if (!self.isStickToEdge) return;
    
    // 记录扩展前的状态，确保可以自动吸附回去
    self.wasStickToEdge = YES;
    
    // 更新状态
    self.isStickToEdge = NO;
    
    // 确保隐藏吸附指示器视图
    self.stickIndicatorView.hidden = YES;
    
    // 恢复按钮背景和边框
    self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
    self.layer.borderWidth = self.isPositionLocked ? 1.5 : 1.0;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
    self.layer.shadowOpacity = 0.5;
    
    // 计算展开后的位置
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    CGFloat targetX;
    
    if (self.isLeftEdge) {
        targetX = self.originalWidth / 2 + 10;
    } else {
        targetX = screenBounds.size.width - self.originalWidth / 2 - 10;
    }
    
    // 使用当前的Y位置
    CGFloat targetY = self.center.y;
    
    // 创建新的居中frame
    CGRect expandedFrame = CGRectMake(
        targetX - self.originalWidth / 2,
        targetY - self.originalHeight / 2,
        self.originalWidth,
        self.originalHeight
    );
    
    // 更新回正常图标 - 先更新，避免动画过程中出现闪烁
    [self updateVisualIndicators];
    
    // 动画展开
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.frame = expandedFrame;
                             self.alpha = 1.0; // 恢复完全不透明
                             self.transform = CGAffineTransformMakeScale(1.05, 1.05); // 稍微放大以提供视觉反馈
                         } completion:^(BOOL finished) {
                             // 恢复正常大小
                             [UIView animateWithDuration:0.1 animations:^{
                                 self.transform = CGAffineTransformIdentity;
                             }];
                             
                             // 再次确认视觉状态正确
                             [self updateVisualIndicators];
                         }];
    } else {
        self.frame = expandedFrame;
        self.alpha = 1.0;
        // 确保视觉状态正确
        [self updateVisualIndicators];
    }
    
    // 更新保存的位置
    [NSUserDefaults.standardUserDefaults setObject:NSStringFromCGPoint(CGPointMake(targetX, targetY)) 
        forKey:@"DYYYHideUIButtonPosition"];
    
    // 重置淡出定时器
    [self resetFadeTimer];
    [self resetReattachTimer];
}

- (void)resetReattachTimer {
    // 取消现有定时器
    [self.reattachTimer invalidate];
    
    // 如果已经处于吸附状态或锁定状态(只检查按钮锁定，不检查位置锁定)，不需要设置自动吸附定时器
    if (self.isStickToEdge || self.isLocked) return;
    
    // 如果之前是吸附状态，设置自动重新吸附定时器
    if (self.wasStickToEdge) {
        self.reattachTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
            // 检查距离最后一次触摸是否已经过去2.5秒(减少等待时间)
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
            if (currentTime - self.lastTouchTime >= 2.5) {
                // 直接尝试执行吸附，不再检查其他条件
                [self performAutoReattach];
            } else {
                // 如果时间不够，重新安排定时器
                [self resetReattachTimer];
            }
        }];
        
        // 确保定时器在滚动时也能触发
        [[NSRunLoop mainRunLoop] addTimer:self.reattachTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)resetFadeTimer {
    [self.fadeTimer invalidate];
    
    // 如果已经吸附到边缘，不设置淡出定时器
    if (self.isStickToEdge) return;
    
    self.fadeTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [UIView animateWithDuration:0.3 animations:^{ 
            self.alpha = 0.6; 
        }];
    }];
    
    if (self.alpha != 1.0) {
        [UIView animateWithDuration:0.2 animations:^{ 
            self.alpha = 1.0; 
        }];
    }
}

- (void)startPeriodicCheck {
    [self.checkTimer invalidate];
    
    self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (self.isElementsHidden) [self hideUIElements];
    }];
    
    // 提高定时器优先级，避免界面滚动时卡顿
    [[NSRunLoop mainRunLoop] addTimer:self.checkTimer forMode:NSRunLoopCommonModes];
}

- (void)savePositionLockState {
    [NSUserDefaults.standardUserDefaults setBool:self.isPositionLocked forKey:@"DYYYHideUIButtonPositionLockState"];
}

- (void)loadPositionLockState {
    self.isPositionLocked = [NSUserDefaults.standardUserDefaults boolForKey:@"DYYYHideUIButtonPositionLockState"];
}

- (void)saveLockState {
    [NSUserDefaults.standardUserDefaults setBool:self.isLocked forKey:@"DYYYHideUIButtonLockState"];
}

- (void)loadLockState {
    self.isLocked = [NSUserDefaults.standardUserDefaults boolForKey:@"DYYYHideUIButtonLockState"];
}

- (void)safeResetState {
    forceResetAllUIElements();
    self.isElementsHidden = NO;
    self.selected = NO;
    [self.hiddenViewsList removeAllObjects];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self updateLastTouchTime];
}

- (void)dealloc {
    [_checkTimer invalidate];
    [_fadeTimer invalidate];
    [_reattachTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

#pragma mark - Hook Section
%hook UIView
- (id)initWithFrame:(CGRect)frame {
    id view = %orig;
    if (hideButton && hideButton.isElementsHidden) {
        for (NSString *className in targetClassNames) {
            if ([view isKindOfClass:NSClassFromString(className)]) {
                [(UIView *)view setAlpha:0.0];
                break;
            }
        }
    }
    return view;
}

- (void)didAddSubview:(UIView *)subview {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        for (NSString *className in targetClassNames) {
            if ([subview isKindOfClass:NSClassFromString(className)]) {
                subview.alpha = 0.0;
                break;
            }
        }
    }
}
%end

%hook AWEFeedTableViewCell
- (void)prepareForReuse {
    %orig;
    if (hideButton.isElementsHidden) [hideButton hideUIElements];
}

- (void)layoutSubviews {
    %orig;
    if (hideButton.isElementsHidden) [hideButton hideUIElements];
}
%end

%hook AWEFeedViewCell
- (void)layoutSubviews {
    %orig;
    if (hideButton.isElementsHidden) [hideButton hideUIElements];
}

- (void)setModel:(id)model {
    %orig;
    if (hideButton.isElementsHidden) [hideButton hideUIElements];
}
%end

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        isAppInTransition = NO;
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        isAppInTransition = NO;
    });
}
%end

%hook AWEFeedContainerViewController
- (void)aweme:(id)arg1 currentIndexWillChange:(NSInteger)arg2 {
    %orig;
    if (hideButton.isElementsHidden) [hideButton hideUIElements];
}

- (void)aweme:(id)arg1 currentIndexDidChange:(NSInteger)arg2 {
    %orig;
    if (hideButton.isElementsHidden) [hideButton hideUIElements];
}

- (void)viewWillLayoutSubviews {
    %orig;
    if (hideButton.isElementsHidden) [hideButton hideUIElements];
}
%end

%hook AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    BOOL result = %orig;
    initTargetClassNames();
    
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"DYYYEnableFloatClearButton"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 移除可能存在的旧按钮
            if (hideButton) [hideButton removeFromSuperview];
            
            // 创建新按钮
            hideButton = [[HideUIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
            
            // 设置位置（如果之前有保存过的话）
            NSString *savedPos = [NSUserDefaults.standardUserDefaults stringForKey:@"DYYYHideUIButtonPosition"];
            hideButton.center = savedPos ? CGPointFromString(savedPos) : 
                CGPointMake(UIScreen.mainScreen.bounds.size.width - 40, UIScreen.mainScreen.bounds.size.height/2);
            
            // 添加进入动画
            hideButton.alpha = 0;
            hideButton.transform = CGAffineTransformMakeScale(0.5, 0.5);
            [getKeyWindow() addSubview:hideButton];
            
            [UIView animateWithDuration:0.3 
                                  delay:0.2 
                                options:UIViewAnimationOptionCurveEaseOut 
                             animations:^{
                hideButton.alpha = 1.0;
                hideButton.transform = CGAffineTransformIdentity;
            } completion:nil];
        });
    }
    return result;
}
%end

%ctor {
    signal(SIGSEGV, SIG_IGN);
}
