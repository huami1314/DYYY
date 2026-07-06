#import "AwemeHeaders.h"
#import "DYYYFloatClearButton.h"
#import "DYYYFloatSpeedButton.h"
#import "DYYYUtils.h"
#import <UIKit/UIKit.h>
#import <float.h>
#import <math.h>
#import <objc/runtime.h>

@class AWEFeedCellViewController;

FloatingSpeedButton *speedButton = nil;
BOOL dyyyCommentViewVisible = NO;
BOOL showSpeedX = NO;
CGFloat speedButtonSize = 32.0;
BOOL isFloatSpeedButtonEnabled = NO;
BOOL speedButtonForceHidden = NO;
BOOL dyyyInteractionViewVisible = NO;

static NSString *const kDYYYDefaultSpeedSettingsString = @"0.75,1.0,1.25,1.5,2.0,2.5,3.0";

static void DYYYApplySpeedButtonHiddenState(UIView *button, BOOL hidden) {
    if (!button) {
        return;
    }
    void (^applyBlock)(UIView *) = ^(UIView *target) {
        if (!target) {
            return;
        }
        if (target.hidden != hidden) {
            target.hidden = hidden;
        }
    };

    if ([NSThread isMainThread]) {
        applyBlock(button);
    } else {
        __weak UIView *weakButton = button;
        dispatch_async(dispatch_get_main_queue(), ^{
            applyBlock(weakButton);
        });
    }
}

static BOOL DYYYShouldHideSpeedButton(void) {
    BOOL clearModeActive = (hideButton && hideButton.isElementsHidden);
    if (clearModeActive) {
        BOOL hideSpeedInClearMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSpeed"];
        if (hideSpeedInClearMode) {
            return YES;
        }
        return speedButtonForceHidden;
    }
    if (!dyyyInteractionViewVisible) {
        return YES;
    }
    if (dyyyCommentViewVisible) {
        return YES;
    }
    if (speedButtonForceHidden) {
        return YES;
    }
    return NO;
}

static NSString *DYYYFormatSpeedOption(double speed) {
    NSString *speedString = [NSString stringWithFormat:@"%.2f", speed];
    while ([speedString containsString:@"."] && [speedString hasSuffix:@"0"]) {
        speedString = [speedString substringToIndex:speedString.length - 1];
    }
    if ([speedString hasSuffix:@"."]) {
        speedString = [speedString substringToIndex:speedString.length - 1];
    }
    return speedString;
}

static BOOL DYYYSpeedValuesMatch(double lhs, double rhs) {
    return fabs(lhs - rhs) <= 0.001;
}

NSString *DYYYDefaultSpeedSettingsString(void) {
    return kDYYYDefaultSpeedSettingsString;
}

static NSString *DYYYSpeedSettingsStringFromValue(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [[value stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return nil;
}

static NSArray<NSString *> *DYYYParsedSpeedOptionsFromString(NSString *speedConfig) {
    NSMutableArray<NSString *> *validSpeeds = [NSMutableArray array];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    for (NSString *component in [speedConfig componentsSeparatedByString:@","]) {
        NSString *trimmedValue = [component stringByTrimmingCharactersInSet:whitespace];
        if (trimmedValue.length == 0) {
            continue;
        }

        NSScanner *scanner = [NSScanner scannerWithString:trimmedValue];
        double speed = 0.0;
        if ([scanner scanDouble:&speed] && scanner.isAtEnd && isfinite(speed) && speed > 0.0) {
            [validSpeeds addObject:DYYYFormatSpeedOption(speed)];
        }
    }
    return validSpeeds;
}

static double DYYYSpeedPreferenceValue(NSString *key, double fallback) {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    double speed = [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : fallback;
    if (!isfinite(speed) || speed <= 0.0) {
        return fallback;
    }
    return speed;
}

static BOOL DYYYSpeedOptionsContainSpeed(NSArray<NSString *> *speedOptions, double speed) {
    if (!isfinite(speed) || speed <= 0.0) {
        return YES;
    }

    for (NSString *speedString in speedOptions) {
        if (DYYYSpeedValuesMatch([speedString doubleValue], speed)) {
            return YES;
        }
    }
    return NO;
}

static BOOL DYYYSpeedOptionsCoverRequiredPlaybackSpeeds(NSArray<NSString *> *speedOptions) {
    double defaultSpeed = DYYYSpeedPreferenceValue(@"DYYYDefaultSpeed", 1.0);
    double longPressSpeed = DYYYSpeedPreferenceValue(@"DYYYLongPressSpeed", 2.0);
    return DYYYSpeedOptionsContainSpeed(speedOptions, defaultSpeed) &&
           DYYYSpeedOptionsContainSpeed(speedOptions, longPressSpeed);
}

BOOL DYYYNormalizeSpeedSettingsForRequiredSpeeds(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *speedConfig = DYYYSpeedSettingsStringFromValue([defaults objectForKey:@"DYYYSpeedSettings"]);
    NSArray<NSString *> *validSpeeds = DYYYParsedSpeedOptionsFromString(speedConfig ?: @"");
    BOOL shouldUseDefaultSettings = speedConfig.length == 0 ||
                                    validSpeeds.count == 0 ||
                                    !DYYYSpeedOptionsCoverRequiredPlaybackSpeeds(validSpeeds);

    if (!shouldUseDefaultSettings) {
        return NO;
    }

    if (![speedConfig isEqualToString:kDYYYDefaultSpeedSettingsString]) {
        [defaults setObject:kDYYYDefaultSpeedSettingsString forKey:@"DYYYSpeedSettings"];
        return YES;
    }
    return NO;
}

NSArray *getSpeedOptions() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    DYYYNormalizeSpeedSettingsForRequiredSpeeds();

    NSString *speedConfig = DYYYSpeedSettingsStringFromValue([defaults objectForKey:@"DYYYSpeedSettings"]) ?: kDYYYDefaultSpeedSettingsString;
    NSArray<NSString *> *validSpeeds = DYYYParsedSpeedOptionsFromString(speedConfig);
    if (validSpeeds.count == 0) {
        [defaults setObject:kDYYYDefaultSpeedSettingsString forKey:@"DYYYSpeedSettings"];
        validSpeeds = DYYYParsedSpeedOptionsFromString(kDYYYDefaultSpeedSettingsString);
    }

    return validSpeeds;
}

NSInteger getCurrentSpeedIndex() {
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYCurrentSpeedIndex"];
    NSArray *speeds = getSpeedOptions();

    if (index >= speeds.count || index < 0) {
        index = 0;
        [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"DYYYCurrentSpeedIndex"];
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
    if (index < 0) {
        index += speeds.count;
    }

    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"DYYYCurrentSpeedIndex"];
}

BOOL setCurrentSpeedValue(float speed) {
    if (!isfinite(speed) || speed <= 0.0f) {
        return NO;
    }

    NSArray *speeds = getSpeedOptions();
    for (NSInteger index = 0; index < speeds.count; index++) {
        if (DYYYSpeedValuesMatch([speeds[index] floatValue], speed)) {
            setCurrentSpeedIndex(index);
            return YES;
        }
    }
    return NO;
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
        __weak FloatingSpeedButton *weakButton = speedButton;
        dispatch_async(dispatch_get_main_queue(), ^{
          FloatingSpeedButton *strongButton = weakButton;
          if (!strongButton) {
              return;
          }
          [strongButton setTitle:formattedSpeed forState:UIControlStateNormal];
        });
    }
}

FloatingSpeedButton *getSpeedButton(void) { return speedButton; }

NSArray *findViewControllersInHierarchy(UIViewController *rootViewController) {
    if (!rootViewController) {
        return @[];
    }

    NSMutableArray *viewControllers = [NSMutableArray array];
    [viewControllers addObject:rootViewController];

    for (UIViewController *childVC in rootViewController.childViewControllers) {
        [viewControllers addObjectsFromArray:findViewControllersInHierarchy(childVC)];
    }

    return viewControllers;
}

void showSpeedButton(void) {
    speedButtonForceHidden = NO;
    updateSpeedButtonVisibility();
}

void hideSpeedButton(void) {
    speedButtonForceHidden = YES;
    updateSpeedButtonVisibility();
}

void updateSpeedButtonVisibility() {
    if (!speedButton)
        return;

    DYYYApplySpeedButtonHiddenState(speedButton, !isFloatSpeedButtonEnabled || DYYYShouldHideSpeedButton());
}

@implementation FloatingSpeedButton

+ (void)reloadConfiguration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    isFloatSpeedButtonEnabled = [defaults boolForKey:@"DYYYEnableFloatSpeedButton"];
    showSpeedX = [defaults boolForKey:@"DYYYSpeedButtonShowX"];

    CGFloat configuredSize = [defaults floatForKey:@"DYYYSpeedButtonSize"];
    if (configuredSize <= 0.0) {
        configuredSize = 32.0;
    }
    speedButtonSize = MIN(MAX(configuredSize, 20.0), 60.0);

    void (^applyBlock)(void) = ^{
      if (speedButton && fabs(speedButton.bounds.size.width - speedButtonSize) > FLT_EPSILON) {
          speedButton.bounds = CGRectMake(0, 0, speedButtonSize, speedButtonSize);
          speedButton.layer.cornerRadius = speedButtonSize / 2.0;
          [speedButton loadSavedPosition];
      }
      updateSpeedButtonUI();
      updateSpeedButtonVisibility();
    };

    if ([NSThread isMainThread]) {
        applyBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), applyBlock);
    }
}

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
        [self ensureStatusCheckTimerRunning];

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
    [self removeTarget:self action:@selector(handleTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self removeTarget:self action:@selector(handleTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self removeTarget:self action:@selector(handleTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];

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

    id currentController = DYYYCurrentSpeedInteractionController();
    if (currentController) {
        self.interactionController = currentController;
    }

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

    __weak __typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
          return;
      }
      strongSelf.justToggledLock = NO;
    });
}

- (void)resetToggleLockFlag {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
          return;
      }
      strongSelf.justToggledLock = NO;
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
    if (self.fadeTimer) {
        [self.fadeTimer invalidate];
        self.fadeTimer = nil;
    }
    __weak __typeof(self) weakSelf = self;
    NSTimer *fadeTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                         repeats:NO
                                                           block:^(NSTimer *timer) {
                                                             __strong __typeof(weakSelf) strongSelf = weakSelf;
                                                             if (!strongSelf) {
                                                                 return;
                                                             }
                                                             [UIView animateWithDuration:0.3
                                                                              animations:^{
                                                                                strongSelf.alpha = 0.5;
                                                                              }];
                                                             strongSelf.fadeTimer = nil;
                                                           }];
    self.fadeTimer = fadeTimer;

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
    }
}

- (void)loadSavedPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float centerXPercent = [defaults floatForKey:@"DYYYSpeedButtonCenterXPercent"];
    float centerYPercent = [defaults floatForKey:@"DYYYSpeedButtonCenterYPercent"];

    self.isLocked = [defaults boolForKey:@"DYYYSpeedButtonLocked"];

    if (centerXPercent > 0 && centerYPercent > 0 && self.superview) {
        CGFloat halfWidth = self.bounds.size.width / 2.0;
        CGFloat halfHeight = self.bounds.size.height / 2.0;
        CGFloat centerX = centerXPercent * self.superview.bounds.size.width;
        CGFloat centerY = centerYPercent * self.superview.bounds.size.height;
        centerX = MAX(halfWidth, MIN(centerX, self.superview.bounds.size.width - halfWidth));
        centerY = MAX(halfHeight, MIN(centerY, self.superview.bounds.size.height - halfHeight));
        self.center = CGPointMake(centerX, centerY);
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (!self.window) {
        [self stopTimers];
        return;
    }
    [self ensureStatusCheckTimerRunning];
    [self resetFadeTimer];
}

- (void)ensureStatusCheckTimerRunning {
    if (self.statusCheckTimer && [self.statusCheckTimer isValid]) {
        return;
    }
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkAndRecoverButtonStatus) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.statusCheckTimer = timer;
}

- (void)stopTimers {
    if (self.statusCheckTimer) {
        [self.statusCheckTimer invalidate];
        self.statusCheckTimer = nil;
    }
    if (self.fadeTimer) {
        [self.fadeTimer invalidate];
        self.fadeTimer = nil;
    }
}

- (void)checkAndRecoverButtonStatus {
    if (!self.isResponding) {
        [self resetButtonState];
        self.isResponding = YES;
    }

    if (!self.interactionController) {
        self.interactionController = DYYYCurrentSpeedInteractionController();
    }
}

- (void)dealloc {
    [self stopTimers];
}
@end
