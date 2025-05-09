#import "AwemeHeaders.h"
#import "DYYYManager.h"

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
	BOOL DYYYForceDownloadEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYForceDownloadEmotion"];
	if (DYYYForceDownloadEmotion) {
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
	BOOL DYYYForceDownloadEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYForceDownloadEmotion"];
	if (DYYYForceDownloadEmotion) {
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
						completion:^(BOOL success){
						}];
				return;
			}
		}
	}
	%orig;
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

%hook AWEIMEmoticonPreviewV2

// 添加保存按钮
- (void)layoutSubviews {
	%orig;
	static char kHasSaveButtonKey;
	BOOL DYYYForceDownloadPreviewEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYForceDownloadPreviewEmotion"];
	if (DYYYForceDownloadPreviewEmotion) {
		if (!objc_getAssociatedObject(self, &kHasSaveButtonKey)) {
			UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
			UIImage *downloadIcon = [UIImage systemImageNamed:@"arrow.down.circle"];
			[saveButton setImage:downloadIcon forState:UIControlStateNormal];
			[saveButton setTintColor:[UIColor whiteColor]];
			saveButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.9 alpha:0.5];

			saveButton.layer.shadowColor = [UIColor blackColor].CGColor;
			saveButton.layer.shadowOffset = CGSizeMake(0, 2);
			saveButton.layer.shadowOpacity = 0.3;
			saveButton.layer.shadowRadius = 3;

			saveButton.translatesAutoresizingMaskIntoConstraints = NO;
			[self addSubview:saveButton];
			CGFloat buttonSize = 24.0;
			saveButton.layer.cornerRadius = buttonSize / 2;

			[NSLayoutConstraint activateConstraints:@[
				[saveButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-15], [saveButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-10],
				[saveButton.widthAnchor constraintEqualToConstant:buttonSize], [saveButton.heightAnchor constraintEqualToConstant:buttonSize]
			]];

			saveButton.userInteractionEnabled = YES;
			[saveButton addTarget:self action:@selector(dyyy_saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
			objc_setAssociatedObject(self, &kHasSaveButtonKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}
	}
}

%new
- (void)dyyy_saveButtonTapped:(UIButton *)sender {
	// 获取表情包URL
	AWEIMEmoticonModel *emoticonModel = self.model;
	if (!emoticonModel) {
		[DYYYManager showToast:@"无法获取表情包信息"];
		return;
	}

	NSString *urlString = nil;
	MediaType mediaType = MediaTypeImage;

	// 尝试动态URL
	if ([emoticonModel valueForKey:@"animate_url"]) {
		urlString = [emoticonModel valueForKey:@"animate_url"];
	}
	// 如果没有动态URL，则使用静态URL
	else if ([emoticonModel valueForKey:@"static_url"]) {
		urlString = [emoticonModel valueForKey:@"static_url"];
	}
	// 使用animateURLModel获取URL
	else if ([emoticonModel valueForKey:@"animateURLModel"]) {
		AWEURLModel *urlModel = [emoticonModel valueForKey:@"animateURLModel"];
		if (urlModel.originURLList.count > 0) {
			urlString = urlModel.originURLList[0];
		}
	}

	if (!urlString) {
		[DYYYManager showToast:@"无法获取表情包链接"];
		return;
	}

	NSURL *url = [NSURL URLWithString:urlString];
	[DYYYManager downloadMedia:url
			 mediaType:MediaTypeHeic
			completion:^(BOOL success){
			}];
}

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

%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}
