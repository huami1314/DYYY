#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "DYYYUtils.h"
#import "DYYYToast.h"
#import "DYYYManager.h"
#import "AwemeHeaders.h"

@implementation DYYYUtils
    static NSArray<UIColor *> *_baseRainbowColors;
    static NSInteger _currentRainbowStartIndex;
    static NSCache *_gradientColorCache;

#pragma mark - Initialization

// +initialize 方法在类第一次被使用时调用，且只调用一次，是线程安全的
+ (void)initialize {
    if (self == [DYYYUtils class]) {
        // 1. 初始化缓存
        _gradientColorCache = [[NSCache alloc] init];
        _gradientColorCache.name = @"DYYYGradientColorCache";
        // 可以设置缓存限制，例如：
        // _gradientColorCache.countLimit = 100; // 最大缓存对象数量
        // _gradientColorCache.totalCostLimit = 10 * 1024 * 1024; // 最大缓存成本（例如10MB）

        // 2. 初始化彩虹颜色数组
        _baseRainbowColors = @[
            [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0], // 红
            [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0], // 橙
            [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0], // 黄
            [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0], // 绿
            [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0], // 青
            [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0], // 蓝
            [UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0]  // 紫
        ];

        // 3. 初始化当前彩虹索引
        _currentRainbowStartIndex = 0;
    }
}

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

    NSRange fullRange = NSMakeRange(0, attributedText.length);
    [attributedText removeAttribute:NSForegroundColorAttributeName range:fullRange];
    [attributedText removeAttribute:NSStrokeColorAttributeName range:fullRange];
    [attributedText removeAttribute:NSStrokeWidthAttributeName range:fullRange];
    [attributedText removeAttribute:NSShadowAttributeName range:fullRange];

    if (!colorHexString || colorHexString.length == 0) {
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
        label.attributedText = attributedText;
        return;
    }

    if (![attributedText attribute:NSFontAttributeName atIndex:0 effectiveRange:nil]) {
        if (label.font) {
            [attributedText addAttribute:NSFontAttributeName value:label.font range:fullRange];
        }
    }

    CGSize maxTextSize = CGSizeMake(CGFLOAT_MAX, label.bounds.size.height);
    CGRect textRect = [attributedText boundingRectWithSize:maxTextSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                   context:nil];
    CGFloat actualTextWidth = MAX(1.0, ceil(textRect.size.width));

    UIColor *finalTextColor = [self colorWithSchemeHexStringForPattern:colorHexString targetWidth:actualTextWidth];

    if (finalTextColor) {
        [attributedText addAttribute:NSForegroundColorAttributeName value:finalTextColor range:fullRange];
    } else {
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
    }
    label.attributedText = attributedText;
}

+ (void)applyStrokeToLabel:(UILabel *)label strokeColor:(UIColor *)strokeColor strokeWidth:(CGFloat)strokeWidth {
    if (!label || label.attributedText.length == 0) {
        return;
    }
    NSMutableAttributedString *mutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:label.attributedText];
    NSRange fullRange = NSMakeRange(0, mutableAttributedText.length);

    // 先移除现有的描边属性，确保新的描边能完全生效
    [mutableAttributedText removeAttribute:NSStrokeColorAttributeName range:fullRange];
    [mutableAttributedText removeAttribute:NSStrokeWidthAttributeName range:fullRange];

    if (strokeColor && strokeWidth != 0) { // 只有当描边颜色和宽度有效时才应用
        [mutableAttributedText addAttribute:NSStrokeColorAttributeName value:strokeColor range:fullRange];
        [mutableAttributedText addAttribute:NSStrokeWidthAttributeName value:@(strokeWidth) range:fullRange];
    }
    label.attributedText = mutableAttributedText;
}

+ (void)applyShadowToLabel:(UILabel *)label shadow:(NSShadow *)shadow {
    if (!label || label.attributedText.length == 0) {
        return;
    }
    NSMutableAttributedString *mutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:label.attributedText];
    NSRange fullRange = NSMakeRange(0, mutableAttributedText.length);

    // 先移除现有的阴影属性，确保新的阴影能完全生效
    [mutableAttributedText removeAttribute:NSShadowAttributeName range:fullRange];

    if (shadow) { // 只有当阴影对象有效时才应用
        [mutableAttributedText addAttribute:NSShadowAttributeName value:shadow range:fullRange];
    }
    label.attributedText = mutableAttributedText;
}

+ (UIColor *)colorWithSchemeHexStringForPattern:(NSString *)hexString targetWidth:(CGFloat)targetWidth {
    if (!hexString || hexString.length == 0) {
        return [UIColor whiteColor];
    }

    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    // 1. 优先处理纯随机色（不缓存）
    if ([lowercaseHexString isEqualToString:@"random"] || [lowercaseHexString isEqualToString:@"#random"]) {
        return [self _randomColor];
    }

    CGFloat quantizedWidth = ceil(targetWidth); // 向上取整到整数像素
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%.0f", lowercaseHexString, quantizedWidth];

    UIColor *cachedColor = [_gradientColorCache objectForKey:cacheKey];
    if (cachedColor) {
        return cachedColor;
    }

    // 2. 尝试解析渐变色（缓存）
    UIColor *finalColor = nil;
    NSArray<UIColor *> *gradientColors = [self gradientColorsForSchemeHexString:hexString];
    if (gradientColors && gradientColors.count > 0) {
        CGSize patternSize = CGSizeMake(MAX(1.0, quantizedWidth), 1);
        UIImage *gradientImage = [self _imageWithGradientColors:gradientColors size:patternSize];

        if (gradientImage) {
            finalColor = [UIColor colorWithPatternImage:gradientImage];
            if (finalColor) [_gradientColorCache setObject:finalColor forKey:cacheKey];
        }
    } else {
        // 3. 处理单色（缓存）
        UIColor *singleColor = [self _colorFromHexString:trimmedHexString];
        if (singleColor) {
            finalColor = singleColor;
            [_gradientColorCache setObject:finalColor forKey:cacheKey];
        }
    }

    if (!finalColor) finalColor = [UIColor whiteColor];
    return finalColor;
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

    // 2. 尝试解析渐变颜色数组
    NSArray<UIColor *> *gradientColors = [self gradientColorsForSchemeHexString:hexString];
    if (gradientColors && gradientColors.count > 0) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = frame;
        
        NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:gradientColors.count];
        for (UIColor *color in gradientColors) {
            [cgColors addObject:(__bridge id)color.CGColor];
        }
        gradientLayer.colors = cgColors;

        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);

        return gradientLayer;
    } else if (singleColor) { // 如果是纯色则返回一个普通的 CALayer
        CALayer *layer = [CALayer layer];
        layer.frame = frame;
        layer.backgroundColor = singleColor.CGColor;
        return layer;
    }

    return nil; // 无法解析的颜色方案
}

+ (NSArray<UIColor *> *)gradientColorsForSchemeHexString:(NSString *)hexString {
    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    if ([lowercaseHexString isEqualToString:@"rainbow"] || [lowercaseHexString isEqualToString:@"#rainbow"]) {
        return _baseRainbowColors;
    }

    if ([lowercaseHexString isEqualToString:@"rotating_rainbow"] || [lowercaseHexString isEqualToString:@"#rotating_rainbow"]) {
        return [self _rotatedRainbowColors];
    }

    if ([lowercaseHexString isEqualToString:@"random_gradient"] || [lowercaseHexString isEqualToString:@"#random_gradient"]) {
        return @[[self _randomColor], [self _randomColor], [self _randomColor]];
    }

    if ([trimmedHexString containsString:@","]) {
        // 处理逗号分隔的多色渐变
        NSArray *hexComponents = [trimmedHexString componentsSeparatedByString:@","];
        NSMutableArray *gradientColors = [NSMutableArray array];
        for (NSString *hex in hexComponents) {
            UIColor *color = [self _colorFromHexString:hex];
            if (color) [gradientColors addObject:color];
        }
        if (gradientColors.count >= 2) { // 确保至少有两个颜色才能形成有效渐变
            return [gradientColors copy];
        }
    }

    return nil; // 不是渐变方案，或者颜色数量不足以形成渐变
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

// 私有辅助方法：获取当前旋转状态的彩虹颜色数组，并更新索引
+ (NSArray<UIColor *> *)_rotatedRainbowColors {
    NSUInteger count = _baseRainbowColors.count;
    if (count == 0) return @[];

    NSMutableArray<UIColor *> *rotatedColors = [NSMutableArray arrayWithCapacity:count];

    @synchronized (self) { // 线程安全地访问和更新索引
        for (NSUInteger i = 0; i < count; i++) {
            [rotatedColors addObject:_baseRainbowColors[(_currentRainbowStartIndex + i) % count]];
        }
        _currentRainbowStartIndex = (_currentRainbowStartIndex + 1) % count;
    }
    return [rotatedColors copy];
}

+ (UIImage *)_imageWithGradientColors:(NSArray<UIColor *> *)colors size:(CGSize)size {
    if (!colors || colors.count < 2 || size.width <= 0 || size.height <= 0) {
        return nil;
    }

    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // 创建CGGradient
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        [cgColors addObject:(__bridge id)color.CGColor];
    }

    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)cgColors, NULL);

    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(size.width, 0);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    return image;
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
