#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"
#import "DYYYManager.h"

@class AWEFeedCellViewController;
@class AWEAwemePlayVideoViewController; 

// 声明悬浮按钮类
@interface FloatingSpeedButton : UIButton
@property (nonatomic, assign) CGPoint lastLocation;
@property (nonatomic, weak) AWEPlayInteractionViewController *interactionController;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, strong) NSTimer *firstStageTimer; 
@property (nonatomic, assign) BOOL justToggledLock; 
@property (nonatomic, assign) BOOL originalLockState; 
@property (nonatomic, assign) BOOL isResponding; 
@property (nonatomic, strong) NSTimer *statusCheckTimer; 
- (void)saveButtonPosition;
- (void)loadSavedPosition;
- (void)resetButtonState; 
- (void)toggleLockState; 
@end

@implementation FloatingSpeedButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.accessibilityLabel = @"speedSwitchButton";
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
        
        [self setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.3] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.5;
        
        // 确保用户交互始终启用
        self.userInteractionEnabled = YES;
        
        // 初始化响应状态为YES
        self.isResponding = YES;
        
        self.statusCheckTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                                 target:self
                                                               selector:@selector(checkAndRecoverButtonStatus)
                                                               userInfo:nil
                                                                repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.statusCheckTimer forMode:NSRunLoopCommonModes];
        
        // 使用单独的方法初始化手势，便于复用
        [self setupGestureRecognizers];
        
        // justToggledLock总是初始化为NO
        self.justToggledLock = NO;
    }
    return self;
}
- (void)setupGestureRecognizers {
    // 移除所有现有手势识别器，避免重复添加
    for (UIGestureRecognizer *recognizer in [self.gestureRecognizers copy]) {
        [self removeGestureRecognizer:recognizer];
    }
    
    // 重新添加拖拽手势 - 不再设置优先级依赖
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:panGesture];
    
    // 重新添加长按手势
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration = 0.5;
    [self addGestureRecognizer:longPressGesture];
    
    // 使用触摸事件而不是单击手势来处理点击
    [self addTarget:self action:@selector(handleTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(handleTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(handleTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    
    // 设置代理
    panGesture.delegate = (id<UIGestureRecognizerDelegate>)self;
    longPressGesture.delegate = (id<UIGestureRecognizerDelegate>)self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

// 添加触摸事件处理方法
- (void)handleTouchDown:(UIButton *)sender {
    // 标记按钮响应状态
    self.isResponding = YES;
}

- (void)handleTouchUpInside:(UIButton *)sender {
    // 如果刚刚切换了锁定状态，不触发点击事件
    if (self.justToggledLock) {
        self.justToggledLock = NO; 
        return;
    }
    
    // 提供视觉反馈
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];
    
    // 确保控制器存在再调用方法
    if (self.interactionController) {
        @try {
            [self.interactionController speedButtonTapped:self];
        }
        @catch (NSException *exception) {
            self.isResponding = NO;
        }
    } else {
        self.isResponding = NO;
    }
}

- (void)handleTouchUpOutside:(UIButton *)sender {
    // 重置可能的状态
    self.justToggledLock = NO;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    // 标记按钮响应状态
    self.isResponding = YES;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // 取消可能存在的先前定时器
        if (self.firstStageTimer && [self.firstStageTimer isValid]) {
            [self.firstStageTimer invalidate];
            self.firstStageTimer = nil;
        }
        
        // 保存原始锁定状态
        self.originalLockState = self.isLocked;
        
        // 直接执行长按操作，不使用分阶段计时器
        [self toggleLockState];
    }
}

- (void)toggleLockState {
    // 切换锁定状态
    self.isLocked = !self.isLocked;
    self.justToggledLock = YES;
    
    // 显示锁定/解锁提示
    NSString *toastMessage = self.isLocked ? @"按钮已锁定" : @"按钮已解锁";
    [DYYYManager showToast:toastMessage];
    
    // 如果锁定了，保存当前位置
    if (self.isLocked) {
        [self saveButtonPosition];
    }
    
    // 触觉反馈
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
    
    // 使用主线程延迟重置锁定标志
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.justToggledLock = NO;
    });
}

- (void)resetToggleLockFlag {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.justToggledLock = NO;
    });
}

// 添加方法确保按钮状态可以被重置
- (void)resetButtonState {
    self.justToggledLock = NO;
    self.isResponding = YES;
    self.userInteractionEnabled = YES;
    self.transform = CGAffineTransformIdentity;
    self.alpha = 1.0;
    
    // 重新设置手势识别器
    [self setupGestureRecognizers];
}

// 优化拖拽手势处理函数
- (void)handlePan:(UIPanGestureRecognizer *)pan {
    // 如果按钮被锁定，不执行拖动
    if (self.isLocked) return;
    
    // 拖动时确保 justToggledLock 为 NO，避免影响后续点击
    self.justToggledLock = NO;

    CGPoint touchPoint = [pan locationInView:self.superview];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.lastLocation = self.center;
    } 
    else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [pan translationInView:self.superview];
        CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        
        // 边界检查
        newCenter.x = MAX(self.frame.size.width / 2, MIN(newCenter.x, self.superview.frame.size.width - self.frame.size.width / 2));
        newCenter.y = MAX(self.frame.size.height / 2, MIN(newCenter.y, self.superview.frame.size.height - self.frame.size.height / 2));
        
        self.center = newCenter;
        [pan setTranslation:CGPointZero inView:self.superview];
        
        // 增加透明度变化提供视觉反馈
        self.alpha = 0.8;
    } 
    else if (pan.state == UIGestureRecognizerStateEnded || 
             pan.state == UIGestureRecognizerStateCancelled) {
        // 恢复透明度
        self.alpha = 1.0;
        [self saveButtonPosition];
    }
}

- (void)saveButtonPosition {
    if (self.superview) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // 修改为相对于父视图的百分比位置
        [defaults setFloat:self.center.x / self.superview.bounds.size.width forKey:@"DYYYSpeedButtonCenterXPercent"];
        [defaults setFloat:self.center.y / self.superview.bounds.size.height forKey:@"DYYYSpeedButtonCenterYPercent"];
        // 保存锁定状态
        [defaults setBool:self.isLocked forKey:@"DYYYSpeedButtonLocked"];
        [defaults synchronize];
    }
}

- (void)loadSavedPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float centerXPercent = [defaults floatForKey:@"DYYYSpeedButtonCenterXPercent"];
    float centerYPercent = [defaults floatForKey:@"DYYYSpeedButtonCenterYPercent"];
    
    // 加载锁定状态
    self.isLocked = [defaults boolForKey:@"DYYYSpeedButtonLocked"];
    
    if (centerXPercent > 0 && centerYPercent > 0 && self.superview) {
        self.center = CGPointMake(centerXPercent * self.superview.bounds.size.width,
                                  centerYPercent * self.superview.bounds.size.height);
    } else if (self.superview) {
        // 默认位置：右下角安全区域
        CGFloat margin = 20.0;
        CGFloat safeBottomMargin = 0;
        if (@available(iOS 11.0, *)) {
            safeBottomMargin = self.superview.safeAreaInsets.bottom;
        }
        self.center = CGPointMake(self.superview.bounds.size.width - self.bounds.size.width - margin, 
                                  self.superview.bounds.size.height - self.bounds.size.height - margin - safeBottomMargin);
    }
}

// 状态检查和恢复方法
- (void)checkAndRecoverButtonStatus {
    if (!self.isResponding) {
        // 如果已经检测到按钮无响应，尝试恢复
        [self resetButtonState];
        [self setupGestureRecognizers];
        self.isResponding = YES;
    }
    
    // 验证控制器引用是否有效
    if (!self.interactionController) {
        UIResponder *responder = self.superview.nextResponder;
        while (responder) {
            if ([responder isKindOfClass:%c(AWEPlayInteractionViewController)]) {
                self.interactionController = (AWEPlayInteractionViewController *)responder;
                break;
            }
            responder = responder.nextResponder;
        }
    }
}

// 查找视图控制器层级
- (NSArray *)findViewControllersInHierarchy:(UIViewController *)rootViewController {
    NSMutableArray *viewControllers = [NSMutableArray array];
    [viewControllers addObject:rootViewController];
    
    for (UIViewController *childVC in rootViewController.childViewControllers) {
        [viewControllers addObjectsFromArray:[self findViewControllersInHierarchy:childVC]];
    }
    
    return viewControllers;
}

// 防止内存泄漏，确保定时器释放
- (void)dealloc {
    if (self.firstStageTimer && [self.firstStageTimer isValid]) {
        [self.firstStageTimer invalidate];
    }
    if (self.statusCheckTimer && [self.statusCheckTimer isValid]) {
        [self.statusCheckTimer invalidate];
    }
}
@end

static AWEAwemePlayVideoViewController *currentVideoController = nil;
static FloatingSpeedButton *speedButton = nil;

static BOOL isCommentViewVisible = NO;
static BOOL showSpeedX = NO;
// 按钮大小变量
static CGFloat speedButtonSize = 32.0;
static BOOL isFloatSpeedButtonEnabled = NO;

%hook AWECommentContainerViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 当评论界面即将显示时，设置标记为YES并隐藏按钮
    isCommentViewVisible = YES;
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = YES;
        });
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    // 评论界面完全显示后，再次确认按钮隐藏状态
    isCommentViewVisible = YES;
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = YES;
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    // 评论界面开始消失时，仍然保持按钮隐藏状态
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = YES;
        });
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    // 评论界面完全消失后，才设置标记为NO并恢复按钮显示
    isCommentViewVisible = NO;
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = NO;
        });
    }
}

// 处理视图布局完成情况
- (void)viewDidLayoutSubviews {
    %orig;
    // 在视图布局期间，保持按钮隐藏
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = YES;
        });
    }
}

%end

// 获取倍速配置
NSArray* getSpeedOptions() {
    NSString *speedConfig = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYSpeedSettings"] ?: @"1.0,1.25,1.5,2.0";
    return [speedConfig componentsSeparatedByString:@","];
}

// 获取当前倍速索引
NSInteger getCurrentSpeedIndex() {
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYCurrentSpeedIndex"];
    NSArray *speeds = getSpeedOptions();
    
    if (index >= speeds.count || index < 0) {
        index = 0;
        [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"DYYYCurrentSpeedIndex"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return index;
}

// 获取当前倍速值
float getCurrentSpeed() {
    NSArray *speeds = getSpeedOptions();
    NSInteger index = getCurrentSpeedIndex();
    
    if (speeds.count == 0) return 1.0;
    float speed = [speeds[index] floatValue];
    return speed > 0 ? speed : 1.0;
}

// 设置倍速索引并保存
void setCurrentSpeedIndex(NSInteger index) {
    NSArray *speeds = getSpeedOptions();

    if (speeds.count == 0) return;
    index = index % speeds.count;
    
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"DYYYCurrentSpeedIndex"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

// 更新倍速按钮UI
void updateSpeedButtonUI() {
    if (!speedButton) return;
    
    float currentSpeed = getCurrentSpeed();
    
    // 更精确的格式控制
    NSString *formattedSpeed;
    if (fmodf(currentSpeed, 1.0) == 0) {
        // 整数值 (1.0, 2.0) -> "1", "2"
        formattedSpeed = [NSString stringWithFormat:@"%.0f", currentSpeed];
    } else if (fmodf(currentSpeed * 10, 1.0) == 0) {
        // 一位小数 (1.5) -> "1.5"
        formattedSpeed = [NSString stringWithFormat:@"%.1f", currentSpeed];
    } else {
        // 两位小数 (1.25) -> "1.25"
        formattedSpeed = [NSString stringWithFormat:@"%.2f", currentSpeed];
    }
    
    // 如果需要显示"x"，则添加"x"
    if (showSpeedX) {
        formattedSpeed = [formattedSpeed stringByAppendingString:@"x"];
    }
    
    [speedButton setTitle:formattedSpeed forState:UIControlStateNormal];
}

@interface AWEAwemePlayVideoViewController (SpeedControl)
- (void)adjustPlaybackSpeed:(float)speed;
@end


%hook AWEAwemePlayVideoViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
    // 检查是否启用了自动恢复第一个倍速的功能
    BOOL autoRestoreSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
    
    // 如果启用了自动恢复功能，则将当前索引设置为0（第一个速度）
    if (autoRestoreSpeed) {
        setCurrentSpeedIndex(0);
    }
    
    float speed = getCurrentSpeed();
    NSInteger speedIndex = getCurrentSpeedIndex();
    
    [self setVideoControllerPlaybackRate:speed];
    %orig(arg0);
    currentVideoController = self;
    
    updateSpeedButtonUI();
}

%new
- (void)adjustPlaybackSpeed:(float)speed {
    [self setVideoControllerPlaybackRate:speed];
}

%end


@interface UIView (SpeedHelper)
- (UIViewController *)firstAvailableUIViewController;
@end

%hook AWEPlayInteractionViewController

- (void)viewDidLayoutSubviews {
    %orig;

	if (!isFloatSpeedButtonEnabled) return;
    // 添加悬浮速度控制按钮作为子视图
    if (speedButton == nil) {
        // 使用保存的按钮大小或默认值
        speedButtonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYSpeedButtonSize"] ?: 32.0;
        
        // 初始位置设为右下角
        CGRect viewBounds = self.view.bounds;
        CGFloat margin = 20.0;
        CGFloat safeBottomMargin = 0;
        if (@available(iOS 11.0, *)) {
            safeBottomMargin = self.view.safeAreaInsets.bottom;
        }
        
        CGRect initialFrame = CGRectMake(
            viewBounds.size.width - speedButtonSize - margin, 
            viewBounds.size.height - speedButtonSize - margin - safeBottomMargin, 
            speedButtonSize, speedButtonSize);
        
        speedButton = [[FloatingSpeedButton alloc] initWithFrame:initialFrame];
        
        // 设置按钮的控制器引用
        speedButton.interactionController = self;
        
        // 加载"显示x"的设置
        showSpeedX = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYSpeedButtonShowX"];
        
        // 添加到控制器视图
        [self.view addSubview:speedButton];
        
        // 确保按钮在视图层次中保持顶层
        [self.view bringSubviewToFront:speedButton];
        
        // 加载保存的位置
        [speedButton loadSavedPosition];
        
        updateSpeedButtonUI();
    } else if (speedButton.superview != self.view) {
        // 如果按钮不在当前视图中，添加它
        [self.view addSubview:speedButton];
        [self.view bringSubviewToFront:speedButton];
        [speedButton loadSavedPosition];
    } else {
        // 重置按钮状态
        [speedButton resetButtonState];
        
        // 更新控制器引用
        if (speedButton.interactionController == nil || speedButton.interactionController != self) {
            speedButton.interactionController = self;
        }
        
        // 确保按钮保持在顶层
        [self.view bringSubviewToFront:speedButton];
        
        // 更新按钮大小如果有变化
        if (speedButton.frame.size.width != speedButtonSize) {
            CGPoint center = speedButton.center;
            CGRect newFrame = CGRectMake(0, 0, speedButtonSize, speedButtonSize);
            speedButton.frame = newFrame;
            speedButton.center = center;
            speedButton.layer.cornerRadius = speedButtonSize / 2;
        }
    }
    
    // 只在评论不可见时才显示按钮
    if (speedButton) {
        speedButton.hidden = isCommentViewVisible;
    }
    
    if (currentVideoController) {
        [currentVideoController adjustPlaybackSpeed:getCurrentSpeed()];
    } else {
        UIViewController *vc = [self firstAvailableUIViewController];
        while (vc && ![vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            vc = vc.parentViewController;
        }
        
        if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            AWEAwemePlayVideoViewController *videoVC = (AWEAwemePlayVideoViewController *)vc;
            [videoVC adjustPlaybackSpeed:getCurrentSpeed()];
            currentVideoController = videoVC;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 视图出现时显示按钮
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = isCommentViewVisible;
        });
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    // 确保按钮在视图层次中保持顶层
    if (speedButton && speedButton.superview == self.view) {
        [self.view bringSubviewToFront:speedButton];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    // 视图消失时隐藏按钮
    if (speedButton) {
        speedButton.hidden = YES;
    }
}

%new
- (UIViewController *)firstAvailableUIViewController {
    UIResponder *responder = [self.view nextResponder];
    while (responder != nil) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

%new
- (void)speedButtonTapped:(UIButton *)sender {
    // 切换到下一个倍速
    NSArray *speeds = getSpeedOptions();
    if (speeds.count == 0) return;
    
    NSInteger currentIndex = getCurrentSpeedIndex();
    NSInteger newIndex = (currentIndex + 1) % speeds.count;
    
    setCurrentSpeedIndex(newIndex);
    
    float newSpeed = [speeds[newIndex] floatValue];

    // 更精确的格式控制
    NSString *formattedSpeed;
    if (fmodf(newSpeed, 1.0) == 0) {
        // 整数值 (1.0, 2.0) -> "1", "2"
        formattedSpeed = [NSString stringWithFormat:@"%.0f", newSpeed];
    } else if (fmodf(newSpeed * 10, 1.0) == 0) {
        // 一位小数 (1.5) -> "1.5"
        formattedSpeed = [NSString stringWithFormat:@"%.1f", newSpeed];
    } else {
        // 两位小数 (1.25) -> "1.25"
        formattedSpeed = [NSString stringWithFormat:@"%.2f", newSpeed];
    }
    
    // 如果需要显示"x"，则添加"x"
    if (showSpeedX) {
        formattedSpeed = [formattedSpeed stringByAppendingString:@"x"];
    }
    
    [sender setTitle:formattedSpeed forState:UIControlStateNormal];
    
    // 按钮动画
    [UIView animateWithDuration:0.15 animations:^{
        sender.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];
    
    if (currentVideoController) {
        [currentVideoController adjustPlaybackSpeed:newSpeed];
    } else {
        UIViewController *vc = [self firstAvailableUIViewController];
        while (vc && ![vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            vc = vc.parentViewController;
        }
        
        if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            AWEAwemePlayVideoViewController *videoVC = (AWEAwemePlayVideoViewController *)vc;
            [videoVC adjustPlaybackSpeed:newSpeed];
            currentVideoController = videoVC;
        }
    }
}

%new
- (void)buttonTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.alpha = 0.7;
        sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
    }];
}

%new
- (void)buttonTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.alpha = 1.0;
        sender.transform = CGAffineTransformIdentity;
    }];
}

%end

%ctor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    isFloatSpeedButtonEnabled = [defaults boolForKey:@"DYYYEnableFloatSpeedButton"];
    
    if (isFloatSpeedButtonEnabled) {
        %init;
    }
}