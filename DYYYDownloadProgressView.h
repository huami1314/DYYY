#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYYYDownloadProgressView : UIView

@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, strong) UIView *progressBarBackground;
@property(nonatomic, strong) UIView *progressBar;
@property(nonatomic, copy) void (^cancelBlock)(void);
@property(nonatomic, assign) BOOL isCancelled;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setProgress:(float)progress;
- (void)show;
- (void)dismiss;
- (void)showSuccessAnimation:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
