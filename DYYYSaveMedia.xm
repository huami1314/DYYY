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

%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}
