#line 1 "/Users/huami/Desktop/DYYY/DYYY/DYYY/DYYY.xm"







#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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

@class AWEPlayInteractionUserAvatarElement; @class AWEAwemePlayVideoViewController; @class AWEDanmakuItemTextInfo; @class UIButton; @class UIView; @class AWEFeedProgressSlider; @class UILabel; @class AWEFeedContainerContentView; @class AWELandscapeFeedEntryView; @class AWECommentPublishGuidanceView; @class AWECommentMiniEmoticonPanelView; @class AWENormalModeTabBarGeneralPlusButton; @class AWEDanmakuContentLabel; @class AWELeftSideBarEntranceView; @class AWENormalModeTabBarBadgeContainerView; @class AWECommentInputViewSwiftImpl_CommentInputViewMiddleContainer; @class AWETextViewInternal; @class AWEPlayInteractionViewController; @class AWEAwemeModel; @class UITextInputTraits; @class AWELongVideoControlModel; @class UIWindow; @class AWEFeedVideoButton; 
static void (*_logos_orig$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$)(_LOGOS_SELF_TYPE_NORMAL AWEAwemePlayVideoViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$(_LOGOS_SELF_TYPE_NORMAL AWEAwemePlayVideoViewController* _LOGOS_SELF_CONST, SEL, BOOL); static id (*_logos_meta_orig$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static id _logos_meta_method$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWEFeedContainerContentView$setAlpha$)(_LOGOS_SELF_TYPE_NORMAL AWEFeedContainerContentView* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$_ungrouped$AWEFeedContainerContentView$setAlpha$(_LOGOS_SELF_TYPE_NORMAL AWEFeedContainerContentView* _LOGOS_SELF_CONST, SEL, CGFloat); static void (*_logos_orig$_ungrouped$AWEDanmakuContentLabel$setTextColor$)(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuContentLabel* _LOGOS_SELF_CONST, SEL, UIColor *); static void _logos_method$_ungrouped$AWEDanmakuContentLabel$setTextColor$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuContentLabel* _LOGOS_SELF_CONST, SEL, UIColor *); static UIColor * _logos_method$_ungrouped$AWEDanmakuContentLabel$colorFromHexString$baseColor$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuContentLabel* _LOGOS_SELF_CONST, SEL, NSString *, UIColor *); static void (*_logos_orig$_ungrouped$AWEDanmakuItemTextInfo$setDanmakuTextColor$)(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuItemTextInfo* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$AWEDanmakuItemTextInfo$setDanmakuTextColor$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuItemTextInfo* _LOGOS_SELF_CONST, SEL, id); static UIColor * _logos_method$_ungrouped$AWEDanmakuItemTextInfo$colorFromHexStringForTextInfo$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuItemTextInfo* _LOGOS_SELF_CONST, SEL, NSString *); static UIWindow* (*_logos_orig$_ungrouped$UIWindow$initWithFrame$)(_LOGOS_SELF_TYPE_INIT UIWindow*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static UIWindow* _logos_method$_ungrouped$UIWindow$initWithFrame$(_LOGOS_SELF_TYPE_INIT UIWindow*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static void _logos_method$_ungrouped$UIWindow$handleDoubleFingerLongPressGesture$(_LOGOS_SELF_TYPE_NORMAL UIWindow* _LOGOS_SELF_CONST, SEL, UILongPressGestureRecognizer *); static void _logos_method$_ungrouped$UIWindow$closeSettings$(_LOGOS_SELF_TYPE_NORMAL UIWindow* _LOGOS_SELF_CONST, SEL, UIButton *); static bool (*_logos_orig$_ungrouped$AWELongVideoControlModel$allowDownload)(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST, SEL); static bool _logos_method$_ungrouped$AWELongVideoControlModel$allowDownload(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST, SEL); static long long (*_logos_orig$_ungrouped$AWELongVideoControlModel$preventDownloadType)(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST, SEL); static long long _logos_method$_ungrouped$AWELongVideoControlModel$preventDownloadType(_LOGOS_SELF_TYPE_NORMAL AWELongVideoControlModel* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWELandscapeFeedEntryView$setHidden$)(_LOGOS_SELF_TYPE_NORMAL AWELandscapeFeedEntryView* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$AWELandscapeFeedEntryView$setHidden$(_LOGOS_SELF_TYPE_NORMAL AWELandscapeFeedEntryView* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$)(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWEAwemeModel$setIsAds$)(_LOGOS_SELF_TYPE_NORMAL AWEAwemeModel* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$AWEAwemeModel$setIsAds$(_LOGOS_SELF_TYPE_NORMAL AWEAwemeModel* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWENormalModeTabBarBadgeContainerView* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWENormalModeTabBarBadgeContainerView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWELeftSideBarEntranceView* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWELeftSideBarEntranceView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWEFeedVideoButton$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWEFeedVideoButton* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWEFeedVideoButton$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWEFeedVideoButton* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$_ungrouped$AWEFeedVideoButton$touchUpInsideBlock)(_LOGOS_SELF_TYPE_NORMAL AWEFeedVideoButton* _LOGOS_SELF_CONST, SEL); static id _logos_method$_ungrouped$AWEFeedVideoButton$touchUpInsideBlock(_LOGOS_SELF_TYPE_NORMAL AWEFeedVideoButton* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$UITextInputTraits$setKeyboardAppearance$)(_LOGOS_SELF_TYPE_NORMAL UITextInputTraits* _LOGOS_SELF_CONST, SEL, UIKeyboardAppearance); static void _logos_method$_ungrouped$UITextInputTraits$setKeyboardAppearance$(_LOGOS_SELF_TYPE_NORMAL UITextInputTraits* _LOGOS_SELF_CONST, SEL, UIKeyboardAppearance); static void (*_logos_orig$_ungrouped$AWECommentMiniEmoticonPanelView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWECommentMiniEmoticonPanelView* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWECommentMiniEmoticonPanelView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWECommentMiniEmoticonPanelView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWECommentPublishGuidanceView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL AWECommentPublishGuidanceView* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$AWECommentPublishGuidanceView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWECommentPublishGuidanceView* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$_ungrouped$AWECommentInputViewSwiftImpl_CommentInputViewMiddleContainer$initWithFrame$)(_LOGOS_SELF_TYPE_INIT id, SEL, CGRect) _LOGOS_RETURN_RETAINED; static id _logos_method$_ungrouped$AWECommentInputViewSwiftImpl_CommentInputViewMiddleContainer$initWithFrame$(_LOGOS_SELF_TYPE_INIT id, SEL, CGRect) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$_ungrouped$UIView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL UIView* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$UIView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL UIView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$UILabel$setText$)(_LOGOS_SELF_TYPE_NORMAL UILabel* _LOGOS_SELF_CONST, SEL, NSString *); static void _logos_method$_ungrouped$UILabel$setText$(_LOGOS_SELF_TYPE_NORMAL UILabel* _LOGOS_SELF_CONST, SEL, NSString *); static void (*_logos_orig$_ungrouped$UIButton$setImage$forState$)(_LOGOS_SELF_TYPE_NORMAL UIButton* _LOGOS_SELF_CONST, SEL, UIImage *, UIControlState); static void _logos_method$_ungrouped$UIButton$setImage$forState$(_LOGOS_SELF_TYPE_NORMAL UIButton* _LOGOS_SELF_CONST, SEL, UIImage *, UIControlState); static void (*_logos_orig$_ungrouped$AWETextViewInternal$drawRect$)(_LOGOS_SELF_TYPE_NORMAL AWETextViewInternal* _LOGOS_SELF_CONST, SEL, CGRect); static void _logos_method$_ungrouped$AWETextViewInternal$drawRect$(_LOGOS_SELF_TYPE_NORMAL AWETextViewInternal* _LOGOS_SELF_CONST, SEL, CGRect); static double (*_logos_orig$_ungrouped$AWETextViewInternal$lineSpacing)(_LOGOS_SELF_TYPE_NORMAL AWETextViewInternal* _LOGOS_SELF_CONST, SEL); static double _logos_method$_ungrouped$AWETextViewInternal$lineSpacing(_LOGOS_SELF_TYPE_NORMAL AWETextViewInternal* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$AWEPlayInteractionUserAvatarElement$onFollowViewClicked$)(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionUserAvatarElement* _LOGOS_SELF_CONST, SEL, UITapGestureRecognizer *); static void _logos_method$_ungrouped$AWEPlayInteractionUserAvatarElement$onFollowViewClicked$(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionUserAvatarElement* _LOGOS_SELF_CONST, SEL, UITapGestureRecognizer *); static void (*_logos_orig$_ungrouped$AWEFeedProgressSlider$setAlpha$)(_LOGOS_SELF_TYPE_NORMAL AWEFeedProgressSlider* _LOGOS_SELF_CONST, SEL, CGFloat); static void _logos_method$_ungrouped$AWEFeedProgressSlider$setAlpha$(_LOGOS_SELF_TYPE_NORMAL AWEFeedProgressSlider* _LOGOS_SELF_CONST, SEL, CGFloat); 

#line 68 "/Users/huami/Desktop/DYYY/DYYY/DYYY/DYYY.xm"


static void _logos_method$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$(_LOGOS_SELF_TYPE_NORMAL AWEAwemePlayVideoViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL arg0) {
    float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];
    
    if (defaultSpeed > 0 && defaultSpeed != 1) {
        [self setVideoControllerPlaybackRate:defaultSpeed];
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



static void _logos_method$_ungrouped$AWEDanmakuItemTextInfo$setDanmakuTextColor$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuItemTextInfo* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    NSLog(@"Original Color: %@", arg1);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"]) {
        NSString *danmuColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYdanmuColor"];
        
        if ([danmuColor.lowercaseString isEqualToString:@"random"] || [danmuColor.lowercaseString isEqualToString:@"#random"]) {
            arg1 = [UIColor colorWithRed:(arc4random_uniform(256)) / 255.0
                                   green:(arc4random_uniform(256)) / 255.0
                                    blue:(arc4random_uniform(256)) / 255.0
                                   alpha:1.0];
            NSLog(@"Random Color: %@", arg1);
        } else if ([danmuColor hasPrefix:@"#"]) {
            arg1 = [self colorFromHexStringForTextInfo:danmuColor];
            NSLog(@"Custom Hex Color: %@", arg1);
        } else {
            arg1 = [self colorFromHexStringForTextInfo:@"#FFFFFF"];
            NSLog(@"Default White Color: %@", arg1);
        }
    }

    _logos_orig$_ungrouped$AWEDanmakuItemTextInfo$setDanmakuTextColor$(self, _cmd, arg1);
}


static UIColor * _logos_method$_ungrouped$AWEDanmakuItemTextInfo$colorFromHexStringForTextInfo$(_LOGOS_SELF_TYPE_NORMAL AWEDanmakuItemTextInfo* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * hexString) {
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




static void _logos_method$_ungrouped$UITextInputTraits$setKeyboardAppearance$(_LOGOS_SELF_TYPE_NORMAL UITextInputTraits* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIKeyboardAppearance appearance) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        _logos_orig$_ungrouped$UITextInputTraits$setKeyboardAppearance$(self, _cmd, UIKeyboardAppearanceDark);
    }else {
        _logos_orig$_ungrouped$UITextInputTraits$setKeyboardAppearance$(self, _cmd, appearance);
    }
}




static void _logos_method$_ungrouped$AWECommentMiniEmoticonPanelView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWECommentMiniEmoticonPanelView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$_ungrouped$AWECommentMiniEmoticonPanelView$layoutSubviews(self, _cmd);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UICollectionView class]]) {
                subview.backgroundColor = [UIColor colorWithRed:115/255.0 green:115/255.0 blue:115/255.0 alpha:1.0];
            }
        }
    }
}




static void _logos_method$_ungrouped$AWECommentPublishGuidanceView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL AWECommentPublishGuidanceView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$_ungrouped$AWECommentPublishGuidanceView$layoutSubviews(self, _cmd);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UICollectionView class]]) {
                subview.backgroundColor = [UIColor colorWithRed:115/255.0 green:115/255.0 blue:115/255.0 alpha:1.0];
            }
        }
    }
}



static id _logos_method$_ungrouped$AWECommentInputViewSwiftImpl_CommentInputViewMiddleContainer$initWithFrame$(_LOGOS_SELF_TYPE_INIT id __unused self, SEL __unused _cmd, CGRect frame) _LOGOS_RETURN_RETAINED {
    self = _logos_orig$_ungrouped$AWECommentInputViewSwiftImpl_CommentInputViewMiddleContainer$initWithFrame$(self, _cmd, frame);
    if (self) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
            
            UIView *view = (UIView *)self;
            view.backgroundColor = [UIColor colorWithRed:40/255.0 green:40/255.0 blue:40/255.0 alpha:1.0];
        }
    }
    return self;
}




static void _logos_method$_ungrouped$UIView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL UIView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$_ungrouped$UIView$layoutSubviews(self, _cmd);
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




static void _logos_method$_ungrouped$UILabel$setText$(_LOGOS_SELF_TYPE_NORMAL UILabel* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * text) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        if ([text hasPrefix:@"善语"] || [text hasPrefix:@"友爱评论"] || [text hasPrefix:@"回复"]) {
            self.textColor = [UIColor colorWithRed:125/255.0 green:125/255.0 blue:125/255.0 alpha:0.6];
        }
    }
    _logos_orig$_ungrouped$UILabel$setText$(self, _cmd, text);
}





static void _logos_method$_ungrouped$UIButton$setImage$forState$(_LOGOS_SELF_TYPE_NORMAL UIButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIImage * image, UIControlState state) {
    NSString *label = self.accessibilityLabel;

    if ([label isEqualToString:@"表情"] || [label isEqualToString:@"at"] || [label isEqualToString:@"图片"] || [label isEqualToString:@"键盘"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
            
            UIImage *whiteImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            self.tintColor = [UIColor whiteColor];
            
            _logos_orig$_ungrouped$UIButton$setImage$forState$(self, _cmd, whiteImage, state);
        }else {
            _logos_orig$_ungrouped$UIButton$setImage$forState$(self, _cmd, image, state);
        }
    } else {
        _logos_orig$_ungrouped$UIButton$setImage$forState$(self, _cmd, image, state);
    }
}





static void _logos_method$_ungrouped$AWETextViewInternal$drawRect$(_LOGOS_SELF_TYPE_NORMAL AWETextViewInternal* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGRect rect) {
    _logos_orig$_ungrouped$AWETextViewInternal$drawRect$(self, _cmd, rect);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        
        self.textColor = [UIColor whiteColor];
    }
}

static double _logos_method$_ungrouped$AWETextViewInternal$lineSpacing(_LOGOS_SELF_TYPE_NORMAL AWETextViewInternal* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    double r = _logos_orig$_ungrouped$AWETextViewInternal$lineSpacing(self, _cmd);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisDarkKeyBoard"]) {
        
        self.textColor = [UIColor whiteColor];
    }
    return r;
}





static void _logos_method$_ungrouped$AWEPlayInteractionUserAvatarElement$onFollowViewClicked$(_LOGOS_SELF_TYPE_NORMAL AWEPlayInteractionUserAvatarElement* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UITapGestureRecognizer * gesture) {

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
                _logos_orig$_ungrouped$AWEPlayInteractionUserAvatarElement$onFollowViewClicked$(self, _cmd, gesture);
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
        _logos_orig$_ungrouped$AWEPlayInteractionUserAvatarElement$onFollowViewClicked$(self, _cmd, gesture);
    }
}




static id _logos_method$_ungrouped$AWEFeedVideoButton$touchUpInsideBlock(_LOGOS_SELF_TYPE_NORMAL AWEFeedVideoButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    id r = _logos_orig$_ungrouped$AWEFeedVideoButton$touchUpInsideBlock(self, _cmd);
    
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

        return nil; 
    }

    return r;
}





static void _logos_method$_ungrouped$AWEFeedProgressSlider$setAlpha$(_LOGOS_SELF_TYPE_NORMAL AWEFeedProgressSlider* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, CGFloat alpha) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowSchedule"]) {
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SuAwemeHookAlwaysShowProgress"]) {
            alpha = 1.0;
        }
        _logos_orig$_ungrouped$AWEFeedProgressSlider$setAlpha$(self, _cmd, alpha);
    }else {
        _logos_orig$_ungrouped$AWEFeedProgressSlider$setAlpha$(self, _cmd, alpha);
    }
}







































static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$AWEAwemePlayVideoViewController = objc_getClass("AWEAwemePlayVideoViewController"); { MSHookMessageEx(_logos_class$_ungrouped$AWEAwemePlayVideoViewController, @selector(setIsAutoPlay:), (IMP)&_logos_method$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$, (IMP*)&_logos_orig$_ungrouped$AWEAwemePlayVideoViewController$setIsAutoPlay$);}Class _logos_class$_ungrouped$AWENormalModeTabBarGeneralPlusButton = objc_getClass("AWENormalModeTabBarGeneralPlusButton"); Class _logos_metaclass$_ungrouped$AWENormalModeTabBarGeneralPlusButton = object_getClass(_logos_class$_ungrouped$AWENormalModeTabBarGeneralPlusButton); { MSHookMessageEx(_logos_metaclass$_ungrouped$AWENormalModeTabBarGeneralPlusButton, @selector(button), (IMP)&_logos_meta_method$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button, (IMP*)&_logos_meta_orig$_ungrouped$AWENormalModeTabBarGeneralPlusButton$button);}Class _logos_class$_ungrouped$AWEFeedContainerContentView = objc_getClass("AWEFeedContainerContentView"); { MSHookMessageEx(_logos_class$_ungrouped$AWEFeedContainerContentView, @selector(setAlpha:), (IMP)&_logos_method$_ungrouped$AWEFeedContainerContentView$setAlpha$, (IMP*)&_logos_orig$_ungrouped$AWEFeedContainerContentView$setAlpha$);}Class _logos_class$_ungrouped$AWEDanmakuContentLabel = objc_getClass("AWEDanmakuContentLabel"); { MSHookMessageEx(_logos_class$_ungrouped$AWEDanmakuContentLabel, @selector(setTextColor:), (IMP)&_logos_method$_ungrouped$AWEDanmakuContentLabel$setTextColor$, (IMP*)&_logos_orig$_ungrouped$AWEDanmakuContentLabel$setTextColor$);}{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(UIColor *), strlen(@encode(UIColor *))); i += strlen(@encode(UIColor *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSString *), strlen(@encode(NSString *))); i += strlen(@encode(NSString *)); memcpy(_typeEncoding + i, @encode(UIColor *), strlen(@encode(UIColor *))); i += strlen(@encode(UIColor *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$AWEDanmakuContentLabel, @selector(colorFromHexString:baseColor:), (IMP)&_logos_method$_ungrouped$AWEDanmakuContentLabel$colorFromHexString$baseColor$, _typeEncoding); }Class _logos_class$_ungrouped$AWEDanmakuItemTextInfo = objc_getClass("AWEDanmakuItemTextInfo"); { MSHookMessageEx(_logos_class$_ungrouped$AWEDanmakuItemTextInfo, @selector(setDanmakuTextColor:), (IMP)&_logos_method$_ungrouped$AWEDanmakuItemTextInfo$setDanmakuTextColor$, (IMP*)&_logos_orig$_ungrouped$AWEDanmakuItemTextInfo$setDanmakuTextColor$);}{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(UIColor *), strlen(@encode(UIColor *))); i += strlen(@encode(UIColor *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSString *), strlen(@encode(NSString *))); i += strlen(@encode(NSString *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$AWEDanmakuItemTextInfo, @selector(colorFromHexStringForTextInfo:), (IMP)&_logos_method$_ungrouped$AWEDanmakuItemTextInfo$colorFromHexStringForTextInfo$, _typeEncoding); }Class _logos_class$_ungrouped$UIWindow = objc_getClass("UIWindow"); { MSHookMessageEx(_logos_class$_ungrouped$UIWindow, @selector(initWithFrame:), (IMP)&_logos_method$_ungrouped$UIWindow$initWithFrame$, (IMP*)&_logos_orig$_ungrouped$UIWindow$initWithFrame$);}{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UILongPressGestureRecognizer *), strlen(@encode(UILongPressGestureRecognizer *))); i += strlen(@encode(UILongPressGestureRecognizer *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$UIWindow, @selector(handleDoubleFingerLongPressGesture:), (IMP)&_logos_method$_ungrouped$UIWindow$handleDoubleFingerLongPressGesture$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIButton *), strlen(@encode(UIButton *))); i += strlen(@encode(UIButton *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$UIWindow, @selector(closeSettings:), (IMP)&_logos_method$_ungrouped$UIWindow$closeSettings$, _typeEncoding); }Class _logos_class$_ungrouped$AWELongVideoControlModel = objc_getClass("AWELongVideoControlModel"); { MSHookMessageEx(_logos_class$_ungrouped$AWELongVideoControlModel, @selector(allowDownload), (IMP)&_logos_method$_ungrouped$AWELongVideoControlModel$allowDownload, (IMP*)&_logos_orig$_ungrouped$AWELongVideoControlModel$allowDownload);}{ MSHookMessageEx(_logos_class$_ungrouped$AWELongVideoControlModel, @selector(preventDownloadType), (IMP)&_logos_method$_ungrouped$AWELongVideoControlModel$preventDownloadType, (IMP*)&_logos_orig$_ungrouped$AWELongVideoControlModel$preventDownloadType);}Class _logos_class$_ungrouped$AWELandscapeFeedEntryView = objc_getClass("AWELandscapeFeedEntryView"); { MSHookMessageEx(_logos_class$_ungrouped$AWELandscapeFeedEntryView, @selector(setHidden:), (IMP)&_logos_method$_ungrouped$AWELandscapeFeedEntryView$setHidden$, (IMP*)&_logos_orig$_ungrouped$AWELandscapeFeedEntryView$setHidden$);}Class _logos_class$_ungrouped$AWEPlayInteractionViewController = objc_getClass("AWEPlayInteractionViewController"); { MSHookMessageEx(_logos_class$_ungrouped$AWEPlayInteractionViewController, @selector(viewDidAppear:), (IMP)&_logos_method$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$, (IMP*)&_logos_orig$_ungrouped$AWEPlayInteractionViewController$viewDidAppear$);}{ MSHookMessageEx(_logos_class$_ungrouped$AWEPlayInteractionViewController, @selector(viewWillLayoutSubviews), (IMP)&_logos_method$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWEPlayInteractionViewController$viewWillLayoutSubviews);}Class _logos_class$_ungrouped$AWEAwemeModel = objc_getClass("AWEAwemeModel"); { MSHookMessageEx(_logos_class$_ungrouped$AWEAwemeModel, @selector(setIsAds:), (IMP)&_logos_method$_ungrouped$AWEAwemeModel$setIsAds$, (IMP*)&_logos_orig$_ungrouped$AWEAwemeModel$setIsAds$);}Class _logos_class$_ungrouped$AWENormalModeTabBarBadgeContainerView = objc_getClass("AWENormalModeTabBarBadgeContainerView"); { MSHookMessageEx(_logos_class$_ungrouped$AWENormalModeTabBarBadgeContainerView, @selector(layoutSubviews), (IMP)&_logos_method$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWENormalModeTabBarBadgeContainerView$layoutSubviews);}Class _logos_class$_ungrouped$AWELeftSideBarEntranceView = objc_getClass("AWELeftSideBarEntranceView"); { MSHookMessageEx(_logos_class$_ungrouped$AWELeftSideBarEntranceView, @selector(layoutSubviews), (IMP)&_logos_method$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWELeftSideBarEntranceView$layoutSubviews);}Class _logos_class$_ungrouped$AWEFeedVideoButton = objc_getClass("AWEFeedVideoButton"); { MSHookMessageEx(_logos_class$_ungrouped$AWEFeedVideoButton, @selector(layoutSubviews), (IMP)&_logos_method$_ungrouped$AWEFeedVideoButton$layoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWEFeedVideoButton$layoutSubviews);}{ MSHookMessageEx(_logos_class$_ungrouped$AWEFeedVideoButton, @selector(touchUpInsideBlock), (IMP)&_logos_method$_ungrouped$AWEFeedVideoButton$touchUpInsideBlock, (IMP*)&_logos_orig$_ungrouped$AWEFeedVideoButton$touchUpInsideBlock);}Class _logos_class$_ungrouped$UITextInputTraits = objc_getClass("UITextInputTraits"); { MSHookMessageEx(_logos_class$_ungrouped$UITextInputTraits, @selector(setKeyboardAppearance:), (IMP)&_logos_method$_ungrouped$UITextInputTraits$setKeyboardAppearance$, (IMP*)&_logos_orig$_ungrouped$UITextInputTraits$setKeyboardAppearance$);}Class _logos_class$_ungrouped$AWECommentMiniEmoticonPanelView = objc_getClass("AWECommentMiniEmoticonPanelView"); { MSHookMessageEx(_logos_class$_ungrouped$AWECommentMiniEmoticonPanelView, @selector(layoutSubviews), (IMP)&_logos_method$_ungrouped$AWECommentMiniEmoticonPanelView$layoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWECommentMiniEmoticonPanelView$layoutSubviews);}Class _logos_class$_ungrouped$AWECommentPublishGuidanceView = objc_getClass("AWECommentPublishGuidanceView"); { MSHookMessageEx(_logos_class$_ungrouped$AWECommentPublishGuidanceView, @selector(layoutSubviews), (IMP)&_logos_method$_ungrouped$AWECommentPublishGuidanceView$layoutSubviews, (IMP*)&_logos_orig$_ungrouped$AWECommentPublishGuidanceView$layoutSubviews);}Class _logos_class$_ungrouped$AWECommentInputViewSwiftImpl_CommentInputViewMiddleContainer = objc_getClass("AWECommentInputViewSwiftImpl.CommentInputViewMiddleContainer"); { MSHookMessageEx(_logos_class$_ungrouped$AWECommentInputViewSwiftImpl_CommentInputViewMiddleContainer, @selector(initWithFrame:), (IMP)&_logos_method$_ungrouped$AWECommentInputViewSwiftImpl_CommentInputViewMiddleContainer$initWithFrame$, (IMP*)&_logos_orig$_ungrouped$AWECommentInputViewSwiftImpl_CommentInputViewMiddleContainer$initWithFrame$);}Class _logos_class$_ungrouped$UIView = objc_getClass("UIView"); { MSHookMessageEx(_logos_class$_ungrouped$UIView, @selector(layoutSubviews), (IMP)&_logos_method$_ungrouped$UIView$layoutSubviews, (IMP*)&_logos_orig$_ungrouped$UIView$layoutSubviews);}Class _logos_class$_ungrouped$UILabel = objc_getClass("UILabel"); { MSHookMessageEx(_logos_class$_ungrouped$UILabel, @selector(setText:), (IMP)&_logos_method$_ungrouped$UILabel$setText$, (IMP*)&_logos_orig$_ungrouped$UILabel$setText$);}Class _logos_class$_ungrouped$UIButton = objc_getClass("UIButton"); { MSHookMessageEx(_logos_class$_ungrouped$UIButton, @selector(setImage:forState:), (IMP)&_logos_method$_ungrouped$UIButton$setImage$forState$, (IMP*)&_logos_orig$_ungrouped$UIButton$setImage$forState$);}Class _logos_class$_ungrouped$AWETextViewInternal = objc_getClass("AWETextViewInternal"); { MSHookMessageEx(_logos_class$_ungrouped$AWETextViewInternal, @selector(drawRect:), (IMP)&_logos_method$_ungrouped$AWETextViewInternal$drawRect$, (IMP*)&_logos_orig$_ungrouped$AWETextViewInternal$drawRect$);}{ MSHookMessageEx(_logos_class$_ungrouped$AWETextViewInternal, @selector(lineSpacing), (IMP)&_logos_method$_ungrouped$AWETextViewInternal$lineSpacing, (IMP*)&_logos_orig$_ungrouped$AWETextViewInternal$lineSpacing);}Class _logos_class$_ungrouped$AWEPlayInteractionUserAvatarElement = objc_getClass("AWEPlayInteractionUserAvatarElement"); { MSHookMessageEx(_logos_class$_ungrouped$AWEPlayInteractionUserAvatarElement, @selector(onFollowViewClicked:), (IMP)&_logos_method$_ungrouped$AWEPlayInteractionUserAvatarElement$onFollowViewClicked$, (IMP*)&_logos_orig$_ungrouped$AWEPlayInteractionUserAvatarElement$onFollowViewClicked$);}Class _logos_class$_ungrouped$AWEFeedProgressSlider = objc_getClass("AWEFeedProgressSlider"); { MSHookMessageEx(_logos_class$_ungrouped$AWEFeedProgressSlider, @selector(setAlpha:), (IMP)&_logos_method$_ungrouped$AWEFeedProgressSlider$setAlpha$, (IMP*)&_logos_orig$_ungrouped$AWEFeedProgressSlider$setAlpha$);}} }
#line 676 "/Users/huami/Desktop/DYYY/DYYY/DYYY/DYYY.xm"
