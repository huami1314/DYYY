//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//  Created on: 2024/10/04
//
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "AwemeHeaders.h"
#import "CityManager.h"
#import "DYYYBottomAlertView.h"
#import "DYYYManager.h"

#import "DYYYConstants.h"

%hook AWEDPlayerFeedPlayerViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
	float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];

	if (defaultSpeed > 0 && defaultSpeed != 1) {
		[self setVideoControllerPlaybackRate:defaultSpeed];
	}

	%orig(arg0);
}

%end

%hook AWEAwemePlayVideoViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
	float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];

	if (defaultSpeed > 0 && defaultSpeed != 1) {
		[self setVideoControllerPlaybackRate:defaultSpeed];
	}

	%orig(arg0);
}

%end

%hook AWEPlayInteractionUserAvatarElement
- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYfollowTips"]) {

		dispatch_async(dispatch_get_main_queue(), ^{
		  [DYYYBottomAlertView showAlertWithTitle:@"关注确认"
						  message:@"是否确认关注？"
					     cancelAction:nil
					    confirmAction:^{
					      %orig(gesture);
					    }];
		});
	} else {
		%orig;
	}
}

%end

%hook AWEPlayInteractionUserAvatarFollowController
- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYfollowTips"]) {

		dispatch_async(dispatch_get_main_queue(), ^{
		  [DYYYBottomAlertView showAlertWithTitle:@"关注确认"
						  message:@"是否确认关注？"
					     cancelAction:nil
					    confirmAction:^{
					      %orig(gesture);
					    }];
		});
	} else {
		%orig;
	}
}

%end

%hook AWENormalModeTabBarGeneralPlusButton
+ (id)button {
	BOOL isHiddenJia = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenJia"];
	if (isHiddenJia) {
		return nil;
	}
	return %orig;
}
%end

%hook AWEFeedContainerContentView
- (void)setAlpha:(CGFloat)alpha {
	// 纯净模式功能
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnablePure"]) {
		%orig(0.0);
		static dispatch_source_t timer = nil;
		static int attempts = 0;
		if (timer) {
			dispatch_source_cancel(timer);
			timer = nil;
		}
		void (^tryFindAndSetPureMode)(void) = ^{
		  UIWindow *keyWindow = [DYYYManager getActiveWindow];
		  if (keyWindow && keyWindow.rootViewController) {
			  UIViewController *feedVC = [self findViewController:keyWindow.rootViewController ofClass:NSClassFromString(@"AWEFeedTableViewController")];
			  if (feedVC) {
				  [feedVC setValue:@YES forKey:@"pureMode"];
				  if (timer) {
					  dispatch_source_cancel(timer);
					  timer = nil;
				  }
				  attempts = 0;
				  return;
			  }
		  }
		  attempts++;
		  if (attempts >= 10) {
			  if (timer) {
				  dispatch_source_cancel(timer);
				  timer = nil;
			  }
			  attempts = 0;
		  }
		};
		timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC, 0);
		dispatch_source_set_event_handler(timer, tryFindAndSetPureMode);
		dispatch_resume(timer);
		tryFindAndSetPureMode();
		return;
	}
	// 原来的透明度设置逻辑，保持不变
	NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYtopbartransparent"];
	if (transparentValue && transparentValue.length > 0) {
		CGFloat alphaValue = [transparentValue floatValue];
		if (alphaValue >= 0.0 && alphaValue <= 1.0) {
			CGFloat finalAlpha = (alphaValue < 0.011) ? 0.011 : alphaValue;
			%orig(finalAlpha);
		} else {
			%orig(1.0);
		}
	} else {
		%orig(1.0);
	}
}
%new
- (UIViewController *)findViewController:(UIViewController *)vc ofClass:(Class)targetClass {
	if (!vc)
		return nil;
	if ([vc isKindOfClass:targetClass])
		return vc;
	for (UIViewController *childVC in vc.childViewControllers) {
		UIViewController *found = [self findViewController:childVC ofClass:targetClass];
		if (found)
			return found;
	}
	return [self findViewController:vc.presentedViewController ofClass:targetClass];
}
%end

// 添加新的 hook 来处理顶栏透明度
%hook AWEFeedTopBarContainer
- (void)layoutSubviews {
	%orig;
	[self applyDYYYTransparency];
}
- (void)didMoveToSuperview {
	%orig;
	[self applyDYYYTransparency];
}
%new
- (void)applyDYYYTransparency {
	// 如果启用了纯净模式，不做任何处理
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnablePure"]) {
		return;
	}

	NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYtopbartransparent"];
	if (transparentValue && transparentValue.length > 0) {
		CGFloat alphaValue = [transparentValue floatValue];
		if (alphaValue >= 0.0 && alphaValue <= 1.0) {
			// 自己骗自己,透明度很小时使用0.011
			CGFloat finalAlpha = (alphaValue < 0.011) ? 0.011 : alphaValue;

			// 设置自身背景色的透明度
			UIColor *backgroundColor = self.backgroundColor;
			if (backgroundColor) {
				CGFloat r, g, b, a;
				if ([backgroundColor getRed:&r green:&g blue:&b alpha:&a]) {
					self.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:finalAlpha * a];
				}
			}

			// 设置视图的alpha
			[(UIView *)self setAlpha:finalAlpha];

			// 确保子视图不会叠加透明度
			for (UIView *subview in self.subviews) {
				subview.alpha = 1.0;
			}
		}
	}
}
%end

// 设置修改顶栏标题
%hook AWEHPTopTabItemTextContentView

- (void)layoutSubviews {
	%orig;

	NSString *topTitleConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYModifyTopTabText"];
	if (topTitleConfig.length == 0)
		return;

	NSArray *titlePairs = [topTitleConfig componentsSeparatedByString:@"#"];

	NSString *accessibilityLabel = nil;
	if ([self.superview respondsToSelector:@selector(accessibilityLabel)]) {
		accessibilityLabel = self.superview.accessibilityLabel;
	}
	if (accessibilityLabel.length == 0)
		return;

	for (NSString *pair in titlePairs) {
		NSArray *components = [pair componentsSeparatedByString:@"="];
		if (components.count != 2)
			continue;

		NSString *originalTitle = components[0];
		NSString *newTitle = components[1];

		if ([accessibilityLabel isEqualToString:originalTitle]) {
			if ([self respondsToSelector:@selector(setContentText:)]) {
				[self setContentText:newTitle];
			} else {
				[self setValue:newTitle forKey:@"contentText"];
			}
			break;
		}
	}
}

%end

%hook AWEDanmakuContentLabel
- (void)setTextColor:(UIColor *)textColor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"]) {
		NSString *danmuColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYdanmuColor"];

		if ([danmuColor.lowercaseString isEqualToString:@"random"] || [danmuColor.lowercaseString isEqualToString:@"#random"]) {
			textColor = [UIColor colorWithRed:(arc4random_uniform(256)) / 255.0
						    green:(arc4random_uniform(256)) / 255.0
						     blue:(arc4random_uniform(256)) / 255.0
						    alpha:CGColorGetAlpha(textColor.CGColor)];
			self.layer.shadowOffset = CGSizeZero;
			self.layer.shadowOpacity = 0.0;
		} else if ([danmuColor hasPrefix:@"#"]) {
			textColor = [self colorFromHexString:danmuColor baseColor:textColor];
			self.layer.shadowOffset = CGSizeZero;
			self.layer.shadowOpacity = 0.0;
		} else {
			textColor = [self colorFromHexString:@"#FFFFFF" baseColor:textColor];
		}
	}

	%orig(textColor);
}

%new
- (UIColor *)colorFromHexString:(NSString *)hexString baseColor:(UIColor *)baseColor {
	if ([hexString hasPrefix:@"#"]) {
		hexString = [hexString substringFromIndex:1];
	}
	if ([hexString length] != 6) {
		return [baseColor colorWithAlphaComponent:1];
	}
	unsigned int red, green, blue;
	[[NSScanner scannerWithString:[hexString substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&red];
	[[NSScanner scannerWithString:[hexString substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&green];
	[[NSScanner scannerWithString:[hexString substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&blue];

	if (red < 128 && green < 128 && blue < 128) {
		return [UIColor whiteColor];
	}

	return [UIColor colorWithRed:(red / 255.0) green:(green / 255.0) blue:(blue / 255.0) alpha:CGColorGetAlpha(baseColor.CGColor)];
}
%end

%hook AWEMarkView

- (void)layoutSubviews {
    %orig;

    UIViewController *vc = [self firstAvailableUIViewController];
    
    if ([vc isKindOfClass:%c(AWEPlayInteractionViewController)]) {
        if (self.markLabel) {
            self.markLabel.textColor = [UIColor whiteColor];
        }
    }
}

%end

%hook AWEDanmakuItemTextInfo
- (void)setDanmakuTextColor:(id)arg1 {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"]) {
		NSString *danmuColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYdanmuColor"];

		if ([danmuColor.lowercaseString isEqualToString:@"random"] || [danmuColor.lowercaseString isEqualToString:@"#random"]) {
			arg1 = [UIColor colorWithRed:(arc4random_uniform(256)) / 255.0 green:(arc4random_uniform(256)) / 255.0 blue:(arc4random_uniform(256)) / 255.0 alpha:1.0];
		} else if ([danmuColor hasPrefix:@"#"]) {
			arg1 = [self colorFromHexStringForTextInfo:danmuColor];
		} else {
			arg1 = [self colorFromHexStringForTextInfo:@"#FFFFFF"];
		}
	}

	%orig(arg1);
}

%new
- (UIColor *)colorFromHexStringForTextInfo:(NSString *)hexString {
	if ([hexString hasPrefix:@"#"]) {
		hexString = [hexString substringFromIndex:1];
	}
	if ([hexString length] != 6) {
		return [UIColor whiteColor];
	}
	unsigned int red, green, blue;
	[[NSScanner scannerWithString:[hexString substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&red];
	[[NSScanner scannerWithString:[hexString substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&green];
	[[NSScanner scannerWithString:[hexString substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&blue];

	if (red < 128 && green < 128 && blue < 128) {
		return [UIColor whiteColor];
	}

	return [UIColor colorWithRed:(red / 255.0) green:(green / 255.0) blue:(blue / 255.0) alpha:1.0];
}
%end

%group DYYYSettingsGesture

%hook UIWindow
- (instancetype)initWithFrame:(CGRect)frame {
	UIWindow *window = %orig(frame);
	if (window) {
		UILongPressGestureRecognizer *doubleFingerLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleFingerLongPressGesture:)];
		doubleFingerLongPressGesture.numberOfTouchesRequired = 2;
		[window addGestureRecognizer:doubleFingerLongPressGesture];
	}
	return window;
}

%new
- (void)handleDoubleFingerLongPressGesture:(UILongPressGestureRecognizer *)gesture {
	if (gesture.state == UIGestureRecognizerStateBegan) {
		UIViewController *rootViewController = self.rootViewController;
		if (rootViewController) {
			UIViewController *settingVC = [[DYYYSettingViewController alloc] init];

			if (settingVC) {
				BOOL isIPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;
				if (@available(iOS 15.0, *)) {
					if (!isIPad) {
						settingVC.modalPresentationStyle = UIModalPresentationPageSheet;
					} else {
						settingVC.modalPresentationStyle = UIModalPresentationFullScreen;
					}
				} else {
					settingVC.modalPresentationStyle = UIModalPresentationFullScreen;
				}

				if (settingVC.modalPresentationStyle == UIModalPresentationFullScreen) {
					UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
					[closeButton setTitle:@"关闭" forState:UIControlStateNormal];
					closeButton.translatesAutoresizingMaskIntoConstraints = NO;

					[settingVC.view addSubview:closeButton];

					[NSLayoutConstraint activateConstraints:@[
						[closeButton.trailingAnchor constraintEqualToAnchor:settingVC.view.trailingAnchor constant:-10],
						[closeButton.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:40], [closeButton.widthAnchor constraintEqualToConstant:80],
						[closeButton.heightAnchor constraintEqualToConstant:40]
					]];

					[closeButton addTarget:self action:@selector(closeSettings:) forControlEvents:UIControlEventTouchUpInside];
				}

				UIView *handleBar = [[UIView alloc] init];
				handleBar.backgroundColor = [UIColor whiteColor];
				handleBar.layer.cornerRadius = 2.5;
				handleBar.translatesAutoresizingMaskIntoConstraints = NO;
				[settingVC.view addSubview:handleBar];

				[NSLayoutConstraint activateConstraints:@[
					[handleBar.centerXAnchor constraintEqualToAnchor:settingVC.view.centerXAnchor],
					[handleBar.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:8], [handleBar.widthAnchor constraintEqualToConstant:40],
					[handleBar.heightAnchor constraintEqualToConstant:5]
				]];

				[rootViewController presentViewController:settingVC animated:YES completion:nil];
			}
		}
	}
}

%new
- (void)closeSettings:(UIButton *)button {
	[button.superview.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}
%end

%end

%hook AWEBaseListViewController
- (void)viewDidLayoutSubviews {
	%orig;
	[self applyBlurEffectIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
	%orig;
	[self applyBlurEffectIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
	%orig;
	[self applyBlurEffectIfNeeded];
}

%new
- (void)applyBlurEffectIfNeeded {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"] &&
	    [self isKindOfClass:NSClassFromString(@"AWECommentPanelContainerSwiftImpl.CommentContainerInnerViewController")]) {

		self.view.backgroundColor = [UIColor clearColor];
		for (UIView *subview in self.view.subviews) {
			if (![subview isKindOfClass:[UIVisualEffectView class]]) {
				subview.backgroundColor = [UIColor clearColor];
			}
		}

		UIVisualEffectView *existingBlurView = nil;
		for (UIView *subview in self.view.subviews) {
			if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 999) {
				existingBlurView = (UIVisualEffectView *)subview;
				break;
			}
		}

		BOOL isDarkMode = [DYYYManager isDarkMode];

		UIBlurEffectStyle blurStyle = isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;

		// 动态获取用户设置的透明度
		float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
		if (userTransparency <= 0 || userTransparency > 1) {
			userTransparency = 0.5; // 默认值0.5（半透明）
		}

		if (!existingBlurView) {
			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			blurEffectView.frame = self.view.bounds;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.alpha = userTransparency; // 设置为用户自定义透明度
			blurEffectView.tag = 999;

			UIView *overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
			CGFloat alpha = isDarkMode ? 0.2 : 0.1;
			overlayView.backgroundColor = [UIColor colorWithWhite:(isDarkMode ? 0 : 1) alpha:alpha];
			overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			[blurEffectView.contentView addSubview:overlayView];

			[self.view insertSubview:blurEffectView atIndex:0];
		} else {
			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
			[existingBlurView setEffect:blurEffect];

			existingBlurView.alpha = userTransparency; // 动态更新已有视图的透明度

			for (UIView *subview in existingBlurView.contentView.subviews) {
				if (subview.tag != 999) {
					CGFloat alpha = isDarkMode ? 0.2 : 0.1;
					subview.backgroundColor = [UIColor colorWithWhite:(isDarkMode ? 0 : 1) alpha:alpha];
				}
			}

			[self.view insertSubview:existingBlurView atIndex:0];
		}
	}
}
%end

%hook UIView

- (void)setAlpha:(CGFloat)alpha {
	UIViewController *vc = [self firstAvailableUIViewController];

	if ([vc isKindOfClass:%c(AWEPlayInteractionViewController)] && alpha > 0) {
		NSString *transparentValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYGlobalTransparency"];
		if (transparentValue.length > 0) {
			CGFloat alphaValue = transparentValue.floatValue;
			if (alphaValue >= 0.0 && alphaValue <= 1.0) {
				%orig(alphaValue);
				return;
			}
		}
	}
	%orig;
}

%new
- (UIViewController *)firstAvailableUIViewController {
	UIResponder *responder = [self nextResponder];
	while (responder != nil) {
		if ([responder isKindOfClass:[UIViewController class]]) {
			return (UIViewController *)responder;
		}
		responder = [responder nextResponder];
	}
	return nil;
}

%end

%hook AWEFeedVideoButton
- (id)touchUpInsideBlock {
	id r = %orig;

	// 只有收藏按钮才显示确认弹窗
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYcollectTips"] && [self.accessibilityLabel isEqualToString:@"收藏"]) {

		dispatch_async(dispatch_get_main_queue(), ^{
		  [DYYYBottomAlertView showAlertWithTitle:@"收藏确认"
						  message:@"是否确认/取消收藏？"
					     cancelAction:nil
					    confirmAction:^{
					      if (r && [r isKindOfClass:NSClassFromString(@"NSBlock")]) {
						      ((void (^)(void))r)();
					      }
					    }];
		});

		return nil; // 阻止原始 block 立即执行
	}

	return r;
}
%end

%hook AWEFeedProgressSlider

- (void)layoutSubviews {
	%orig;
	[self applyCustomProgressStyle];
}

%new
- (void)applyCustomProgressStyle {
    NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];

    if ([scheduleStyle isEqualToString:@"进度条两侧左右"]) {
        // 获取父视图宽度，以便计算新的宽度
        CGFloat parentWidth = self.superview.bounds.size.width;
        
        // 计算宽度百分比和边距
        CGFloat widthPercent = 0.80;
        NSString *widthPercentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressBarWidthPercent"];
        if (widthPercentValue.length > 0) {
            CGFloat customPercent = [widthPercentValue floatValue];
            if (customPercent > 0 && customPercent <= 1.0) {
                widthPercent = customPercent;
            }
        }

        // 调整进度条宽度和位置
        CGFloat newWidth = parentWidth * widthPercent;
        CGFloat centerX = self.frame.origin.x + self.frame.size.width / 2;
        CGFloat newX = centerX - newWidth / 2;
        CGFloat height = self.frame.size.height;
        CGFloat y = self.frame.origin.y;
        
        // 使用 CGRectMake 创建新的 frame
        self.frame = CGRectMake(newX, y, newWidth, height);

    }
}

// 开启视频进度条后默认显示进度条的透明度否则有部分视频不会显示进度条以及秒数
- (void)setAlpha:(CGFloat)alpha {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]) {
		// 如果启用了隐藏视频进度，进度条透明度为0
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideVideoProgress"]) {
			%orig(0);
		} else {
			%orig(1.0);
		}
	} else {
		%orig;
	}
}

// MARK: 视频显示进度条以及视频进度秒数
- (void)setLimitUpperActionArea:(BOOL)arg1 {
	%orig;
	// 定义一下进度条默认算法
	NSString *duration = [self.progressSliderDelegate formatTimeFromSeconds:floor(self.progressSliderDelegate.model.videoDuration / 1000)];
	// 如果开启了显示时间进度
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]) {
		UIView *parentView = self.superview;
		if (!parentView)
			return;

		// 移除之前可能存在的标签
		[[parentView viewWithTag:10001] removeFromSuperview];
		[[parentView viewWithTag:10002] removeFromSuperview];

		// 计算标签在父视图中的位置
		CGRect sliderFrame = [self convertRect:self.bounds toView:parentView];

		// 获取垂直偏移量配置值，默认为-12.5
		CGFloat verticalOffset = -12.5;
		NSString *offsetValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimelineVerticalPosition"];
		if (offsetValue.length > 0) {
			CGFloat configOffset = [offsetValue floatValue];
			if (configOffset != 0) {
				verticalOffset = configOffset;
			}
		}

		// 获取显示样式设置
		NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
		BOOL showRemainingTime = [scheduleStyle isEqualToString:@"进度条右侧剩余"];
		BOOL showCompleteTime = [scheduleStyle isEqualToString:@"进度条右侧完整"];
		BOOL showLeftRemainingTime = [scheduleStyle isEqualToString:@"进度条左侧剩余"];
		BOOL showLeftCompleteTime = [scheduleStyle isEqualToString:@"进度条左侧完整"];

		// 获取用户设置的时间标签颜色
		NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressLabelColor"];
		UIColor *labelColor = [UIColor whiteColor]; // 默认白色
		if (labelColorHex && labelColorHex.length > 0) {
			labelColor = [DYYYManager colorWithHexString:labelColorHex];
		}

		// 创建左侧时间标签 - 根据不同的显示模式处理
		if (!showRemainingTime && !showCompleteTime) {
			UILabel *leftLabel = [[UILabel alloc] init];
			leftLabel.frame = CGRectMake(sliderFrame.origin.x, sliderFrame.origin.y + verticalOffset, 50, 15);
			leftLabel.backgroundColor = [UIColor clearColor];

			// 根据左侧显示模式设置不同的初始文本
			if (showLeftRemainingTime) {
				[leftLabel setText:@"00:00"]; // 剩余时间模式
			} else if (showLeftCompleteTime) {
				[leftLabel setText:[NSString stringWithFormat:@"00:00/%@", duration]]; // 完整时间模式
			} else {
				[leftLabel setText:@"00:00"]; // 默认模式
			}

			[leftLabel setTextColor:labelColor];
			[leftLabel setFont:[UIFont systemFontOfSize:8]];
			leftLabel.tag = 10001;
			[parentView addSubview:leftLabel];
		}

		// 只在非左侧显示模式下创建右侧标签
		if (!showLeftRemainingTime && !showLeftCompleteTime) {
			UILabel *rightLabel = [[UILabel alloc] init];
			if (showCompleteTime) {
				rightLabel.frame = CGRectMake(sliderFrame.origin.x + sliderFrame.size.width - 50, sliderFrame.origin.y + verticalOffset, 50, 15);
				// 修改这里：始终使用 00:00/时长 的格式
				[rightLabel setText:[NSString stringWithFormat:@"00:00/%@", duration]];
			} else {
				rightLabel.frame = CGRectMake(sliderFrame.origin.x + sliderFrame.size.width - 23, sliderFrame.origin.y + verticalOffset, 50, 15);
				[rightLabel setText:showRemainingTime ? @"00:00" : duration];
			}
			rightLabel.backgroundColor = [UIColor clearColor];
			[rightLabel setTextColor:labelColor];
			[rightLabel setFont:[UIFont systemFontOfSize:8]];
			rightLabel.tag = 10002;
			[parentView addSubview:rightLabel];
		}
	}
}

%end

// MARK: 视频显示-算法
%hook AWEPlayInteractionProgressController
%new
// 根据时间来给算法
- (NSString *)formatTimeFromSeconds:(CGFloat)seconds {
	// 小时
	NSInteger hours = (NSInteger)seconds / 3600;
	// 分钟
	NSInteger minutes = ((NSInteger)seconds % 3600) / 60;
	// 秒数
	NSInteger secs = (NSInteger)seconds % 60;

	// 定义进度条实例
	AWEFeedProgressSlider *progressSlider = self.progressSlider;
	UIView *parentView = progressSlider.superview;
	UILabel *rightLabel = [parentView viewWithTag:10002];

	// 如果视频超过 60 分钟
	if (hours > 0) {
		// 主线程设置他的显示总时间进度条位置
		dispatch_async(dispatch_get_main_queue(), ^{
		  if (rightLabel) {
			  CGRect sliderFrame = [progressSlider convertRect:progressSlider.bounds toView:parentView];
			  CGRect frame = rightLabel.frame;
			  frame.origin.x = sliderFrame.origin.x + sliderFrame.size.width - 46;
			  // 保持原来的垂直位置
			  rightLabel.frame = frame;
		  }
		});
		// 返回 00:00:00
		return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)secs];
	} else {
		// 返回 00:00
		return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)secs];
	}
}

- (void)updateProgressSliderWithTime:(CGFloat)arg1 totalDuration:(CGFloat)arg2 {
	%orig;
	// 如果开启了显示视频进度
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]) {
		// 获取进度条实例
		AWEFeedProgressSlider *progressSlider = self.progressSlider;
		UIView *parentView = progressSlider.superview;

		UILabel *leftLabel = [parentView viewWithTag:10001];
		UILabel *rightLabel = [parentView viewWithTag:10002];

		// 获取用户设置的时间标签颜色
		NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressLabelColor"];
		UIColor *labelColor = [UIColor whiteColor]; // 默认白色
		if (labelColorHex && labelColorHex.length > 0) {
			labelColor = [DYYYManager colorWithHexString:labelColorHex];
		}

		// 获取显示样式设置
		NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
		BOOL showRemainingTime = [scheduleStyle isEqualToString:@"进度条右侧剩余"];
		BOOL showCompleteTime = [scheduleStyle isEqualToString:@"进度条右侧完整"];
		BOOL showLeftRemainingTime = [scheduleStyle isEqualToString:@"进度条左侧剩余"];
		BOOL showLeftCompleteTime = [scheduleStyle isEqualToString:@"进度条左侧完整"];

		// 如果检测到时间
		if (arg1 > 0 && leftLabel) {
			if (showLeftRemainingTime) {
				// 计算剩余时间
				CGFloat remainingTime = arg2 - arg1;
				if (remainingTime < 0)
					remainingTime = 0;
				[leftLabel setText:[NSString stringWithFormat:@"%@", [self formatTimeFromSeconds:remainingTime]]];
			} else if (showLeftCompleteTime) {
				// 显示当前时间/总时间
				[leftLabel setText:[NSString stringWithFormat:@"%@/%@", [self formatTimeFromSeconds:arg1], [self formatTimeFromSeconds:arg2]]];
			} else {
				// 常规模式显示当前时间
				[leftLabel setText:[self formatTimeFromSeconds:arg1]];
			}
			[leftLabel setTextColor:labelColor];
		}
		if (arg2 > 0 && rightLabel) {
			if (showRemainingTime) {
				CGFloat remainingTime = arg2 - arg1;
				if (remainingTime < 0)
					remainingTime = 0;
				[rightLabel setText:[NSString stringWithFormat:@"%@", [self formatTimeFromSeconds:remainingTime]]];
			} else if (showCompleteTime) {
				[rightLabel setText:[NSString stringWithFormat:@"%@/%@", [self formatTimeFromSeconds:arg1], [self formatTimeFromSeconds:arg2]]];
			} else {
				[rightLabel setText:[self formatTimeFromSeconds:arg2]];
			}
			[rightLabel setTextColor:labelColor];
		}
	}
}

// 增加检测是否隐藏视频进度条的处理
- (void)setHidden:(BOOL)hidden {
	%orig;

	BOOL hideVideoProgress = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideVideoProgress"];
	BOOL showScheduleDisplay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"];

	// 如果需要隐藏视频进度但显示时长
	if (hideVideoProgress && showScheduleDisplay && !hidden) {
		self.alpha = 0;
	}
}

%end

%hook AWEFakeProgressSliderView
- (void)layoutSubviews {
	%orig;
	[self applyCustomProgressStyle];
}

%new
- (void)applyCustomProgressStyle {
	NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];

	if ([scheduleStyle isEqualToString:@"进度条两侧左右"]) {
		for (UIView *subview in self.subviews) {
			if ([subview class] == [UIView class]) {
				subview.hidden = YES;
			}
		}
	}
}
%end

%hook AWENormalModeTabBarTextView

- (void)layoutSubviews {
	%orig;

	NSString *indexTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYIndexTitle"];
	NSString *friendsTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFriendsTitle"];
	NSString *msgTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYMsgTitle"];
	NSString *selfTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYSelfTitle"];

	for (UIView *subview in [self subviews]) {
		if ([subview isKindOfClass:[UILabel class]]) {
			UILabel *label = (UILabel *)subview;
			if ([label.text isEqualToString:@"首页"]) {
				if (indexTitle.length > 0) {
					[label setText:indexTitle];
					[self setNeedsLayout];
				}
			}
			if ([label.text isEqualToString:@"朋友"]) {
				if (friendsTitle.length > 0) {
					[label setText:friendsTitle];
					[self setNeedsLayout];
				}
			}
			if ([label.text isEqualToString:@"消息"]) {
				if (msgTitle.length > 0) {
					[label setText:msgTitle];
					[self setNeedsLayout];
				}
			}
			if ([label.text isEqualToString:@"我"]) {
				if (selfTitle.length > 0) {
					[label setText:selfTitle];
					[self setNeedsLayout];
				}
			}
		}
	}
}
%end

%hook AWEFeedIPhoneAutoPlayManager

- (BOOL)isAutoPlayOpen {
	BOOL r = %orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableAutoPlay"]) {
		return YES;
	}
	return r;
}

%end

%hook AWEFeedModuleService

- (BOOL)getFeedIphoneAutoPlayState {
	BOOL r = %orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableAutoPlay"]) {
		return YES;
	}
	return %orig;
}
%end

%hook AWEPlayInteractionTimestampElement
- (id)timestampLabel {
	UILabel *label = %orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"]) {
		NSString *text = label.text;
		NSString *cityCode = self.model.cityCode;

		if (cityCode.length > 0) {
			NSString *cityName = [CityManager.sharedInstance getCityNameWithCode:cityCode];
			NSString *provinceName = [CityManager.sharedInstance getProvinceNameWithCode:cityCode];
			// 使用 GeoNames API
			if (!cityName || cityName.length == 0) {
				NSString *cacheKey = cityCode;

				static NSCache *geoNamesCache = nil;
				static dispatch_once_t onceToken;
				dispatch_once(&onceToken, ^{
				  geoNamesCache = [[NSCache alloc] init];
				  geoNamesCache.name = @"com.dyyy.geonames.cache";
				  geoNamesCache.countLimit = 1000;
				});

				NSDictionary *cachedData = [geoNamesCache objectForKey:cacheKey];

				if (!cachedData) {
					NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
					NSString *geoNamesCacheDir = [cachesDir stringByAppendingPathComponent:@"DYYYGeoNamesCache"];

					NSFileManager *fileManager = [NSFileManager defaultManager];
					if (![fileManager fileExistsAtPath:geoNamesCacheDir]) {
						[fileManager createDirectoryAtPath:geoNamesCacheDir withIntermediateDirectories:YES attributes:nil error:nil];
					}

					NSString *cacheFilePath = [geoNamesCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", cacheKey]];

					if ([fileManager fileExistsAtPath:cacheFilePath]) {
						cachedData = [NSDictionary dictionaryWithContentsOfFile:cacheFilePath];
						if (cachedData) {
							[geoNamesCache setObject:cachedData forKey:cacheKey];
						}
					}
				}

				if (cachedData) {
					NSString *countryName = cachedData[@"countryName"];
					NSString *adminName1 = cachedData[@"adminName1"];
					NSString *localName = cachedData[@"name"];
					NSString *displayLocation = @"未知";

					if (countryName.length > 0) {
						if (adminName1.length > 0 && localName.length > 0 && ![countryName isEqualToString:@"中国"] && ![countryName isEqualToString:localName]) {
							// 国外位置：国家 + 州/省 + 地点
							displayLocation = [NSString stringWithFormat:@"%@ %@ %@", countryName, adminName1, localName];
						} else if (localName.length > 0 && ![countryName isEqualToString:localName]) {
							// 只有国家和地点名
							displayLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
						} else {
							// 只有国家名
							displayLocation = countryName;
						}
					} else if (localName.length > 0) {
						displayLocation = localName;
					}

					dispatch_async(dispatch_get_main_queue(), ^{
					  NSString *currentText = label.text ?: @"";

					  if ([currentText containsString:@"IP属地："]) {
						  NSRange range = [currentText rangeOfString:@"IP属地："];
						  if (range.location != NSNotFound) {
							  NSString *baseText = [currentText substringToIndex:range.location];
							  if (![currentText containsString:displayLocation]) {
								  label.text = [NSString stringWithFormat:@"%@IP属地：%@", baseText, displayLocation];
							  }
						  }
					  } else {
						  NSString *baseText = label.text ?: @"";
						  if (baseText.length > 0) {
							  label.text = [NSString stringWithFormat:@"%@  IP属地：%@", baseText, displayLocation];
						  }
					  }
					});
				} else {
					[CityManager fetchLocationWithGeonameId:cityCode
							      completionHandler:^(NSDictionary *locationInfo, NSError *error) {
								if (locationInfo) {
									NSString *countryName = locationInfo[@"countryName"];
									NSString *adminName1 = locationInfo[@"adminName1"]; // 州/省级名称
									NSString *localName = locationInfo[@"name"];	    // 当前地点名称
									NSString *displayLocation = @"未知";

									// 根据返回数据构建位置显示文本
									if (countryName.length > 0) {
										if (adminName1.length > 0 && localName.length > 0 && ![countryName isEqualToString:@"中国"] &&
										    ![countryName isEqualToString:localName]) {
											// 国外位置：国家 + 州/省 + 地点
											displayLocation = [NSString stringWithFormat:@"%@ %@ %@", countryName, adminName1, localName];
										} else if (localName.length > 0 && ![countryName isEqualToString:localName]) {
											// 只有国家和地点名
											displayLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
										} else {
											// 只有国家名
											displayLocation = countryName;
										}
									} else if (localName.length > 0) {
										displayLocation = localName;
									}

									[geoNamesCache setObject:locationInfo forKey:cacheKey];

									NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
									NSString *geoNamesCacheDir = [cachesDir stringByAppendingPathComponent:@"DYYYGeoNamesCache"];
									NSString *cacheFilePath = [geoNamesCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", cacheKey]];

									[locationInfo writeToFile:cacheFilePath atomically:YES];

									dispatch_async(dispatch_get_main_queue(), ^{
									  NSString *currentText = label.text ?: @"";

									  if ([currentText containsString:@"IP属地："]) {
										  NSRange range = [currentText rangeOfString:@"IP属地："];
										  if (range.location != NSNotFound) {
											  NSString *baseText = [currentText substringToIndex:range.location];
											  if (![currentText containsString:displayLocation]) {
												  label.text = [NSString stringWithFormat:@"%@IP属地：%@", baseText, displayLocation];
											  }
										  }
									  } else {
										  NSString *baseText = label.text ?: @"";
										  if (baseText.length > 0) {
											  label.text = [NSString stringWithFormat:@"%@  IP属地：%@", baseText, displayLocation];
										  }
									  }
									});
								}
							      }];
				}
			} else if (![text containsString:cityName]) {
				if (!self.model.ipAttribution) {
					BOOL isDirectCity = [provinceName isEqualToString:cityName] ||
							    ([cityCode hasPrefix:@"11"] || [cityCode hasPrefix:@"12"] || [cityCode hasPrefix:@"31"] || [cityCode hasPrefix:@"50"]);

					if (isDirectCity) {
						label.text = [NSString stringWithFormat:@"%@  IP属地：%@", text, cityName];
					} else {
						label.text = [NSString stringWithFormat:@"%@  IP属地：%@ %@", text, provinceName, cityName];
					}
				} else {
					BOOL isDirectCity = [provinceName isEqualToString:cityName] ||
							    ([cityCode hasPrefix:@"11"] || [cityCode hasPrefix:@"12"] || [cityCode hasPrefix:@"31"] || [cityCode hasPrefix:@"50"]);

					BOOL containsProvince = [text containsString:provinceName];
					if (containsProvince && !isDirectCity) {
						label.text = [NSString stringWithFormat:@"%@ %@", text, cityName];
					} else if (containsProvince && isDirectCity) {
						label.text = [NSString stringWithFormat:@"%@  IP属地：%@", text, cityName];
					} else if (isDirectCity && containsProvince) {
						label.text = text;
					} else if (containsProvince) {
						label.text = [NSString stringWithFormat:@"%@ %@", text, cityName];
					} else {
						label.text = text;
					}
				}
			}
		}
	}
	// 应用IP属地标签上移
	NSString *ipScaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];
	if (ipScaleValue.length > 0) {
		UIFont *originalFont = label.font;
		CGRect originalFrame = label.frame;
		CGFloat offset = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYIPLabelVerticalOffset"];
		if (offset > 0) {
			CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(0, -offset);
			label.transform = translationTransform;
		} else {
			CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(0, -3);
			label.transform = translationTransform;
		}

		label.font = originalFont;
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnabsuijiyanse"]) {
		UIColor *color1 = [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
						  green:(CGFloat)arc4random_uniform(256) / 255.0
						   blue:(CGFloat)arc4random_uniform(256) / 255.0
						  alpha:1.0];
		UIColor *color2 = [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
						  green:(CGFloat)arc4random_uniform(256) / 255.0
						   blue:(CGFloat)arc4random_uniform(256) / 255.0
						  alpha:1.0];
		UIColor *color3 = [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
						  green:(CGFloat)arc4random_uniform(256) / 255.0
						   blue:(CGFloat)arc4random_uniform(256) / 255.0
						  alpha:1.0];

		NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:label.text];
		CFIndex length = [attributedText length];
		for (CFIndex i = 0; i < length; i++) {
			CGFloat progress = (CGFloat)i / (length == 0 ? 1 : length - 1);

			UIColor *startColor;
			UIColor *endColor;
			CGFloat subProgress;

			if (progress < 0.5) {
				startColor = color1;
				endColor = color2;
				subProgress = progress * 2;
			} else {
				startColor = color2;
				endColor = color3;
				subProgress = (progress - 0.5) * 2;
			}

			CGFloat startRed, startGreen, startBlue, startAlpha;
			CGFloat endRed, endGreen, endBlue, endAlpha;
			[startColor getRed:&startRed green:&startGreen blue:&startBlue alpha:&startAlpha];
			[endColor getRed:&endRed green:&endGreen blue:&endBlue alpha:&endAlpha];

			CGFloat red = startRed + (endRed - startRed) * subProgress;
			CGFloat green = startGreen + (endGreen - startGreen) * subProgress;
			CGFloat blue = startBlue + (endBlue - startBlue) * subProgress;
			CGFloat alpha = startAlpha + (endAlpha - startAlpha) * subProgress;

			UIColor *currentColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
			[attributedText addAttribute:NSForegroundColorAttributeName value:currentColor range:NSMakeRange(i, 1)];
		}

		label.attributedText = attributedText;
	} else {
		NSString *labelColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelColor"];
		if (labelColor.length > 0) {
			label.textColor = [DYYYManager colorWithHexString:labelColor];
		}
	}
	return label;
}

+ (BOOL)shouldActiveWithData:(id)arg1 context:(id)arg2 {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"];
}

%end

%hook AWEPlayInteractionDescriptionScrollView

- (void)layoutSubviews {
	%orig;

	self.transform = CGAffineTransformIdentity;

	NSString *descriptionOffsetValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDescriptionVerticalOffset"];
	CGFloat verticalOffset = 0;
	if (descriptionOffsetValue.length > 0) {
		verticalOffset = [descriptionOffsetValue floatValue];
	}

	UIView *parentView = self.superview;
	UIView *grandParentView = nil;

	if (parentView) {
		grandParentView = parentView.superview;
	}

	if (grandParentView && verticalOffset != 0) {
		CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(0, verticalOffset);
		grandParentView.transform = translationTransform;
	}
}

%end

// 对新版文案的偏移（33.0以上）
%hook AWEPlayInteractionDescriptionLabel

- (void)layoutSubviews {
	%orig;

	self.transform = CGAffineTransformIdentity;

	NSString *descriptionOffsetValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDescriptionVerticalOffset"];
	CGFloat verticalOffset = 0;
	if (descriptionOffsetValue.length > 0) {
		verticalOffset = [descriptionOffsetValue floatValue];
	}

	UIView *parentView = self.superview;
	UIView *grandParentView = nil;

	if (parentView) {
		grandParentView = parentView.superview;
	}

	if (grandParentView && verticalOffset != 0) {
		CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(0, verticalOffset);
		grandParentView.transform = translationTransform;
	}
}

%end

%hook AWEUserNameLabel

- (void)layoutSubviews {
	%orig;

	self.transform = CGAffineTransformIdentity;

	// 添加垂直偏移支持
	NSString *verticalOffsetValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameVerticalOffset"];
	CGFloat verticalOffset = 0;
	if (verticalOffsetValue.length > 0) {
		verticalOffset = [verticalOffsetValue floatValue];
	}

	UIView *parentView = self.superview;
	UIView *grandParentView = nil;

	if (parentView) {
		grandParentView = parentView.superview;
	}

	// 检查祖父视图是否为 AWEBaseElementView 类型
	if (grandParentView && [grandParentView.superview isKindOfClass:%c(AWEBaseElementView)]) {
		CGRect scaledFrame = grandParentView.frame;
		CGFloat translationX = -scaledFrame.origin.x;

		CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(translationX, verticalOffset);
		grandParentView.transform = translationTransform;
	}
}

%end

%hook AWEFeedVideoButton

- (void)setImage:(id)arg1 {
	NSString *nameString = nil;

	if ([self respondsToSelector:@selector(imageNameString)]) {
		nameString = [self performSelector:@selector(imageNameString)];
	}

	if (!nameString) {
		%orig;
		return;
	}

	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
	NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];

	[[NSFileManager defaultManager] createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:nil];

	NSDictionary *iconMapping = @{
		@"icon_home_like_after" : @"like_after.png",
		@"icon_home_like_before" : @"like_before.png",
		@"icon_home_comment" : @"comment.png",
		@"icon_home_unfavorite" : @"unfavorite.png",
		@"icon_home_favorite" : @"favorite.png",
		@"iconHomeShareRight" : @"share.png"
	};

	NSString *customFileName = nil;
	if ([nameString containsString:@"_comment"]) {
		customFileName = @"comment.png";
	} else if ([nameString containsString:@"_like"]) {
		customFileName = @"like_before.png";
	} else if ([nameString containsString:@"_collect"]) {
		customFileName = @"unfavorite.png";
	} else if ([nameString containsString:@"_share"]) {
		customFileName = @"share.png";
	}

	for (NSString *prefix in iconMapping.allKeys) {
		if ([nameString hasPrefix:prefix]) {
			customFileName = iconMapping[prefix];
			break;
		}
	}

	if (customFileName) {
		NSString *customImagePath = [dyyyFolderPath stringByAppendingPathComponent:customFileName];

		if ([[NSFileManager defaultManager] fileExistsAtPath:customImagePath]) {
			UIImage *customImage = [UIImage imageWithContentsOfFile:customImagePath];
			if (customImage) {
				CGFloat targetWidth = 44.0;
				CGFloat targetHeight = 44.0;
				CGSize originalSize = customImage.size;

				CGFloat scale = MIN(targetWidth / originalSize.width, targetHeight / originalSize.height);
				CGFloat newWidth = originalSize.width * scale;
				CGFloat newHeight = originalSize.height * scale;

				UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), NO, 0.0);
				[customImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
				UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();

				if (resizedImage) {
					%orig(resizedImage);
					return;
				}
			}
		}
	}

	%orig;
}

%end

// 获取资源的地址
%hook AWEURLModel
%new - (NSURL *)getDYYYSrcURLDownload {
	;
	NSURL *bestURL;
	for (NSString *url in self.originURLList) {
		if ([url containsString:@"video_mp4"] || [url containsString:@".jpeg"] || [url containsString:@".mp3"]) {
			bestURL = [NSURL URLWithString:url];
		}
	}

	if (bestURL == nil) {
		bestURL = [NSURL URLWithString:[self.originURLList firstObject]];
	}

	return bestURL;
}
%end

// 禁用点击首页刷新
%hook AWENormalModeTabBarGeneralButton

- (BOOL)enableRefresh {
	if ([self.accessibilityLabel isEqualToString:@"首页"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDisableHomeRefresh"]) {
			return NO;
		}
	}
	return %orig;
}

%end

// 屏蔽版本更新
%hook AWEVersionUpdateManager

- (void)startVersionUpdateWorkflow:(id)arg1 completion:(id)arg2 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoUpdates"]) {
		if (arg2) {
			void (^completionBlock)(void) = arg2;
			completionBlock();
		}
	} else {
		%orig;
	}
}

- (id)workflow {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoUpdates"] ? nil : %orig;
}

- (id)badgeModule {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoUpdates"] ? nil : %orig;
}

%end

// 应用内推送毛玻璃效果
%hook AWEInnerNotificationWindow

- (id)initWithFrame:(CGRect)frame {
	id orig = %orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableNotificationTransparency"]) {
		[self setupBlurEffectForNotificationView];
	}
	return orig;
}

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableNotificationTransparency"]) {
		[self setupBlurEffectForNotificationView];
	}
}

- (void)didMoveToWindow {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableNotificationTransparency"]) {
		[self setupBlurEffectForNotificationView];
	}
}

- (void)didAddSubview:(UIView *)subview {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableNotificationTransparency"] && [NSStringFromClass([subview class]) containsString:@"AWEInnerNotificationContainerView"]) {
		[self setupBlurEffectForNotificationView];
	}
}

%new
- (void)setupBlurEffectForNotificationView {
	for (UIView *subview in self.subviews) {
		if ([NSStringFromClass([subview class]) containsString:@"AWEInnerNotificationContainerView"]) {
			[self applyBlurEffectToView:subview];
			break;
		}
	}
}

%new
- (void)applyBlurEffectToView:(UIView *)containerView {
	if (!containerView) {
		return;
	}

	containerView.backgroundColor = [UIColor clearColor];

	float userRadius = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNotificationCornerRadius"] floatValue];
	if (!userRadius || userRadius < 0 || userRadius > 50) {
		userRadius = 12;
	}

	containerView.layer.cornerRadius = userRadius;
	containerView.layer.masksToBounds = YES;

	for (UIView *subview in containerView.subviews) {
		if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 999) {
			[subview removeFromSuperview];
		}
	}

	BOOL isDarkMode = [DYYYManager isDarkMode];
	UIBlurEffectStyle blurStyle = isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
	UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
	UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

	blurView.frame = containerView.bounds;
	blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	blurView.tag = 999;
	blurView.layer.cornerRadius = userRadius;
	blurView.layer.masksToBounds = YES;

	float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
	if (userTransparency <= 0 || userTransparency > 1) {
		userTransparency = 0.5;
	}

	blurView.alpha = userTransparency;

	[containerView insertSubview:blurView atIndex:0];

	[self clearBackgroundRecursivelyInView:containerView];

	[self setLabelsColorWhiteInView:containerView];
}

%new
- (void)setLabelsColorWhiteInView:(UIView *)view {
	for (UIView *subview in view.subviews) {
		if ([subview isKindOfClass:[UILabel class]]) {
			UILabel *label = (UILabel *)subview;
			NSString *text = label.text;

			if (![text isEqualToString:@"回复"] && ![text isEqualToString:@"查看"] && ![text isEqualToString:@"续火花"]) {
				label.textColor = [UIColor whiteColor];
			}
		}
		[self setLabelsColorWhiteInView:subview];
	}
}

%new
- (void)clearBackgroundRecursivelyInView:(UIView *)view {
	for (UIView *subview in view.subviews) {
		if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 999 && [subview isKindOfClass:[UIButton class]]) {
			continue;
		}
		subview.backgroundColor = [UIColor clearColor];
		subview.opaque = NO;
		[self clearBackgroundRecursivelyInView:subview];
	}
}

%end

// 为 AWEUserActionSheetView 添加毛玻璃效果
%hook AWEUserActionSheetView

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableSheetBlur"]) {
		[self applyBlurEffectAndWhiteText];
	}
}

%new
- (void)applyBlurEffectAndWhiteText {
	// 应用毛玻璃效果到容器视图
	if (self.containerView) {
		self.containerView.backgroundColor = [UIColor clearColor];

		for (UIView *subview in self.containerView.subviews) {
			if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 9999) {
				[subview removeFromSuperview];
			}
		}

		UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		blurEffectView.frame = self.containerView.bounds;
		blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		blurEffectView.alpha = 0.9;
		blurEffectView.tag = 9999;

		[self.containerView insertSubview:blurEffectView atIndex:0];

		[self setTextColorWhiteRecursivelyInView:self.containerView];
	}
}

%new
- (void)setTextColorWhiteRecursivelyInView:(UIView *)view {
	for (UIView *subview in view.subviews) {
		if (![subview isKindOfClass:[UIVisualEffectView class]]) {
			subview.backgroundColor = [UIColor clearColor];
		}

		if ([subview isKindOfClass:[UILabel class]]) {
			UILabel *label = (UILabel *)subview;
			label.textColor = [UIColor whiteColor];
		}

		if ([subview isKindOfClass:[UIButton class]]) {
			UIButton *button = (UIButton *)subview;
			[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		}

		[self setTextColorWhiteRecursivelyInView:subview];
	}
}
%end

%hook _TtC33AWECommentLongPressPanelSwiftImpl32CommentLongPressPanelCopyElement

- (void)elementTapped {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCommentCopyText"]) {
		AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
		AWECommentModel *selectdComment = [commentPageContext selectdComment];
		if (!selectdComment) {
			AWECommentLongPressPanelParam *params = [commentPageContext params];
			selectdComment = [params selectdComment];
		}
		NSString *descText = [selectdComment content];
		[[UIPasteboard generalPasteboard] setString:descText];
		[DYYYManager showToast:@"文案已复制到剪贴板"];
	}
}
%end

// 启用自动勾选原图
%hook AWEIMPhotoPickerFunctionModel

- (void)setUseShadowIcon:(BOOL)arg1 {
    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisAutoSelectOriginalPhoto"];
    if (enabled) {
        %orig(YES);
    } else {
        %orig(arg1);
    }
}

- (BOOL)isSelected {
    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisAutoSelectOriginalPhoto"];
    if (enabled) {
        return YES;
    }
    return %orig;
}

%end

%hook AWESharePanelStyleOptionsManager

+ (unsigned long long)styleOptionsOfContext:(id)context {
    return 101;
}

%end

// 屏蔽直播PCDN
%hook HTSLiveStreamPcdnManager

+ (void)start {
    BOOL disablePCDN = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDisableLivePCDN"];
    if (!disablePCDN) {
        %orig;
    }
}

+ (void)configAndStartLiveIO {
    BOOL disablePCDN = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDisableLivePCDN"];
    if (!disablePCDN) {
        %orig;
    }
}

%end
%ctor {
	%init(DYYYSettingsGesture);
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}
