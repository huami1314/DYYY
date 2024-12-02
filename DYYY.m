#line 1 "/Users/huami/Desktop/DYYY/DYYY/DYYY/DYYY.x"







#import <UIKit/UIKit.h>

@interface AWENormalModeTabBarGeneralButton : UIButton
@end

@interface AWENormalModeTabBarBadgeContainerView : UIView

@end

@interface AWEFeedContainerContentView : UIView
@end

@interface AWELeftSideBarEntranceView : UIView
@end

@interface AWEDanmakuContentLabel : UILabel
- (UIColor *)colorFromHexString:(NSString *)hexString baseColor:(UIColor *)baseColor;
@end

@interface AWELandscapeFeedEntryView : UIView
@end

@interface AWEPlayInteractionViewController : UIViewController
@end

@interface AWEFeedVideoButton : UIButton
@end

@interface AWEAwemePlayVideoViewController : UIViewController

- (void)setVideoControllerPlaybackRate:(double)arg0;

@end



#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

__asm__(".linker_option \"-framework\", \"CydiaSubstrate\"");

@class AWEDanmakuContentLabel; @class AWEAwemePlayVideoViewController; @class UIWindow; @class AWENormalModeTabBarBadgeContainerView; @class AWELongVideoControlModel; @class AWEAwemeModel; @class AWENormalModeTabBarGeneralPlusButton; @class AWEFeedVideoButton; @class AWELandscapeFeedEntryView; @class AWEPlayInteractionViewController; @class AWEFeedContainerContentView; @class AWELeftSideBarEntranceView; 
static void (*_logos_orig$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$)(_LOGOS_SELF_TYPE_NORMAL AWEAwemePlayVideoViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$(_LOGOS_SELF_TYPE_NORMAL AWEAwemePlayVideoViewController* _LOGOS_SELF_CONST, SEL, BOOL); static id (*_logos_meta_orig$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static id _logos_meta_method$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWEFeedContainerContentView$setAlpha$)(_LOGOS_SELF_TYPE_NORMAL AWEFeedContainerContentView* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$_ungrouped$AWEFeedContainerContentView$setAlpha$(_LOGOS_SELF_TYPE_NORMAL AWEFeedContainerContentView* _LOGOS_SELF_CONST, SEL, CGFloat); static void (*_logos_orig$_ungrouped$AWEDanmakuContentLabel$setTextColor$)(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuContentLabel* _LOGOS_SELF_CONST, SEL, UIColor *); static void _logos_method$_ungrouped$AWEDanmakuContentLabel$setTextColor$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuContentLabel* _LOGOS_SELF_CONST, SEL, UIColor *); static UIColor * _logos_method$_ungrouped$AWEDanmakuContentLabel$colorFromHexString$baseColor$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuContentLabel* _LOGOS_SELF_CONST, SEL, NSString *, UIColor *); static UIWindow* (*_logos_orig$_ungrouped$UIWindow$initWithFrame$)(_LOGOS_SELF_TYPE_INIT UIWindow*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static UIWindow* _logos_method$_ungrouped$UIWindow$initWithFrame$(_LOGOS_SELF_TYPE_INIT UIWindow*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static void _logos_method$_ungrouped$UIWindow$handleDoubleFingerLongPressGesture$(_LOGOS_SELF_TYPE_NORMAL UIWindow* _LOGOS_SELF_CONST, SEL, UILongPressGestureRecognizer *); static void _logos_method$_ungrouped$UIWindow$closeSettings$(_LOGOS_SELF_TYPE_NORMAL UIWindow* _LOGOS_SELF_CONST, SEL, UIButton *); static bool (*_logos_orig$_ungrouped$AWELongVideoControlModel$allowDownload)(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST, SEL); static bool _logos_method$_ungrouped$AWELongVideoControlModel$allowDownload(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST, SEL); static long long (*_logos_orig$_ungrouped$AWELongVideoControlModel$preventDownloadType)(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST, SEL); static long long _logos_method$_ungrouped$AWELongVideoControlModel$preventDownloadType(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWELandscapeFeedEntryView$setHidden$)(_LOGOS_SELF_TYPE_NORMAL AWELandscapeFeedEntryView* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$AWELandscapeFeedEntryView$setHidden$(_LOGOS_SELF_TYPE_NORMAL AWELandscapeFeedEntryView* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$)(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWEAwemeModel$setIsAds$)(_LOGOS_SELF_TYPE_NORMAL AWEAwemeModel* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$AWEAwemeModel$setIsAds$(_LOGOS_SELF_TYPE_NORMAL AWEAwemeModel* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWENormalModeTabBarBadgeContainerView* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWENormalModeTabBarBadgeContainerView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWELeftSideBarEntranceView* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWELeftSideBarEntranceView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWEFeedVideoButton$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWEFeedVideoButton* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWEFeedVideoButton$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWEFeedVideoButton* _LOGOS_SELF_CONST, SEL); 

#line 43 "/Users/huami/Desktop/DYYY/DYYY/DYYY/DYYY.x"


static void _logos_method$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$(_LOGOS_SELF_TYPE_NORMAL AWEAwemePlayVideoViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL arg0) {
    float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];
    
    if (defaultSpeed > 0) {
        [self setVideoControllerPlaybackRate:defaultSpeed];
    } else {
        [self setVideoControllerPlaybackRate:1.0];
    }
    
    _logos_orig$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$(self, _cmd, arg0);
}





static id _logos_meta_method$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    BOOL isHiddenJia = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenJia"];
    if (isHiddenJia) {
        return nil;
    }
    return _logos_meta_orig$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button(self, _cmd);
}



static void _logos_method$_ungrouped$AWEFeedContainerContentView$setAlpha$(_LOGOS_SELF_TYPE_NORMAL AWEFeedContainerContentView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat alpha) {
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYtopbartransparent"];
    if (transparentValue) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {
            _logos_orig$_ungrouped$AWEFeedContainerContentView$setAlpha$(self, _cmd, alphaValue);
        } else {
            _logos_orig$_ungrouped$AWEFeedContainerContentView$setAlpha$(self, _cmd, 1.0);
        }
    } else {
        _logos_orig$_ungrouped$AWEFeedContainerContentView$setAlpha$(self, _cmd, 1.0);
    }
}



static void _logos_method$_ungrouped$AWEDanmakuContentLabel$setTextColor$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuContentLabel* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIColor * textColor) {
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

    _logos_orig$_ungrouped$AWEDanmakuContentLabel$setTextColor$(self, _cmd, textColor);
}


static UIColor * _logos_method$_ungrouped$AWEDanmakuContentLabel$colorFromHexString$baseColor$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuContentLabel* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * hexString, UIColor * baseColor) {
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





























static UIWindow* _logos_method$_ungrouped$UIWindow$initWithFrame$(_LOGOS_SELF_TYPE_INIT UIWindow* __unused self, SEL __unused _cmd, CGRect frame) _LOGOS_RETURN_RETAINED {
    UIWindow *window = _logos_orig$_ungrouped$UIWindow$initWithFrame$(self, _cmd, frame);
    if (window) {
        UILongPressGestureRecognizer *doubleFingerLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleFingerLongPressGesture:)];
        doubleFingerLongPressGesture.numberOfTouchesRequired = 2;
        [window addGestureRecognizer:doubleFingerLongPressGesture];
    }
    return window;
}


static void _logos_method$_ungrouped$UIWindow$handleDoubleFingerLongPressGesture$(_LOGOS_SELF_TYPE_NORMAL UIWindow* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UILongPressGestureRecognizer * gesture) {
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

static void _logos_method$_ungrouped$UIWindow$closeSettings$(_LOGOS_SELF_TYPE_NORMAL UIWindow* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIButton * button) {
    [button.superview.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}





static bool _logos_method$_ungrouped$AWELongVideoControlModel$allowDownload(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return YES;
}



static long long _logos_method$_ungrouped$AWELongVideoControlModel$preventDownloadType(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return 0;
}



static void _logos_method$_ungrouped$AWELandscapeFeedEntryView$setHidden$(_LOGOS_SELF_TYPE_NORMAL AWELandscapeFeedEntryView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL hidden) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenEntry"]) {
        hidden = YES;
    }
    
    _logos_orig$_ungrouped$AWELandscapeFeedEntryView$setHidden$(self, _cmd, hidden);
}




static void _logos_method$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL animated) {
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYGlobalTransparency"];
    if (transparentValue) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue == 1.0) {
            _logos_orig$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$(self, _cmd, animated);
        } else if (alphaValue >= 0.0 && alphaValue < 1.0) {
            _logos_orig$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$(self, _cmd, animated);
            self.view.alpha = alphaValue;
        } else {
            _logos_orig$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$(self, _cmd, animated);
        }
    } else {
        _logos_orig$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$(self, _cmd, animated);
    }

}

static void _logos_method$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYGlobalTransparency"];
    if (transparentValue) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue == 1.0) {
            _logos_orig$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews(self, _cmd);
        } else if (alphaValue >= 0.0 && alphaValue < 1.0) {
            _logos_orig$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews(self, _cmd);
            self.view.alpha = alphaValue;
        } else {
            _logos_orig$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews(self, _cmd);
        }
    } else {
        _logos_orig$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews(self, _cmd);
    }

}





static void _logos_method$_ungrouped$AWEAwemeModel$setIsAds$(_LOGOS_SELF_TYPE_NORMAL AWEAwemeModel* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL isAds) {
    _logos_orig$_ungrouped$AWEAwemeModel$setIsAds$(self, _cmd, NO);
}






static void _logos_method$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWENormalModeTabBarBadgeContainerView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews(self, _cmd);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenBottomDot"]) {
        for (UIView *subview in [self subviews]) {
            if ([subview isKindOfClass:NSClassFromString(@"DUXBadge")]) {
                [subview setHidden:YES];
            }
        }
    }
}





static void _logos_method$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWELeftSideBarEntranceView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews(self, _cmd);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenSidebarDot"]) {
        for (UIView *subview in [self subviews]) {
            if ([subview isKindOfClass:NSClassFromString(@"DUXBadge")]) {
                subview.hidden = YES;
            }
        }
    }
}






static void _logos_method$_ungrouped$AWEFeedVideoButton$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWEFeedVideoButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$_ungrouped$AWEFeedVideoButton$layoutSubviews(self, _cmd);

    BOOL hideLikeButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeButton"];
    BOOL hideCommentButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentButton"];
    BOOL hideCollectButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectButton"];
    BOOL hideShareButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareButton"];

    NSString *accessibilityLabel = self.accessibilityLabel;



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










































static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$AWEAwemePlayVideoViewController = objc_getClass("AWEAwemePlayVideoViewController"); { MSHookMessageEx(_logos_class$_ungrouped$AWEAwemePlayVideoViewController, @selector(setIsAutoPlay:), (IMP)&_logos_method$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$, (IMP*)&_logos_orig$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$);}Class _logos_class$_ungrouped$AWENormalModeTabBarGeneralPlusButton = objc_getClass("AWENormalModeTabBarGeneralPlusButton"); Class _logos_metaclass$_ungrouped$AWENormalModeTabBarGeneralPlusButton = object_getClass(_logos_class$_ungrouped$AWENormalModeTabBarGeneralPlusButton); { MSHookMessageEx(_logos_metaclass$_ungrouped$AWENormalModeTabBarGeneralPlusButton, @selector(button), (IMP)&_logos_meta_method$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button, (IMP*)&_logos_meta_orig$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button);}Class _logos_class$_ungrouped$AWEFeedContainerContentView = objc_getClass("AWEFeedContainerContentView"); { MSHookMessageEx(_logos_class$_ungrouped$AWEFeedContainerContentView, @selector(setAlpha:), (IMP)&_logos_method$_ungrouped$AWEFeedContainerContentView$setAlpha$, (IMP*)&_logos_orig$_ungrouped$AWEFeedContainerContentView$setAlpha$);}Class _logos_class$_ungrouped$AWEDanmakuContentLabel = objc_getClass("AWEDanmakuContentLabel"); { MSHookMessageEx(_logos_class$_ungrouped$AWEDanmakuContentLabel, @selector(setTextColor:), (IMP)&_logos_method$_ungrouped$AWEDanmakuContentLabel$setTextColor$, (IMP*)&_logos_orig$_ungrouped$AWEDanmakuContentLabel$setTextColor$);}{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(UIColor *), strlen(@encode(UIColor *))); i += strlen(@encode(UIColor *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSString *), strlen(@encode(NSString *))); i += strlen(@encode(NSString *)); memcpy(_typeEncoding + i, @encode(UIColor *), strlen(@encode(UIColor *))); i += strlen(@encode(UIColor *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$AWEDanmakuContentLabel, @selector(colorFromHexString:baseColor:), (IMP)&_logos_method$_ungrouped$AWEDanmakuContentLabel$colorFromHexString$baseColor$, _typeEncoding); }Class _logos_class$_ungrouped$UIWindow = objc_getClass("UIWindow"); { MSHookMessageEx(_logos_class$_ungrouped$UIWindow, @selector(initWithFrame:), (IMP)&_logos_method$_ungrouped$UIWindow$initWithFrame$, (IMP*)&_logos_orig$_ungrouped$UIWindow$initWithFrame$);}{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UILongPressGestureRecognizer *), strlen(@encode(UILongPressGestureRecognizer *))); i += strlen(@encode(UILongPressGestureRecognizer *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$UIWindow, @selector(handleDoubleFingerLongPressGesture:), (IMP)&_logos_method$_ungrouped$UIWindow$handleDoubleFingerLongPressGesture$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIButton *), strlen(@encode(UIButton *))); i += strlen(@encode(UIButton *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$UIWindow, @selector(closeSettings:), (IMP)&_logos_method$_ungrouped$UIWindow$closeSettings$, _typeEncoding); }Class _logos_class$_ungrouped$AWELongVideoControlModel = objc_getClass("AWELongVideoControlModel"); { MSHookMessageEx(_logos_class$_ungrouped$AWELongVideoControlModel, @selector(allowDownload), (IMP)&_logos_method$_ungrouped$AWELongVideoControlModel$allowDownload, (IMP*)&_logos_orig$_ungrouped$AWELongVideoControlModel$allowDownload);}{ MSHookMessageEx(_logos_class$_ungrouped$AWELongVideoControlModel, @selector(preventDownloadType), (IMP)&_logos_method$_ungrouped$AWELongVideoControlModel$preventDownloadType, (IMP*)&_logos_orig$_ungrouped$AWELongVideoControlModel$preventDownloadType);}Class _logos_class$_ungrouped$AWELandscapeFeedEntryView = objc_getClass("AWELandscapeFeedEntryView"); { MSHookMessageEx(_logos_class$_ungrouped$AWELandscapeFeedEntryView, @selector(setHidden:), (IMP)&_logos_method$_ungrouped$AWELandscapeFeedEntryView$setHidden$, (IMP*)&_logos_orig$_ungrouped$AWELandscapeFeedEntryView$setHidden$);}Class _logos_class$_ungrouped$AWEPlayInteractionViewController = objc_getClass("AWEPlayInteractionViewController"); { MSHookMessageEx(_logos_class$_ungrouped$AWEPlayInteractionViewController, @selector(viewDidAppear:), (IMP)&_logos_method$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$, (IMP*)&_logos_orig$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$);}{ MSHookMessageEx(_logos_class$_ungrouped$AWEPlayInteractionViewController, @selector(viewWillLayoutSubviews), (IMP)&_logos_method$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews);}Class _logos_class$_ungrouped$AWEAwemeModel = objc_getClass("AWEAwemeModel"); { MSHookMessageEx(_logos_class$_ungrouped$AWEAwemeModel, @selector(setIsAds:), (IMP)&_logos_method$_ungrouped$AWEAwemeModel$setIsAds$, (IMP*)&_logos_orig$_ungrouped$AWEAwemeModel$setIsAds$);}Class _logos_class$_ungrouped$AWENormalModeTabBarBadgeContainerView = objc_getClass("AWENormalModeTabBarBadgeContainerView"); { MSHookMessageEx(_logos_class$_ungrouped$AWENormalModeTabBarBadgeContainerView, @selector(layoutSubviews), (IMP)&_logos_method$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews);}Class _logos_class$_ungrouped$AWELeftSideBarEntranceView = objc_getClass("AWELeftSideBarEntranceView"); { MSHookMessageEx(_logos_class$_ungrouped$AWELeftSideBarEntranceView, @selector(layoutSubviews), (IMP)&_logos_method$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews);}Class _logos_class$_ungrouped$AWEFeedVideoButton = objc_getClass("AWEFeedVideoButton"); { MSHookMessageEx(_logos_class$_ungrouped$AWEFeedVideoButton, @selector(layoutSubviews), (IMP)&_logos_method$_ungrouped$AWEFeedVideoButton$layoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWEFeedVideoButton$layoutSubviews);}} }
#line 382 "/Users/huami/Desktop/DYYY/DYYY/DYYY/DYYY.x"
