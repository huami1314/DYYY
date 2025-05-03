#import "AwemeHeaders.h"
#import "DYYYBottomAlertView.h"
#import "DYYYCustomInputView.h"
#import "DYYYFilterSettingsView.h"
#import "DYYYKeywordListView.h"
#import "DYYYManager.h"

%hook AWELongPressPanelViewGroupModel
%property(nonatomic, assign) BOOL isDYYYCustomGroup;
%end

// Modern风格长按面板（新版UI）
%hook AWEModernLongPressPanelTableViewController

- (NSArray *)dataArray {
	NSArray *originalArray = %orig;

	if (!originalArray) {
		originalArray = @[];
	}

	// 检查是否启用了任意长按功能
	BOOL hasAnyFeatureEnabled = NO;

	// 检查各个单独的功能开关
	BOOL enableSaveVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveVideo"];
	BOOL enableSaveCover = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveCover"];
	BOOL enableSaveAudio = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveAudio"];
	BOOL enableSaveCurrentImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveCurrentImage"];
	BOOL enableSaveAllImages = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveAllImages"];
	BOOL enableCopyText = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCopyText"];
	BOOL enableCopyLink = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCopyLink"];
	BOOL enableApiDownload = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressApiDownload"];
	BOOL enableFilterUser = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterUser"];
	BOOL enableFilterKeyword = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterTitle"];
	BOOL enableTimerClose = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressTimerClose"];

	// 兼容旧版设置
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"]) {
		if (!enableSaveVideo && !enableSaveCover && !enableSaveAudio && !enableSaveCurrentImage && !enableSaveAllImages) {
			enableSaveVideo = enableSaveCover = enableSaveAudio = enableSaveCurrentImage = enableSaveAllImages = YES;
		}
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		if (!enableCopyText && !enableCopyLink) {
			enableCopyText = enableCopyLink = YES;
		}
	}

	// 检查是否有任何功能启用
	hasAnyFeatureEnabled = enableSaveVideo || enableSaveCover || enableSaveAudio || enableSaveCurrentImage || enableSaveAllImages || enableCopyText || enableCopyLink || enableApiDownload ||
			       enableFilterUser || enableFilterKeyword || enableTimerClose;

	if (!hasAnyFeatureEnabled) {
		return originalArray;
	}

	NSMutableArray *viewModels = [NSMutableArray array];

	// 视频下载功能
	if (enableSaveVideo && self.awemeModel.awemeType != 68) {
		AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		downloadViewModel.awemeModel = self.awemeModel;
		downloadViewModel.actionType = 666;
		downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
		downloadViewModel.describeString = @"保存视频";

		downloadViewModel.action = ^{
		  AWEAwemeModel *awemeModel = self.awemeModel;
		  AWEVideoModel *videoModel = awemeModel.video;

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

	// 封面下载功能
	if (enableSaveCover && self.awemeModel.awemeType != 68) {
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

	// 音频下载功能
	if (enableSaveAudio) {
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
	}

	// 当前图片/实况下载功能
	if (enableSaveCurrentImage && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
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
		  if (currentImageModel.clipVideo != nil) {
			  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
			  NSURL *videoURL = [currentImageModel.clipVideo.playURL getDYYYSrcURLDownload];

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
	}

	// 保存所有图片/实况功能
	if (enableSaveAllImages && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 1) {
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

	// 复制文案功能
	if (enableCopyText) {
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
	}

	// 复制分享链接功能
	if (enableCopyLink) {
		AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyShareLink.awemeModel = self.awemeModel;
		copyShareLink.actionType = 672;
		copyShareLink.duxIconName = @"ic_share_outlined";
		copyShareLink.describeString = @"复制链接";

		copyShareLink.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  [[UIPasteboard generalPasteboard] setString:shareLink];
		  [DYYYManager showToast:@"分享链接已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyShareLink];
	}

	// 接口保存功能
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
	if (enableApiDownload && apiKey.length > 0) {
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

	if (enableTimerClose) {
		AWELongPressPanelBaseViewModel *timerCloseViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		timerCloseViewModel.awemeModel = self.awemeModel;
		timerCloseViewModel.actionType = 676;
		timerCloseViewModel.duxIconName = @"ic_c_alarm_outlined";

		// 检查是否已有定时任务在运行
		NSNumber *shutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
		BOOL hasActiveTimer = shutdownTime != nil && [shutdownTime doubleValue] > [[NSDate date] timeIntervalSince1970];

		timerCloseViewModel.describeString = hasActiveTimer ? @"取消定时" : @"定时关闭";

		timerCloseViewModel.action = ^{
		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];

		  NSNumber *shutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
		  BOOL hasActiveTimer = shutdownTime != nil && [shutdownTime doubleValue] > [[NSDate date] timeIntervalSince1970];

		  if (hasActiveTimer) {
			  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DYYYTimerShutdownTime"];
			  [[NSUserDefaults standardUserDefaults] synchronize];

			  [DYYYManager showToast:@"已取消定时关闭任务"];
			  return;
		  }

		  DYYYCustomInputView *inputView = [[DYYYCustomInputView alloc] initWithTitle:@"设置定时关闭时间" defaultText:@"5" placeholder:@"请输入关闭时间(单位:分钟)"];

		  inputView.onConfirm = ^(NSString *inputText) {
		    NSInteger minutes = [inputText integerValue];
            if (minutes <= 0) {
                minutes = 5;
            }
            NSInteger seconds = minutes * 60;

		    NSTimeInterval shutdownTimeValue = [[NSDate date] timeIntervalSince1970] + seconds;
		    [[NSUserDefaults standardUserDefaults] setObject:@(shutdownTimeValue) forKey:@"DYYYTimerShutdownTime"];
		    [[NSUserDefaults standardUserDefaults] synchronize];

		    [DYYYManager showToast:[NSString stringWithFormat:@"抖音将在%ld分钟后关闭...", (long)minutes]];
            
		    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		      NSNumber *currentShutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
		      if (currentShutdownTime != nil && [currentShutdownTime doubleValue] <= [[NSDate date] timeIntervalSince1970]) {
			      [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DYYYTimerShutdownTime"];
			      [[NSUserDefaults standardUserDefaults] synchronize];
			      exit(0);
		      }
		    });
		  };

		  [inputView show];
		};

		[viewModels addObject:timerCloseViewModel];
	}

	// 过滤用户功能
	if (enableFilterUser) {
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 674;
		filterKeywords.duxIconName = @"ic_userban_outlined_20";
		filterKeywords.describeString = @"过滤用户";

		filterKeywords.action = ^{
		  AWEUserModel *author = self.awemeModel.author;
		  NSString *nickname = author.nickname ?: @"未知用户";
		  NSString *shortId = author.shortID ?: @"";

		  // 创建当前用户的过滤格式 "nickname-shortid"
		  NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];

		  // 获取保存的过滤用户列表
		  NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterUsers"] ?: @"";
		  NSArray *userArray = [savedUsers length] > 0 ? [savedUsers componentsSeparatedByString:@","] : @[];

		  BOOL userExists = NO;
		  for (NSString *userInfo in userArray) {
			  NSArray *components = [userInfo componentsSeparatedByString:@"-"];
			  if (components.count >= 2) {
				  NSString *userId = [components lastObject];
				  if ([userId isEqualToString:shortId] && shortId.length > 0) {
					  userExists = YES;
					  break;
				  }
			  }
		  }
		  NSString *actionButtonText = userExists ? @"取消过滤" : @"添加过滤";

		  [DYYYBottomAlertView showAlertWithTitle:@"过滤用户视频"
		      message:[NSString stringWithFormat:@"用户: %@ (ID: %@)", nickname, shortId]
		      cancelButtonText:@"管理过滤列表"
		      confirmButtonText:actionButtonText
		      cancelAction:^{
			DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:userArray];
			keywordListView.onConfirm = ^(NSArray *users) {
			  NSString *userString = [users componentsJoinedByString:@","];
			  [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYfilterUsers"];
			  [[NSUserDefaults standardUserDefaults] synchronize];

			  [DYYYManager showToast:@"过滤用户列表已更新"];
			};

			[keywordListView show];
		      }
		      confirmAction:^{
			// 添加或移除用户过滤
			NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];

			if (userExists) {
				// 移除用户
				NSMutableArray *toRemove = [NSMutableArray array];
				for (NSString *userInfo in updatedUsers) {
					NSArray *components = [userInfo componentsSeparatedByString:@"-"];
					if (components.count >= 2) {
						NSString *userId = [components lastObject];
						if ([userId isEqualToString:shortId]) {
							[toRemove addObject:userInfo];
						}
					}
				}
				[updatedUsers removeObjectsInArray:toRemove];
				[DYYYManager showToast:@"已从过滤列表中移除此用户"];
			} else {
				// 添加用户
				[updatedUsers addObject:currentUserFilter];
				[DYYYManager showToast:@"已添加此用户到过滤列表"];
			}

			// 保存更新后的列表
			NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
			[[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYfilterUsers"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		      }];
		};

		[viewModels addObject:filterKeywords];
	}

	// 过滤文案功能
	if (enableFilterKeyword) {
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 675;
		filterKeywords.duxIconName = @"ic_funnel_outlined_20";
		filterKeywords.describeString = @"过滤文案";

		filterKeywords.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];

		  DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"过滤关键词调整" text:descText];
		  filterView.onConfirm = ^(NSString *selectedText) {
		    if (selectedText.length > 0) {
			    NSString *currentKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
			    NSString *newKeywords;

			    if (currentKeywords.length > 0) {
				    newKeywords = [NSString stringWithFormat:@"%@,%@", currentKeywords, selectedText];
			    } else {
				    newKeywords = selectedText;
			    }

			    [[NSUserDefaults standardUserDefaults] setObject:newKeywords forKey:@"DYYYfilterKeywords"];
			    [[NSUserDefaults standardUserDefaults] synchronize];
			    [DYYYManager showToast:[NSString stringWithFormat:@"已添加过滤词: %@", selectedText]];
		    }
		  };

		  filterView.onKeywordFilterTap = ^{
		    NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
		    NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
		    DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];

		    keywordListView.onConfirm = ^(NSArray *keywords) {
		      NSString *keywordString = [keywords componentsJoinedByString:@","];
		      [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYfilterKeywords"];
		      [[NSUserDefaults standardUserDefaults] synchronize];
		      [DYYYManager showToast:@"过滤关键词已更新"];
		    };
		    [keywordListView show];
		  };

		  [filterView show];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:filterKeywords];
	}

	NSMutableArray<AWELongPressPanelViewGroupModel *> *customGroups = [NSMutableArray array];
	NSInteger totalButtons = viewModels.count;
	// 根据按钮总数确定每行的按钮数
	NSInteger firstRowCount = 0;
	NSInteger secondRowCount = 0;

	if (totalButtons <= 2) {
		firstRowCount = totalButtons;
	} else if (totalButtons <= 4) {
		firstRowCount = totalButtons / 2;
		secondRowCount = totalButtons - firstRowCount;
	} else if (totalButtons <= 5) {
		firstRowCount = 3;
		secondRowCount = totalButtons - firstRowCount;
	} else if (totalButtons <= 6) {
		firstRowCount = 4;
		secondRowCount = totalButtons - firstRowCount;
	} else if (totalButtons <= 8) {
		firstRowCount = 4;
		secondRowCount = totalButtons - firstRowCount;
	} else {
		firstRowCount = 5;
		secondRowCount = totalButtons - firstRowCount;
	}

	// 创建第一行
	if (firstRowCount > 0) {
		NSArray<AWELongPressPanelBaseViewModel *> *firstRowButtons = [viewModels subarrayWithRange:NSMakeRange(0, firstRowCount)];

		AWELongPressPanelViewGroupModel *firstRowGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
		firstRowGroup.isDYYYCustomGroup = YES;
		firstRowGroup.groupType = (firstRowCount <= 3) ? 11 : 12;
		firstRowGroup.isModern = YES;
		firstRowGroup.groupArr = firstRowButtons;
		[customGroups addObject:firstRowGroup];
	}

	// 创建第二行
	if (secondRowCount > 0) {
		NSArray<AWELongPressPanelBaseViewModel *> *secondRowButtons = [viewModels subarrayWithRange:NSMakeRange(firstRowCount, secondRowCount)];

		AWELongPressPanelViewGroupModel *secondRowGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
		secondRowGroup.isDYYYCustomGroup = YES;
		secondRowGroup.groupType = (secondRowCount <= 3) ? 11 : 12;
		secondRowGroup.isModern = YES;
		secondRowGroup.groupArr = secondRowButtons;
		[customGroups addObject:secondRowGroup];
	}

	// 处理日常转发按钮
	if (originalArray.count > 0 && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelDaily"]) {
		NSMutableArray *modifiedArray = [originalArray mutableCopy];
		AWELongPressPanelViewGroupModel *firstGroup = modifiedArray[0];
		if (firstGroup.groupArr.count > 1) {
			NSMutableArray *groupArray = [firstGroup.groupArr mutableCopy];
			if ([[groupArray[1] valueForKey:@"describeString"] isEqualToString:@"转发到日常"]) {
				[groupArray removeObjectAtIndex:1];
			}
			firstGroup.groupArr = groupArray;
			modifiedArray[0] = firstGroup;
		}
		originalArray = modifiedArray;
	}

	return [customGroups arrayByAddingObjectsFromArray:originalArray];
}
%end

// 修复Modern风格长按面板水平设置单元格的大小计算
%hook AWEModernLongPressHorizontalSettingCell

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.longPressViewGroupModel && [self.longPressViewGroupModel isDYYYCustomGroup]) {
		if (self.dataArray && indexPath.item < self.dataArray.count) {
			CGFloat totalWidth = collectionView.bounds.size.width;
			NSInteger itemCount = self.dataArray.count;
			CGFloat itemWidth = totalWidth / itemCount;
			return CGSizeMake(itemWidth, 73);
		}
		return CGSizeMake(73, 73);
	}

	return %orig;
}

%end

// 修复Modern风格长按面板交互单元格的大小计算
%hook AWEModernLongPressInteractiveCell

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.longPressViewGroupModel && [self.longPressViewGroupModel isDYYYCustomGroup]) {
		if (self.dataArray && indexPath.item < self.dataArray.count) {
			NSInteger itemCount = self.dataArray.count;
			CGFloat totalWidth = collectionView.bounds.size.width - 12 * (itemCount - 1);
			CGFloat itemWidth = totalWidth / itemCount;
			return CGSizeMake(itemWidth, 73);
		}
		return CGSizeMake(73, 73);
	}

	return %orig;
}

%end

// 经典风格长按面板
%hook AWELongPressPanelTableViewController

- (NSArray *)dataArray {
	NSArray *originalArray = %orig;

	if (!originalArray) {
		originalArray = @[];
	}

	// 检查是否启用了任意长按功能
	BOOL hasAnyFeatureEnabled = NO;

	// 检查各个单独的功能开关
	BOOL enableSaveVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveVideo"];
	BOOL enableSaveCover = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveCover"];
	BOOL enableSaveAudio = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveAudio"];
	BOOL enableSaveCurrentImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveCurrentImage"];
	BOOL enableSaveAllImages = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveAllImages"];
	BOOL enableCopyText = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCopyText"];
	BOOL enableCopyLink = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCopyLink"];
	BOOL enableApiDownload = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressApiDownload"];
	BOOL enableFilterUser = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterUser"];
	BOOL enableFilterKeyword = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterTitle"];

	// 兼容旧版设置
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"]) {
		if (!enableSaveVideo && !enableSaveCover && !enableSaveAudio && !enableSaveCurrentImage && !enableSaveAllImages) {
			enableSaveVideo = enableSaveCover = enableSaveAudio = enableSaveCurrentImage = enableSaveAllImages = YES;
		}
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		if (!enableCopyText && !enableCopyLink) {
			enableCopyText = enableCopyLink = YES;
		}
	}

	// 检查是否有任何功能启用
	hasAnyFeatureEnabled = enableSaveVideo || enableSaveCover || enableSaveAudio || enableSaveCurrentImage || enableSaveAllImages || enableCopyText || enableCopyLink || enableApiDownload ||
			       enableFilterUser || enableFilterKeyword;

	if (!hasAnyFeatureEnabled) {
		return originalArray;
	}

	AWELongPressPanelViewGroupModel *newGroupModel = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
	newGroupModel.groupType = 0;

	NSMutableArray *viewModels = [NSMutableArray array];

	// 视频下载功能
	if (enableSaveVideo && self.awemeModel.awemeType != 68) {
		AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		downloadViewModel.awemeModel = self.awemeModel;
		downloadViewModel.actionType = 666;
		downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
		downloadViewModel.describeString = @"保存视频";

		downloadViewModel.action = ^{
		  AWEAwemeModel *awemeModel = self.awemeModel;
		  AWEVideoModel *videoModel = awemeModel.video;

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

	// 封面下载功能
	if (enableSaveCover && self.awemeModel.awemeType != 68) {
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

	// 音频下载功能
	if (enableSaveAudio) {
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
	}

	// 当前图片/实况下载功能
	if (enableSaveCurrentImage && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
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
		  if (currentImageModel.clipVideo != nil) {
			  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
			  NSURL *videoURL = [currentImageModel.clipVideo.playURL getDYYYSrcURLDownload];

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
	}

	// 保存所有图片/实况功能
	if (enableSaveAllImages && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 1) {
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

	// 接口保存功能
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
	if (enableApiDownload && apiKey.length > 0) {
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

	if (enableTimerClose) {
		AWELongPressPanelBaseViewModel *timerCloseViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		timerCloseViewModel.awemeModel = self.awemeModel;
		timerCloseViewModel.actionType = 676;
		timerCloseViewModel.duxIconName = @"ic_c_alarm_outlined";

		// 检查是否已有定时任务在运行
		NSNumber *shutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
		BOOL hasActiveTimer = shutdownTime != nil && [shutdownTime doubleValue] > [[NSDate date] timeIntervalSince1970];

		timerCloseViewModel.describeString = hasActiveTimer ? @"取消定时" : @"定时关闭";

		timerCloseViewModel.action = ^{
		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];

		  NSNumber *shutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
		  BOOL hasActiveTimer = shutdownTime != nil && [shutdownTime doubleValue] > [[NSDate date] timeIntervalSince1970];

		  if (hasActiveTimer) {
			  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DYYYTimerShutdownTime"];
			  [[NSUserDefaults standardUserDefaults] synchronize];

			  [DYYYManager showToast:@"已取消定时关闭任务"];
			  return;
		  }

		  DYYYCustomInputView *inputView = [[DYYYCustomInputView alloc] initWithTitle:@"设置定时关闭时间" defaultText:@"5" placeholder:@"请输入关闭时间(单位:分钟)"];

		  inputView.onConfirm = ^(NSString *inputText) {
		    NSInteger minutes = [inputText integerValue];
            if (minutes <= 0) {
                minutes = 5;
            }
            NSInteger seconds = minutes * 60;

		    NSTimeInterval shutdownTimeValue = [[NSDate date] timeIntervalSince1970] + seconds;
		    [[NSUserDefaults standardUserDefaults] setObject:@(shutdownTimeValue) forKey:@"DYYYTimerShutdownTime"];
		    [[NSUserDefaults standardUserDefaults] synchronize];

		    [DYYYManager showToast:[NSString stringWithFormat:@"抖音将在%ld分钟后关闭...", (long)minutes]];
            
		    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		      NSNumber *currentShutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
		      if (currentShutdownTime != nil && [currentShutdownTime doubleValue] <= [[NSDate date] timeIntervalSince1970]) {
			      [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DYYYTimerShutdownTime"];
			      [[NSUserDefaults standardUserDefaults] synchronize];
			      exit(0);
		      }
		    });
		  };

		  [inputView show];
		};

		[viewModels addObject:timerCloseViewModel];
	}

	// 复制文案功能
	if (enableCopyText) {
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
	}

	// 复制分享链接功能
	if (enableCopyLink) {
		AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyShareLink.awemeModel = self.awemeModel;
		copyShareLink.actionType = 672;
		copyShareLink.duxIconName = @"ic_share_outlined";
		copyShareLink.describeString = @"复制链接";

		copyShareLink.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  [[UIPasteboard generalPasteboard] setString:shareLink];
		  [DYYYManager showToast:@"分享链接已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyShareLink];
	}

	// 过滤用户功能
	if (enableFilterUser) {
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 674;
		filterKeywords.duxIconName = @"ic_userban_outlined_20";
		filterKeywords.describeString = @"过滤用户";

		filterKeywords.action = ^{
		  // 获取当前视频作者信息
		  AWEUserModel *author = self.awemeModel.author;
		  NSString *nickname = author.nickname ?: @"未知用户";
		  NSString *shortId = author.shortID ?: @"";

		  // 创建当前用户的过滤格式 "nickname-shortid"
		  NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];

		  // 获取保存的过滤用户列表
		  NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterUsers"] ?: @"";
		  NSArray *userArray = [savedUsers length] > 0 ? [savedUsers componentsSeparatedByString:@","] : @[];

		  // 检查当前用户是否已在过滤列表中
		  BOOL userExists = NO;
		  for (NSString *userInfo in userArray) {
			  NSArray *components = [userInfo componentsSeparatedByString:@"-"];
			  if (components.count >= 2) {
				  NSString *userId = [components lastObject];
				  if ([userId isEqualToString:shortId] && shortId.length > 0) {
					  userExists = YES;
					  break;
				  }
			  }
		  }
		  NSString *actionButtonText = userExists ? @"取消过滤" : @"添加过滤";

		  [DYYYBottomAlertView showAlertWithTitle:@"过滤用户视频"
		      message:[NSString stringWithFormat:@"用户: %@ (ID: %@)", nickname, shortId]
		      cancelButtonText:@"管理过滤列表"
		      confirmButtonText:actionButtonText
		      cancelAction:^{
			// 创建并显示关键词列表视图
			DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:userArray];
			// 设置确认回调
			keywordListView.onConfirm = ^(NSArray *users) {
			  // 将用户数组转换为逗号分隔的字符串
			  NSString *userString = [users componentsJoinedByString:@","];

			  // 保存到用户默认设置
			  [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYfilterUsers"];
			  [[NSUserDefaults standardUserDefaults] synchronize];

			  // 显示提示
			  [DYYYManager showToast:@"过滤用户列表已更新"];
			};

			[keywordListView show];
		      }
		      confirmAction:^{
			// 添加或移除用户过滤
			NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];

			if (userExists) {
				// 移除用户
				NSMutableArray *toRemove = [NSMutableArray array];
				for (NSString *userInfo in updatedUsers) {
					NSArray *components = [userInfo componentsSeparatedByString:@"-"];
					if (components.count >= 2) {
						NSString *userId = [components lastObject];
						if ([userId isEqualToString:shortId]) {
							[toRemove addObject:userInfo];
						}
					}
				}
				[updatedUsers removeObjectsInArray:toRemove];
				[DYYYManager showToast:@"已从过滤列表中移除此用户"];
			} else {
				// 添加用户
				[updatedUsers addObject:currentUserFilter];
				[DYYYManager showToast:@"已添加此用户到过滤列表"];
			}

			// 保存更新后的列表
			NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
			[[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYfilterUsers"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		      }];
		};

		[viewModels addObject:filterKeywords];
	}

	// 过滤文案功能
	if (enableFilterKeyword) {
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 675;
		filterKeywords.duxIconName = @"ic_funnel_outlined_20";
		filterKeywords.describeString = @"过滤文案";

		filterKeywords.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];

		  DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"过滤关键词调整" text:descText];
		  filterView.onConfirm = ^(NSString *selectedText) {
		    if (selectedText.length > 0) {
			    NSString *currentKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
			    NSString *newKeywords;

			    if (currentKeywords.length > 0) {
				    newKeywords = [NSString stringWithFormat:@"%@,%@", currentKeywords, selectedText];
			    } else {
				    newKeywords = selectedText;
			    }

			    [[NSUserDefaults standardUserDefaults] setObject:newKeywords forKey:@"DYYYfilterKeywords"];
			    [[NSUserDefaults standardUserDefaults] synchronize];
			    [DYYYManager showToast:[NSString stringWithFormat:@"已添加过滤词: %@", selectedText]];
		    }
		  };

		  // 设置过滤关键词按钮回调
		  filterView.onKeywordFilterTap = ^{
		    // 获取保存的关键词
		    NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
		    NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];

		    // 创建并显示关键词列表视图
		    DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];

		    // 设置确认回调
		    keywordListView.onConfirm = ^(NSArray *keywords) {
		      // 将关键词数组转换为逗号分隔的字符串
		      NSString *keywordString = [keywords componentsJoinedByString:@","];

		      // 保存到用户默认设置
		      [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYfilterKeywords"];
		      [[NSUserDefaults standardUserDefaults] synchronize];

		      // 显示提示
		      [DYYYManager showToast:@"过滤关键词已更新"];
		    };

		    // 显示关键词列表视图
		    [keywordListView show];
		  };

		  [filterView show];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:filterKeywords];
	}

	newGroupModel.groupArr = viewModels;

	if (originalArray.count > 0) {
		NSMutableArray *resultArray = [originalArray mutableCopy];
		[resultArray insertObject:newGroupModel atIndex:1];
		return [resultArray copy];
	} else {
		return @[ newGroupModel ];
	}
}

%end

// 初始化钩子
%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}
