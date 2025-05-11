#import "AwemeHeaders.h"

%hook UIView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDiscover"] && [self.accessibilityLabel isEqualToString:@"搜索"]) {
		[self removeFromSuperview];
	}
}
%end

%hook AWEFeedLiveMarkView
- (void)setHidden:(BOOL)hidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
		hidden = YES;
	}

	%orig(hidden);
}
%end

// 隐藏头像加号和透明
%hook LOTAnimationView
- (void)layoutSubviews {
	%orig;

	// 检查是否需要隐藏加号
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLOTAnimationView"]) {
		[self removeFromSuperview];
		return;
	}

	// 应用透明度设置
	NSString *transparencyValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYAvatarViewTransparency"];
	if (transparencyValue && transparencyValue.length > 0) {
		CGFloat alphaValue = [transparencyValue floatValue];
		if (alphaValue >= 0.0 && alphaValue <= 1.0) {
			self.alpha = alphaValue;
		}
	}
}
%end

// 首页头像隐藏和透明
%hook AWEAdAvatarView
- (void)layoutSubviews {
	%orig;

	// 检查是否需要隐藏头像
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
		[self removeFromSuperview];
		return;
	}

	// 应用透明度设置
	NSString *transparencyValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYAvatarViewTransparency"];
	if (transparencyValue && transparencyValue.length > 0) {
		CGFloat alphaValue = [transparencyValue floatValue];
		if (alphaValue >= 0.0 && alphaValue <= 1.0) {
			self.alpha = alphaValue;
		}
	}
}
%end

// 移除同城吃喝玩乐提示框
%hook AWENearbySkyLightCapsuleView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideNearbyCapsuleView"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 移除共创头像列表
%hook AWEPlayInteractionCoCreatorNewInfoView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGongChuang"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隐藏右下音乐和取消静音按钮
%hook AFDCancelMuteAwemeView
- (void)layoutSubviews {
	%orig;

	UIView *superview = self.superview;

	if ([superview isKindOfClass:NSClassFromString(@"AWEBaseElementView")]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCancelMute"]) {
			self.hidden = YES;
		}
	}
}
%end

// 隐藏弹幕按钮
%hook AWEPlayDanmakuInputContainView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDanmuButton"]) {
		self.hidden = YES;
	}
}

%end

// 隐藏作者店铺
%hook AWEECommerceEntryView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideHisShop"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隐藏评论区大家都在搜
%hook AWECommentSearchAnchorView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}

%end

// 隐藏评论区免费去看短剧
%hook AWEShowPlayletCommentHeaderView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}

%end

// 隐藏评论区定位
%hook AWEPOIEntryAnchorView

- (void)p_addViews {
	// 检查用户偏好设置
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		// 直接跳过视图添加流程
		return;
	}
	// 执行原始方法
	%orig;
}

- (void)setIconUrls:(id)arg1 defaultImage:(id)arg2 {
	// 根据需求选择是否拦截资源加载
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		// 可选：传入空值阻止资源加载
		%orig(nil, nil);
		return;
	}
	// 正常传递参数
	%orig(arg1, arg2);
}

- (void)setContentSize:(CGSize)arg1 {
	// 可选：动态调整尺寸计算逻辑
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		// 计算不包含评论视图的尺寸
		CGSize newSize = CGSizeMake(arg1.width, arg1.height - 44); // 示例减法
		%orig(newSize);
		return;
	}
	// 保持原有尺寸计算
	%orig(arg1);
}

%end

// 隐藏评论音乐
%hook AWECommentGuideLunaAnchorView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}

%end

// Swift 类组 - 这些会在 %ctor 中动态初始化
%group CommentHeaderGeneralGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}
%end
%end
%group CommentHeaderGoodsGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}
%end
%end
%group CommentHeaderTemplateGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}
%end
%end
// Swift 类初始化
%ctor {

	// 动态获取 Swift 类并初始化对应的组
	Class commentHeaderGeneralClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderGeneralView");
	if (commentHeaderGeneralClass) {
		%init(CommentHeaderGeneralGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView = commentHeaderGeneralClass);
	}

	Class commentHeaderGoodsClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderGoodsView");
	if (commentHeaderGoodsClass) {
		%init(CommentHeaderGoodsGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView = commentHeaderGoodsClass);
	}

	Class commentHeaderTemplateClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderTemplateAnchorView");
	if (commentHeaderTemplateClass) {
		%init(CommentHeaderTemplateGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView = commentHeaderTemplateClass);
	}
}

// 去除隐藏大家都在搜后的留白
%hook AWESearchAnchorListModel

- (BOOL)hideWords {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"];
}

%end

// 隐藏观看历史搜索
%hook AWEDiscoverFeedEntranceView
- (id)init {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideInteractionSearch"]) {
		return nil;
	}
	return %orig;
}
%end

// 隐藏校园提示
%hook AWETemplateTagsCommonView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplateTags"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隐藏挑战贴纸
%hook AWEFeedStickerContainerView

- (BOOL)isHidden {
	BOOL origHidden = %orig;
	BOOL hideRecommend = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"];
	return origHidden || hideRecommend;
}

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"];
	%orig(forceHide ? YES : hidden);
}

%end

// 去除"我的"加入挑战横幅
%hook AWEPostWorkViewController
- (BOOL)isDouGuideTipViewShow {
	BOOL r = %orig;
	NSLog(@"Original value: %@", @(r));
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"]) {
		NSLog(@"Force return YES");
		return YES;
	}
	return r;
}
%end

// 隐藏消息页顶栏头像气泡
%hook AFDSkylightCellBubble
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenAvatarBubble"]) {
		[self removeFromSuperview];
		return;
	}
}
%end

// 隐藏消息页开启通知提示
%hook AWEIMMessageTabOptPushBannerView

- (instancetype)initWithFrame:(CGRect)frame {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePushBanner"]) {
		return %orig(CGRectMake(frame.origin.x, frame.origin.y, 0, 0));
	}
	return %orig;
}

%end

// 隐藏拍同款
%hook AWEFeedAnchorContainerView

- (BOOL)isHidden {
	BOOL origHidden = %orig;
	BOOL hideSamestyle = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFeedAnchorContainer"];
	return origHidden || hideSamestyle;
}

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFeedAnchorContainer"];
	%orig(forceHide ? YES : hidden);
}

%end

// 隐藏合集和声明
%hook AWEAntiAddictedNoticeBarView
- (void)layoutSubviews {
	%orig;

	// 获取 tipsLabel 属性
	UILabel *tipsLabel = [self valueForKey:@"tipsLabel"];

	if (tipsLabel && [tipsLabel isKindOfClass:%c(UILabel)]) {
		NSString *labelText = tipsLabel.text;

		if (labelText) {
			// 明确判断是合集还是作者声明
			if ([labelText containsString:@"合集"]) {
				// 如果是合集，只检查合集的开关
				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplateVideo"]) {
					[self removeFromSuperview];
				}
			} else {
				// 如果不是合集（即作者声明），只检查声明的开关
				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAntiAddictedNotice"]) {
					[self removeFromSuperview];
				}
			}
		}
	}
}
%end

// 隐藏我的添加朋友
%hook AWEProfileNavigationButton
- (void)setupUI {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideButton"]) {
		return;
	}
	%orig;
}
%end

// 隐藏朋友"关注/不关注"按钮
%hook AWEFeedUnfollowFamiliarFollowAndDislikeView
- (void)showUnfollowFamiliarView {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFamiliar"]) {
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隐藏朋友日常按钮
%hook AWEFamiliarNavView
- (void)layoutSubviews {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFamiliar"]) {
		self.hidden = YES;
	}

	%orig;
}
%end

// 隐藏分享给朋友提示
%hook AWEPlayInteractionStrongifyShareContentView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareContentView"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 移除下面推荐框黑条
%hook AWEPlayInteractionRelatedVideoView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideBottomRelated"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

%hook AWEFeedRelatedSearchTipView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideBottomRelated"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

%hook AWENormalModeTabBarBadgeContainerView

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenBottomDot"]) {
		for (UIView *subview in [self subviews]) {
			if ([subview isKindOfClass:NSClassFromString(@"DUXBadge")]) {
				[subview setHidden:YES];
			}
		}
	}
}

%end

%hook AWELeftSideBarEntranceView

- (void)layoutSubviews {

	__block BOOL isInTargetController = NO;
	UIResponder *currentResponder = self;

	while ((currentResponder = [currentResponder nextResponder])) {
		if ([currentResponder isKindOfClass:NSClassFromString(@"AWEUserHomeViewControllerV2")]) {
			isInTargetController = YES;
			break;
		}
	}

	if (!isInTargetController && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenLeftSideBar"]) {
		for (UIView *subview in self.subviews) {
			subview.hidden = YES;
		}
	}
}

%end

%hook AWEFeedVideoButton

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"点赞"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeButton"]) {
			[self removeFromSuperview];
			return;
		}

		// 隐藏点赞数值标签
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeLabel"]) {
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:[UILabel class]]) {
					subview.hidden = YES;
				}
			}
		}
	} else if ([accessibilityLabel isEqualToString:@"评论"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentButton"]) {
			[self removeFromSuperview];
			return;
		}

		// 隐藏评论数值标签
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLabel"]) {
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:[UILabel class]]) {
					subview.hidden = YES;
				}
			}
		}
	} else if ([accessibilityLabel isEqualToString:@"分享"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareButton"]) {
			[self removeFromSuperview];
			return;
		}

		// 隐藏分享数值标签
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareLabel"]) {
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:[UILabel class]]) {
					subview.hidden = YES;
				}
			}
		}
	} else if ([accessibilityLabel isEqualToString:@"收藏"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectButton"]) {
			[self removeFromSuperview];
			return;
		}

		// 隐藏收藏数值标签
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectLabel"]) {
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:[UILabel class]]) {
					subview.hidden = YES;
				}
			}
		}
	}
}

%end

%hook UIButton

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    %orig;
    
    if ([title isEqualToString:@"加入挑战"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"]) {
                UIResponder *responder = self;
                BOOL isInPlayInteractionViewController = NO;

                while ((responder = [responder nextResponder])) {
                    if ([responder isKindOfClass:%c(AWEPlayInteractionViewController)]) {
                        isInPlayInteractionViewController = YES;
                        break;
                    }
                }

                if (isInPlayInteractionViewController) {
                    UIView *parentView = self.superview;
                    if (parentView) {
                        UIView *grandParentView = parentView.superview;
                        if (grandParentView) {
                            grandParentView.hidden = YES;
                        } else {
                            parentView.hidden = YES;
                        }
                    } else {
                        self.hidden = YES;
                    }
                }
            }
        });
    }
}

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"拍照搜同款"] || [accessibilityLabel isEqualToString:@"扫一扫"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideScancode"]) {
			[self removeFromSuperview];
			return;
		}
	}
}

%end

%hook ACCGestureResponsibleStickerView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"]) {
		[self removeFromSuperview];
		return;
	}
}
%end

%hook AWEMusicCoverButton

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"音乐详情"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMusicButton"]) {
			[self removeFromSuperview];
			return;
		}
	}
}

%end

%hook AWEPlayInteractionListenFeedView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMusicButton"]) {
		[self removeFromSuperview];
		return;
	}
}
%end

%hook AWEPlayInteractionFollowPromptView

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"关注"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
			[self removeFromSuperview];
			return;
		}
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFollowPromptView"]) {
			self.userInteractionEnabled = NO;
			[self removeFromSuperview];
			return;
		}
	}
}

%end

%hook AWENormalModeTabBar

- (void)layoutSubviews {
	%orig;

	BOOL hideShop = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShopButton"];
	BOOL hideMsg = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMessageButton"];
	BOOL hideFri = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFriendsButton"];
	BOOL hideMe = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMyButton"];

	NSMutableArray *visibleButtons = [NSMutableArray array];
	Class generalButtonClass = %c(AWENormalModeTabBarGeneralButton);
	Class plusButtonClass = %c(AWENormalModeTabBarGeneralPlusButton);

	for (UIView *subview in self.subviews) {
		if (![subview isKindOfClass:generalButtonClass] && ![subview isKindOfClass:plusButtonClass])
			continue;

		NSString *label = subview.accessibilityLabel;
		BOOL shouldHide = NO;

		if ([label isEqualToString:@"商城"]) {
			shouldHide = hideShop;
		} else if ([label containsString:@"消息"]) {
			shouldHide = hideMsg;
		} else if ([label containsString:@"朋友"]) {
			shouldHide = hideFri;
		} else if ([label containsString:@"我"]) {
			shouldHide = hideMe;
		}

		if (!shouldHide) {
			[visibleButtons addObject:subview];
		} else {
			[subview removeFromSuperview];
		}
	}

	[visibleButtons sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
	  return [@(a.frame.origin.x) compare:@(b.frame.origin.x)];
	}];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		// iPad端布局逻辑
		UIView *targetView = nil;
		CGFloat containerWidth = self.bounds.size.width;
		CGFloat offsetX = 0;

		// 查找目标容器视图
		for (UIView *subview in self.subviews) {
			if ([subview class] == [UIView class] && fabs(subview.frame.size.width - self.bounds.size.width) > 0.1) {
				targetView = subview;
				containerWidth = subview.frame.size.width;
				offsetX = subview.frame.origin.x;
				break;
			}
		}

		// 在目标容器内均匀分布按钮
		CGFloat buttonWidth = containerWidth / visibleButtons.count;
		for (NSInteger i = 0; i < visibleButtons.count; i++) {
			UIView *button = visibleButtons[i];
			button.frame = CGRectMake(offsetX + (i * buttonWidth), button.frame.origin.y, buttonWidth, button.frame.size.height);
		}
	} else {
		// iPhone端布局逻辑
		CGFloat totalWidth = self.bounds.size.width;
		CGFloat buttonWidth = totalWidth / visibleButtons.count;

		for (NSInteger i = 0; i < visibleButtons.count; i++) {
			UIView *button = visibleButtons[i];
			button.frame = CGRectMake(i * buttonWidth, button.frame.origin.y, buttonWidth, button.frame.size.height);
		}
	}
}

%end

// 隐藏双指缩放虾线
%hook AWELoadingAndVolumeView

- (void)layoutSubviews {
	%orig;

	if ([self respondsToSelector:@selector(removeFromSuperview)]) {
		[self removeFromSuperview];
	}
	self.hidden = YES;
	return;
}

%end

// 隐藏状态栏
%hook AWEFeedRootViewController
- (BOOL)prefersStatusBarHidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHideStatusbar"]) {
		return YES;
	} else {
		if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
		    class_getInstanceMethod([%c(AWEFeedRootViewController) class], @selector(prefersStatusBarHidden))) {
			return %orig;
		}
		return NO;
	}
}
%end

// 直播状态栏
%hook IESLiveAudienceViewController
- (BOOL)prefersStatusBarHidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHideStatusbar"]) {
		return YES;
	} else {
		if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
		    class_getInstanceMethod([%c(IESLiveAudienceViewController) class], @selector(prefersStatusBarHidden))) {
			return %orig;
		}
		return NO;
	}
}
%end

// 隐藏视频定位
%hook AWEFeedTemplateAnchorView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLocation"]) {
		[self removeFromSuperview];
		return;
	}
}

%end

// 隐藏同城视频定位
%hook AWEMarkView

- (void)layoutSubviews {
    %orig;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLocation"]) {
        self.hidden = YES;
        return;
    }
}

%end

%hook AWEPlayInteractionSearchAnchorView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideInteractionSearch"]) {
		[self removeFromSuperview];
		return;
	}
}

%end

%hook AWEAwemeMusicInfoView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideQuqishuiting"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隐藏短剧合集
%hook AWETemplatePlayletView

- (void)layoutSubviews {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplatePlaylet"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隐藏视频上方搜索长框
%hook AWESearchEntranceView

- (void)layoutSubviews {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSearchEntrance"]) {
		self.hidden = YES;
		return;
	}
	%orig;
}

%end

// 隐藏视频滑条
%hook AWEStoryProgressSlideView

- (void)layoutSubviews {
	%orig;

	BOOL shouldHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideStoryProgressSlide"];
	if (!shouldHide)
		return;
	__block UIView *targetView = nil;
	[self.subviews enumerateObjectsUsingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
	  if ([obj isKindOfClass:NSClassFromString(@"UISlider")] || obj.frame.size.height < 5) {
		  targetView = obj.superview;
		  *stop = YES;
	  }
	}];

	if (targetView) {
		targetView.hidden = YES;
	} else {
	}
}

%end

// 隐藏好友分享私信
%hook AFDNewFastReplyView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePrivateMessages"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隐藏下面底部热点框
%hook AWENewHotSpotBottomBarView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideHotspot"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

%hook AWETemplateHotspotView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideHotspot"]) {
		[self removeFromSuperview];
		return;
	}
}

%end

// 隐藏关注直播
%hook AWEConcernSkylightCapsuleView
- (void)setHidden:(BOOL)hidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideConcernCapsuleView"]) {
		[self removeFromSuperview];
		return;
	}

	%orig(hidden);
}
%end

// 隐藏直播发现
%hook AWEFeedLiveTabRevisitControlView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveDiscovery"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
}
%end

// 隐藏直播点歌
%hook IESLiveKTVSongIndicatorView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideKTVSongIndicator"]) {
		self.hidden = YES;
		[self removeFromSuperview];
	}
}
%end

// 隐藏图片滑条
%hook AWEStoryProgressContainerView
- (BOOL)isHidden {
	BOOL originalValue = %orig;
	BOOL customHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDotsIndicator"];
	return originalValue || customHide;
}

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDotsIndicator"];
	%orig(forceHide ? YES : hidden);
}
%end

// 隐藏昵称右侧
%hook UILabel
- (void)layoutSubviews {
	%orig;

	BOOL hideRightLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideRightLable"];
	if (!hideRightLabel)
		return;

	NSString *accessibilityLabel = self.accessibilityLabel;
	if (!accessibilityLabel || accessibilityLabel.length == 0)
		return;

	NSString *trimmedLabel = [accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	BOOL shouldHide = NO;

	if ([trimmedLabel hasSuffix:@"人共创"]) {
		NSString *prefix = [trimmedLabel substringToIndex:trimmedLabel.length - 3];
		NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
		shouldHide = ([prefix rangeOfCharacterFromSet:nonDigits].location == NSNotFound);
	}

	if (!shouldHide) {
		shouldHide = [trimmedLabel isEqualToString:@"章节要点"] || [trimmedLabel isEqualToString:@"图集"];
	}

	if (shouldHide) {
		self.hidden = YES;

		// 找到父视图是否为 UIStackView
		UIView *superview = self.superview;
		if ([superview isKindOfClass:[UIStackView class]]) {
			UIStackView *stackView = (UIStackView *)superview;
			// 刷新 UIStackView 的布局
			[stackView layoutIfNeeded];
		}
	}
}
%end

// 隐藏顶栏关注下的提示线
%hook AWEFeedMultiTabSelectedContainerView

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidentopbarprompt"];

	if (forceHide) {
		%orig(YES);
	} else {
		%orig(hidden);
	}
}

%end

%hook AFDRecommendToFriendEntranceLabel
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideRecommendTips"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隐藏自己无公开作品的视图
%hook AWEProfileMixCollectionViewCell
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePostView"]) {
		self.hidden = YES;
	}
}
%end

%hook AWEProfileTaskCardStyleListCollectionViewCell
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePostView"]) {
		self.hidden = YES;
	}
}
%end

// 隐藏关注直播顶端
%hook AWENewLiveSkylightViewController

// 隐藏顶部直播视图 - 添加条件判断
- (void)showSkylight:(BOOL)arg0 animated:(BOOL)arg1 actionMethod:(unsigned long long)arg2 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidenLiveView"]) {
		return;
	}
	%orig(arg0, arg1, arg2);
}

- (void)updateIsSkylightShowing:(BOOL)arg0 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidenLiveView"]) {
		%orig(NO);
	} else {
		%orig(arg0);
	}
}

%end

// 隐藏同城顶端
%hook AWENearbyFullScreenViewModel

- (void)setShowSkyLight:(id)arg1 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMenuView"]) {
		arg1 = nil;
	}
	%orig(arg1);
}

- (void)setHaveSkyLight:(id)arg1 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMenuView"]) {
		arg1 = nil;
	}
	%orig(arg1);
}

%end

// 隐藏笔记
%hook AWECorrelationItemTag

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideItemTag"]) {
		self.frame = CGRectMake(0, 0, 0, 0);
		self.hidden = YES;
	}
}

%end

// 隐藏话题
%hook AWEPlayInteractionTemplateButtonGroup
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplateGroup"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

%hook AWEPlayInteractionViewController

- (void)onVideoPlayerViewDoubleClicked:(id)arg1 {
	BOOL isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDouble"];
	if (!isSwitchOn) {
		%orig;
	}
}
%end

// 隐藏右上搜索，但可点击
%hook AWEHPDiscoverFeedEntranceView

- (void)layoutSubviews {
    %orig;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDiscover"]) {
        UIView *firstSubview = self.subviews.firstObject;
        if ([firstSubview isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)firstSubview).image = nil;
        }
    }
}

%end

// 隐藏点击进入直播间
%hook AWELiveFeedStatusLabel
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideEnterLive"]) {
		UIView *parentView = self.superview;
		UIView *grandparentView = parentView.superview;

		if (grandparentView) {
			grandparentView.hidden = YES;
		} else if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}
%end

// 去除消息群直播提示
%hook AWEIMCellLiveStatusContainerView

- (void)p_initUI {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYGroupLiving"])
		%orig;
}
%end

%hook AWELiveStatusIndicatorView

- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYGroupLiving"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

%hook AWELiveSkylightCatchView
- (void)layoutSubviews {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidenLiveCapsuleView"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}

%end

// 隐藏首页直播胶囊
%hook AWEHPTopTabItemBadgeContentView

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveCapsuleView"]) {
		self.frame = CGRectMake(0, 0, 0, 0);
		self.hidden = YES;
	}
}

%end

// 隐藏群商店
%hook AWEIMFansGroupTopDynamicDomainTemplateView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGroupShop"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 去除群聊天输入框上方快捷方式
%hook AWEIMInputActionBarInteractor

- (void)p_setupUI {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGroupInputActionBar"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隐藏相机定位
%hook AWETemplateCommonView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCameraLocation"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隐藏侧栏红点
%hook AWEHPTopBarCTAItemView

- (void)showRedDot {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYisHiddenSidebarDot"])
		%orig;
}

- (void)hideCountRedDot {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYisHiddenSidebarDot"])
		%orig;
}

- (void)layoutSubviews {
	%orig;
	for (UIView *subview in self.subviews) {
		if ([subview isKindOfClass:[%c(DUXBadge) class]]) {
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenSidebarDot"]) {
				subview.hidden = YES;
			}
		}
	}
}
%end

%hook AWELeftSideBarEntranceView

- (void)setRedDot:(id)redDot {
	%orig(nil);
}

- (void)setNumericalRedDot:(id)numericalRedDot {
	%orig(nil);
}

%end

// 隐藏搜同款
%hook ACCStickerContainerView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSearchSame"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES; // 隐藏更彻底
		return;
	}
	%orig;
}
%end

// 隐藏礼物展馆
%hook BDXWebView
- (void)layoutSubviews {
	%orig;

	BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGiftPavilion"];
	if (!enabled)
		return;

	NSString *title = [self valueForKey:@"title"];

	if ([title containsString:@"任务Banner"] || [title containsString:@"活动Banner"]) {
		[self removeFromSuperview];
	}
}
%end

%hook AWEVideoTypeTagView

- (void)setupUI {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideLiveGIF"])
		%orig;
}
%end

%hook IESLiveActivityBannnerView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGiftPavilion"]) {
		self.hidden = YES;
	}
}

%end

// 隐藏直播广场
%hook IESLiveFeedDrawerEntranceView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLivePlayground"]) {
		self.hidden = YES;
	}
}

%end

// 隐藏顶栏红点
%hook AWEHPTopTabItemBadgeContentView
- (id)showBadgeWithBadgeStyle:(NSUInteger)style badgeConfig:(id)config count:(NSInteger)count text:(id)text {
	BOOL hideEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTopBarBadge"];

	if (hideEnabled) {
		// 阻断徽章创建
		return nil; // 返回 nil 阻止视图生成
	} else {
		// 未启用隐藏功能时正常显示
		return %orig(style, config, count, text);
	}
}
%end

// 隐藏直播退出清屏、投屏按钮
%hook IESLiveButton

- (void)layoutSubviews {
	%orig;

	// 处理清屏按钮
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomClear"]) {
		if ([self.accessibilityLabel isEqualToString:@"退出清屏"] && self.superview) {
			[self.superview removeFromSuperview];
		}
	}

	// 投屏按钮
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomMirroring"]) {
		if ([self.accessibilityLabel isEqualToString:@"投屏"] && self.superview) {
			[self.superview removeFromSuperview];
		}
	}

	// 横屏按钮,可点击
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomFullscreen"]) {
		if ([self.accessibilityLabel isEqualToString:@"横屏"] && self.superview) {
			for (UIView *subview in self.subviews) {
			subview.hidden = YES;
			}
		}
	}
}

%end

// 隐藏直播间右上方关闭直播按钮
%hook IESLiveLayoutPlaceholderView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomClose"]) {
		self.hidden = YES;
	}
}
%end

// 隐藏直播间流量弹窗
%hook AWELiveFlowAlertView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCellularAlert"]) {
		self.hidden = YES;
	}
}
%end

// 隐藏直播间商品信息
%hook IESECLivePluginLayoutView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveGoodsMsg"]) {
		[self removeFromSuperview];
	}
}
%end

// 隐藏直播间点赞动画
%hook HTSLiveDiggView
- (void)setIconImageView:(UIImageView *)arg1 {
	if (DYYYGetBool(@"DYYYHideLiveLikeAnimation")) {
		%orig(nil);
	} else {
		%orig(arg1);
	}
}
%end

// 屏蔽青少年模式弹窗
%hook AWEUIAlertView
- (void)show {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideteenmode"])
		%orig;
}
%end

// 屏蔽青少年模式弹窗
%hook AWETeenModeAlertView
- (BOOL)show {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideteenmode"]) {
		return NO;
	}
	return %orig;
}
%end

// 屏蔽青少年模式弹窗
%hook AWETeenModeSimpleAlertView
- (BOOL)show {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideteenmode"]) {
		return NO;
	}
	return %orig;
}
%end

// 强制启用新版抖音长按 UI（现代风）
%hook AWELongPressPanelDataManager
+ (BOOL)enableModernLongPressPanelConfigWithSceneIdentifier:(id)arg1 {
	return DYYYGetBool(@"DYYYisEnableModern");
}
%end

%hook AWELongPressPanelABSettings
+ (NSUInteger)modernLongPressPanelStyleMode {
	return DYYYGetBool(@"DYYYisEnableModern") ? 1 : 0;
}
%end

%hook AWEModernLongPressPanelUIConfig
+ (NSUInteger)modernLongPressPanelStyleMode {
	return DYYYGetBool(@"DYYYisEnableModern") ? 1 : 0;
}
%end

// 聊天视频底部评论框背景透明
%hook AWEIMFeedBottomQuickEmojiInputBar

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChatCommentBg"]) {
		UIView *parentView = self.superview;
		while (parentView) {
			if ([NSStringFromClass([parentView class]) isEqualToString:@"UIView"]) {
				dispatch_async(dispatch_get_main_queue(), ^{
				  parentView.backgroundColor = [UIColor clearColor];
				  parentView.layer.backgroundColor = [UIColor clearColor].CGColor;
				  parentView.opaque = NO;
				});
				break;
			}
			parentView = parentView.superview;
		}
	}
}

%end

// 隐藏章节进度条
%hook AWEDemaciaChapterProgressSlider

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChapterProgress"]) {
		[self removeFromSuperview];
	}
}

%end

// 移除极速版我的片面红包横幅
%hook AWELuckyCatBannerView
- (id)initWithFrame:(CGRect)frame {
	return nil;
}

- (id)init {
	return nil;
}
%end

// 极速版红包激励挂件容器视图类组（移除逻辑）
%group IncentivePendantGroup
%hook AWEIncentiveSwiftImplDOUYINLite_IncentivePendantContainerView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePendantGroup"]) {
		[self removeFromSuperview]; // 移除视图
	}
}
%end
%end

// Swift 红包类初始化
%ctor {

	// 初始化红包激励挂件容器视图类组
	Class incentivePendantClass = objc_getClass("AWEIncentiveSwiftImplDOUYINLite.IncentivePendantContainerView");
	if (incentivePendantClass) {
		%init(IncentivePendantGroup, AWEIncentiveSwiftImplDOUYINLite_IncentivePendantContainerView = incentivePendantClass);
	}
}

%hook AWEFeedChannelManager

- (void)reloadChannelWithChannelModels:(id)arg1 currentChannelIDList:(id)arg2 reloadType:(id)arg3 selectedChannelID:(id)arg4 {
	NSArray *channelModels = arg1;
	NSMutableArray *newChannelModels = [NSMutableArray array];
	NSArray *currentChannelIDList = arg2;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSMutableArray *newCurrentChannelIDList = [NSMutableArray arrayWithArray:currentChannelIDList];

	NSString *hideOtherChannels = [defaults objectForKey:@"DYYYHideOtherChannel"] ?: @"";
	NSArray *hideChannelKeywords = [hideOtherChannels componentsSeparatedByString:@","];

	for (AWEHPTopTabItemModel *tabItemModel in channelModels) {
		NSString *channelID = tabItemModel.channelID;
		NSString *newChannelTitle = tabItemModel.title;
		NSString *oldChannelTitle = tabItemModel.channelTitle;

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
		} else if ([channelID isEqualToString:@"homepage_pad_cinema"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideCinema"];
		} else if ([channelID isEqualToString:@"homepage_pad_kids_v2"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideKidsV2"];
		} else if ([channelID isEqualToString:@"homepage_pad_game"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideGame"];
		}

		if (oldChannelTitle.length > 0 || newChannelTitle.length > 0) {
			for (NSString *keyword in hideChannelKeywords) {
				if (keyword.length > 0 && ([oldChannelTitle containsString:keyword] || [newChannelTitle containsString:keyword])) {
					isHideChannel = YES;
				}
			}
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

%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}

// 隐藏键盘ai
//  隐藏父视图的子视图
static void hideParentViewsSubviews(UIView *view) {
	if (!view)
		return;
	// 获取第一层父视图
	UIView *parentView = [view superview];
	if (!parentView)
		return;
	// 获取第二层父视图
	UIView *grandParentView = [parentView superview];
	if (!grandParentView)
		return;
	// 获取第三层父视图
	UIView *greatGrandParentView = [grandParentView superview];
	if (!greatGrandParentView)
		return;
	// 隐藏所有子视图
	for (UIView *subview in greatGrandParentView.subviews) {
		subview.hidden = YES;
	}
}
// 递归查找目标视图
static void findTargetViewInView(UIView *view) {
	if ([view isKindOfClass:NSClassFromString(@"AWESearchKeyboardVoiceSearchEntranceView")]) {
		hideParentViewsSubviews(view);
		return;
	}
	for (UIView *subview in view.subviews) {
		findTargetViewInView(subview);
	}
}
// 构造函数
%ctor {
	// 注册键盘通知
	[[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
							  object:nil
							   queue:[NSOperationQueue mainQueue]
						      usingBlock:^(NSNotification *notification) {
							// 检查开关状态
							if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidekeyboardai"]) {
								// 执行查找隐藏
								for (UIWindow *window in [UIApplication sharedApplication].windows) {
									findTargetViewInView(window);
								}
							}
						      }];
}
