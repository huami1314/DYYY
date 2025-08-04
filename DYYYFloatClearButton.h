#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif

@class HideUIButton;

extern HideUIButton *hideButton;
extern BOOL isInPlayInteractionVC;
extern BOOL isPureViewVisible;
extern BOOL clearButtonForceHidden;
extern BOOL isAppActive;
extern BOOL isAppInTransition;
extern NSArray *targetClassNames;
extern BOOL dyyyInteractionViewVisible;
extern BOOL dyyyCommentViewVisible;

UIWindow *getKeyWindow(void);

void updateClearButtonVisibility(void);
void showClearButton(void);
void hideClearButton(void);
void initTargetClassNames(void);

#ifdef __cplusplus
}
#endif

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

