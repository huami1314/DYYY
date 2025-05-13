#import "AwemeHeaders.h"
#import "DYYYManager.h"
#import "DYYYToast.h"

%hook AWEPlayInteractionViewController

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
								      completion:^(BOOL success) {
								      }];
					      }
				      } else {
					      // 视频内容
					      if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
						      NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
						      [DYYYManager downloadMedia:url
								       mediaType:MediaTypeVideo
								      completion:^(BOOL success) {
								      }];
					      }
				      }
				    }];
			[actions addObject:downloadAction];

			// 添加保存封面选项
			if (!isImageContent) { // 仅视频内容显示保存封面选项
				AWEUserSheetAction *saveCoverAction = [NSClassFromString(@"AWEUserSheetAction")
				    actionWithTitle:@"保存封面"
					    imgName:nil
					    handler:^{
					      AWEVideoModel *videoModel = awemeModel.video;
					      if (videoModel && videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
						      NSURL *coverURL = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
						      [DYYYManager downloadMedia:coverURL
								       mediaType:MediaTypeImage
								      completion:^(BOOL success) {
								      }];
					      }
					    }];
				[actions addObject:saveCoverAction];
			}

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
														 [DYYYToast showSuccessToastWithMessage:@"文案已复制"];

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

		// 添加分享选项
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDoubleTapshowSharePanel"] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapshowSharePanel"]) {

			AWEUserSheetAction *showSharePanel = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"分享视频"
													       imgName:nil
													       handler:^{
														 [self showSharePanel]; // 执行分享操作
													       }];
			[actions addObject:showSharePanel];
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

%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}
