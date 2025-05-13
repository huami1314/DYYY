#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"
#import "DYYYManager.h"

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

%hook UIView
- (void)layoutSubviews {
	%orig;

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

- (void)setFrame:(CGRect)frame {

	if ([self isKindOfClass:%c(AWEIMSkylightListView)] && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenAvatarList"]) {
		frame = CGRectZero;
	}

	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		%orig;
		return;
	}

	UIViewController *vc = [self firstAvailableUIViewController];
	if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)] || [vc isKindOfClass:%c(AWEDPlayerFeedPlayerViewController)]) {

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

%end

%hook AWEDPlayerFeedPlayerViewController

- (void)viewDidLayoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		UIView *contentView = self.contentView;
		if (contentView && contentView.superview) {
			CGRect frame = contentView.frame;
			CGFloat parentHeight = contentView.superview.frame.size.height;

			if (frame.size.height == parentHeight - 83) {
				frame.size.height = parentHeight;
				contentView.frame = frame;
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

%hook AWEElementStackView
static CGFloat stream_frame_y = 0;
static CGFloat right_tx = 0;
static CGFloat left_tx = 0;
static CGFloat currentScale = 1.0;
static BOOL leftScaleLocked = NO;
static CGFloat lockedLeftScale;
static BOOL vcTransformLocked = NO;

- (void)layoutSubviews {
    %orig;

	//处理视频流直播间文案缩放
	UIResponder *nextResponder = [self nextResponder];
	if ([nextResponder isKindOfClass:[UIView class]]) {
		UIView *parentView = (UIView *)nextResponder;
		UIViewController *viewController = [parentView firstAvailableUIViewController];

		if ([viewController isKindOfClass:%c(AWELiveNewPreStreamViewController)]) {
			NSString *vcScaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];
			if (vcScaleValue.length > 0) {
				CGFloat scale = [vcScaleValue floatValue];
				self.transform = CGAffineTransformIdentity;

				if (scale > 0 && scale != 1.0) {
					NSArray *subviews = [self.subviews copy];
					CGFloat ty = 0;

					for (UIView *view in subviews) {
						CGFloat viewHeight = view.frame.size.height;
						CGFloat contribution = (viewHeight - viewHeight * scale) / 2;
						ty += contribution;
					}

					CGFloat frameWidth = self.frame.size.width;
					CGFloat tx = (frameWidth - frameWidth * scale) / 2 - frameWidth * (1 - scale);

					CGAffineTransform newTransform = CGAffineTransformMakeScale(scale, scale);
					newTransform = CGAffineTransformTranslate(newTransform, tx / scale, ty / scale);

					self.transform = newTransform;
				} 
			}
		}
	}


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
        }
    }
    
    if ([self.accessibilityLabel isEqualToString:@"left"]) {
        NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];
        
        if (scaleValue.length > 0) {
            CGFloat scale = [scaleValue floatValue];
            
            // 重置transform以便重新计算
            self.transform = CGAffineTransformIdentity;
            
            if (scale > 0 && scale != 1.0) {
                // 计算垂直偏移
                NSArray *subviews = [self.subviews copy];
                CGFloat ty = 0;
                
                for (UIView *view in subviews) {
                    CGFloat viewHeight = view.frame.size.height;
                    CGFloat contribution = (viewHeight - viewHeight * scale) / 2;
                    ty += contribution;
                }

                // 计算左边距调整
                CGFloat frameWidth = self.frame.size.width;
                CGFloat left_tx = (frameWidth - frameWidth * scale) / 2 - frameWidth * (1 - scale);
                
                // 创建缩放和平移变换
                CGAffineTransform newTransform = CGAffineTransformMakeScale(scale, scale);
                newTransform = CGAffineTransformTranslate(newTransform, left_tx/scale, ty/scale);
                
                // 应用变换
                self.transform = newTransform;
                
                // 只锁定缩放系数
                leftScaleLocked = YES;
                lockedLeftScale = scale;
            } else {
                leftScaleLocked = NO;
            }
        }
    }
}

- (void)setTransform:(CGAffineTransform)transform {
    if ([self.accessibilityLabel isEqualToString:@"left"] && leftScaleLocked) {
        CGFloat a = transform.a;
        CGFloat d = transform.d;
        
        if (fabs(a - 1.0) > 0.01 || fabs(d - 1.0) > 0.01) {
            CGAffineTransform newTransform = CGAffineTransformMakeScale(lockedLeftScale, lockedLeftScale);
            newTransform.tx = transform.tx * (lockedLeftScale / a);
            newTransform.ty = transform.ty * (lockedLeftScale / d);
            %orig(newTransform);
        } else {
            %orig;
        }
    } else {
        %orig;
    }
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

%hook AWENormalModeTabBar

- (void)setHidden:(BOOL)hidden {
	%orig(hidden);

	BOOL hideBottomBg = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenBottomBg"];

	// 如果开启了隐藏底部背景，则直接隐藏背景视图，不进行其他判断
	if (hideBottomBg) {
		UIView *backgroundView = nil;
		for (UIView *subview in self.subviews) {
			if ([subview class] == [UIView class]) {
				BOOL hasImageView = NO;
				for (UIView *childView in subview.subviews) {
					if ([childView isKindOfClass:[UIImageView class]]) {
						hasImageView = YES;
						break;
					}
				}
				if (hasImageView) {
					backgroundView = subview;
					backgroundView.hidden = YES;
					break;
				}
			}
		}
	} else {
		Class generalButtonClass = %c(AWENormalModeTabBarGeneralButton);

		for (UIView *subview in self.subviews) {
			if ([subview isKindOfClass:generalButtonClass]) {
				AWENormalModeTabBarGeneralButton *button = (AWENormalModeTabBarGeneralButton *)subview;
				if ([button.accessibilityLabel isEqualToString:@"首页"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDisableHomeRefresh"] && button.status == 2) {
					if (button.gestureRecognizers && button.gestureRecognizers.count > 0) {
						button.userInteractionEnabled = NO;
					}
				} else if ([button.accessibilityLabel isEqualToString:@"首页"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDisableHomeRefresh"] && button.status == 1) {
					if (button.gestureRecognizers && button.gestureRecognizers.count > 0) {
						button.userInteractionEnabled = YES;
					}
				}
			}
		}

		// 仅对全屏模式处理背景显示逻辑
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
			UIView *backgroundView = nil;
			BOOL hideFriendsButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFriendsButton"];
			BOOL isHomeSelected = NO;
			BOOL isFriendsSelected = NO;

			for (UIView *subview in self.subviews) {
				if ([subview class] == [UIView class]) {
					BOOL hasImageView = NO;
					for (UIView *childView in subview.subviews) {
						if ([childView isKindOfClass:[UIImageView class]]) {
							hasImageView = YES;
							break;
						}
					}
					if (hasImageView) {
						backgroundView = subview;
						break;
					}
				}
			}

			// 查找当前选中的按钮
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:generalButtonClass]) {
					AWENormalModeTabBarGeneralButton *button = (AWENormalModeTabBarGeneralButton *)subview;
					// status == 2 表示按钮处于选中状态
					if (button.status == 2) {
						if ([button.accessibilityLabel isEqualToString:@"首页"]) {
							isHomeSelected = YES;
						} else if ([button.accessibilityLabel containsString:@"朋友"]) {
							isFriendsSelected = YES;
						}
					}
				}
			}

			// 根据当前选中的按钮决定是否显示背景
			if (backgroundView) {
				BOOL shouldShowBackground = isHomeSelected || (isFriendsSelected && !hideFriendsButton);
				backgroundView.hidden = shouldShowBackground;
			}
		}
	}

	// 隐藏分隔线
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		for (UIView *subview in self.subviews) {
			if (![subview isKindOfClass:[UIView class]])
				continue;
			if (subview.frame.size.height <= 0.5 && subview.frame.size.width > 300) {
				subview.hidden = YES;
				CGRect frame = subview.frame;
				frame.size.height = 0;
				subview.frame = frame;
				subview.alpha = 0;
			}
		}
	}
}

%end

%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}
