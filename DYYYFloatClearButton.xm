/*
 * Tweak Name: 1KeyHideDYUI
 * Target App: com.ss.iphone.ugc.Aweme
 * Dev: @c00kiec00k 曲奇的坏品味🍻
 * iOS Version: 16.5
 */
#import "DYYYManager.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <signal.h>
#import "DYYYFloatSpeedButton.h"
#import "DYYYUtils.h"

void updateClearButtonVisibility(void);
void showClearButton(void);
void hideClearButton(void);

static BOOL isInPlayInteractionVC = NO;
static BOOL isCommentViewVisible = NO;
static BOOL isForceHidden = NO;
static BOOL isAppActive = YES;
static BOOL isInteractionViewVisible = NO;

@interface HideUIButton : UIButton

@property(nonatomic, assign) BOOL isElementsHidden;
@property(nonatomic, assign) BOOL isLocked;
@property(nonatomic, strong) NSMutableArray *hiddenViewsList;
@property(nonatomic, strong) UIImage *showIcon;
@property(nonatomic, strong) UIImage *hideIcon;
@property(nonatomic, assign) CGFloat originalAlpha;
@property(nonatomic, strong) NSTimer *checkTimer;
@property(nonatomic, strong) NSTimer *fadeTimer;
- (void)resetFadeTimer;
- (void)hideUIElements;
- (void)findAndHideViews:(NSArray *)classNames;
- (void)safeResetState;
- (void)startPeriodicCheck;
- (UIViewController *)findViewController:(UIView *)view;
- (void)loadIcons;
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
- (void)handleTap;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture;
- (void)handleTouchDown;
- (void)handleTouchUpInside;
- (void)handleTouchUpOutside;
- (void)saveLockState;
- (void)loadLockState;
@end

static HideUIButton *hideButton;
static BOOL isAppInTransition = NO;
static NSArray *targetClassNames;
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
static UIWindow *getKeyWindow(void) {
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
        if (!isInteractionViewVisible) {
            hideButton.hidden = YES;
            return;
        }
        
        BOOL shouldHide = isCommentViewVisible || isForceHidden;
        if (hideButton.hidden != shouldHide) {
            hideButton.hidden = shouldHide;
        }
    });
}

void showClearButton(void) {
    isForceHidden = NO;
}

void hideClearButton(void) {
    isForceHidden = YES;
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
			if([view isKindOfClass:StackViewClass]) {
				view.alpha = DYGetGlobalAlpha();
			}
			else{
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
static void initTargetClassNames(void) {
    NSMutableArray<NSString *> *list = [@[
        @"AWEHPTopBarCTAContainer", @"AWEHPDiscoverFeedEntranceView", @"AWELeftSideBarEntranceView",
        @"DUXBadge", @"AWEBaseElementView", @"AWEElementStackView",
        @"AWEPlayInteractionDescriptionLabel", @"AWEUserNameLabel",
        @"ACCEditTagStickerView", @"AWEFeedTemplateAnchorView",
        @"AWESearchFeedTagView", @"AWEPlayInteractionSearchAnchorView",
        @"AFDRecommendToFriendTagView", @"AWELandscapeFeedEntryView",
        @"AWEFeedAnchorContainerView", @"AFDAIbumFolioView", @"DUXPopover",
		@"AWEMixVideoPanelMoreView", @"AWEHotSearchInnerBottomView"
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
        self.originalAlpha = 1.0;  // 交互时为完全不透明
        self.alpha = 0.5;  // 初始为半透明
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
										self.alpha = 0.5;  // 变为半透明
									      }];
							   }];
	// 交互时变为完全不透明
    if (self.alpha != self.originalAlpha) {
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.alpha = self.originalAlpha;  // 变为完全不透明
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
            [animatedImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [animatedImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [animatedImageView.widthAnchor constraintEqualToAnchor:self.widthAnchor],
            [animatedImageView.heightAnchor constraintEqualToAnchor:self.heightAnchor]
        ]];
        
        [animatedImageView startAnimating];
    } else {
        [self setTitle:@"隐藏" forState:UIControlStateNormal];
        [self setTitle:@"显示" forState:UIControlStateSelected];
        self.titleLabel.font = [UIFont systemFontOfSize:10];
    }
}
- (void)handleTouchDown {
	[self resetFadeTimer];  // 这会使按钮变为完全不透明
}
- (void)handleTouchUpInside {
	[self resetFadeTimer];  // 这会使按钮变为完全不透明
}
- (void)handleTouchUpOutside {
	[self resetFadeTimer];  // 这会使按钮变为完全不透明
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
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnabshijianjindu"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTimeProgress"]) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            [self recursivelyRestoreAWEPlayInteractionProgressContainerViewInView:window];
        }
    }
}

- (void)recursivelyRestoreAWEPlayInteractionProgressContainerViewInView:(UIView *)view {
    if ([view isKindOfClass:NSClassFromString(@"AWEPlayInteractionProgressContainerView")]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnabshijianjindu"]) {
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
		[self resetFadeTimer];  // 这会使按钮变为完全不透明
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
}

- (void)hideAWEPlayInteractionProgressContainerView {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnabshijianjindu"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTimeProgress"]) {
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                    [self recursivelyHideAWEPlayInteractionProgressContainerViewInView:window];
                }
    }
}

- (void)recursivelyHideAWEPlayInteractionProgressContainerViewInView:(UIView *)view {
    if ([view isKindOfClass:NSClassFromString(@"AWEPlayInteractionProgressContainerView")]) {
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnabshijianjindu"]) {
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
// Hook 部分
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

%hook AWEElementStackView
- (void)setAlpha:(CGFloat)alpha {
    %orig;
    if (hideButton) {
        if (alpha == 0) {
            isCommentViewVisible = YES;
        } else if (alpha == 1) {
            isCommentViewVisible = NO;
        }
    }
}
%end

%hook AWECommentContainerViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isCommentViewVisible = YES;
    updateClearButtonVisibility();
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    isCommentViewVisible = YES;
    updateClearButtonVisibility();
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    updateClearButtonVisibility();
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    isCommentViewVisible = NO;
    updateClearButtonVisibility();
}

%end

%hook AWEPlayInteractionViewController
- (void)loadView {
    %orig;
    if (hideButton) {
        hideButton.hidden = NO;
        hideButton.alpha = 0.5;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isInPlayInteractionVC = YES;
    isInteractionViewVisible = YES;
    if (hideButton) {
        hideButton.hidden = NO;
        hideButton.alpha = 0.5;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    isInteractionViewVisible = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    isInPlayInteractionVC = NO;
    isInteractionViewVisible = NO;
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
            hideButton.center = CGPointMake(screenWidth - buttonSize/2 - 5, screenHeight / 2);
        }
        
        hideButton.hidden = YES;
        [getKeyWindow() addSubview:hideButton];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeKeyNotification
                                                         object:nil
                                                          queue:[NSOperationQueue mainQueue]
                                                     usingBlock:^(NSNotification * _Nonnull notification) {
            if (isInteractionViewVisible && !isCommentViewVisible && !isForceHidden) {
                updateClearButtonVisibility();
            }
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                         object:nil
                                                          queue:[NSOperationQueue mainQueue]
                                                     usingBlock:^(NSNotification * _Nonnull notification) {
            isAppActive = YES;
            updateClearButtonVisibility();
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                         object:nil
                                                          queue:[NSOperationQueue mainQueue]
                                                     usingBlock:^(NSNotification * _Nonnull notification) {
            isAppActive = NO;
            updateClearButtonVisibility();
        }];
    }
    
    return result;
}
%end

%ctor {
	signal(SIGSEGV, SIG_IGN);
}