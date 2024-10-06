//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//  Created on: 2024/10/04
//
#import <UIKit/UIKit.h>

@interface AWENormalModeTabBarGeneralButton : UIButton
@end

@interface AWEFeedContainerContentView : UIView
@end

@interface AWEDanmakuContentLabel : UILabel
- (UIColor *)colorFromHexString:(NSString *)hexString baseColor:(UIColor *)baseColor;
@end

@interface AWELandscapeFeedEntryView : UIView
@end

@interface AWEPlayInteractionViewController : UIViewController
@end

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
    if (transparentValue) {
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
%end

%hook AWEDanmakuContentLabel
- (void)setTextColor:(UIColor *)textColor {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"]) {
        NSString *danmuColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYdanmuColor"];

        if ([danmuColor.lowercaseString isEqualToString:@"random"]) {
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

%hook UIWindow
- (instancetype)initWithFrame:(CGRect)frame {
    UIWindow *window = %orig(frame);
    if (window) {
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
        doubleTapGesture.numberOfTapsRequired = 1;
        doubleTapGesture.numberOfTouchesRequired = 3;
        [window addGestureRecognizer:doubleTapGesture];
    }
    return window;
}

%new
- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        UIViewController *rootViewController = self.rootViewController;
        if (rootViewController) {
            UIViewController *settingVC = [[NSClassFromString(@"DYYYSettingViewController") alloc] init];
            if (settingVC) {
                [rootViewController presentViewController:settingVC animated:YES completion:nil];
            }
        }
    }
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

%hook AWEPlayInteractionViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYGlobalTransparency"];
    if (transparentValue) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {
            %orig(animated);
            self.view.alpha = alphaValue;
        } else {
            %orig(animated);
            self.view.alpha = 1.0;
        }
    } else {
        %orig(animated);
        self.view.alpha = 1.0;
    }
}

- (void)viewWillLayoutSubviews {
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYGlobalTransparency"];
    if (transparentValue) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {
            %orig;
            self.view.alpha = alphaValue;
        } else {
            %orig;
            self.view.alpha = 1.0;
        }
    } else {
        %orig;
        self.view.alpha = 1.0;
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
