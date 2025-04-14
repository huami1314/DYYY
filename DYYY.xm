//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//  Created on: 2024/10/04
//
#import "AwemeHeaders.h"
#import "CityManager.h"
#import "DYYYBottomAlertView.h"
#import "DYYYManager.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define DYYY @"DYYY"
#define tweakVersion @"2.2-4"

@interface DYYYManager (API)
+ (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink apiKey:(NSString *)apiKey;
+ (void)batchDownloadResources:(NSArray *)videos images:(NSArray *)images;
@end

static void DYYYAddCustomViewToParent(UIView *parentView, float transparency) {
	if (!parentView)
		return;

	parentView.backgroundColor = [UIColor clearColor];

	UIVisualEffectView *existingBlurView = nil;
	for (UIView *subview in parentView.subviews) {
		if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 999) {
			existingBlurView = (UIVisualEffectView *)subview;
			break;
		}
	}

	BOOL isDarkMode = [DYYYManager isDarkMode];
	UIBlurEffectStyle blurStyle = isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;

	if (transparency <= 0 || transparency > 1) {
		transparency = 0.5;
	}

	if (!existingBlurView) {
		UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
		UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		blurEffectView.frame = parentView.bounds;
		blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		blurEffectView.alpha = transparency;
		blurEffectView.tag = 999;

		UIView *overlayView = [[UIView alloc] initWithFrame:parentView.bounds];
		CGFloat alpha = isDarkMode ? 0.2 : 0.1;
		overlayView.backgroundColor = [UIColor colorWithWhite:(isDarkMode ? 0 : 1) alpha:alpha];
		overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[blurEffectView.contentView addSubview:overlayView];

		[parentView insertSubview:blurEffectView atIndex:0];
	} else {
		UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
		[existingBlurView setEffect:blurEffect];
		existingBlurView.alpha = transparency;

		for (UIView *subview in existingBlurView.contentView.subviews) {
			CGFloat alpha = isDarkMode ? 0.2 : 0.1;
			subview.backgroundColor = [UIColor colorWithWhite:(isDarkMode ? 0 : 1) alpha:alpha];
		}

		[parentView insertSubview:existingBlurView atIndex:0];
	}
}

%group needDelays

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
			%orig(alphaValue);
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
			// 设置自身背景色的透明度
			UIColor *backgroundColor = self.backgroundColor;
			if (backgroundColor) {
				CGFloat r, g, b, a;
				if ([backgroundColor getRed:&r green:&g blue:&b alpha:&a]) {
					self.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:alphaValue * a];
				}
			}

			// 使用类型转换确保编译器知道这是一个 UIView
			[(UIView *)self setAlpha:alphaValue];

			// 确保子视图不会叠加透明度
			for (UIView *subview in self.subviews) {
				subview.alpha = 1.0;
			}
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

%hook AWELongVideoControlModel
- (bool)allowDownload {
	return YES;
}
%end

%hook AWELongVideoControlModel
- (long long)preventDownloadType {
	return 0;
}
%end

%hook AWELandscapeFeedEntryView
- (void)setCenter:(CGPoint)center {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"]) {
		center.y += 60;
	}

	%orig(center);
}

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenEntry"]) {
		[self removeFromSuperview];
	}
}

%end

%hook AWEPlayInteractionViewController
- (void)viewDidLayoutSubviews {
	%orig;
	if (![self.parentViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
		return;
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		CGRect frame = self.view.frame;
		frame.size.height = self.view.superview.frame.size.height - 83;
		self.view.frame = frame;
	}
}
- (void)onPlayer:(id)arg0 didDoubleClick:(id)arg1 {
	BOOL isPopupEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDoubleOpenAlertController"];
	BOOL isDirectCommentEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDoubleOpenComment"];

	// 直接打开评论区的情况
	if (isDirectCommentEnabled) {
		[self performCommentAction];
		return;
	}

	// 显示弹窗的情况
	if (isPopupEnabled) {
		// 获取当前视频模型
		AWEAwemeModel *awemeModel = nil;

		// 尝试通过可能的方法/属性获取模型
		if ([self respondsToSelector:@selector(awemeModel)]) {
			awemeModel = [self performSelector:@selector(awemeModel)];
		} else if ([self respondsToSelector:@selector(currentAwemeModel)]) {
			awemeModel = [self performSelector:@selector(currentAwemeModel)];
		} else if ([self respondsToSelector:@selector(getAwemeModel)]) {
			awemeModel = [self performSelector:@selector(getAwemeModel)];
		}

		// 如果仍然无法获取模型，尝试从视图控制器获取
		if (!awemeModel) {
			UIViewController *baseVC = [self valueForKey:@"awemeBaseViewController"];
			if (baseVC && [baseVC respondsToSelector:@selector(model)]) {
				awemeModel = [baseVC performSelector:@selector(model)];
			} else if (baseVC && [baseVC respondsToSelector:@selector(awemeModel)]) {
				awemeModel = [baseVC performSelector:@selector(awemeModel)];
			}
		}

		// 如果无法获取模型，执行默认行为并返回
		if (!awemeModel) {
			%orig;
			return;
		}

		AWEVideoModel *videoModel = awemeModel.video;
		AWEMusicModel *musicModel = awemeModel.music;

		// 确定内容类型（视频或图片）
		BOOL isImageContent = (awemeModel.awemeType == 68);
		NSString *downloadTitle = isImageContent ? @"保存图片" : @"保存视频";

		// 创建AWEUserActionSheetView
		AWEUserActionSheetView *actionSheet = [[NSClassFromString(@"AWEUserActionSheetView") alloc] init];
		NSMutableArray *actions = [NSMutableArray array];

		// 添加下载选项
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDoubleTapDownload"] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapDownload"]) {

			AWEUserSheetAction *downloadAction = [NSClassFromString(@"AWEUserSheetAction")
			    actionWithTitle:downloadTitle
				    imgName:nil
				    handler:^{
				      if (isImageContent) {
					      // 图片内容
					      AWEImageAlbumImageModel *currentImageModel = nil;
					      if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
						      currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
					      } else {
						      currentImageModel = awemeModel.albumImages.firstObject;
					      }

					      if (currentImageModel && currentImageModel.urlList.count > 0) {
						      NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
						      [DYYYManager downloadMedia:url
								       mediaType:MediaTypeImage
								      completion:^{
									[DYYYManager showToast:@"图片已保存到相册"];
								      }];
					      }
				      } else {
					      // 视频内容
					      if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
						      NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
						      [DYYYManager downloadMedia:url
								       mediaType:MediaTypeVideo
								      completion:^{
									[DYYYManager showToast:@"视频已保存到相册"];
								      }];
					      }
				      }
				    }];
			[actions addObject:downloadAction];

			// 如果是图集，添加下载所有图片选项
			if (isImageContent && awemeModel.albumImages.count > 1) {
				AWEUserSheetAction *downloadAllAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"保存所有图片"
															  imgName:nil
															  handler:^{
															    NSMutableArray *imageURLs = [NSMutableArray array];
															    for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
																    if (imageModel.urlList.count > 0) {
																	    [imageURLs addObject:imageModel.urlList.firstObject];
																    }
															    }
															    [DYYYManager downloadAllImages:imageURLs];
															  }];
				[actions addObject:downloadAllAction];
			}
		}

		// 添加下载音频选项
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDoubleTapDownloadAudio"] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapDownloadAudio"]) {

			AWEUserSheetAction *downloadAudioAction = [NSClassFromString(@"AWEUserSheetAction")
			    actionWithTitle:@"保存音频"
				    imgName:nil
				    handler:^{
				      if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
					      NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
					      [DYYYManager downloadMedia:url mediaType:MediaTypeAudio completion:nil];
				      }
				    }];
			[actions addObject:downloadAudioAction];
		}

		// 添加接口保存选项
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDoubleInterfaceDownload"]) {
			NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
			if (apiKey.length > 0) {
				AWEUserSheetAction *apiDownloadAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"接口保存"
															  imgName:nil
															  handler:^{
															    NSString *shareLink = [awemeModel valueForKey:@"shareURL"];
															    if (shareLink.length == 0) {
																    [DYYYManager showToast:@"无法获取分享链接"];
																    return;
															    }

															    // 使用封装的方法进行解析下载
															    [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];
															  }];
				[actions addObject:apiDownloadAction];
			}
		}

		// 添加复制文案选项
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDoubleTapCopyDesc"] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapCopyDesc"]) {

			AWEUserSheetAction *copyTextAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"复制文案"
													       imgName:nil
													       handler:^{
														 NSString *descText = [awemeModel valueForKey:@"descriptionString"];
														 [[UIPasteboard generalPasteboard] setString:descText];
														 [DYYYManager showToast:@"文案已复制到剪贴板"];
													       }];
			[actions addObject:copyTextAction];
		}

		// 添加打开评论区选项
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDoubleTapComment"] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapComment"]) {

			AWEUserSheetAction *openCommentAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"打开评论"
														  imgName:nil
														  handler:^{
														    [self performCommentAction];
														  }];
			[actions addObject:openCommentAction];
		}

		// 添加点赞视频选项
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDoubleTapLike"] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapLike"]) {

			AWEUserSheetAction *likeAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"点赞视频"
													   imgName:nil
													   handler:^{
													     [self performLikeAction]; // 执行点赞操作
													   }];
			[actions addObject:likeAction];
		}

		// 添加分享选项
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDoubleTapshowSharePanel"] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapshowSharePanel"]) {

			AWEUserSheetAction *showSharePanel = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"分享视频"
													       imgName:nil
													       handler:^{
														 [self showSharePanel]; // 执行分享操作
													       }];
			[actions addObject:showSharePanel];
		}
		// 添加长按面板
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDoubleTapshowDislikeOnVideo"] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapshowDislikeOnVideo"]) {

			AWEUserSheetAction *showDislikeOnVideo = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"长按面板"
														   imgName:nil
														   handler:^{
														     [self showDislikeOnVideo]; // 执行长按面板操作
														   }];
			[actions addObject:showDislikeOnVideo];
		}

		// 显示操作表
		[actionSheet setActions:actions];
		[actionSheet show];

		return;
	}

	// 默认行为
	%orig;
}

%end

%hook AWEStoryContainerCollectionView
- (void)layoutSubviews {
	%orig;
	if ([self.subviews count] == 2)
		return;

	// 获取 enableEnterProfile 属性来判断是否是主页
	id enableEnterProfile = [self valueForKey:@"enableEnterProfile"];
	BOOL isHome = (enableEnterProfile != nil && [enableEnterProfile boolValue]);

	// 检查是否在作者主页
	BOOL isAuthorProfile = NO;
	UIResponder *responder = self;
	while ((responder = [responder nextResponder])) {
		if ([NSStringFromClass([responder class]) containsString:@"UserHomeViewController"] || [NSStringFromClass([responder class]) containsString:@"ProfileViewController"]) {
			isAuthorProfile = YES;
			break;
		}
	}

	// 如果不是主页也不是作者主页，直接返回
	if (!isHome && !isAuthorProfile)
		return;

	for (UIView *subview in self.subviews) {
		if ([subview isKindOfClass:[UIView class]]) {
			UIView *nextResponder = (UIView *)subview.nextResponder;

			// 处理主页的情况
			if (isHome && [nextResponder isKindOfClass:%c(AWEPlayInteractionViewController)]) {
				UIViewController *awemeBaseViewController = [nextResponder valueForKey:@"awemeBaseViewController"];
				if (![awemeBaseViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
					continue;
				}

				CGRect frame = subview.frame;
				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
					frame.size.height = subview.superview.frame.size.height - 83;
					subview.frame = frame;
				}
			}
			// 处理作者主页的情况
			else if (isAuthorProfile) {
				// 检查是否是作品图片
				BOOL isWorkImage = NO;

				// 可以通过检查子视图、标签或其他特性来确定是否是作品图片
				for (UIView *childView in subview.subviews) {
					if ([NSStringFromClass([childView class]) containsString:@"ImageView"] || [NSStringFromClass([childView class]) containsString:@"ThumbnailView"]) {
						isWorkImage = YES;
						break;
					}
				}

				if (isWorkImage) {
					// 修复作者主页作品图片上移问题
					CGRect frame = subview.frame;
					frame.origin.y += 83;
					subview.frame = frame;
				}
			}
		}
	}
}
%end

%hook AWEFeedTableView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		CGRect frame = self.frame;
		frame.size.height = self.superview.frame.size.height;
		self.frame = frame;
	}
}
%end

%hook AWEPlayInteractionProgressContainerView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		for (UIView *subview in self.subviews) {
			if ([subview class] == [UIView class]) {
				[subview setBackgroundColor:[UIColor clearColor]];
			}
		}
	}
}
%end

%hook UIView

- (void)setFrame:(CGRect)frame {

	if ([self isKindOfClass:%c(AWEIMSkylightListView)] && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenAvatarList"]) {
		frame = CGRectZero;
	}

	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		%orig;
		return;
	}

	UIViewController *vc = [self firstAvailableUIViewController];
	if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {

		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"] && frame.origin.x != 0) {
			return;
		} else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"] && frame.origin.x != 0 && frame.origin.y != 0) {
			%orig;
			return;
		} else {
			CGRect superviewFrame = self.superview.frame;

			if (superviewFrame.size.height > 0 && frame.size.height > 0 && frame.size.height < superviewFrame.size.height && frame.origin.x == 0 && frame.origin.y == 0) {

				CGFloat heightDifference = superviewFrame.size.height - frame.size.height;
				if (fabs(heightDifference - 83) < 1.0) {
					frame.size.height = superviewFrame.size.height;
					%orig(frame);
					return;
				}
			}
		}
	}
	%orig;
}

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

%hook AFDFastSpeedView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		for (UIView *subview in self.subviews) {
			if ([subview class] == [UIView class]) {
				[subview setBackgroundColor:[UIColor clearColor]];
			}
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

%hook AWEAwemeModel
- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
	id orig = %orig;

	BOOL noAds = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoAds"];
	BOOL skipLive = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisSkipLive"];
	BOOL skipHotSpot = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisSkipHotSpot"];

	BOOL shouldFilterAds = noAds && (self.hotSpotLynxCardModel || self.isAds);
	BOOL shouldFilterRec = skipLive && (self.liveReason != nil);
	BOOL shouldFilterHotSpot = skipHotSpot && self.hotSpotLynxCardModel;

	BOOL shouldFilterLowLikes = NO;
	BOOL shouldFilterKeywords = NO;

	BOOL shouldFilterTime = NO;

	// 获取用户设置的需要过滤的关键词
	NSString *filterKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"];
	NSArray *keywordsList = nil;

	if (filterKeywords.length > 0) {
		keywordsList = [filterKeywords componentsSeparatedByString:@","];
	}

	NSInteger filterLowLikesThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYfilterLowLikes"];

	// 只有当shareRecExtra不为空时才过滤点赞量低的视频和关键词
	if (self.shareRecExtra && ![self.shareRecExtra isEqual:@""]) {
		// 过滤低点赞量视频
		if (filterLowLikesThreshold > 0) {
			AWESearchAwemeExtraModel *searchExtraModel = [self searchExtraModel];
			if (!searchExtraModel) {
				AWEAwemeStatisticsModel *statistics = self.statistics;
				if (statistics && statistics.diggCount) {
					shouldFilterLowLikes = statistics.diggCount.integerValue < filterLowLikesThreshold;
				}
			}
		}

		// 过滤包含特定关键词的视频
		if (keywordsList.count > 0) {
			// 检查视频标题
			if (self.itemTitle.length > 0) {
				for (NSString *keyword in keywordsList) {
					NSString *trimmedKeyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					if (trimmedKeyword.length > 0 && [self.itemTitle containsString:trimmedKeyword]) {
						shouldFilterKeywords = YES;
						break;
					}
				}
			}

			// 如果标题中没有关键词，检查标签(textExtras)
			if (!shouldFilterKeywords && self.textExtras.count > 0) {
				for (AWEAwemeTextExtraModel *textExtra in self.textExtras) {
					NSString *hashtagName = textExtra.hashtagName;
					if (hashtagName.length > 0) {
						for (NSString *keyword in keywordsList) {
							NSString *trimmedKeyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
							if (trimmedKeyword.length > 0 && [hashtagName containsString:trimmedKeyword]) {
								shouldFilterKeywords = YES;
								break;
							}
						}
						if (shouldFilterKeywords)
							break;
					}
				}
			}
		}

		// 过滤视频发布时间
		long long currentTimestamp = (long long)[[NSDate date] timeIntervalSince1970];
		NSInteger daysThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYfiltertimelimit"];
		if (daysThreshold > 0) {
			NSTimeInterval videoTimestamp = [self.createTime doubleValue];
			if (videoTimestamp > 0) {
				NSTimeInterval threshold = daysThreshold * 86400.0;
				NSTimeInterval current = (NSTimeInterval)currentTimestamp;
				NSTimeInterval timeDifference = current - videoTimestamp;
				shouldFilterTime = (timeDifference > threshold);
			}
		}
	}
	return (shouldFilterAds || shouldFilterRec || shouldFilterHotSpot || shouldFilterLowLikes || shouldFilterKeywords || shouldFilterTime) ? nil : orig;
}

- (id)init {
	id orig = %orig;

	BOOL noAds = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoAds"];
	BOOL skipLive = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisSkipLive"];
	BOOL skipHotSpot = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisSkipHotSpot"];

	BOOL shouldFilterAds = noAds && (self.hotSpotLynxCardModel || self.isAds);
	BOOL shouldFilterRec = skipLive && (self.liveReason != nil);
	BOOL shouldFilterHotSpot = skipHotSpot && self.hotSpotLynxCardModel;

	BOOL shouldFilterLowLikes = NO;
	BOOL shouldFilterKeywords = NO;

	BOOL shouldFilterTime = NO;

	// 获取用户设置的需要过滤的关键词
	NSString *filterKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"];
	NSArray *keywordsList = nil;

	if (filterKeywords.length > 0) {
		keywordsList = [filterKeywords componentsSeparatedByString:@","];
	}

	NSInteger filterLowLikesThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYfilterLowLikes"];

	// 只有当shareRecExtra不为空时才过滤
	if (self.shareRecExtra && ![self.shareRecExtra isEqual:@""]) {
		// 过滤低点赞量视频
		if (filterLowLikesThreshold > 0) {
			AWESearchAwemeExtraModel *searchExtraModel = [self searchExtraModel];
			if (!searchExtraModel) {
				AWEAwemeStatisticsModel *statistics = self.statistics;
				if (statistics && statistics.diggCount) {
					shouldFilterLowLikes = statistics.diggCount.integerValue < filterLowLikesThreshold;
				}
			}
		}

		// 过滤包含特定关键词的视频
		if (keywordsList.count > 0) {
			// 检查视频标题
			if (self.itemTitle.length > 0) {
				for (NSString *keyword in keywordsList) {
					NSString *trimmedKeyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					if (trimmedKeyword.length > 0 && [self.itemTitle containsString:trimmedKeyword]) {
						shouldFilterKeywords = YES;
						break;
					}
				}
			}

			// 如果标题中没有关键词，检查标签(textExtras)
			if (!shouldFilterKeywords && self.textExtras.count > 0) {
				for (AWEAwemeTextExtraModel *textExtra in self.textExtras) {
					NSString *hashtagName = textExtra.hashtagName;
					if (hashtagName.length > 0) {
						for (NSString *keyword in keywordsList) {
							NSString *trimmedKeyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
							if (trimmedKeyword.length > 0 && [hashtagName containsString:trimmedKeyword]) {
								shouldFilterKeywords = YES;
								break;
							}
						}
						if (shouldFilterKeywords)
							break;
					}
				}
			}
		}

		// 过滤视频发布时间
		long long currentTimestamp = (long long)[[NSDate date] timeIntervalSince1970];
		NSInteger daysThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYfiltertimelimit"];
		if (daysThreshold > 0) {
			NSTimeInterval videoTimestamp = [self.createTime doubleValue];
			if (videoTimestamp > 0) {
				NSTimeInterval threshold = daysThreshold * 86400.0;
				NSTimeInterval current = (NSTimeInterval)currentTimestamp;
				NSTimeInterval timeDifference = current - videoTimestamp;
				shouldFilterTime = (timeDifference > threshold);
			}
		}
	}

	return (shouldFilterAds || shouldFilterRec || shouldFilterHotSpot || shouldFilterLowLikes || shouldFilterKeywords || shouldFilterTime) ? nil : orig;
}

- (bool)preventDownload {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoAds"]) {
		return NO;
	} else {
		return %orig;
	}
}

- (void)setAdLinkType:(long long)arg1 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoAds"]) {
		arg1 = 0;
	} else {
	}

	%orig;
}

%end

// 拦截开屏广告
%hook BDASplashControllerView
+ (id)alloc {
	BOOL noAds = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoAds"];
	if (noAds) {
		return nil;
	}
	return %orig;
}
%end

%hook UIView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDiscover"] && [self.accessibilityLabel isEqualToString:@"搜索"]) {
		[self removeFromSuperview];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"]) {
		for (UIView *subview in self.subviews) {
			if ([subview isKindOfClass:NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputViewMiddleContainer")]) {
				BOOL containsDanmu = NO;

				for (UIView *innerSubview in subview.subviews) {
					if ([innerSubview isKindOfClass:[UILabel class]] && [((UILabel *)innerSubview).text containsString:@"弹幕"]) {
						containsDanmu = YES;
						break;
					}
				}
				if (containsDanmu) {
					UIView *parentView = subview.superview;
					for (UIView *innerSubview in parentView.subviews) {
						if ([innerSubview isKindOfClass:[UIView class]]) {
							// NSLog(@"[innerSubview] %@", innerSubview);
							[innerSubview.subviews[0] removeFromSuperview];

							UIView *whiteBackgroundView = [[UIView alloc] initWithFrame:innerSubview.bounds];
							whiteBackgroundView.backgroundColor = [UIColor whiteColor];
							whiteBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
							[innerSubview addSubview:whiteBackgroundView];
							break;
						}
					}
				} else {
					for (UIView *innerSubview in subview.subviews) {
						if ([innerSubview isKindOfClass:[UIView class]]) {
							float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
							if (userTransparency <= 0 || userTransparency > 1) {
								userTransparency = 0.95;
							}
							DYYYAddCustomViewToParent(innerSubview, userTransparency);
							break;
						}
					}
				}
			}
		}
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"]) {

		UIViewController *vc = [self firstAvailableUIViewController];
		if ([vc isKindOfClass:%c(AWEPlayInteractionViewController)]) {
			BOOL shouldHideSubview = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"] ||
						 [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"];

			if (shouldHideSubview) {
				for (UIView *subview in self.subviews) {
					if ([subview isKindOfClass:[UIView class]] && subview.backgroundColor && CGColorEqualToColor(subview.backgroundColor.CGColor, [UIColor blackColor].CGColor)) {
						subview.hidden = YES;
					}
				}
			}
		}
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"]) {
		NSString *className = NSStringFromClass([self class]);
		if ([className isEqualToString:@"AWECommentInputViewSwiftImpl.CommentInputContainerView"]) {
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:[UIView class]] && subview.backgroundColor) {
					CGFloat red = 0, green = 0, blue = 0, alpha = 0;
					[subview.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];

					if ((red == 22 / 255.0 && green == 22 / 255.0 && blue == 22 / 255.0) || (red == 1.0 && green == 1.0 && blue == 1.0)) {
						float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
						if (userTransparency <= 0 || userTransparency > 1) {
							userTransparency = 0.95;
						}
						DYYYAddCustomViewToParent(subview, userTransparency);
					}
				}
			}
		}
	}
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

// 在初始化时设置进度条样式
- (instancetype)initWithFrame:(CGRect)frame {
	self = %orig;
	if (self) {
		[self applyCustomProgressStyle];
	}
	return self;
}

// 在布局更新时应用自定义样式
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
		CGRect frame = self.frame;

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
		CGFloat centerX = frame.origin.x + frame.size.width / 2;

		frame.size.width = newWidth;
		frame.origin.x = centerX - newWidth / 2;

		self.frame = frame;

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

// 确保即使进度条隐藏也可以拖动
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	// 如果隐藏视频进度但显示进度时长，扩大判断区域以便于用户交互
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideVideoProgress"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]) {
		CGRect expandedBounds = CGRectInset(self.bounds, -20, -20);
		return CGRectContainsPoint(expandedBounds, point);
	}
	return %orig;
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

		// 获取用户设置的时间标签颜色
		NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressLabelColor"];
		UIColor *labelColor = [UIColor whiteColor]; // 默认白色
		if (labelColorHex && labelColorHex.length > 0) {
			labelColor = [DYYYManager colorWithHexString:labelColorHex];
		}

		// 只有在非"进度条右侧剩余"和非"进度条右侧完整"模式时创建左侧时间标签
		if (!showRemainingTime && !showCompleteTime) {
			// 创建左侧时间标签
			UILabel *leftLabel = [[UILabel alloc] init];
			leftLabel.frame = CGRectMake(sliderFrame.origin.x, sliderFrame.origin.y + verticalOffset, 50, 15);
			leftLabel.backgroundColor = [UIColor clearColor];
			[leftLabel setText:@"00:00"];
			[leftLabel setTextColor:labelColor];
			[leftLabel setFont:[UIFont systemFontOfSize:8]];
			leftLabel.tag = 10001;
			[parentView addSubview:leftLabel];
		}

		// 创建右侧时间标签
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

		// 如果检测到时间
		if (arg1 > 0 && leftLabel) {
			[leftLabel setText:[self formatTimeFromSeconds:arg1]];
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
        // 获取父视图宽度，以便计算新的宽度
        CGFloat parentWidth = self.superview.bounds.size.width;
        CGRect frame = self.frame;

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
        CGFloat centerX = frame.origin.x + frame.size.width / 2;

        frame.size.width = newWidth;
        frame.origin.x = centerX - newWidth / 2;

        self.frame = frame;

        // 调整进度条子视图的位置和大小，隐藏UIView类型的子视图
        for (UIView *subview in self.subviews) {
            if ([subview class] == [UIView class]) {
                subview.hidden = YES;
            } else {
                // 对其他类型的子视图调整宽度
                CGRect subFrame = subview.frame;
                subFrame.size.width = newWidth;
                subview.frame = subFrame;
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

%hook AWEFeedChannelManager

- (void)reloadChannelWithChannelModels:(id)arg1 currentChannelIDList:(id)arg2 reloadType:(id)arg3 selectedChannelID:(id)arg4 {
	NSArray *channelModels = arg1;
	NSMutableArray *newChannelModels = [NSMutableArray array];
	NSArray *currentChannelIDList = arg2;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSMutableArray *newCurrentChannelIDList = [NSMutableArray arrayWithArray:currentChannelIDList];

	for (AWEHPTopTabItemModel *tabItemModel in channelModels) {
		NSString *channelID = tabItemModel.channelID;

		if ([channelID isEqualToString:@"homepage_hot_container"]) {
			[newChannelModels addObject:tabItemModel];
			continue;
		}

		BOOL isHideChannel = NO;
		if ([channelID isEqualToString:@"homepage_follow"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideFollow"];
		} else if ([channelID isEqualToString:@"homepage_mediumvideo"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideMediumVideo"];
		} else if ([channelID isEqualToString:@"homepage_mall"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideMall"];
		} else if ([channelID isEqualToString:@"homepage_nearby"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideNearby"];
		} else if ([channelID isEqualToString:@"homepage_groupon"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideGroupon"];
		} else if ([channelID isEqualToString:@"homepage_tablive"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideTabLive"];
		} else if ([channelID isEqualToString:@"homepage_pad_hot"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHidePadHot"];
		} else if ([channelID isEqualToString:@"homepage_hangout"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideHangout"];
		} else if ([channelID isEqualToString:@"homepage_familiar"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideFriend"];
		} else if ([channelID isEqualToString:@"homepage_playlet_stream"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHidePlaylet"];
		}

		if (!isHideChannel) {
			[newChannelModels addObject:tabItemModel];
		} else {
			[newCurrentChannelIDList removeObject:channelID];
		}
	}

	%orig(newChannelModels, newCurrentChannelIDList, arg3, arg4);
}

%end

%hook AWEPlayInteractionTimestampElement
- (id)timestampLabel {
	UILabel *label = %orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"]) {
		NSString *text = label.text;
		NSString *cityCode = self.model.cityCode;

		if (cityCode.length > 0) {
			NSString *cityName = [CityManager.sharedInstance getCityNameWithCode:cityCode] ?: @"";
			NSString *provinceName = [CityManager.sharedInstance getProvinceNameWithCode:cityCode] ?: @"";

			if (cityName.length > 0 && ![text containsString:cityName]) {
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
	NSString *labelColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelColor"];
	if (labelColor.length > 0) {
		label.textColor = [DYYYManager colorWithHexString:labelColor];
	}
	return label;
}

+ (BOOL)shouldActiveWithData:(id)arg1 context:(id)arg2 {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"];
}

%end

%hook AWEModernLongPressPanelTableViewController

- (NSArray *)dataArray {
	NSArray *originalArray = %orig;

	if (!originalArray) {
		originalArray = @[];
	}

	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		return originalArray;
	}

	AWELongPressPanelViewGroupModel *newGroupModel = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
	newGroupModel.groupType = 0;

	NSMutableArray *viewModels = [NSMutableArray array];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"]) {
		if (self.awemeModel.awemeType != 68) {
			AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			downloadViewModel.awemeModel = self.awemeModel;
			downloadViewModel.actionType = 666;
			downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			downloadViewModel.describeString = @"保存视频";

			downloadViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;
			  AWEMusicModel *musicModel = awemeModel.music;

			  if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeVideo
						  completion:^{
						    [DYYYManager showToast:@"视频已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:downloadViewModel];
		}

		if (self.awemeModel.awemeType != 68) {
			AWELongPressPanelBaseViewModel *coverViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			coverViewModel.awemeModel = self.awemeModel;
			coverViewModel.actionType = 667;
			coverViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			coverViewModel.describeString = @"保存封面";

			coverViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;

			  if (videoModel && videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"封面已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:coverViewModel];
		}

		AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		audioViewModel.awemeModel = self.awemeModel;
		audioViewModel.actionType = 668;
		audioViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
		audioViewModel.describeString = @"保存音频";

		audioViewModel.action = ^{
		  AWEAwemeModel *awemeModel = self.awemeModel;
		  AWEMusicModel *musicModel = awemeModel.music;

		  if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
			  NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
			  [DYYYManager downloadMedia:url mediaType:MediaTypeAudio completion:nil];
		  }

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:audioViewModel];

		if (self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
			AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			imageViewModel.awemeModel = self.awemeModel;
			imageViewModel.actionType = 669;
			imageViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			imageViewModel.describeString = @"保存当前图片";

			AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
			if (currimge.clipVideo != nil) {
				imageViewModel.describeString = @"保存当前实况";
			}
			imageViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEImageAlbumImageModel *currentImageModel = nil;

			  if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
				  currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
			  } else {
				  currentImageModel = awemeModel.albumImages.firstObject;
			  }
			  // 如果是实况的话
			  if (currimge.clipVideo != nil) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  NSURL *videoURL = [currimge.clipVideo.playURL getDYYYSrcURLDownload];

				  [DYYYManager downloadLivePhoto:url
							videoURL:videoURL
						      completion:^{
							[DYYYManager showToast:@"实况照片已保存到相册"];
						      }];
			  } else if (currentImageModel && currentImageModel.urlList.count > 0) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"图片已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:imageViewModel];

			if (self.awemeModel.albumImages.count > 1) {
				AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
				allImagesViewModel.awemeModel = self.awemeModel;
				allImagesViewModel.actionType = 670;
				allImagesViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
				allImagesViewModel.describeString = @"保存所有图片";

				// 检查是否有实况照片并更改按钮文字
				BOOL hasLivePhoto = NO;
				for (AWEImageAlbumImageModel *imageModel in self.awemeModel.albumImages) {
					if (imageModel.clipVideo != nil) {
						hasLivePhoto = YES;
						break;
					}
				}

				if (hasLivePhoto) {
					allImagesViewModel.describeString = @"保存所有实况";
				}

				allImagesViewModel.action = ^{
				  AWEAwemeModel *awemeModel = self.awemeModel;
				  NSMutableArray *imageURLs = [NSMutableArray array];

				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.urlList.count > 0) {
						  [imageURLs addObject:imageModel.urlList.firstObject];
					  }
				  }

				  // 检查是否有实况照片
				  BOOL hasLivePhoto = NO;
				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.clipVideo != nil) {
						  hasLivePhoto = YES;
						  break;
					  }
				  }

				  // 如果有实况照片，使用单独的downloadLivePhoto方法逐个下载
				  if (hasLivePhoto) {
					  NSMutableArray *livePhotos = [NSMutableArray array];
					  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
						  if (imageModel.urlList.count > 0 && imageModel.clipVideo != nil) {
							  NSURL *photoURL = [NSURL URLWithString:imageModel.urlList.firstObject];
							  NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];

							  [livePhotos addObject:@{@"imageURL" : photoURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
						  }
					  }

					  // 使用批量下载实况照片方法
					  [DYYYManager downloadAllLivePhotos:livePhotos];
				  } else if (imageURLs.count > 0) {
					  [DYYYManager downloadAllImages:imageURLs];
				  }

				  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
				  [panelManager dismissWithAnimation:YES completion:nil];
				};

				[viewModels addObject:allImagesViewModel];
			}
		}
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		AWELongPressPanelBaseViewModel *copyText = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyText.awemeModel = self.awemeModel;
		copyText.actionType = 671;
		copyText.duxIconName = @"ic_xiaoxihuazhonghua_outlined";
		copyText.describeString = @"复制文案";

		copyText.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
		  [[UIPasteboard generalPasteboard] setString:descText];
		  [DYYYManager showToast:@"文案已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyText];

		// 新增复制分享链接
		AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyShareLink.awemeModel = self.awemeModel;
		copyShareLink.actionType = 672;
		copyShareLink.duxIconName = @"ic_share_outlined";
		copyShareLink.describeString = @"复制分享链接";

		copyShareLink.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  [[UIPasteboard generalPasteboard] setString:shareLink];
		  [DYYYManager showToast:@"分享链接已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyShareLink];
	}

	// 添加接口保存功能
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
	if (apiKey.length > 0) {
		AWELongPressPanelBaseViewModel *apiDownload = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		apiDownload.awemeModel = self.awemeModel;
		apiDownload.actionType = 673;
		apiDownload.duxIconName = @"ic_cloudarrowdown_outlined_20";
		apiDownload.describeString = @"接口保存视频";

		apiDownload.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  if (shareLink.length == 0) {
			  [DYYYManager showToast:@"无法获取分享链接"];
			  return;
		  }

		  // 使用封装的方法进行解析下载
		  [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:apiDownload];
	}

	newGroupModel.groupArr = viewModels;
	return [@[ newGroupModel ] arrayByAddingObjectsFromArray:originalArray];
}

%end

%hook AWELongPressPanelTableViewController

- (NSArray *)dataArray {
	NSArray *originalArray = %orig;

	if (!originalArray) {
		originalArray = @[];
	}

	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		return originalArray;
	}

	AWELongPressPanelViewGroupModel *newGroupModel = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
	newGroupModel.groupType = 0;

	NSMutableArray *viewModels = [NSMutableArray array];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"]) {
		if (self.awemeModel.awemeType != 68) {
			AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			downloadViewModel.awemeModel = self.awemeModel;
			downloadViewModel.actionType = 666;
			downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			downloadViewModel.describeString = @"保存视频";

			downloadViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;
			  AWEMusicModel *musicModel = awemeModel.music;

			  if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeVideo
						  completion:^{
						    [DYYYManager showToast:@"视频已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:downloadViewModel];
		}

		if (self.awemeModel.awemeType != 68) {
			AWELongPressPanelBaseViewModel *coverViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			coverViewModel.awemeModel = self.awemeModel;
			coverViewModel.actionType = 667;
			coverViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			coverViewModel.describeString = @"保存封面";

			coverViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;

			  if (videoModel && videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"封面已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:coverViewModel];
		}

		AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		audioViewModel.awemeModel = self.awemeModel;
		audioViewModel.actionType = 668;
		audioViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
		audioViewModel.describeString = @"保存音频";

		audioViewModel.action = ^{
		  AWEAwemeModel *awemeModel = self.awemeModel;
		  AWEMusicModel *musicModel = awemeModel.music;

		  if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
			  NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
			  [DYYYManager downloadMedia:url mediaType:MediaTypeAudio completion:nil];
		  }

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:audioViewModel];

		if (self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
			AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			imageViewModel.awemeModel = self.awemeModel;
			imageViewModel.actionType = 669;
			imageViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			imageViewModel.describeString = @"保存当前图片";

			AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
			if (currimge.clipVideo != nil) {
				imageViewModel.describeString = @"保存当前实况";
			}
			imageViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEImageAlbumImageModel *currentImageModel = nil;

			  if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
				  currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
			  } else {
				  currentImageModel = awemeModel.albumImages.firstObject;
			  }
			  // 如果是实况的话
			  if (currimge.clipVideo != nil) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  NSURL *videoURL = [currimge.clipVideo.playURL getDYYYSrcURLDownload];

				  [DYYYManager downloadLivePhoto:url
							videoURL:videoURL
						      completion:^{
							[DYYYManager showToast:@"实况照片已保存到相册"];
						      }];
			  } else if (currentImageModel && currentImageModel.urlList.count > 0) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"图片已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:imageViewModel];

			if (self.awemeModel.albumImages.count > 1) {
				AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
				allImagesViewModel.awemeModel = self.awemeModel;
				allImagesViewModel.actionType = 670;
				allImagesViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
				allImagesViewModel.describeString = @"保存所有图片";

				// 检查是否有实况照片并更改按钮文字
				BOOL hasLivePhoto = NO;
				for (AWEImageAlbumImageModel *imageModel in self.awemeModel.albumImages) {
					if (imageModel.clipVideo != nil) {
						hasLivePhoto = YES;
						break;
					}
				}

				if (hasLivePhoto) {
					allImagesViewModel.describeString = @"保存所有实况";
				}

				allImagesViewModel.action = ^{
				  AWEAwemeModel *awemeModel = self.awemeModel;
				  NSMutableArray *imageURLs = [NSMutableArray array];

				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.urlList.count > 0) {
						  [imageURLs addObject:imageModel.urlList.firstObject];
					  }
				  }

				  // 检查是否有实况照片
				  BOOL hasLivePhoto = NO;
				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.clipVideo != nil) {
						  hasLivePhoto = YES;
						  break;
					  }
				  }

				  // 如果有实况照片，使用单独的downloadLivePhoto方法逐个下载
				  if (hasLivePhoto) {
					  NSMutableArray *livePhotos = [NSMutableArray array];
					  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
						  if (imageModel.urlList.count > 0 && imageModel.clipVideo != nil) {
							  NSURL *photoURL = [NSURL URLWithString:imageModel.urlList.firstObject];
							  NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];

							  [livePhotos addObject:@{@"imageURL" : photoURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
						  }
					  }

					  // 使用批量下载实况照片方法
					  [DYYYManager downloadAllLivePhotos:livePhotos];
				  } else if (imageURLs.count > 0) {
					  [DYYYManager downloadAllImages:imageURLs];
				  }

				  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
				  [panelManager dismissWithAnimation:YES completion:nil];
				};

				[viewModels addObject:allImagesViewModel];
			}
		}
	}

	// 添加接口保存功能
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
	if (apiKey.length > 0) {
		AWELongPressPanelBaseViewModel *apiDownload = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		apiDownload.awemeModel = self.awemeModel;
		apiDownload.actionType = 673;
		apiDownload.duxIconName = @"ic_cloudarrowdown_outlined_20";
		apiDownload.describeString = @"接口保存";

		apiDownload.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  if (shareLink.length == 0) {
			  [DYYYManager showToast:@"无法获取分享链接"];
			  return;
		  }

		  // 使用封装的方法进行解析下载
		  [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:apiDownload];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		AWELongPressPanelBaseViewModel *copyText = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyText.awemeModel = self.awemeModel;
		copyText.actionType = 671;
		copyText.duxIconName = @"ic_xiaoxihuazhonghua_outlined";
		copyText.describeString = @"复制文案";

		copyText.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
		  [[UIPasteboard generalPasteboard] setString:descText];
		  [DYYYManager showToast:@"文案已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyText];

		// 新增复制分享链接
		AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyShareLink.awemeModel = self.awemeModel;
		copyShareLink.actionType = 672;
		copyShareLink.duxIconName = @"ic_share_outlined";
		copyShareLink.describeString = @"复制分享链接";

		copyShareLink.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  [[UIPasteboard generalPasteboard] setString:shareLink];
		  [DYYYManager showToast:@"分享链接已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyShareLink];
	}

	newGroupModel.groupArr = viewModels;
    
    if (originalArray.count > 0) {
        NSMutableArray *resultArray = [originalArray mutableCopy];
        [resultArray insertObject:newGroupModel atIndex:1]; 
        return [resultArray copy];
    } else {
        return @[newGroupModel];
    }
}

%end

static CGFloat stream_frame_y = 0;

%hook AWEElementStackView
static CGFloat right_tx = 0;
static CGFloat left_tx = 0;
static CGFloat currentScale = 1.0;

- (void)viewWillAppear:(BOOL)animated {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		UIResponder *nextResponder = [self nextResponder];
		if ([nextResponder isKindOfClass:[UIView class]]) {
			UIView *parentView = (UIView *)nextResponder;
			UIViewController *viewController = [parentView firstAvailableUIViewController];

			if ([viewController isKindOfClass:%c(AWELiveNewPreStreamViewController)]) {
				CGRect frame = self.frame;
				if (stream_frame_y != 0) {
					frame.origin.y = stream_frame_y;
					self.frame = frame;
				}
			}
		}
	}
}

- (void)viewDidAppear:(BOOL)animated {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		UIResponder *nextResponder = [self nextResponder];
		if ([nextResponder isKindOfClass:[UIView class]]) {
			UIView *parentView = (UIView *)nextResponder;
			UIViewController *viewController = [parentView firstAvailableUIViewController];

			if ([viewController isKindOfClass:%c(AWELiveNewPreStreamViewController)]) {
				CGRect frame = self.frame;
				if (stream_frame_y != 0) {
					frame.origin.y = stream_frame_y;
					self.frame = frame;
				}
			}
		}
	}
}

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		UIResponder *nextResponder = [self nextResponder];
		if ([nextResponder isKindOfClass:[UIView class]]) {
			UIView *parentView = (UIView *)nextResponder;
			UIViewController *viewController = [parentView firstAvailableUIViewController];

			if ([viewController isKindOfClass:%c(AWELiveNewPreStreamViewController)]) {
				CGRect frame = self.frame;
				frame.origin.y -= 83;
				stream_frame_y = frame.origin.y;
				self.frame = frame;
			}
		}
	}

	NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYElementScale"];
	if ([self.accessibilityLabel isEqualToString:@"right"]) {

		self.transform = CGAffineTransformIdentity;

		if (scaleValue.length > 0) {
			CGFloat scale = [scaleValue floatValue];

			if (currentScale != scale) {
				currentScale = scale;
			}

			if (scale > 0 && scale != 1.0) {
				CGFloat ty = 0;

				for (UIView *view in self.subviews) {
					CGFloat viewHeight = view.frame.size.height;
					CGFloat contribution = (viewHeight - viewHeight * scale) / 2;
					ty += contribution;
				}

				CGFloat frameWidth = self.frame.size.width;
				right_tx = (frameWidth - frameWidth * scale) / 2;

				self.transform = CGAffineTransformMake(scale, 0, 0, scale, right_tx, ty);
			} else {
				self.transform = CGAffineTransformIdentity;
			}
		} else {
		}
	}

	if ([self.accessibilityLabel isEqualToString:@"left"]) {
		NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];

		// 首先恢复到原始状态，确保变换不会累积
		self.transform = CGAffineTransformIdentity;

		if (scaleValue.length > 0) {
			CGFloat scale = [scaleValue floatValue];

			if (currentScale != scale) {
				currentScale = scale;
			}

			if (scale > 0 && scale != 1.0) {
				CGFloat ty = 0;

				for (UIView *view in self.subviews) {
					CGFloat viewHeight = view.frame.size.height;
					CGFloat contribution = (viewHeight - viewHeight * scale) / 2;
					ty += contribution;
				}

				CGFloat frameWidth = self.frame.size.width;
				left_tx = (frameWidth - frameWidth * scale) / 2 - frameWidth * (1 - scale);

				self.transform = CGAffineTransformMake(scale, 0, 0, scale, left_tx, ty);
			} else {
				self.transform = CGAffineTransformIdentity;
			}
		}
	}
}

%end

%hook AWEPlayInteractionDescriptionScrollView

- (void)layoutSubviews {
	%orig;

	self.transform = CGAffineTransformIdentity;

	// 添加文案垂直偏移支持
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
}

%end

// 对新版文案的缩放（33.0以上）

%hook AWEPlayInteractionDescriptionLabel

- (void)layoutSubviews {
	%orig;

	self.transform = CGAffineTransformIdentity;

	// 添加文案垂直偏移支持
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

%hook AWECommentMediaDownloadConfigLivePhoto

bool commentLivePhotoNotWaterMark = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCommentLivePhotoNotWaterMark"];

- (bool)needClientWaterMark {
	return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (bool)needClientEndWaterMark {
	return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (id)watermarkConfig {
	return commentLivePhotoNotWaterMark ? nil : %orig;
}

%end

%hook AWECommentImageModel
- (id)downloadUrl {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCommentNotWaterMark"]) {
		return self.originUrl;
	}
	return %orig;
}
%end

%hook _TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement

static BOOL isDownloadFlied = NO;

- (BOOL)elementShouldShow {
	BOOL DYYYFourceDownloadEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYFourceDownloadEmotion"];
	if (DYYYFourceDownloadEmotion) {
		AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
		AWECommentModel *selectdComment = [commentPageContext selectdComment];
		if (!selectdComment) {
			AWECommentLongPressPanelParam *params = [commentPageContext params];
			selectdComment = [params selectdComment];
		}
		AWEIMStickerModel *sticker = [selectdComment sticker];
		if (sticker) {
			AWEURLModel *staticURLModel = [sticker staticURLModel];
			NSArray *originURLList = [staticURLModel originURLList];
			if (originURLList.count > 0) {
				return YES;
			}
		}
	}
	return %orig;
}

- (void)elementTapped {
	BOOL DYYYFourceDownloadEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYFourceDownloadEmotion"];
	if (DYYYFourceDownloadEmotion) {
		AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
		AWECommentModel *selectdComment = [commentPageContext selectdComment];
		if (!selectdComment) {
			AWECommentLongPressPanelParam *params = [commentPageContext params];
			selectdComment = [params selectdComment];
		}
		AWEIMStickerModel *sticker = [selectdComment sticker];
		if (sticker) {
			AWEURLModel *staticURLModel = [sticker staticURLModel];
			NSArray *originURLList = [staticURLModel originURLList];
			if (originURLList.count > 0) {
				NSString *urlString = @"";
				if (isDownloadFlied) {
					urlString = originURLList[originURLList.count - 1];
					isDownloadFlied = NO;
				} else {
					urlString = originURLList[0];
				}

				NSURL *heifURL = [NSURL URLWithString:urlString];
				[DYYYManager downloadMedia:heifURL
						 mediaType:MediaTypeHeic
						completion:^{
						  [DYYYManager showToast:@"表情包已保存到相册"];
						}];
				return;
			}
		}
	}
	%orig;
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

// 去除启动视频广告
%hook AWEAwesomeSplashFeedCellOldAccessoryView

// 在方法入口处添加控制逻辑
- (id)ddExtraView {
	// 检查用户是否启用了无广告模式
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoAds"]) {
		NSLog(@"[AdControl] 无广告模式已启用 - 隐藏ddExtraView");
		return NULL; // 返回空视图
	}

	// 正常模式调用原始方法
	return %orig;
}

%end

// 去广告功能
%hook AwemeAdManager
- (void)showAd {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoAds"])
		return;
	%orig;
}
%end

// 获取资源的地址
%hook AWEURLModel
%new - (NSURL *)getDYYYSrcURLDownload {
	;
	;
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

%hook DYYYManager

%new
+ (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink apiKey:(NSString *)apiKey {
	if (shareLink.length == 0 || apiKey.length == 0) {
		[self showToast:@"分享链接或API密钥无效"];
		return;
	}

	NSString *apiUrl = [NSString stringWithFormat:@"%@%@", apiKey, [shareLink stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
	[self showToast:@"正在通过接口解析..."];

	NSURL *url = [NSURL URLWithString:apiUrl];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSURLSession *session = [NSURLSession sharedSession];

	NSURLSessionDataTask *dataTask = [session
	    dataTaskWithRequest:request
	      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
		  if (error) {
			  [self showToast:[NSString stringWithFormat:@"接口请求失败: %@", error.localizedDescription]];
			  return;
		  }

		  NSError *jsonError;
		  NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
		  if (jsonError) {
			  [self showToast:@"解析接口返回数据失败"];
			  return;
		  }

		  NSInteger code = [json[@"code"] integerValue];
		  if (code != 0 && code != 200) {
			  [self showToast:[NSString stringWithFormat:@"接口返回错误: %@", json[@"msg"] ?: @"未知错误"]];
			  return;
		  }

		  NSDictionary *dataDict = json[@"data"];
		  if (!dataDict) {
			  [self showToast:@"接口返回数据为空"];
			  return;
		  }

		  NSArray *videos = dataDict[@"videos"];
		  NSArray *images = dataDict[@"images"];
		  NSArray *videoList = dataDict[@"video_list"];
		  BOOL hasVideos = [videos isKindOfClass:[NSArray class]] && videos.count > 0;
		  BOOL hasImages = [images isKindOfClass:[NSArray class]] && images.count > 0;
		  BOOL hasVideoList = [videoList isKindOfClass:[NSArray class]] && videoList.count > 0;
		  BOOL shouldShowQualityOptions = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYShowAllVideoQuality"];

		  // 如果启用了显示清晰度选项并且存在 videoList，或者原本就需要显示清晰度选项
		  if ((shouldShowQualityOptions && hasVideoList) || (!hasVideos && !hasImages && hasVideoList)) {
			  AWEUserActionSheetView *actionSheet = [[NSClassFromString(@"AWEUserActionSheetView") alloc] init];
			  NSMutableArray *actions = [NSMutableArray array];

			  for (NSDictionary *videoDict in videoList) {
				  NSString *url = videoDict[@"url"];
				  NSString *level = videoDict[@"level"];
				  if (url.length > 0 && level.length > 0) {
					  AWEUserSheetAction *qualityAction = [NSClassFromString(@"AWEUserSheetAction")
					      actionWithTitle:level
						      imgName:nil
						      handler:^{
							NSURL *videoDownloadUrl = [NSURL URLWithString:url];
							[self downloadMedia:videoDownloadUrl
								  mediaType:MediaTypeVideo
								 completion:^{
								   [self showToast:[NSString stringWithFormat:@"视频已保存到相册 (%@)", level]];
								 }];
						      }];
					  [actions addObject:qualityAction];
				  }
			  }

			  // 如果用户选择了显示清晰度选项，并且有视频和图片需要下载，添加一个批量下载选项
			  if (shouldShowQualityOptions && (hasVideos || hasImages)) {
				  AWEUserSheetAction *batchDownloadAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"批量下载所有资源"
															      imgName:nil
															      handler:^{
																// 执行批量下载
																[self batchDownloadResources:videos images:images];
															      }];
				  [actions addObject:batchDownloadAction];
			  }

			  if (actions.count > 0) {
				  [actionSheet setActions:actions];
				  [actionSheet show];
				  return;
			  }
		  }

		  // 如果显示清晰度选项但是没有videoList，并且有videos数组（多个视频）
		  if (shouldShowQualityOptions && !hasVideoList && hasVideos && videos.count > 1) {
			  AWEUserActionSheetView *actionSheet = [[NSClassFromString(@"AWEUserActionSheetView") alloc] init];
			  NSMutableArray *actions = [NSMutableArray array];

			  for (NSInteger i = 0; i < videos.count; i++) {
				  NSDictionary *videoDict = videos[i];
				  NSString *videoUrl = videoDict[@"url"];
				  NSString *desc = videoDict[@"desc"] ?: [NSString stringWithFormat:@"视频 %ld", (long)(i + 1)];

				  if (videoUrl.length > 0) {
					  AWEUserSheetAction *videoAction = [NSClassFromString(@"AWEUserSheetAction")
					      actionWithTitle:[NSString stringWithFormat:@"%@", desc]
						      imgName:nil
						      handler:^{
							NSURL *videoDownloadUrl = [NSURL URLWithString:videoUrl];
							[self downloadMedia:videoDownloadUrl
								  mediaType:MediaTypeVideo
								 completion:^{
								   [self showToast:[NSString stringWithFormat:@"视频已保存到相册"]];
								 }];
						      }];
					  [actions addObject:videoAction];
				  }
			  }

			  AWEUserSheetAction *batchDownloadAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"批量下载所有资源"
														      imgName:nil
														      handler:^{
															// 执行批量下载
															[self batchDownloadResources:videos images:images];
														      }];
			  [actions addObject:batchDownloadAction];

			  if (actions.count > 0) {
				  [actionSheet setActions:actions];
				  [actionSheet show];
				  return;
			  }
		  }

		  // 如果没有视频或图片数组，但有单个视频URL
		  if (!hasVideos && !hasImages && !hasVideoList) {
			  NSString *videoUrl = dataDict[@"url"];
			  if (videoUrl.length > 0) {
				  [self showToast:@"开始下载单个视频..."];
				  NSURL *videoDownloadUrl = [NSURL URLWithString:videoUrl];
				  [self downloadMedia:videoDownloadUrl
					    mediaType:MediaTypeVideo
					   completion:^{
					     [self showToast:@"视频已保存到相册"];
					   }];
			  } else {
				  [self showToast:@"接口未返回有效的视频链接"];
			  }
			  return;
		  }

		  [self batchDownloadResources:videos images:images];
		});
	      }];

	[dataTask resume];
}

%new
+ (void)batchDownloadResources:(NSArray *)videos images:(NSArray *)images {
	BOOL hasVideos = [videos isKindOfClass:[NSArray class]] && videos.count > 0;
	BOOL hasImages = [images isKindOfClass:[NSArray class]] && images.count > 0;

	NSMutableArray<id> *videoFiles = [NSMutableArray arrayWithCapacity:videos.count];
	NSMutableArray<id> *imageFiles = [NSMutableArray arrayWithCapacity:images.count];
	for (NSInteger i = 0; i < videos.count; i++)
		[videoFiles addObject:[NSNull null]];
	for (NSInteger i = 0; i < images.count; i++)
		[imageFiles addObject:[NSNull null]];

	dispatch_group_t downloadGroup = dispatch_group_create();
	__block NSInteger totalDownloads = 0;
	__block NSInteger completedDownloads = 0;

	if (hasVideos) {
		totalDownloads += videos.count;
		for (NSInteger i = 0; i < videos.count; i++) {
			NSDictionary *videoDict = videos[i];
			NSString *videoUrl = videoDict[@"url"];
			if (videoUrl.length == 0) {
				completedDownloads++;
				continue;
			}
			dispatch_group_enter(downloadGroup);
			NSURL *videoDownloadUrl = [NSURL URLWithString:videoUrl];
			[self downloadMediaWithProgress:videoDownloadUrl
					      mediaType:MediaTypeVideo
					       progress:nil
					     completion:^(BOOL success, NSURL *fileURL) {
					       if (success && fileURL) {
						       @synchronized(videoFiles) {
							       videoFiles[i] = fileURL;
						       }
					       }
					       completedDownloads++;
					       dispatch_group_leave(downloadGroup);
					     }];
		}
	}

	if (hasImages) {
		totalDownloads += images.count;
		for (NSInteger i = 0; i < images.count; i++) {
			NSString *imageUrl = images[i];
			if (imageUrl.length == 0) {
				completedDownloads++;
				continue;
			}
			dispatch_group_enter(downloadGroup);
			NSURL *imageDownloadUrl = [NSURL URLWithString:imageUrl];
			[self downloadMediaWithProgress:imageDownloadUrl
					      mediaType:MediaTypeImage
					       progress:nil
					     completion:^(BOOL success, NSURL *fileURL) {
					       if (success && fileURL) {
						       @synchronized(imageFiles) {
							       imageFiles[i] = fileURL;
						       }
					       }
					       completedDownloads++;
					       dispatch_group_leave(downloadGroup);
					     }];
		}
	}

	dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
	  if (completedDownloads < totalDownloads) {
		  [self showToast:@"部分下载失败"];
	  }

	  NSInteger videoSuccessCount = 0;
	  for (id file in videoFiles) {
		  if ([file isKindOfClass:[NSURL class]]) {
			  [self saveMedia:(NSURL *)file mediaType:MediaTypeVideo completion:nil];
			  videoSuccessCount++;
		  }
	  }

	  NSInteger imageSuccessCount = 0;
	  for (id file in imageFiles) {
		  if ([file isKindOfClass:[NSURL class]]) {
			  [self saveMedia:(NSURL *)file mediaType:MediaTypeImage completion:nil];
			  imageSuccessCount++;
		  }
	  }

	  NSString *toastMessage;
	  if (hasVideos && hasImages) {
		  toastMessage = [NSString stringWithFormat:@"已保存 %ld/%ld 个视频和 %ld/%ld 张图片", (long)videoSuccessCount, (long)videos.count, (long)imageSuccessCount, (long)images.count];
	  } else if (hasVideos) {
		  toastMessage = [NSString stringWithFormat:@"已保存 %ld/%ld 个视频", (long)videoSuccessCount, (long)videos.count];
	  } else if (hasImages) {
		  toastMessage = [NSString stringWithFormat:@"已保存 %ld/%ld 张图片", (long)imageSuccessCount, (long)images.count];
	  }
	  [self showToast:toastMessage];
	});
}

%end

// 强制启用保存他人头像
%hook AFDProfileAvatarFunctionManager
- (BOOL)shouldShowSaveAvatarItem {
	BOOL shouldEnable = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableSaveAvatar"];
	if (shouldEnable) {
		return YES;
	}
	return %orig;
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
	if (userRadius < 0 || userRadius > 50) {
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

	if (isDarkMode) {
		[self setLabelsColorWhiteInView:containerView];
	}
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

%ctor {
	%init(DYYYSettingsGesture);
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		  %init(needDelays);
		});
	}
}
