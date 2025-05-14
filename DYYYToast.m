#import "DYYYToast.h"
#import "DYYYManager.h"

@interface DYYYToast ()

@property(nonatomic, strong) CAShapeLayer *progressLayer;
@property(nonatomic, strong) UILabel *percentLabel;
@property(nonatomic, assign) CGFloat progress;
@property(nonatomic, strong) UIVisualEffectView *blurEffectView;
// 新增属性
@property(nonatomic, strong) CAShapeLayer *checkmarkLayer;
@property(nonatomic, strong) UIView *progressView;
@property(nonatomic, assign)
    BOOL isShowingSuccessAnimation; // 新增属性，标记是否正在显示成功动画

@end

@implementation DYYYToast

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // 设置透明背景
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = YES;
    self.isCancelled = NO;

    BOOL isDarkMode = [DYYYManager isDarkMode];

    CGFloat containerWidth = 160;
    CGFloat containerHeight = 40;
    _containerView = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, containerWidth, containerHeight)];
    _containerView.center = CGPointMake(CGRectGetMidX(self.bounds), 130);

    _containerView.backgroundColor = [UIColor clearColor];
    _containerView.layer.cornerRadius = containerHeight / 2;
    _containerView.clipsToBounds = YES;
    _containerView.userInteractionEnabled = YES;

    // 添加毛玻璃效果
    UIBlurEffect *blurEffect =
        [UIBlurEffect effectWithStyle:isDarkMode ? UIBlurEffectStyleDark
                                                 : UIBlurEffectStyleLight];
    _blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _blurEffectView.frame = _containerView.bounds;
    _blurEffectView.layer.cornerRadius = containerHeight / 2;
    _blurEffectView.clipsToBounds = YES;
    [_containerView addSubview:_blurEffectView];

    [self addSubview:_containerView];

    _containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    _containerView.layer.shadowOffset = CGSizeMake(0, 2);
    _containerView.layer.shadowRadius = 6;
    _containerView.layer.shadowOpacity = 0.2;

    CGFloat circleSize = 30;
    CGFloat yCenter = containerHeight / 2;
    // 修改为属性而非局部变量
    _progressView = [[UIView alloc]
        initWithFrame:CGRectMake(10, (containerHeight - circleSize) / 2,
                                 circleSize, circleSize)];
    [_containerView addSubview:_progressView];
    CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
    UIBezierPath *circularPath = [UIBezierPath
        bezierPathWithArcCenter:CGPointMake(circleSize / 2, circleSize / 2)
                         radius:circleSize / 2 - 2 // 稍微减小半径
                     startAngle:-M_PI / 2
                       endAngle:3 * M_PI / 2
                      clockwise:YES];
    backgroundLayer.path = circularPath.CGPath;

    UIColor *separatorColor = isDarkMode
                                  ? [UIColor colorWithWhite:0.4 alpha:1.0]
                                  : [UIColor colorWithWhite:0.85 alpha:1.0];
    backgroundLayer.strokeColor = separatorColor.CGColor;
    backgroundLayer.fillColor = [UIColor clearColor].CGColor;
    backgroundLayer.lineWidth = 2;
    backgroundLayer.lineCap = kCALineCapRound;
    [_progressView.layer addSublayer:backgroundLayer];

    _progressLayer = [CAShapeLayer layer];
    _progressLayer.path = circularPath.CGPath;

    UIColor *progressColor = isDarkMode ? [UIColor colorWithRed:48 / 255.0
                                                          green:209 / 255.0
                                                           blue:151 / 255.0
                                                          alpha:1.0]
                                        : [UIColor colorWithRed:11 / 255.0
                                                          green:195 / 255.0
                                                           blue:139 / 255.0
                                                          alpha:1.0];
    _progressLayer.strokeColor = progressColor.CGColor;
    _progressLayer.fillColor = [UIColor clearColor].CGColor;
    _progressLayer.lineWidth = 2;
    _progressLayer.lineCap = kCALineCapRound;
    _progressLayer.strokeEnd = 0;
    [_progressView.layer addSublayer:_progressLayer];

    _percentLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(0, 0, containerWidth, containerHeight)];
    _percentLabel.textAlignment = NSTextAlignmentCenter;
    _percentLabel.textColor = isDarkMode
                                  ? [UIColor colorWithWhite:0.9 alpha:1.0]
                                  : [UIColor colorWithWhite:0.2 alpha:1.0];
    _percentLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _percentLabel.text = @"下载中... 0%";
    CGFloat progressViewRightEdge =
        _progressView.frame.origin.x + _progressView.frame.size.width;
    CGFloat labelWidth = containerWidth - progressViewRightEdge;
    _percentLabel.frame =
        CGRectMake(progressViewRightEdge - 3, 0, labelWidth, containerHeight);
    _percentLabel.textAlignment = NSTextAlignmentCenter;
    [_containerView addSubview:_percentLabel];

    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleTap:)];
    [_containerView addGestureRecognizer:tapGesture];

    self.alpha = 0;
  }
  return self;
}

- (void)setProgress:(float)progress {
  // 确保在主线程中更新UI
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self setProgress:progress];
    });
    return;
  }

  // 进度值限制在0到1之间
  progress = MAX(0.0, MIN(1.0, progress));
  _progress = progress;

  // 设置环形进度
  _progressLayer.strokeEnd = progress;

  // 更新进度百分比
  int percentage = (int)(progress * 100);
  _percentLabel.text =
      [NSString stringWithFormat:@"下载中... %d%%", percentage];
}

- (void)show {
  UIWindow *window = [UIApplication sharedApplication].keyWindow;
  if (!window)
    return;

  [window addSubview:self];

  [UIView animateWithDuration:0.3
                   animations:^{
                     self.alpha = 1.0;
                   }];
}

- (void)dismiss {
  if (_progress >= 0.5 && !self.isShowingSuccessAnimation &&
      !self.isCancelled) {
    self.isShowingSuccessAnimation = YES;
    [self showSuccessAnimation:nil];
  }
  if (self.isCancelled) {
    [self showCancelAnimation:nil];
  } else {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          [UIView animateWithDuration:0.3
              animations:^{
                self.alpha = 0;
              }
              completion:^(BOOL finished) {
                [self removeFromSuperview];
              }];
        });
  }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
  self.isCancelled = YES;
  if (self.cancelBlock) {
    self.cancelBlock();
  }
  [self dismiss];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  if (self.hidden || self.alpha == 0) {
    return nil;
  }

  CGPoint containerPoint = [self convertPoint:point toView:_containerView];
  if ([_containerView pointInside:containerPoint withEvent:event]) {
    return [super hitTest:point withEvent:event];
  }

  return nil;
}
// 下载成功动画方法
- (void)showSuccessAnimation:(void (^)(void))completion {
  BOOL isDarkMode = [DYYYManager isDarkMode];

  UIColor *successColor = isDarkMode ? [UIColor colorWithRed:48 / 255.0
                                                       green:209 / 255.0
                                                        blue:151 / 255.0
                                                       alpha:1.0]
                                     : [UIColor colorWithRed:11 / 255.0
                                                       green:195 / 255.0
                                                        blue:139 / 255.0
                                                       alpha:1.0];

  [UIView animateWithDuration:0.3
      animations:^{
        [self setProgress:1.0];
      }
      completion:^(BOOL finished) {
        CAShapeLayer *circleLayer = [CAShapeLayer layer];
        CGFloat circleSize = 30;
        UIBezierPath *circlePath = [UIBezierPath
            bezierPathWithOvalInRect:CGRectMake(0, 0, circleSize, circleSize)];

        circleLayer.path = circlePath.CGPath;
        circleLayer.fillColor = successColor.CGColor;
        circleLayer.opacity = 0;

        [self.progressView.layer addSublayer:circleLayer];

        CAShapeLayer *checkmarkLayer = [CAShapeLayer layer];

        UIBezierPath *checkPath = [UIBezierPath bezierPath];
        [checkPath
            moveToPoint:CGPointMake(circleSize * 0.25, circleSize * 0.5)];
        [checkPath
            addLineToPoint:CGPointMake(circleSize * 0.45, circleSize * 0.7)];
        [checkPath
            addLineToPoint:CGPointMake(circleSize * 0.75, circleSize * 0.3)];

        checkmarkLayer.path = checkPath.CGPath;
        checkmarkLayer.fillColor = nil;
        checkmarkLayer.strokeColor = [UIColor whiteColor].CGColor;
        checkmarkLayer.lineWidth = 2.5;
        checkmarkLayer.lineCap = kCALineCapRound;
        checkmarkLayer.lineJoin = kCALineJoinRound;
        checkmarkLayer.strokeEnd = 0;

        [self.progressView.layer addSublayer:checkmarkLayer];

        [UIView animateWithDuration:0.15
            animations:^{
              self.progressLayer.opacity = 0;

              [UIView
                  transitionWithView:self.percentLabel
                            duration:0.2
                             options:
                                 UIViewAnimationOptionTransitionCrossDissolve
                          animations:^{
                            self.percentLabel.text = @"下载完成";
                          }
                          completion:nil];
            }
            completion:^(BOOL finished) {
              CABasicAnimation *circleAnimation =
                  [CABasicAnimation animationWithKeyPath:@"opacity"];
              circleAnimation.fromValue = @0.0;
              circleAnimation.toValue = @1.0;
              circleAnimation.duration = 0.1; // 从0.2改为0.1
              circleLayer.opacity = 1.0;
              [circleLayer addAnimation:circleAnimation forKey:@"fadeIn"];

              dispatch_after(
                  dispatch_time(DISPATCH_TIME_NOW,
                                (int64_t)(0.1 * NSEC_PER_SEC)), // 从0.2改为0.1
                  dispatch_get_main_queue(), ^{
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHapticFeedbackEnabled"]) {
                      UINotificationFeedbackGenerator *feedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
                      [feedbackGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
                    }
                    CABasicAnimation *checkmarkAnimation =
                        [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
                    checkmarkAnimation.fromValue = @0.0;
                    checkmarkAnimation.toValue = @1.0;
                    checkmarkAnimation.duration = 0.15; // 从0.3改为0.15
                    checkmarkAnimation.timingFunction = [CAMediaTimingFunction
                        functionWithName:kCAMediaTimingFunctionEaseOut];
                    checkmarkLayer.strokeEnd = 1.0;
                    [checkmarkLayer addAnimation:checkmarkAnimation
                                          forKey:@"drawCheckmark"];

                    [UIView animateWithDuration:0.15 // 从0.2改为0.15
                        delay:0.1
                        usingSpringWithDamping:0.6
                        initialSpringVelocity:0.8
                        options:UIViewAnimationOptionCurveEaseInOut
                        animations:^{
                          self.progressView.transform =
                              CGAffineTransformMakeScale(1.15, 1.15);
                        }
                        completion:^(BOOL finished) {
                          [UIView animateWithDuration:0.2
                                           animations:^{
                                             self.progressView.transform =
                                                 CGAffineTransformIdentity;
                                           }];
                        }];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                                 (int64_t)(1.2 * NSEC_PER_SEC)),
                                   dispatch_get_main_queue(), ^{
                                     [UIView animateWithDuration:0.2 // 从0.3改为0.2
                                         animations:^{
                                           self.alpha = 0;
                                         }
                                         completion:^(BOOL finished) {
                                           [self removeFromSuperview];
                                           if (completion) {
                                             completion();
                                           }
                                         }];
                                   });
                  });
            }];
      }];
}

// 下载取消动画方法
- (void)showCancelAnimation:(void (^)(void))completion {
  BOOL isDarkMode = [DYYYManager isDarkMode];

  UIColor *cancelColor = isDarkMode ? [UIColor colorWithRed:52/255.0 green:152/255.0 blue:219/255.0 alpha:1.0] 
                                    : [UIColor colorWithRed:41/255.0 green:128/255.0 blue:185/255.0 alpha:1.0];

  // 创建圆形背景
  CAShapeLayer *circleLayer = [CAShapeLayer layer];
  CGFloat circleSize = 30;
  UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, circleSize, circleSize)];

  circleLayer.path = circlePath.CGPath;
  circleLayer.fillColor = cancelColor.CGColor;
  circleLayer.opacity = 0;

  [self.progressView.layer addSublayer:circleLayer];

  CAShapeLayer *crossLayer = [CAShapeLayer layer];
  
  UIBezierPath *crossPath = [UIBezierPath bezierPath];
  
  [crossPath moveToPoint:CGPointMake(circleSize * 0.7, circleSize * 0.3)];
  [crossPath addLineToPoint:CGPointMake(circleSize * 0.3, circleSize * 0.7)];
  [crossPath moveToPoint:CGPointMake(circleSize * 0.3, circleSize * 0.3)];
  [crossPath addLineToPoint:CGPointMake(circleSize * 0.7, circleSize * 0.7)];

  crossLayer.path = crossPath.CGPath;
  crossLayer.fillColor = nil;
  crossLayer.strokeColor = [UIColor whiteColor].CGColor;
  crossLayer.lineWidth = 2.5;
  crossLayer.lineCap = kCALineCapRound;
  crossLayer.lineJoin = kCALineJoinRound;
  crossLayer.strokeEnd = 0;

  [self.progressView.layer addSublayer:crossLayer];

  [UIView animateWithDuration:0.15
      animations:^{
        self.progressLayer.opacity = 0;
        
        [UIView transitionWithView:self.percentLabel
                          duration:0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                          self.percentLabel.text = @"已取消下载";
                        }
                        completion:nil];
      }
      completion:^(BOOL finished) {
        CABasicAnimation *circleAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        circleAnimation.fromValue = @0.0;
        circleAnimation.toValue = @1.0;
        circleAnimation.duration = 0.1; // 从0.2改为0.1
        circleLayer.opacity = 1.0;
        [circleLayer addAnimation:circleAnimation forKey:@"fadeIn"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), // 从0.2改为0.1
                       dispatch_get_main_queue(), ^{
          if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHapticFeedbackEnabled"]) {
              UINotificationFeedbackGenerator *feedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
              [feedbackGenerator notificationOccurred:UINotificationFeedbackTypeError];
          }
          // 绘制叉号
          CABasicAnimation *crossAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
          crossAnimation.fromValue = @0.0;
          crossAnimation.toValue = @1.0;
          crossAnimation.duration = 0.15; // 从0.3改为0.15
          crossAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
          crossLayer.strokeEnd = 1.0;
          [crossLayer addAnimation:crossAnimation forKey:@"drawCross"];
          
          [UIView animateWithDuration:0.15 // 从0.2改为0.15
                                delay:0.1
               usingSpringWithDamping:0.6
                initialSpringVelocity:0.8
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
            self.progressView.transform = CGAffineTransformMakeScale(1.15, 1.15);
          }
                           completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2
                             animations:^{
              self.progressView.transform = CGAffineTransformIdentity;
            }];
          }];
          
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                         dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 // 从0.3改为0.2
                animations:^{
                  self.alpha = 0;
                }
                completion:^(BOOL finished) {
                  [self removeFromSuperview];
                  if (completion) {
                    completion();
                  }
                }];
          });
        });
      }];
}

+ (void)showSuccessToastWithMessage:(NSString *)message {
    DYYYToast *toast = [[DYYYToast alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [toast showSuccessToastWithMessage:message completion:nil];
}

- (void)showSuccessToastWithMessage:(NSString *)message completion:(void (^)(void))completion {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window)
        return;
    for (UIGestureRecognizer *gesture in self.containerView.gestureRecognizers) {
        [self.containerView removeGestureRecognizer:gesture];
    }
    
    [window addSubview:self];

    self.percentLabel.text = message ?: @"成功";
    
    self.progressLayer.opacity = 0;
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         [self directlyShowSuccessAnimation:completion];
                     }];
}

- (void)directlyShowSuccessAnimation:(void (^)(void))completion {
    BOOL isDarkMode = [DYYYManager isDarkMode];

    UIColor *successColor = isDarkMode ? [UIColor colorWithRed:48/255.0 green:209/255.0 blue:151/255.0 alpha:1.0] 
                                      : [UIColor colorWithRed:11/255.0 green:195/255.0 blue:139/255.0 alpha:1.0];
    
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    CGFloat circleSize = 30;
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, circleSize, circleSize)];

    circleLayer.path = circlePath.CGPath;
    circleLayer.fillColor = successColor.CGColor;
    circleLayer.opacity = 0;

    [self.progressView.layer addSublayer:circleLayer];

    CAShapeLayer *checkmarkLayer = [CAShapeLayer layer];

    UIBezierPath *checkPath = [UIBezierPath bezierPath];
    [checkPath moveToPoint:CGPointMake(circleSize * 0.25, circleSize * 0.5)];
    [checkPath addLineToPoint:CGPointMake(circleSize * 0.45, circleSize * 0.7)];
    [checkPath addLineToPoint:CGPointMake(circleSize * 0.75, circleSize * 0.3)];

    checkmarkLayer.path = checkPath.CGPath;
    checkmarkLayer.fillColor = nil;
    checkmarkLayer.strokeColor = [UIColor whiteColor].CGColor;
    checkmarkLayer.lineWidth = 2.5;
    checkmarkLayer.lineCap = kCALineCapRound;
    checkmarkLayer.lineJoin = kCALineJoinRound;
    checkmarkLayer.strokeEnd = 0;

    [self.progressView.layer addSublayer:checkmarkLayer];

    CABasicAnimation *circleAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    circleAnimation.fromValue = @0.0;
    circleAnimation.toValue = @1.0;
    circleAnimation.duration = 0.1;
    circleLayer.opacity = 1.0;
    [circleLayer addAnimation:circleAnimation forKey:@"fadeIn"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHapticFeedbackEnabled"]) {
            UINotificationFeedbackGenerator *feedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
            [feedbackGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
        }
        
        CABasicAnimation *checkmarkAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        checkmarkAnimation.fromValue = @0.0;
        checkmarkAnimation.toValue = @1.0;
        checkmarkAnimation.duration = 0.15;
        checkmarkAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        checkmarkLayer.strokeEnd = 1.0;
        [checkmarkLayer addAnimation:checkmarkAnimation forKey:@"drawCheckmark"];

        [UIView animateWithDuration:0.15
                              delay:0.1
             usingSpringWithDamping:0.6
              initialSpringVelocity:0.8
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.progressView.transform = CGAffineTransformMakeScale(1.15, 1.15);
        }
                         completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2
                             animations:^{
                self.progressView.transform = CGAffineTransformIdentity;
            }];
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2
                             animations:^{
                self.alpha = 0;
            }
                             completion:^(BOOL finished) {
                [self removeFromSuperview];
                if (completion) {
                    completion();
                }
            }];
        });
    });
}

@end
