#import <sys/stat.h>
#import "DYYYAudioManager.h"
#import "AwemeHeaders.h"
#import "DYYYBottomAlertView.h"
#import "DYYYConfirmCloseView.h"
#import "DYYYCustomInputView.h"
#import "DYYYFilterSettingsView.h"
#import "DYYYKeywordListView.h"
#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"
#import "DYYYVoiceViewController.h"
#import <AVFoundation/AVFoundation.h>

// ==========================================
// 完美声明区
// ==========================================
@interface DYYYManager (Download)
+ (void)downloadMediaWithProgress:(NSURL *)url mediaType:(NSInteger)mediaType audio:(NSURL *)audioURL progress:(void (^)(float progress))progressBlock completion:(void (^)(BOOL success, NSURL *fileURL))completion;
@end
// ==========================================

%hook AWELongPressPanelViewGroupModel
%property(nonatomic, assign) BOOL isDYYYCustomGroup;
%end

// ==========================================
// Modern风格长按面板（新版UI）
// ==========================================
%hook AWEModernLongPressPanelTableViewController
- (NSArray *)dataArray {
    NSArray *originalArray = %orig;
    if (!originalArray) {
        originalArray = @[];
    }

    BOOL hasAnyFeatureEnabled = NO;
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
    BOOL enableCreateVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCreateVideo"];
    BOOL enableVoiceFavorites = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressVoiceFavorites"];

    hasAnyFeatureEnabled = enableSaveVideo || enableSaveCover || enableSaveAudio || enableSaveCurrentImage || enableSaveAllImages || enableCopyText || enableCopyLink || enableApiDownload ||
                           enableFilterUser || enableFilterKeyword || enableTimerClose || enableCreateVideo || enableVoiceFavorites;

    BOOL hideDaily = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelDaily"];
    BOOL hideRecommend = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelRecommend"];
    BOOL hideNotInterested = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelNotInterested"];
    BOOL hideReport = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelReport"];
    BOOL hideSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSpeed"];
    BOOL hideClearScreen = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelClearScreen"];
    BOOL hideFavorite = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelFavorite"];
    BOOL hideLater = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelLater"];
    BOOL hideCast = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelCast"];
    BOOL hideOpenInPC = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelOpenInPC"];
    BOOL hideSubtitle = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSubtitle"];
    BOOL hideAutoPlay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelAutoPlay"];
    BOOL hideSearchImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSearchImage"];
    BOOL hideListenDouyin = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelListenDouyin"];
    BOOL hideBackgroundPlay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelBackgroundPlay"];
    BOOL hideBiserial = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelBiserial"];
    BOOL hideTimerclose = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelTimerClose"];

    NSMutableArray *modifiedOriginalGroups = [NSMutableArray array];

    for (id group in originalArray) {
        if ([group isKindOfClass:%c(AWELongPressPanelViewGroupModel)]) {
            AWELongPressPanelViewGroupModel *groupModel = (AWELongPressPanelViewGroupModel *)group;
            NSMutableArray *filteredGroupArr = [NSMutableArray array];

            for (id item in groupModel.groupArr) {
                if ([item isKindOfClass:%c(AWELongPressPanelBaseViewModel)]) {
                    AWELongPressPanelBaseViewModel *viewModel = (AWELongPressPanelBaseViewModel *)item;
                    NSString *descString = viewModel.describeString;
                    BOOL shouldHide = NO;
                    if (([descString isEqualToString:@"转发到日常"] || [descString isEqualToString:@"分享到日常"]) && hideDaily) {
                        shouldHide = YES;
                    } else if (([descString isEqualToString:@"推荐"] || [descString isEqualToString:@"取消推荐"]) && hideRecommend) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"不感兴趣"] && hideNotInterested) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"举报"] && hideReport) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"倍速"] && hideSpeed) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"清屏播放"] && hideClearScreen) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"缓存视频"] && hideFavorite) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"添加至稍后再看"] && hideLater) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"投屏"] && hideCast) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"电脑/Pad打开"] && hideOpenInPC) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕开关"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕设置"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"自动连播"] && hideAutoPlay) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"识别图片"] && hideSearchImage) {
                        shouldHide = YES;
                    } else if (([descString isEqualToString:@"听抖音"] || [descString isEqualToString:@"后台听"] || [descString isEqualToString:@"听视频"]) && hideListenDouyin) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"后台播放设置"] && hideBackgroundPlay) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"首页双列快捷入口"] && hideBiserial) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"定时关闭"] && hideTimerclose) {
                        shouldHide = YES;
                    }

                    if (!shouldHide) {
                        [filteredGroupArr addObject:viewModel];
                    }
                }
            }

            if (filteredGroupArr.count > 0) {
                AWELongPressPanelViewGroupModel *newGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
                newGroup.isDYYYCustomGroup = YES;
                newGroup.groupType = groupModel.groupType;
                newGroup.isModern = YES;
                newGroup.groupArr = filteredGroupArr;
                [modifiedOriginalGroups addObject:newGroup];
            }
        }
    }

    if (!hasAnyFeatureEnabled) {
        return modifiedOriginalGroups;
    }

    NSMutableArray *viewModels = [NSMutableArray array];
    BOOL isNewLivePhoto = (self.awemeModel.video && self.awemeModel.animatedImageVideoInfo != nil);

    if (enableSaveVideo && self.awemeModel.awemeType != 68 && !isNewLivePhoto) {
        AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        downloadViewModel.awemeModel = self.awemeModel;
        downloadViewModel.actionType = 666;
        downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        downloadViewModel.describeString = @"保存视频";
        downloadViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id videoModel = awemeModel.video;
            id musicModel = awemeModel.music;
            NSURL *audioURL = nil;
            
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        audioURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }

            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"h264URL")]) {
                id h264URL = [videoModel performSelector:NSSelectorFromString(@"h264URL")];
                if (h264URL && [h264URL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [h264URL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeVideo audio:audioURL completion:nil];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:downloadViewModel];
    }

    if (enableSaveVideo && self.awemeModel.awemeType != 68 && isNewLivePhoto) {
        AWELongPressPanelBaseViewModel *livePhotoViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        livePhotoViewModel.awemeModel = self.awemeModel;
        livePhotoViewModel.actionType = 679;
        livePhotoViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        livePhotoViewModel.describeString = @"保存实况";
        livePhotoViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id videoModel = awemeModel.video;

            NSURL *imageURL = nil;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"coverURL")]) {
                id coverURL = [videoModel performSelector:NSSelectorFromString(@"coverURL")];
                if (coverURL && [coverURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [coverURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        imageURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }

            NSURL *videoURL = nil;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [videoModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        videoURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            } else if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"h264URL")]) {
                id h264URL = [videoModel performSelector:NSSelectorFromString(@"h264URL")];
                if (h264URL && [h264URL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [h264URL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        videoURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }

            if (imageURL && videoURL) {
                [DYYYManager downloadLivePhoto:imageURL videoURL:videoURL completion:nil];
            }

            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:livePhotoViewModel];
    }

    if (enableSaveCurrentImage && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
        AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        imageViewModel.awemeModel = self.awemeModel;
        imageViewModel.actionType = 669;
        imageViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";

        if (self.awemeModel.albumImages.count == 1) {
            imageViewModel.describeString = @"保存图片";
        } else {
            imageViewModel.describeString = @"保存当前图片";
        }

        AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
        if (currimge.clipVideo != nil || self.awemeModel.isLivePhoto) {
            if (self.awemeModel.albumImages.count == 1) {
                imageViewModel.describeString = @"保存实况";
            } else {
                imageViewModel.describeString = @"保存当前实况";
            }
        }
        imageViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEImageAlbumImageModel *currentImageModel = nil;
            if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
            } else {
                currentImageModel = awemeModel.albumImages.firstObject;
            }

            NSURL *downloadURL = nil;
            for (NSString *urlString in currentImageModel.urlList) {
                NSURL *url = [NSURL URLWithString:urlString];
                NSString *pathExtension = [url.path.lowercaseString pathExtension];
                if (![pathExtension isEqualToString:@"image"]) {
                    downloadURL = url;
                    break;
                }
            }

            if (currentImageModel.clipVideo != nil) {
                NSURL *videoURL = [currentImageModel.clipVideo.playURL getDYYYSrcURLDownload];
                [DYYYManager downloadLivePhoto:downloadURL videoURL:videoURL completion:nil];
            } else if (currentImageModel && currentImageModel.urlList.count > 0) {
                if (downloadURL) {
                    [DYYYManager downloadMedia:downloadURL mediaType:MediaTypeImage audio:nil completion:^(BOOL success) {
                        if (!success) {
                            [DYYYUtils showToast:@"图片保存已取消"];
                        }
                    }];
                } else {
                    [DYYYUtils showToast:@"没有找到合适格式的图片"];
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:imageViewModel];
    }

    if (enableSaveAllImages && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 1) {
        AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        allImagesViewModel.awemeModel = self.awemeModel;
        allImagesViewModel.actionType = 670;
        allImagesViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        allImagesViewModel.describeString = @"保存所有图片";
        
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
            NSMutableArray *livePhotos = [NSMutableArray array];

            for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                if (imageModel.urlList.count > 0) {
                    NSURL *downloadURL = nil;
                    for (NSString *urlString in imageModel.urlList) {
                        NSURL *url = [NSURL URLWithString:urlString];
                        NSString *pathExtension = [url.path.lowercaseString pathExtension];
                        if (![pathExtension isEqualToString:@"image"]) {
                            downloadURL = url;
                            break;
                        }
                    }
                    if (!downloadURL && imageModel.urlList.count > 0) {
                        downloadURL = [NSURL URLWithString:imageModel.urlList.firstObject];
                    }

                    if (imageModel.clipVideo != nil) {
                        NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                        [livePhotos addObject:@{@"imageURL" : downloadURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
                    } else {
                        [imageURLs addObject:downloadURL.absoluteString];
                    }
                }
            }

            if (livePhotos.count > 0) {
                [DYYYManager downloadAllLivePhotos:livePhotos];
            }
            if (imageURLs.count > 0) {
                [DYYYManager downloadAllImages:imageURLs];
            }
            if (livePhotos.count == 0 && imageURLs.count == 0) {
                [DYYYUtils showToast:@"没有找到合适格式的图片"];
            }

            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:allImagesViewModel];
    }

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
                [DYYYUtils showToast:@"无法获取分享链接"];
                return;
            }
            [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:apiDownload];
    }

    if (enableSaveCover && self.awemeModel.awemeType != 68) {
        AWELongPressPanelBaseViewModel *coverViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        coverViewModel.awemeModel = self.awemeModel;
        coverViewModel.actionType = 667;
        coverViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        coverViewModel.describeString = @"保存封面";
        coverViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id videoModel = awemeModel.video;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"coverURL")]) {
                id coverURL = [videoModel performSelector:NSSelectorFromString(@"coverURL")];
                if (coverURL && [coverURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [coverURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeImage audio:nil completion:^(BOOL success) {
                            if (!success) {
                                [DYYYUtils showToast:@"封面保存已取消"];
                            }
                        }];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:coverViewModel];
    }

    if (enableSaveAudio) {
        AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        audioViewModel.awemeModel = self.awemeModel;
        audioViewModel.actionType = 668;
        audioViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        audioViewModel.describeString = @"保存音频";
        audioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id musicModel = awemeModel.music;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeAudio audio:nil completion:nil];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:audioViewModel];
    }

    if (enableVoiceFavorites) {
        AWELongPressPanelBaseViewModel *voiceViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        voiceViewModel.awemeModel = self.awemeModel;
        voiceViewModel.actionType = 680;
        voiceViewModel.duxIconName = @"ic_phonearrowup_outlined_20"; 
        voiceViewModel.describeString = @"音频助手";
        voiceViewModel.action = ^{
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:^{
                UIViewController *topVC = [DYYYUtils topView];
                if (!topVC) return;
                Class VoiceVCClass = NSClassFromString(@"DYYYVoiceViewController");
                if (VoiceVCClass) {
                    UIViewController *voiceVC = [[VoiceVCClass alloc] init];
                    voiceVC.modalPresentationStyle = UIModalPresentationPageSheet;
                    [topVC presentViewController:voiceVC animated:YES completion:nil];
                }
            }];
        };
        [viewModels addObject:voiceViewModel];
    }

    if (enableVoiceFavorites) {
        AWELongPressPanelBaseViewModel *favAudioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        favAudioViewModel.awemeModel = self.awemeModel;
        favAudioViewModel.actionType = 681; 
        favAudioViewModel.duxIconName = @"ic_star_outlined_20"; 
        favAudioViewModel.describeString = @"音频入库";
        favAudioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id musicModel = awemeModel.music;
            id videoModel = awemeModel.video;
            NSString *audioUrlString = nil;
            
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if ([originList isKindOfClass:[NSArray class]] && originList.count > 0) {
                        audioUrlString = originList.firstObject;
                    }
                }
            } else if (videoModel) {
                id downloadURL = nil;
                if ([videoModel respondsToSelector:NSSelectorFromString(@"downloadURL")]) {
                    downloadURL = [videoModel performSelector:NSSelectorFromString(@"downloadURL")];
                } else if ([videoModel respondsToSelector:NSSelectorFromString(@"playAddr")]) {
                    downloadURL = [videoModel performSelector:NSSelectorFromString(@"playAddr")];
                }
                if (downloadURL && [downloadURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [downloadURL performSelector:NSSelectorFromString(@"originURLList")];
                    if ([originList isKindOfClass:[NSArray class]] && originList.count > 0) {
                        audioUrlString = originList.firstObject;
                    }
                }
            }
            
            if (audioUrlString && audioUrlString.length > 0) {
                NSString *videoTitle = [awemeModel valueForKey:@"descriptionString"];
                if (!videoTitle || videoTitle.length == 0) {
                    videoTitle = [NSString stringWithFormat:@"提取音频_%ld", (long)[[NSDate date] timeIntervalSince1970]];
                } else {
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@" " withString:@""]; 
                    if (videoTitle.length > 20) {
                        videoTitle = [videoTitle substringToIndex:20];
                    }
                }
                NSString *fileName = videoTitle;
                NSURL *downloadUrl = [NSURL URLWithString:audioUrlString];
                
                [DYYYManager downloadMediaWithProgress:downloadUrl 
                                             mediaType:MediaTypeAudio
                                                 audio:nil 
                                              progress:nil 
                                            completion:^(BOOL success, NSURL *fileURL) {
                    if (success && fileURL) {
                        NSString *targetDir = [[DYYYAudioManager sharedManager] voiceDirectory];
                        NSString *safeFileName = [fileName stringByAppendingPathExtension:@"m4a"];
                        NSString *targetPath = [targetDir stringByAppendingPathComponent:safeFileName];
                        
                        if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
                            [[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
                        }
                        [[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:[NSURL fileURLWithPath:targetPath] error:nil];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [DYYYUtils showToast:@"❌ 下载失败：版权限制或网络错误"];
                        });
                    }
                }];
            } else {
                [DYYYUtils showToast:@"⚠️ 此视频无法提取声音"];
            }
            
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:favAudioViewModel];
    }

    if (enableCreateVideo && self.awemeModel.awemeType == 68) {
        AWELongPressPanelBaseViewModel *createVideoViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        createVideoViewModel.awemeModel = self.awemeModel;
        createVideoViewModel.actionType = 677;
        createVideoViewModel.duxIconName = @"ic_videosearch_outlined_20";
        createVideoViewModel.describeString = @"制作视频";
        createVideoViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            NSMutableArray *imageURLs = [NSMutableArray array];
            NSMutableArray *livePhotos = [NSMutableArray array];
            NSString *bgmURL = nil;
            id musicModel = awemeModel.music;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        bgmURL = originList.firstObject;
                    }
                }
            }

            for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                if (imageModel.urlList.count > 0) {
                    NSString *bestURL = nil;
                    for (NSString *urlString in imageModel.urlList) {
                        NSURL *url = [NSURL URLWithString:urlString];
                        NSString *pathExtension = [url.path.lowercaseString pathExtension];
                        if (![pathExtension isEqualToString:@"image"]) {
                            bestURL = urlString;
                            break;
                        }
                    }
                    if (!bestURL && imageModel.urlList.count > 0) {
                        bestURL = imageModel.urlList.firstObject;
                    }
                    if (imageModel.clipVideo != nil) {
                        NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                        if (videoURL) {
                            [livePhotos addObject:@{@"imageURL" : bestURL, @"videoURL" : videoURL.absoluteString}];
                        }
                    } else {
                        [imageURLs addObject:bestURL];
                    }
                }
            }

            [DYYYManager createVideoFromMedia:imageURLs livePhotos:livePhotos bgmURL:bgmURL progress:nil completion:^(BOOL success, NSString *message) {
                if (!success) {
                    [DYYYUtils showToast:[NSString stringWithFormat:@"视频制作失败: %@", message]];
                }
            }];

            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:createVideoViewModel];
    }

    if (enableCopyText) {
        AWELongPressPanelBaseViewModel *copyText = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        copyText.awemeModel = self.awemeModel;
        copyText.actionType = 671;
        copyText.duxIconName = @"ic_xiaoxihuazhonghua_outlined";
        copyText.describeString = @"复制文案";
        copyText.action = ^{
            NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
            [[UIPasteboard generalPasteboard] setString:descText];
            [DYYYToast showSuccessToastWithMessage:@"文案已复制"];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:copyText];
    }

    if (enableCopyLink) {
        AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        copyShareLink.awemeModel = self.awemeModel;
        copyShareLink.actionType = 672;
        copyShareLink.duxIconName = @"ic_share_outlined";
        copyShareLink.describeString = @"复制链接";
        copyShareLink.action = ^{
            NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
            NSString *cleanedURL = cleanShareURL(shareLink);
            [[UIPasteboard generalPasteboard] setString:cleanedURL];
            [DYYYToast showSuccessToastWithMessage:@"分享链接已复制"];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:copyShareLink];
    }

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
            NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];
            NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterUsers"] ?: @"";
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
            [DYYYBottomAlertView showAlertWithTitle:@"过滤用户视频" message:[NSString stringWithFormat:@"用户: %@ (ID: %@)", nickname, shortId] avatarURL:nil cancelButtonText:@"管理过滤列表" confirmButtonText:actionButtonText cancelAction:^{
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:userArray];
                keywordListView.onConfirm = ^(NSArray *users) {
                    NSString *userString = [users componentsJoinedByString:@","];
                    [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYFilterUsers"];
                    [DYYYUtils showToast:@"过滤用户列表已更新"];
                };
                [keywordListView show];
            } closeAction:nil confirmAction:^{
                NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];
                if (userExists) {
                    NSMutableArray *toRemove = [NSMutableArray array];
                    for (NSString *userInfo in updatedUsers) {
                        NSArray *components = [userInfo componentsSeparatedByString:@"-"];
                        if (components.count >= 2 && [[components lastObject] isEqualToString:shortId]) {
                            [toRemove addObject:userInfo];
                        }
                    }
                    [updatedUsers removeObjectsInArray:toRemove];
                    [DYYYUtils showToast:@"已从过滤列表中移除此用户"];
                } else {
                    [updatedUsers addObject:currentUserFilter];
                    [DYYYUtils showToast:@"已添加此用户到过滤列表"];
                }
                NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
                [[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYFilterUsers"];
            }];
        };
        [viewModels addObject:filterKeywords];
    }

    if (enableFilterKeyword) {
        AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        filterKeywords.awemeModel = self.awemeModel;
        filterKeywords.actionType = 675;
        filterKeywords.duxIconName = @"ic_funnel_outlined_20";
        filterKeywords.describeString = @"过滤文案";
        filterKeywords.action = ^{
            NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
            NSString *propName = nil;
            if (self.awemeModel.propGuideV2) {
                propName = self.awemeModel.propGuideV2.propName;
            }
            DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"过滤关键词调整" text:descText propName:propName];
            filterView.onConfirm = ^(NSString *selectedText) {
                if (selectedText.length > 0) {
                    NSString *currentKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                    NSString *newKeywords = currentKeywords.length > 0 ? [NSString stringWithFormat:@"%@,%@", currentKeywords, selectedText] : selectedText;
                    [[NSUserDefaults standardUserDefaults] setObject:newKeywords forKey:@"DYYYFilterKeywords"];
                    [DYYYUtils showToast:[NSString stringWithFormat:@"已添加过滤词: %@", selectedText]];
                }
            };
            filterView.onKeywordFilterTap = ^{
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];
                keywordListView.onConfirm = ^(NSArray *keywords) {
                    NSString *keywordString = [keywords componentsJoinedByString:@","];
                    [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYFilterKeywords"];
                    [DYYYUtils showToast:@"过滤关键词已更新"];
                };
                [keywordListView show];
            };
            [filterView show];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:filterKeywords];
    }

    if (enableTimerClose) {
        AWELongPressPanelBaseViewModel *timerCloseViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        timerCloseViewModel.awemeModel = self.awemeModel;
        timerCloseViewModel.actionType = 676;
        timerCloseViewModel.duxIconName = @"ic_alarm_outlined";
        
        NSNumber *shutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
        BOOL hasActiveTimer = shutdownTime != nil && [shutdownTime doubleValue] > [[NSDate date] timeIntervalSince1970];
        timerCloseViewModel.describeString = hasActiveTimer ? @"取消定时" : @"定时关闭";
        
        timerCloseViewModel.action = ^{
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:timerCloseViewModel];
    }

    NSMutableArray *customGroups = [NSMutableArray array];
    NSInteger totalButtons = viewModels.count;
    NSInteger buttonsPerRow = 5; 
    
    for (NSInteger i = 0; i < totalButtons; i += buttonsPerRow) {
        NSInteger length = MIN(buttonsPerRow, totalButtons - i);
        NSArray<AWELongPressPanelBaseViewModel *> *rowButtons = [viewModels subarrayWithRange:NSMakeRange(i, length)];
        
        AWELongPressPanelViewGroupModel *rowGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
        rowGroup.isDYYYCustomGroup = YES;
        rowGroup.groupType = (length <= 3) ? 11 : 12;
        rowGroup.isModern = YES;
        rowGroup.groupArr = rowButtons;
        
        [customGroups addObject:rowGroup];
    }

    NSMutableArray *resultArray = [NSMutableArray arrayWithArray:customGroups];
    [resultArray addObjectsFromArray:modifiedOriginalGroups];
    return resultArray;
}
%end

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

// ==========================================
// 经典风格长按面板 (旧版UI)
// ==========================================
%hook AWELongPressPanelTableViewController
- (NSArray *)dataArray {
    NSArray *originalArray = %orig;
    if (!originalArray) {
        originalArray = @[];
    }
    if (!self.awemeModel.author.nickname) {
        return originalArray;
    }

    BOOL hasAnyFeatureEnabled = NO;
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
    BOOL enableCreateVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCreateVideo"];
    BOOL enableVoiceFavorites = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressVoiceFavorites"];

    hasAnyFeatureEnabled = enableSaveVideo || enableSaveCover || enableSaveAudio || enableSaveCurrentImage || enableSaveAllImages || enableCopyText || enableCopyLink || enableApiDownload ||
                           enableFilterUser || enableFilterKeyword || enableTimerClose || enableCreateVideo || enableVoiceFavorites;

    NSMutableArray *modifiedArray = [NSMutableArray array];

    BOOL hideDaily = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelDaily"];
    BOOL hideRecommend = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelRecommend"];
    BOOL hideNotInterested = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelNotInterested"];
    BOOL hideReport = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelReport"];
    BOOL hideSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSpeed"];
    BOOL hideClearScreen = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelClearScreen"];
    BOOL hideFavorite = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelFavorite"];
    BOOL hideLater = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelLater"];
    BOOL hideCast = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelCast"];
    BOOL hideOpenInPC = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelOpenInPC"];
    BOOL hideSubtitle = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSubtitle"];
    BOOL hideAutoPlay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelAutoPlay"];
    BOOL hideSearchImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSearchImage"];
    BOOL hideListenDouyin = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelListenDouyin"];
    BOOL hideBackgroundPlay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelBackgroundPlay"];
    BOOL hideBiserial = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelBiserial"];
    BOOL hideTimerclose = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelTimerClose"];

    for (id group in originalArray) {
        if ([group isKindOfClass:%c(AWELongPressPanelViewGroupModel)]) {
            AWELongPressPanelViewGroupModel *groupModel = (AWELongPressPanelViewGroupModel *)group;
            NSMutableArray *filteredGroupArr = [NSMutableArray array];
            for (id item in groupModel.groupArr) {
                if ([item isKindOfClass:%c(AWELongPressPanelBaseViewModel)]) {
                    AWELongPressPanelBaseViewModel *viewModel = (AWELongPressPanelBaseViewModel *)item;
                    NSString *descString = viewModel.describeString;
                    BOOL shouldHide = NO;
                    if (([descString isEqualToString:@"转发到日常"] || [descString isEqualToString:@"分享到日常"]) && hideDaily) {
                        shouldHide = YES;
                    } else if (([descString isEqualToString:@"推荐"] || [descString isEqualToString:@"取消推荐"]) && hideRecommend) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"不感兴趣"] && hideNotInterested) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"举报"] && hideReport) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"倍速"] && hideSpeed) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"清屏播放"] && hideClearScreen) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"缓存视频"] && hideFavorite) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"添加至稍后再看"] && hideLater) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"投屏"] && hideCast) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"电脑/Pad打开"] && hideOpenInPC) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕开关"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕设置"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"自动连播"] && hideAutoPlay) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"识别图片"] && hideSearchImage) {
                        shouldHide = YES;
                    } else if (([descString isEqualToString:@"听抖音"] || [descString isEqualToString:@"后台听"] || [descString isEqualToString:@"听视频"]) && hideListenDouyin) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"后台播放设置"] && hideBackgroundPlay) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"首页双列快捷入口"] && hideBiserial) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"定时关闭"] && hideTimerclose) {
                        shouldHide = YES;
                    }

                    if (!shouldHide) {
                        [filteredGroupArr addObject:viewModel];
                    }
                } else {
                    [filteredGroupArr addObject:item];
                }
            }
            if (filteredGroupArr.count > 0) {
                AWELongPressPanelViewGroupModel *newGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
                newGroup.groupType = groupModel.groupType;
                newGroup.groupArr = filteredGroupArr;
                [modifiedArray addObject:newGroup];
            }
        } else {
            [modifiedArray addObject:group];
        }
    }

    if (!hasAnyFeatureEnabled) {
        return modifiedArray;
    }

    AWELongPressPanelViewGroupModel *newGroupModel = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
    newGroupModel.groupType = 0;
    NSMutableArray *viewModels = [NSMutableArray array];
    BOOL isNewLivePhoto = (self.awemeModel.video && self.awemeModel.animatedImageVideoInfo != nil);

    if (enableSaveVideo && self.awemeModel.awemeType != 68 && !isNewLivePhoto) {
        AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        downloadViewModel.awemeModel = self.awemeModel;
        downloadViewModel.actionType = 666;
        downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        downloadViewModel.describeString = @"保存视频";
        downloadViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEVideoModel *videoModel = awemeModel.video;
            AWEMusicModel *musicModel = awemeModel.music;
            NSURL *audioURL = nil;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        audioURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"h264URL")]) {
                id h264URL = [videoModel performSelector:NSSelectorFromString(@"h264URL")];
                if (h264URL && [h264URL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [h264URL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeVideo audio:audioURL completion:nil];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:downloadViewModel];
    }

    if (enableSaveVideo && self.awemeModel.awemeType != 68 && isNewLivePhoto) {
        AWELongPressPanelBaseViewModel *livePhotoViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        livePhotoViewModel.awemeModel = self.awemeModel;
        livePhotoViewModel.actionType = 679;
        livePhotoViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        livePhotoViewModel.describeString = @"保存实况";
        livePhotoViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEVideoModel *videoModel = awemeModel.video;
            
            NSURL *imageURL = nil;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"coverURL")]) {
                id coverURL = [videoModel performSelector:NSSelectorFromString(@"coverURL")];
                if (coverURL && [coverURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [coverURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        imageURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }
            
            NSURL *videoURL = nil;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [videoModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        videoURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            } else if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"h264URL")]) {
                id h264URL = [videoModel performSelector:NSSelectorFromString(@"h264URL")];
                if (h264URL && [h264URL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [h264URL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        videoURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }
            
            if (imageURL && videoURL) {
                [DYYYManager downloadLivePhoto:imageURL videoURL:videoURL completion:nil];
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:livePhotoViewModel];
    }

    if (enableSaveCurrentImage && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
        AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        imageViewModel.awemeModel = self.awemeModel;
        imageViewModel.actionType = 669;
        imageViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";

        if (self.awemeModel.albumImages.count == 1) {
            imageViewModel.describeString = @"保存图片";
        } else {
            imageViewModel.describeString = @"保存当前图片";
        }
        AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
        if (currimge.clipVideo != nil || self.awemeModel.isLivePhoto) {
            if (self.awemeModel.albumImages.count == 1) {
                imageViewModel.describeString = @"保存实况";
            } else {
                imageViewModel.describeString = @"保存当前实况";
            }
        }
        imageViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEImageAlbumImageModel *currentImageModel = nil;
            if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
            } else {
                currentImageModel = awemeModel.albumImages.firstObject;
            }
            NSURL *downloadURL = nil;
            for (NSString *urlString in currentImageModel.urlList) {
                NSURL *url = [NSURL URLWithString:urlString];
                NSString *pathExtension = [url.path.lowercaseString pathExtension];
                if (![pathExtension isEqualToString:@"image"]) {
                    downloadURL = url;
                    break;
                }
            }
            if (currentImageModel.clipVideo != nil) {
                NSURL *videoURL = [currentImageModel.clipVideo.playURL getDYYYSrcURLDownload];
                [DYYYManager downloadLivePhoto:downloadURL videoURL:videoURL completion:nil];
            } else if (currentImageModel && currentImageModel.urlList.count > 0) {
                if (downloadURL) {
                    [DYYYManager downloadMedia:downloadURL mediaType:MediaTypeImage audio:nil completion:^(BOOL success) {
                        if (!success) {
                            [DYYYUtils showToast:@"图片保存已取消"];
                        }
                    }];
                } else {
                    [DYYYUtils showToast:@"没有找到合适格式的图片"];
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:imageViewModel];
    }

    if (enableSaveAllImages && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 1) {
        AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        allImagesViewModel.awemeModel = self.awemeModel;
        allImagesViewModel.actionType = 670;
        allImagesViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        allImagesViewModel.describeString = @"保存所有图片";
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
            NSMutableArray *livePhotos = [NSMutableArray array];
            for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                if (imageModel.urlList.count > 0) {
                    NSURL *downloadURL = nil;
                    for (NSString *urlString in imageModel.urlList) {
                        NSURL *url = [NSURL URLWithString:urlString];
                        NSString *pathExtension = [url.path.lowercaseString pathExtension];
                        if (![pathExtension isEqualToString:@"image"]) {
                            downloadURL = url;
                            break;
                        }
                    }
                    if (!downloadURL && imageModel.urlList.count > 0) {
                        downloadURL = [NSURL URLWithString:imageModel.urlList.firstObject];
                    }
                    if (imageModel.clipVideo != nil) {
                        NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                        [livePhotos addObject:@{@"imageURL" : downloadURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
                    } else {
                        [imageURLs addObject:downloadURL.absoluteString];
                    }
                }
            }
            if (livePhotos.count > 0) {
                [DYYYManager downloadAllLivePhotos:livePhotos];
            }
            if (imageURLs.count > 0) {
                [DYYYManager downloadAllImages:imageURLs];
            }
            if (livePhotos.count == 0 && imageURLs.count == 0) {
                [DYYYUtils showToast:@"没有找到合适格式的图片"];
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:allImagesViewModel];
    }

    if (enableApiDownload && [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"]) {
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
                    [DYYYUtils showToast:@"无法获取分享链接"];
                    return;
                }
                [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];
                AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
                [panelManager dismissWithAnimation:YES completion:nil];
            };
            [viewModels addObject:apiDownload];
        }
    }

    if (enableSaveCover && self.awemeModel.awemeType != 68) {
        AWELongPressPanelBaseViewModel *coverViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        coverViewModel.awemeModel = self.awemeModel;
        coverViewModel.actionType = 667;
        coverViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        coverViewModel.describeString = @"保存封面";
        coverViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEVideoModel *videoModel = awemeModel.video;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"coverURL")]) {
                id coverURL = [videoModel performSelector:NSSelectorFromString(@"coverURL")];
                if (coverURL && [coverURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [coverURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeImage audio:nil completion:^(BOOL success) {
                            if (!success) {
                                [DYYYUtils showToast:@"封面保存已取消"];
                            }
                        }];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:coverViewModel];
    }

    if (enableSaveAudio) {
        AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        audioViewModel.awemeModel = self.awemeModel;
        audioViewModel.actionType = 668;
        audioViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        audioViewModel.describeString = @"保存音频";
        audioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id musicModel = awemeModel.music;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeAudio audio:nil completion:nil];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:audioViewModel];
    }

    if (enableVoiceFavorites) {
        AWELongPressPanelBaseViewModel *voiceViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        voiceViewModel.awemeModel = self.awemeModel;
        voiceViewModel.actionType = 680;
        voiceViewModel.duxIconName = @"ic_phonearrowup_outlined_20"; 
        voiceViewModel.describeString = @"音频助手";
        voiceViewModel.action = ^{
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:^{
                UIViewController *topVC = [DYYYUtils topView];
                if (!topVC) return;
                Class VoiceVCClass = NSClassFromString(@"DYYYVoiceViewController");
                if (VoiceVCClass) {
                    UIViewController *voiceVC = [[VoiceVCClass alloc] init];
                    voiceVC.modalPresentationStyle = UIModalPresentationPageSheet;
                    [topVC presentViewController:voiceVC animated:YES completion:nil];
                }
            }];
        };
        [viewModels addObject:voiceViewModel];
    }

    if (enableVoiceFavorites) {
        AWELongPressPanelBaseViewModel *favAudioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        favAudioViewModel.awemeModel = self.awemeModel;
        favAudioViewModel.actionType = 681; 
        favAudioViewModel.duxIconName = @"ic_star_outlined_20"; 
        favAudioViewModel.describeString = @"音频入库";
        favAudioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id musicModel = awemeModel.music;
            id videoModel = awemeModel.video;
            NSString *audioUrlString = nil;
            
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if ([originList isKindOfClass:[NSArray class]] && originList.count > 0) {
                        audioUrlString = originList.firstObject;
                    }
                }
            } else if (videoModel) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                id downloadURL = nil;
                if ([videoModel respondsToSelector:NSSelectorFromString(@"downloadURL")]) {
                    downloadURL = [videoModel performSelector:NSSelectorFromString(@"downloadURL")];
                } else if ([videoModel respondsToSelector:NSSelectorFromString(@"playAddr")]) {
                    downloadURL = [videoModel performSelector:NSSelectorFromString(@"playAddr")];
                }
                
                if (downloadURL && [downloadURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [downloadURL performSelector:NSSelectorFromString(@"originURLList")];
                    if ([originList isKindOfClass:[NSArray class]] && originList.count > 0) {
                        audioUrlString = originList.firstObject;
                    }
                }
                #pragma clang diagnostic pop
            }
            
            if (audioUrlString && audioUrlString.length > 0) {
                NSString *videoTitle = [awemeModel valueForKey:@"descriptionString"];
                if (!videoTitle || videoTitle.length == 0) {
                    videoTitle = [NSString stringWithFormat:@"提取音频_%ld", (long)[[NSDate date] timeIntervalSince1970]];
                } else {
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@" " withString:@""]; 
                    if (videoTitle.length > 20) {
                        videoTitle = [videoTitle substringToIndex:20];
                    }
                }
                NSString *fileName = videoTitle;
                NSURL *downloadUrl = [NSURL URLWithString:audioUrlString];
                
                [DYYYManager downloadMediaWithProgress:downloadUrl 
                                             mediaType:MediaTypeAudio
                                                 audio:nil 
                                              progress:nil 
                                            completion:^(BOOL success, NSURL *fileURL) {
                    if (success && fileURL) {
                        NSString *targetDir = [[DYYYAudioManager sharedManager] voiceDirectory];
                        NSString *safeFileName = [fileName stringByAppendingPathExtension:@"m4a"];
                        NSString *targetPath = [targetDir stringByAppendingPathComponent:safeFileName];
                        
                        if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
                            [[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
                        }
                        [[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:[NSURL fileURLWithPath:targetPath] error:nil];
                    }
                }];
            } else {
                [DYYYUtils showToast:@"⚠️ 此视频无法提取声音"];
            }
            
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:favAudioViewModel];
    }

    if (enableCreateVideo && self.awemeModel.awemeType == 68) {
        AWELongPressPanelBaseViewModel *createVideoViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        createVideoViewModel.awemeModel = self.awemeModel;
        createVideoViewModel.actionType = 677;
        createVideoViewModel.duxIconName = @"ic_videosearch_outlined_20";
        createVideoViewModel.describeString = @"制作视频";
        createVideoViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            NSMutableArray *imageURLs = [NSMutableArray array];
            NSMutableArray *livePhotos = [NSMutableArray array];
            NSString *bgmURL = nil;
            id musicModel = awemeModel.music;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        bgmURL = originList.firstObject;
                    }
                }
            }

            for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                if (imageModel.urlList.count > 0) {
                    NSString *bestURL = nil;
                    for (NSString *urlString in imageModel.urlList) {
                        NSURL *url = [NSURL URLWithString:urlString];
                        NSString *pathExtension = [url.path.lowercaseString pathExtension];
                        if (![pathExtension isEqualToString:@"image"]) {
                            bestURL = urlString;
                            break;
                        }
                    }
                    if (!bestURL && imageModel.urlList.count > 0) {
                        bestURL = imageModel.urlList.firstObject;
                    }
                    if (imageModel.clipVideo != nil) {
                        NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                        if (videoURL) {
                            [livePhotos addObject:@{@"imageURL" : bestURL, @"videoURL" : videoURL.absoluteString}];
                        }
                    } else {
                        [imageURLs addObject:bestURL];
                    }
                }
            }

            [DYYYManager createVideoFromMedia:imageURLs livePhotos:livePhotos bgmURL:bgmURL progress:nil completion:^(BOOL success, NSString *message) {
                if (!success) {
                    [DYYYUtils showToast:[NSString stringWithFormat:@"视频制作失败: %@", message]];
                }
            }];

            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:createVideoViewModel];
    }

    if (enableCopyText) {
        AWELongPressPanelBaseViewModel *copyText = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        copyText.awemeModel = self.awemeModel;
        copyText.actionType = 671;
        copyText.duxIconName = @"ic_xiaoxihuazhonghua_outlined";
        copyText.describeString = @"复制文案";
        copyText.action = ^{
            NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
            [[UIPasteboard generalPasteboard] setString:descText];
            [DYYYToast showSuccessToastWithMessage:@"文案已复制"];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:copyText];
    }

    if (enableCopyLink) {
        AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        copyShareLink.awemeModel = self.awemeModel;
        copyShareLink.actionType = 672;
        copyShareLink.duxIconName = @"ic_share_outlined";
        copyShareLink.describeString = @"复制链接";
        copyShareLink.action = ^{
            NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
            NSString *cleanedURL = cleanShareURL(shareLink);
            [[UIPasteboard generalPasteboard] setString:cleanedURL];
            [DYYYToast showSuccessToastWithMessage:@"分享链接已复制"];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:copyShareLink];
    }

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
            NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];
            NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterUsers"] ?: @"";
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
            [DYYYBottomAlertView showAlertWithTitle:@"过滤用户视频" message:[NSString stringWithFormat:@"用户: %@ (ID: %@)", nickname, shortId] avatarURL:nil cancelButtonText:@"管理过滤列表" confirmButtonText:actionButtonText cancelAction:^{
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:userArray];
                keywordListView.onConfirm = ^(NSArray *users) {
                    NSString *userString = [users componentsJoinedByString:@","];
                    [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYFilterUsers"];
                    [DYYYUtils showToast:@"过滤用户列表已更新"];
                };
                [keywordListView show];
            } closeAction:nil confirmAction:^{
                NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];
                if (userExists) {
                    NSMutableArray *toRemove = [NSMutableArray array];
                    for (NSString *userInfo in updatedUsers) {
                        NSArray *components = [userInfo componentsSeparatedByString:@"-"];
                        if (components.count >= 2 && [[components lastObject] isEqualToString:shortId]) {
                            [toRemove addObject:userInfo];
                        }
                    }
                    [updatedUsers removeObjectsInArray:toRemove];
                    [DYYYUtils showToast:@"已从过滤列表中移除此用户"];
                } else {
                    [updatedUsers addObject:currentUserFilter];
                    [DYYYUtils showToast:@"已添加此用户到过滤列表"];
                }
                NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
                [[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYFilterUsers"];
            }];
        };
        [viewModels addObject:filterKeywords];
    }

    if (enableFilterKeyword) {
        AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        filterKeywords.awemeModel = self.awemeModel;
        filterKeywords.actionType = 675;
        filterKeywords.duxIconName = @"ic_funnel_outlined_20";
        filterKeywords.describeString = @"过滤文案";
        filterKeywords.action = ^{
            NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
            NSString *propName = nil;
            if (self.awemeModel.propGuideV2) {
                propName = self.awemeModel.propGuideV2.propName;
            }
            DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"过滤关键词调整" text:descText propName:propName];
            filterView.onConfirm = ^(NSString *selectedText) {
                if (selectedText.length > 0) {
                    NSString *currentKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                    NSString *newKeywords = currentKeywords.length > 0 ? [NSString stringWithFormat:@"%@,%@", currentKeywords, selectedText] : selectedText;
                    [[NSUserDefaults standardUserDefaults] setObject:newKeywords forKey:@"DYYYFilterKeywords"];
                    [DYYYUtils showToast:[NSString stringWithFormat:@"已添加过滤词: %@", selectedText]];
                }
            };
            filterView.onKeywordFilterTap = ^{
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];
                keywordListView.onConfirm = ^(NSArray *keywords) {
                    NSString *keywordString = [keywords componentsJoinedByString:@","];
                    [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYFilterKeywords"];
                    [DYYYUtils showToast:@"过滤关键词已更新"];
                };
                [keywordListView show];
            };
            [filterView show];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:filterKeywords];
    }

    if (enableTimerClose) {
        AWELongPressPanelBaseViewModel *timerCloseViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        timerCloseViewModel.awemeModel = self.awemeModel;
        timerCloseViewModel.actionType = 676;
        timerCloseViewModel.duxIconName = @"ic_alarm_outlined";
        
        NSNumber *shutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
        BOOL hasActiveTimer = shutdownTime != nil && [shutdownTime doubleValue] > [[NSDate date] timeIntervalSince1970];
        timerCloseViewModel.describeString = hasActiveTimer ? @"取消定时" : @"定时关闭";
        
        timerCloseViewModel.action = ^{
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:timerCloseViewModel];
    }

    newGroupModel.groupArr = viewModels;

    if (modifiedArray.count > 0) {
        NSMutableArray *resultArray = [modifiedArray mutableCopy];
        [resultArray insertObject:newGroupModel atIndex:0];
        return [resultArray copy];
    } else {
        return @[ newGroupModel ];
    }
}
%end

// 隐藏评论分享功能~ 
%hook AWEIMCommentShareUserHorizontalCollectionViewCell
- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentShareToFriends"]) {
        self.hidden = YES;
    } else {
        self.hidden = NO;
    }
}
%end

%hook AWEIMCommentShareUserHorizontalSectionController
- (CGSize)sizeForItemAtIndex:(NSInteger)index model:(id)model collectionViewSize:(CGSize)size {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentShareToFriends"]) {
        return CGSizeZero;
    }
    return %orig;
}

- (void)configCell:(id)cell index:(NSInteger)index model:(id)model {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentShareToFriends"]) {
        return;
    }
    %orig;
}
%end


// ==========================================
// 🚀 评论区/私信语音提取模块 (终极全覆盖修复版)
// ==========================================
static NSString *g_lastCapturedAudioPath = nil;
static NSData   *g_lastCapturedAudioData = nil; // 内存缓存：防止临时文件被抖音删除
static BOOL g_isLastCapturedNetwork = NO;

// 通过文件头 magic bytes 判断是否音频，不依赖扩展名/路径
// 抖音评论区语音是无扩展名的哈希文件，必须靠内容识别
static BOOL DYYY_IsAudioMagic(NSData *data) {
    if (!data || data.length < 8) return NO;
    const uint8_t *b = (const uint8_t *)data.bytes;
    // M4A / AAC: ftyp box (偏移 4 处)
    if (data.length >= 8 && b[4]=='f' && b[5]=='t' && b[6]=='y' && b[7]=='p') return YES;
    // MP3: ID3 tag
    if (b[0]==0x49 && b[1]==0x44 && b[2]==0x33) return YES;
    // MP3: frame sync
    if (b[0]==0xFF && (b[1] & 0xE0)==0xE0) return YES;
    // OGG
    if (b[0]==0x4F && b[1]==0x67 && b[2]==0x67 && b[3]==0x53) return YES;
    // FLAC
    if (b[0]==0x66 && b[1]==0x4C && b[2]==0x61 && b[3]==0x43) return YES;
    // WAV (RIFF)
    if (b[0]==0x52 && b[1]==0x49 && b[2]==0x46 && b[3]==0x46) return YES;
    // AMR
    if (data.length>=5 && b[0]=='#' && b[1]=='!' && b[2]=='A' && b[3]=='M' && b[4]=='R') return YES;
    // SILK（抖音/微信私信常用）
    if (data.length>=6 && b[0]=='#' && b[1]=='!' && b[2]=='S' && b[3]=='I' && b[4]=='L' && b[5]=='K') return YES;
    return NO;
}

static void DYYY_CheckAndCaptureAudio(NSURL *URL, NSString *source) {
    if (!URL) return;

    NSString *urlStr = URL.absoluteString;
    NSString *localPath = URL.path;
    NSString *lowerStr = urlStr.lowercaseString;
    NSString *lowerName = URL.lastPathComponent.lowercaseString ?: @"";
    NSString *pathExt = URL.pathExtension.lowercaseString ?: @"";

    // Fast-path: skip known non-audio extensions immediately
    static NSSet *nonAudioExts = nil;
    static dispatch_once_t nonAudioToken;
    dispatch_once(&nonAudioToken, ^{
        nonAudioExts = [NSSet setWithArray:@[@"mp4", @"mov", @"flv", @"m3u8", @"ts",
                                              @"jpg", @"jpeg", @"png", @"webp", @"gif", @"bmp",
                                              @"json", @"xml", @"html", @"js", @"css",
                                              @"zip", @"tar", @"gz", @"7z"]];
    });
    if (pathExt.length > 0 && [nonAudioExts containsObject:pathExt]) return;

    if ([lowerName hasPrefix:@"temp_trimmed"] ||
        [lowerName hasPrefix:@"dyyy_"] ||
        [lowerStr containsString:@"/record/"] ||
        [lowerStr containsString:@"/draft/"]) {
        return;
    }

    BOOL isNetwork = [lowerStr hasPrefix:@"http"];

    // 🎵 扩展名白名单：抖音评论区/私信语音常见格式
    BOOL hasAudioExt = ([pathExt isEqualToString:@"mp3"] ||
                        [pathExt isEqualToString:@"m4a"] ||
                        [pathExt isEqualToString:@"aac"] ||
                        [pathExt isEqualToString:@"amr"] ||
                        [pathExt isEqualToString:@"silk"] ||
                        [pathExt isEqualToString:@"wav"] ||
                        [pathExt isEqualToString:@"ogg"] ||
                        [pathExt isEqualToString:@"opus"] ||
                        [pathExt isEqualToString:@"flac"]);

    // 🎯 关键词白名单：评论区/私信语音的 CDN 路径常用 voice / im_msg / obj/im
    BOOL hasAudioKeyword = ([lowerStr containsString:@"audio"] ||
                            [lowerStr containsString:@"voice"] ||
                            [lowerStr containsString:@"im_msg"] ||
                            [lowerStr containsString:@"im-msg"] ||
                            [lowerStr containsString:@"obj/im"]);

    BOOL isLocalTarget = localPath && (
                         [lowerStr containsString:@"cache"] ||
                         [lowerStr containsString:@"attachment"] ||
                         [lowerStr containsString:@"comment"] ||
                         [lowerStr containsString:@"im_audio"] ||
                         [lowerStr containsString:@"im-audio"] ||
                         [lowerStr containsString:@"chat"] ||

                         [lowerStr containsString:@"voice"] ||
                         [lowerStr containsString:@"audio"]);

    // 🎯 记录路径并区分网络/本地
    if (isNetwork && (hasAudioExt || hasAudioKeyword)) {
        g_lastCapturedAudioPath = urlStr;
        g_isLastCapturedNetwork = YES;
    } else if (!isNetwork && (isLocalTarget || hasAudioExt)) {
        // ⚠️ 本地文件必须存纯路径 localPath，不能存 urlStr
        g_lastCapturedAudioPath = localPath;
        g_isLastCapturedNetwork = NO;
    }
}

// --- 🎯 全面拦截 AVFoundation 的初始化与类方法 (防止漏网) ---

%hook AVPlayerItem
- (instancetype)initWithURL:(NSURL *)URL {
    DYYY_CheckAndCaptureAudio(URL, @"AVPlayerItem_Init");
    return %orig;
}
+ (instancetype)playerItemWithURL:(NSURL *)URL {
    DYYY_CheckAndCaptureAudio(URL, @"AVPlayerItem");
    return %orig;
}
%end

%hook AVPlayer
- (instancetype)initWithURL:(NSURL *)URL {
    DYYY_CheckAndCaptureAudio(URL, @"AVPlayer_Init");
    return %orig;
}
+ (instancetype)playerWithURL:(NSURL *)URL {
    DYYY_CheckAndCaptureAudio(URL, @"AVPlayer_Class");
    return %orig;
}
%end

%hook AVAudioPlayer
- (id)initWithContentsOfURL:(NSURL *)url error:(NSError **)outError {
    DYYY_CheckAndCaptureAudio(url, @"AVAudioPlayer_Init");
    return %orig;
}
%end

%hook AVURLAsset
- (id)initWithURL:(NSURL *)URL options:(NSDictionary<NSString *,id> *)options {
    DYYY_CheckAndCaptureAudio(URL, @"AVURLAsset_Init");
    return %orig;
}
+ (instancetype)URLAssetWithURL:(NSURL *)URL options:(NSDictionary<NSString *,id> *)options {
    DYYY_CheckAndCaptureAudio(URL, @"AVURLAsset_Class");
    return %orig;
}
%end

// --- 🌐 兜底：NSURLSession / NSURLRequest 拦截 ---
// 抖音评论区语音常走字节自家播放器（TTPlayerView 等），不经 AVFoundation，
// 但 HTTP 下载终归要走 NSURLSession。在请求层捕获 URL 作为最后防线。

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url {
    DYYY_CheckAndCaptureAudio(url, @"URLSession_Data_URL");
    return %orig;
}
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    if (request.URL) DYYY_CheckAndCaptureAudio(request.URL, @"URLSession_Data_Req");
    return %orig;
}
- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url {
    DYYY_CheckAndCaptureAudio(url, @"URLSession_Dl_URL");
    return %orig;
}
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request {
    if (request.URL) DYYY_CheckAndCaptureAudio(request.URL, @"URLSession_Dl_Req");
    return %orig;
}
%end

%hook NSURLRequest
+ (instancetype)requestWithURL:(NSURL *)URL {
    DYYY_CheckAndCaptureAudio(URL, @"URLRequest_With");
    return %orig;
}
%end

// --- 📂 文件读取拦截：用 magic bytes 识别音频，数据缓存到内存 ---
// 抖音评论区语音是无扩展名的哈希缓存文件，无法靠路径识别，
// 靠文件头 magic bytes 判断是否音频，并立即在内存里存一份，
// 避免抖音读完就删临时文件导致摇一摇时拷贝失败。

static void DYYY_CaptureFromData(NSData *result, NSString *path, BOOL isNetworkURL) {
    if (!result || !DYYY_IsAudioMagic(result)) return;
    if (!path) return;
    NSString *lower = path.lowercaseString;
    NSString *lname = path.lastPathComponent.lowercaseString;
    // 排除自己写入的文件
    if ([lname hasPrefix:@"dyyy_"] || [lname hasPrefix:@"temp_trimmed"] ||
        [lname hasPrefix:@"提取语音"] || [lower containsString:@"/record/"] ||
        [lower containsString:@"/draft/"]) return;
    // 记录路径 + 内存缓存
    g_lastCapturedAudioPath = path;
    g_lastCapturedAudioData = result;
    g_isLastCapturedNetwork = isNetworkURL;
}

static NSSet *DYYYAudioExtensionsForCapture(void) {
    static NSSet *exts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exts = [NSSet setWithArray:@[@"mp3", @"m4a", @"aac", @"amr", @"silk", @"wav", @"ogg", @"opus", @"flac"]];
    });
    return exts;
}

%hook NSData
+ (instancetype)dataWithContentsOfFile:(NSString *)path {
    NSData *result = %orig;
    if (result && result.length > 4) {
        NSString *ext = path.pathExtension.lowercaseString;
        if (ext.length == 0 || [DYYYAudioExtensionsForCapture() containsObject:ext]) {
            DYYY_CaptureFromData(result, path, NO);
        }
    }
    return result;
}
+ (instancetype)dataWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)opts error:(NSError **)err {
    NSData *result = %orig;
    if (result && result.length > 4) {
        NSString *ext = path.pathExtension.lowercaseString;
        if (ext.length == 0 || [DYYYAudioExtensionsForCapture() containsObject:ext]) {
            DYYY_CaptureFromData(result, path, NO);
        }
    }
    return result;
}
+ (instancetype)dataWithContentsOfURL:(NSURL *)url {
    NSData *result = %orig;
    if (result && result.length > 4 && url) {
        NSString *ext = url.pathExtension.lowercaseString;
        BOOL isAudioExt = ext.length == 0 || [DYYYAudioExtensionsForCapture() containsObject:ext];
        BOOL isNetwork = [url.scheme hasPrefix:@"http"];
        if (isAudioExt || isNetwork) {
            DYYY_CaptureFromData(result, url.absoluteString, isNetwork);
        }
    }
    return result;
}
+ (instancetype)dataWithContentsOfURL:(NSURL *)url options:(NSDataReadingOptions)opts error:(NSError **)err {
    NSData *result = %orig;
    if (result && result.length > 4 && url) {
        NSString *ext = url.pathExtension.lowercaseString;
        BOOL isAudioExt = ext.length == 0 || [DYYYAudioExtensionsForCapture() containsObject:ext];
        BOOL isNetwork = [url.scheme hasPrefix:@"http"];
        if (isAudioExt || isNetwork) {
            DYYY_CaptureFromData(result, url.absoluteString, isNetwork);
        }
    }
    return result;
}
%end


// ==========================================
// 📁 兜底：沙盒扫描（按 atime 找最近被访问的音频，不是按 mtime）
// ==========================================
// 抖音评论区语音是预缓存的：用户点播时只读取已有文件，mtime 不会更新。
// 改用 atime（access time，通过 stat() 拿）找最近被"读取"的音频文件。
static NSString *DYYY_ScanRecentAudioInCache(NSTimeInterval maxAgeSec, NSMutableString *outStats) {
    NSArray<NSString *> *roots = @[
        [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] ?: @"",
        [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] ?: @"",
        [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] ?: @"",
        NSTemporaryDirectory() ?: @"",
    ];

    NSArray<NSString *> *audioExts = @[ @"m4a", @"mp3", @"aac", @"amr", @"silk", @"wav", @"ogg", @"opus", @"flac" ];

    time_t now = time(NULL);
    time_t cutoff = now - (time_t)maxAgeSec;

    NSString *bestPath = nil;
    time_t bestAtime = 0;
    NSInteger totalSeen = 0;
    NSInteger matchedExt = 0;
    NSInteger inWindow = 0;
    NSInteger const kMaxScanEntries = 20000; // 保护上限，避免无限遍历巨大目录

    for (NSString *root in roots) {
        if (!root.length) continue;
        if (totalSeen >= kMaxScanEntries) break;
        NSDirectoryEnumerator *e = [[NSFileManager defaultManager] enumeratorAtPath:root];
        NSString *rel;
        while ((rel = [e nextObject])) {
            if (totalSeen++ >= kMaxScanEntries) break;
            NSString *ext = rel.pathExtension.lowercaseString;
            if (![audioExts containsObject:ext]) continue;
            matchedExt++;

            NSString *full = [root stringByAppendingPathComponent:rel];
            NSString *lower = full.lowercaseString;
            NSString *lastComp = full.lastPathComponent.lowercaseString;

            // 排除自己写入的文件
            if ([lastComp hasPrefix:@"dyyy_"] ||
                [lastComp hasPrefix:@"temp_trimmed"] ||
                [lastComp hasPrefix:@"提取语音"] ||
                [lower containsString:@"/record/"] ||
                [lower containsString:@"/draft/"]) continue;

            struct stat st;
            if (stat(full.fileSystemRepresentation, &st) != 0) continue;
            // 取 atime/mtime 较大者作为"最近活动时间"，兼容 atime 不更新的情况
            time_t latest = st.st_atime > st.st_mtime ? st.st_atime : st.st_mtime;
            if (latest < cutoff) continue;
            inWindow++;

            if (latest > bestAtime) {
                bestAtime = latest;
                bestPath = full;
            }
        }
    }
    if (outStats) {
        [outStats appendFormat:@"扫描:%ld 音频:%ld 窗口内:%ld", (long)totalSeen, (long)matchedExt, (long)inWindow];
    }
    return bestPath;
}


// ==========================================
// 📱 摇一摇触发导出 (网络与本地智能分发版)
// ==========================================
%hook UIWindow
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion != UIEventSubtypeMotionShake) {
        %orig;
        return;
    }

    BOOL capturedPath = (g_lastCapturedAudioPath != nil);
    BOOL capturedMem  = (g_lastCapturedAudioData != nil);

    NSMutableString *stats = [NSMutableString string];
    if (!capturedPath && !capturedMem) {
        NSString *scanned = DYYY_ScanRecentAudioInCache(300.0, stats);
        if (scanned) {
            g_lastCapturedAudioPath = scanned;
            g_isLastCapturedNetwork = NO;
            capturedPath = YES;
        }
    }

    if (!capturedPath && !capturedMem) {
        NSString *diag = [NSString stringWithFormat:@"摇到了但没抓到 %@", stats];
        dispatch_async(dispatch_get_main_queue(), ^{
            [DYYYUtils showToast:diag];
        });
        %orig;
        return;
    }

    // Audio was captured — consume the shake event
    {

        NSString *targetDir = [[DYYYAudioManager sharedManager] voiceDirectory];
        NSString *ext = @"aac"; // 默认 aac
        
        if (!g_isLastCapturedNetwork && g_lastCapturedAudioPath.pathExtension.length > 0) {
            ext = g_lastCapturedAudioPath.pathExtension.lowercaseString;
        } else if (g_isLastCapturedNetwork && [[NSURL URLWithString:g_lastCapturedAudioPath] pathExtension].length > 0) {
            ext = [[NSURL URLWithString:g_lastCapturedAudioPath] pathExtension].lowercaseString;
        }
        if ([ext containsString:@"tmp"]) ext = @"aac";
        
        NSString *fileName = [NSString stringWithFormat:@"提取语音_%ld.%@", (long)[[NSDate date] timeIntervalSince1970], ext];
        NSString *targetPath = [targetDir stringByAppendingPathComponent:fileName];
        
        // 🌐 场景 1：网络下载 (评论区)
        if (g_isLastCapturedNetwork) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [DYYYUtils showToast:@"⏳ 正在下载网络语音..."];
            });
            
            NSString *downloadUrl = g_lastCapturedAudioPath; // 备份URL防止被覆盖
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *audioData = [NSData dataWithContentsOfURL:[NSURL URLWithString:downloadUrl]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (audioData && [audioData writeToFile:targetPath atomically:YES]) {
                        [DYYYUtils showToast:@"✅ 摇一摇：评论语音已下载至助手！"];
                        g_lastCapturedAudioPath = nil; 
                    } else {
                        [DYYYUtils showToast:@"❌ 语音下载失败，请重新播放"];
                    }
                });
            });
            
        } 
        // 📁 场景 2：本地（评论区缓存 / 私信）
        else {
            NSData *memData = g_lastCapturedAudioData;
            NSString *srcPath = g_lastCapturedAudioPath;
            g_lastCapturedAudioPath = nil;
            g_lastCapturedAudioData = nil;

            // 优先用内存数据（应对临时文件已被删的情况）
            if (memData && [memData writeToFile:targetPath atomically:YES]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [DYYYUtils showToast:@"✅ 摇一摇：语音已提取至助手！"];
                });
            } else if (srcPath && [[NSFileManager defaultManager] fileExistsAtPath:srcPath]) {
                NSError *error = nil;
                [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:targetPath error:&error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [DYYYUtils showToast:error ? @"❌ 本地提取失败" : @"✅ 摇一摇：语音已提取至助手！"];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [DYYYUtils showToast:@"❌ 未捕获到语音，请先播放再摇"];
                });
            }
        }
    }
}  // end consume-shake block
%end



%ctor {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
        %init;
    }
}

%group DYYYFilterSetterGroup
%hook HOOK_TARGET_OWNER_CLASS
- (void)setModelsArray:(id)arg1 {
    if (![arg1 isKindOfClass:[NSArray class]]) {
        %orig(arg1);
        return;
    }

    NSArray *inputArray = (NSArray *)arg1;
    NSMutableArray *filteredArray = nil;

    for (id item in inputArray) {
        NSString *className = NSStringFromClass([item class]);

        BOOL shouldFilter = ([className isEqualToString:@"AWECommentIMSwiftImpl.CommentLongPressPanelForwardElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressDaily"]) ||
                            ([className isEqualToString:@"AWECommentLongPressPanelSwiftImpl.CommentLongPressPanelCopyElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressCopy"]) ||
                            ([className isEqualToString:@"AWECommentLongPressPanelSwiftImpl.CommentLongPressPanelSaveImageElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressSaveImage"]) ||
                            ([className isEqualToString:@"AWECommentLongPressPanelSwiftImpl.CommentLongPressPanelReportElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressReport"]) ||
                            ([className isEqualToString:@"AWECommentStudioSwiftImpl.CommentLongPressPanelVideoReplyElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressVideoReply"]) ||
                            ([className isEqualToString:@"AWECommentSearchSwiftImpl.CommentLongPressPanelPictureSearchElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressPictureSearch"]) ||
                            ([className isEqualToString:@"AWECommentSearchSwiftImpl.CommentLongPressPanelSearchElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressSearch"]);

        if (shouldFilter) {
            if (!filteredArray) {
                filteredArray = [NSMutableArray arrayWithCapacity:inputArray.count];
                for (id keepItem in inputArray) {
                    if (keepItem == item)
                        break;
                    [filteredArray addObject:keepItem];
                }
            }
            continue;
        }

        if (filteredArray) {
            [filteredArray addObject:item];
        }
    }

    if (filteredArray) {
        %orig([filteredArray copy]);
    } else {
        %orig(arg1);
    }
}
%end
%end


// ==========================================
// ⚠️ 构造函数必须永远放在文件的【最底部】
// ==========================================
%ctor {
    Class ownerClass = objc_getClass("AWECommentLongPressPanelSwiftImpl.CommentLongPressPanelNormalSectionViewModel");
    if (ownerClass) {
        %init(DYYYFilterSetterGroup, HOOK_TARGET_OWNER_CLASS = ownerClass);
    }
}