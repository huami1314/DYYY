#import <UIKit/UIKit.h>

@interface FloatingSpeedButton : UIButton
@property(nonatomic, assign) CGPoint lastLocation;
@property(nonatomic, weak) id interactionController;
@property(nonatomic, assign) BOOL isLocked;
@property(nonatomic, assign) BOOL justToggledLock;
@property(nonatomic, assign) BOOL originalLockState;
@property(nonatomic, assign) BOOL isResponding;
@property(nonatomic, strong) NSTimer *statusCheckTimer;
@property(nonatomic, strong) NSTimer *fadeTimer;
@property(nonatomic, assign) CGFloat originalAlpha;
- (void)saveButtonPosition;
- (void)loadSavedPosition;
- (void)resetButtonState;
- (void)toggleLockState;
- (void)resetFadeTimer;
@end

#ifdef __cplusplus
extern "C" {
#endif

extern FloatingSpeedButton *speedButton;
extern BOOL dyyyCommentViewVisible;
extern BOOL dyyyInteractionViewVisible;
extern BOOL isFloatSpeedButtonEnabled;
extern BOOL speedButtonForceHidden;
extern BOOL showSpeedX;
extern CGFloat speedButtonSize;

extern NSArray *getSpeedOptions(void);

extern FloatingSpeedButton *getSpeedButton(void);
extern void showSpeedButton(void);
extern void hideSpeedButton(void);
extern void toggleSpeedButtonVisibility(void);
extern NSArray *findViewControllersInHierarchy(UIViewController *rootViewController);
extern float getCurrentSpeed(void);
extern NSInteger getCurrentSpeedIndex(void);
extern void setCurrentSpeedIndex(NSInteger index);
extern void updateSpeedButtonUI(void);
extern void updateSpeedButtonVisibility(void);

#ifdef __cplusplus
}
#endif
