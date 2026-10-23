// DYYYLiquidGlass.xm
// 新增两个功能：
//   1. 液态玻璃底栏（DYYYEnableLiquidGlass）
//   2. 进度条流光动画（DYYYProgressShimmer）
// 使用方法见文末注释。未在设备上编译测试，请先本地 make 验证。

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "AwemeHeaders.h"   // 提供 DYYYGetBool 以及 AWENormalModeTabBar / AWEFeedProgressSlider 声明

static const NSInteger kDYYYGlassTag = 0xD1A55;
static NSString *const kDYYYShimmerName = @"dyyyShimmer";

#pragma mark - 液态玻璃

static UIVisualEffectView *DYYYMakeGlassView(void) {
    UIVisualEffect *fx = nil;
    // iOS 26+ 才有 UIGlassEffect，用运行时取类，旧 SDK 也能编译
    Class glassCls = NSClassFromString(@"UIGlassEffect");
    if (glassCls) {
        id obj = [[glassCls alloc] init];
        if ([obj isKindOfClass:[UIVisualEffect class]]) {
            fx = obj;
            if ([obj respondsToSelector:NSSelectorFromString(@"setInteractive:")]) {
                [obj setValue:@YES forKey:@"interactive"];
            }
        }
    }
    if (!fx) {
        fx = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    }
    UIVisualEffectView *v = [[UIVisualEffectView alloc] initWithEffect:fx];
    v.userInteractionEnabled = NO;
    v.clipsToBounds = YES;
    v.tag = kDYYYGlassTag;
    return v;
}

%hook AWENormalModeTabBar

- (void)layoutSubviews {
    %orig;

    UIView *old = [self viewWithTag:kDYYYGlassTag];

    if (!DYYYGetBool(@"DYYYEnableLiquidGlass")) {
        [old removeFromSuperview];
        return;
    }

    UIVisualEffectView *glass = (UIVisualEffectView *)old;
    if (!glass) {
        glass = DYYYMakeGlassView();
        [self insertSubview:glass atIndex:0];
    }

    // 悬浮胶囊：左右各留 12，上下各留 6
    CGRect frame = CGRectInset(self.bounds, 12, 6);
    // 底部安全区由原底栏高度承担，这里只包住按钮区域
    CGFloat safeBottom = self.safeAreaInsets.bottom;
    frame.size.height = MAX(44, frame.size.height - safeBottom);
    glass.frame = frame;
    glass.layer.cornerRadius = frame.size.height / 2.0;
    if (@available(iOS 13.0, *)) {
        glass.layer.cornerCurve = kCACornerCurveContinuous;
    }
    [self sendSubviewToBack:glass];

    // 隐藏原底栏背景，避免和玻璃叠在一起
    Class barBg = NSClassFromString(@"_UIBarBackground");
    for (UIView *sub in self.subviews) {
        if (sub == glass) continue;
        if (barBg && [sub isKindOfClass:barBg]) {
            sub.hidden = YES;
        }
    }
}

%end

#pragma mark - 进度条流光

static void DYYYUpdateShimmer(UIView *bar) {
    CAGradientLayer *shimmer = nil;
    for (CALayer *l in bar.layer.sublayers) {
        if ([l.name isEqualToString:kDYYYShimmerName]) {
            shimmer = (CAGradientLayer *)l;
            break;
        }
    }

    if (!DYYYGetBool(@"DYYYProgressShimmer")) {
        [shimmer removeFromSuperlayer];
        return;
    }

    if (!shimmer) {
        shimmer = [CAGradientLayer layer];
        shimmer.name = kDYYYShimmerName;
        shimmer.colors = @[
            (id)[UIColor colorWithWhite:1 alpha:0].CGColor,
            (id)[UIColor colorWithWhite:1 alpha:0.75].CGColor,
            (id)[UIColor colorWithWhite:1 alpha:0].CGColor
        ];
        shimmer.startPoint = CGPointMake(0, 0.5);
        shimmer.endPoint = CGPointMake(1, 0.5);
        shimmer.locations = @[@-0.3, @-0.15, @0];
        

        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"locations"];
        a.toValue = @[@1, @1.15, @1.3];
        a.duration = 1.4;
        a.repeatCount = HUGE_VALF;
        a.removedOnCompletion = NO;
        [shimmer addAnimation:a forKey:@"shimmer"];

        [bar.layer addSublayer:shimmer];
    }

    // 关闭隐式动画，避免布局时 frame 跟着"滑"
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    shimmer.frame = bar.bounds;
    [CATransaction commit];
}

%hook AWEFeedProgressSlider

- (void)layoutSubviews {
    %orig;
    DYYYUpdateShimmer(self);
}

%end

/*
 ========== 接入步骤 ==========

 1) Makefile 第 39 行的 DYYY_FILES 末尾加上：  DYYYLiquidGlass.xm

 2) DYYYSettings.xm 里，紧跟 DYYYEnableSheetBlur 那一项后面加两个开关：

    @{@"identifier" : @"DYYYEnableLiquidGlass",
      @"title" : @"液态玻璃底栏",
      @"detail" : @"",
      @"cellType" : @6,
      @"imageName" : @"ic_list_outlined"},
    @{@"identifier" : @"DYYYProgressShimmer",
      @"title" : @"进度条流光动画",
      @"detail" : @"",
      @"cellType" : @6,
      @"imageName" : @"ic_eye_outlined_20"},

 3) make clean package 编译。
*/
