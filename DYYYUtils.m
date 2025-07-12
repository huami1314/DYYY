#import "DYYYUtils.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <UIKit/UIKit.h>
#import <os/lock.h>
#import <stdatomic.h>
#import "AwemeHeaders.h"
#import "DYYYManager.h"
#import "DYYYToast.h"

@implementation DYYYUtils

#pragma mark - Public UI Utilities (公共 UI/窗口/控制器 工具)

+ (UIWindow *)getActiveWindow {
    if (@available(iOS 15.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
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

+ (UIViewController *)topView {
    UIWindow *window = [self getActiveWindow];
    if (!window)
        return nil;

    UIViewController *topViewController = window.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

+ (UIViewController *)firstAvailableViewControllerFromView:(UIView *)view {
    UIResponder *responder = view;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

+ (UIViewController *)findViewControllerOfClass:(Class)targetClass inViewController:(UIViewController *)vc {
    if (!vc)
        return nil;
    if ([vc isKindOfClass:targetClass]) {
        return vc;
    }
    for (UIViewController *childVC in vc.childViewControllers) {
        UIViewController *found = [self findViewControllerOfClass:targetClass inViewController:childVC];
        if (found)
            return found;
    }
    return [self findViewControllerOfClass:targetClass inViewController:vc.presentedViewController];
}

+ (UIResponder *)findAncestorResponderOfClass:(Class)targetClass fromView:(UIView *)view {
    if (!view)
        return nil;
    UIResponder *responder = view.superview;
    while (responder) {
        if ([responder isKindOfClass:targetClass]) {
            return responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

+ (NSArray<UIView *> *)findAllSubviewsOfClass:(Class)targetClass inView:(UIView *)view {
    if (!view)
        return @[];
    NSMutableArray *foundViews = [NSMutableArray array];
    if ([view isKindOfClass:targetClass]) {
        [foundViews addObject:view];
    }
    for (UIView *subview in view.subviews) {
        [foundViews addObjectsFromArray:[self findAllSubviewsOfClass:targetClass inView:subview]];
    }
    return [foundViews copy];
}

+ (UIView *)findSubviewOfClass:(Class)targetClass inView:(UIView *)view {
    if (!view)
        return nil;
    if ([view isKindOfClass:targetClass]) {
        return view;
    }
    for (UIView *subview in view.subviews) {
        UIView *result = [self findSubviewOfClass:targetClass inView:subview];
        if (result) {
            return result;
        }
    }
    return nil;
}

+ (BOOL)containsSubviewOfClass:(Class)targetClass inView:(UIView *)view {
    if (!view)
        return NO;
    if ([view isKindOfClass:targetClass]) {
        return YES;
    }
    for (UIView *subview in view.subviews) {
        if ([self containsSubviewOfClass:targetClass inView:subview]) {
            return YES;
        }
    }
    return NO;
}

+ (void)applyBlurEffectToView:(UIView *)view transparency:(float)userTransparency blurViewTag:(NSInteger)tag {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!view)
          return;

      view.backgroundColor = [UIColor clearColor];

      UIVisualEffectView *existingBlurView = nil;
      for (UIView *subview in view.subviews) {
          if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == tag) {
              existingBlurView = (UIVisualEffectView *)subview;
              break;
          }
      }

      BOOL isDarkMode = [DYYYUtils isDarkMode];
      UIBlurEffectStyle blurStyle = isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;

      UIView *overlayView = nil;

      if (!existingBlurView) {
          UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
          UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
          blurEffectView.frame = view.bounds;
          blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
          blurEffectView.alpha = userTransparency;
          blurEffectView.tag = tag;

          overlayView = [[UIView alloc] initWithFrame:view.bounds];
          overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
          [blurEffectView.contentView addSubview:overlayView];

          [view insertSubview:blurEffectView atIndex:0];
      } else {
          UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
          [existingBlurView setEffect:blurEffect];
          existingBlurView.alpha = userTransparency;

          for (UIView *subview in existingBlurView.contentView.subviews) {
              if ([subview isKindOfClass:[UIView class]]) {
                  overlayView = subview;
                  break;
              }
          }
          if (!overlayView) {
              overlayView = [[UIView alloc] initWithFrame:existingBlurView.bounds];
              overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
              [existingBlurView.contentView addSubview:overlayView];
          }
      }
      if (overlayView) {
          CGFloat alpha = isDarkMode ? 0.2 : 0.1;
          overlayView.backgroundColor = [UIColor colorWithWhite:(isDarkMode ? 0 : 1) alpha:alpha];
      }
    });
}

+ (void)clearBackgroundRecursivelyInView:(UIView *)view {
    if (!view)
        return;

    BOOL shouldClear = YES;

    if ([view isKindOfClass:[UIVisualEffectView class]]) {
        shouldClear = NO;  // 不清除 UIVisualEffectView 本身的背景
    } else if (view.superview && [view.superview isKindOfClass:[UIVisualEffectView class]]) {
        shouldClear = NO;  // 不清除 UIVisualEffectView 的 contentView 的背景
    }

    if (shouldClear) {
        view.backgroundColor = [UIColor clearColor];
        view.opaque = NO;
    }

    for (UIView *subview in view.subviews) {
        [self clearBackgroundRecursivelyInView:subview];
    }
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

    NSURL *directoryURL = [NSURL fileURLWithPath:directoryPath];

    NSArray<NSURLResourceKey> *keys = @[ NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey, NSURLFileSizeKey ];

    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:directoryURL
                                          includingPropertiesForKeys:keys
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                          NSLog(@"Error enumerating %@: %@", url.path, error);
                                                          return YES;
                                                        }];

    for (NSURL *fileURL in enumerator) {
        NSError *resourceError;
        NSDictionary<NSURLResourceKey, id> *resourceValues = [fileURL resourceValuesForKeys:keys error:&resourceError];

        if (resourceError) {
            NSLog(@"Error getting resource values for %@: %@", fileURL.path, resourceError);
            continue;
        }

        NSNumber *isDirectory = resourceValues[NSURLIsDirectoryKey];
        NSNumber *isSymbolicLink = resourceValues[NSURLIsSymbolicLinkKey];
        if (isDirectory.boolValue || isSymbolicLink.boolValue) {
            continue;
        }

        NSNumber *fileSize = resourceValues[NSURLFileSizeKey];
        if (fileSize) {
            totalSize += fileSize.unsignedLongLongValue;
        } else {
            NSLog(@"Missing file size for %@", fileURL.path);
        }
    }
    return totalSize;
}

+ (void)removeAllContentsAtPath:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;

    if (![fileManager fileExistsAtPath:directoryPath isDirectory:&isDir] || !isDir) {
        NSLog(@"[CacheClean] Path is not a directory or does not exist: %@", directoryPath);
        return;
    }

    NSURL *directoryURL = [NSURL fileURLWithPath:directoryPath];

    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:directoryURL
                                          includingPropertiesForKeys:@[ NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey ]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *enumError) {
                                                          NSLog(@"[CacheClean] Error enumerating directory %@: %@", url, enumError);
                                                          return YES;
                                                        }];

    NSMutableArray<NSURL *> *itemsToDelete = [NSMutableArray array];
    for (NSURL *itemURL in enumerator) {
        NSNumber *isSymbolicLink;
        [itemURL getResourceValue:&isSymbolicLink forKey:NSURLIsSymbolicLinkKey error:nil];
        if ([isSymbolicLink boolValue]) {
            continue;
        }
        [itemsToDelete addObject:itemURL];
    }

    for (NSURL *itemURL in [itemsToDelete reverseObjectEnumerator]) {
        NSError *removeError = nil;
        if ([fileManager removeItemAtURL:itemURL error:&removeError]) {
            // NSLog(@"[CacheClean] Successfully removed: %@", itemURL.lastPathComponent);
        } else {
            NSLog(@"[CacheClean] Error removing %@: %@", itemURL.path, removeError);
        }
    }
}

// MARK: - Cache Utilities

+ (NSString *)cacheDirectory {
    NSString *tmpDir = NSTemporaryDirectory();
    if (!tmpDir) {
        tmpDir = @"/tmp";
    }
    NSString *cacheDir = [tmpDir stringByAppendingPathComponent:@"DYYY"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fileManager fileExistsAtPath:cacheDir isDirectory:&isDir] || !isDir) {
        [fileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return cacheDir;
}

+ (void)clearCacheDirectory {
    NSString *cacheDir = [self cacheDirectory];
    [self removeAllContentsAtPath:cacheDir];
}

+ (NSString *)cachePathForFilename:(NSString *)filename {
    return [[self cacheDirectory] stringByAppendingPathComponent:filename];
}

#pragma mark - Public Color Scheme Methods (公共颜色方案方法)

static NSCache *_gradientColorCache;
static NSArray<UIColor *> *_baseRainbowColors;
static atomic_uint_fast64_t _rainbowRotationCounter = 0;
static os_unfair_lock _staticColorCreationLock = OS_UNFAIR_LOCK_INIT;

// +initialize 方法在类第一次被使用时调用，且只调用一次，是线程安全的
+ (void)initialize {
    if (self == [DYYYUtils class]) {
        _gradientColorCache = [[NSCache alloc] init];
        _gradientColorCache.name = @"DYYYGradientColorCache";
        // 可以自定义缓存限制，例如：
        // _gradientColorCache.countLimit = 100; // 最大缓存对象数量
        // _gradientColorCache.totalCostLimit = 10 * 1024 * 1024; // 最大缓存成本（例如10MB）

        _baseRainbowColors = @[
            [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0],  // 红
            [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0],  // 橙
            [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0],  // 黄
            [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0],  // 绿
            [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0],  // 青
            [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0],  // 蓝
            [UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0]   // 紫
        ];

        atomic_init(&_rainbowRotationCounter, 0);
    }
}

+ (void)applyTextColorRecursively:(UIColor *)color inView:(UIView *)view shouldExcludeViewBlock:(BOOL (^)(UIView *subview))excludeBlock {
    if (!view || !color)
        return;

    BOOL shouldExclude = NO;
    if (excludeBlock)
        shouldExclude = excludeBlock(view);

    if (!shouldExclude) {
        if ([view isKindOfClass:[UILabel class]]) {
            ((UILabel *)view).textColor = color;
        } else if ([view isKindOfClass:[UIButton class]]) {
            [(UIButton *)view setTitleColor:color forState:UIControlStateNormal];
        }
    }

    for (UIView *subview in view.subviews) {
        [self applyTextColorRecursively:color inView:subview shouldExcludeViewBlock:excludeBlock];
    }
}

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
    CGRect textRect = [attributedText boundingRectWithSize:maxTextSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGFloat actualTextWidth = MAX(1.0, ceil(textRect.size.width));

    UIColor *finalTextColor = [self colorFromSchemeHexString:colorHexString targetWidth:actualTextWidth];

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

    if (strokeColor && strokeWidth != 0) {  // 只有当描边颜色和宽度有效时才应用
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

    if (shadow) {  // 只有当阴影对象有效时才应用
        [mutableAttributedText addAttribute:NSShadowAttributeName value:shadow range:fullRange];
    }
    label.attributedText = mutableAttributedText;
}

+ (UIColor *)colorFromSchemeHexString:(NSString *)hexString targetWidth:(CGFloat)targetWidth {
    if (!hexString || hexString.length == 0) {
        return [UIColor whiteColor];
    }

    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    // 1. 处理随机纯色（不缓存）
    if ([lowercaseHexString isEqualToString:@"random"] || [lowercaseHexString isEqualToString:@"#random"]) {
        return [self _randomColor];
    }
    // 2. 处理随机渐变（不缓存）
    if ([lowercaseHexString isEqualToString:@"random_gradient"] || [lowercaseHexString isEqualToString:@"#random_gradient"]) {
        NSArray<UIColor *> *randomGradientColors = @[ [self _randomColor], [self _randomColor], [self _randomColor] ];
        CGSize patternSize = CGSizeMake(MAX(1.0, ceil(targetWidth)), 1);
        UIImage *gradientImage = [self _imageWithGradientColors:randomGradientColors size:patternSize];
        if (gradientImage) {
            return [UIColor colorWithPatternImage:gradientImage];
        }
        return [UIColor whiteColor];  // Fallback
    }

    // 3. 处理旋转彩虹（缓存）
    CGFloat quantizedWidth = ceil(targetWidth);
    if ([lowercaseHexString isEqualToString:@"rainbow_rotating"] || [lowercaseHexString isEqualToString:@"#rainbow_rotating"]) {
        NSUInteger count = _baseRainbowColors.count;
        if (count == 0)
            return [UIColor whiteColor];

        uint_fast64_t currentRotationIndex = atomic_fetch_add(&_rainbowRotationCounter, 1) % count;

        NSString *cacheKey = [NSString stringWithFormat:@"%@_%.0f_idx_%llu", lowercaseHexString, quantizedWidth, currentRotationIndex];

        UIColor *cachedColor = [_gradientColorCache objectForKey:cacheKey];
        if (cachedColor) {
            return cachedColor;
        }

        NSArray<UIColor *> *rotatedColors = [self _rotatedRainbowColorsForIndex:currentRotationIndex];
        CGSize patternSize = CGSizeMake(MAX(1.0, quantizedWidth), 1);
        UIImage *gradientImage = [self _imageWithGradientColors:rotatedColors size:patternSize];

        if (gradientImage) {
            UIColor *finalColor = [UIColor colorWithPatternImage:gradientImage];
            if (finalColor)
                [_gradientColorCache setObject:finalColor forKey:cacheKey];
            return finalColor;
        }
        return [UIColor whiteColor];
    }

    // 4. 处理静态颜色（缓存）
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%.0f", lowercaseHexString, quantizedWidth];

    UIColor *cachedColor = [_gradientColorCache objectForKey:cacheKey];
    if (cachedColor) {
        return cachedColor;
    }

    os_unfair_lock_lock(&_staticColorCreationLock);
    @try {
        cachedColor = [_gradientColorCache objectForKey:cacheKey];
        if (cachedColor)
            return cachedColor;

        UIColor *finalColor = nil;
        NSArray<UIColor *> *gradientColors = [self _staticGradientColorsForHexString:hexString];
        if (gradientColors && gradientColors.count > 0) {
            CGSize patternSize = CGSizeMake(MAX(1.0, quantizedWidth), 1);
            UIImage *gradientImage = [self _imageWithGradientColors:gradientColors size:patternSize];

            if (gradientImage) {
                finalColor = [UIColor colorWithPatternImage:gradientImage];
            }
        } else {
            UIColor *singleColor = [self _colorFromHexString:trimmedHexString];
            if (singleColor) {
                finalColor = singleColor;
            }
        }

        if (finalColor) {
            [_gradientColorCache setObject:finalColor forKey:cacheKey];
        }
        return finalColor;
    } @finally {
        os_unfair_lock_unlock(&_staticColorCreationLock);
    }

    return [UIColor whiteColor];
}

+ (CALayer *)layerFromSchemeHexString:(NSString *)hexString frame:(CGRect)frame {
    if (!hexString || hexString.length == 0 || CGRectIsEmpty(frame)) {
        return nil;
    }

    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    // 处理动态颜色方案，直接生成 CALayer
    if ([lowercaseHexString isEqualToString:@"random"] || [lowercaseHexString isEqualToString:@"#random"]) {
        CALayer *layer = [CALayer layer];
        layer.frame = frame;
        layer.backgroundColor = [self _randomColor].CGColor;
        return layer;
    }
    if ([lowercaseHexString isEqualToString:@"rainbow_rotating"] || [lowercaseHexString isEqualToString:@"#rainbow_rotating"]) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = frame;

        NSUInteger count = _baseRainbowColors.count;
        if (count == 0)
            return nil;
        uint_fast64_t currentRotationIndex = atomic_fetch_add(&_rainbowRotationCounter, 1) % count;     // 同样原子递增
        NSArray<UIColor *> *rotatedColors = [self _rotatedRainbowColorsForIndex:currentRotationIndex];  // 使用指定索引获取颜色数组

        NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:rotatedColors.count];
        for (UIColor *color in rotatedColors) {
            [cgColors addObject:(__bridge id)color.CGColor];
        }
        gradientLayer.colors = cgColors;
        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);
        return gradientLayer;
    }
    if ([lowercaseHexString isEqualToString:@"random_gradient"] || [lowercaseHexString isEqualToString:@"#random_gradient"]) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = frame;

        NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:3];
        for (int i = 0; i < 3; i++) {
            [cgColors addObject:(__bridge id)[self _randomColor].CGColor];
        }
        gradientLayer.colors = cgColors;
        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);
        return gradientLayer;
    }

    // 解析静态渐变颜色数组
    NSArray<UIColor *> *gradientColors = [self _staticGradientColorsForHexString:hexString];
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
    } else {  // 如果不是渐变，则尝试作为单色处理
        UIColor *singleColor = [self _colorFromHexString:trimmedHexString];
        if (singleColor) {
            CALayer *layer = [CALayer layer];
            layer.frame = frame;
            layer.backgroundColor = singleColor.CGColor;
            return layer;
        }
    }

    return nil;  // 无法解析的颜色方案
}

#pragma mark - Private Helper Methods (私有辅助方法)

/**
 * @brief 私有辅助方法：解析单个十六进制颜色字符串。
 * @param hexString 十六进制颜色字符串，例如 "#FF0000", "FF0000", "#F00", "F00", "#AARRGGBB"
 * @return 解析出的 UIColor 对象。如果格式无效，返回 nil。
 */
+ (UIColor *)_colorFromHexString:(NSString *)hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    CGFloat alpha = 1.0;
    unsigned int hexValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:colorString];

    BOOL scanSuccess = NO;
    if (colorString.length == 8) {  // AARRGGBB
        if ([scanner scanHexInt:&hexValue]) {
            alpha = ((hexValue & 0xFF000000) >> 24) / 255.0;
            scanSuccess = YES;
        }
    } else if (colorString.length == 6) {  // RRGGBB
        if ([scanner scanHexInt:&hexValue]) {
            scanSuccess = YES;
        }
    } else if (colorString.length == 3) {  // RGB (简写)
        NSString *r = [colorString substringWithRange:NSMakeRange(0, 1)];
        NSString *g = [colorString substringWithRange:NSMakeRange(1, 1)];
        NSString *b = [colorString substringWithRange:NSMakeRange(2, 1)];
        NSString *expandedColorString = [NSString stringWithFormat:@"%@%@%@%@%@%@", r, r, g, g, b, b];
        NSScanner *expandedScanner = [NSScanner scannerWithString:expandedColorString];
        if ([expandedScanner scanHexInt:&hexValue]) {
            scanSuccess = YES;
        }
    }
    if (!scanSuccess) {
        return nil;  // 返回 nil 表示解析失败
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
    return [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0 green:(CGFloat)arc4random_uniform(256) / 255.0 blue:(CGFloat)arc4random_uniform(256) / 255.0 alpha:1.0];
}

// 私有辅助方法：根据指定的起始索引获取旋转状态的彩虹颜色数组
+ (NSArray<UIColor *> *)_rotatedRainbowColorsForIndex:(uint_fast64_t)startIndex {
    NSUInteger count = _baseRainbowColors.count;
    if (count == 0)
        return @[];

    NSMutableArray<UIColor *> *rotatedColors = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [rotatedColors addObject:_baseRainbowColors[(startIndex + i) % count]];
    }
    return [rotatedColors copy];
}

/**
 * @brief 私有辅助方法：解析预定义或逗号分隔的渐变颜色字符串。
 * @param hexString 颜色方案字符串，例如 "rainbow" 或 "red,blue,#00FF00"
 * @return 颜色数组，如果不是静态渐变方案，返回 nil。
 */
+ (NSArray<UIColor *> *)_staticGradientColorsForHexString:(NSString *)hexString {
    NSString *trimmedHexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lowercaseHexString = [trimmedHexString lowercaseString];

    if ([lowercaseHexString isEqualToString:@"rainbow"] || [lowercaseHexString isEqualToString:@"#rainbow"]) {
        return _baseRainbowColors;
    }

    if ([trimmedHexString containsString:@","]) {
        // 处理逗号分隔的多色渐变
        NSArray *hexComponents = [trimmedHexString componentsSeparatedByString:@","];
        NSMutableArray *gradientColors = [NSMutableArray array];
        for (NSString *hex in hexComponents) {
            UIColor *color = [self _colorFromHexString:hex];
            if (color)
                [gradientColors addObject:color];
        }
        if (gradientColors.count >= 2) {  // 渐变至少要有两种颜色
            return [gradientColors copy];
        }
    }

    return nil;
}

+ (UIImage *)_imageWithGradientColors:(NSArray<UIColor *> *)colors size:(CGSize)size {
    if (!colors || colors.count < 2 || size.width <= 0 || size.height <= 0) {
        return nil;
    }

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];

    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext) {
      CGContextRef context = rendererContext.CGContext;

      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      NSMutableArray *cgColors = [NSMutableArray array];
      for (UIColor *color in colors) {
          [cgColors addObject:(__bridge id)color.CGColor];
      }

      CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)cgColors, NULL);

      CGPoint startPoint = CGPointMake(0, 0);
      CGPoint endPoint = CGPointMake(size.width, 0);

      CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

      CGGradientRelease(gradient);
      CGColorSpaceRelease(colorSpace);
    }];

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
        if ([label isEqualToString:@"right"])
            return YES;
        if ([label isEqualToString:@"left"])
            return NO;
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
        if ([label isEqualToString:@"left"])
            return YES;
        if ([label isEqualToString:@"right"])
            return NO;
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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnablePure"]) {
        return;
    }

    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTopBarTransparent"];
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
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
        return obj;
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id value in (NSArray *)obj) {
            id safeValue = DYYYJSONSafeObject(value);
            if (safeValue)
                [array addObject:safeValue];
        }
        return array;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (id key in (NSDictionary *)obj) {
            id safeValue = DYYYJSONSafeObject([(NSDictionary *)obj objectForKey:key]);
            if (safeValue)
                dict[key] = safeValue;
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
