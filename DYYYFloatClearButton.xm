/*
 * Tweak Name: 1KeyHideDYUI
 * Target App: com.ss.iphone.ugc.Aweme
 * Dev: @c00kiec00k 曲奇的坏品味🍻
 * iOS Version: 16.5
 */
#import "DYYYFloatSpeedButton.h"
#import "DYYYFloatClearButton.h"
#import "DYYYManager.h"
#import "DYYYUtils.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <signal.h>

void updateClearButtonVisibility(void);
void showClearButton(void);
void hideClearButton(void);

BOOL isInPlayInteractionVC = NO;
BOOL isPureViewVisible = NO;
BOOL clearButtonForceHidden = NO;
BOOL isAppActive = YES;


HideUIButton *hideButton;
BOOL isAppInTransition = NO;
NSArray *targetClassNames;
static CGFloat DYGetGlobalAlpha(void) {
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYGlobalTransparency"];
    CGFloat a = value.length ? value.floatValue : 1.0;
    return (a >= 0.0 && a <= 1.0) ? a : 1.0;
}
static void findViewsOfClassHelper(UIView *view, Class viewClass, NSMutableArray *result) {
    if ([view isKindOfClass:viewClass]) {
        [result addObject:view];
    }
    for (UIView *subview in view.subviews) {
        findViewsOfClassHelper(subview, viewClass, result);
    }
}
UIWindow *getKeyWindow(void) {
    UIWindow *keyWindow = nil;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    return keyWindow;
}

void updateClearButtonVisibility() {
    if (!hideButton || !isAppActive)
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
      if (!dyyyInteractionViewVisible) {
          hideButton.hidden = YES;
          return;
      }

      BOOL shouldHide = dyyyCommentViewVisible || clearButtonForceHidden || isPureViewVisible;
      if (hideButton.hidden != shouldHide) {
          hideButton.hidden = shouldHide;
      }
    });
}

void showClearButton(void) { clearButtonForceHidden = NO; }

void hideClearButton(void) {
    clearButtonForceHidden = YES;
    if (hideButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
          hideButton.hidden = YES;
        });
    }
}

static void forceResetAllUIElements(void) {
    UIWindow *window = getKeyWindow();
    if (!window)
        return;
    Class StackViewClass = NSClassFromString(@"AWEElementStackView");
    for (NSString *className in targetClassNames) {
        Class viewClass = NSClassFromString(className);
        if (!viewClass)
            continue;
        NSMutableArray *views = [NSMutableArray array];
        findViewsOfClassHelper(window, viewClass, views);
        for (UIView *view in views) {
            if ([view isKindOfClass:StackViewClass]) {
                view.alpha = DYGetGlobalAlpha();
            } else {
                view.alpha = 1.0; // 恢复透明度
            }
        }
    }
}
static void reapplyHidingToAllElements(HideUIButton *button) {
    if (!button || !button.isElementsHidden)
        return;
    [button hideUIElements];
}
void initTargetClassNames(void) {
    NSMutableArray<NSString *> *list = [@[
        @"AWEHPTopBarCTAContainer", @"AWEHPDiscoverFeedEntranceView", @"AWELeftSideBarEntranceView", @"DUXBadge", @"AWEBaseElementView", @"AWEElementStackView", @"AWEPlayInteractionDescriptionLabel",
        @"AWEUserNameLabel", @"ACCEditTagStickerView", @"AWEFeedTemplateAnchorView", @"AWESearchFeedTagView", @"AWEPlayInteractionSearchAnchorView", @"AFDRecommendToFriendTagView",
        @"AWELandscapeFeedEntryView", @"AWEFeedAnchorContainerView", @"AFDAIbumFolioView", @"DUXPopover", @"AWEMixVideoPanelMoreView", @"AWEHotSearchInnerBottomView"
    ] mutableCopy];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTabBar"]) {
        [list addObject:@"AWENormalModeTabBar"];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDanmaku"]) {
        [list addObject:@"AWEVideoPlayDanmakuContainerView"];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSlider"]) {
        [list addObject:@"AWEStoryProgressSlideView"];
        [list addObject:@"AWEStoryProgressContainerView"];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChapter"]) {
        [list addObject:@"AWEDemaciaChapterProgressSlider"];
    }

    targetClassNames = [list copy];
}
@implementation HideUIButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        self.isElementsHidden = NO;
        self.hiddenViewsList = [NSMutableArray array];

        // 设置默认状态为半透明
        self.originalAlpha = 1.0; // 交互时为完全不透明
        self.alpha = 0.5;         // 初始为半透明
        // 加载保存的锁定状态
        [self loadLockState];
        [self loadIcons];
        [self setImage:self.showIcon forState:UIControlStateNormal];
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(handleTouchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(handleTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(handleTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPressGesture];
        [self startPeriodicCheck];
        [self resetFadeTimer];

        // 初始状态下隐藏按钮，直到进入正确的控制器
        self.hidden = YES;
    }
    return self;
}
- (void)startPeriodicCheck {
    [self.checkTimer invalidate];
    self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                      repeats:YES
                                                        block:^(NSTimer *timer) {
                                                          if (self.isElementsHidden) {
                                                              [self hideUIElements];
                                                          }
                                                        }];
}
- (void)resetFadeTimer {
    [self.fadeTimer invalidate];
    self.fadeTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                     repeats:NO
                                                       block:^(NSTimer *timer) {
                                                         [UIView animateWithDuration:0.3
                                                                          animations:^{
                                                                            self.alpha = 0.5; // 变为半透明
                                                                          }];
                                                       }];
    // 交互时变为完全不透明
    if (self.alpha != self.originalAlpha) {
        [UIView animateWithDuration:0.2
                         animations:^{
                           self.alpha = self.originalAlpha; // 变为完全不透明
                         }];
    }
}
- (void)saveLockState {
    [[NSUserDefaults standardUserDefaults] setBool:self.isLocked forKey:@"DYYYHideUIButtonLockState"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)loadLockState {
    self.isLocked = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideUIButtonLockState"];
}
- (void)loadIcons {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *iconPath = [documentsPath stringByAppendingPathComponent:@"DYYY/qingping.gif"];
    NSData *gifData = [NSData dataWithContentsOfFile:iconPath];

    if (gifData) {
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)gifData, NULL);
        size_t imageCount = CGImageSourceGetCount(source);

        NSMutableArray<UIImage *> *imageArray = [NSMutableArray arrayWithCapacity:imageCount];
        NSTimeInterval totalDuration = 0.0;

        for (size_t i = 0; i < imageCount; i++) {
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            [imageArray addObject:image];
            CFRelease(imageRef);

            // 获取当前帧的属性
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
            if (properties) {
                // 进行类型转换
                CFDictionaryRef gifProperties = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
                if (gifProperties) {
                    // 尝试获取未限制的延迟时间，如果没有则获取常规延迟时间
                    NSNumber *frameDuration = (__bridge NSNumber *)CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
                    if (!frameDuration) {
                        frameDuration = (__bridge NSNumber *)CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
                    }
                    if (frameDuration) {
                        totalDuration += frameDuration.doubleValue;
                    }
                }
                CFRelease(properties);
            }
        }
        CFRelease(source);

        // 创建一个UIImageView并设置动画图像
        UIImageView *animatedImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        animatedImageView.animationImages = imageArray;

        // 设置动画持续时间为所有帧延迟时间的总和
        animatedImageView.animationDuration = totalDuration;
        animatedImageView.animationRepeatCount = 0; // 无限循环
        [self addSubview:animatedImageView];

        // 调整约束或布局（如果需要）
        animatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [animatedImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor], [animatedImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [animatedImageView.widthAnchor constraintEqualToAnchor:self.widthAnchor], [animatedImageView.heightAnchor constraintEqualToAnchor:self.heightAnchor]
        ]];

        [animatedImageView startAnimating];
    } else {
        [self setTitle:@"隐藏" forState:UIControlStateNormal];
        [self setTitle:@"显示" forState:UIControlStateSelected];
        self.titleLabel.font = [UIFont systemFontOfSize:10];
    }
}
- (void)handleTouchDown {
    [self resetFadeTimer]; // 这会使按钮变为完全不透明
}
- (void)handleTouchUpInside {
    [self resetFadeTimer]; // 这会使按钮变为完全不透明
}
- (void)handleTouchUpOutside {
    [self resetFadeTimer]; // 这会使按钮变为完全不透明
}
- (UIViewController *)findViewController:(UIView *)view {
    __weak UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
        if (!responder)
            break;
    }
    return nil;
}
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (self.isLocked)
        return;
    [self resetFadeTimer];
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    newCenter.x = MAX(self.frame.size.width / 2, MIN(newCenter.x, self.superview.frame.size.width - self.frame.size.width / 2));
    newCenter.y = MAX(self.frame.size.height / 2, MIN(newCenter.y, self.superview.frame.size.height - self.frame.size.height / 2));
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(self.center) forKey:@"DYYYHideUIButtonPosition"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)handleTap {
    if (isAppInTransition)
        return;
    [self resetFadeTimer];
    if (!self.isElementsHidden) {
        [self hideUIElements];
        self.isElementsHidden = YES;
        self.selected = YES;

        BOOL hideSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSpeed"];
        if (hideSpeed) {
            hideSpeedButton();
        }
    } else {
        forceResetAllUIElements();
        [self restoreAWEPlayInteractionProgressContainerView];
        self.isElementsHidden = NO;
        [self.hiddenViewsList removeAllObjects];
        self.selected = NO;

        BOOL hideSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSpeed"];
        if (hideSpeed) {
            showSpeedButton();
        }
    }
}

- (void)restoreAWEPlayInteractionProgressContainerView {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYRemoveTimeProgress"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTimeProgress"]) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            [self recursivelyRestoreAWEPlayInteractionProgressContainerViewInView:window];
        }
    }
}

- (void)recursivelyRestoreAWEPlayInteractionProgressContainerViewInView:(UIView *)view {
    if ([view isKindOfClass:NSClassFromString(@"AWEPlayInteractionProgressContainerView")]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYRemoveTimeProgress"]) {
            // 如果设置了移除时间进度条，直接显示
            view.hidden = NO;
        } else {
            // 恢复透明度
            view.alpha = DYGetGlobalAlpha();
        }
        return;
    }

    for (UIView *subview in view.subviews) {
        [self recursivelyRestoreAWEPlayInteractionProgressContainerViewInView:subview];
    }
}
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self resetFadeTimer]; // 这会使按钮变为完全不透明
        self.isLocked = !self.isLocked;
        // 保存锁定状态
        [self saveLockState];
        NSString *toastMessage = self.isLocked ? @"按钮已锁定" : @"按钮已解锁";
        [DYYYUtils showToast:toastMessage];
        if (@available(iOS 10.0, *)) {
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [generator prepare];
            [generator impactOccurred];
        }
    }
}
- (void)hideUIElements {
    [self.hiddenViewsList removeAllObjects];
    [self findAndHideViews:targetClassNames];
    // 新增隐藏 AWEPlayInteractionProgressContainerView 视图
    [self hideAWEPlayInteractionProgressContainerView];
    self.isElementsHidden = YES;
    // 确保按钮本身不会被隐藏
    self.hidden = NO;
    if (self.superview) {
        [self.superview bringSubviewToFront:self];
    }
}

- (void)hideAWEPlayInteractionProgressContainerView {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYRemoveTimeProgress"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTimeProgress"]) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            [self recursivelyHideAWEPlayInteractionProgressContainerViewInView:window];
        }
    }
}

- (void)recursivelyHideAWEPlayInteractionProgressContainerViewInView:(UIView *)view {
    if ([view isKindOfClass:NSClassFromString(@"AWEPlayInteractionProgressContainerView")]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYRemoveTimeProgress"]) {
            // 如果设置了移除时间进度条
            view.hidden = YES;
        } else {
            // 否则设置透明度为 0.0,可拖动
            view.tag = DYYY_IGNORE_GLOBAL_ALPHA_TAG;
            view.alpha = 0.0;
        }
        [self.hiddenViewsList addObject:view];
        return;
    }

    for (UIView *subview in view.subviews) {
        [self recursivelyHideAWEPlayInteractionProgressContainerViewInView:subview];
    }
}
- (void)findAndHideViews:(NSArray *)classNames {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        for (NSString *className in classNames) {
            Class viewClass = NSClassFromString(className);
            if (!viewClass)
                continue;
            NSMutableArray *views = [NSMutableArray array];
            findViewsOfClassHelper(window, viewClass, views);
            for (UIView *view in views) {
                if ([view isKindOfClass:[UIView class]]) {
                    if (view == self)
                        continue;
                    if ([view isKindOfClass:NSClassFromString(@"AWELeftSideBarEntranceView")]) {
                        UIViewController *controller = [self findViewController:view];
                        if (![controller isKindOfClass:NSClassFromString(@"AWEFeedContainerViewController")]) {
                            continue;
                        }
                    }
                    [self.hiddenViewsList addObject:view];
                    view.alpha = 0.0;
                }
            }
        }
    }
}
- (void)safeResetState {
    forceResetAllUIElements();
    self.isElementsHidden = NO;
    [self.hiddenViewsList removeAllObjects];
    self.selected = NO;

    if (self.superview) {
        [self.superview bringSubviewToFront:self];
    }

    // 恢复倍速按钮的显示
    BOOL hideSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSpeed"];
    if (hideSpeed) {
        showSpeedButton();
    }
}
- (void)dealloc {
    [self.checkTimer invalidate];
    [self.fadeTimer invalidate];
    self.checkTimer = nil;
    self.fadeTimer = nil;
}
@end
%hook AWECommentContainerViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    dyyyCommentViewVisible = YES;
    updateSpeedButtonVisibility();
    updateClearButtonVisibility();
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    dyyyCommentViewVisible = NO;
    updateSpeedButtonVisibility();
    updateClearButtonVisibility();
}

- (void)viewDidLayoutSubviews {
    %orig;

    BOOL enableCommentBlur = DYYYGetBool(@"DYYYEnableCommentBlur");
    if (!enableCommentBlur)
        return;

    Class containerViewClass = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputContainerView");
    UIView *containerView = [DYYYUtils findSubviewOfClass:containerViewClass inView:self.view];
    if (containerView) {
        for (UIView *subview in containerView.subviews) {
            if (subview.alpha > 0.1f && subview.backgroundColor && CGColorGetAlpha(subview.backgroundColor.CGColor) > 0.1f) {
                float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
                if (userTransparency <= 0 || userTransparency > 1) {
                    userTransparency = 0.8;
                }
                [DYYYUtils applyBlurEffectToView:subview transparency:userTransparency blurViewTag:999];
                [DYYYUtils clearBackgroundRecursivelyInView:subview];
            }
        }
    }

    Class middleContainerClass = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputViewMiddleContainer");
    NSArray<UIView *> *middleContainers = [DYYYUtils findAllSubviewsOfClass:middleContainerClass inView:self.view];
    for (UIView *middleContainer in middleContainers) {
        BOOL containsDanmu = NO;
        for (UIView *innerSubviewCheck in middleContainer.subviews) {
            if ([innerSubviewCheck isKindOfClass:[UILabel class]] && [((UILabel *)innerSubviewCheck).text containsString:@"弹幕"]) {
                containsDanmu = YES;
                break;
            }
        }

        if (containsDanmu) {
            UIView *parentView = middleContainer.superview;
            for (UIView *innerSubview in parentView.subviews) {
                if ([innerSubview isKindOfClass:[UIView class]]) {
                    // NSLog(@"[innerSubview] %@", innerSubview);
                    if (innerSubview.subviews.count > 0) {
                        innerSubview.subviews[0].hidden = YES;
                    }

                    UIView *whiteBackgroundView = [[UIView alloc] initWithFrame:innerSubview.bounds];
                    whiteBackgroundView.backgroundColor = [UIColor whiteColor];
                    whiteBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    [innerSubview addSubview:whiteBackgroundView];
                    break;
                }
            }
        } else {
            for (UIView *innerSubview in middleContainer.subviews) {
                if (innerSubview.alpha > 0.1f && innerSubview.backgroundColor && CGColorGetAlpha(innerSubview.backgroundColor.CGColor) > 0.1f) {
                    [DYYYUtils applyBlurEffectToView:innerSubview transparency:0.2f blurViewTag:999];
                    [DYYYUtils clearBackgroundRecursivelyInView:innerSubview];
                    break;
                }
            }
        }
    }
}

%end

%hook UIView
- (id)initWithFrame:(CGRect)frame {
    UIView *view = %orig;
    if (hideButton && hideButton.isElementsHidden) {
        for (NSString *className in targetClassNames) {
            if ([view isKindOfClass:NSClassFromString(className)]) {
                if ([view isKindOfClass:NSClassFromString(@"AWELeftSideBarEntranceView")]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                      UIViewController *controller = [hideButton findViewController:view];
                      if ([controller isKindOfClass:NSClassFromString(@"AWEFeedContainerViewController")]) {
                          view.alpha = 0.0;
                      }
                    });
                    break;
                }
                view.alpha = 0.0;
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
                if ([subview isKindOfClass:NSClassFromString(@"AWELeftSideBarEntranceView")]) {
                    UIViewController *controller = [hideButton findViewController:subview];
                    if ([controller isKindOfClass:NSClassFromString(@"AWEFeedContainerViewController")]) {
                        subview.alpha = 0.0;
                    }
                    break;
                }
                subview.alpha = 0.0;
                break;
            }
        }
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        for (NSString *className in targetClassNames) {
            if ([self isKindOfClass:NSClassFromString(className)]) {
                if ([self isKindOfClass:NSClassFromString(@"AWELeftSideBarEntranceView")]) {
                    UIViewController *controller = [hideButton findViewController:self];
                    if ([controller isKindOfClass:NSClassFromString(@"AWEFeedContainerViewController")]) {
                        self.alpha = 0.0;
                    }
                    break;
                }
                self.alpha = 0.0;
                break;
            }
        }
    }
}
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        if (self.frame.size.height == tabHeight && tabHeight > 0) {
            UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
            if ([vc isKindOfClass:NSClassFromString(@"AWEMixVideoPanelDetailTableViewController")] || [vc isKindOfClass:NSClassFromString(@"AWECommentInputViewController")] ||
                [vc isKindOfClass:NSClassFromString(@"AWEAwemeDetailTableViewController")]) {
                self.backgroundColor = [UIColor clearColor];
            }
        }
    }

    if (DYYYGetBool(@"DYYYEnableFullScreen") || DYYYGetBool(@"DYYYEnableCommentBlur")) {
        UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
        if ([vc isKindOfClass:%c(AWEPlayInteractionViewController)]) {
            for (UIView *subview in self.subviews) {
                if ([subview isKindOfClass:[UIView class]] && subview.backgroundColor && CGColorEqualToColor(subview.backgroundColor.CGColor, [UIColor blackColor].CGColor)) {
                    subview.hidden = YES;
                }
            }
        }
    }
}

- (void)setFrame:(CGRect)frame {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setFrame:frame];
        });
        return;
    }

    BOOL enableBlur = DYYYGetBool(@"DYYYEnableCommentBlur");
    BOOL enableFS = DYYYGetBool(@"DYYYEnableFullScreen");
    BOOL hideAvatar = DYYYGetBool(@"DYYYHideAvatarList");

    Class SkylightListViewClass = NSClassFromString(@"AWEIMSkylightListView");
    if (hideAvatar && SkylightListViewClass && [self isKindOfClass:SkylightListViewClass]) {
        frame = CGRectZero;
        %orig(frame);
        return;
    }

    UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
    Class DetailVCClass = NSClassFromString(@"AWEMixVideoPanelDetailTableViewController");
    Class PlayVCClass1 = NSClassFromString(@"AWEAwemePlayVideoViewController");
    Class PlayVCClass2 = NSClassFromString(@"AWEDPlayerFeedPlayerViewController");

    BOOL isDetailVC = (DetailVCClass && [vc isKindOfClass:DetailVCClass]);
    BOOL isPlayVC = ((PlayVCClass1 && [vc isKindOfClass:PlayVCClass1]) || (PlayVCClass2 && [vc isKindOfClass:PlayVCClass2]));

    if (isPlayVC && enableBlur) {
        if (frame.origin.x != 0) {
            return;
        }
    }

    if (isPlayVC && enableFS) {
        if (frame.origin.x != 0 && frame.origin.y != 0) {
            %orig(frame);
            return;
        }
        CGRect superF = self.superview.frame;
        if (CGRectGetHeight(superF) > 0 && CGRectGetHeight(frame) > 0 && CGRectGetHeight(frame) < CGRectGetHeight(superF)) {
            CGFloat diff = CGRectGetHeight(superF) - CGRectGetHeight(frame);
            if (fabs(diff - tabHeight) < 1.0) {
                frame.size.height = CGRectGetHeight(superF);
            }
        }
        %orig(frame);
        return;
    }

    %orig(frame);
}

%end

%hook AWEPlayInteractionViewController
- (void)viewDidLayoutSubviews {
    %orig;
    if (isFloatSpeedButtonEnabled) {
        BOOL hasRightStack = NO;
        Class stackClass = NSClassFromString(@"AWEElementStackView");
        for (UIView *sub in self.view.subviews) {
            if ([sub isKindOfClass:stackClass] && ([sub.accessibilityLabel isEqualToString:@"right"] ||
                                                  [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEPlayInteractionUserAvatarView")
                                                                          inView:self.view])) {
                hasRightStack = YES;
                break;
            }
        }
        if (hasRightStack) {
            if (speedButton == nil) {
                speedButtonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYSpeedButtonSize"] ?: 32.0;
                CGRect screenBounds = [UIScreen mainScreen].bounds;
                CGRect initialFrame = CGRectMake((screenBounds.size.width - speedButtonSize) / 2,
                                                 (screenBounds.size.height - speedButtonSize) / 2,
                                                 speedButtonSize, speedButtonSize);
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
            dyyyInteractionViewVisible = YES;
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (keyWindow && ![speedButton isDescendantOfView:keyWindow]) {
                [keyWindow addSubview:speedButton];
                [speedButton loadSavedPosition];
                [speedButton resetFadeTimer];
            }
        }
    }

    if (!DYYYGetBool(@"DYYYEnableFullScreen")) {
        return;
    }

    UIViewController *parentVC = self.parentViewController;
    int maxIterations = 3;
    int count = 0;

    while (parentVC && count < maxIterations) {
        if ([parentVC isKindOfClass:%c(AFDPlayRemoteFeedTableViewController)]) {
            return;
        }
        parentVC = parentVC.parentViewController;
        count++;
    }

    if (!self.view.superview) {
        return;
    }

    CGRect frame = self.view.frame;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat superviewHeight = self.view.superview.frame.size.height;

    if (frame.size.width != screenWidth && frame.size.height < superviewHeight) {
        return;
    }

    NSString *currentReferString = self.referString;

    BOOL useFullHeight = [currentReferString isEqualToString:@"general_search"] || [currentReferString isEqualToString:@"chat"] || [currentReferString isEqualToString:@"search_result"] ||
                         [currentReferString isEqualToString:@"close_friends_moment"] || [currentReferString isEqualToString:@"offline_mode"] || [currentReferString isEqualToString:@"challenge"] ||
                         currentReferString == nil;

    if (useFullHeight) {
        frame.size.height = superviewHeight;
    } else {
        frame.size.height = superviewHeight - tabHeight;
    }

    if (fabs(frame.size.height - self.view.frame.size.height) > 0.5) {
        self.view.frame = frame;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    BOOL hasRightStack = NO;
    Class stackClass = NSClassFromString(@"AWEElementStackView");
    for (UIView *sub in self.view.subviews) {
        if ([sub isKindOfClass:stackClass] && ([sub.accessibilityLabel isEqualToString:@"right"] ||
                                              [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEPlayInteractionUserAvatarView")
                                                                      inView:self.view])) {
            hasRightStack = YES;
            break;
        }
    }
    if (hasRightStack) {
        dyyyInteractionViewVisible = NO;
        dyyyCommentViewVisible = self.isCommentVCShowing;
        updateSpeedButtonVisibility();
        updateClearButtonVisibility();
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

- (void)viewDidLayoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        UIView *contentView = self.contentView;
        if (contentView && contentView.superview) {
            CGRect frame = contentView.frame;
            CGFloat parentHeight = contentView.superview.frame.size.height;
            CGFloat h = customTabBarHeight();
            if (h > 0) {
                if (frame.size.height == parentHeight - h) {
                    frame.size.height = parentHeight;
                    contentView.frame = frame;
                } else if (frame.size.height == parentHeight - (h * 2)) {
                    frame.size.height = parentHeight - h;
                    contentView.frame = frame;
                }
            } else {
                if (frame.size.height == parentHeight - tabHeight) {
                    frame.size.height = parentHeight;
                    contentView.frame = frame;
                } else if (frame.size.height == parentHeight - (tabHeight * 2)) {
                    frame.size.height = parentHeight - tabHeight;
                    contentView.frame = frame;
                }
            }
        }
    }
}

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

%hook AWEFeedTableView
- (void)layoutSubviews {
    %orig;
    CGFloat h = customTabBarHeight();
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        if (self.superview) {
            CGFloat currentDifference = self.superview.frame.size.height - self.frame.size.height;
            if (currentDifference > 0 && tabHeight == 0) {
                tabHeight = currentDifference;
            }
        }

        CGRect frame = self.frame;
        frame.size.height = self.superview.frame.size.height;
        self.frame = frame;
    } else if (!DYYYGetBool(@"DYYYEnableFullScreen") && h > 0) {
        CGRect frame = self.frame;
        frame.size.height = self.superview.frame.size.height - h;
        self.frame = frame;
    }
}
%end

%hook AWEFeedTableViewCell
- (void)prepareForReuse {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)layoutSubviews {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
}
%end

%hook AWEFeedViewCell
- (void)layoutSubviews {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)setModel:(id)model {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}
%end

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      isAppInTransition = NO;
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      isAppInTransition = NO;
    });
}
%end

%hook AFDPureModePageContainerViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    isPureViewVisible = YES;
    updateClearButtonVisibility();
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    isPureViewVisible = NO;
    updateClearButtonVisibility();
}
%end

%hook AWEFeedContainerViewController
- (void)aweme:(id)arg1 currentIndexWillChange:(NSInteger)arg2 {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)aweme:(id)arg1 currentIndexDidChange:(NSInteger)arg2 {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)viewWillLayoutSubviews {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
}
%end

%hook AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    initTargetClassNames();

    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFloatClearButton"];
    if (isEnabled) {
        if (hideButton) {
            [hideButton removeFromSuperview];
            hideButton = nil;
        }

        CGFloat buttonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYEnableFloatClearButtonSize"] ?: 40.0;
        hideButton = [[HideUIButton alloc] initWithFrame:CGRectMake(0, 0, buttonSize, buttonSize)];
        hideButton.alpha = 0.5;

        NSString *savedPositionString = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideUIButtonPosition"];
        if (savedPositionString) {
            hideButton.center = CGPointFromString(savedPositionString);
        } else {
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
            hideButton.center = CGPointMake(screenWidth - buttonSize / 2 - 5, screenHeight / 2);
        }

        hideButton.hidden = YES;
        [getKeyWindow() addSubview:hideButton];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeKeyNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *_Nonnull notification) {
                                                        if (dyyyInteractionViewVisible && !dyyyCommentViewVisible && !clearButtonForceHidden && !isPureViewVisible) {
                                                            updateClearButtonVisibility();
                                                        }
                                                      }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *_Nonnull notification) {
                                                        isAppActive = YES;
                                                        updateClearButtonVisibility();
                                                      }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *_Nonnull notification) {
                                                        isAppActive = NO;
                                                        updateClearButtonVisibility();
                                                      }];
    }

    return result;
}
%end
