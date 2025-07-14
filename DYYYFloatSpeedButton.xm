#import "AwemeHeaders.h"
#import "DYYYFloatSpeedButton.h"
#import "DYYYUtils.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@class AWEFeedCellViewController;

static FloatingSpeedButton *speedButton = nil;
static BOOL isCommentViewVisible = NO;
static BOOL showSpeedX = NO;
static CGFloat speedButtonSize = 32.0;
static BOOL isFloatSpeedButtonEnabled = NO;
static BOOL isForceHidden = NO;
static BOOL isInteractionViewVisible = NO;

NSArray *getSpeedOptions() {
    NSString *speedConfig = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYSpeedSettings"] ?: @"1.0,1.25,1.5,2.0";
    return [speedConfig componentsSeparatedByString:@","];
}

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

float getCurrentSpeed() {
    NSArray *speeds = getSpeedOptions();
    NSInteger index = getCurrentSpeedIndex();

    if (speeds.count == 0)
        return 1.0;
    float speed = [speeds[index] floatValue];
    return speed > 0 ? speed : 1.0;
}

void setCurrentSpeedIndex(NSInteger index) {
    NSArray *speeds = getSpeedOptions();

    if (speeds.count == 0)
        return;
    index = index % speeds.count;

    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"DYYYCurrentSpeedIndex"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

void updateSpeedButtonUI() {
    if (!speedButton)
        return;

    float currentSpeed = getCurrentSpeed();

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

    if (showSpeedX) {
        formattedSpeed = [formattedSpeed stringByAppendingString:@"x"];
    }

    if ([NSThread isMainThread]) {
        [speedButton setTitle:formattedSpeed forState:UIControlStateNormal];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          [speedButton setTitle:formattedSpeed forState:UIControlStateNormal];
        });
    }
}

FloatingSpeedButton *getSpeedButton(void) { return speedButton; }

NSArray *findViewControllersInHierarchy(UIViewController *rootViewController) {
    NSMutableArray *viewControllers = [NSMutableArray array];
    [viewControllers addObject:rootViewController];

    for (UIViewController *childVC in rootViewController.childViewControllers) {
        [viewControllers addObjectsFromArray:findViewControllersInHierarchy(childVC)];
    }

    return viewControllers;
}

void showSpeedButton(void) { isForceHidden = NO; }

void hideSpeedButton(void) {
    isForceHidden = YES;
    if (speedButton) {
        if ([NSThread isMainThread]) {
            speedButton.hidden = YES;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
              speedButton.hidden = YES;
            });
        }
    }
}

void updateSpeedButtonVisibility() {
    if (!speedButton || !isFloatSpeedButtonEnabled)
        return;

    // 如果已经在主线程，直接执行；否则异步到主线程
    if ([NSThread isMainThread]) {
        if (!isInteractionViewVisible) {
            speedButton.hidden = YES;
            return;
        }

        // 在交互界面时，根据评论界面状态决定是否显示
        BOOL shouldHide = isCommentViewVisible || isForceHidden;
        if (speedButton.hidden != shouldHide) {
            speedButton.hidden = shouldHide;
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (!isInteractionViewVisible) {
              speedButton.hidden = YES;
              return;
          }

          // 在交互界面时，根据评论界面状态决定是否显示
          BOOL shouldHide = isCommentViewVisible || isForceHidden;
          if (speedButton.hidden != shouldHide) {
              speedButton.hidden = shouldHide;
          }
        });
    }
}

@interface UIView (SpeedHelper)
- (UIViewController *)firstAvailableUIViewController;
@end

@implementation FloatingSpeedButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.accessibilityLabel = @"DYYYSpeedSwitchButton";
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;

        [self setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.3] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:15];

        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.2;

        self.userInteractionEnabled = YES;
        self.isResponding = YES;

        self.originalAlpha = 1.0;
        self.alpha = 0.5;

        [self resetFadeTimer];

        self.statusCheckTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkAndRecoverButtonStatus) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.statusCheckTimer forMode:NSRunLoopCommonModes];

        [self setupGestureRecognizers];

        [self loadSavedPosition];

        self.justToggledLock = NO;
    }
    return self;
}
- (void)setupGestureRecognizers {
    for (UIGestureRecognizer *recognizer in [self.gestureRecognizers copy]) {
        [self removeGestureRecognizer:recognizer];
    }

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:panGesture];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration = 0.5;
    [self addGestureRecognizer:longPressGesture];

    [self addTarget:self action:@selector(handleTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(handleTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(handleTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];

    panGesture.delegate = (id<UIGestureRecognizerDelegate>)self;
    longPressGesture.delegate = (id<UIGestureRecognizerDelegate>)self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

- (void)handleTouchDown:(UIButton *)sender {
    self.isResponding = YES;
    [self resetFadeTimer];
}

- (void)handleTouchUpInside:(UIButton *)sender {
    if (self.justToggledLock) {
        self.justToggledLock = NO;
        return;
    }

    [self resetFadeTimer];

    [UIView animateWithDuration:0.08
        animations:^{
          self.transform = CGAffineTransformMakeScale(1.15, 1.15);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.08
                           animations:^{
                             self.transform = CGAffineTransformIdentity;
                           }];
        }];

    if (self.interactionController) {
        @try {
            [self.interactionController speedButtonTapped:self];
        } @catch (NSException *exception) {
            self.isResponding = NO;
        }
    } else {
        self.isResponding = NO;
    }
}

- (void)handleTouchUpOutside:(UIButton *)sender {
    self.justToggledLock = NO;
    [self resetFadeTimer];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    self.isResponding = YES;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self resetFadeTimer];

        self.originalLockState = self.isLocked;

        [self toggleLockState];
    }
}

- (void)toggleLockState {
    self.isLocked = !self.isLocked;
    self.justToggledLock = YES;

    NSString *toastMessage = self.isLocked ? @"按钮已锁定" : @"按钮已解锁";
    [DYYYUtils showToast:toastMessage];

    if (self.isLocked) {
        [self saveButtonPosition];
    }

    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      self.justToggledLock = NO;
    });
}

- (void)resetToggleLockFlag {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.justToggledLock = NO;
    });
}

- (void)resetButtonState {
    self.justToggledLock = NO;
    self.isResponding = YES;
    self.userInteractionEnabled = YES;
    self.transform = CGAffineTransformIdentity;
    self.alpha = self.originalAlpha;

    [self resetFadeTimer];

    [self setupGestureRecognizers];
}

- (void)resetFadeTimer {
    [self.fadeTimer invalidate];
    self.fadeTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                     repeats:NO
                                                       block:^(NSTimer *timer) {
                                                         [UIView animateWithDuration:0.3
                                                                          animations:^{
                                                                            self.alpha = 0.5;
                                                                          }];
                                                       }];

    if (self.alpha != self.originalAlpha) {
        [UIView animateWithDuration:0.2
                         animations:^{
                           self.alpha = self.originalAlpha;
                         }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if (self.isLocked)
        return;

    self.justToggledLock = NO;
    [self resetFadeTimer];

    CGPoint touchPoint = [pan locationInView:self.superview];

    if (pan.state == UIGestureRecognizerStateBegan) {
        self.lastLocation = self.center;
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [pan translationInView:self.superview];
        CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);

        newCenter.x = MAX(self.frame.size.width / 2, MIN(newCenter.x, self.superview.frame.size.width - self.frame.size.width / 2));
        newCenter.y = MAX(self.frame.size.height / 2, MIN(newCenter.y, self.superview.frame.size.height - self.frame.size.height / 2));

        self.center = newCenter;
        [pan setTranslation:CGPointZero inView:self.superview];

        self.alpha = 0.8;
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        self.alpha = self.originalAlpha;
        [self saveButtonPosition];
    }
}

- (void)saveButtonPosition {
    if (self.superview) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setFloat:self.center.x / self.superview.bounds.size.width forKey:@"DYYYSpeedButtonCenterXPercent"];
        [defaults setFloat:self.center.y / self.superview.bounds.size.height forKey:@"DYYYSpeedButtonCenterYPercent"];
        [defaults setBool:self.isLocked forKey:@"DYYYSpeedButtonLocked"];
        [defaults synchronize];
    }
}

- (void)loadSavedPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float centerXPercent = [defaults floatForKey:@"DYYYSpeedButtonCenterXPercent"];
    float centerYPercent = [defaults floatForKey:@"DYYYSpeedButtonCenterYPercent"];

    self.isLocked = [defaults boolForKey:@"DYYYSpeedButtonLocked"];

    if (centerXPercent > 0 && centerYPercent > 0 && self.superview) {
        self.center = CGPointMake(centerXPercent * self.superview.bounds.size.width, centerYPercent * self.superview.bounds.size.height);
    }
}

- (void)checkAndRecoverButtonStatus {
    if (!self.isResponding) {
        [self resetButtonState];
        [self setupGestureRecognizers];
        self.isResponding = YES;
    }

    if (!self.interactionController) {
        UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topVC.presentedViewController) {
            topVC = topVC.presentedViewController;
        }

        for (UIViewController *vc in findViewControllersInHierarchy(topVC)) {
            if ([vc isKindOfClass:%c(AWEPlayInteractionViewController)]) {
                self.interactionController = (AWEPlayInteractionViewController *)vc;
                break;
            }
        }
    }
}

- (void)dealloc {
    if (self.statusCheckTimer && [self.statusCheckTimer isValid]) {
        [self.statusCheckTimer invalidate];
    }
    if (self.fadeTimer && [self.fadeTimer isValid]) {
        [self.fadeTimer invalidate];
    }
}
@end

%hook AWEElementStackView

- (void)setAlpha:(CGFloat)alpha {
    %orig;

    if (speedButton && isFloatSpeedButtonEnabled) {
        if (alpha == 0) {
            isCommentViewVisible = YES;
        } else if (alpha == 1) {
            isCommentViewVisible = NO;
        }
        updateSpeedButtonVisibility();
    }
}

%end

@interface AWEAwemePlayVideoViewController (SpeedControl)
- (void)adjustPlaybackSpeed:(float)speed;
@end

@interface AWEDPlayerFeedPlayerViewController (SpeedControl)
- (void)adjustPlaybackSpeed:(float)speed;
@end

%hook AWEAwemePlayVideoViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
    %orig(arg0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
          float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];

          if (defaultSpeed > 0 && defaultSpeed != 1) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [self setVideoControllerPlaybackRate:defaultSpeed];
              });
          }
      }
      float speed = getCurrentSpeed();
      if (speed != 1.0) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self adjustPlaybackSpeed:speed];
          });
      }
    });
}

- (void)prepareForDisplay {
    %orig;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      BOOL autoRestoreSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
      if (autoRestoreSpeed) {
          setCurrentSpeedIndex(0);
      }
      float speed = getCurrentSpeed();
      if (speed != 1.0) {
          [self adjustPlaybackSpeed:speed];
      }
      updateSpeedButtonUI();
    });
}

%new
- (void)adjustPlaybackSpeed:(float)speed {
    [self setVideoControllerPlaybackRate:speed];
}

%end

%hook AWEDPlayerFeedPlayerViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
    %orig(arg0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
          float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];

          if (defaultSpeed > 0 && defaultSpeed != 1) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [self setVideoControllerPlaybackRate:defaultSpeed];
              });
          }
      }
      float speed = getCurrentSpeed();
      if (speed != 1.0) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self adjustPlaybackSpeed:speed];
          });
      }
    });
}

- (void)prepareForDisplay {
    %orig;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      BOOL autoRestoreSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
      if (autoRestoreSpeed) {
          setCurrentSpeedIndex(0);
      }
      float speed = getCurrentSpeed();
      if (speed != 1.0) {
          [self adjustPlaybackSpeed:speed];
      }
      updateSpeedButtonUI();
    });
}

%new
- (void)adjustPlaybackSpeed:(float)speed {
    [self setVideoControllerPlaybackRate:speed];
}

%end

%hook AWECommentContainerViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    isCommentViewVisible = YES;
    updateSpeedButtonVisibility();
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    isCommentViewVisible = NO;
    updateSpeedButtonVisibility();
}

%end

%hook AWEPlayInteractionViewController

- (void)viewDidLayoutSubviews {
    %orig;
    if (!isFloatSpeedButtonEnabled)
        return;
    BOOL hasRightStack = NO;
    Class stackClass = NSClassFromString(@"AWEElementStackView");
    for (UIView *sub in self.view.subviews) {
        if ([sub isKindOfClass:stackClass] && ([sub.accessibilityLabel isEqualToString:@"right"] || [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEPlayInteractionUserAvatarView")
                                                                                                                               inView:self.view])) {
            hasRightStack = YES;
            break;
        }
    }
    if (hasRightStack) {
        if (speedButton == nil) {
            speedButtonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYSpeedButtonSize"] ?: 32.0;

            CGRect screenBounds = [UIScreen mainScreen].bounds;
            CGRect initialFrame = CGRectMake((screenBounds.size.width - speedButtonSize) / 2, (screenBounds.size.height - speedButtonSize) / 2, speedButtonSize, speedButtonSize);

            speedButton = [[FloatingSpeedButton alloc] initWithFrame:initialFrame];

            speedButton.interactionController = self;

            showSpeedX = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYSpeedButtonShowX"];

            updateSpeedButtonUI();
        } else {
            [speedButton resetButtonState];

            if (speedButton.interactionController == nil || speedButton.interactionController != self) {
                speedButton.interactionController = self;
            }

            if (speedButton.frame.size.width != speedButtonSize) {
                CGPoint center = speedButton.center;
                CGRect newFrame = CGRectMake(0, 0, speedButtonSize, speedButtonSize);
                speedButton.frame = newFrame;
                speedButton.center = center;
                speedButton.layer.cornerRadius = speedButtonSize / 2;
            }
        }

        isInteractionViewVisible = YES;

        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (keyWindow && ![speedButton isDescendantOfView:keyWindow]) {
            [keyWindow addSubview:speedButton];
            [speedButton loadSavedPosition];
            [speedButton resetFadeTimer];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    BOOL hasRightStack = NO;
    Class stackClass = NSClassFromString(@"AWEElementStackView");
    for (UIView *sub in self.view.subviews) {
        if ([sub isKindOfClass:stackClass] && ([sub.accessibilityLabel isEqualToString:@"right"] || [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEPlayInteractionUserAvatarView")
                                                                                                                               inView:self.view])) {
            hasRightStack = YES;
            break;
        }
    }
    if (hasRightStack) {
        isInteractionViewVisible = NO;
        isCommentViewVisible = self.isCommentVCShowing;
        updateSpeedButtonVisibility();
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
    [(FloatingSpeedButton *)sender resetFadeTimer];
    NSArray *speeds = getSpeedOptions();
    if (speeds.count == 0)
        return;

    NSInteger currentIndex = getCurrentSpeedIndex();
    NSInteger newIndex = (currentIndex + 1) % speeds.count;

    setCurrentSpeedIndex(newIndex);

    float newSpeed = [speeds[newIndex] floatValue];

    NSString *formattedSpeed;
    if (fmodf(newSpeed, 1.0) == 0) {
        formattedSpeed = [NSString stringWithFormat:@"%.0f", newSpeed];
    } else if (fmodf(newSpeed * 10, 1.0) == 0) {
        formattedSpeed = [NSString stringWithFormat:@"%.1f", newSpeed];
    } else {
        formattedSpeed = [NSString stringWithFormat:@"%.2f", newSpeed];
    }

    if (showSpeedX) {
        formattedSpeed = [formattedSpeed stringByAppendingString:@"x"];
    }

    [sender setTitle:formattedSpeed forState:UIControlStateNormal];

    [UIView animateWithDuration:0.1
        delay:0
        options:UIViewAnimationOptionCurveEaseOut
        animations:^{
          sender.transform = CGAffineTransformMakeScale(1.1, 1.1);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.1
                                delay:0
                              options:UIViewAnimationOptionCurveEaseIn
                           animations:^{
                             sender.transform = CGAffineTransformIdentity;
                           }
                           completion:nil];
        }];

    BOOL speedApplied = NO;

    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }

    NSArray *viewControllers = findViewControllersInHierarchy(rootVC);

    for (UIViewController *vc in viewControllers) {
        if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            [(AWEAwemePlayVideoViewController *)vc setVideoControllerPlaybackRate:newSpeed];
            speedApplied = YES;
        }
        if ([vc isKindOfClass:%c(AWEDPlayerFeedPlayerViewController)]) {
            [(AWEDPlayerFeedPlayerViewController *)vc setVideoControllerPlaybackRate:newSpeed];
            speedApplied = YES;
        }
    }

    if (!speedApplied) {
        [DYYYUtils showToast:@"无法找到视频控制器"];
    }
}

%new
- (void)buttonTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1
                     animations:^{
                       sender.alpha = 0.7;
                       sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
                     }];
}

%new
- (void)buttonTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.1
                     animations:^{
                       sender.alpha = 1.0;
                       sender.transform = CGAffineTransformIdentity;
                     }];
}

%end

%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;

    if (!isFloatSpeedButtonEnabled)
        return;

    if (speedButton && ![speedButton isDescendantOfView:self]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self addSubview:speedButton];
          [speedButton loadSavedPosition];
          [speedButton resetFadeTimer];
        });
    }
}
%end

%ctor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    isFloatSpeedButtonEnabled = [defaults boolForKey:@"DYYYEnableFloatSpeedButton"];
    %init;
}
