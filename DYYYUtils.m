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

+ (void)applyColorSettingsToLabel:(UILabel *)label colorHexString:(NSString *)colorHexString {
    if (!label || !label.text || label.text.length == 0) {
        NSMutableAttributedString *attributedText;
        if ([label.attributedText isKindOfClass:[NSAttributedString class]]) {
            attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:label.attributedText];
            [attributedText removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, attributedText.length)];
            [attributedText removeAttribute:NSStrokeColorAttributeName range:NSMakeRange(0, attributedText.length)];
            [attributedText removeAttribute:NSStrokeWidthAttributeName range:NSMakeRange(0, attributedText.length)];
        } else {
            attributedText = [[NSMutableAttributedString alloc] initWithString:label.text ?: @""];
        }
        label.attributedText = attributedText;
        return;
    }

    if (!colorHexString || colorHexString.length == 0) {
        NSMutableAttributedString *attributedText;
        if ([label.attributedText isKindOfClass:[NSAttributedString class]]) {
            attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:label.attributedText];
            [attributedText removeAttribute:NSStrokeColorAttributeName range:NSMakeRange(0, attributedText.length)];
            [attributedText removeAttribute:NSStrokeWidthAttributeName range:NSMakeRange(0, attributedText.length)];
        } else {
            attributedText = [[NSMutableAttributedString alloc] initWithString:label.text ?: @""];
        }
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attributedText.length)];
        label.attributedText = attributedText;
        return;
    }

    NSString *trimmedHexString = [colorHexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    UIColor * (^colorScheme)(CGFloat) = [self colorSchemeBlockWithHexString:lowercaseHexString];

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:label.text];

    CFIndex length = [attributedText length];
    for (CFIndex i = 0; i < length; i++) {
        CGFloat progress = (length > 1) ? (CGFloat)i / (length - 1) : 0.0;

        UIColor *currentColor = colorScheme(progress);

        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        if (currentColor) {
            attributes[NSForegroundColorAttributeName] = currentColor;
        } else {
            attributes[NSForegroundColorAttributeName] = [UIColor whiteColor]; // 默认白色
        }

        if ([lowercaseHexString isEqualToString:@"random_rainbow"] || [lowercaseHexString isEqualToString:@"rainbow"]) {
            attributes[NSStrokeColorAttributeName] = [UIColor whiteColor];  // 设置描边为白色
            attributes[NSStrokeWidthAttributeName] = @(-1.0);               // 设置描边宽度，-1.0表示描边和填充
        }

        [attributedText addAttributes:attributes range:NSMakeRange(i, 1)];
    }
    label.attributedText = attributedText;
}

// 私有辅助方法：只解析单个十六进制颜色字符串，不处理渐变或彩虹
+ (UIColor *)_colorFromHexString:(NSString *)hexString {
    NSString *colorString =
        [[hexString stringByReplacingOccurrencesOfString:@"#"
                                              withString:@""] uppercaseString];
    CGFloat alpha = 1.0;
    unsigned int hexValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:colorString];

    if (colorString.length == 8) {
      // 8位十六进制：AARRGGBB，前两位为透明度
      if ([scanner scanHexInt:&hexValue]) {
           alpha = ((hexValue & 0xFF000000) >> 24) / 255.0;
      } else { return nil; }
    } else if (colorString.length == 6) {
      // 处理常规6位十六进制：RRGGBB
      if (![scanner scanHexInt:&hexValue]) {
          return nil;
      }
    } else if (colorString.length == 3) {
        // 3位简写格式：RGB
        NSString *r = [colorString substringWithRange:NSMakeRange(0, 1)];
        NSString *g = [colorString substringWithRange:NSMakeRange(1, 1)];
        NSString *b = [colorString substringWithRange:NSMakeRange(2, 1)];
        NSString *expandedColorString = [NSString stringWithFormat:@"%@%@%@%@%@%@", r, r, g, g, b, b];
        NSScanner *expandedScanner = [NSScanner scannerWithString:expandedColorString];
        if (![expandedScanner scanHexInt:&hexValue]) {
            return nil;
        }
    } else {
        return nil;
    }

    CGFloat red = ((hexValue & 0x00FF0000) >> 16) / 255.0;
    CGFloat green = ((hexValue & 0x0000FF00) >> 8) / 255.0;
    CGFloat blue = (hexValue & 0x000000FF) / 255.0;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

// 私有辅助方法：生成一个随机颜色
+ (UIColor *)_randomColor {
    return [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
                           green:(CGFloat)arc4random_uniform(256) / 255.0
                            blue:(CGFloat)arc4random_uniform(256) / 255.0
                           alpha:1.0];
}

// 私有辅助方法：通用渐变 Block 工厂，接收一个颜色数组，返回一个根据进度计算颜色的 Block
+ (UIColor *(^)(CGFloat progress))_gradientBlockWithColors:(NSArray<UIColor *> *)colors {
    if (!colors || colors.count == 0) {
        return ^UIColor *(CGFloat progress) { return [UIColor blackColor]; };
    }
    if (colors.count == 1) {
        UIColor *singleColor = colors.firstObject;
        return ^UIColor *(CGFloat progress) { return singleColor; };
    }

    return ^UIColor *(CGFloat progress) {
        progress = fmaxf(0.0, fminf(1.0, progress));

        CGFloat segmentWidth = 1.0 / (colors.count - 1);
        NSInteger startIndex = floor(progress / segmentWidth);

        if (startIndex >= colors.count - 1) {
            startIndex = colors.count - 2;
        }
        NSInteger endIndex = startIndex + 1;

        UIColor *startColor = colors[startIndex];
        UIColor *endColor = colors[endIndex];

        CGFloat segmentProgress = (progress - startIndex * segmentWidth) / segmentWidth;

        CGFloat startRed, startGreen, startBlue, startAlpha;
        CGFloat endRed, endGreen, endBlue, endAlpha;
        [startColor getRed:&startRed green:&startGreen blue:&startBlue alpha:&startAlpha];
        [endColor getRed:&endRed green:&endGreen blue:&endBlue alpha:&endAlpha];

        CGFloat red = startRed + (endRed - startRed) * segmentProgress;
        CGFloat green = startGreen + (endGreen - startGreen) * segmentProgress;
        CGFloat blue = startBlue + (endBlue - startBlue) * segmentProgress;
        CGFloat alpha = startAlpha + (endAlpha - startAlpha) * segmentProgress;

        return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    };
}

+ (UIColor *(^)(CGFloat progress))colorSchemeBlockWithHexString:(NSString *)hexString {
    UIColor *(^defaultScheme)(CGFloat) = ^UIColor *(CGFloat progress) {
        return [UIColor blackColor];
    };

    if (!hexString || hexString.length == 0) {
        return defaultScheme;
    }

    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    if ([lowercaseHexString isEqualToString:@"random_rainbow"] || [lowercaseHexString isEqualToString:@"#random_rainbow"]) {
        // 生成三个随机颜色，用于三色渐变
        UIColor *color1 = [self _randomColor];
        UIColor *color2 = [self _randomColor];
        UIColor *color3 = [self _randomColor];

        return [self _gradientBlockWithColors:@[color1, color2, color3]];
    }

    if ([lowercaseHexString isEqualToString:@"rainbow"] || [lowercaseHexString isEqualToString:@"#rainbow"]) {
        // 定义彩虹色数组 (ARC管理的对象)
        NSArray *rainbowColors = @[
            [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0], // 红
            [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0], // 橙
            [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0], // 黄
            [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0], // 绿
            [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0], // 青
            [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0], // 蓝
            [UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0]  // 紫
        ];

        return [self _gradientBlockWithColors:rainbowColors];
    }

    if ([lowercaseHexString isEqualToString:@"random"] || [lowercaseHexString isEqualToString:@"#random"]) {
        UIColor *randomColor = [self _randomColor];
        return ^UIColor *(CGFloat progress) {
            return randomColor;
        };
    }

    // 处理多色渐变方案 (逗号分隔的十六进制)
    if ([trimmedHexString containsString:@","]) {
        NSArray *hexComponents = [trimmedHexString componentsSeparatedByString:@","];
        NSMutableArray *gradientColors = [NSMutableArray array];
        for (NSString *hex in hexComponents) {
            UIColor *color = [self _colorFromHexString:hex];
            if (color) {
                [gradientColors addObject:color];
            }
        }

        return [self _gradientBlockWithColors:gradientColors];
    }

    // 处理单色方案 (单个十六进制)
    UIColor *singleColor = [self _colorFromHexString:trimmedHexString];
    if (singleColor) {
        return ^UIColor *(CGFloat progress) {
            return singleColor;
        };
    }

    return defaultScheme;
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

    if (!gradient) {
        UIGraphicsEndImageContext();
        if (colorSpace) CGColorSpaceRelease(colorSpace);
        return [UIColor blackColor];
    }

    CGPoint startPoint = CGPointMake(0, size.height / 2);
    CGPoint endPoint = CGPointMake(size.width, size.height / 2);

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGGradientRelease(gradient);
    if (colorSpace) CGColorSpaceRelease(colorSpace);

    if (gradientImage) {
        return [UIColor colorWithPatternImage:gradientImage];
    }
    return [UIColor blackColor];
  }

  // 如果包含半角逗号，则解析两个颜色代码并生成渐变色
  if ([hexString containsString:@","]) {
    NSArray *components = [hexString componentsSeparatedByString:@","];
    if (components.count == 2) {
      NSString *firstHex = [[components objectAtIndex:0]
          stringByTrimmingCharactersInSet:[NSCharacterSet
                                              whitespaceAndNewlineCharacterSet]];
      NSString *secondHex = [[components objectAtIndex:1]
          stringByTrimmingCharactersInSet:[NSCharacterSet
                                              whitespaceAndNewlineCharacterSet]];

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

      // 测试首尾两色渐变
      NSArray *colorsArray = @[
        (__bridge id)firstColor.CGColor,
        (__bridge id)secondColor.CGColor
      ];

      // 创建渐变
      CGGradientRef gradient = NULL;
      if (colorSpace && colorsArray.count == 2) {
        gradient = CGGradientCreateWithColors(
            colorSpace, (__bridge CFArrayRef)colorsArray, NULL);
      }

      if (!gradient) {
            UIGraphicsEndImageContext();
            if (colorSpace) CGColorSpaceRelease(colorSpace);
            return [UIColor blackColor];
      }

      CGPoint startPoint = CGPointMake(0, size.height / 2);
      CGPoint endPoint = CGPointMake(size.width, size.height / 2);

      CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
      UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      CGGradientRelease(gradient);
      if (colorSpace) CGColorSpaceRelease(colorSpace);

      if (gradientImage) {
            return [UIColor colorWithPatternImage:gradientImage];
      }
    }
    return [UIColor blackColor];
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
  BOOL scanSuccess = NO;
  unsigned int hexValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:colorString];

  if (colorString.length == 8) {
    // 8位十六进制：AARRGGBB，前两位为透明度
    if ([scanner scanHexInt:&hexValue]) {
         alpha = ((hexValue & 0xFF000000) >> 24) / 255.0;
         scanSuccess = YES;
    }
  } else if (colorString.length == 6) {
    // 处理常规6位十六进制：RRGGBB
    if ([scanner scanHexInt:&hexValue]) {
        scanSuccess = YES;
    }
  } else if (colorString.length == 3) {
      // 3位简写格式：RGB
      NSString *r = [colorString substringWithRange:NSMakeRange(0, 1)];
      NSString *g = [colorString substringWithRange:NSMakeRange(1, 1)];
      NSString *b = [colorString substringWithRange:NSMakeRange(2, 1)];
      NSString *expandedColorString =
          [NSString stringWithFormat:@"%@%@%@%@%@%@", r, r, g, g, b, b];
      NSScanner *expandedScanner = [NSScanner scannerWithString:expandedColorString];
      if ([expandedScanner scanHexInt:&hexValue]) {
        scanSuccess = YES;
      }
  }
  if (!scanSuccess) {
      return [UIColor blackColor];
  }
  CGFloat red = ((hexValue & 0x00FF0000) >> 16) / 255.0;
  CGFloat green = ((hexValue & 0x0000FF00) >> 8) / 255.0;
  CGFloat blue = (hexValue & 0x000000FF) / 255.0;

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

+ (NSString *)formattedSize:(unsigned long long)size {
    NSString *dataSizeString;
    if (size < 1024) {
        dataSizeString = [NSString stringWithFormat:@"%llu B", size];
    } else if (size < 1024 * 1024) {
        dataSizeString = [NSString stringWithFormat:@"%.2f KB", (double)size / 1024.0];
    } else if (size < 1024 * 1024 * 1024) {
        dataSizeString = [NSString stringWithFormat:@"%.2f MB", (double)size / (1024.0 * 1024.0)];
    } else {
        dataSizeString = [NSString stringWithFormat:@"%.2f GB", (double)size / (1024.0 * 1024.0 * 1024.0)];
    }
    return dataSizeString;
}

+ (unsigned long long)directorySizeAtPath:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    unsigned long long totalSize = 0;
    BOOL isDir = NO;
    if (![fileManager fileExistsAtPath:directoryPath isDirectory:&isDir] || !isDir) {
        return 0;
    }
    NSError *error = nil;
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) return 0;
    for (NSString *item in contents) {
        if ([item hasPrefix:@"."]) continue;
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:item];
        // 跳过符号链接，防止递归死循环
        NSDictionary *lstatAttrs = [fileManager attributesOfItemAtPath:fullPath error:nil];
        NSString *fileType = lstatAttrs[NSFileType];
        if ([fileType isEqualToString:NSFileTypeSymbolicLink]) {
            continue;
        }
        BOOL isSubDir = NO;
        @try {
            if ([fileManager fileExistsAtPath:fullPath isDirectory:&isSubDir]) {
                if (isSubDir) {
                    totalSize += [self directorySizeAtPath:fullPath];
                } else {
                    NSDictionary *attrs = [fileManager attributesOfItemAtPath:fullPath error:nil];
                    totalSize += attrs ? [attrs fileSize] : 0;
                }
            }
        } @catch (__unused NSException *exception) {
            // 忽略异常，防止递归卡死
            continue;
        }
    }
    return totalSize;
}

+ (void)removeAllContentsAtPath:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fileManager fileExistsAtPath:directoryPath isDirectory:&isDir] || !isDir) {
        return;
    }
    NSError *error = nil;
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) return;
    for (NSString *item in contents) {
        if ([item hasPrefix:@"."]) continue;
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:item];
        BOOL isSubDir = NO;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isSubDir]) {
            if (isSubDir) {
                [self removeAllContentsAtPath:fullPath];
                // 删除空文件夹本身
                [fileManager removeItemAtPath:fullPath error:nil];
            } else {
                [fileManager removeItemAtPath:fullPath error:nil];
            }
        }
    }
}

+ (NSString *)cacheDirectory {
    NSString *tmp = NSTemporaryDirectory();
    NSString *cacheDir = [tmp stringByAppendingPathComponent:@"DYYY"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:cacheDir]) {
        [fm createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cacheDir;
}

+ (void)clearCacheDirectory {
    [self removeAllContentsAtPath:[self cacheDirectory]];
}

+ (NSString *)cachePathForFilename:(NSString *)filename {
    return [[self cacheDirectory] stringByAppendingPathComponent:filename];
}

@end

BOOL viewContainsSubviewOfClass(UIView *view, Class viewClass) {
    if (!view)
        return NO;
    if ([view isKindOfClass:viewClass])
        return YES;
    for (UIView *subview in view.subviews) {
        if (viewContainsSubviewOfClass(subview, viewClass))
            return YES;
    }
    return NO;
}

BOOL isRightInteractionStack(UIView *stackView) {
    if (!stackView)
        return NO;
    NSString *label = stackView.accessibilityLabel;
    if (label) {
        if ([label isEqualToString:@"right"]) return YES;
        if ([label isEqualToString:@"left"]) return NO;
    }
    for (UIView *sub in stackView.subviews) {
        if (viewContainsSubviewOfClass(sub, NSClassFromString(@"AWEPlayInteractionUserAvatarView")))
            return YES;
        if (viewContainsSubviewOfClass(sub, NSClassFromString(@"AWEFeedAnchorContainerView")))
            return NO;
    }
    return NO;
}

BOOL isLeftInteractionStack(UIView *stackView) {
    if (!stackView)
        return NO;
    NSString *label = stackView.accessibilityLabel;
    if (label) {
        if ([label isEqualToString:@"left"]) return YES;
        if ([label isEqualToString:@"right"]) return NO;
    }
    for (UIView *sub in stackView.subviews) {
        if (viewContainsSubviewOfClass(sub, NSClassFromString(@"AWEFeedAnchorContainerView")))
            return YES;
        if (viewContainsSubviewOfClass(sub, NSClassFromString(@"AWEPlayInteractionUserAvatarView")))
            return NO;
    }
    return NO;
}
