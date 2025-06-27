#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "DYYYUtils.h"
#import "DYYYToast.h"
#import "DYYYManager.h"
#import "AwemeHeaders.h"

@implementation DYYYUtils

#pragma mark - Public UI/Window/Controller Utilities (公共 UI/窗口/控制器 工具)

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

#pragma mark - Public Color Scheme Methods (公共颜色方案方法)

+ (void)applyColorSettingsToLabel:(UILabel *)label colorHexString:(NSString *)colorHexString {
    NSMutableAttributedString *attributedText;
    if ([label.attributedText isKindOfClass:[NSAttributedString class]]) {
        attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:label.attributedText];
    } else {
        attributedText = [[NSMutableAttributedString alloc] initWithString:label.text ?: @""];
    }

    if (attributedText.length == 0) {
        label.attributedText = attributedText;
        return;
    }

    [attributedText removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, attributedText.length)];
    [attributedText removeAttribute:NSStrokeColorAttributeName range:NSMakeRange(0, attributedText.length)];
    [attributedText removeAttribute:NSStrokeWidthAttributeName range:NSMakeRange(0, attributedText.length)];

    if (!colorHexString || colorHexString.length == 0) {
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attributedText.length)];
        label.attributedText = attributedText;
        return;
    }

    NSString *trimmedHexString = [colorHexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    // 获取颜色计算 Block
    UIColor * (^colorScheme)(CGFloat) = [self colorSchemeBlockWithHexString:lowercaseHexString];

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

        [attributedText addAttributes:attributes range:NSMakeRange(i, 1)];
    }
    label.attributedText = attributedText;
}

+ (UIColor *(^)(CGFloat progress))colorSchemeBlockWithHexString:(NSString *)hexString {
    UIColor *(^defaultScheme)(CGFloat) = ^UIColor *(CGFloat progress) {
        return [UIColor whiteColor];
    };

    if (!hexString || hexString.length == 0) {
        return defaultScheme;
    }

    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    // 1. 优先处理纯随机色
    if ([lowercaseHexString isEqualToString:@"random"] || [lowercaseHexString isEqualToString:@"#random"]) {
        UIColor *randomColor = [self _randomColor];
        return ^UIColor *(CGFloat progress) {
            return randomColor; // 始终返回同一个随机色
        };
    }

    // 2. 尝试获取渐变颜色数组 (包括 rainbow, random_rainbow, 多色渐变)
    NSArray<UIColor *> *gradientColors = [self _gradientColorsForSchemeHexString:hexString];
    if (gradientColors && gradientColors.count > 0) {
        return [self _gradientBlockWithColors:gradientColors];
    }

    // 3. 处理单色方案 (单个十六进制)
    UIColor *singleColor = [self _colorFromHexString:trimmedHexString];
    if (singleColor) {
        return ^UIColor *(CGFloat progress) {
            return singleColor; // 始终返回同一个单色
        };
    }

    return defaultScheme; // 无法解析的方案
}

+ (CALayer *)colorSchemeLayerWithHexString:(NSString *)hexString frame:(CGRect)frame {
    if (!hexString || hexString.length == 0 || CGRectIsEmpty(frame)) {
        return nil;
    }

    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    // 1. 优先处理纯色或纯随机色
    UIColor *singleColor = nil;
    if ([lowercaseHexString isEqualToString:@"random"] || [lowercaseHexString isEqualToString:@"#random"]) {
        singleColor = [self _randomColor];
    } else {
        singleColor = [self _colorFromHexString:trimmedHexString];
    }

    // 如果是纯色或纯随机色，并且不是渐变方案，则返回一个普通的 CALayer
    if (singleColor && ![self _gradientColorsForSchemeHexString:hexString]) {
        CALayer *layer = [CALayer layer];
        layer.frame = frame;
        layer.backgroundColor = singleColor.CGColor;
        return layer;
    }

    // 2. 尝试获取渐变颜色数组
    NSArray<UIColor *> *gradientColors = [self _gradientColorsForSchemeHexString:hexString];
    if (gradientColors && gradientColors.count > 0) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = frame;
        
        // 将 UIColor 数组转换为 CGColorRef 数组
        NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:gradientColors.count];
        for (UIColor *color in gradientColors) {
            [cgColors addObject:(__bridge id)color.CGColor];
        }
        gradientLayer.colors = cgColors;

        // 默认水平渐变，可根据需求调整 startPoint 和 endPoint
        gradientLayer.startPoint = CGPointMake(0.0, 0.5); // 从左到右
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);

        return gradientLayer;
    }

    return nil; // 无法解析的颜色方案
}

+ (UIColor *)colorWithSchemeHexStringForPattern:(NSString *)hexString {
    if (!hexString || hexString.length == 0) {
        return [UIColor whiteColor];
    }

    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    // 1. 优先处理纯随机色
    if ([lowercaseHexString isEqualToString:@"random"] || [lowercaseHexString isEqualToString:@"#random"]) {
        return [self _randomColor];
    }

    // 2. 尝试解析为单色 (非渐变方案)
    // 只有当 _gradientColorsForSchemeHexString 返回 nil 时，才可能是纯单色
    if (![self _gradientColorsForSchemeHexString:hexString]) {
        UIColor *singleColor = [self _colorFromHexString:trimmedHexString];
        if (singleColor) {
            return singleColor;
        }
    }

    // 3. 对于渐变色（包括 rainbow, random_rainbow, 多色渐变），使用图案填充
    UIColor *(^gradientBlock)(CGFloat progress) = [self colorSchemeBlockWithHexString:hexString];

    // 定义图案图像的尺寸。宽度足够大以避免重复，高度为1以避免垂直拉伸形变。
    // 2000x1 是一个经验值，可以覆盖大多数文本宽度，且垂直方向不会有形变。
    CGSize patternSize = CGSizeMake(2000, 1);

    UIImage *gradientImage = [self _imageWithGradientBlock:gradientBlock size:patternSize];

    if (gradientImage) {
        return [UIColor colorWithPatternImage:gradientImage];
    }

    return [UIColor whiteColor]; // 无法解析的方案
}

#pragma mark - Public File Management (公共文件管理)

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

#pragma mark - Private Helper Methods (私有辅助方法)

/**
 * @brief 私有辅助方法：解析单个十六进制颜色字符串。
 * @param hexString 十六进制颜色字符串，例如 "#FF0000", "FF0000", "#F00", "F00", "#AARRGGBB"
 * @return 解析出的 UIColor 对象。如果格式无效，返回 nil。
 */
+ (UIColor *)_colorFromHexString:(NSString *)hexString {
    NSString *colorString =
        [[hexString stringByReplacingOccurrencesOfString:@"#"
                                              withString:@""] uppercaseString];
    CGFloat alpha = 1.0;
    unsigned int hexValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:colorString];

    BOOL scanSuccess = NO;
    if (colorString.length == 8) { // AARRGGBB
      if ([scanner scanHexInt:&hexValue]) {
           alpha = ((hexValue & 0xFF000000) >> 24) / 255.0;
           scanSuccess = YES;
      }
    } else if (colorString.length == 6) { // RRGGBB
      if ([scanner scanHexInt:&hexValue]) {
          scanSuccess = YES;
      }
    } else if (colorString.length == 3) { // RGB (简写)
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
        return nil; // 返回 nil 表示解析失败
    }
    CGFloat red = ((hexValue & 0x00FF0000) >> 16) / 255.0;
    CGFloat green = ((hexValue & 0x0000FF00) >> 8) / 255.0;
    CGFloat blue = (hexValue & 0x000000FF) / 255.0;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

/**
 * @brief 私有辅助方法：生成一个随机颜色。
 * @return 随机生成的 UIColor 对象。
 */
+ (UIColor *)_randomColor {
    return [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
                           green:(CGFloat)arc4random_uniform(256) / 255.0
                            blue:(CGFloat)arc4random_uniform(256) / 255.0
                           alpha:1.0];
}

/**
 * @brief 私有辅助方法：通用渐变 Block 工厂，接收一个颜色数组，返回一个根据进度计算颜色的 Block。
 *        此 Block 实现了颜色在数组中的平滑过渡。
 * @param colors 包含 UIColor 对象的数组，至少需要两个颜色才能形成渐变。
 * @return 一个 UIColor *(^)(CGFloat progress) Block。如果颜色数组无效，返回一个始终返回黑色的 Block。
 */
+ (UIColor *(^)(CGFloat progress))_gradientBlockWithColors:(NSArray<UIColor *> *)colors {
    if (!colors || colors.count == 0) {
        return ^UIColor *(CGFloat progress) { return [UIColor whiteColor]; };
    }
    if (colors.count == 1) { // 单色也视为一种特殊的“渐变”
        UIColor *singleColor = colors.firstObject;
        return ^UIColor *(CGFloat progress) { return singleColor; };
    }

    return ^UIColor *(CGFloat progress) {
        progress = fmaxf(0.0, fminf(1.0, progress)); // 确保进度在 0.0 到 1.0 之间

        // 计算当前进度所在的颜色段
        CGFloat segmentWidth = 1.0 / (colors.count - 1);
        NSInteger startIndex = floor(progress / segmentWidth);

        // 边界处理
        if (startIndex >= colors.count - 1) {
            startIndex = colors.count - 2;
        }
        NSInteger endIndex = startIndex + 1;

        UIColor *startColor = colors[startIndex];
        UIColor *endColor = colors[endIndex];

        CGFloat segmentProgress = (progress - startIndex * segmentWidth);
        
        // 颜色插值计算
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

/**
 * @brief 私有辅助方法：根据颜色方案字符串解析出渐变所需的颜色数组。
 *        此方法专门处理多色渐变、"rainbow" 和 "random_rainbow" 方案。
 * @param hexString 颜色方案字符串。
 * @return 包含 UIColor 对象的数组。如果不是渐变方案（例如单色或纯随机色），则返回 nil。
 */
+ (NSArray<UIColor *> *)_gradientColorsForSchemeHexString:(NSString *)hexString {
    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    if ([lowercaseHexString isEqualToString:@"rainbow"] || [lowercaseHexString isEqualToString:@"#rainbow"]) {
        // 定义彩虹色数组
        return @[
            [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0], // 红
            [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0], // 橙
            [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0], // 黄
            [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0], // 绿
            [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0], // 青
            [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0], // 蓝
            [UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0]  // 紫
        ];
    }

    if ([lowercaseHexString isEqualToString:@"random_rainbow"] || [lowercaseHexString isEqualToString:@"#random_rainbow"]) {
        // 生成三个随机颜色用于三色渐变
        return @[[self _randomColor], [self _randomColor], [self _randomColor]];
    }

    if ([trimmedHexString containsString:@","]) {
        // 处理逗号分隔的多色渐变
        NSArray *hexComponents = [trimmedHexString componentsSeparatedByString:@","];
        NSMutableArray *gradientColors = [NSMutableArray array];
        for (NSString *hex in hexComponents) {
            UIColor *color = [self _colorFromHexString:hex];
            if (color) {
                [gradientColors addObject:color];
            }
        }
        // 确保至少有两个颜色才能形成有效渐变
        if (gradientColors.count >= 2) {
            return [gradientColors copy];
        }
    }

    return nil; // 不是渐变方案，或者颜色数量不足以形成渐变
}

/**
 * @brief 私有辅助方法：将颜色计算 Block 渲染成 UIImage。
 *        用于创建 UIColor 的 patternImage。
 * @param gradientBlock 颜色计算 Block。
 * @param size 渲染图像的尺寸。
 * @return 渲染出的 UIImage 对象。
 */
+ (UIImage *)_imageWithGradientBlock:(UIColor *(^)(CGFloat progress))gradientBlock size:(CGSize)size {
    if (!gradientBlock || size.width <= 0 || size.height <= 0) {
        return nil;
    }

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // 遍历图像的宽度，逐像素绘制颜色
    for (int x = 0; x < size.width; x++) {
        CGFloat progress = (CGFloat)x / (size.width - 1); // 计算当前像素的进度 (0.0 到 1.0)
        UIColor *color = gradientBlock(progress); // 获取当前进度的颜色

        if (color) {
            [color setFill]; // 设置填充颜色
            CGContextFillRect(context, CGRectMake(x, 0, 1, size.height)); // 绘制1像素宽的垂直条
        }
    }

    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return gradientImage;
}

@end

#pragma mark - External C Functions (外部 C 函数)

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

UIViewController *findViewControllerOfClass(UIViewController *vc, Class targetClass) {
    if (!vc)
        return nil;
    if ([vc isKindOfClass:targetClass])
        return vc;
    for (UIViewController *childVC in vc.childViewControllers) {
        UIViewController *found = findViewControllerOfClass(childVC, targetClass);
        if (found)
            return found;
    }
    return findViewControllerOfClass(vc.presentedViewController, targetClass);
}

void applyTopBarTransparency(UIView *topBar) {
    if (!topBar)
        return;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnablePure"]) {
        return;
    }

    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYtopbartransparent"];
    if (transparentValue && transparentValue.length > 0) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {
            CGFloat finalAlpha = (alphaValue < 0.011) ? 0.011 : alphaValue;

            UIColor *backgroundColor = topBar.backgroundColor;
            if (backgroundColor) {
                CGFloat r, g, b, a;
                if ([backgroundColor getRed:&r green:&g blue:&b alpha:&a]) {
                    topBar.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:finalAlpha * a];
                }
            }

            topBar.alpha = finalAlpha;
            for (UIView *subview in topBar.subviews) {
                subview.alpha = 1.0;
            }
        }
    }
}

id DYYYJSONSafeObject(id obj) {
    if (!obj || obj == [NSNull null]) {
        return [NSNull null];
    }
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]]) {
        return obj;
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id value in (NSArray *)obj) {
            id safeValue = DYYYJSONSafeObject(value);
            if (safeValue) [array addObject:safeValue];
        }
        return array;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (id key in (NSDictionary *)obj) {
            id safeValue = DYYYJSONSafeObject([(NSDictionary *)obj objectForKey:key]);
            if (safeValue) dict[key] = safeValue;
        }
        return dict;
    }
    if ([obj isKindOfClass:[NSData class]]) {
        return [(NSData *)obj base64EncodedStringWithOptions:0];
    }
    if ([obj isKindOfClass:[NSDate class]]) {
        return @([(NSDate *)obj timeIntervalSince1970]);
    }
    return [obj description];
}
