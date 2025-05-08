#import "DYYYDownloadProgressView.h"
#import "DYYYManager.h"

@interface DYYYDownloadProgressView ()

@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *percentLabel;
@property (nonatomic, assign) CGFloat progress;

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
    _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerWidth, containerHeight)];
    _containerView.center = CGPointMake(CGRectGetMidX(self.bounds), 130); 
    
    _containerView.backgroundColor = isDarkMode ? 
                                    [UIColor darkGrayColor] : 
                                    [UIColor whiteColor];

    _containerView.layer.cornerRadius = containerHeight / 2;
    _containerView.clipsToBounds = YES;
    
    _containerView.userInteractionEnabled = YES;
    [self addSubview:_containerView];
    
    // 阴影效果
    _containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    _containerView.layer.shadowOffset = CGSizeMake(0, 2);
    _containerView.layer.shadowRadius = 6;
    _containerView.layer.shadowOpacity = 0.2;
    
    // 创建环形进度条背景 - 调整大小和位置
    CGFloat circleSize = 30; 
    CGFloat yCenter = containerHeight / 2;
    UIView *progressView = [[UIView alloc] initWithFrame:CGRectMake(10, (containerHeight - circleSize) / 2, circleSize, circleSize)];
    [_containerView addSubview:progressView];
    
    // 创建背景圆环
    CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
    UIBezierPath *circularPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(circleSize/2, circleSize/2)
                                                               radius:circleSize/2 - 2 // 稍微减小半径
                                                           startAngle:-M_PI/2
                                                             endAngle:3*M_PI/2
                                                            clockwise:YES];
    backgroundLayer.path = circularPath.CGPath;
    backgroundLayer.strokeColor = isDarkMode ? 
                                [UIColor colorWithWhite:0.3 alpha:1.0].CGColor : 
                                [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;
    backgroundLayer.fillColor = [UIColor clearColor].CGColor;
    backgroundLayer.lineWidth = 2;
    backgroundLayer.lineCap = kCALineCapRound;
    [progressView.layer addSublayer:backgroundLayer];
    
    // 创建进度圆环
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.path = circularPath.CGPath;
    _progressLayer.strokeColor = [UIColor colorWithRed:11/255.0 green:223/255.0 blue:154/255.0 alpha:1.0].CGColor;
    _progressLayer.fillColor = [UIColor clearColor].CGColor;
    _progressLayer.lineWidth = 2; 
    _progressLayer.lineCap = kCALineCapRound;
    _progressLayer.strokeEnd = 0;
    [progressView.layer addSublayer:_progressLayer];
    
    // 创建百分比标签 - 调整位置和大小
    _percentLabel = [[UILabel alloc] initWithFrame:CGRectMake(circleSize + 15, 0, containerWidth - circleSize - 25, containerHeight)];
    _percentLabel.textAlignment = NSTextAlignmentLeft;
    _percentLabel.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
    _percentLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _percentLabel.text = @"下载中... 0%";
    [_containerView addSubview:_percentLabel];
    
    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] 
                                         initWithTarget:self 
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
  _percentLabel.text = [NSString stringWithFormat:@"下载中... %d%%", percentage];
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