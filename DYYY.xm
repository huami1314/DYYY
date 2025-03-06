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
@interface AWENormalModeTabBarGeneralButton : UIButton
@end

@interface AWENormalModeTabBarBadgeContainerView : UIView

@end

@interface AWEFeedContainerContentView : UIView
- (UIViewController *)findViewController:(UIViewController *)vc ofClass:(Class)targetClass;
@end

@interface AWELeftSideBarEntranceView : UIView
@end

@interface AWEDanmakuContentLabel : UILabel
- (UIColor *)colorFromHexString:(NSString *)hexString baseColor:(UIColor *)baseColor;
@end

@interface AWELandscapeFeedEntryView : UIView
@end

@interface AWEPlayInteractionViewController : UIViewController
@property (nonatomic, strong) UIView *view;
@end

@interface UIView (Transparency)
- (UIViewController *)firstAvailableUIViewController;
@end

@interface AWEFeedVideoButton : UIButton
@end

@interface AWEMusicCoverButton : UIButton
@end

@interface AWEAwemePlayVideoViewController : UIViewController

- (void)setVideoControllerPlaybackRate:(double)arg0;

@end

@interface AWEDanmakuItemTextInfo : NSObject
- (void)setDanmakuTextColor:(id)arg1;
- (UIColor *)colorFromHexStringForTextInfo:(NSString *)hexString;
@end

@interface AWECommentMiniEmoticonPanelView : UIView

@end

@interface AWEBaseElementView : UIView

@end

@interface AWETextViewInternal : UITextView

@end

@interface AWECommentPublishGuidanceView : UIView

@end

@interface AWEPlayInteractionFollowPromptView : UIView

@end

@interface AWENormalModeTabBarTextView : UIView

@end

@interface AWEPlayInteractionProgressController : UIView
//- (void)writeLog:(NSString *)log;
- (UIViewController *)findViewController:(UIViewController *)vc ofClass:(Class)targetClass;
@end

@interface AWEAdAvatarView : UIView

@end

@interface AWENormalModeTabBar : UIView

@end

@interface AWEPlayInteractionListenFeedView : UIView

@end

@interface AWEFeedLiveMarkView : UIView

@end

@interface AWEAwemeModel : NSObject
@property (nonatomic, copy) NSString *ipAttribution;
@property (nonatomic, copy) NSString *cityCode;
@end

@interface AWEPlayInteractionTimestampElement : UIView
@property (nonatomic, strong) AWEAwemeModel *model;
@end

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
            Class FeedTableVC = NSClassFromString(@"AWEFeedTableViewController");
            UIViewController *feedVC = nil;
            
            UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
            if (keyWindow && keyWindow.rootViewController) {
                feedVC = [self findViewController:keyWindow.rootViewController ofClass:FeedTableVC];
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
    return [UIColor colorWithRed:(red / 255.0) green:(green / 255.0) blue:(blue / 255.0) alpha:CGColorGetAlpha(baseColor.CGColor)];
}
%end

%hook AWEDanmakuItemTextInfo
- (void)setDanmakuTextColor:(id)arg1 {
//    NSLog(@"Original Color: %@", arg1);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"]) {
        NSString *danmuColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYdanmuColor"];
        
        if ([danmuColor.lowercaseString isEqualToString:@"random"] || [danmuColor.lowercaseString isEqualToString:@"#random"]) {
            arg1 = [UIColor colorWithRed:(arc4random_uniform(256)) / 255.0
                                   green:(arc4random_uniform(256)) / 255.0
                                    blue:(arc4random_uniform(256)) / 255.0
                                   alpha:1.0];
//            NSLog(@"Random Color: %@", arg1);
        } else if ([danmuColor hasPrefix:@"#"]) {
            arg1 = [self colorFromHexStringForTextInfo:danmuColor];
//            NSLog(@"Custom Hex Color: %@", arg1);
        } else {
            arg1 = [self colorFromHexStringForTextInfo:@"#FFFFFF"];
//            NSLog(@"Default White Color: %@", arg1);
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
    return [UIColor colorWithRed:(red / 255.0) green:(green / 255.0) blue:(blue / 255.0) alpha:1.0];
}
%end

//%hook UIWindow
//- (instancetype)initWithFrame:(CGRect)frame {
//    UIWindow *window = %orig(frame);
//    if (window) {
//        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
//        doubleTapGesture.numberOfTapsRequired = 1;
//        doubleTapGesture.numberOfTouchesRequired = 3;
//        [window addGestureRecognizer:doubleTapGesture];
//    }
//    return window;
//}
//
//%new
//- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)gesture {
//    if (gesture.state == UIGestureRecognizerStateRecognized) {
//        UIViewController *rootViewController = self.rootViewController;
//        if (rootViewController) {
//            UIViewController *settingVC = [[NSClassFromString(@"DYYYSettingViewController") alloc] init];
//            if (settingVC) {
//                [rootViewController presentViewController:settingVC animated:YES completion:nil];
//            }
//        }
//    }
//}
//%end

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
            UIViewController *settingVC = [[NSClassFromString(@"DYYYSettingViewController") alloc] init];
            
            if (settingVC) {
                settingVC.modalPresentationStyle = UIModalPresentationFullScreen;
                
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

    BOOL hideLikeButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeButton"];
    BOOL hideCommentButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentButton"];
    BOOL hideCollectButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectButton"];
    BOOL hideShareButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareButton"];

    NSString *accessibilityLabel = self.accessibilityLabel;

//    NSLog(@"Accessibility Label: %@", accessibilityLabel);

    if ([accessibilityLabel isEqualToString:@"点赞"]) {
        if (hideLikeButton) {
            [self removeFromSuperview];
            return;
        }
    } else if ([accessibilityLabel isEqualToString:@"评论"]) {
        if (hideCommentButton) {
            [self removeFromSuperview];
            return;
        }
    } else if ([accessibilityLabel isEqualToString:@"分享"]) {
        if (hideShareButton) {
            [self removeFromSuperview];
            return;
        }
    } else if ([accessibilityLabel isEqualToString:@"收藏"]) {
        if (hideCollectButton) {
            [self removeFromSuperview];
            return;
        }
    }

}

%end

%hook AWEMusicCoverButton

- (void)layoutSubviews {
    %orig;

    BOOL hideMusicButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMusicButton"];

    NSString *accessibilityLabel = self.accessibilityLabel;

//    NSLog(@"Accessibility Label: %@", accessibilityLabel);

    if ([accessibilityLabel isEqualToString:@"音乐详情"]) {
        if (hideMusicButton) {
            [self removeFromSuperview];
            return;
        }
    }
}

%end

%hook AWEPlayInteractionListenFeedView
- (void)layoutSubviews {
    %orig;
    BOOL hideMusicButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMusicButton"];
    if (hideMusicButton) {
        [self removeFromSuperview];
        return;
    }
}
%end

%hook AWEPlayInteractionFollowPromptView

- (void)layoutSubviews {
    %orig;

    BOOL hideAvatarButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"];

    NSString *accessibilityLabel = self.accessibilityLabel;

//    NSLog(@"Accessibility Label: %@", accessibilityLabel);

    if ([accessibilityLabel isEqualToString:@"关注"]) {
        if (hideAvatarButton) {
            [self removeFromSuperview];
            return;
        }
    }
}

%end

%hook AWEAdAvatarView

- (void)layoutSubviews {
    %orig;

    BOOL hideAvatarButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"];
    if (hideAvatarButton) {
        [self removeFromSuperview];
        return;
    }
}

%end

%hook AWENormalModeTabBar

- (void)layoutSubviews {
    %orig;

    // 获取用户设置
    BOOL hideShop = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShopButton"];
    BOOL hideMsg = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMessageButton"];
    BOOL hideFri = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFriendsButton"];
    
    NSMutableArray *visibleButtons = [NSMutableArray array];
    Class generalButtonClass = %c(AWENormalModeTabBarGeneralButton);
    Class plusButtonClass = %c(AWENormalModeTabBarGeneralPlusButton);
    
    // 遍历所有子视图处理隐藏逻辑
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

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenBottomBg"]) {
        for (UIView *subview in self.subviews) {
            if ([subview class] == [UIView class]) {  // 确保是真正的UIView而不是子类
                BOOL hasImageView = NO;
                for (UIView *childView in subview.subviews) {
                    if ([childView isKindOfClass:[UIImageView class]]) {
                        hasImageView = YES;
                        break;
                    }
                }
                
                if (hasImageView) {
                    subview.hidden = YES;
                    break;  // 只隐藏第一个符合条件的视图
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
            
            UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (topController.presentedViewController) {
                topController = topController.presentedViewController;
            }
            [topController presentViewController:alertController animated:YES completion:nil];
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

            UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (topController.presentedViewController) {
                topController = topController.presentedViewController;
            }
            [topController presentViewController:alertController animated:YES completion:nil];
        });

        return nil; // 阻止原始 block 立即执行
    }

    return r;
}
%end

%hook AWEFeedProgressSlider

- (void)setAlpha:(CGFloat)alpha {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowSchedule"]) {
        alpha = 1.0;
        %orig(alpha);
    }else {
        %orig;
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
-(id)timestampLabel{
    UILabel *label = %orig;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"]){
        NSString *text = label.text;
        AWEAwemeModel *model = self.model;
        NSString *ipAttribution = model.ipAttribution;
        NSString *cityCode = model.cityCode;
        if (!ipAttribution && cityCode) {
            NSString *provinceName = [CityManager.sharedInstance getProvinceNameWithCode:cityCode] ?: @"";
            NSString *cityName = [CityManager.sharedInstance getCityNameWithCode:cityCode] ?: @"";
            
            if (cityName.length > 0) {
                if ([provinceName isEqualToString:cityName]) {
                    label.text = [NSString stringWithFormat:@"%@  IP属地：%@", text, cityName];
                } else {
                    label.text = [NSString stringWithFormat:@"%@  IP属地：%@ %@", text, provinceName, cityName];
                }
            }
        } else {
            label.text = text; 
        }
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

//%ctor {
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        [defaults registerDefaults:@{@"isShowDYYYAlert": @(NO)}];
//
//        if (![defaults boolForKey:@"isShowDYYYAlert"]) {
//            [defaults setBool:YES forKey:@"isShowDYYYAlert"];
//            [defaults synchronize];
//
//            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"by @huamidev"
//                                                                           message:@"仅供学习交流 请在24小时内删除\n弹窗只会显示一次"
//                                                                    preferredStyle:UIAlertControllerStyleAlert];
//
//            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
//            [alert addAction:okAction];
//
//            UIAlertAction *goToChannelAction = [UIAlertAction actionWithTitle:@"前往频道" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                UIApplication *application = [UIApplication sharedApplication];
//                NSURL *tgTestURL = [NSURL URLWithString:@"tg://"];
//                NSURL *telegramTestURL = [NSURL URLWithString:@"telegram://"];
//
//                if ([application canOpenURL:tgTestURL] || [application canOpenURL:telegramTestURL]) {
//                    NSURL *tgURL = [NSURL URLWithString:@"tg://resolve?domain=huamidev"];
//                    [application openURL:tgURL options:@{} completionHandler:nil];
//                } else {
//                    NSURL *webURL = [NSURL URLWithString:@"https://t.me/huamidev"];
//                    [application openURL:webURL options:@{} completionHandler:nil];
//                }
//            }];
//            [alert addAction:goToChannelAction];
//
//            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
//            [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
//        }
//    });
//}

