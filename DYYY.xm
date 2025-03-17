//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//  Created on: 2024/10/04
//
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "CityManager.h"
#import "AwemeHeaders.h"

static UIWindow * getActiveWindow(void) {
    if (@available(iOS 15.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                    if (w.isKeyWindow) return w;
                }
            }
        }
        return nil;
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [UIApplication sharedApplication].windows.firstObject;
        #pragma clang diagnostic pop
    }
}

static UIViewController * getActiveTopController(void) {
    UIWindow *window = getActiveWindow();
    if (!window) return nil;
    
    UIViewController *topController = window.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

static UIColor * colorWithHexString(NSString *hexString) {
    if ([[hexString lowercaseString] isEqualToString:@"random"] || 
        [[hexString lowercaseString] isEqualToString:@"#random"]) {
        CGFloat red = arc4random_uniform(200) / 255.0;
        CGFloat green = arc4random_uniform(200) / 255.0;
        CGFloat blue = arc4random_uniform(128) / 255.0;
        CGFloat alpha = 1;
        return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }
    
    NSString *colorString = hexString;
    if ([hexString hasPrefix:@"#"]) {
        colorString = [hexString substringFromIndex:1];
    }
    
    if (colorString.length == 3) {
        NSString *r = [colorString substringWithRange:NSMakeRange(0, 1)];
        NSString *g = [colorString substringWithRange:NSMakeRange(1, 1)];
        NSString *b = [colorString substringWithRange:NSMakeRange(2, 1)];
        colorString = [NSString stringWithFormat:@"%@%@%@%@%@%@", r, r, g, g, b, b];
    }
    
    if (colorString.length == 6) {
        unsigned int hexValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:colorString];
        [scanner scanHexInt:&hexValue];
        
        CGFloat red = ((hexValue & 0xFF0000) >> 16) / 255.0;
        CGFloat green = ((hexValue & 0x00FF00) >> 8) / 255.0;
        CGFloat blue = (hexValue & 0x0000FF) / 255.0;
        
        return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    }
    
    if (colorString.length == 8) {
        unsigned int hexValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:colorString];
        [scanner scanHexInt:&hexValue];
        
        CGFloat red = ((hexValue & 0xFF000000) >> 24) / 255.0;
        CGFloat green = ((hexValue & 0x00FF0000) >> 16) / 255.0;
        CGFloat blue = ((hexValue & 0x0000FF00) >> 8) / 255.0;
        CGFloat alpha = (hexValue & 0x000000FF) / 255.0;
        
        return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }
    
    return [UIColor whiteColor];
}

void showToast(NSString *text) {
    [%c(DUXToast) showText:text];
}

void saveMedia(NSURL *mediaURL, MediaType mediaType, void (^completion)(void)) {
    if (mediaType == MediaTypeAudio) {
        return;
    }

    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                if (mediaType == MediaTypeVideo) {
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:mediaURL];
                } else if (mediaType == MediaTypeHeic) {
                    [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:mediaURL];
                } else {
                    UIImage *image = [UIImage imageWithContentsOfFile:mediaURL.path];
                    if (image) {
                        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                    }
                }
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    if (completion) {
                        completion();
                    }
                } else {
                    showToast(@"保存失败");
                }
                [[NSFileManager defaultManager] removeItemAtPath:mediaURL.path error:nil];
            }];
        }
    }];
}

void downloadMedia(NSURL *url, MediaType mediaType, void (^completion)(void)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        Class AWEProgressLoadingViewClass = %c(AWEProgressLoadingView);
        id loadingView = nil;
        
        if ([AWEProgressLoadingViewClass respondsToSelector:@selector(alloc)]) {
            id allocatedView = [AWEProgressLoadingViewClass alloc];
            if ([allocatedView respondsToSelector:@selector(init)]) {
                loadingView = [allocatedView init];
                if ([loadingView respondsToSelector:@selector(setTitle:)]) {
                    [loadingView performSelector:@selector(setTitle:) withObject:@"解析中..."];
                }
            }
        }
        
        if (loadingView && [loadingView respondsToSelector:@selector(showInView:animated:)]) {
            [loadingView performSelector:@selector(showInView:animated:) withObject:[UIApplication sharedApplication].keyWindow withObject:@(YES)];
        } else if (loadingView && [loadingView respondsToSelector:@selector(showOnView:animated:)]) {
            [loadingView showOnView:[UIApplication sharedApplication].keyWindow animated:YES];
        }

        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (loadingView) {
                    if ([loadingView respondsToSelector:@selector(dismissAnimated:)]) {
                        [loadingView dismissAnimated:YES];
                    } else if ([loadingView respondsToSelector:@selector(dismiss)]) {
                        [loadingView performSelector:@selector(dismiss)];
                    }
                }
            });

            if (!error) {
                NSString *fileName = url.lastPathComponent;

                if (!fileName.pathExtension.length) {
                    switch (mediaType) {
                        case MediaTypeVideo:
                            fileName = [fileName stringByAppendingPathExtension:@"mp4"];
                            break;
                        case MediaTypeImage:
                            fileName = [fileName stringByAppendingPathExtension:@"jpg"];
                            break;
                        case MediaTypeAudio:
                            fileName = [fileName stringByAppendingPathExtension:@"mp3"];
                            break;
                        case MediaTypeHeic:
                            fileName = [fileName stringByAppendingPathExtension:@"heic"];
                            break;
                    }
                }

                NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
                NSURL *destinationURL = [tempDir URLByAppendingPathComponent:fileName];
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:destinationURL error:nil];

                if (mediaType == MediaTypeAudio) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[destinationURL] applicationActivities:nil];

                        [activityVC setCompletionWithItemsHandler:^(UIActivityType _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable error) {
                            [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
                        }];
                        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
                        [rootVC presentViewController:activityVC animated:YES completion:nil];
                    });
                } else {
                    saveMedia(destinationURL, mediaType, completion);
                }
            } else {
                showToast(@"下载失败");
            }
        }];
        [downloadTask resume];
    });
}

void downloadAllImages(NSMutableArray *imageURLs) {
    dispatch_group_t group = dispatch_group_create();
    __block NSInteger downloadCount = 0;

    for (NSString *imageURL in imageURLs) {
        NSURL *url = [NSURL URLWithString:imageURL];
        dispatch_group_enter(group);

        downloadMedia(url, MediaTypeImage, ^{
            dispatch_group_leave(group);
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        showToast(@"所有图片保存完成");
    });
}

%hook AWEAwemePlayVideoViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
    float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];
    
    if (defaultSpeed > 0 && defaultSpeed != 1) {
        [self setVideoControllerPlaybackRate:defaultSpeed];
    }
    
    %orig(arg0);
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
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYtopbartransparent"];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnablePure"]) {
        %orig(0.0);
        
        static dispatch_source_t timer = nil;
        static int attempts = 0;
        
        if (timer) {
            dispatch_source_cancel(timer);
            timer = nil;
        }
        
        void (^tryFindAndSetPureMode)(void) = ^{
            UIWindow *keyWindow = getActiveWindow();
            
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
    if (!vc) return nil;
    if ([vc isKindOfClass:targetClass]) return vc;
    
    for (UIViewController *childVC in vc.childViewControllers) {
        UIViewController *found = [self findViewController:childVC ofClass:targetClass];
        if (found) return found;
    }
    
    return [self findViewController:vc.presentedViewController ofClass:targetClass];
}
%end

%hook AWEDanmakuContentLabel
- (void)setTextColor:(UIColor *)textColor {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"]) {
        NSString *danmuColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYdanmuColor"];
        
        if ([danmuColor.lowercaseString isEqualToString:@"random"] || [danmuColor.lowercaseString isEqualToString:@"#random"]) {
            textColor = colorWithHexString(@"random");
            self.layer.shadowOffset = CGSizeZero;
            self.layer.shadowOpacity = 0.0;
        } else if ([danmuColor hasPrefix:@"#"]) {
            textColor = colorWithHexString(danmuColor);
            self.layer.shadowOffset = CGSizeZero;
            self.layer.shadowOpacity = 0.0;
        }
    }

    %orig(textColor);
}
%end

%hook AWEDanmakuItemTextInfo
- (void)setDanmakuTextColor:(id)arg1 {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"]) {
        NSString *danmuColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYdanmuColor"];
        
        if ([danmuColor.lowercaseString isEqualToString:@"random"] || [danmuColor.lowercaseString isEqualToString:@"#random"]) {
            arg1 = colorWithHexString(@"random");
        } else if ([danmuColor hasPrefix:@"#"]) {
            arg1 = colorWithHexString(danmuColor);
        }
    }

    %orig(arg1);
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
                        [closeButton.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:40],
                        [closeButton.widthAnchor constraintEqualToConstant:80],
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
                    [handleBar.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:8],
                    [handleBar.widthAnchor constraintEqualToConstant:40],
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

%hook AWESettingsViewModel

- (NSArray *)sectionDataArray {
    NSArray *originalSections = %orig;
    
    BOOL sectionExists = NO;
    for (AWESettingSectionModel *section in originalSections) {
        if ([section.sectionHeaderTitle isEqualToString:@"DYYY"]) {
            sectionExists = YES;
            break;
        }
    }
    
    if (self.traceEnterFrom && !sectionExists) {
        AWESettingItemModel *dyyyItem = [[%c(AWESettingItemModel) alloc] init];
        dyyyItem.identifier = @"DYYY";
        dyyyItem.title = @"DYYY";
        dyyyItem.detail = @"v2.1-5";
        dyyyItem.type = 0;
        dyyyItem.iconImageName = @"noticesettting_like";
        dyyyItem.cellType = 26;
        dyyyItem.colorStyle = 2;
        dyyyItem.isEnable = YES;
        
        dyyyItem.cellTappedBlock = ^{
            UIViewController *rootViewController = self.controllerDelegate;
            DYYYSettingViewController *settingVC = [[DYYYSettingViewController alloc] init];
            if (rootViewController.navigationController) {
                [rootViewController.navigationController pushViewController:settingVC animated:YES];
            } else {
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingVC];
                [rootViewController presentViewController:navController animated:YES completion:nil];
            }

        };
        
        AWESettingSectionModel *dyyySection = [[%c(AWESettingSectionModel) alloc] init];
        dyyySection.sectionHeaderTitle = @"DYYY";
        dyyySection.sectionHeaderHeight = 40;
        dyyySection.type = 0;
        dyyySection.itemArray = @[dyyyItem];
        
        NSMutableArray<AWESettingSectionModel *> *newSections = [NSMutableArray arrayWithArray:originalSections];
        [newSections insertObject:dyyySection atIndex:0];
        
        return newSections;
    }
    
    return originalSections;
}

%end


%end

%hook AWEFeedLiveMarkView
- (void)setHidden:(BOOL)hidden {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
        hidden = YES;
    }

    %orig(hidden);
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

%hook AWELandscapeFeedEntryView
- (void)setHidden:(BOOL)hidden {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenEntry"]) {
        hidden = YES;
    }
    
    %orig(hidden);
}
%end

%hook AWEAwemeModel

- (void)live_callInitWithDictyCategoryMethod:(id)arg1 {
    if (self.currentAweme && [self.currentAweme isLive] && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisSkipLive"]) {
        return;
    }
    %orig;
}

+ (id)liveStreamURLJSONTransformer {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisSkipLive"] ? nil : %orig;
}

+ (id)relatedLiveJSONTransformer {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisSkipLive"] ? nil : %orig;
}

+ (id)rawModelFromLiveRoomModel:(id)arg1 {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisSkipLive"] ? nil : %orig;
}

+ (id)aweLiveRoom_subModelPropertyKey {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisSkipLive"] ? nil : %orig;
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
//MARK: 双击视频打开评论区视频的双击事件
- (void)onPlayer:(id)arg0 didDoubleClick:(id)arg1{
    //如果打开双击评论功能
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDoubleOpenComment"]){
        //调用原生的
         [self performCommentAction];
        return;
    }
    %orig;
}
%end


%hook AWEStoryContainerCollectionView
- (void)layoutSubviews {
    %orig;
    
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIView class]]) {
            UIView *nextResponder = (UIView *)subview.nextResponder;
            if ([nextResponder isKindOfClass:%c(AWEPlayInteractionViewController)]) {
                UIViewController *awemeBaseViewController = [nextResponder valueForKey:@"awemeBaseViewController"];
                if (![awemeBaseViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
                    return;
                }
            }
            
            CGRect frame = subview.frame;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
                frame.size.height = subview.superview.frame.size.height - 83;
                subview.frame = frame;
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
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
        %orig;
        return;
    }
    
    UIViewController *vc = [self firstAvailableUIViewController];
    if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
        if (frame.origin.x != 0 || frame.origin.y != 0) {
            return;
        } else {
            CGRect superviewFrame = self.superview.frame;
            
            if (superviewFrame.size.height > 0 && frame.size.height > 0 && 
                frame.size.height < superviewFrame.size.height && 
                frame.origin.x == 0 && frame.origin.y == 0) {
                
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
        
        BOOL isDarkMode = YES;
        
        UILabel *commentLabel = [self findCommentLabel:self.view];
        if (commentLabel) {
            UIColor *textColor = commentLabel.textColor;
            CGFloat red, green, blue, alpha;
            [textColor getRed:&red green:&green blue:&blue alpha:&alpha];
            
            if (red > 0.7 && green > 0.7 && blue > 0.7) {
                isDarkMode = YES;
            } else if (red < 0.3 && green < 0.3 && blue < 0.3) {
                isDarkMode = NO;
            }
        }
        
        UIBlurEffectStyle blurStyle = isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
        
        if (!existingBlurView) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
            UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurEffectView.frame = self.view.bounds;
            blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            blurEffectView.alpha = 0.98;
            blurEffectView.tag = 999;
            
            UIView *overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
            CGFloat alpha = isDarkMode ? 0.3 : 0.1;
            overlayView.backgroundColor = [UIColor colorWithWhite:(isDarkMode ? 0 : 1) alpha:alpha];
            overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [blurEffectView.contentView addSubview:overlayView];
            
            [self.view insertSubview:blurEffectView atIndex:0];
        } else {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
            [existingBlurView setEffect:blurEffect];
            
            for (UIView *subview in existingBlurView.contentView.subviews) {
                if (subview.tag != 999) {
                    CGFloat alpha = isDarkMode ? 0.3 : 0.1;
                    subview.backgroundColor = [UIColor colorWithWhite:(isDarkMode ? 0 : 1) alpha:alpha];
                }
            }
            
            [self.view insertSubview:existingBlurView atIndex:0];
        }
    }
}

%new
- (UILabel *)findCommentLabel:(UIView *)view {
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (label.text && ([label.text hasSuffix:@"条评论"] || [label.text hasSuffix:@"暂无评论"])) {
            return label;
        }
    }
    
    for (UIView *subview in view.subviews) {
        UILabel *result = [self findCommentLabel:subview];
        if (result) {
            return result;
        }
    }
    
    return nil;
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

- (void)setIsAds:(BOOL)isAds {
    %orig(NO);
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
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenSidebarDot"]) {
        for (UIView *subview in [self subviews]) {
            if ([subview isKindOfClass:NSClassFromString(@"DUXBadge")]) {
                subview.hidden = YES;
            }
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
    } else if ([accessibilityLabel isEqualToString:@"评论"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentButton"]) {
            [self removeFromSuperview];
            return;
        }
    } else if ([accessibilityLabel isEqualToString:@"分享"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareButton"]) {
            [self removeFromSuperview];
            return;
        }
    } else if ([accessibilityLabel isEqualToString:@"收藏"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectButton"]) {
            [self removeFromSuperview];
            return;
        }
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
    }
}

%end

%hook AWEAdAvatarView

- (void)layoutSubviews {
    %orig;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
        [self removeFromSuperview];
        return;
    }
}

%end

%hook AWENormalModeTabBar

- (void)layoutSubviews {
    %orig;

    BOOL hideShop = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShopButton"];
    BOOL hideMsg = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMessageButton"];
    BOOL hideFri = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFriendsButton"];
    
    NSMutableArray *visibleButtons = [NSMutableArray array];
    Class generalButtonClass = %c(AWENormalModeTabBarGeneralButton);
    Class plusButtonClass = %c(AWENormalModeTabBarGeneralPlusButton);
    
    for (UIView *subview in self.subviews) {
        if (![subview isKindOfClass:generalButtonClass] && ![subview isKindOfClass:plusButtonClass]) continue;
        
        NSString *label = subview.accessibilityLabel;
        BOOL shouldHide = NO;
        
        if ([label isEqualToString:@"商城"]) {
            shouldHide = hideShop;
        } else if ([label containsString:@"消息"]) {
            shouldHide = hideMsg;
        } else if ([label containsString:@"朋友"]) {
            shouldHide = hideFri;
        }
        
        if (!shouldHide) {
            [visibleButtons addObject:subview];
        } else {
            [subview removeFromSuperview];
        }
    }

    [visibleButtons sortUsingComparator:^NSComparisonResult(UIView* a, UIView* b) {
        return [@(a.frame.origin.x) compare:@(b.frame.origin.x)];
    }];

    CGFloat totalWidth = self.bounds.size.width;
    CGFloat buttonWidth = totalWidth / visibleButtons.count;
    
    for (NSInteger i = 0; i < visibleButtons.count; i++) {
        UIView *button = visibleButtons[i];
        button.frame = CGRectMake(i * buttonWidth, button.frame.origin.y, buttonWidth, button.frame.size.height);
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenBottomBg"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
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
                    subview.hidden = YES;
                    break;
                }
            }
        }
    }
}

%end

%hook UITextInputTraits
- (void)setKeyboardAppearance:(UIKeyboardAppearance)appearance {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        %orig(UIKeyboardAppearanceDark);
    }else {
        %orig;
    }
}
%end

%hook AWECommentMiniEmoticonPanelView

- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UICollectionView class]]) {
                subview.backgroundColor = [UIColor colorWithRed:115/255.0 green:115/255.0 blue:115/255.0 alpha:1.0];
            }
        }
    }
}
%end

%hook AWECommentPublishGuidanceView

- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UICollectionView class]]) {
                subview.backgroundColor = [UIColor colorWithRed:115/255.0 green:115/255.0 blue:115/255.0 alpha:1.0];
            }
        }
    }
}
%end

%hook UIView
- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputViewMiddleContainer")]) {
                for (UIView *innerSubview in subview.subviews) {
                    if ([innerSubview isKindOfClass:[UIView class]]) {
                        innerSubview.backgroundColor = [UIColor colorWithRed:31/255.0 green:33/255.0 blue:35/255.0 alpha:1.0];
                        break;
                    }
                }
            }
            if ([subview isKindOfClass:NSClassFromString(@"AWEIMEmoticonPanelBoxView")]) {
                subview.backgroundColor = [UIColor colorWithRed:33/255.0 green:33/255.0 blue:33/255.0 alpha:1.0];
            }
        }
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"] || 
    [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"]) {
        NSString *className = NSStringFromClass([self class]);
        if ([className isEqualToString:@"AWECommentInputViewSwiftImpl.CommentInputContainerView"]) {
            for (UIView *subview in self.subviews) {
                if ([subview isKindOfClass:[UIView class]] && subview.backgroundColor) {
                    CGFloat red = 0, green = 0, blue = 0, alpha = 0;
                    [subview.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
                    
                    if ((red == 22/255.0 && green == 22/255.0 && blue == 22/255.0) || 
                        (red == 1.0 && green == 1.0 && blue == 1.0)) {
                        subview.backgroundColor = [UIColor clearColor];
                    }
                }
            }
        }
        
        UIViewController *vc = [self firstAvailableUIViewController];
        if ([vc isKindOfClass:%c(AWEPlayInteractionViewController)]) {
            BOOL shouldHideSubview = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"] || 
                                [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"];

            if (shouldHideSubview) {
                for (UIView *subview in self.subviews) {
                    if ([subview isKindOfClass:[UIView class]] && 
                        subview.backgroundColor && 
                        CGColorEqualToColor(subview.backgroundColor.CGColor, [UIColor blackColor].CGColor)) {
                        subview.hidden = YES;
                    }
                }
            }
        }
    }
}
%end

%hook UILabel

- (void)setText:(NSString *)text {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        if ([text hasPrefix:@"善语"] || [text hasPrefix:@"友爱评论"] || [text hasPrefix:@"回复"]) {
            self.textColor = [UIColor colorWithRed:125/255.0 green:125/255.0 blue:125/255.0 alpha:0.6];
        }
    }
    %orig;
}

%end

%hook UIButton

- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    NSString *label = self.accessibilityLabel;
//    NSLog(@"Label -> %@",accessibilityLabel);
    if ([label isEqualToString:@"表情"] || [label isEqualToString:@"at"] || [label isEqualToString:@"图片"] || [label isEqualToString:@"键盘"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
            
            UIImage *whiteImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            self.tintColor = [UIColor whiteColor];
            
            %orig(whiteImage, state);
        }else {
            %orig(image, state);
        }
    } else {
        %orig(image, state);
    }
}

%end

%hook AWETextViewInternal

- (void)drawRect:(CGRect)rect {
    %orig(rect);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        
        self.textColor = [UIColor whiteColor];
    }
}

- (double)lineSpacing {
    double r = %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        
        self.textColor = [UIColor whiteColor];
    }
    return r;
}

%end

%hook AWEPlayInteractionUserAvatarElement

- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
//    NSLog(@"拦截到关注按钮点击");
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYfollowTips"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"关注确认"
                                                  message:@"是否确认关注？"
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:@"取消"
                                           style:UIAlertActionStyleCancel
                                           handler:nil];
            
            UIAlertAction *confirmAction = [UIAlertAction
                                            actionWithTitle:@"确定"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                %orig(gesture);
            }];
            
            [alertController addAction:cancelAction];
            [alertController addAction:confirmAction];
            
            UIViewController *topController = getActiveTopController();
            if (topController) {
                [topController presentViewController:alertController animated:YES completion:nil];
            }
        });
    }else {
        %orig;
    }
}

%end

%hook AWEFeedVideoButton
- (id)touchUpInsideBlock {
    id r = %orig;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYcollectTips"] && [self.accessibilityLabel isEqualToString:@"收藏"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"收藏确认"
                                                  message:@"是否[确认/取消]收藏？"
                                                  preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:@"取消"
                                           style:UIAlertActionStyleCancel
                                           handler:nil];

            UIAlertAction *confirmAction = [UIAlertAction
                                            actionWithTitle:@"确定"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                if (r && [r isKindOfClass:NSClassFromString(@"NSBlock")]) {
                    ((void(^)(void))r)();
                }
            }];

            [alertController addAction:cancelAction];
            [alertController addAction:confirmAction];

            UIViewController *topController = getActiveTopController();
            if (topController) {
                [topController presentViewController:alertController animated:YES completion:nil];
            }
        });

        return nil; // 阻止原始 block 立即执行
    }

    return r;
}
%end

%hook AWEFeedProgressSlider

//开启视频进度条后默认显示进度条的透明度否则有部分视频不会显示进度条以及秒数
- (void)setAlpha:(CGFloat)alpha {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]) {
        alpha = 1.0;
        %orig(alpha);
    }else {
        %orig;
    }
}
//MARK: 视频显示进度条以及视频进度秒数
//新建一个左时间
%property (nonatomic, strong) UIView *leftLabelUI;
//新建一个右时间
%property (nonatomic, strong) UIView *rightLabelUI;

- (void)setLimitUpperActionArea:(BOOL)arg1 {
    %orig;
    //定义一下进度条默认算法
    NSString *duration = [self.progressSliderDelegate formatTimeFromSeconds:floor(self.progressSliderDelegate.model.videoDuration/1000)];
    //如果开启了显示时间进度
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]){
        //左时间的视图不存在就创建 50 15 大小的视图文本
        if (!self.leftLabelUI) {
            self.leftLabelUI = [[UILabel alloc] init];
            self.leftLabelUI.frame = CGRectMake(3, -12, 50, 15);
            self.leftLabelUI.backgroundColor = [UIColor clearColor];
            [(UILabel *)self.leftLabelUI setText:@"00:00"];
            [(UILabel *)self.leftLabelUI setTextColor:[UIColor whiteColor]];
            [(UILabel *)self.leftLabelUI setFont:[UIFont systemFontOfSize:10]];
            [self addSubview:self.leftLabelUI];
        }else{
            [(UILabel *)self.leftLabelUI setText:@"00:00"];
            [(UILabel *)self.leftLabelUI setTextColor:[UIColor whiteColor]];
            [(UILabel *)self.leftLabelUI setFont:[UIFont systemFontOfSize:10]];
        }
        
        // 如果rightLabelUI为空,创建右侧视图
        if (!self.rightLabelUI) {
            self.rightLabelUI = [[UILabel alloc] init];
            self.rightLabelUI.frame = CGRectMake(self.frame.size.width - 30, -12, 50, 15);
            self.rightLabelUI.backgroundColor = [UIColor clearColor];
            [(UILabel *)self.rightLabelUI setText:duration];
            [(UILabel *)self.rightLabelUI setTextColor:[UIColor whiteColor]];
            [(UILabel *)self.rightLabelUI setFont:[UIFont systemFontOfSize:10]];
            [self addSubview:self.rightLabelUI];
        }else{
            [(UILabel *)self.rightLabelUI setText:duration];
            [(UILabel *)self.rightLabelUI setTextColor:[UIColor whiteColor]];
            [(UILabel *)self.rightLabelUI setFont:[UIFont systemFontOfSize:10]];
        }
    }
}

%end
//MARK: 视频显示-算法
%hook AWEPlayInteractionProgressController
%new
//根据时间来给算法
- (NSString *)formatTimeFromSeconds:(CGFloat)seconds {
    //小时
    NSInteger hours = (NSInteger)seconds / 3600;
    //分钟
    NSInteger minutes = ((NSInteger)seconds % 3600) / 60;
    //秒数
    NSInteger secs = (NSInteger)seconds % 60;
    //定义进度条实例
    AWEFeedProgressSlider *progressSlider = self.progressSlider;
    //如果视频超过 60 分钟
    if (hours > 0) {
        //主线程设置他的显示总时间进度条位置
         dispatch_async(dispatch_get_main_queue(), ^{
            //设置右边小时进度条的位置
            progressSlider.rightLabelUI.frame = CGRectMake(progressSlider.frame.size.width - 46, -12, 50, 15);
         });
         //返回 00:00:00
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)secs];
    } else {
        //返回 00:00
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)secs];
    }
}

- (void)updateProgressSliderWithTime:(CGFloat)arg1 totalDuration:(CGFloat)arg2 {
    %orig;
    //如果开启了显示视频进度
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]){
        //获取进度条实例
        AWEFeedProgressSlider *progressSlider = self.progressSlider;
        //如果检测到时间
        if (arg1 > 0) {
            //创建左边的文本进度并且算法格式化时间
            [(UILabel *)progressSlider.leftLabelUI setText:[self formatTimeFromSeconds:arg1]];
        }
        //如果检测到时间
        if (arg2 > 0) {
            //创建右边的文本进度条并且算法格式化时间
            [(UILabel *)progressSlider.rightLabelUI setText:[self formatTimeFromSeconds:arg2]];
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

%hook AWEHPTopTabItemModel

- (void)setChannelID:(NSString *)channelID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (([channelID isEqualToString:@"homepage_hot_container"] && [defaults boolForKey:@"DYYYHideHotContainer"]) ||
        ([channelID isEqualToString:@"homepage_follow"] && [defaults boolForKey:@"DYYYHideFollow"]) ||
        ([channelID isEqualToString:@"homepage_mediumvideo"] && [defaults boolForKey:@"DYYYHideMediumVideo"]) ||
        ([channelID isEqualToString:@"homepage_mall"] && [defaults boolForKey:@"DYYYHideMall"]) ||
        ([channelID isEqualToString:@"homepage_nearby"] && [defaults boolForKey:@"DYYYHideNearby"]) ||
        ([channelID isEqualToString:@"homepage_groupon"] && [defaults boolForKey:@"DYYYHideGroupon"]) ||
        ([channelID isEqualToString:@"homepage_tablive"] && [defaults boolForKey:@"DYYYHideTabLive"]) ||
        ([channelID isEqualToString:@"homepage_pad_hot"] && [defaults boolForKey:@"DYYYHidePadHot"]) ||
        ([channelID isEqualToString:@"homepage_hangout"] && [defaults boolForKey:@"DYYYHideHangout"])) {
        return;
    }
    %orig;
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
                                       ([cityCode hasPrefix:@"11"] || [cityCode hasPrefix:@"12"] || 
                                        [cityCode hasPrefix:@"31"] || [cityCode hasPrefix:@"50"]);
                    
                    if (isDirectCity) {
                        label.text = [NSString stringWithFormat:@"%@  IP属地：%@", text, cityName];
                    } else {
                        label.text = [NSString stringWithFormat:@"%@  IP属地：%@ %@", text, provinceName, cityName];
                    }
                } else {
                    BOOL isDirectCity = [provinceName isEqualToString:cityName] || 
                                       ([cityCode hasPrefix:@"11"] || [cityCode hasPrefix:@"12"] || 
                                        [cityCode hasPrefix:@"31"] || [cityCode hasPrefix:@"50"]);
                    
                    BOOL containsProvince = [text containsString:provinceName];
                    
                    if (isDirectCity && containsProvince) {
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
    NSString *labelColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelColor"];
    if (labelColor.length > 0) {
        label.textColor = colorWithHexString(labelColor);
    }

    return label;
}

+(BOOL)shouldActiveWithData:(id)arg1 context:(id)arg2{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"];
}

%end

%hook AWEFeedRootViewController

- (BOOL)prefersStatusBarHidden {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHideStatusbar"]){
        return YES;
    } else {
        return %orig;
    }
}

%end

%hook AWEHPDiscoverFeedEntranceView
- (void)setAlpha:(CGFloat)alpha {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDiscover"]) {
        alpha = 0;
        %orig(alpha);
   }else {
       %orig;
    }
}

%end

%hook AWEUserWorkCollectionViewComponentCell

- (void)layoutSubviews {
    %orig;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMyPage"]) {
        [self removeFromSuperview];
        return;
    }
}

%end

%hook AWEFeedRefreshFooter

- (void)layoutSubviews {
    %orig;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMyPage"]) {
        [self removeFromSuperview];
        return;
    }
}

%end

%hook AWERLSegmentView

- (void)layoutSubviews {
    %orig;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMyPage"]) {
        [self removeFromSuperview];
        return;
    }
}

%end

%hook AWEFeedTemplateAnchorView

- (void)layoutSubviews {
    %orig;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLocation"]) {
        [self removeFromSuperview];
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
        self.hidden = YES;
    }
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

%hook AWEModernLongPressPanelTableViewController

- (NSArray *)dataArray {
    NSArray *originalArray = %orig;
    
    if (!originalArray) {
        originalArray = @[];
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"] && 
        ![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
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
            downloadViewModel.duxIconName = @"ic_circledown_filled_20";
            downloadViewModel.describeString = @"保存视频";
            
            downloadViewModel.action = ^{
                AWEAwemeModel *awemeModel = self.awemeModel;
                AWEVideoModel *videoModel = awemeModel.video;
                AWEMusicModel *musicModel = awemeModel.music;
                
                if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
                    NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
                    downloadMedia(url, MediaTypeVideo, ^{
                        showToast(@"视频已保存到相册");
                    });
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
            coverViewModel.duxIconName = @"ic_circledown_filled_20";
            coverViewModel.describeString = @"保存封面";
            
            coverViewModel.action = ^{
                AWEAwemeModel *awemeModel = self.awemeModel;
                AWEVideoModel *videoModel = awemeModel.video;
                
                if (videoModel && videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
                    NSURL *url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
                    downloadMedia(url, MediaTypeImage, ^{
                        showToast(@"封面已保存到相册");
                    });
                }
                
                AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
                [panelManager dismissWithAnimation:YES completion:nil];
            };
            
            [viewModels addObject:coverViewModel];
        }
        
        AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        audioViewModel.awemeModel = self.awemeModel;
        audioViewModel.actionType = 668;
        audioViewModel.duxIconName = @"ic_circledown_filled_20";
        audioViewModel.describeString = @"保存音频";
        
        audioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEMusicModel *musicModel = awemeModel.music;
            
            if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
                NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
                downloadMedia(url, MediaTypeAudio, nil);
            }
            
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        
        [viewModels addObject:audioViewModel];
        
        if (self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
            AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
            imageViewModel.awemeModel = self.awemeModel;
            imageViewModel.actionType = 669;
            imageViewModel.duxIconName = @"ic_circledown_filled_20";
            imageViewModel.describeString = @"保存当前图片";
            
            imageViewModel.action = ^{
                AWEAwemeModel *awemeModel = self.awemeModel;
                AWEImageAlbumImageModel *currentImageModel = nil;
                
                if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                    currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
                } else {
                    currentImageModel = awemeModel.albumImages.firstObject;
                }
                
                if (currentImageModel && currentImageModel.urlList.count > 0) {
                    NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
                    downloadMedia(url, MediaTypeImage, ^{
                        showToast(@"图片已保存到相册");
                    });
                }
                
                AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
                [panelManager dismissWithAnimation:YES completion:nil];
            };
            
            [viewModels addObject:imageViewModel];
            
            if (self.awemeModel.albumImages.count > 1) {
                AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
                allImagesViewModel.awemeModel = self.awemeModel;
                allImagesViewModel.actionType = 670;
                allImagesViewModel.duxIconName = @"ic_circledown_filled_20";
                allImagesViewModel.describeString = @"保存所有图片";
                
                allImagesViewModel.action = ^{
                    AWEAwemeModel *awemeModel = self.awemeModel;
                    NSMutableArray *imageURLs = [NSMutableArray array];
                    
                    for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                        if (imageModel.urlList.count > 0) {
                            [imageURLs addObject:imageModel.urlList.firstObject];
                        }
                    }
                    
                    if (imageURLs.count > 0) {
                        downloadAllImages(imageURLs);
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
            showToast(@"文案已复制到剪贴板");
            
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        
        [viewModels addObject:copyText];
    }
    
    newGroupModel.groupArr = viewModels;
    
    return [@[newGroupModel] arrayByAddingObjectsFromArray:originalArray];
}

%end

%hook AWELongPressPanelTableViewController

- (NSArray *)dataArray {
    NSArray *originalArray = %orig;
    
    if (!originalArray) {
        originalArray = @[];
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"] && 
        ![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
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
            downloadViewModel.duxIconName = @"ic_circledown_filled_20";
            downloadViewModel.describeString = @"保存视频";
            
            downloadViewModel.action = ^{
                AWEAwemeModel *awemeModel = self.awemeModel;
                AWEVideoModel *videoModel = awemeModel.video;
                AWEMusicModel *musicModel = awemeModel.music;
                
                if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
                    NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
                    downloadMedia(url, MediaTypeVideo, ^{
                        showToast(@"视频已保存到相册");
                    });
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
            coverViewModel.duxIconName = @"ic_circledown_filled_20";
            coverViewModel.describeString = @"保存封面";
            
            coverViewModel.action = ^{
                AWEAwemeModel *awemeModel = self.awemeModel;
                AWEVideoModel *videoModel = awemeModel.video;
                
                if (videoModel && videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
                    NSURL *url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
                    downloadMedia(url, MediaTypeImage, ^{
                        showToast(@"封面已保存到相册");
                    });
                }
                
                AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
                [panelManager dismissWithAnimation:YES completion:nil];
            };
            
            [viewModels addObject:coverViewModel];
        }
        
        AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        audioViewModel.awemeModel = self.awemeModel;
        audioViewModel.actionType = 668;
        audioViewModel.duxIconName = @"ic_circledown_filled_20";
        audioViewModel.describeString = @"保存音频";
        
        audioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEMusicModel *musicModel = awemeModel.music;
            
            if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
                NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
                downloadMedia(url, MediaTypeAudio, nil);
            }
            
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        
        [viewModels addObject:audioViewModel];
        
        if (self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
            AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
            imageViewModel.awemeModel = self.awemeModel;
            imageViewModel.actionType = 669;
            imageViewModel.duxIconName = @"ic_circledown_filled_20";
            imageViewModel.describeString = @"保存当前图片";
            
            imageViewModel.action = ^{
                AWEAwemeModel *awemeModel = self.awemeModel;
                AWEImageAlbumImageModel *currentImageModel = nil;
                
                if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                    currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
                } else {
                    currentImageModel = awemeModel.albumImages.firstObject;
                }
                
                if (currentImageModel && currentImageModel.urlList.count > 0) {
                    NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
                    downloadMedia(url, MediaTypeImage, ^{
                        showToast(@"图片已保存到相册");
                    });
                }
                
                AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
                [panelManager dismissWithAnimation:YES completion:nil];
            };
            
            [viewModels addObject:imageViewModel];
            
            if (self.awemeModel.albumImages.count > 1) {
                AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
                allImagesViewModel.awemeModel = self.awemeModel;
                allImagesViewModel.actionType = 670;
                allImagesViewModel.duxIconName = @"ic_circledown_filled_20";
                allImagesViewModel.describeString = @"保存所有图片";
                
                allImagesViewModel.action = ^{
                    AWEAwemeModel *awemeModel = self.awemeModel;
                    NSMutableArray *imageURLs = [NSMutableArray array];
                    
                    for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                        if (imageModel.urlList.count > 0) {
                            [imageURLs addObject:imageModel.urlList.firstObject];
                        }
                    }
                    
                    if (imageURLs.count > 0) {
                        downloadAllImages(imageURLs);
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
            showToast(@"文案已复制到剪贴板");
            
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        
        [viewModels addObject:copyText];
    }
    
    newGroupModel.groupArr = viewModels;
    
    return [@[newGroupModel] arrayByAddingObjectsFromArray:originalArray];
}

%end

%hook AWEElementStackView
static CGFloat right_tx = 0;
static CGFloat left_tx = 0;
static CGFloat currentScale = 1.0;
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
                self.frame = frame;
            }
        }
    }

    NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYElementScale"];
    if ([self.accessibilityLabel isEqualToString:@"right"]) {
        if (scaleValue.length > 0) {
            CGFloat scale = [scaleValue floatValue];
            if(currentScale !=  scale){
                currentScale = scale;
                right_tx = 0;
                left_tx = 0;
            }
            if (scale > 0 && scale != 1.0) {
                CGFloat ty = 0;
                for(UIView *view in self.subviews){
                    ty += (view.frame.size.height - view.frame.size.height * scale)/2;
                }
                if(right_tx == 0){
                    right_tx = (self.frame.size.width - self.frame.size.width * scale)/2;
                }
                self.transform = CGAffineTransformMake(scale, 0, 0, scale, right_tx, ty);
            }
        }
    }
    if ([self.accessibilityLabel isEqualToString:@"left"]) {
        NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYElementScale"];
        if (scaleValue.length > 0) {
            CGFloat scale = [scaleValue floatValue];
            if (scale > 0 && scale != 1.0) {
                CGFloat ty = 0;
                for(UIView *view in self.subviews){
                    ty += (view.frame.size.height - view.frame.size.height * scale)/2;
                }
                if(left_tx == 0){
                    left_tx = (self.frame.size.width - self.frame.size.width * scale)/2 - self.frame.size.width * (1 -scale);
                }
                self.transform = CGAffineTransformMake(scale, 0, 0, scale, left_tx, ty);
            }
        }
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
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dyyyFolderPath 
                            withIntermediateDirectories:YES 
                                             attributes:nil 
                                                  error:nil];
    
    NSDictionary *iconMapping = @{
        @"icon_home_like_after": @"like_after.png",
        @"icon_home_like_before": @"like_before.png",
        @"icon_home_comment": @"comment.png",
        @"icon_home_unfavorite": @"unfavorite.png",
        @"icon_home_favorite": @"favorite.png",
        @"iconHomeShareRight": @"share.png"
    };
    
    NSString *customFileName = nil;
    for (NSString *prefix in iconMapping.allKeys) {
        if (([nameString hasPrefix:prefix]) || ([nameString containsString:@"_comment"])) {
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
-(id)downloadUrl{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCommentNotWaterMark"]) {
        return self.originUrl;
    }
    return %orig;
}
%end

%hook _TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement

static BOOL isDownloadFlied = NO;

-(BOOL)elementShouldShow{
    BOOL DYYYFourceDownloadEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYFourceDownloadEmotion"];
    if(DYYYFourceDownloadEmotion){
        AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
        AWECommentModel *selectdComment = [commentPageContext selectdComment];
        if(!selectdComment){
            AWECommentLongPressPanelParam *params = [commentPageContext params];
            selectdComment = [params selectdComment];
        }
        AWEIMStickerModel *sticker = [selectdComment sticker];
        if(sticker){
            AWEURLModel *staticURLModel = [sticker staticURLModel];
            NSArray *originURLList = [staticURLModel originURLList];
            if (originURLList.count > 0) {
                return YES;
            }
        }
    }
    return %orig;
}

-(void)elementTapped{
    BOOL DYYYFourceDownloadEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYFourceDownloadEmotion"];
    if(DYYYFourceDownloadEmotion){
        AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
        AWECommentModel *selectdComment = [commentPageContext selectdComment];
        if(!selectdComment){
            AWECommentLongPressPanelParam *params = [commentPageContext params];
            selectdComment = [params selectdComment];
        }
        AWEIMStickerModel *sticker = [selectdComment sticker];
        if(sticker){
            AWEURLModel *staticURLModel = [sticker staticURLModel];
            NSArray *originURLList = [staticURLModel originURLList];
            if (originURLList.count > 0) {
                NSString *urlString = @"";
                if(isDownloadFlied){
                    urlString = originURLList[originURLList.count-1];
                    isDownloadFlied = NO;
                }else{
                    urlString = originURLList[0];
                }

                NSURL *heifURL = [NSURL URLWithString:urlString];
                downloadMedia(heifURL, MediaTypeHeic, ^{
                    showToast(@"表情包已保存到相册");
                    });
                return;
            }
        }
    }
    %orig;
}
%end

%ctor {
    %init(DYYYSettingsGesture);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
        %init;
    }
}


