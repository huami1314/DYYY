#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "DYYYUtils.h"
#import "DYYYToast.h"
#import "DYYYManager.h"
#import "AwemeHeaders.h"

NSString *cleanShareURL(NSString *url) {
    if (!url || url.length == 0) {
        return url;
    }
    
    NSRange questionMarkRange = [url rangeOfString:@"?"];

    if (questionMarkRange.location != NSNotFound) {
        return [url substringToIndex:questionMarkRange.location];
    }

    return url;
}

UIViewController *topView(void) {
    return [DYYYUtils topView];
}

@implementation DYYYUtils

+ (UIViewController *)topView {
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    return topViewController;
}

+ (NSUInteger)clearDirectoryContents:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSUInteger totalSize = 0;
    
    if (![fileManager fileExistsAtPath:directoryPath]) {
        return 0;
    }
    
    NSError *error = nil;
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    
    if (error) {
        NSLog(@"获取目录内容失败 %@: %@", directoryPath, error);
        return 0;
    }
    
    for (NSString *item in contents) {
        if ([item hasPrefix:@"."]) {
            continue;
        }
        
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:item];
        
        NSDictionary<NSFileAttributeKey, id> *attrs = [fileManager attributesOfItemAtPath:fullPath error:nil];
        NSUInteger fileSize = attrs ? [attrs fileSize] : 0;
        
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
            if (isDirectory) {
                fileSize += [self clearDirectoryContents:fullPath];
            }
            
            NSError *delError = nil;
            [fileManager removeItemAtPath:fullPath error:&delError];
            if (delError) {
                NSLog(@"删除失败 %@: %@", fullPath, delError);
            } else {
                totalSize += fileSize;
            }
        }
    }
    
    return totalSize;
}

+ (UIWindow *)getActiveWindow {
  if (@available(iOS 15.0, *)) {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
      if ([scene isKindOfClass:[UIWindowScene class]] &&
          scene.activationState == UISceneActivationStateForegroundActive) {
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
          if (w.isKeyWindow)
            return w;
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

+ (UIViewController *)getActiveTopController {
  UIWindow *window = [self getActiveWindow];
  if (!window)
    return nil;

  UIViewController *topController = window.rootViewController;
  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
  }

  return topController;
}

+ (UIColor *)colorWithHexString:(NSString *)hexString {
  // 处理rainbow直接生成彩虹色的情况
  if ([hexString.lowercaseString isEqualToString:@"rainbow"] ||
      [hexString.lowercaseString isEqualToString:@"#rainbow"]) {
    CGSize size = CGSizeMake(400, 100);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // 彩虹色：红、橙、黄、绿、青、蓝、紫
    UIColor *red = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    UIColor *orange = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
    UIColor *yellow = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];
    UIColor *green = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    UIColor *cyan = [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0];
    UIColor *blue = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
    UIColor *purple = [UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0];

    NSArray *colorsArray = @[
      (__bridge id)red.CGColor, (__bridge id)orange.CGColor,
      (__bridge id)yellow.CGColor, (__bridge id)green.CGColor,
      (__bridge id)cyan.CGColor, (__bridge id)blue.CGColor,
      (__bridge id)purple.CGColor
    ];

    // 创建渐变
    CGGradientRef gradient = CGGradientCreateWithColors(
        colorSpace, (__bridge CFArrayRef)colorsArray, NULL);

    CGPoint startPoint = CGPointMake(0, size.height / 2);
    CGPoint endPoint = CGPointMake(size.width, size.height / 2);

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    return [UIColor colorWithPatternImage:gradientImage];
  }

  // 如果包含半角逗号，则解析两个颜色代码并生成渐变色
  if ([hexString containsString:@","]) {
    NSArray *components = [hexString componentsSeparatedByString:@","];
    if (components.count == 2) {
      NSString *firstHex = [[components objectAtIndex:0]
          stringByTrimmingCharactersInSet:[NSCharacterSet
                                              whitespaceCharacterSet]];
      NSString *secondHex = [[components objectAtIndex:1]
          stringByTrimmingCharactersInSet:[NSCharacterSet
                                              whitespaceCharacterSet]];

      // 分别解析两个颜色
      UIColor *firstColor = [self colorWithHexString:firstHex];
      UIColor *secondColor = [self colorWithHexString:secondHex];

      // 使用渐变layer生成图片
      CGSize size = CGSizeMake(400, 100);
      UIGraphicsBeginImageContextWithOptions(size, NO, 0);
      CGContextRef context = UIGraphicsGetCurrentContext();
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

      // 普通双色渐变效果
      CGFloat midR = (CGColorGetComponents(firstColor.CGColor)[0] +
                      CGColorGetComponents(secondColor.CGColor)[0]) /
                     2;
      CGFloat midG = (CGColorGetComponents(firstColor.CGColor)[1] +
                      CGColorGetComponents(secondColor.CGColor)[1]) /
                     2;
      CGFloat midB = (CGColorGetComponents(firstColor.CGColor)[2] +
                      CGColorGetComponents(secondColor.CGColor)[2]) /
                     2;
      UIColor *midColor = [UIColor colorWithRed:midR
                                          green:midG
                                           blue:midB
                                          alpha:1.0];

      NSArray *colorsArray = @[
        (__bridge id)firstColor.CGColor, (__bridge id)midColor.CGColor,
        (__bridge id)secondColor.CGColor
      ];

      // 创建渐变
      CGGradientRef gradient = CGGradientCreateWithColors(
          colorSpace, (__bridge CFArrayRef)colorsArray, NULL);

      CGPoint startPoint = CGPointMake(0, size.height / 2);
      CGPoint endPoint = CGPointMake(size.width, size.height / 2);

      CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
      UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      CGGradientRelease(gradient);
      CGColorSpaceRelease(colorSpace);

      return [UIColor colorWithPatternImage:gradientImage];
    }
  }

  // 处理随机颜色的情况
  if ([hexString.lowercaseString isEqualToString:@"random"] ||
      [hexString.lowercaseString isEqualToString:@"#random"]) {
    return [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
                           green:(CGFloat)arc4random_uniform(256) / 255.0
                            blue:(CGFloat)arc4random_uniform(256) / 255.0
                           alpha:1.0];
  }

  // 去掉"#"前缀并转为大写
  NSString *colorString =
      [[hexString stringByReplacingOccurrencesOfString:@"#"
                                            withString:@""] uppercaseString];
  CGFloat alpha = 1.0;
  CGFloat red = 0.0;
  CGFloat green = 0.0;
  CGFloat blue = 0.0;

  if (colorString.length == 8) {
    // 8位十六进制：AARRGGBB，前两位为透明度
    NSScanner *scanner = [NSScanner
        scannerWithString:[colorString substringWithRange:NSMakeRange(0, 2)]];
    unsigned int alphaValue;
    [scanner scanHexInt:&alphaValue];
    alpha = (CGFloat)alphaValue / 255.0;

    scanner = [NSScanner
        scannerWithString:[colorString substringWithRange:NSMakeRange(2, 2)]];
    unsigned int redValue;
    [scanner scanHexInt:&redValue];
    red = (CGFloat)redValue / 255.0;

    scanner = [NSScanner
        scannerWithString:[colorString substringWithRange:NSMakeRange(4, 2)]];
    unsigned int greenValue;
    [scanner scanHexInt:&greenValue];
    green = (CGFloat)greenValue / 255.0;

    scanner = [NSScanner
        scannerWithString:[colorString substringWithRange:NSMakeRange(6, 2)]];
    unsigned int blueValue;
    [scanner scanHexInt:&blueValue];
    blue = (CGFloat)blueValue / 255.0;
  } else {
    // 处理常规6位十六进制：RRGGBB
    NSScanner *scanner = nil;
    unsigned int hexValue = 0;

    if (colorString.length == 6) {
      scanner = [NSScanner scannerWithString:colorString];
    } else if (colorString.length == 3) {
      // 3位简写格式：RGB
      NSString *r = [colorString substringWithRange:NSMakeRange(0, 1)];
      NSString *g = [colorString substringWithRange:NSMakeRange(1, 1)];
      NSString *b = [colorString substringWithRange:NSMakeRange(2, 1)];
      colorString =
          [NSString stringWithFormat:@"%@%@%@%@%@%@", r, r, g, g, b, b];
      scanner = [NSScanner scannerWithString:colorString];
    }

    if (scanner && [scanner scanHexInt:&hexValue]) {
      red = ((hexValue & 0xFF0000) >> 16) / 255.0;
      green = ((hexValue & 0x00FF00) >> 8) / 255.0;
      blue = (hexValue & 0x0000FF) / 255.0;
    }
  }

  return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (void)showToast:(NSString *)text {
  Class toastClass = NSClassFromString(@"DUXToast");
  if (toastClass && [toastClass respondsToSelector:@selector(showText:)]) {
    [toastClass performSelector:@selector(showText:) withObject:text];
  }
}

+ (BOOL)isDarkMode {
  Class themeManagerClass = NSClassFromString(@"AWEUIThemeManager");
  if (!themeManagerClass) {
    return NO;
  }
  return [themeManagerClass isLightTheme] ? NO : YES;
}

@end