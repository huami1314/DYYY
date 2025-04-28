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
    if (!objc_getAssociatedObject(self, &kHasSaveButtonKey)) {
        // 创建保存按钮
        UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
        
        // 使用图标而非文字
        UIImage *downloadIcon = [UIImage imageNamed:@"ic_boxarrowdownhigh_outlined_20"];
        if (!downloadIcon) {
            // 备用方案：尝试从应用中查找图标
            downloadIcon = [UIImage imageNamed:@"ic_boxarrowdownhigh_outlined_20" inBundle:[NSBundle mainBundle] compatibleWithTraitCollection:nil];
            
            // 如果仍然找不到，使用系统图标(iOS 13+)
            if (!downloadIcon && @available(iOS 13.0, *)) {
                downloadIcon = [UIImage systemImageNamed:@"arrow.down.circle"];
            }
        }
        
        [saveButton setImage:downloadIcon forState:UIControlStateNormal];
        [saveButton setTintColor:[UIColor whiteColor]];
        
        // 设置半透明背景
        saveButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.9 alpha:0.5];
        saveButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        
        // 添加阴影效果
        saveButton.layer.shadowColor = [UIColor blackColor].CGColor;
        saveButton.layer.shadowOffset = CGSizeMake(0, 2);
        saveButton.layer.shadowOpacity = 0.3;
        saveButton.layer.shadowRadius = 3;
        
        // 将按钮添加到主视图
        saveButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:saveButton];
        
        // 设置大小和圆角
        CGFloat buttonSize = 24.0;
        saveButton.layer.cornerRadius = buttonSize / 2;
        
        // 修改约束 - 放在右下角
        [NSLayoutConstraint activateConstraints:@[
            [saveButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-15],
            [saveButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-15],
            [saveButton.widthAnchor constraintEqualToConstant:buttonSize],
            [saveButton.heightAnchor constraintEqualToConstant:buttonSize]
        ]];
        
        // 确保用户交互已启用
        saveButton.userInteractionEnabled = YES;
        
        // 添加点击事件
        [saveButton addTarget:self action:@selector(dyyy_saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // 标记已添加按钮
        objc_setAssociatedObject(self, &kHasSaveButtonKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    NSLog(@"dyyy url: %@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    [DYYYManager downloadMedia:url
                    mediaType:MediaTypeHeic
                   completion:^{
                       [DYYYManager showToast:@"表情包已保存到相册"];
                   }];
}

%end

%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}
