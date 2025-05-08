#import "DYYYDownloadProgressView.h"
#import "DYYYManager.h"

@interface DYYYDownloadProgressView ()

@property(nonatomic, strong) CAShapeLayer *progressLayer;
@property(nonatomic, strong) UILabel *percentLabel;
@property(nonatomic, assign) CGFloat progress;
@property(nonatomic, strong) UIVisualEffectView *blurEffectView;
@property(nonatomic, strong) CAShapeLayer *checkmarkLayer;
@property(nonatomic, strong) UIView *progressView;

@end

@implementation DYYYDownloadProgressView

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
    _progressView = [[UIView alloc]
        initWithFrame:CGRectMake(10, (containerHeight - circleSize) / 2,
                                 circleSize, circleSize)];
    [_containerView addSubview:_progressView];

    CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
    UIBezierPath *circularPath = [UIBezierPath
        bezierPathWithArcCenter:CGPointMake(circleSize / 2, circleSize / 2)
                         radius:circleSize / 2 - 2
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
    CGFloat progressViewRightEdge = _progressView.frame.origin.x + _progressView.frame.size.width;
    CGFloat labelWidth = containerWidth - progressViewRightEdge;
    _percentLabel.frame = CGRectMake(progressViewRightEdge - 3, 0, labelWidth, containerHeight);
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

- (void)showSuccessAnimation:(void (^)(void))completion {
  CGFloat circleSize = 30;
  UIImageView *checkmarkView =
      [[UIImageView alloc] initWithFrame:_progressView.frame];
  checkmarkView.contentMode = UIViewContentModeScaleAspectFit;
  checkmarkView.alpha = 0;

  UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration
      configurationWithPointSize:20
                          weight:UIImageSymbolWeightBold];
  UIImage *checkmarkImage = [UIImage systemImageNamed:@"checkmark.circle.fill"
                                    withConfiguration:config];

  checkmarkView.image = checkmarkImage;
  checkmarkView.tintColor = [UIColor systemGreenColor];
  [_containerView addSubview:checkmarkView];

  [UIView animateWithDuration:0.2
      animations:^{
        _progressView.hidden = YES;
        _percentLabel.text = @"下载完成";

        checkmarkView.alpha = 1.0;
        checkmarkView.transform = CGAffineTransformMakeScale(1.2, 1.2);
      }
      completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2
            animations:^{
              checkmarkView.transform = CGAffineTransformIdentity;
            }
            completion:^(BOOL finished) {
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                           (int64_t)(0.8 * NSEC_PER_SEC)),
                             dispatch_get_main_queue(), ^{
                               [UIView animateWithDuration:0.2
                                   animations:^{
                                     self.alpha = 0;
                                   }
                                   completion:^(BOOL finished) {
                                     [checkmarkView removeFromSuperview];
                                     [self removeFromSuperview];
                                     if (completion) {
                                       completion();
                                     }
                                   }];
                             });
            }];
      }];
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
  [UIView animateWithDuration:0.3
      animations:^{
        self.alpha = 0;
      }
      completion:^(BOOL finished) {
        [self removeFromSuperview];
      }];
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

@end