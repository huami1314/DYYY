//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//  Created on: 2024/10/04
//
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <float.h>
#import <math.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <syslog.h>

#import "AwemeHeaders.h"
#import "CityManager.h"
#import "DYYYBottomAlertView.h"
#import "DYYYManager.h"

#import "AWMSafeDispatchTimer.h"
#import "DYYYConstants.h"
#import "DYYYFloatClearButton.h"
#import "DYYYFloatSpeedButton.h"
#import "DYYYSettingViewController.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"

static CGFloat gStartY = 0.0;
static CGFloat gStartVal = 0.0;
static DYEdgeMode gMode = DYEdgeModeNone;
static __weak UICollectionView *gFeedCV = nil;

static const CGFloat kInvalidAlpha = -1.0;
static const CGFloat kInvalidHeight = -1.0;
static CGFloat gGlobalTransparency = kInvalidAlpha;
static CGFloat gCurrentTabBarHeight = kInvalidHeight;
static CGFloat originalTabBarHeight = kInvalidHeight;
static NSString *const kDYYYGlobalTransparencyKey = @"DYYYGlobalTransparency";
static NSString *const kDYYYGlobalTransparencyDidChangeNotification = @"DYYYGlobalTransparencyDidChangeNotification";
static char kDYYYGlobalTransparencyBaseAlphaKey;
static NSInteger dyyyGlobalTransparencyMutationDepth = 0;

static void updateGlobalTransparencyCache() {
    NSString *transparentValue = DYYYGetString(kDYYYGlobalTransparencyKey);
    if (transparentValue.length > 0) {
        float alphaValue;
        NSScanner *scanner = [NSScanner scannerWithString:transparentValue];
        if ([scanner scanFloat:&alphaValue] && scanner.isAtEnd) {
            gGlobalTransparency = MIN(MAX(alphaValue, 0.0), 1.0);
            return;
        }
    }
    gGlobalTransparency = kInvalidAlpha;
}

static NSDictionary<NSString *, NSString *> *DYYYTopTabTitleMapping(void) {
    static NSString *cachedRawValue = nil;
    static NSDictionary<NSString *, NSString *> *cachedMapping = nil;

    NSString *currentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYModifyTopTabText"];
    BOOL rawValueChanged = (cachedRawValue != currentValue) && ![cachedRawValue isEqualToString:currentValue];

    if (!rawValueChanged) {
        return cachedMapping;
    }

    cachedRawValue = [currentValue copy];

    if (currentValue.length == 0) {
        cachedMapping = nil;
        return nil;
    }

    NSMutableDictionary<NSString *, NSString *> *mapping = [NSMutableDictionary dictionary];
    NSArray<NSString *> *titlePairs = [currentValue componentsSeparatedByString:@"#"];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    for (NSString *pair in titlePairs) {
        NSArray<NSString *> *components = [pair componentsSeparatedByString:@"="];
        if (components.count != 2) {
            continue;
        }

        NSString *originalTitle = [components[0] stringByTrimmingCharactersInSet:whitespace];
        NSString *newTitle = [components[1] stringByTrimmingCharactersInSet:whitespace];

        if (originalTitle.length == 0 || newTitle.length == 0) {
            continue;
        }

        mapping[originalTitle] = newTitle;
    }

    cachedMapping = mapping.count > 0 ? [mapping copy] : nil;
    return cachedMapping;
}

static NSString *DYYYCustomAssetsDirectory(void) {
    static NSString *customDirectory = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
      NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
      customDirectory = [documentsPath stringByAppendingPathComponent:@"DYYY"];
      [[NSFileManager defaultManager] createDirectoryAtPath:customDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    });

    return customDirectory;
}

static NSString *DYYYCustomIconFileNameForButtonName(NSString *nameString) {
    if (nameString.length == 0) {
        return nil;
    }

    static NSDictionary<NSString *, NSString *> *prefixMapping = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      prefixMapping = @{
          @"icon_home_like_after" : @"like_after.png",
          @"icon_home_like_before" : @"like_before.png",
          @"icon_home_comment" : @"comment.png",
          @"icon_home_unfavorite" : @"unfavorite.png",
          @"icon_home_favorite" : @"favorite.png",
          @"iconHomeShareRight" : @"share.png"
      };
    });

    for (NSString *prefix in prefixMapping) {
        if ([nameString hasPrefix:prefix]) {
            return prefixMapping[prefix];
        }
    }

    if ([nameString containsString:@"_comment"]) {
        return @"comment.png";
    }
    if ([nameString containsString:@"_like"]) {
        BOOL isLikedState = [nameString containsString:@"_after"] || [nameString containsString:@"_liked"];
        return isLikedState ? @"like_after.png" : @"like_before.png";
    }
    if ([nameString containsString:@"_collect"]) {
        return @"unfavorite.png";
    }
    if ([nameString containsString:@"_share"]) {
        return @"share.png";
    }

    return nil;
}

static UIImage *DYYYLoadCustomImage(NSString *fileName, CGSize targetSize) {
    if (fileName.length == 0) {
        return nil;
    }

    static NSCache<NSString *, UIImage *> *imageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      imageCache = [[NSCache alloc] init];
      imageCache.name = @"com.dyyy.customIcons.cache";
    });

    NSString *cacheKey = (targetSize.width > 0.0 && targetSize.height > 0.0) ? [NSString stringWithFormat:@"%@_%0.1f_%0.1f", fileName, targetSize.width, targetSize.height] : fileName;

    UIImage *cachedImage = [imageCache objectForKey:cacheKey];
    if (cachedImage) {
        return cachedImage;
    }

    NSString *fullPath = [DYYYCustomAssetsDirectory() stringByAppendingPathComponent:fileName];
    UIImage *sourceImage = [UIImage imageWithContentsOfFile:fullPath];
    if (!sourceImage) {
        return nil;
    }

    if (targetSize.width <= 0.0 || targetSize.height <= 0.0) {
        [imageCache setObject:sourceImage forKey:cacheKey];
        return sourceImage;
    }

    CGSize originalSize = sourceImage.size;
    if (originalSize.width <= 0.0 || originalSize.height <= 0.0) {
        return sourceImage;
    }

    CGFloat widthScale = targetSize.width / originalSize.width;
    CGFloat heightScale = targetSize.height / originalSize.height;
    CGFloat scale = fmin(widthScale, heightScale);

    if (fabs(1.0 - scale) <= FLT_EPSILON) {
        [imageCache setObject:sourceImage forKey:cacheKey];
        return sourceImage;
    }

    CGSize newSize = CGSizeMake(originalSize.width * scale, originalSize.height * scale);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [sourceImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIImage *resultImage = resizedImage ?: sourceImage;
    [imageCache setObject:resultImage forKey:cacheKey];
    return resultImage;
}

static BOOL DYYYShouldHandleSpeedFeatures(void) {
    if (isFloatSpeedButtonEnabled) {
        return YES;
    }

    float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];
    if (defaultSpeed <= 0.0f) {
        return NO;
    }

    return fabsf(defaultSpeed - 1.0f) > FLT_EPSILON;
}

@interface AWEFeedProgressSlider (DYYYProgressLabel)
- (NSString *)dyyy_formatTimeFromSeconds:(CGFloat)seconds;
- (CGFloat)dyyy_modelDurationInSeconds;
- (CGFloat)dyyy_scheduleVerticalOffset;
- (void)dyyy_removeScheduleLabels;
- (void)dyyy_updateScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration;
@end

@interface AWEPlayInteractionProgressController (DYYYProgressLabel)
- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration;
@end

@interface AWEDProgressCoreContainer (DYYYProgressLabel)
- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration;
@end

@interface UIView (DYYYProgressLabelLegacy)
- (void)dyyy_updateScheduleLabelsLegacyWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration model:(id)model;
@end

@implementation UIView (DYYYProgressLabelLegacy)

- (NSString *)dyyy_legacyFormatTimeFromSeconds:(CGFloat)seconds {
    CGFloat safeSeconds = seconds;
    if (safeSeconds < 0) {
        safeSeconds = 0;
    }

    NSInteger total = (NSInteger)floor(safeSeconds);
    NSInteger hours = total / 3600;
    NSInteger minutes = (total % 3600) / 60;
    NSInteger secs = total % 60;

    if (hours > 0) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)secs];
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)secs];
}

- (CGFloat)dyyy_legacyScheduleVerticalOffset {
    CGFloat verticalOffset = -12.5;
    NSString *offsetValueString = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimelineVerticalPosition"];
    if (offsetValueString.length > 0) {
        CGFloat configuredOffset = [offsetValueString floatValue];
        if (configuredOffset != 0) {
            verticalOffset = configuredOffset;
        }
    }
    return verticalOffset;
}

- (CGFloat)dyyy_legacyModelDurationInSeconds:(id)model {
    if (!model || ![model respondsToSelector:@selector(videoDuration)]) {
        return 0;
    }

    CGFloat videoDurationMs = [[model valueForKey:@"videoDuration"] doubleValue];
    if (videoDurationMs <= 0) {
        return 0;
    }
    return videoDurationMs / 1000.0;
}

- (void)dyyy_updateScheduleLabelsLegacyWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration model:(id)model {
    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        UIView *parentView = self.superview;
        if (parentView) {
            [[parentView viewWithTag:10001] removeFromSuperview];
            [[parentView viewWithTag:10002] removeFromSuperview];
        }
        return;
    }

    if (![NSThread isMainThread]) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
          [weakSelf dyyy_updateScheduleLabelsLegacyWithCurrentTime:currentTime totalDuration:totalDuration model:model];
        });
        return;
    }

    UIView *parentView = self.superview;
    if (!parentView) {
        return;
    }
    [parentView layoutIfNeeded];
    [self layoutIfNeeded];

    NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
    BOOL showRightRemainingTime = [scheduleStyle isEqualToString:@"进度条右侧剩余"];
    BOOL showRightCompleteTime = [scheduleStyle isEqualToString:@"进度条右侧完整"];
    BOOL showLeftRemainingTime = [scheduleStyle isEqualToString:@"进度条左侧剩余"];
    BOOL showLeftCompleteTime = [scheduleStyle isEqualToString:@"进度条左侧完整"];

    BOOL shouldShowLeftLabel = !showRightRemainingTime && !showRightCompleteTime;
    BOOL shouldShowRightLabel = !showLeftRemainingTime && !showLeftCompleteTime;

    CGFloat modelDuration = [self dyyy_legacyModelDurationInSeconds:model];
    CGFloat effectiveTotalDuration = totalDuration > 0 ? totalDuration : modelDuration;
    if (effectiveTotalDuration < 0) {
        effectiveTotalDuration = 0;
    }

    CGFloat effectiveCurrentTime = currentTime;
    if (effectiveCurrentTime < 0) {
        effectiveCurrentTime = 0;
    }
    if (effectiveTotalDuration > 0 && effectiveCurrentTime > effectiveTotalDuration) {
        effectiveCurrentTime = effectiveTotalDuration;
    }

    CGRect sliderFrameInParent = [self convertRect:self.bounds toView:parentView];
    if (CGRectGetWidth(sliderFrameInParent) <= 1.0 || CGRectGetHeight(sliderFrameInParent) <= 1.0) {
        return;
    }
    CGFloat labelYPosition = CGRectGetMinY(sliderFrameInParent) + [self dyyy_legacyScheduleVerticalOffset];
    CGFloat labelHeight = 15.0;
    UIFont *labelFont = [UIFont systemFontOfSize:8];
    NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressLabelColor"];

    UILabel *leftLabel = (UILabel *)[parentView viewWithTag:10001];
    if (leftLabel && ![leftLabel isKindOfClass:[UILabel class]]) {
        [leftLabel removeFromSuperview];
        leftLabel = nil;
    }

    if (shouldShowLeftLabel) {
        if (!leftLabel) {
            leftLabel = [[UILabel alloc] init];
            leftLabel.backgroundColor = [UIColor clearColor];
            leftLabel.tag = 10001;
            [parentView addSubview:leftLabel];
        }
        leftLabel.font = labelFont;

        NSString *newLeftText = nil;
        if (showLeftRemainingTime) {
            newLeftText = [self dyyy_legacyFormatTimeFromSeconds:MAX(effectiveTotalDuration - effectiveCurrentTime, 0)];
        } else if (showLeftCompleteTime) {
            newLeftText = [NSString stringWithFormat:@"%@/%@", [self dyyy_legacyFormatTimeFromSeconds:effectiveCurrentTime], [self dyyy_legacyFormatTimeFromSeconds:effectiveTotalDuration]];
        } else {
            newLeftText = [self dyyy_legacyFormatTimeFromSeconds:effectiveCurrentTime];
        }

        if (![leftLabel.text isEqualToString:newLeftText]) {
            leftLabel.text = newLeftText;
        }
        [leftLabel sizeToFit];
        leftLabel.frame = CGRectMake(CGRectGetMinX(sliderFrameInParent), labelYPosition, CGRectGetWidth(leftLabel.bounds), labelHeight);
        [DYYYUtils applyColorSettingsToLabel:leftLabel colorHexString:labelColorHex];
    } else {
        [leftLabel removeFromSuperview];
    }

    UILabel *rightLabel = (UILabel *)[parentView viewWithTag:10002];
    if (rightLabel && ![rightLabel isKindOfClass:[UILabel class]]) {
        [rightLabel removeFromSuperview];
        rightLabel = nil;
    }

    if (shouldShowRightLabel) {
        if (!rightLabel) {
            rightLabel = [[UILabel alloc] init];
            rightLabel.backgroundColor = [UIColor clearColor];
            rightLabel.tag = 10002;
            [parentView addSubview:rightLabel];
        }
        rightLabel.font = labelFont;

        NSString *newRightText = nil;
        if (showRightRemainingTime) {
            newRightText = [self dyyy_legacyFormatTimeFromSeconds:MAX(effectiveTotalDuration - effectiveCurrentTime, 0)];
        } else if (showRightCompleteTime) {
            newRightText = [NSString stringWithFormat:@"%@/%@", [self dyyy_legacyFormatTimeFromSeconds:effectiveCurrentTime], [self dyyy_legacyFormatTimeFromSeconds:effectiveTotalDuration]];
        } else {
            newRightText = [self dyyy_legacyFormatTimeFromSeconds:effectiveTotalDuration];
        }

        if (![rightLabel.text isEqualToString:newRightText]) {
            rightLabel.text = newRightText;
        }
        [rightLabel sizeToFit];
        CGFloat rightLabelX = MAX(CGRectGetMaxX(sliderFrameInParent) - CGRectGetWidth(rightLabel.bounds), CGRectGetMinX(sliderFrameInParent));
        rightLabel.frame = CGRectMake(rightLabelX, labelYPosition, CGRectGetWidth(rightLabel.bounds), labelHeight);
        [DYYYUtils applyColorSettingsToLabel:rightLabel colorHexString:labelColorHex];
    } else {
        [rightLabel removeFromSuperview];
    }
}

@end

// 关闭不可见水印
%hook AWEHPChannelInvisibleWaterMarkModel

- (BOOL)isEnter {
    return NO;
}

- (BOOL)isAppear {
    return NO;
}

%end

// 长按复制个人简介
%hook AWEProfileMentionLabel

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYBioCopyText")) {
        return;
    }

    BOOL hasLongPressGesture = NO;
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
            hasLongPressGesture = YES;
            break;
        }
    }

    if (!hasLongPressGesture) {
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPressGesture.minimumPressDuration = 0.5;
        [self addGestureRecognizer:longPressGesture];
        self.userInteractionEnabled = YES;
    }
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSString *bioText = self.text;
        if (bioText && bioText.length > 0) {
            [[UIPasteboard generalPasteboard] setString:bioText];
            [DYYYToast showSuccessToastWithMessage:@"个人简介已复制"];
        }
    }
}

%end

// 默认视频流最高画质
%hook AWEVideoModel

- (AWEURLModel *)playURL {
    if (!DYYYGetBool(@"DYYYEnableVideoHighestQuality")) {
        return %orig;
    }

    // 获取比特率模型数组
    NSArray *bitrateModels = [self bitrateModels];
    if (!bitrateModels || bitrateModels.count == 0) {
        return %orig;
    }

    // 查找比特率最高的模型
    id highestBitrateModel = nil;
    NSInteger highestBitrate = 0;

    for (id model in bitrateModels) {
        NSInteger bitrate = 0;
        BOOL validModel = NO;

        if ([model isKindOfClass:NSClassFromString(@"AWEVideoBSModel")]) {
            id bitrateValue = [model bitrate];
            if (bitrateValue) {
                bitrate = [bitrateValue integerValue];
                validModel = YES;
            }
        }

        if (validModel && bitrate > highestBitrate) {
            highestBitrate = bitrate;
            highestBitrateModel = model;
        }
    }

    // 如果找到了最高比特率模型，获取其播放地址
    if (highestBitrateModel) {
        id playAddr = [highestBitrateModel valueForKey:@"playAddr"];
        if (playAddr && [playAddr isKindOfClass:%c(AWEURLModel)]) {
            return playAddr;
        }
    }

    return %orig;
}

- (NSArray *)bitrateModels {

    NSArray *originalModels = %orig;

    if (!DYYYGetBool(@"DYYYEnableVideoHighestQuality")) {
        return originalModels;
    }

    if (originalModels.count == 0) {
        return originalModels;
    }

    // 查找比特率最高的模型
    id highestBitrateModel = nil;
    NSInteger highestBitrate = 0;

    for (id model in originalModels) {

        NSInteger bitrate = 0;
        BOOL validModel = NO;

        if ([model isKindOfClass:NSClassFromString(@"AWEVideoBSModel")]) {
            id bitrateValue = [model bitrate];
            if (bitrateValue) {
                bitrate = [bitrateValue integerValue];
                validModel = YES;
            }
        }

        if (validModel) {
            if (bitrate > highestBitrate) {
                highestBitrate = bitrate;
                highestBitrateModel = model;
            }
        }
    }

    if (highestBitrateModel) {
        return @[ highestBitrateModel ];
    }

    return originalModels;
}

%end

// 直播间真实人数
%hook IESLiveUserSeqlistFragment

- (void)refreshVerticalUserCount:(id)arg1 horizontalUserCount:(id)arg2 trueValue:(NSInteger)trueValue {
    if ( trueValue > 0 && DYYYGetBool(@"DYYYEnableLiveRealCount") ) {
        NSString *realStr = [NSString stringWithFormat:@"%ld", (long)trueValue];
        %orig(realStr, realStr, trueValue);
    } else {
        %orig;
    }
}

%end

// 评论具体时间
%hook AWEDateTimeFormatter

+ (id)formattedDateForTimestamp:(double)timestamp {
    if (!DYYYGetBool(@"DYYYCommentExactTime")) return %orig(timestamp);
    return [NSString stringWithFormat:@"%.0f ", timestamp];
}

%end

%hook AWERLVirtualLabel

- (void)setText:(NSString *)text {
    if (!DYYYGetBool(@"DYYYCommentExactTime") || !text || text.length == 0) {
        %orig(text);
        return;
    }

    if ([text isEqualToString:@"回复"]) {
        %orig(@"");
        return;
    }

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d{10,13})([\\s\\S]*)" options:0 error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];

    if (match) {
        NSString *rawTs = [text substringWithRange:[match rangeAtIndex:1]];
        NSString *suffix = [text substringWithRange:[match rangeAtIndex:2]];
        
        long long ts = [rawTs longLongValue];
        
        if (ts > 100000000000) {
            ts = ts / 1000;
        }
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *formattedDate = [formatter stringFromDate:date];
        
        NSString *newText = [NSString stringWithFormat:@"%@%@", formattedDate, suffix];
        %orig(newText);
    } else {
        %orig(text);
    }
}

%end

%group DYYYCommentExactTimeGroup
%hook AWECommentSwiftBizUI_CommentInteractionBaseLabel

- (void)setText:(NSString *)text {
    %orig(text); // 先让系统把文本赋上去
    
    if (!DYYYGetBool(@"DYYYCommentExactTime")) {
        return;
    }

    UILabel *label = (UILabel *)self;
    if (!text || text.length == 0) return;

    // --- 1. 拦截翻译文本，将其绝对定位在屏幕右侧 100 像素 ---
    if ([text isEqualToString:@"翻译"] || [text isEqualToString:@"隐藏翻译"]) {
        CGRect currentFrame = label.frame;
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        // 重新计算 X 坐标：屏幕宽度 - 100 - 标签自身宽度
        currentFrame.origin.x = screenWidth - 100.0 - currentFrame.size.width;
        label.frame = currentFrame;
        return;
    }

    // --- 2. 拦截时间文本，如果不够宽则扩充宽度 ---
    UIFont *font = label.font;
    if (font) {
        CGFloat expectedWidth = ceilf([text sizeWithAttributes:@{NSFontAttributeName: font}].width);
        CGRect currentFrame = label.frame;
        
        // 如果当前宽度不够，并且不是尚未初始化的状态（>0），则强行修改并重新赋值
        if (currentFrame.size.width < expectedWidth && currentFrame.size.width > 0) {
            currentFrame.size.width = expectedWidth;
            label.frame = currentFrame; 
            label.clipsToBounds = NO;
        }
    }
}

- (void)setFrame:(CGRect)frame {
    if (!DYYYGetBool(@"DYYYCommentExactTime") || ![self respondsToSelector:@selector(text)]) {
        %orig(frame);
        return;
    }

    UILabel *label = (UILabel *)self;
    NSString *text = label.text;

    if (text && text.length > 0) {
        // --- 1. 拦截翻译文本，将其绝对定位在屏幕右侧 100 像素 ---
        if ([text isEqualToString:@"翻译"] || [text isEqualToString:@"隐藏翻译"]) {
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            frame.origin.x = screenWidth - 100.0 - frame.size.width;
        } 
        // --- 2. 拦截时间文本，如果不够宽则扩充宽度 ---
        else if ([self respondsToSelector:@selector(font)]) {
            UIFont *font = label.font;
            if (font) {
                CGFloat expectedWidth = ceilf([text sizeWithAttributes:@{NSFontAttributeName: font}].width);
                if (frame.size.width < expectedWidth && frame.size.width > 0) {
                    frame.size.width = expectedWidth;
                    label.clipsToBounds = NO;
                }
            }
        }
    }

    %orig(frame);
}

%end
%end

// 前面的AWEDateTimeFormatter会导致图文视频展开时间文本变成时间戳，这里处理下
%hook YYLabel

// 1. Hook 富文本赋值方法 (核心)
- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (!DYYYGetBool(@"DYYYCommentExactTime") || !attributedText || attributedText.length == 0) {
        %orig(attributedText);
        return;
    }

    NSString *plainText = [attributedText string];

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d{10,13})" options:0 error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:plainText options:0 range:NSMakeRange(0, plainText.length)];

    if (match) {
        NSString *rawTs = [plainText substringWithRange:[match rangeAtIndex:1]];
        long long ts = [rawTs longLongValue];
        
        if (ts > 100000000000) {
            ts = ts / 1000;
        }
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *formattedDate = [formatter stringFromDate:date];
        
        NSMutableAttributedString *newAttrStr = [attributedText mutableCopy];
        [newAttrStr replaceCharactersInRange:[match rangeAtIndex:1] withString:formattedDate];
        
        %orig(newAttrStr);
    } else {
        %orig(attributedText);
    }
}

%end

// 禁用自动进入直播间
%hook AWELiveGuideElement

- (BOOL)enableAutoEnterRoom {
    if (DYYYGetBool(@"DYYYDisableAutoEnterLive")) {
        return NO;
    }
    return %orig;
}

- (BOOL)enableNewAutoEnter {
    if (DYYYGetBool(@"DYYYDisableAutoEnterLive")) {
        return NO;
    }
    return %orig;
}

%end

%hook AWEFeedChannelManager

- (void)reloadChannelWithChannelModels:(id)arg1 currentChannelIDList:(id)arg2 reloadType:(id)arg3 selectedChannelID:(id)arg4 {
    NSArray *channelModels = arg1;
    NSMutableArray *newChannelModels = [NSMutableArray array];
    NSArray *currentChannelIDList = arg2;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *newCurrentChannelIDList = [NSMutableArray arrayWithArray:currentChannelIDList];

    if (!arg1 || !arg2) {
        %orig(arg1, arg2, arg3, arg4);
        return;
    }

    if (![channelModels isKindOfClass:[NSArray class]] || ![currentChannelIDList isKindOfClass:[NSArray class]]) {
        %orig(arg1, arg2, arg3, arg4);
        return;
    }

    if (channelModels.count == 0) {
        %orig(arg1, arg2, arg3, arg4);
        return;
    }

    for (AWEHPTopTabItemModel *tabItemModel in channelModels) {
        NSString *channelID = tabItemModel.channelID;
        BOOL isHideChannel = NO;

        if ([channelID isEqualToString:@"homepage_hot_container"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideHotContainer"];
        } else if ([channelID isEqualToString:@"homepage_follow"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideFollow"];
        } else if ([channelID isEqualToString:@"homepage_mall"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideMall"];
        } else if ([channelID isEqualToString:@"homepage_nearby"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideNearby"];
        } else if ([channelID isEqualToString:@"homepage_groupon"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideGroupon"];
        } else if ([channelID isEqualToString:@"homepage_tablive"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideTabLive"];
        } else if ([channelID isEqualToString:@"homepage_pad_hot"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHidePadHot"];
        } else if ([channelID isEqualToString:@"homepage_hangout"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideHangout"];
        } else if ([channelID isEqualToString:@"homepage_familiar"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideFriend"];
        } else if ([channelID isEqualToString:@"homepage_playlet_stream"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHidePlaylet"];
        } else if ([channelID isEqualToString:@"homepage_pad_cinema"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideCinema"];
        } else if ([channelID isEqualToString:@"homepage_pad_kids_v2"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideKidsV2"];
        } else if ([channelID isEqualToString:@"homepage_pad_game"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideGame"];
        } else if ([channelID isEqualToString:@"homepage_mediumvideo"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideMediumVideo"];
        }

        if (!isHideChannel) {
            [newChannelModels addObject:tabItemModel];
        } else {
            [newCurrentChannelIDList removeObject:channelID];
        }
    }

    %orig(newChannelModels, newCurrentChannelIDList, arg3, arg4);
}

%end

%hook AWELandscapeFeedViewController
- (void)viewDidLoad {
    %orig;

    // 尝试优先走属性
    gFeedCV = self.collectionView;

    // 保险起见再fallback,遍历 subviews
    if (!gFeedCV) {
        gFeedCV = [DYYYUtils findSubviewOfClass:[UICollectionView class] inContainer:self.view];
    }
}
%end

%hook UICollectionView

// 拦截手指拖动
- (void)handlePan:(UIPanGestureRecognizer *)pan {

    /* 仅处理横屏Feed列表。其余collectionView直接走系统逻辑 */
    if (self != gFeedCV || !DYYYGetBool(@"DYYYVideoGesture")) {
        %orig;
        return;
    }

    /* 取触点坐标、手势状态 */
    CGPoint loc = [pan locationInView:self];
    CGFloat w = self.bounds.size.width;
    CGFloat xPct = loc.x / w; // 0.0 ~ 1.0
    UIGestureRecognizerState st = pan.state;

    /* BEGAN：判定左右 20 % 区域 → 进入亮度 / 音量模式 */
    if (st == UIGestureRecognizerStateBegan) {

        gStartY = loc.y;

        if (xPct <= 0.20) { // 左边缘 → 亮度
            gMode = DYEdgeModeBrightness;
            gStartVal = [UIScreen mainScreen].brightness;

        } else if (xPct >= 0.80) { // 右边缘 → 音量
            gMode = DYEdgeModeVolume;
            gStartVal = [[objc_getClass("AVSystemController") sharedAVSystemController] volumeForCategory:@"Audio/Video"];

        } else {
            gMode = DYEdgeModeNone; // 中间区域走原逻辑
        }
    }

    /* 调节阶段：左右边缘时吞掉滚动、修改亮度/音量 */
    if (gMode != DYEdgeModeNone) {

        if (st == UIGestureRecognizerStateChanged) {

            CGFloat delta = (gStartY - loc.y) / self.bounds.size.height; // ↑ 为正
            const CGFloat kScale = 2.0;                                  // 灵敏度
            float newVal = gStartVal + delta * kScale;
            newVal = fminf(fmaxf(newVal, 0.0), 1.0); // Clamp 0~1

            if (gMode == DYEdgeModeBrightness) {
                [UIScreen mainScreen].brightness = newVal;
                // 弹系统亮度 HUD
                [[%c(SBHUDController) sharedInstance] presentHUDWithIcon:@"Brightness" level:newVal];

            } else { // DYEdgeModeVolume
                // iOS 18 音量控制 + 系统音量 HUD
                [[objc_getClass("AVSystemController") sharedAVSystemController] setVolumeTo:newVal forCategory:@"Audio/Video"];
            }

            // 吞掉滚动：归零 translation，防止内容位移
            [pan setTranslation:CGPointZero inView:self];
        }

        /* 结束／取消：状态复位 */
        if (st == UIGestureRecognizerStateEnded || st == UIGestureRecognizerStateCancelled || st == UIGestureRecognizerStateFailed) {
            gMode = DYEdgeModeNone;
        }

        return; // 左右边缘：彻底阻断 %orig，避免翻页
    }

    /* 中间区域：直接执行原先翻页逻辑 */
    %orig;
}

%end

%hook AWELeftSideBarAddChildTransitionObject

- (void)handleShowSliderPanGesture:(id)gr {
    if (DYYYGetBool(@"DYYYDisableSidebarGesture")) {
        return;
    }
    %orig(gr);
}

%end

%hook AWEPlayInteractionUserAvatarElement
- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
    if (DYYYGetBool(@"DYYYFollowTips")) {
        // 获取用户信息
        AWEUserModel *author = nil;
        NSString *nickname = @"";
        NSString *signature = @"";
        NSString *avatarURL = @"";

        if ([self respondsToSelector:@selector(model)]) {
            id model = [self model];
            if ([model isKindOfClass:NSClassFromString(@"AWEAwemeModel")]) {
                author = [model valueForKey:@"author"];
            }
        }

        if (author) {
            // 获取昵称
            if ([author respondsToSelector:@selector(nickname)]) {
                nickname = [author valueForKey:@"nickname"] ?: @"";
            }

            // 获取签名
            if ([author respondsToSelector:@selector(signature)]) {
                signature = [author valueForKey:@"signature"] ?: @"";
            }

            // 获取头像URL
            if ([author respondsToSelector:@selector(avatarThumb)]) {
                AWEURLModel *avatarThumb = [author valueForKey:@"avatarThumb"];
                if (avatarThumb && avatarThumb.originURLList.count > 0) {
                    avatarURL = avatarThumb.originURLList.firstObject;
                }
            }
        }

        NSMutableString *messageContent = [NSMutableString string];
        if (signature.length > 0) {
            [messageContent appendFormat:@"%@", signature];
        }

        NSString *title = nickname.length > 0 ? nickname : @"关注确认";

        [DYYYBottomAlertView showAlertWithTitle:title
                                        message:messageContent
                                      avatarURL:avatarURL
                               cancelButtonText:@"取消"
                              confirmButtonText:@"关注"
                                   cancelAction:nil
                                    closeAction:nil
                                  confirmAction:^{
                                    %orig(gesture);
                                  }];
    } else {
        %orig;
    }
}

%end

%hook AWEPlayInteractionUserAvatarFollowController
- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
    if (DYYYGetBool(@"DYYYFollowTips")) {
        // 获取用户信息
        AWEUserModel *author = nil;
        NSString *nickname = @"";
        NSString *signature = @"";
        NSString *avatarURL = @"";

        if ([self respondsToSelector:@selector(model)]) {
            id model = [self model];
            if ([model isKindOfClass:NSClassFromString(@"AWEAwemeModel")]) {
                author = [model valueForKey:@"author"];
            }
        }

        if (author) {
            // 获取昵称
            if ([author respondsToSelector:@selector(nickname)]) {
                nickname = [author valueForKey:@"nickname"] ?: @"";
            }

            // 获取签名
            if ([author respondsToSelector:@selector(signature)]) {
                signature = [author valueForKey:@"signature"] ?: @"";
            }

            // 获取头像URL
            if ([author respondsToSelector:@selector(avatarThumb)]) {
                AWEURLModel *avatarThumb = [author valueForKey:@"avatarThumb"];
                if (avatarThumb && avatarThumb.originURLList.count > 0) {
                    avatarURL = avatarThumb.originURLList.firstObject;
                }
            }
        }

        NSMutableString *messageContent = [NSMutableString string];
        if (signature.length > 0) {
            [messageContent appendFormat:@"%@", signature];
        }

        NSString *title = nickname.length > 0 ? nickname : @"关注确认";

        [DYYYBottomAlertView showAlertWithTitle:title
                                        message:messageContent
                                      avatarURL:avatarURL
                               cancelButtonText:@"取消"
                              confirmButtonText:@"关注"
                                   cancelAction:nil
                                    closeAction:nil
                                  confirmAction:^{
                                    %orig(gesture);
                                  }];
    } else {
        %orig;
    }
}

%end

%hook AWEFeedTopBarContainer
- (void)didMoveToSuperview {
    %orig;
    applyTopBarTransparency(self);
}
- (void)setAlpha:(CGFloat)alpha {
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTopBarTransparent"];
    if (transparentValue && transparentValue.length > 0) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {
            CGFloat finalAlpha = (alphaValue < 0.011) ? 0.011 : alphaValue;
            %orig(finalAlpha);
        } else {
            %orig(1.0);
        }
    } else {
        %orig(1.0);
    }
}
%end

// 设置修改顶栏标题
%hook AWEHPTopTabItemTextContentView

- (void)layoutSubviews {
    %orig;
    NSDictionary<NSString *, NSString *> *titleMapping = DYYYTopTabTitleMapping();
    if (titleMapping.count == 0) {
        return;
    }

    NSString *accessibilityLabel = nil;
    if ([self.superview respondsToSelector:@selector(accessibilityLabel)]) {
        accessibilityLabel = self.superview.accessibilityLabel;
    }
    if (accessibilityLabel.length == 0) {
        return;
    }

    NSString *newTitle = titleMapping[accessibilityLabel];
    if (newTitle.length == 0) {
        return;
    }

    if ([self respondsToSelector:@selector(setContentText:)]) {
        [self setContentText:newTitle];
    } else {
        [self setValue:newTitle forKey:@"contentText"];
    }
}

%end

%hook AWEDanmakuContentLabel
- (void)setTextColor:(UIColor *)textColor {
    if (DYYYGetBool(@"DYYYEnableDanmuColor")) {
        NSString *danmuColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDanmuColor"];
        if (DYYYGetBool(@"DYYYDanmuRainbowRotating")) {
            danmuColor = @"rainbow_rotating";
        }
        [DYYYUtils applyColorSettingsToLabel:self colorHexString:danmuColor];
    } else {
        %orig(textColor);
    }
}

- (void)setStrokeWidth:(double)strokeWidth {
    if (DYYYGetBool(@"DYYYEnableDanmuColor")) {
        %orig(FLT_MIN);
    } else {
        %orig(strokeWidth);
    }
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    if (DYYYGetBool(@"DYYYEnableDanmuColor")) {
        %orig(nil);
    } else {
        %orig(strokeColor);
    }
}

%end

%hook XIGDanmakuPlayerView

- (id)initWithFrame:(CGRect)frame {
    id orig = %orig;

    ((UIView *)orig).tag = DYYY_IGNORE_GLOBAL_ALPHA_TAG;

    return orig;
}

- (void)setAlpha:(CGFloat)alpha {
    if (DYYYGetBool(@"DYYYCommentShowDanmaku") && alpha == 0.0) {
        return;
    } else {
        %orig(alpha);
    }
}

%end

%hook DDanmakuPlayerView

- (void)setAlpha:(CGFloat)alpha {
    if (DYYYGetBool(@"DYYYCommentShowDanmaku") && alpha == 0.0) {
        return;
    } else {
        %orig(alpha);
    }
}

%end

%hook AWEMarkView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideLocation")) {
        self.hidden = YES;
        return;
    }
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
                        [closeButton.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:40], [closeButton.widthAnchor constraintEqualToConstant:80],
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
                    [handleBar.centerXAnchor constraintEqualToAnchor:settingVC.view.centerXAnchor], [handleBar.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:8],
                    [handleBar.widthAnchor constraintEqualToConstant:40], [handleBar.heightAnchor constraintEqualToConstant:5]
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

- (void)makeKeyAndVisible {
    %orig;

    if (!isFloatSpeedButtonEnabled)
        return;

    if (speedButton && ![speedButton isDescendantOfView:self]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self addSubview:speedButton];
          [speedButton loadSavedPosition];
          [speedButton resetFadeTimer];
        });
    }
}
%end

%end

%hook AWEBaseListViewController
- (void)viewDidLayoutSubviews {
    %orig;
    [self applyBlurEffectIfNeeded];
}

%new
- (void)applyBlurEffectIfNeeded {
    if (DYYYGetBool(@"DYYYEnableCommentBlur") && [self isKindOfClass:NSClassFromString(@"AWECommentPanelContainerSwiftImpl.CommentContainerInnerViewController")]) {
        // 动态获取用户设置的透明度
        float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
        if (userTransparency <= 0 || userTransparency > 1) {
            userTransparency = 0.9;
        }

        // 应用毛玻璃效果
        [DYYYUtils applyBlurEffectToView:self.view transparency:userTransparency blurViewTag:999];
    }
}
%end

%hook AWEFeedVideoButton
- (id)touchUpInsideBlock {
    id r = %orig;

    // 只有收藏按钮才显示确认弹窗
    if (DYYYGetBool(@"DYYYCollectTips") && [self.accessibilityLabel isEqualToString:@"收藏"]) {

        dispatch_async(dispatch_get_main_queue(), ^{
          [DYYYBottomAlertView showAlertWithTitle:@"收藏确认"
                                          message:@"是否确认/取消收藏？"
                                        avatarURL:nil
                                 cancelButtonText:nil
                                confirmButtonText:nil
                                     cancelAction:nil
                                      closeAction:nil
                                    confirmAction:^{
                                      if (r && [r isKindOfClass:NSClassFromString(@"NSBlock")]) {
                                          ((void (^)(void))r)();
                                      }
                                    }];
        });

        return nil;
    }

    return r;
}
%end

%hook AWEPlayInteractionProgressContainerView
- (void)layoutSubviews {
    %orig;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFullScreen"]) {
        return;
    }

    static char kDYProgressBgKey;
    NSArray *bgViews = objc_getAssociatedObject(self, &kDYProgressBgKey);
    if (!bgViews) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview class] == [UIView class]) {
                [tmp addObject:subview];
            }
        }
        bgViews = [tmp copy];
        objc_setAssociatedObject(self, &kDYProgressBgKey, bgViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *v in bgViews) {
        v.backgroundColor = [UIColor clearColor];
    }
}

%end

%hook AWEFeedProgressSlider

- (void)setAlpha:(CGFloat)alpha {
    if (DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        if (DYYYGetBool(@"DYYYHideVideoProgress")) {
            %orig(0);
        } else {
            %orig(1.0);
        }
    } else {
        %orig;
    }
}

%new
- (NSString *)dyyy_formatTimeFromSeconds:(CGFloat)seconds {
    CGFloat safeSeconds = seconds;
    if (safeSeconds < 0) {
        safeSeconds = 0;
    }

    NSInteger total = (NSInteger)floor(safeSeconds);
    NSInteger hours = total / 3600;
    NSInteger minutes = (total % 3600) / 60;
    NSInteger secs = total % 60;

    if (hours > 0) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)secs];
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)secs];
}

%new
- (CGFloat)dyyy_modelDurationInSeconds {
    id delegate = self.progressSliderDelegate;
    if (!delegate || ![delegate respondsToSelector:@selector(model)]) {
        return 0;
    }

    id model = [delegate valueForKey:@"model"];
    if (!model || ![model respondsToSelector:@selector(videoDuration)]) {
        return 0;
    }

    CGFloat videoDurationMs = [[model valueForKey:@"videoDuration"] doubleValue];
    if (videoDurationMs <= 0) {
        return 0;
    }
    return videoDurationMs / 1000.0;
}

%new
- (CGFloat)dyyy_scheduleVerticalOffset {
    CGFloat verticalOffset = -12.5;
    NSString *offsetValueString = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimelineVerticalPosition"];
    if (offsetValueString.length > 0) {
        CGFloat configuredOffset = [offsetValueString floatValue];
        if (configuredOffset != 0) {
            verticalOffset = configuredOffset;
        }
    }
    return verticalOffset;
}

%new
- (void)dyyy_removeScheduleLabels {
    UIView *parentView = self.superview;
    if (!parentView) {
        return;
    }
    [parentView layoutIfNeeded];
    [self layoutIfNeeded];
    [[parentView viewWithTag:10001] removeFromSuperview];
    [[parentView viewWithTag:10002] removeFromSuperview];
}

%new
- (void)dyyy_updateScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration {
    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        [self dyyy_removeScheduleLabels];
        return;
    }

    if (![NSThread isMainThread]) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
          [weakSelf dyyy_updateScheduleLabelsWithCurrentTime:currentTime totalDuration:totalDuration];
        });
        return;
    }

    UIView *parentView = self.superview;
    if (!parentView) {
        return;
    }
    [parentView layoutIfNeeded];
    [self layoutIfNeeded];

    NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
    BOOL showRightRemainingTime = [scheduleStyle isEqualToString:@"进度条右侧剩余"];
    BOOL showRightCompleteTime = [scheduleStyle isEqualToString:@"进度条右侧完整"];
    BOOL showLeftRemainingTime = [scheduleStyle isEqualToString:@"进度条左侧剩余"];
    BOOL showLeftCompleteTime = [scheduleStyle isEqualToString:@"进度条左侧完整"];

    BOOL shouldShowLeftLabel = !showRightRemainingTime && !showRightCompleteTime;
    BOOL shouldShowRightLabel = !showLeftRemainingTime && !showLeftCompleteTime;

    CGFloat modelDuration = [self dyyy_modelDurationInSeconds];
    CGFloat effectiveTotalDuration = totalDuration > 0 ? totalDuration : modelDuration;
    if (effectiveTotalDuration < 0) {
        effectiveTotalDuration = 0;
    }

    CGFloat effectiveCurrentTime = currentTime;
    if (effectiveCurrentTime < 0) {
        effectiveCurrentTime = 0;
    }
    if (effectiveTotalDuration > 0 && effectiveCurrentTime > effectiveTotalDuration) {
        effectiveCurrentTime = effectiveTotalDuration;
    }

    CGRect sliderFrameInParent = [self convertRect:self.bounds toView:parentView];
    if (CGRectGetWidth(sliderFrameInParent) <= 1.0 || CGRectGetHeight(sliderFrameInParent) <= 1.0) {
        return;
    }
    CGFloat labelYPosition = CGRectGetMinY(sliderFrameInParent) + [self dyyy_scheduleVerticalOffset];
    CGFloat labelHeight = 15.0;
    UIFont *labelFont = [UIFont systemFontOfSize:8];
    NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressLabelColor"];

    UILabel *leftLabel = (UILabel *)[parentView viewWithTag:10001];
    if (leftLabel && ![leftLabel isKindOfClass:[UILabel class]]) {
        [leftLabel removeFromSuperview];
        leftLabel = nil;
    }

    if (shouldShowLeftLabel) {
        if (!leftLabel) {
            leftLabel = [[UILabel alloc] init];
            leftLabel.backgroundColor = [UIColor clearColor];
            leftLabel.tag = 10001;
            [parentView addSubview:leftLabel];
        }

        leftLabel.font = labelFont;
        NSString *newLeftText = nil;
        if (showLeftRemainingTime) {
            newLeftText = [self dyyy_formatTimeFromSeconds:MAX(effectiveTotalDuration - effectiveCurrentTime, 0)];
        } else if (showLeftCompleteTime) {
            newLeftText = [NSString stringWithFormat:@"%@/%@", [self dyyy_formatTimeFromSeconds:effectiveCurrentTime], [self dyyy_formatTimeFromSeconds:effectiveTotalDuration]];
        } else {
            newLeftText = [self dyyy_formatTimeFromSeconds:effectiveCurrentTime];
        }

        if (![leftLabel.text isEqualToString:newLeftText]) {
            leftLabel.text = newLeftText;
        }
        [leftLabel sizeToFit];
        leftLabel.frame = CGRectMake(CGRectGetMinX(sliderFrameInParent), labelYPosition, CGRectGetWidth(leftLabel.bounds), labelHeight);
        [DYYYUtils applyColorSettingsToLabel:leftLabel colorHexString:labelColorHex];
    } else {
        [leftLabel removeFromSuperview];
    }

    UILabel *rightLabel = (UILabel *)[parentView viewWithTag:10002];
    if (rightLabel && ![rightLabel isKindOfClass:[UILabel class]]) {
        [rightLabel removeFromSuperview];
        rightLabel = nil;
    }

    if (shouldShowRightLabel) {
        if (!rightLabel) {
            rightLabel = [[UILabel alloc] init];
            rightLabel.backgroundColor = [UIColor clearColor];
            rightLabel.tag = 10002;
            [parentView addSubview:rightLabel];
        }

        rightLabel.font = labelFont;
        NSString *newRightText = nil;
        if (showRightRemainingTime) {
            newRightText = [self dyyy_formatTimeFromSeconds:MAX(effectiveTotalDuration - effectiveCurrentTime, 0)];
        } else if (showRightCompleteTime) {
            newRightText = [NSString stringWithFormat:@"%@/%@", [self dyyy_formatTimeFromSeconds:effectiveCurrentTime], [self dyyy_formatTimeFromSeconds:effectiveTotalDuration]];
        } else {
            newRightText = [self dyyy_formatTimeFromSeconds:effectiveTotalDuration];
        }

        if (![rightLabel.text isEqualToString:newRightText]) {
            rightLabel.text = newRightText;
        }
        [rightLabel sizeToFit];
        CGFloat rightLabelX = MAX(CGRectGetMaxX(sliderFrameInParent) - CGRectGetWidth(rightLabel.bounds), CGRectGetMinX(sliderFrameInParent));
        rightLabel.frame = CGRectMake(rightLabelX, labelYPosition, CGRectGetWidth(rightLabel.bounds), labelHeight);
        [DYYYUtils applyColorSettingsToLabel:rightLabel colorHexString:labelColorHex];
    } else {
        [rightLabel removeFromSuperview];
    }
}

- (void)setLimitUpperActionArea:(BOOL)arg1 {
    %orig;
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf dyyy_updateScheduleLabelsWithCurrentTime:0 totalDuration:0];
    });
}

- (void)setHidden:(BOOL)hidden {
    %orig;
    BOOL hideVideoProgress = DYYYGetBool(@"DYYYHideVideoProgress");
    BOOL showScheduleDisplay = DYYYGetBool(@"DYYYShowScheduleDisplay");
    if (hideVideoProgress && showScheduleDisplay && !hidden) {
        self.alpha = 0;
    }
}

%end

%hook AWEPlayInteractionTimestampElement

- (id)timestampLabel {
    UILabel *label = %orig;
    BOOL isEnableArea = DYYYGetBool(@"DYYYEnableArea");
    if (!isEnableArea) {
        return label;
    }

    NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelColor"];
    if (DYYYGetBool(@"DYYYEnableRandomGradient")) {
        labelColorHex = @"random_gradient";
    }

    BOOL boldEnabled = DYYYGetBool(@"DYYYBoldTimestamp");
    if (boldEnabled && label.font) {
        UIFont *boldFont = [UIFont boldSystemFontOfSize:label.font.pointSize];
        label.font = boldFont;
    }

    NSString *cityCode = self.model.cityCode;
    NSString *regionCode = nil;
    if ([self.model respondsToSelector:@selector(region)]) {
        regionCode = [self.model performSelector:@selector(region)];
    }

    if (cityCode && ([cityCode isEqualToString:@"0"] || [cityCode integerValue] == 0)) {
        cityCode = nil;
    }

    static NSCache *locationCache;
    static NSMutableSet *inFlight;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        locationCache = [[NSCache alloc] init];
        locationCache.countLimit = 100;
        inFlight = [[NSMutableSet alloc] init];
    });

    void (^updateLabelWithLocation)(UILabel *, NSString *) = ^(UILabel *lbl, NSString *location) {
        if (location.length == 0) return;

        NSString *currentText = lbl.text ?: @"";
        if ([currentText containsString:location]) return;

        if ([currentText containsString:@"IP属地："]) {
            NSRange range = [currentText rangeOfString:@"IP属地："];
            NSString *baseText = [currentText substringToIndex:range.location];
            lbl.text = [NSString stringWithFormat:@"%@IP属地：%@", baseText, location];
        } else if (currentText.length > 0) {
            lbl.text = [NSString stringWithFormat:@"%@  IP属地：%@", currentText, location];
        }

        [DYYYUtils applyColorSettingsToLabel:lbl colorHexString:labelColorHex];
    };

    if (cityCode.length == 0 && regionCode.length == 0) {
        updateLabelWithLocation(label, @"未知地区");
        return label;
    }

    NSString *cacheKey = cityCode.length > 0 ? cityCode : regionCode;

    NSString *cachedLocation = [locationCache objectForKey:cacheKey];
    if (cachedLocation) {
        updateLabelWithLocation(label, cachedLocation);

        NSString *ipScaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];
        if (ipScaleValue.length > 0) {
            UIFont *originalFont = label.font;
            CGFloat offset = DYYYGetFloat(@"DYYYIPLabelVerticalOffset");
            if (offset > 0) {
                label.transform = CGAffineTransformMakeTranslation(0, -offset);
            } else {
                label.transform = CGAffineTransformMakeTranslation(0, -3);
            }
            label.font = originalFont;
        }
        return label;
    }

    NSString *displayLocation = nil;

    if (cityCode.length > 0) {
        displayLocation = [CityManager.sharedInstance getCityNameWithCode:cityCode];

        if (!displayLocation && regionCode.length > 0) {
            displayLocation = [CityManager.sharedInstance getCountryNameWithCode:regionCode];
        }

        if (!displayLocation) {
            @synchronized(inFlight) {
                if ([inFlight containsObject:cityCode]) {
                    return label;
                }
                [inFlight addObject:cityCode];
            }

            [CityManager fetchLocationWithGeonameId:cityCode completionHandler:^(NSDictionary *locationInfo, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @synchronized(inFlight) {
                        [inFlight removeObject:cityCode];
                    }

                    NSString *apiLocation = nil;

                    if (!error && locationInfo) {
                        NSString *cityName = locationInfo[@"adminName1"];
                        NSString *countryName = locationInfo[@"countryName"];

                        if (cityName && countryName) {
                            if ([cityName isEqualToString:countryName]) {
                                apiLocation = countryName;
                            } else {
                                apiLocation = [NSString stringWithFormat:@"%@ %@", countryName, cityName];
                            }
                        } else if (countryName) {
                            apiLocation = countryName;
                        } else if (cityName) {
                            apiLocation = cityName;
                        }
                    }

                    if (apiLocation) {
                        [locationCache setObject:apiLocation forKey:cacheKey];
                        updateLabelWithLocation(label, apiLocation);
                    }
                });
            }];

            return label;
        }
    }

    if (!displayLocation && !cityCode && regionCode.length > 0) {
        displayLocation = [CityManager.sharedInstance getCountryNameWithCode:regionCode];
    }

    if (!displayLocation) {
        displayLocation = @"未知地区";
        updateLabelWithLocation(label, displayLocation);
        return label;
    }

    [locationCache setObject:displayLocation forKey:cacheKey];
    updateLabelWithLocation(label, displayLocation);

    NSString *ipScaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];
    if (ipScaleValue.length > 0) {
        UIFont *originalFont = label.font;
        CGFloat offset = DYYYGetFloat(@"DYYYIPLabelVerticalOffset");
        if (offset > 0) {
            label.transform = CGAffineTransformMakeTranslation(0, -offset);
        } else {
            label.transform = CGAffineTransformMakeTranslation(0, -3);
        }
        label.font = originalFont;
    }
    return label;
}

+ (BOOL)shouldActiveWithData:(id)arg1 context:(id)arg2 {
    return DYYYGetBool(@"DYYYEnableArea");
}

%end

%hook AWEPlayInteractionProgressController

%new
- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration {
    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        return;
    }

    id progressSlider = self.progressSlider;
    if (progressSlider && [progressSlider respondsToSelector:@selector(dyyy_updateScheduleLabelsWithCurrentTime:totalDuration:)]) {
        [progressSlider dyyy_updateScheduleLabelsWithCurrentTime:currentTime totalDuration:totalDuration];
    }

    if ([progressSlider isKindOfClass:[UIView class]]) {
        [(UIView *)progressSlider dyyy_updateScheduleLabelsLegacyWithCurrentTime:currentTime totalDuration:totalDuration model:self.model];
    }
}

- (void)updateProgressSliderWithTime:(CGFloat)arg1 totalDuration:(CGFloat)arg2 {
    %orig;
    [self dyyy_syncScheduleLabelsWithCurrentTime:arg1 totalDuration:arg2];
}

%end

%hook AWEDProgressCoreContainer

%new
- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration {
    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        return;
    }

    id progressSlider = self.progressSlider;
    if (progressSlider && [progressSlider respondsToSelector:@selector(dyyy_updateScheduleLabelsWithCurrentTime:totalDuration:)]) {
        [progressSlider dyyy_updateScheduleLabelsWithCurrentTime:currentTime totalDuration:totalDuration];
    }

    id model = nil;
    if ([self respondsToSelector:@selector(model)]) {
        model = [self valueForKey:@"model"];
    }

    if ([progressSlider isKindOfClass:[UIView class]]) {
        [(UIView *)progressSlider dyyy_updateScheduleLabelsLegacyWithCurrentTime:currentTime totalDuration:totalDuration model:model];
    }
}

- (void)updateProgressSliderWithTime:(CGFloat)arg1 totalDuration:(CGFloat)arg2 {
    %orig;
    [self dyyy_syncScheduleLabelsWithCurrentTime:arg1 totalDuration:arg2];
}

%end

%hook AWEPlayInteractionDescriptionScrollView

- (void)layoutSubviews {
    %orig;

    self.transform = CGAffineTransformIdentity;

    NSString *descriptionOffsetValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDescriptionVerticalOffset"];
    CGFloat verticalOffset = 0;
    if (descriptionOffsetValue.length > 0) {
        verticalOffset = [descriptionOffsetValue floatValue];
    }

    UIView *parentView = self.superview;
    UIView *grandParentView = nil;

    if (parentView) {
        grandParentView = parentView.superview;
    }

    if (grandParentView && verticalOffset != 0) {
        CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(0, verticalOffset);
        grandParentView.transform = translationTransform;
    }
}

%end

// 对新版文案的偏移（33.0以上）
%hook AWEPlayInteractionDescriptionLabel

static char kLongPressGestureKey;
static NSString *const kDYYYLongPressCopyEnabledKey = @"DYYYLongPressCopyTextEnabled";

- (void)didMoveToWindow {
    %orig;

    BOOL longPressCopyEnabled = DYYYGetBool(kDYYYLongPressCopyEnabledKey);

    if (![[NSUserDefaults standardUserDefaults] objectForKey:kDYYYLongPressCopyEnabledKey]) {
        longPressCopyEnabled = NO;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDYYYLongPressCopyEnabledKey];
    }

    UIGestureRecognizer *existingGesture = objc_getAssociatedObject(self, &kLongPressGestureKey);
    if (existingGesture && !longPressCopyEnabled) {
        [self removeGestureRecognizer:existingGesture];
        objc_setAssociatedObject(self, &kLongPressGestureKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    if (longPressCopyEnabled && !objc_getAssociatedObject(self, &kLongPressGestureKey)) {
        UILongPressGestureRecognizer *highPriorityLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHighPriorityLongPress:)];
        highPriorityLongPress.minimumPressDuration = 0.3;

        [self addGestureRecognizer:highPriorityLongPress];

        UIView *currentView = self;
        while (currentView.superview) {
            currentView = currentView.superview;

            for (UIGestureRecognizer *recognizer in currentView.gestureRecognizers) {
                if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]] || [recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
                    [recognizer requireGestureRecognizerToFail:highPriorityLongPress];
                }
            }
        }

        objc_setAssociatedObject(self, &kLongPressGestureKey, highPriorityLongPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer.view isEqual:self] && [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer.view isEqual:self] && [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

%new
- (void)handleHighPriorityLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {

        NSString *description = self.text;

        if (description.length > 0) {
            [[UIPasteboard generalPasteboard] setString:description];
            [DYYYToast showSuccessToastWithMessage:@"视频文案已复制"];
        }
    }
}

- (void)layoutSubviews {
    %orig;

    self.transform = CGAffineTransformIdentity;

    NSString *descriptionOffsetValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDescriptionVerticalOffset"];
    CGFloat verticalOffset = 0;
    if (descriptionOffsetValue.length > 0) {
        verticalOffset = [descriptionOffsetValue floatValue];
    }

    UIView *parentView = self.superview;
    UIView *grandParentView = nil;

    if (parentView) {
        grandParentView = parentView.superview;
    }

    if (grandParentView && verticalOffset != 0) {
        CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(0, verticalOffset);
        grandParentView.transform = translationTransform;
    }
}

%end

%hook AWEUserNameLabel

- (void)layoutSubviews {
    %orig;

    self.transform = CGAffineTransformIdentity;

    // 添加垂直偏移支持
    NSString *verticalOffsetValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameVerticalOffset"];
    CGFloat verticalOffset = 0;
    if (verticalOffsetValue.length > 0) {
        verticalOffset = [verticalOffsetValue floatValue];
    }

    UIView *parentView = self.superview;
    UIView *grandParentView = nil;

    if (parentView) {
        grandParentView = parentView.superview;
    }

    // 检查祖父视图是否为 AWEBaseElementView 类型
    if (grandParentView && [grandParentView.superview isKindOfClass:%c(AWEBaseElementView)]) {
        CGRect scaledFrame = grandParentView.frame;
        CGFloat translationX = -scaledFrame.origin.x;

        CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(translationX, verticalOffset);
        grandParentView.transform = translationTransform;
    }
}

%end

%hook AWEFeedVideoButton

- (void)setImage:(id)arg1 {
    UIImage *imageToApply = arg1;
    NSString *nameString = nil;

    if ([self respondsToSelector:@selector(imageNameString)]) {
        IMP imp = [self methodForSelector:@selector(imageNameString)];
        if (imp) {
            NSString *(*func)(id, SEL) = (NSString * (*)(id, SEL)) imp;
            if (func) {
                nameString = func(self, @selector(imageNameString));
            }
        }
    }

    NSString *customFileName = DYYYCustomIconFileNameForButtonName(nameString);
    if (customFileName.length > 0) {
        UIImage *customImage = DYYYLoadCustomImage(customFileName, CGSizeMake(44.0, 44.0));
        if (customImage) {
            imageToApply = customImage;
        }
    }

    %orig(imageToApply);
}

%end

%hook AWENormalModeTabBarGeneralPlusButton
- (void)setImage:(UIImage *)image forState:(UIControlState)state {

    UIImage *imageToApply = image;
    if ([self.accessibilityLabel isEqualToString:@"拍摄"]) {
        UIImage *customImage = DYYYLoadCustomImage(@"tab_plus.png", CGSizeZero);
        if (customImage) {
            imageToApply = customImage;
        }
    }

    %orig(imageToApply, state);
}
%end

// 获取资源的地址
%hook AWEURLModel
%new - (NSURL *)getDYYYSrcURLDownload {
    NSURL *bestURL;
    for (NSString *url in self.originURLList) {
        if ([url containsString:@"video_mp4"] || [url containsString:@".jpeg"] || [url containsString:@".mp3"]) {
            bestURL = [NSURL URLWithString:url];
        }
    }

    if (bestURL == nil) {
        bestURL = [NSURL URLWithString:[self.originURLList firstObject]];
    }

    return bestURL;
}
%end

// 屏蔽版本更新
%hook AWEVersionUpdateManager

- (void)startVersionUpdateWorkflow:(id)arg1 completion:(id)arg2 {
    if (DYYYGetBool(@"DYYYNoUpdates")) {
        if (arg2) {
            void (^completionBlock)(void) = arg2;
            completionBlock();
        }
    } else {
        %orig;
    }
}

- (id)workflow {
    return DYYYGetBool(@"DYYYNoUpdates") ? nil : %orig;
}

- (id)badgeModule {
    return DYYYGetBool(@"DYYYNoUpdates") ? nil : %orig;
}

%end

// 应用内推送毛玻璃效果
%hook AWEInnerNotificationWindow

- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableNotificationTransparency"]) {
        [self setupBlurEffectForNotificationView];
    }
}

- (void)didMoveToWindow {
    %orig;
    if (self.window && DYYYGetBool(@"DYYYEnableNotificationTransparency")) {
        [self setupBlurEffectForNotificationView];
    }
}

%new
- (void)setupBlurEffectForNotificationView {
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"AWEInnerNotificationContainerView"]) {
            [self applyBlurEffectToView:subview];
            break;
        }
    }
}

%new
- (void)applyBlurEffectToView:(UIView *)containerView {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!containerView) {
          return;
      }

      containerView.backgroundColor = [UIColor clearColor];

      float userRadius = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNotificationCornerRadius"] floatValue];
      if (!userRadius || userRadius < 0 || userRadius > 50) {
          userRadius = 12;
      }

      containerView.layer.cornerRadius = userRadius;
      containerView.layer.masksToBounds = YES;

      for (UIView *subview in containerView.subviews) {
          if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 999) {
              [subview removeFromSuperview];
          }
      }

      BOOL isDarkMode = [DYYYUtils isDarkMode];
      UIBlurEffectStyle blurStyle = isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
      UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
      UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

      blurView.frame = containerView.bounds;
      blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      blurView.tag = 999;
      blurView.layer.cornerRadius = userRadius;
      blurView.layer.masksToBounds = YES;

      float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
      if (userTransparency <= 0 || userTransparency > 1) {
          userTransparency = 0.5;
      }

      blurView.alpha = userTransparency;

      [containerView insertSubview:blurView atIndex:0];

      [self clearBackgroundRecursivelyInView:containerView];

      [self setLabelsColorWhiteInView:containerView];
    });
}

%new
- (void)setLabelsColorWhiteInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            NSString *text = label.text;

            if (![text isEqualToString:@"回复"] && ![text isEqualToString:@"查看"] && ![text isEqualToString:@"续火花"]) {
                label.textColor = [UIColor whiteColor];
            }
        }
        [self setLabelsColorWhiteInView:subview];
    }
}

%new
- (void)clearBackgroundRecursivelyInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 999 && [subview isKindOfClass:[UIButton class]]) {
            continue;
        }
        subview.backgroundColor = [UIColor clearColor];
        [self clearBackgroundRecursivelyInView:subview];
    }
}

%end

// 为 AWEUserActionSheetView 添加毛玻璃效果
%hook AWEUserActionSheetView

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYEnableSheetBlur")) {
        [self applyBlurEffectAndWhiteText];
    }
}

%new
- (void)applyBlurEffectAndWhiteText {
    // 应用毛玻璃效果到容器视图
    if (self.containerView) {
        self.containerView.backgroundColor = [UIColor clearColor];

        // 动态获取用户设置的透明度
        float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYSheetBlurTransparent"] floatValue];
        if (userTransparency <= 0 || userTransparency > 1) {
            userTransparency = 0.9; // 默认值0.9
        }

        [DYYYUtils applyBlurEffectToView:self.containerView transparency:userTransparency blurViewTag:9999];
        [DYYYUtils clearBackgroundRecursivelyInView:self.containerView];
        // 调用新的通用方法设置文本颜色，这里没有排除需求，所以传入 nil Block
        [DYYYUtils applyTextColorRecursively:[UIColor whiteColor] inView:self.containerView shouldExcludeViewBlock:nil];
    }
}

%end

%hook _TtC33AWECommentLongPressPanelSwiftImpl32CommentLongPressPanelCopyElement

- (void)elementTapped {
    if (DYYYGetBool(@"DYYYCommentCopyText")) {
        AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
        AWECommentModel *selectdComment = [commentPageContext selectdComment];
        if (!selectdComment) {
            AWECommentLongPressPanelParam *params = [commentPageContext params];
            selectdComment = [params selectdComment];
        }
        NSString *descText = [selectdComment content];
        [[UIPasteboard generalPasteboard] setString:descText];
        [DYYYToast showSuccessToastWithMessage:@"评论已复制"];
    }
}
%end

// 启用自动勾选原图
%hook AWEIMPhotoPickerFunctionModel

- (void)setUseShadowIcon:(BOOL)arg1 {
    BOOL enabled = DYYYGetBool(@"DYYYAutoSelectOriginalPhoto");
    if (enabled) {
        %orig(YES);
    } else {
        %orig(arg1);
    }
}

- (BOOL)isSelected {
    BOOL enabled = DYYYGetBool(@"DYYYAutoSelectOriginalPhoto");
    if (enabled) {
        return YES;
    }
    return %orig;
}

%end

// 屏蔽直播PCDN
%hook HTSLiveStreamPcdnManager

+ (void)start {
    BOOL disablePCDN = DYYYGetBool(@"DYYYDisableLivePCDN");
    if (!disablePCDN) {
        %orig;
    } else {
        NSLog(@"[DYYY] HTSLiveStreamPcdnManager start blocked");
    }
}

+ (void)configAndStartLiveIO {
    BOOL disablePCDN = DYYYGetBool(@"DYYYDisableLivePCDN");
    if (!disablePCDN) {
        %orig;
    } else {
        NSLog(@"[DYYY] HTSLiveStreamPcdnManager configAndStartLiveIO blocked");
    }
}

%end

// PCDN启动任务hook
%hook IESLiveLaunchTaskPcdn

- (void)excute {
    BOOL disablePCDN = DYYYGetBool(@"DYYYDisableLivePCDN");
    if (disablePCDN) {
        NSLog(@"[DYYY] IESLiveLaunchTaskPcdn excute blocked");
        return;
    }
    %orig;
}

%end

// 投屏忽略 VPN 检测
%hook BDByteCastUtils

+ (BOOL)netVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

%end

%hook BDByteCastNetUtilities

- (BOOL)getVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

%end

%hook BDByteCastMonitorManager

- (BOOL)netVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

- (void)setNetVPNStatus:(BOOL)netVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        %orig(NO);
        return;
    }
    %orig(netVPNStatus);
}

%end

%hook BDByteCastEnvInfo

- (BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

- (void)setIsVPNActive:(BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        %orig(NO);
        return;
    }
    %orig(isVPNActive);
}

%end

%hook BDByteScreenCastContext

- (BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

- (void)setIsVPNActive:(BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        %orig(NO);
        return;
    }
    %orig(isVPNActive);
}

%end

// 调整直播默认清晰度功能
static NSArray<NSString *> *dyyy_qualityRank = nil;

%hook HTSLiveStreamQualityFragment

- (void)setupStreamQuality:(id)arg1 {
    %orig;

    NSString *preferredQuality = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLiveQuality"];
    if (!preferredQuality || [preferredQuality isEqualToString:@"自动"]) {
        NSLog(@"[DYYY] Live quality auto - skipping hook");
        return;
    }

    BOOL preferLower = YES;
    NSLog(@"[DYYY] preferredQuality=%@ preferLower=%@", preferredQuality, @(preferLower));

    NSArray *qualities = self.streamQualityArray;
    if (!qualities || qualities.count == 0) {
        qualities = [self getQualities];
    }
    if (!qualities || qualities.count == 0) {
        return;
    }

    if (!dyyy_qualityRank) {
        dyyy_qualityRank = @[ @"蓝光帧彩", @"蓝光", @"超清", @"高清", @"标清" ];
    }
    NSArray *orderedNames = dyyy_qualityRank;

    // Map available names to their indices in the provided order
    NSMutableDictionary<NSString *, NSNumber *> *nameToIndex = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *availableNames = [NSMutableArray array];
    NSMutableArray<NSNumber *> *rankArray = [NSMutableArray array];
    for (NSInteger i = 0; i < qualities.count; i++) {
        id q = qualities[i];
        NSString *name = nil;
        if ([q respondsToSelector:@selector(name)]) {
            name = [q name];
        } else {
            name = [q valueForKey:@"name"];
        }
        if (name) {
            [availableNames addObject:name];
            nameToIndex[name] = @(i);
            NSInteger rank = [orderedNames indexOfObject:name];
            if (rank != NSNotFound) {
                [rankArray addObject:@(rank)];
            }
        }
    }
    NSLog(@"[DYYY] available qualities: %@", availableNames);

    BOOL qualityDesc = YES; // ranks ascending -> high to low
    BOOL qualityAsc = YES;  // ranks descending -> low to high
    for (NSInteger i = 1; i < rankArray.count; i++) {
        NSInteger prev = rankArray[i - 1].integerValue;
        NSInteger curr = rankArray[i].integerValue;
        if (curr < prev) {
            qualityDesc = NO;
        }
        if (curr > prev) {
            qualityAsc = NO;
        }
    }

    NSInteger count = availableNames.count;
    NSInteger (^convertIndex)(NSInteger) = ^NSInteger(NSInteger idx) {
      if (qualityAsc && !qualityDesc) {
          return count - 1 - idx;
      }
      return idx;
    };

    NSArray *searchOrder = orderedNames;

    NSNumber *indexToUse = nameToIndex[preferredQuality];
    if (indexToUse) {
        NSInteger finalIdx = convertIndex(indexToUse.integerValue);
        NSLog(@"[DYYY] exact quality %@ found at index %ld", preferredQuality, (long)finalIdx);
        [self setResolutionWithIndex:finalIdx isManual:YES beginChange:nil completion:nil];
        return;
    }

    NSInteger targetPos = [orderedNames indexOfObject:preferredQuality];
    if (targetPos == NSNotFound) {
        NSLog(@"[DYYY] preferred quality %@ not in list", preferredQuality);
        return;
    }

    NSInteger step = preferLower ? 1 : -1;
    BOOL applied = NO;
    for (NSInteger pos = targetPos + step; pos >= 0 && pos < searchOrder.count; pos += step) {
        NSString *candidate = searchOrder[pos];
        NSNumber *idx = nameToIndex[candidate];
        if (idx) {
            NSInteger finalIdx = convertIndex(idx.integerValue);
            NSLog(@"[DYYY] fallback quality %@ at index %ld", candidate, (long)finalIdx);
            [self setResolutionWithIndex:finalIdx isManual:YES beginChange:nil completion:nil];
            applied = YES;
            break;
        }
    }
    if (!applied) {
        NSLog(@"[DYYY] no suitable fallback quality found");
    }
}

%end

// 强制启用新版抖音长按 UI（现代风）
%hook AWELongPressPanelDataManager
+ (BOOL)enableModernLongPressPanelConfigWithSceneIdentifier:(id)arg1 {
    return DYYYGetBool(@"DYYYEnableModernPanel");
}
%end

%hook AWELongPressPanelABSettings
+ (NSUInteger)modernLongPressPanelStyleMode {
    if (!DYYYGetBool(@"DYYYEnableModernPanel")) {
        return %orig;
    }

    BOOL forceBlur = DYYYGetBool(@"DYYYLongPressPanelBlur");
    BOOL forceDark = DYYYGetBool(@"DYYYLongPressPanelDark");

    if (forceBlur && forceDark) {
        return 1;
    } else if (!forceBlur && !forceDark) {
        BOOL isDarkMode = [DYYYUtils isDarkMode];
        return isDarkMode ? 1 : 2;
    }
}
%end

%hook AWEModernLongPressPanelUIConfig
+ (NSUInteger)modernLongPressPanelStyleMode {
    if (!DYYYGetBool(@"DYYYEnableModernPanel")) {
        return %orig;
    }

    BOOL forceBlur = DYYYGetBool(@"DYYYLongPressPanelBlur");
    BOOL forceDark = DYYYGetBool(@"DYYYLongPressPanelDark");

    if (forceBlur && forceDark) {
        return 1;
    } else if (!forceBlur && !forceDark) {
        BOOL isDarkMode = [DYYYUtils isDarkMode];
        return isDarkMode ? 1 : 2;
    }
}
%end

// 禁用个人资料自动进入橱窗
%hook AWEUserTabListModel

- (NSInteger)profileLandingTab {
    if (DYYYGetBool(@"DYYYDefaultEnterWorks")) {
        return 0;
    } else {
        return %orig;
    }
}

%end

%group AutoPlay

%hook AWEAwemeDetailTableViewController

- (BOOL)hasIphoneAutoPlaySwitch {
    return YES;
}

%end

%hook AWEAwemeDetailContainerPlayControlConfig

- (BOOL)enableUserProfilePostAutoPlay {
    return YES;
}

%end

%hook AWEFeedIPhoneAutoPlayManager

- (BOOL)isAutoPlayOpen {
    return YES;
}

%end

%hook AWEFeedModuleService

- (BOOL)getFeedIphoneAutoPlayState {
    return YES;
}
%end

%hook AWEFeedIPhoneAutoPlayManager

- (BOOL)getFeedIphoneAutoPlayState {
    BOOL r = %orig;
    return YES;
}
%end

%end

%hook AWEPlayInteractionSpeedController

static BOOL hasChangedSpeed = NO;
static CGFloat currentLongPressSpeed = 0;
static CGFloat initialTouchX = 0;
static BOOL isGestureActive = NO;

- (CGFloat)longPressFastSpeedValue {
    float longPressSpeed = DYYYGetFloat(@"DYYYLongPressSpeed");
    if (longPressSpeed == 0) {
        longPressSpeed = 2.0;
    }
    return longPressSpeed;
}

- (void)changeSpeed:(double)speed {
    float longPressSpeed = DYYYGetFloat(@"DYYYLongPressSpeed");

    if (isGestureActive && currentLongPressSpeed > 0) {
        %orig(currentLongPressSpeed);
        return;
    }

    if (speed == 2.0) {
        if (!hasChangedSpeed) {
            if (longPressSpeed != 0 && longPressSpeed != 2.0) {
                hasChangedSpeed = YES;
                %orig(longPressSpeed);
                return;
            }
        } else {
            hasChangedSpeed = NO;
            %orig(1.0);
            return;
        }
    }

    if (longPressSpeed == 0 || longPressSpeed == 2) {
        %orig(speed);
        return;
    }
}

- (void)handleLongPressFastSpeed:(UILongPressGestureRecognizer *)gesture {
    %orig;

    if (!DYYYGetBool(@"DYYYEnableLongPressSpeedGesture")) {
        return;
    }

    CGPoint location = [gesture locationInView:gesture.view];

    static CGFloat initialTouchY = 0;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        initialTouchY = location.y;
        isGestureActive = YES;

        float longPressSpeed = DYYYGetFloat(@"DYYYLongPressSpeed");
        if (longPressSpeed == 0) {
            longPressSpeed = 2.0;
        }
        currentLongPressSpeed = longPressSpeed;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged && isGestureActive) {
        CGFloat deltaY = location.y - initialTouchY;
        CGFloat threshold = 10.0;

        if (fabs(deltaY) > threshold) {
            CGFloat speedChange;
            speedChange = (deltaY > 0) ? 0.25 : -0.25;

            CGFloat newSpeed = currentLongPressSpeed + speedChange;
            newSpeed = MAX(0.5, MIN(3.0, newSpeed));

            if (newSpeed != currentLongPressSpeed) {
                currentLongPressSpeed = newSpeed;
                initialTouchY = location.y;
                [self changeSpeed:currentLongPressSpeed];
            }
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded ||
             gesture.state == UIGestureRecognizerStateCancelled) {
        isGestureActive = NO;
        currentLongPressSpeed = 0;
        initialTouchY = 0;
    }
}
%end

%hook UILabel

- (void)setText:(NSString *)text {
    UIView *superview = self.superview;

    if ([superview isKindOfClass:%c(AFDFastSpeedView)] && text) {
        CGFloat displaySpeed = isGestureActive && currentLongPressSpeed > 0 ? currentLongPressSpeed : DYYYGetFloat(@"DYYYLongPressSpeed");
        if (displaySpeed == 0) {
            displaySpeed = 2.0;
        }

        NSString *speedString = [NSString stringWithFormat:@"%.2f", displaySpeed];
        if ([speedString hasSuffix:@".00"]) {
            speedString = [speedString substringToIndex:speedString.length - 3];
        } else if ([speedString hasSuffix:@"0"] && [speedString containsString:@"."]) {
            speedString = [speedString substringToIndex:speedString.length - 1];
        }

        if ([text containsString:@"2"]) {
            text = [text stringByReplacingOccurrencesOfString:@"2" withString:speedString];
        }
    }

    %orig(text);
}
%end

// 强制启用保存他人头像
%hook AFDProfileAvatarFunctionManager
- (BOOL)shouldShowSaveAvatarItem {
    BOOL shouldEnable = DYYYGetBool(@"DYYYEnableSaveAvatar");
    if (shouldEnable) {
        return YES;
    }
    return %orig;
}
%end

%hook AWECommentMediaDownloadConfigLivePhoto

BOOL commentLivePhotoNotWaterMark = DYYYGetBool(@"DYYYCommentLivePhotoNotWaterMark");

- (BOOL)needClientWaterMark {
    return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (BOOL)needClientEndWaterMark {
    return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (id)watermarkConfig {
    return commentLivePhotoNotWaterMark ? nil : %orig;
}

%end

%hook AWECommentImageModel
- (id)downloadUrl {
    if (DYYYGetBool(@"DYYYCommentNotWaterMark")) {
        return self.originUrl;
    }
    return %orig;
}
%end

%group EnableStickerSaveMenu
static __weak YYAnimatedImageView *targetStickerView = nil;
static BOOL dyyyShouldUseLastStickerURL = NO;

%hook _TtCV28AWECommentPanelListSwiftImpl6NEWAPI27CommentCellStickerComponent

- (void)handleLongPressWithGes:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if ([gesture.view isKindOfClass:%c(YYAnimatedImageView)]) {
            targetStickerView = (YYAnimatedImageView *)gesture.view;
            NSLog(@"DYYY 长按表情：%@", targetStickerView);
        } else {
            targetStickerView = nil;
        }
    }

    %orig;
}

%end

%hook _TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement

- (BOOL)elementShouldShow {
    BOOL shouldShow = %orig;
    if (!DYYYGetBool(@"DYYYForceDownloadEmotion") && !DYYYGetBool(@"DYYYForceDownloadCommentAudio")) {
        return shouldShow;
    }
    AWECommentLongPressPanelContext *context = [self commentPageContext];
    AWECommentModel *selected = [context selectdComment] ?: [[context params] selectdComment];
    AWEIMStickerModel *sticker = [selected sticker];
    NSArray *originURLList = sticker.staticURLModel.originURLList;
    if (originURLList.count > 0) {
        return YES;
    }
    AWECommentAudioModel *audio = [selected audioModel];
    if (audio && audio.content) {
        return YES;
    }
    return shouldShow;
}

- (void)elementTapped {
    AWECommentLongPressPanelContext *context = [self commentPageContext];
    AWECommentLongPressPanelParam *params = [context params];
    AWECommentModel *comment = [context selectdComment] ?: [params selectdComment];
    
    // 判断保存类型(表情包/音频/图片)
    AWEIMStickerModel *sticker = [comment sticker];
    NSArray *stickerURLList = sticker.staticURLModel.originURLList;
    BOOL hasSticker = (stickerURLList.count > 0);

    AWECommentAudioModel *audio = [comment audioModel];
    BOOL hasAudio = (audio && audio.content);
    
    NSArray *imageList = nil;
    if ([comment respondsToSelector:@selector(imageList)]) {
        imageList = [comment imageList];
    }
    BOOL hasImages = (imageList && imageList.count > 0);
    
    // 表情包保存逻辑
    if (hasSticker && DYYYGetBool(@"DYYYForceDownloadEmotion")) {
        NSString *urlString = dyyyShouldUseLastStickerURL ? stickerURLList.lastObject : stickerURLList.firstObject;
        dyyyShouldUseLastStickerURL = NO;
        NSURL *stickerURL = [NSURL URLWithString:urlString];
        
        if (stickerURL) {
            [DYYYManager downloadMedia:stickerURL
                             mediaType:MediaTypeHeic
                                 audio:nil
                            completion:^(BOOL success) {
                              if (!success && stickerURLList.count > 1) {
                                  dyyyShouldUseLastStickerURL = YES;
                              }
                            }];
            return;
        }
    }

    // 音频保存逻辑
    if (hasAudio && DYYYGetBool(@"DYYYForceDownloadCommentAudio")) {
        NSString *audioContent = audio.content;
        
        NSString *userName = @"未知用户";
        if (comment.author && [comment.author respondsToSelector:@selector(nickname)]) {
            NSString *nickname = [comment.author performSelector:@selector(nickname)];
            if (nickname && nickname.length > 0) {
                userName = nickname;
            }
        }
        
        [DYYYManager downloadAndShareCommentAudio:audioContent
                                         userName:userName
                                       createTime:comment.createTime];
        return;
    }

    // 图片保存逻辑
    if (hasImages && DYYYGetBool(@"DYYYForceDownloadCommentImage")) {
        // 检查 is_pic_inflow 判断是保存全部还是单张
        // is_pic_inflow = 1: 点开具体图片后长按 -> 只保存当前图片
        // is_pic_inflow = 0: 直接在评论区长按 -> 保存全部图片
        NSDictionary *extraParams = [params extraParams];
        BOOL isPicInflow = NO;
        if (extraParams && [extraParams isKindOfClass:[NSDictionary class]]) {
            id isPicInflowValue = extraParams[@"is_pic_inflow"];
            if (isPicInflowValue) {
                isPicInflow = [isPicInflowValue integerValue] == 1;
            }
        }
        
        NSInteger currentIndex = -1; // -1 表示保存全部
        
        if (isPicInflow) {
            // 使用 DYYYUtils 封装的方法查找目标控制器
            UIViewController *topVC = [DYYYUtils topView];
            
            // 获取 Ivar 定义的类和目标控制器类
            Class ivarClass = NSClassFromString(@"AWECommentMediaFeedSwfitImpl.CommentMediaFeedCellViewController");
            Class targetClass = NSClassFromString(@"AWECommentMediaFeedSwfitImpl.CommentMediaFeedCommonImageCellViewController");
            
            if (ivarClass && targetClass && topVC) {
                Ivar multiIndexIvar = class_getInstanceVariable(ivarClass, "currentIndexInMultiImageList");
                if (multiIndexIvar) {
                    UIViewController *cellVC = [DYYYUtils findViewControllerOfClass:targetClass inViewController:topVC];
                    if (cellVC) {
                        ptrdiff_t offset = ivar_getOffset(multiIndexIvar);
                        NSInteger *ptr = (NSInteger *)((char *)(__bridge void *)cellVC + offset);
                        currentIndex = *ptr;
                    }
                }
            }
        }
        
        NSString *hint = (currentIndex >= 0) ? @"正在保存当前图片..." : 
            [NSString stringWithFormat:@"正在保存 %lu 张图片...", (unsigned long)imageList.count];
        [DYYYUtils showToast:hint];
        
        [DYYYManager saveCommentImages:imageList
                            currentIndex:currentIndex
                            completion:^(NSInteger successCount, NSInteger livePhotoCount, NSInteger failedCount) {
            NSMutableString *message = [NSMutableString stringWithFormat:@"成功保存 %ld 张", (long)successCount];
            if (livePhotoCount > 0) {
                [message appendFormat:@"\n(含 %ld 张实况照片)", (long)livePhotoCount];
            }
            if (failedCount > 0) {
                [message appendFormat:@"\n失败 %ld 张", (long)failedCount];
            }
            [DYYYUtils showToast:message];
        }];
        return;
    }
    
    // 默认行为
    %orig;
}

%end

%hook UIMenu

+ (instancetype)menuWithTitle:(NSString *)title image:(UIImage *)image identifier:(UIMenuIdentifier)identifier options:(UIMenuOptions)options children:(NSArray<UIMenuElement *> *)children {
    BOOL hasAddStickerOption = NO;
    BOOL hasSaveLocalOption = NO;

    for (UIMenuElement *element in children) {
        NSString *elementTitle = nil;

        if ([element isKindOfClass:%c(UIAction)]) {
            elementTitle = [(UIAction *)element title];
        } else if ([element isKindOfClass:%c(UICommand)]) {
            elementTitle = [(UICommand *)element title];
        }

        if ([elementTitle isEqualToString:@"添加到表情"]) {
            hasAddStickerOption = YES;
        } else if ([elementTitle isEqualToString:@"保存到相册"]) {
            hasSaveLocalOption = YES;
        }
    }

    if (hasAddStickerOption && !hasSaveLocalOption) {
        NSMutableArray *newChildren = [children mutableCopy];

        UIAction *saveAction = [%c(UIAction) actionWithTitle:@"保存到相册"
                                                                 image:nil
                                                            identifier:nil
                                                               handler:^(__kindof UIAction *_Nonnull action) {
                                                                 // 使用全局变量 targetStickerView 保存当前长按的表情
                                                                 if (targetStickerView) {
                                                                     [DYYYManager saveAnimatedSticker:targetStickerView];
                                                                 } else {
                                                                     [DYYYUtils showToast:@"无法获取表情视图"];
                                                                 }
                                                               }];

        [newChildren addObject:saveAction];
        return %orig(title, image, identifier, options, newChildren);
    }

    return %orig;
}

%end
%end

%hook AWEIMEmoticonPreviewV2

// 添加保存按钮
- (void)layoutSubviews {
    %orig;
    static char kHasSaveButtonKey;
    BOOL DYYYForceDownloadPreviewEmotion = DYYYGetBool(@"DYYYForceDownloadPreviewEmotion");
    if (DYYYForceDownloadPreviewEmotion) {
        if (!objc_getAssociatedObject(self, &kHasSaveButtonKey)) {
            UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
            UIImage *downloadIcon = [UIImage systemImageNamed:@"arrow.down.circle"];
            [saveButton setImage:downloadIcon forState:UIControlStateNormal];
            [saveButton setTintColor:[UIColor whiteColor]];
            saveButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.9 alpha:0.5];

            saveButton.layer.shadowColor = [UIColor blackColor].CGColor;
            saveButton.layer.shadowOffset = CGSizeMake(0, 2);
            saveButton.layer.shadowOpacity = 0.3;
            saveButton.layer.shadowRadius = 3;

            saveButton.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:saveButton];
            CGFloat buttonSize = 24.0;
            saveButton.layer.cornerRadius = buttonSize / 2;

            [NSLayoutConstraint activateConstraints:@[
                [saveButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-15], [saveButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-10],
                [saveButton.widthAnchor constraintEqualToConstant:buttonSize], [saveButton.heightAnchor constraintEqualToConstant:buttonSize]
            ]];

            saveButton.userInteractionEnabled = YES;
            [saveButton addTarget:self action:@selector(dyyy_saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            objc_setAssociatedObject(self, &kHasSaveButtonKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

%new
- (void)dyyy_saveButtonTapped:(UIButton *)sender {
    // 获取表情包URL
    AWEIMEmoticonModel *emoticonModel = self.model;
    if (!emoticonModel) {
        [DYYYUtils showToast:@"无法获取表情包信息"];
        return;
    }

    NSString *urlString = nil;
    MediaType mediaType = MediaTypeImage;

    // 尝试动态URL
    if ([emoticonModel valueForKey:@"animate_url"]) {
        urlString = [emoticonModel valueForKey:@"animate_url"];
    }
    // 如果没有动态URL，则使用静态URL
    else if ([emoticonModel valueForKey:@"static_url"]) {
        urlString = [emoticonModel valueForKey:@"static_url"];
    }
    // 使用animateURLModel获取URL
    else if ([emoticonModel valueForKey:@"animateURLModel"]) {
        AWEURLModel *urlModel = [emoticonModel valueForKey:@"animateURLModel"];
        if (urlModel.originURLList.count > 0) {
            urlString = urlModel.originURLList[0];
        }
    }

    if (!urlString) {
        [DYYYUtils showToast:@"无法获取表情包链接"];
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    [DYYYManager downloadMedia:url
                     mediaType:MediaTypeHeic
                         audio:nil
                    completion:^(BOOL success){
                    }];
}

%end

static NSString *DYYYIMMessageStringValue(id object, NSString *selectorName) {
    if (!object || selectorName.length == 0) {
        return nil;
    }
    SEL selector = NSSelectorFromString(selectorName);
    if (!selector || ![object respondsToSelector:selector]) {
        return nil;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id value = [object performSelector:selector];
#pragma clang diagnostic pop
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
        return value;
    }
    return nil;
}

static NSURL *DYYYIMEmotionDownloadURLFromMessage(AWEIMGiphyMessage *giphyMessage) {
    if (!giphyMessage) {
        return nil;
    }
    NSString *urlString = nil;
    if (giphyMessage.giphyURL.originURLList.count > 0) {
        urlString = giphyMessage.giphyURL.originURLList.firstObject;
    }
    if (urlString.length == 0) {
        NSString *animateURL = DYYYIMMessageStringValue(giphyMessage, @"animateURL");
        if (animateURL.length > 0) {
            urlString = animateURL;
        }
    }
    if (urlString.length == 0) {
        NSString *displayIconURL = DYYYIMMessageStringValue(giphyMessage, @"displayIconURL");
        if (displayIconURL.length > 0) {
            urlString = displayIconURL;
        }
    }
    if (urlString.length == 0) {
        return nil;
    }
    return [NSURL URLWithString:urlString];
}

static AWEIMCustomMenuModel *DYYYIMCreateDownloadMenuItem(AWEIMReusableCommonCell *cell) {
    if (!cell) {
        return nil;
    }
    __weak AWEIMReusableCommonCell *weakCell = cell;
    AWEIMCustomMenuModel *menuItem = [%c(AWEIMCustomMenuModel) new];
    menuItem.title = @"保存表情";
    menuItem.imageName = @"im_emoticon_interactive_tab_new";
    menuItem.trackerName = @"保存表情";
    menuItem.willPerformMenuActionSelectorBlock = ^(id arg1) {
      AWEIMReusableCommonCell *strongCell = weakCell;
      if (!strongCell) {
          [DYYYUtils showToast:@"无法获取表情包信息"];
          return;
      }
      AWEIMMessageComponentContext *context = (AWEIMMessageComponentContext *)strongCell.currentContext;
      if (!context || ![context.message isKindOfClass:%c(AWEIMGiphyMessage)]) {
          [DYYYUtils showToast:@"无法获取表情包信息"];
          return;
      }
      NSURL *downloadURL = DYYYIMEmotionDownloadURLFromMessage((AWEIMGiphyMessage *)context.message);
      if (!downloadURL) {
          [DYYYUtils showToast:@"无法获取表情包链接"];
          return;
      }
      [DYYYManager downloadMedia:downloadURL
                       mediaType:MediaTypeHeic
                           audio:nil
                      completion:^(BOOL success){
                      }];
    };
    return menuItem;
}

static NSArray *DYYYIMMenuItemsByAddingDownloadAction(NSArray *menuItems, id cell) {
    if (!DYYYGetBool(@"DYYYForceDownloadIMEmotion")) {
        return menuItems;
    }
    if (!menuItems || !cell) {
        return menuItems;
    }
    AWEIMReusableCommonCell *commonCell = [cell isKindOfClass:%c(AWEIMReusableCommonCell)] ? (AWEIMReusableCommonCell *)cell : nil;
    if (!commonCell) {
        return menuItems;
    }
    AWEIMMessageComponentContext *context = (AWEIMMessageComponentContext *)commonCell.currentContext;
    if (!context || ![context.message isKindOfClass:%c(AWEIMGiphyMessage)]) {
        return menuItems;
    }
    for (AWEIMCustomMenuModel *item in menuItems) {
        if ([item isKindOfClass:%c(AWEIMCustomMenuModel)] && [item.title isEqualToString:@"保存表情"]) {
            return menuItems;
        }
    }
    NSMutableArray *newMenuItems = [menuItems mutableCopy];
    AWEIMCustomMenuModel *downloadItem = DYYYIMCreateDownloadMenuItem(commonCell);
    if (downloadItem) {
        [newMenuItems addObject:downloadItem];
    }
    return newMenuItems ?: menuItems;
}

%group DYYYIMMenuLegacyGroup
%hook AWEIMCustomMenuComponent
- (void)msg_showMenuForBubbleFrameInScreen:(CGRect)bubbleFrame tapLocationInScreen:(CGPoint)tapLocation menuItemList:(NSArray *)menuItems moreEmoticon:(BOOL)moreEmoticon onCell:(id)cell extra:(id)extra {
    NSArray *updatedMenuItems = DYYYIMMenuItemsByAddingDownloadAction(menuItems, cell);
    %orig(bubbleFrame, tapLocation, updatedMenuItems, moreEmoticon, cell, extra);
}
%end
%end

%group DYYYIMMenuTapLocationGroup
%hook AWEIMCustomMenuComponent
- (void)msg_showMenuForBubbleFrameInScreen:(CGRect)bubbleFrame tapLocationInScreen:(CGPoint)tapLocation menuItemList:(NSArray *)menuItems menuPanelOptions:(unsigned long long)menuPanelOptions moreEmoticon:(BOOL)moreEmoticon onCell:(id)cell extra:(id)extra {
    NSArray *updatedMenuItems = DYYYIMMenuItemsByAddingDownloadAction(menuItems, cell);
    %orig(bubbleFrame, tapLocation, updatedMenuItems, menuPanelOptions, moreEmoticon, cell, extra);
}
%end
%end

%group DYYYIMMenuHighLowGroup
%hook AWEIMCustomMenuComponent
- (void)msg_showMenuForBubbleFrameInScreen:(CGRect)bubbleFrame highLocationInScreen:(CGPoint)highLocation lowLocationInScreen:(CGPoint)lowLocation tryHighLocationFirst:(BOOL)tryHighLocationFirst menuItemList:(NSArray *)menuItems menuPanelOptions:(unsigned long long)menuPanelOptions onCell:(id)cell extra:(id)extra {
    NSArray *updatedMenuItems = DYYYIMMenuItemsByAddingDownloadAction(menuItems, cell);
    %orig(bubbleFrame, highLocation, lowLocation, tryHighLocationFirst, updatedMenuItems, menuPanelOptions, cell, extra);
}
%end
%end

%hook AWEFeedTabJumpGuideView

- (void)layoutSubviews {
    %orig;
    [self removeFromSuperview];
}

%end

%hook AWEFeedLiveMarkView
- (void)setHidden:(BOOL)hidden {
    if (DYYYGetBool(@"DYYYHideAvatarButton")) {
        hidden = YES;
    }

    %orig(hidden);
}
%end

// 隐藏头像加号和透明
%hook LOTAnimationView
- (void)layoutSubviews {
    %orig;
    // 确保只有头像的LOTAnimationView才则执行该逻辑, 防止误杀
    if ([self.superview isKindOfClass:%c(AWEPlayInteractionFollowPromptView)]) {
        // 检查是否需要隐藏加号
        if (DYYYGetBool(@"DYYYHideLOTAnimationView") || DYYYGetBool(@"DYYYHideFollowPromptView")) {
            [self removeFromSuperview];
            return;
        }
        // 应用透明度设置
        NSString *transparencyValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYAvatarViewTransparency"];
        if (transparencyValue && transparencyValue.length > 0) {
            CGFloat alphaValue = [transparencyValue floatValue];
            self.alpha = alphaValue;
        }
    }
}
%end

// 首页头像隐藏和透明
%hook AWEAdAvatarView
- (void)layoutSubviews {
    %orig;

    // 检查是否需要隐藏头像
    if (DYYYGetBool(@"DYYYHideAvatarButton")) {
        self.hidden = YES;
        return;
    }

    // 应用透明度设置
    NSString *transparencyValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYAvatarViewTransparency"];
    if (transparencyValue && transparencyValue.length > 0) {
        CGFloat alphaValue = [transparencyValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {
            self.alpha = alphaValue;
        }
    }
}
%end

// 移除同城吃喝玩乐提示框
%hook AWENearbySkyLightCapsuleView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideNearbyCapsuleView")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end


// 隐藏右下音乐和取消静音按钮
%hook AFDCancelMuteAwemeView
- (void)layoutSubviews {
    %orig;

    UIView *superview = self.superview;

    if ([superview isKindOfClass:NSClassFromString(@"AWEBaseElementView")]) {
        if (DYYYGetBool(@"DYYYHideCancelMute")) {
            self.hidden = YES;
            return;
        }
    }
}
%end

// 隐藏弹幕按钮
%hook AWEPlayDanmakuInputContainView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideDanmuButton")) {
        self.hidden = YES;
        return;
    }
}

%end

// 隐藏评论区免费去看短剧
%hook AWEShowPlayletCommentHeaderView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        self.hidden = YES;
        return;
    }
}

%end

// 隐藏评论区定位
%hook AWEPOIEntryAnchorView

- (void)p_addViews {
    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        return;
    }
    %orig;
}

%end

// 隐藏评论音乐
%hook AWECommentGuideLunaAnchorView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }

    if (DYYYGetBool(@"DYYYMusicCopyText")) {
        UILabel *label = nil;
        if ([self respondsToSelector:@selector(preTitleLabel)]) {
            label = [self valueForKey:@"preTitleLabel"];
        }
        if (label && [label isKindOfClass:[UILabel class]]) {
            label.text = @"";
        }
    }
}

- (void)p_didClickSong {
    if (DYYYGetBool(@"DYYYMusicCopyText")) {
        // 通过 KVC 拿到内部的 songButton
        UIButton *btn = nil;
        if ([self respondsToSelector:@selector(songButton)]) {
            btn = (UIButton *)[self valueForKey:@"songButton"];
        }

        // 获取歌曲名并复制到剪贴板
        if (btn && [btn isKindOfClass:[UIButton class]]) {
            NSString *song = btn.currentTitle;
            if (song.length) {
                [UIPasteboard generalPasteboard].string = song;
                [DYYYToast showSuccessToastWithMessage:@"歌曲名已复制"];
            }
        }
    } else {
        %orig;
    }
}

%end

// Swift 类组
%group CommentHeaderGeneralGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }
}
%end
%end
%group CommentHeaderGoodsGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }
}
%end
%end
%group CommentHeaderTemplateGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }
}
%end
%end
%group CommentBottomTipsVCGroup
%hook AWECommentPanelListSwiftImpl_CommentBottomTipsContainerViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    if (DYYYGetBool(@"DYYYHideCommentTips")) {
        ((UIViewController *)self).view.hidden = YES;
    }
}
%end
%end

// 去除隐藏大家都在搜后的留白
%hook AWESearchAnchorListModel

- (BOOL)hideWords {
    return DYYYGetBool(@"DYYYHideCommentViews");
}

%end

// 隐藏观看历史搜索
%hook AWEDiscoverFeedEntranceView
- (id)init {
    if (DYYYGetBool(@"DYYYHideInteractionSearch")) {
        return nil;
    }
    return %orig;
}
%end

// 隐藏校园提示
%hook AWETemplateTagsCommonView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideTemplateTags")) {
        UIView *parentView = self.superview;
        if (parentView) {
            parentView.hidden = YES;
        } else {
            self.hidden = YES;
        }
    }
}

%end



// 隐藏消息页顶栏头像气泡
%hook AFDSkylightCellBubble
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideAvatarBubble")) {
        [self removeFromSuperview];
    }
    %orig;
}
%end

// 隐藏消息页开启通知提示
%hook AWEIMMessageTabOptPushBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYHidePushBanner")) {
        return %orig(CGRectMake(frame.origin.x, frame.origin.y, 0, 0));
    }
    return %orig;
}

%end

// 隐藏消息页顶栏红包
%hook AWEIMMessageTabSideBarView
- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHideMessageTabRedPacket")) {
        return;
    }

    UIView *parentView = self.superview;
    if (!parentView) {
        return;
    }

    NSArray<UIView *> *siblings = [parentView.subviews copy];
    if (siblings.count <= 1) {
        return;
    }

    for (UIView *subview in siblings) {
        if (subview != self) {
            [subview removeFromSuperview];
        }
    }
}
%end

// 隐藏我的添加朋友
%hook AWEProfileNavigationButton
- (void)setupUI {

    if (DYYYGetBool(@"DYYYHideButton")) {
        return;
    }
    %orig;
}
%end

// 隐藏朋友"关注/不关注"按钮
%hook AWEFeedUnfollowFamiliarFollowAndDislikeView
- (void)showUnfollowFamiliarView {
    if (DYYYGetBool(@"DYYYHideFamiliar")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏朋友日常按钮
%hook AWEFamiliarNavView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideFamiliar")) {
        self.hidden = YES;
    }
    %orig;
}
%end

// 隐藏分享给朋友提示
%hook AWEPlayInteractionStrongifyShareContentView

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideShareContentView")) {
        UIView *parentView = self.superview;
        if (parentView) {
            parentView.hidden = YES;
        } else {
            self.hidden = YES;
        }
    }
}

%end


%hook AWELeftSideBarEntranceView

- (void)setRedDot:(id)redDot {
    %orig(nil);
}

- (void)setNumericalRedDot:(id)numericalRedDot {
    %orig(nil);
}

- (void)layoutSubviews {
    %orig;

    // 隐藏左侧边栏的 badge
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:%c(DUXBadge)]) {
            subview.hidden = YES;
            break;
        }
    }

    UIResponder *responder = self;
    UIViewController *parentVC = nil;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:%c(AWEFeedContainerViewController)]) {
            parentVC = (UIViewController *)responder;
            break;
        }
    }

    if (!(parentVC && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLeftSideBar"])) {
        return;
    }

    static char kDYLeftSideViewCacheKey;
    NSArray *cachedViews = objc_getAssociatedObject(self, &kDYLeftSideViewCacheKey);
    if (!cachedViews) {
        NSMutableArray *views = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:%c(DUXBaseImageView)]) {
                [views addObject:subview];
            }
        }
        cachedViews = [views copy];
        objc_setAssociatedObject(self, &kDYLeftSideViewCacheKey, cachedViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *v in cachedViews) {
        v.hidden = YES;
    }
}

%end

%hook AWEFeedVideoButton

- (void)layoutSubviews {
    %orig;

    NSString *accessibilityLabel = self.accessibilityLabel;

    BOOL hideBtn = NO;
    BOOL hideLabel = NO;

    if ([accessibilityLabel isEqualToString:@"点赞"]) {
        hideBtn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeButton"];
        hideLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeLabel"];
    } else if ([accessibilityLabel isEqualToString:@"评论"]) {
        hideBtn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentButton"];
        hideLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLabel"];
    } else if ([accessibilityLabel isEqualToString:@"分享"]) {
        hideBtn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareButton"];
        hideLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareLabel"];
    } else if ([accessibilityLabel isEqualToString:@"收藏"]) {
        hideBtn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectButton"];
        hideLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectLabel"];
    }

    if (!hideBtn && !hideLabel) {
        return; // 设置未启用，无需额外处理
    }

    if (hideBtn) {
        [self removeFromSuperview];
        return;
    }

    static char kDYLabelCacheKey;
    NSArray *cachedLabels = objc_getAssociatedObject(self, &kDYLabelCacheKey);
    if (!cachedLabels) {
        NSMutableArray *labels = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                [labels addObject:subview];
            }
        }
        cachedLabels = [labels copy];
        objc_setAssociatedObject(self, &kDYLabelCacheKey, cachedLabels, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UILabel *label in cachedLabels) {
        label.hidden = hideLabel;
    }
}

%end

%hook UIButton

- (void)layoutSubviews {
    %orig;

    NSString *accessibilityLabel = self.accessibilityLabel;

    if ([accessibilityLabel isEqualToString:@"拍照搜同款"] || [accessibilityLabel isEqualToString:@"扫一扫"]) {
        if (DYYYGetBool(@"DYYYHideScancode")) {
            [self removeFromSuperview];
        }
    }

    if ([accessibilityLabel isEqualToString:@"返回"]) {
        if (DYYYGetBool(@"DYYYHideBack")) {
            UIView *parent = self.superview;
            // 父视图是AWEBaseElementView(排除用户主页返回按钮) 按钮类不是AWENoxusHighlightButton(排除横屏返回按钮)
            if ([parent isKindOfClass:%c(AWEBaseElementView)] && ![self isKindOfClass:%c(AWENoxusHighlightButton)]) {
                [self removeFromSuperview];
            }
            return;
        }
    }
}

%end

%hook AWEIMFeedVideoQuickReplayInputViewController

- (void)viewDidLayoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideReply")) {
        [self.view removeFromSuperview];
        return;
    }
}

%end

%hook AWEHPSearchBubbleEntranceView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideSearchBubble")) {
        [self removeFromSuperview];
        return;
    }
}

%end

%hook AWEFeedLiveTabTopSelectionView
- (void)setHideTimer:(id)timer {
    if (DYYYGetBool(@"DYYYDisableAutoHideLive")) {
        timer = nil;
    }
    %orig(timer);
}
%end

%hook AWEMusicCoverButton

- (void)layoutSubviews {
    %orig;
    NSString *accessibilityLabel = self.accessibilityLabel;
    if ([accessibilityLabel isEqualToString:@"音乐详情"]) {
        if (DYYYGetBool(@"DYYYHideMusicButton")) {
            UIView *parent = self.superview;
            if (parent) {
                [parent removeFromSuperview];
            }
            return;
        }
    }
}

%end

%hook AWEPlayInteractionListenFeedView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideMusicButton")) {
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
        if (DYYYGetBool(@"DYYYHideAvatarButton") || DYYYGetBool(@"DYYYHideFollowPromptView")) {
            self.userInteractionEnabled = NO;
            self.hidden = YES;
            return;
        }
    }
}

%end

%hook AWEPlayInteractionElementMaskView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGradient")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook AWEGradientView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGradient")) {
        UIView *parent = self.superview;
        if ([parent.accessibilityLabel isEqualToString:@"暂停，按钮"] || [parent.accessibilityLabel isEqualToString:@"播放，按钮"] || [parent.accessibilityLabel isEqualToString:@"“切换视角，按钮"] ||
            [parent isKindOfClass:%c(AWEStoryProgressContainerView)]) {
            self.hidden = YES;
        }
        return;
    }
    %orig;
}
%end

%hook AWEHotSpotBlurView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGradient")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook AWEHotSearchInnerBottomView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideHotSearch")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 隐藏双指缩放虾线
%hook AWELoadingAndVolumeView

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    return;
}

%end

// 隐藏状态栏
%hook AWEFeedRootViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    } else {
        if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) != class_getInstanceMethod([%c(AWEFeedRootViewController) class], @selector(prefersStatusBarHidden))) {
            return %orig;
        }
        return NO;
    }
}
%end

// 直播状态栏
%hook IESLiveAudienceViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    } else {
        if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
            class_getInstanceMethod([%c(IESLiveAudienceViewController) class], @selector(prefersStatusBarHidden))) {
            return %orig;
        }
        return NO;
    }
}
%end

// 主页状态栏
%hook AWEAwemeDetailTableViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    } else {
        if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
            class_getInstanceMethod([%c(AWEAwemeDetailTableViewController) class], @selector(prefersStatusBarHidden))) {
            return %orig;
        }
        return NO;
    }
}
%end

// 热点状态栏
%hook AWEAwemeHotSpotTableViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    } else {
        if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
            class_getInstanceMethod([%c(AWEAwemeHotSpotTableViewController) class], @selector(prefersStatusBarHidden))) {
            return %orig;
        }
        return NO;
    }
}
%end

// 图文状态栏
%hook AWEFullPageFeedNewContainerViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    } else {
        if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
            class_getInstanceMethod([%c(AWEFullPageFeedNewContainerViewController) class], @selector(prefersStatusBarHidden))) {
            return %orig;
        }
        return NO;
    }
}
%end

// 纯净模式状态栏
%hook AFDPureModePageContainerViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    } else {
        if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
            class_getInstanceMethod([%c(AFDPureModePageContainerViewController) class], @selector(prefersStatusBarHidden))) {
            return %orig;
        }
        return NO;
    }
}
%end


%hook AWEPlayInteractionSearchAnchorView

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideInteractionSearch")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}

%end


// 隐藏暂停关键词
%hook AWEFeedPauseRelatedWordComponent

- (id)updateViewWithModel:(id)arg0 {
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        return nil;
    }
    return %orig;
}

- (id)pauseContentWithModel:(id)arg0 {
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        return nil;
    }
    return %orig;
}

- (id)recommendsWords {
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        return nil;
    }
    return %orig;
}

- (void)showRelatedRecommendPanelControllerWithSelectedText:(id)arg0 {
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        return;
    }
    %orig;
}

- (void)setupUI {
    %orig;
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        if (self.relatedView) {
            self.relatedView.hidden = YES;
        }
    }
}

%end

// 隐藏视频顶部搜索框、隐藏搜索框背景、应用全局透明
%hook AWESearchEntranceView

- (void)layoutSubviews {

    if (DYYYGetBool(@"DYYYHideSearchEntrance")) {
        self.hidden = YES;
        return;
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSearchEntranceIndicator"]) {
        static char kDYSearchIndicatorKey;
        NSArray *indicatorViews = objc_getAssociatedObject(self, &kDYSearchIndicatorKey);
        if (!indicatorViews) {
            NSMutableArray *tmp = [NSMutableArray array];
            for (UIView *subviews in self.subviews) {
                if ([subviews isKindOfClass:%c(UIImageView)] && [NSStringFromClass([((UIImageView *)subviews).image class]) isEqualToString:@"_UIResizableImage"]) {
                    [tmp addObject:subviews];
                }
            }
            indicatorViews = [tmp copy];
            objc_setAssociatedObject(self, &kDYSearchIndicatorKey, indicatorViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        for (UIImageView *imgView in indicatorViews) {
            imgView.hidden = YES;
        }
    }

    %orig;
}

%end

// 隐藏视频滑条
%hook AWEStoryProgressSlideView

- (void)layoutSubviews {
    %orig;

    BOOL shouldHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideStoryProgressSlide"];
    if (!shouldHide)
        return;

    static char kDYStoryProgressCacheKey;
    UIView *targetView = objc_getAssociatedObject(self, &kDYStoryProgressCacheKey);
    if (!targetView) {
        for (UIView *obj in self.subviews) {
            if ([obj isKindOfClass:NSClassFromString(@"UISlider")] || obj.frame.size.height < 5) {
                targetView = obj.superview;
                break;
            }
        }
        if (targetView) {
            objc_setAssociatedObject(self, &kDYStoryProgressCacheKey, targetView, OBJC_ASSOCIATION_ASSIGN);
        }
    }

    if (targetView) {
        targetView.hidden = YES;
    }
}

%end

// 隐藏好友分享私信
%hook AFDNewFastReplyView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHidePrivateMessages")) {
        UIView *parentView = self.superview;
        if (parentView) {
            parentView.hidden = YES;
        } else {
            self.hidden = YES;
        }
    }
}

%end



// 隐藏直播发现
%hook AWEFeedLiveTabRevisitControlView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideLiveDiscovery")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveDynamicRankListEntranceView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveDetail")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook _TtC18IESLiveRevenueImpl34IESLiveDynamicRankListEntranceView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveDetail")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveMatrixEntranceView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveDetail")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveShortTouchActionView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTouchView")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveLotteryAnimationViewNew
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTouchView")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveConfigurableShortTouchEntranceView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTouchView")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveRedEnvelopeAniLynxView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTouchView")) {
        self.hidden = YES;
        return;
    }
}
%end

// 隐藏直播点歌
%hook IESLiveKTVSongIndicatorView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideKTVSongIndicator")) {
        self.hidden = YES;
        return;
    }
}
%end

// 隐藏昵称右侧
%hook UILabel

static NSHashTable *processedParentViews = nil;

+ (void)load {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      processedParentViews = [NSHashTable weakObjectsHashTable];
    });
}

- (void)layoutSubviews {
    %orig;

    BOOL hideRightLabel = DYYYGetBool(@"DYYYHideRightLabel");
    if (!hideRightLabel)
        return;

    NSString *accessibilityLabel = self.accessibilityLabel;
    if (!accessibilityLabel || accessibilityLabel.length == 0)
        return;

    // 避免重复处理同一个父视图
    UIView *parentView = self.superview;
    if (!parentView)
        return;

    @synchronized(processedParentViews) {
        if ([processedParentViews containsObject:parentView]) {
            return;
        }
    }

    NSString *trimmedLabel = [accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL shouldRemove = NO;

    if ([trimmedLabel hasSuffix:@"人共创"] && trimmedLabel.length > 3) {
        NSString *prefix = [trimmedLabel substringToIndex:trimmedLabel.length - 3];
        NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        shouldRemove = ([prefix rangeOfCharacterFromSet:nonDigits].location == NSNotFound);
    }

    if (!shouldRemove) {
        shouldRemove = [trimmedLabel isEqualToString:@"章节要点"] || [trimmedLabel isEqualToString:@"图集"] || [trimmedLabel isEqualToString:@"下一章"];
    }

    if (shouldRemove) {
        @synchronized(processedParentViews) {
            [processedParentViews addObject:parentView];
        }

        UIView *grandparentView = parentView.superview; // 爷爷视图

        if (grandparentView) {

            dispatch_async(dispatch_get_main_queue(), ^{
              if ([grandparentView isKindOfClass:[UIStackView class]]) {
                  UIStackView *stackView = (UIStackView *)grandparentView;
                  [stackView removeArrangedSubview:parentView];
              }

              [parentView removeFromSuperview];

              // 强制刷新爷爷视图布局
              [grandparentView setNeedsLayout];
              [grandparentView layoutIfNeeded];
            });
        }
    }
}

%end

// 隐藏顶栏关注下的提示线
%hook AWEFeedMultiTabSelectedContainerView

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTopBarLine")) {
        self.hidden = YES;
    }
}

%end

%hook AFDRecommendToFriendEntranceLabel
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideRecommendTips")) {
        if (self.accessibilityLabel) {
            [self removeFromSuperview];
        }
    }
}

%end

// 隐藏自己无公开作品的视图
%hook AWEProfileMixItemCollectionViewCell
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        if ([self.accessibilityLabel isEqualToString:@"私密作品"]) {
            self.hidden = YES;
            return;
        }
    }
}
%end

%hook AWEProfilePostEmptyPublishGuideCollectionViewCell

- (void)didMoveToSuperview {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        if ([(UIView *)self superview]) {
            [(UIView *)self setHidden:YES];
        }
    }
}

%end

%hook AWEProfileTaskCardStyleListCollectionViewCell
- (BOOL)shouldShowPublishGuide {
    if (DYYYGetBool(@"DYYYHidePostView")) {
        return NO;
    }
    return %orig;
}
%end

%hook AWEProfileRichEmptyView

- (void)setTitle:(id)title {
    if (DYYYGetBool(@"DYYYHidePostView")) {
        return;
    }
    %orig(title);
}

- (void)setDetail:(id)detail {
    if (DYYYGetBool(@"DYYYHidePostView")) {
        return;
    }
    %orig(detail);
}
%end

// 隐藏关注直播顶端的直播视图
%hook AWENewLiveSkylightViewController

- (void)showSkylight:(BOOL)arg0 animated:(BOOL)arg1 actionMethod:(unsigned long long)arg2 {
    if (DYYYGetBool(@"DYYYHideLiveView")) {
        return;
    }
    %orig(arg0, arg1, arg2);
}

- (void)updateIsSkylightShowing:(BOOL)arg0 {
    if (DYYYGetBool(@"DYYYHideLiveView")) {
        %orig(NO);
    } else {
        %orig(arg0);
    }
}

%end

// 隐藏关注直播
%hook AWELiveSkylightViewModel

- (id)dataSource {
	BOOL DYYYHideConcernCapsuleView = DYYYGetBool(@"DYYYHideConcernCapsuleView");
	if (DYYYHideConcernCapsuleView) {
		return nil;
	}
	return %orig;
}

- (void)setDataSource:(id)dataSource {
	BOOL DYYYHideConcernCapsuleView = DYYYGetBool(@"DYYYHideConcernCapsuleView");
	if (DYYYHideConcernCapsuleView) {
		%orig(nil);
		return;
	}
	%orig;
}

%end

%hook AWELiveAutoEnterStyleAView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideLiveView")) {
        self.hidden = YES;
        return;
    }
}

%end

// 隐藏同城顶端
%hook AWENearbyFullScreenViewModel

- (void)setShowSkyLight:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideMenuView")) {
        arg1 = nil;
    }
    %orig(arg1);
}

- (void)setHaveSkyLight:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideMenuView")) {
        arg1 = nil;
    }
    %orig(arg1);
}

%end

// 隐藏笔记
%hook AWECorrelationItemTag

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideItemTag")) {
        self.hidden = YES;
        return;
    }
}

%end

// 屏蔽模板按钮组件（底部互动）- hook button 方法返回 nil
%hook AWEPlayInteractionTemplateButton
- (id)button {
	BOOL DYYYHideBottomInteraction = DYYYGetBool(@"DYYYHideBottomInteraction");
	if (DYYYHideBottomInteraction) {
		return nil;
	}
	return %orig;
}

- (void)setButton:(id)button {
	BOOL DYYYHideBottomInteraction = DYYYGetBool(@"DYYYHideBottomInteraction");
	if (DYYYHideBottomInteraction) {
		return;  // 不设置按钮
	}
	%orig;
}
%end

// 隐藏右上搜索，但可点击
%hook AWEHPDiscoverFeedEntranceView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideDiscover")) {
        UIView *firstSubview = self.subviews.firstObject;
        if ([firstSubview isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)firstSubview).image = nil;
        }
    }
}

%end

// 隐藏点击进入直播间
%hook AWELiveFeedStatusLabel
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideEnterLive")) {
        UIView *parentView = self.superview;
        UIView *grandparentView = parentView.superview;

        if (grandparentView) {
            grandparentView.hidden = YES;
            return;
        } else if (parentView) {
            parentView.hidden = YES;
            return;
        } else {
            self.hidden = YES;
            return;
        }
    }
    %orig;
}
%end

// 去除消息群直播提示
%hook AWEIMCellLiveStatusContainerView

- (void)p_initUI {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideGroupLiveIndicator"])
        %orig;
}
%end

%hook AWELiveStatusIndicatorView

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGroupLiveIndicator")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook AWELiveFeedLabelTagView
- (void)layoutSubviews {

    if (DYYYGetBool(@"DYYYHideLiveCapsuleView")) {
        UIView *parentView = self.superview;
        if (parentView) {
            parentView.hidden = YES;
            return;
        } else {
            self.hidden = YES;
            return;
        }
    }
    %orig;
}

%end

%hook AWEPlayInteractionLiveExtendGuideView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveCapsuleView")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 隐藏首页直播胶囊
%hook AWEHPTopTabItemBadgeContentView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideConcernCapsuleView")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏群商店
%hook AWEIMFansGroupTopDynamicDomainTemplateView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGroupShop")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 去除群聊天输入框上方快捷方式
%hook AWEIMInputActionBarInteractor

- (void)p_setupUI {
    if (DYYYGetBool(@"DYYYHideGroupInputActionBar")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏相机定位
%hook AWETemplateCommonView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideCameraLocation")) {
        [self removeFromSuperview];
    }
}
%end

// 隐藏侧栏红点
%hook AWEHPTopBarCTAItemView

- (void)showRedDot {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideSidebarDot"])
        %orig;
}

- (void)hideCountRedDot {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideSidebarDot"])
        %orig;
}

- (void)layoutSubviews {
    %orig;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSidebarDot"]) {
        return;
    }

    static char kDYSidebarBadgeCacheKey;
    NSArray *cachedBadges = objc_getAssociatedObject(self, &kDYSidebarBadgeCacheKey);
    if (!cachedBadges) {
        NSMutableArray *badges = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:%c(DUXBadge)]) {
                [badges addObject:subview];
            }
        }
        cachedBadges = [badges copy];
        objc_setAssociatedObject(self, &kDYSidebarBadgeCacheKey, cachedBadges, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *badge in cachedBadges) {
        badge.hidden = YES;
    }
}
%end

// 隐藏搜同款
%hook ACCStickerContainerView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideSearchSame")) {
        [self removeFromSuperview];
    }
}
%end

// 隐藏礼物展馆
%hook BDXWebView
- (void)layoutSubviews {
    %orig;

    BOOL enabled = DYYYGetBool(@"DYYYHideGiftPavilion");
    if (!enabled)
        return;

    NSString *title = [self valueForKey:@"title"];

    if ([title containsString:@"任务Banner"] || [title containsString:@"活动Banner"]) {
        self.hidden = YES;
    }
}
%end

%hook AWEVideoTypeTagView

- (void)setupUI {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideLiveGIF"])
        %orig;
}
%end

// 隐藏直播广场
%hook IESLiveFeedDrawerEntranceView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideLivePlayground")) {
        self.hidden = YES;
    }
}

%end

// 隐藏直播退出清屏、投屏按钮
%hook IESLiveButton

- (void)layoutSubviews {
    %orig;
    BOOL hideClear = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomClear"];
    BOOL hideMirror = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomMirroring"];
    BOOL hideFull = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomFullscreen"];
    BOOL hideClose = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomClose"];

    if (!(hideClear || hideMirror || hideFull)) {
        return;
    }

    NSString *label = self.accessibilityLabel;
    if (hideClear && [label isEqualToString:@"退出清屏"] && self.superview) {
        [self.superview removeFromSuperview];
        return;
    } else if (hideMirror && [label isEqualToString:@"投屏"] && self.superview) {
        self.superview.hidden = YES;
        return;
    } else if (hideFull && [label isEqualToString:@"横屏"] && self.superview) {
        static char kDYLiveButtonCacheKey;
        NSArray *cached = objc_getAssociatedObject(self, &kDYLiveButtonCacheKey);
        if (!cached) {
            cached = [self.subviews copy];
            objc_setAssociatedObject(self, &kDYLiveButtonCacheKey, cached, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        for (UIView *subview in cached) {
            subview.hidden = YES;
        }
        return;
    } else if (hideClose && [self.superview isKindOfClass:%c(HTSLive4LayerContainerView)]) {
        self.hidden = YES;
        return;
    }
}

%end

// 隐藏直播间右上方关闭直播按钮
%hook IESLiveLayoutPlaceholderView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveRoomClose")) {
        [self removeFromSuperview];
        return;
    }
}
%end

// 隐藏直播间流量弹窗
%hook AWELiveFlowAlertView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideCellularAlert")) {
        self.hidden = YES;
        return;
    }
}
%end

// 隐藏直播间商品和推广
%hook IESECLivePluginLayoutView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESECLiveCardSizeComponent
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESECLiveGoodsCardView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveBottomRightCardView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveGameCPExplainCardContainerImpl
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook AWEPOILivePurchaseAtmosphereView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg") && self.superview) {
        self.superview.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveActivityBannnerView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 隐藏直播间点赞动画
%hook HTSLiveDiggView
- (void)setIconImageView:(UIImageView *)arg1 {
    if (DYYYGetBool(@"DYYYHideLiveLikeAnimation")) {
        %orig(nil);
    } else {
        %orig(arg1);
    }
}
%end

// 隐藏直播间文字贴纸
%hook IESLiveStickerView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideStickerView")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 隐藏直播间礼物挑战
%hook IESLiveGroupLiveComponentView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGroupComponent")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 预约直播
%hook IESLivePreAnnouncementPanelViewNew
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideStickerView")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏会员进场特效
%hook IESLiveDynamicUserEnterView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLivePopup")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 会员进场特效: 高版本启用swift类名
%hook _TtC18IESLiveRevenueImpl32IESLiveSwiftDynamicUserEnterView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLivePopup")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏特殊进场特效
%hook PlatformCanvasView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLivePopup")) {
        UIView *pview = self.superview;
        UIView *gpview = pview.superview;
        // 基于accessibilitylabel的判断
        BOOL isLynxView = [pview isKindOfClass:%c(UILynxView)] && [gpview isKindOfClass:%c(LynxView)] && [gpview.accessibilityLabel isEqualToString:@"lynxview"];
        // 基于最近的视图控制器IESLiveAudienceViewController的判断
        UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
        BOOL isLiveAudienceVC = [vc isKindOfClass:%c(IESLiveAudienceViewController)];
        if (isLynxView && isLiveAudienceVC) {
            self.hidden = YES;
        }
    }
    return;
}
%end

// 特殊视频进场特效:高版本启用swift类名
%hook _TtC18IESLiveRevenueImpl35IESLiveSwiftVideoLayerUserEnterView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLivePopup")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveDanmakuVariousView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveDanmaku")) {
        self.hidden = YES;
        return;
    }
    %orig;
}

%end

%hook IESLiveDanmakuSupremeView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveDanmaku")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveHotMessageView
- (void)layoutSubviews {

    if (DYYYGetBool(@"DYYYHideLiveHotMessage")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook AWEHotListDataController

%new
- (NSNumber *)dyyy_numberValueForLowLikesFilter:(id)rawValue {
    if (!rawValue || rawValue == [NSNull null]) {
        return nil;
    }

    if ([rawValue isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)rawValue;
    }

    if ([rawValue isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)rawValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0) {
            return nil;
        }

        NSScanner *integerScanner = [NSScanner scannerWithString:trimmed];
        long long integerValue = 0;
        if ([integerScanner scanLongLong:&integerValue] && integerScanner.isAtEnd) {
            return @(integerValue);
        }

        NSScanner *doubleScanner = [NSScanner scannerWithString:trimmed];
        double doubleValue = 0.0;
        if ([doubleScanner scanDouble:&doubleValue] && doubleScanner.isAtEnd) {
            return @((long long)llround(doubleValue));
        }
    }

    return nil;
}

%new
- (NSNumber *)dyyy_resolvedDiggCountForAweme:(AWEAwemeModel *)aweme {
    if (!aweme) {
        return nil;
    }

    static NSArray<NSString *> *diggKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        diggKeyPaths = @[
            @"statistics.diggCount",
            @"statistics.digg_count",
            @"diggCount",
            @"digg_count",
            @"feedSequenceExtendFeature.digg_count",
            @"feedSequenceExtendFeature.diggCount",
            @"recommendFeedExtendFeature.digg_count",
            @"recommendFeedExtendFeature.diggCount"
        ];
    });

    for (NSString *keyPath in diggKeyPaths) {
        id rawValue = nil;
        @try {
            rawValue = [aweme valueForKeyPath:keyPath];
        } @catch (__unused NSException *exception) {
            rawValue = nil;
        }

        NSNumber *resolved = [self dyyy_numberValueForLowLikesFilter:rawValue];
        if (resolved) {
            return resolved;
        }
    }

    return nil;
}

- (id)transferAwemeListIfNeededWithArray:(id)arg1 isInitFetch:(BOOL)arg2 {
    NSArray *orig = %orig;
    if (![orig isKindOfClass:[NSArray class]] || orig.count == 0) {
        return orig;
    }

    // --- 配置读取 ---
    NSInteger daysThreshold = DYYYGetInteger(@"DYYYFilterTimeLimit");
    BOOL skipLive = DYYYGetBool(@"DYYYSkipLive"); // 读取直播过滤开关
    NSInteger minLikesThreshold = DYYYGetInteger(@"DYYYFilterLowLikes"); // 读取低赞过滤阈值 (例如: 1000)
    BOOL skipPhotoText = DYYYGetBool(@"DYYYSkipPhotoText"); // 图文过滤
    BOOL skipPhoto = DYYYGetBool(@"DYYYSkipPhoto"); // 图集过滤

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval thresholdInSeconds = MAX(daysThreshold, 0) * 86400.0;

    // 第一阶段：先做稳定字段过滤（直播/时间/类型）
    NSMutableArray *baseFiltered = [NSMutableArray arrayWithCapacity:orig.count];

    for (id obj in orig) {
        if (![obj isKindOfClass:%c(AWEAwemeModel)]) {
            [baseFiltered addObject:obj];
            continue;
        }

        AWEAwemeModel *m = (AWEAwemeModel *)obj;

        // 1. 广告白名单
        if ([m respondsToSelector:@selector(isAds)] && m.isAds) {
            [baseFiltered addObject:obj];
            continue;
        }

        // 2. 直播过滤逻辑 (仅依赖 cellRoom)
        if (skipLive && [m respondsToSelector:@selector(cellRoom)] && m.cellRoom != nil) {
            continue; // 命中直播过滤，跳过
        }

        // 2.1 图文模式过滤逻辑（推荐页）
        if (skipPhotoText &&
            [m respondsToSelector:@selector(isNewTextMode)] &&
            m.isNewTextMode &&
            [m respondsToSelector:@selector(referString)] &&
            [m.referString isEqualToString:@"homepage_hot"]) {
            continue; // 图文模式且来自推荐页，跳过
        }

        // 2.2 图集过滤逻辑（推荐页）
        if (skipPhoto &&
            [m respondsToSelector:@selector(awemeType)] &&
            m.awemeType == 68 &&
            [m respondsToSelector:@selector(referString)] &&
            [m.referString isEqualToString:@"homepage_hot"]) {
            continue; // 图集且来自推荐页，跳过
        }

        // 3. 时间限制过滤
        if (daysThreshold > 0 && [m respondsToSelector:@selector(createTime)]) {
            NSTimeInterval vTs = [m.createTime doubleValue];
            if (vTs > 1e12) {
                vTs /= 1000.0; // 毫秒转秒
            }

            if (vTs > 0 && (now - vTs) > thresholdInSeconds) {
                continue; // 超过设定时限，跳过
            }
        }

        [baseFiltered addObject:obj];
    }

    if (minLikesThreshold <= 0 || baseFiltered.count == 0) {
        return [baseFiltered copy];
    }

    // 第二阶段：低赞过滤（字段缺失时放行，避免误杀）
    NSMutableArray *lowLikesFiltered = [NSMutableArray arrayWithCapacity:baseFiltered.count];
    NSInteger awemeCount = 0;
    NSInteger unresolvedLikesCount = 0;
    NSInteger filteredByLowLikesCount = 0;

    for (id obj in baseFiltered) {
        if (![obj isKindOfClass:%c(AWEAwemeModel)]) {
            [lowLikesFiltered addObject:obj];
            continue;
        }

        awemeCount++;
        AWEAwemeModel *m = (AWEAwemeModel *)obj;
        NSNumber *diggCountValue = [self dyyy_resolvedDiggCountForAweme:m];
        NSInteger diggCount = diggCountValue.integerValue;

        // 新版部分链路点赞字段会短暂缺失/回填为0，这里按未知放行，避免整批误过滤
        if (!diggCountValue || diggCount <= 0) {
            unresolvedLikesCount++;
            [lowLikesFiltered addObject:obj];
            continue;
        }

        if (diggCount < minLikesThreshold) {
            filteredByLowLikesCount++;
            continue;
        }

        [lowLikesFiltered addObject:obj];
    }

    CGFloat unresolvedRatio = awemeCount > 0 ? ((CGFloat)unresolvedLikesCount / (CGFloat)awemeCount) : 0.0f;
    BOOL shouldRollbackLowLikes = (awemeCount >= 3 && lowLikesFiltered.count <= 1 && unresolvedRatio >= 0.5f);
    BOOL shouldPreventEmptyBatch = (awemeCount >= 3 && lowLikesFiltered.count == 0 && filteredByLowLikesCount > 0);

    if (shouldRollbackLowLikes || shouldPreventEmptyBatch) {
        NSLog(@"[DYYY] 低赞过滤回退: total=%ld kept=%ld unresolved=%ld lowLikesFiltered=%ld threshold=%ld",
              (long)awemeCount,
              (long)lowLikesFiltered.count,
              (long)unresolvedLikesCount,
              (long)filteredByLowLikesCount,
              (long)minLikesThreshold);
        return [baseFiltered copy];
    }

    return [lowLikesFiltered copy];
}

%end

%hook AWEAwemeModel

- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
    id orig = %orig;
    if (orig && [self contentFilter])
        return nil;
    return orig;
}

%new
- (BOOL)contentFilter {
    BOOL noAds = DYYYGetBool(@"DYYYNoAds");
    BOOL skipAllLive = DYYYGetBool(@"DYYYSkipAllLive");
    BOOL skipHotSpot = DYYYGetBool(@"DYYYSkipHotSpot");
    BOOL skipPhoto = DYYYGetBool(@"DYYYSkipPhoto");
    BOOL skipPhotoText = DYYYGetBool(@"DYYYSkipPhotoText");
    BOOL skipMusic = DYYYGetBool(@"DYYYSkipMusic");
    BOOL skipAIInteraction = DYYYGetBool(@"DYYYSkipAIInteraction");
    BOOL filterHDR = DYYYGetBool(@"DYYYFilterFeedHDR");

    BOOL shouldFilterAds = noAds && (self.isAds);
    BOOL shouldFilterHotSpot = skipHotSpot && self.hotSpotLynxCardModel;
    BOOL shouldFilterAllLive = skipAllLive && [self.videoFeedTag isEqualToString:@"直播中"];
    BOOL isRecommendFeed = [self.referString isEqualToString:@"homepage_hot"];
    BOOL shouldskipPhoto = skipPhoto && (self.awemeType == 68) && isRecommendFeed;
    BOOL shouldskipPhotoText = skipPhotoText && self.isNewTextMode && isRecommendFeed;
    BOOL shouldFilterMusic = skipMusic && self.musicCard && isRecommendFeed; // or self.awemeType == 155
    BOOL shouldFilterAIInteraction = skipAIInteraction && (self.awemeType == 162) && isRecommendFeed;
    BOOL shouldFilterHDR = NO;
    BOOL shouldFilterLowLikes = NO;
    BOOL shouldFilterKeywords = NO;
    BOOL shouldFilterProp = NO;
    BOOL shouldFilterTime = NO;
    BOOL shouldFilterUser = NO;

    // 获取用户设置的需要过滤的关键词
    NSString *filterKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"];
    NSArray *keywordsList = nil;

    if (filterKeywords.length > 0) {
        keywordsList = [filterKeywords componentsSeparatedByString:@","];
    }

    // 过滤包含指定拍同款的视频
    NSString *filterProp = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterProp"];
    NSArray *propKeywordsList = nil;

    if (filterProp.length > 0) {
        propKeywordsList = [filterProp componentsSeparatedByString:@","];
    }

    // 获取需要过滤的用户列表
    NSString *filterUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterUsers"];

    // 检查是否需要过滤特定用户
    if (isRecommendFeed && filterUsers.length > 0 && self.author) {
        NSArray *usersList = [filterUsers componentsSeparatedByString:@","];
        NSString *currentShortID = self.author.shortID;
        NSString *currentNickname = self.author.nickname;

        if (currentShortID.length > 0) {
            for (NSString *userInfo in usersList) {
                // 解析"昵称-id"格式
                NSArray *components = [userInfo componentsSeparatedByString:@"-"];
                if (components.count >= 2) {
                    NSString *userId = [components lastObject];
                    NSString *userNickname = [[components subarrayWithRange:NSMakeRange(0, components.count - 1)] componentsJoinedByString:@"-"];

                    if ([userId isEqualToString:currentShortID]) {
                        shouldFilterUser = YES;
                        break;
                    }
                }
            }
        }
    }

    // 仅在推荐页过滤关键词和道具
    if (isRecommendFeed) {
        // 过滤包含特定关键词的视频
        if (keywordsList.count > 0) {
            // 检查视频标题
            if (self.descriptionString.length > 0) {
                for (NSString *keyword in keywordsList) {
                    NSString *trimmedKeyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (trimmedKeyword.length > 0 && [self.descriptionString containsString:trimmedKeyword]) {
                        shouldFilterKeywords = YES;
                        break;
                    }
                }
            }
        }

        // 过滤包含特定道具的视频
        if (propKeywordsList.count > 0 && self.propGuideV2) {
            NSString *propName = self.propGuideV2.propName;
            if (propName.length > 0) {
                for (NSString *propKeyword in propKeywordsList) {
                    NSString *trimmedKeyword = [propKeyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (trimmedKeyword.length > 0 && [propName containsString:trimmedKeyword]) {
                        shouldFilterProp = YES;
                        break;
                    }
                }
            }
        }
    }


    // 检查是否为HDR视频
    if (filterHDR && self.video && self.video.bitrateModels) {
        for (id bitrateModel in self.video.bitrateModels) {
            NSNumber *hdrType = [bitrateModel valueForKey:@"hdrType"];
            NSNumber *hdrBit = [bitrateModel valueForKey:@"hdrBit"];

            // 如果hdrType=1且hdrBit=10，则视为HDR视频
            if (hdrType && [hdrType integerValue] == 1 && hdrBit && [hdrBit integerValue] == 10) {
                shouldFilterHDR = YES;
                break;
            }
        }
    }
    return shouldFilterAds || shouldFilterAllLive || shouldFilterHotSpot || shouldFilterHDR || shouldFilterKeywords || shouldFilterProp ||
           shouldFilterTime || shouldFilterUser;
}

- (AWEECommerceLabel *)ecommerceBelowLabel {
    if (DYYYGetBool(@"DYYYHideHisShop")) {
        return nil;
    }
    return %orig;
}

- (void)setEcommerceBelowLabel:(id)label {
	if (DYYYGetBool(@"DYYYHideHisShop")) {
		%orig(nil);
		return;
	}
	%orig;
}

- (void)setDescriptionString:(NSString *)desc {
    NSString *labelStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelStyle"];
    BOOL hideLabel = [labelStyle isEqualToString:@"文案标签隐藏"];
    if (hideLabel) {
        // 过滤掉所有以 # 开头的标签
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#\\S+" options:0 error:nil];
        NSString *filtered = [regex stringByReplacingMatchesInString:desc options:0 range:NSMakeRange(0, desc.length) withTemplate:@""];
        // 去除首尾空白字符
        filtered = [filtered stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // 为空则赋nil，避免显示空行
        desc = filtered.length > 0 ? filtered : nil;
    }
    %orig(desc);
}

- (void)setTextExtras:(NSArray *)extras {
    NSString *labelStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelStyle"];
    BOOL disableLabelSearch = [labelStyle isEqualToString:@"文案标签禁止跳转搜索"] || [labelStyle isEqualToString:@"文案标签隐藏"];
    if (disableLabelSearch && [extras isKindOfClass:[NSArray class]]) {
        NSMutableArray *filtered = [NSMutableArray array];
        for (AWEAwemeTextExtraModel *model in extras) {
            if (model.userID.length > 0) {
                [filtered addObject:model];
            }
        }
        extras = [filtered copy];
    }
    %orig(extras);
}

// 固定设置为 1，启用自定义背景色
- (NSUInteger)awe_playerBackgroundViewShowType {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYVideoBGColor"]) {
        return 1;
    }
    return %orig;
}

- (UIColor *)awe_smartBackgroundColor {
    NSString *colorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYVideoBGColor"];
    if (colorHex && colorHex.length > 0) {
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        UIColor *customColor = [DYYYUtils colorFromSchemeHexString:colorHex targetWidth:screenWidth];
        if (customColor)
            return customColor;
    }
    return %orig;
}

//屏蔽章节要点数据
- (NSArray *)chapterList {
	BOOL hideChapterList = DYYYGetBool(@"DYYYHideChapterProgress");
	if (hideChapterList) {
		return @[]; // 返回空数组
	}
	return %orig;
}

// 屏蔽共创数据
- (id)acceptedCoCreators {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return @[]; // 永远为空
	}
	return %orig;
}

- (id)unAcceptedCoCreators {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return @[];
	}
	return %orig;
}

- (NSInteger)acceptedCoCreatorsNums {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return 0;
	}
	return %orig;
}

- (id)awe_coCreatorPoster {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return nil;
	}
	return %orig;
}

- (id)awe_coCreatorFromAuthor {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return nil;
	}
	return %orig;
}

- (id)awe_userModelWithCoCreator:(id)creator {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return nil;
	}
	return %orig;
}


// 屏蔽相关视频推荐
- (id)relatedVideoExtra {
	BOOL DYYYHideBottomRelated = DYYYGetBool(@"DYYYHideBottomRelated");
	if (DYYYHideBottomRelated) {
		return nil;
	}
	return %orig;
}

- (id)relatedVideo {
	BOOL DYYYHideBottomRelated = DYYYGetBool(@"DYYYHideBottomRelated");
	if (DYYYHideBottomRelated) {
		return nil;
	}
	return %orig;
}

- (id)playletRelatedVideoInfoModel {
	BOOL DYYYHideBottomRelated = DYYYGetBool(@"DYYYHideBottomRelated");
	if (DYYYHideBottomRelated) {
		return nil;
	}
	return %orig;
}

// 屏蔽评论搜索锚点
- (id)commonSearchAnchor {
	BOOL DYYYHideCommentLongPressSearch = DYYYGetBool(@"DYYYHideCommentLongPressSearch");
	if (DYYYHideCommentLongPressSearch) {
		return nil;
	}
	return %orig;
}

- (void)setCommonSearchAnchor:(id)arg {
	BOOL DYYYHideCommentLongPressSearch = DYYYGetBool(@"DYYYHideCommentLongPressSearch");
	if (DYYYHideCommentLongPressSearch) {
		%orig(nil);
		return;
	}
	%orig;
}

// 屏蔽汽水音乐锚点
- (id)relatedMusicAnchor {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		return nil;
	}
	return %orig;
}

- (void)setRelatedMusicAnchor:(id)anchor {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		%orig(nil);
		return;
	}
	%orig;
}

// 屏蔽底栏热点
- (id)hotSpotRawData {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return nil;
	}
	return %orig;
}

- (void)setHotSpotRawData:(id)data {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)hotSpotListModel {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return nil;
	}
	return %orig;
}

- (void)setHotSpotListModel:(id)model {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		%orig(nil);
		return;
	}
	%orig;
}

- (NSString *)templateBarsString {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (void)setTemplateBarsString:(NSString *)string {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		%orig(@"");
		return;
	}
	%orig;
}

// 屏蔽底部合集（只对推荐页生效）
- (id)mixInfo {
	BOOL DYYYHideTemplateVideo = DYYYGetBool(@"DYYYHideTemplateVideo");
	if (DYYYHideTemplateVideo && [self.referString isEqualToString:@"homepage_hot"]) {
		return nil;
	}
	return %orig;
}

// 屏蔽短剧信息（复用屏蔽合集开关，只对推荐页生效）
- (id)playletInfoModel {
	BOOL DYYYHideTemplatePlaylet = DYYYGetBool(@"DYYYHideTemplatePlaylet");
	if (DYYYHideTemplatePlaylet && [self.referString isEqualToString:@"homepage_hot"]) {
		return nil;
	}
	return %orig;
}

// 屏蔽锚点信息
- (id)anchorInfo {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) {
		return nil;
	}
	return %orig;
}

- (void)setAnchorInfo:(id)info {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)localLifeAnchorInfo {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) {
		return nil;
	}
	return %orig;
}

- (void)setLocalLifeAnchorInfo:(id)info {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)nearbyFeedDualAnchorInfo {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) {
		return nil;
	}
	return %orig;
}

- (void)setNearbyFeedDualAnchorInfo:(id)info {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)minorAnchorInfo {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) {
		return nil;
	}
	return %orig;
}

- (void)setMinorAnchorInfo:(id)info {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) {
		%orig(nil);
		return;
	}
	%orig;
}

// 屏蔽通用锚点（合并到锚点信息）
- (id)commonAnchor {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) { 
		return nil;
	}
	return %orig;
}

- (void)setCommonAnchor:(id)anchor {
	BOOL DYYYHideFeedAnchorContainer = DYYYGetBool(@"DYYYHideFeedAnchorContainer");
	if (DYYYHideFeedAnchorContainer) {
		%orig(nil);
		return;
	}
	%orig;
}

// 屏蔽作者声明及风险提示
- (id)riskInfoModel {
	BOOL DYYYHideAntiAddictedNotice = DYYYGetBool(@"DYYYHideAntiAddictedNotice");
	if (DYYYHideAntiAddictedNotice) {
		return nil;
	}
	return %orig;
}

- (void)setRiskInfoModel:(id)model {
	BOOL DYYYHideAntiAddictedNotice = DYYYGetBool(@"DYYYHideAntiAddictedNotice");
	if (DYYYHideAntiAddictedNotice) {
		%orig(nil);
		return;
	}
	%orig;
}

%end



//以下部分为新增
// 屏蔽头像直播
%hook AWEUserModel

- (NSNumber *)roomID {
	BOOL DYYYHideAvatarLive = DYYYGetBool(@"DYYYHideAvatarLive");
	if (DYYYHideAvatarLive) {
		return @(0);
	}
	return %orig;
}

%end


// 屏蔽头像光圈
%hook AWEUserModel

- (id)storyRing {
	BOOL DYYYHideAvatarRing = DYYYGetBool(@"DYYYHideAvatarRing");
	if (DYYYHideAvatarRing) {
		return nil;
	}
	return %orig;
}

- (void)setStoryRing:(id)ring {
	BOOL DYYYHideAvatarRing = DYYYGetBool(@"DYYYHideAvatarRing");
	if (DYYYHideAvatarRing) {
		%orig(nil);
		return;
	}
	%orig;
}

%end

%hook AWECodeGenStoryRingInfoModel

- (NSArray *)storyRingsModelArray {
	BOOL DYYYHideAvatarRing = DYYYGetBool(@"DYYYHideAvatarRing");
	if (DYYYHideAvatarRing) {
		return @[];
	}
	return %orig;
}

- (void)setStoryRingsModelArray:(NSArray *)array {
	BOOL DYYYHideAvatarRing = DYYYGetBool(@"DYYYHideAvatarRing");
	if (DYYYHideAvatarRing) {
		%orig(@[]);
		return;
	}
	%orig;
}

%end

// 屏蔽挑战贴纸
%hook AWEInteractionHashtagStickerModel

- (id)hashtagInfo {
	BOOL DYYYHideChallengeStickers = DYYYGetBool(@"DYYYHideChallengeStickers");
	if (DYYYHideChallengeStickers) {
		return nil;
	}
	return %orig;
}

- (void)setHashtagInfo:(id)info {
	BOOL DYYYHideChallengeStickers = DYYYGetBool(@"DYYYHideChallengeStickers");
	if (DYYYHideChallengeStickers) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)hashtagId {
	BOOL DYYYHideChallengeStickers = DYYYGetBool(@"DYYYHideChallengeStickers");
	if (DYYYHideChallengeStickers) {
		return nil;
	}
	return %orig;
}

- (id)hashtagName {
	BOOL DYYYHideChallengeStickers = DYYYGetBool(@"DYYYHideChallengeStickers");
	if (DYYYHideChallengeStickers) {
		return nil;
	}
	return %orig;
}

%end

// 屏蔽互动贴纸
%hook AWEInteractionEditTagStickerModel

- (id)editTagInfo {
	if (DYYYGetBool(@"DYYYHideEditTag")) {
		return nil;
	}
	return %orig;
}

- (void)setEditTagInfo:(id)info {
	if (DYYYGetBool(@"DYYYHideEditTag")) {
		%orig(nil);
		return;
	}
	%orig;
}

%end


// 隐藏下面底部热点框
%hook AWEHotSpotListModel

- (BOOL)disableDisplay {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return YES;
	}
	return %orig;
}

- (BOOL)disableDisplayInner {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return YES;
	}
	return %orig;
}

- (NSString *)hotSpotTipTitleHeader {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)hotSpotTipTitle {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)hotSpotTipTitleFooter {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)hotInfoWord {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)i18NTipTitle {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)tipSchema {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return nil;
	}
	return %orig;
}

- (NSDictionary *)extraDictionary {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @{};
	}
	return %orig;
}

- (NSDictionary *)relativityExtra {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @{};
	}
	return %orig;
}

%end

// 屏蔽精选标签
%hook AWETemplateStaticLabelInfoModel

- (NSArray *)containers {
	if (DYYYGetBool(@"DYYYHideTemplateLabel")) {
		return @[];
	}
	return %orig;
}

- (void)setContainers:(NSArray *)containers {
	if (DYYYGetBool(@"DYYYHideTemplateLabel")) {
		%orig(@[]);
		return;
	}
	%orig;
}

%end

// 隐藏好友推荐
%hook AFDFriendRecommendTagView

- (void)layoutSubviews {
	if (DYYYGetBool(@"DYYYHideFriendRecommend")) {
		self.hidden = YES;
		return;
	}
	%orig;
}

%end

// 屏蔽汽水音乐锚点 - hook AWERelatedMusicAnchorModel
%hook AWERelatedMusicAnchorModel

- (instancetype)init {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		return nil;
	}
	return %orig;
}

- (instancetype)initWithDictionary:(id)dict error:(NSError **)error {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		return nil;
	}
	return %orig;
}

%end

// 屏蔽汽水音乐 - 清空 commentTopBarInfo
%hook AWEMusicExtraModel

- (id)commentTopBarInfo {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		return nil;
	}
	return %orig;
}

- (void)setCommentTopBarInfo:(id)info {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		%orig(nil);
		return;
	}
	%orig;
}

%end


// 拦截开屏广告 - hook TTAdSplashModel，直接返回 nil
%hook TTAdSplashModel

+ (id)alloc {
	if (DYYYGetBool(@"DYYYNoAds")) {
		return nil;  // 直接返回 nil，阻止对象创建
	}
	return %orig;
}

%end

%hook AWEOriginalAdModel
- (instancetype)init {
	BOOL noAds = DYYYGetBool(@"DYYYNoAds");
	if (noAds) {
		return nil;  // 阻止创建，直接返回 nil
	}
	return %orig;
}

- (instancetype)initWithDictionary:(id)dict error:(NSError **)error {
	BOOL noAds = DYYYGetBool(@"DYYYNoAds");
	if (noAds) {
		return nil;  // 阻止创建，直接返回 nil
	}
	return %orig;
}
%end

// 屏蔽 AWEGeneralSearchModel 中的广告卡（强判定）
%hook AWEGeneralSearchModel
- (instancetype)initWithDictionary:(id)dict error:(NSError **)error {
	id orig = %orig;
	
	BOOL noAds = DYYYGetBool(@"DYYYNoAds");
	if (!noAds || !orig) {
		return orig;
	}
	
	// 强判定：检查是否为广告卡（检查 commonDynamicPatchModel.is_ad == 1）
	if ([[orig valueForKeyPath:@"commonDynamicPatchModel.is_ad"] integerValue] == 1) {
		return nil;
	}
	
	return orig;
}
%end

// 去除启动视频广告
%hook AWEAwesomeSplashFeedCellOldAccessoryView

// 在方法入口处添加控制逻辑
- (id)ddExtraView {
	if (DYYYGetBool(@"DYYYNoAds")) {
		return NULL; // 返回空视图
	}

	// 正常模式调用原始方法
	return %orig;
}

%end

// 屏蔽青少年模式弹窗
%hook AWETeenModeAlertView
- (BOOL)show {
	if (DYYYGetBool(@"DYYYHideTeenMode")) {
		return NO;
	}
	return %orig;
}
%end

// 屏蔽青少年模式弹窗
%hook AWETeenModeSimpleAlertView
- (BOOL)show {
	if (DYYYGetBool(@"DYYYHideTeenMode")) {
		return NO;
	}
	return %orig;
}
%end













%hook AWEFeedCommentConfigModel
- (void)setCommentInputConfigText:(NSString *)text {
    NSString *customText = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentContent"];
    if (customText && customText.length > 0) {
        text = customText;
    }
    %orig(text);
}
%end

%hook AWEAwemeStatusModel
- (void)setListenVideoStatus:(NSInteger)status {
    if (status == 1 && DYYYGetBool(@"DYYYEnableBackgroundListen")) {
        status = 2;
    }
    %orig(status);
}
%end

%hook MTKView

- (void)layoutSubviews {
    %orig;
    UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
    Class playVCClass = NSClassFromString(@"AWEPlayVideoViewController");
    if (vc && playVCClass && [vc isKindOfClass:playVCClass]) {
        NSString *colorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYVideoBGColor"];
        if (colorHex && colorHex.length > 0) {
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            UIColor *customColor = [DYYYUtils colorFromSchemeHexString:colorHex targetWidth:screenWidth];
            if (customColor)
                self.backgroundColor = customColor;
        }
    }
}

%end

%hook AWEPlayInteractionUserAvatarView
- (void)layoutSubviews {
    %orig;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFollowPromptView"]) {
        return;
    }

    static char kDYAvatarCacheKey;
    NSArray *viewCache = objc_getAssociatedObject(self, &kDYAvatarCacheKey);
    if (!viewCache) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview isMemberOfClass:[UIView class]]) {
                [tmp addObject:subview];
            }
        }
        viewCache = [tmp copy];
        objc_setAssociatedObject(self, &kDYAvatarCacheKey, viewCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *container in viewCache) {
        for (UIView *child in container.subviews) {
            child.alpha = 0.0;
        }
    }
}
%end

%hook AWEPlayInteractionViewController

- (void)onPlayer:(id)arg0 didDoubleClick:(id)arg1 {
    BOOL isPopupEnabled = DYYYGetBool(@"DYYYEnableDoubleTapMenu");
    BOOL isDirectCommentEnabled = DYYYGetBool(@"DYYYEnableDoubleOpenComment");

    // 直接打开评论区的情况
    if (isDirectCommentEnabled) {
        [self performCommentAction];
        return;
    }

    if (isPopupEnabled) {
        AWEAwemeModel *awemeModel = nil;

        awemeModel = [self performSelector:@selector(awemeModel)];

        AWEVideoModel *videoModel = awemeModel.video;
        AWEMusicModel *musicModel = awemeModel.music;
        NSURL *audioURL = nil;
        if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
            audioURL = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
        }

        // 确定内容类型（视频或图片）
        BOOL isImageContent = (awemeModel.awemeType == 68);
        // 判断是否为新版实况照片
        BOOL isNewLivePhoto = (awemeModel.video && awemeModel.animatedImageVideoInfo != nil);
        NSString *downloadTitle;

        if (isImageContent) {
            AWEImageAlbumImageModel *currentImageModel = nil;
            if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
            } else {
                currentImageModel = awemeModel.albumImages.firstObject;
            }

            if (awemeModel.albumImages.count > 1) {
                downloadTitle = (currentImageModel.clipVideo != nil || awemeModel.isLivePhoto) ? @"保存当前实况" : @"保存当前图片";
            } else {
                downloadTitle = (currentImageModel.clipVideo != nil || awemeModel.isLivePhoto) ? @"保存实况" : @"保存图片";
            }
        } else if (isNewLivePhoto) {
            downloadTitle = @"保存实况";
        } else {
            downloadTitle = @"保存视频";
        }

        AWEUserActionSheetView *actionSheet = [[NSClassFromString(@"AWEUserActionSheetView") alloc] init];
        NSMutableArray *actions = [NSMutableArray array];

        // 添加下载选项
        if (DYYYGetBool(@"DYYYDoubleTapDownload") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapDownload"]) {

            AWEUserSheetAction *downloadAction = [NSClassFromString(@"AWEUserSheetAction")
                actionWithTitle:downloadTitle
                        imgName:nil
                        handler:^{
                          if (isImageContent) {
                              // 图片内容
                              AWEImageAlbumImageModel *currentImageModel = nil;
                              if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                                  currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
                              } else {
                                  currentImageModel = awemeModel.albumImages.firstObject;
                              }

                              // 查找非.image后缀的URL
                              NSURL *downloadURL = nil;
                              for (NSString *urlString in currentImageModel.urlList) {
                                  NSURL *url = [NSURL URLWithString:urlString];
                                  NSString *pathExtension = [url.path.lowercaseString pathExtension];
                                  if (![pathExtension isEqualToString:@"image"]) {
                                      downloadURL = url;
                                      break;
                                  }
                              }

                              if (currentImageModel.clipVideo != nil) {
                                  NSURL *videoURL = [currentImageModel.clipVideo.playURL getDYYYSrcURLDownload];
                                  [DYYYManager downloadLivePhoto:downloadURL
                                                        videoURL:videoURL
                                                      completion:^{
                                                      }];
                              } else if (currentImageModel && currentImageModel.urlList.count > 0) {
                                  if (downloadURL) {
                                      [DYYYManager downloadMedia:downloadURL
                                                       mediaType:MediaTypeImage
                                                           audio:nil
                                                      completion:^(BOOL success) {
                                                        if (success) {
                                                        } else {
                                                            [DYYYUtils showToast:@"图片保存已取消"];
                                                        }
                                                      }];
                                  } else {
                                      [DYYYUtils showToast:@"没有找到合适格式的图片"];
                                  }
                              }
                          } else if (isNewLivePhoto) {
                              // 新版实况照片
                              // 使用封面URL作为图片URL
                              NSURL *imageURL = nil;
                              if (videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
                                  imageURL = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
                              }

                              // 视频URL从视频模型获取
                              NSURL *videoURL = nil;
                              if (videoModel && videoModel.playURL && videoModel.playURL.originURLList.count > 0) {
                                  videoURL = [NSURL URLWithString:videoModel.playURL.originURLList.firstObject];
                              } else if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
                                  videoURL = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
                              }

                              // 下载实况照片
                              if (imageURL && videoURL) {
                                  [DYYYManager downloadLivePhoto:imageURL
                                                        videoURL:videoURL
                                                      completion:^{
                                                      }];
                              }
                          } else {
                              if (videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
                                  NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
                                  [DYYYManager downloadMedia:url
                                                   mediaType:MediaTypeVideo
                                                       audio:audioURL
                                                  completion:^(BOOL success){
                                                  }];
                              }
                          }
                        }];
            [actions addObject:downloadAction];

            // 如果是图集，添加下载所有图片选项
            if (isImageContent && awemeModel.albumImages.count > 1) {
                // 检查是否有实况照片
                BOOL hasLivePhoto = NO;
                for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                    if (imageModel.clipVideo != nil) {
                        hasLivePhoto = YES;
                        break;
                    }
                }

                NSString *actionTitle = hasLivePhoto ? @"保存所有实况" : @"保存所有图片";

                AWEUserSheetAction *downloadAllAction = [NSClassFromString(@"AWEUserSheetAction")
                    actionWithTitle:actionTitle
                            imgName:nil
                            handler:^{
                              NSMutableArray *imageURLs = [NSMutableArray array];
                              NSMutableArray *livePhotos = [NSMutableArray array];

                              for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                                  if (imageModel.urlList.count > 0) {
                                      // 查找非.image后缀的URL
                                      NSURL *downloadURL = nil;
                                      for (NSString *urlString in imageModel.urlList) {
                                          NSURL *url = [NSURL URLWithString:urlString];
                                          NSString *pathExtension = [url.path.lowercaseString pathExtension];
                                          if (![pathExtension isEqualToString:@"image"]) {
                                              downloadURL = url;
                                              break;
                                          }
                                      }

                                      if (!downloadURL && imageModel.urlList.count > 0) {
                                          downloadURL = [NSURL URLWithString:imageModel.urlList.firstObject];
                                      }

                                      // 检查是否是实况照片
                                      if (imageModel.clipVideo != nil) {
                                          NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                                          [livePhotos addObject:@{@"imageURL" : downloadURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
                                      } else {
                                          [imageURLs addObject:downloadURL.absoluteString];
                                      }
                                  }
                              }

                              // 分别处理普通图片和实况照片
                              if (livePhotos.count > 0) {
                                  [DYYYManager downloadAllLivePhotos:livePhotos];
                              }

                              if (imageURLs.count > 0) {
                                  [DYYYManager downloadAllImages:imageURLs];
                              }

                              if (livePhotos.count == 0 && imageURLs.count == 0) {
                                  [DYYYUtils showToast:@"没有找到合适格式的图片"];
                              }
                            }];
                [actions addObject:downloadAllAction];
            }
        }

        // 添加下载音频选项
        if (DYYYGetBool(@"DYYYDoubleTapDownloadAudio") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapDownloadAudio"]) {

            AWEUserSheetAction *downloadAudioAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"保存音频"
                                                                                                        imgName:nil
                                                                                                        handler:^{
                                                                                                          if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
                                                                                                              NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
                                                                                                              [DYYYManager downloadMedia:url mediaType:MediaTypeAudio audio:nil completion:nil];
                                                                                                          }
                                                                                                        }];
            [actions addObject:downloadAudioAction];
        }

        // 添加接口保存选项
        if (DYYYGetBool(@"DYYYDoubleInterfaceDownload")) {
            NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
            if (apiKey.length > 0) {
                AWEUserSheetAction *apiDownloadAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"接口保存"
                                                                                                          imgName:nil
                                                                                                          handler:^{
                                                                                                            NSString *shareLink = [awemeModel valueForKey:@"shareURL"];
                                                                                                            if (shareLink.length == 0) {
                                                                                                                [DYYYUtils showToast:@"无法获取分享链接"];
                                                                                                                return;
                                                                                                            }

                                                                                                            // 使用封装的方法进行解析下载
                                                                                                            [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];
                                                                                                          }];
                [actions addObject:apiDownloadAction];
            }
        }

        // 添加制作视频功能
        if (DYYYGetBool(@"DYYYDoubleCreateVideo") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleCreateVideo"]) {
            if (isImageContent) {
                AWEUserSheetAction *createVideoAction = [NSClassFromString(@"AWEUserSheetAction")
                    actionWithTitle:@"制作视频"
                            imgName:nil
                            handler:^{
                              // 收集普通图片URL
                              NSMutableArray *imageURLs = [NSMutableArray array];
                              // 收集实况照片信息（图片URL+视频URL）
                              NSMutableArray *livePhotos = [NSMutableArray array];

                              // 获取背景音乐URL
                              NSString *bgmURL = nil;
                              if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
                                  bgmURL = musicModel.playURL.originURLList.firstObject;
                              }

                              // 处理所有图片和实况
                              for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                                  if (imageModel.urlList.count > 0) {
                                      // 查找非.image后缀的URL
                                      NSString *bestURL = nil;
                                      for (NSString *urlString in imageModel.urlList) {
                                          NSURL *url = [NSURL URLWithString:urlString];
                                          NSString *pathExtension = [url.path.lowercaseString pathExtension];
                                          if (![pathExtension isEqualToString:@"image"]) {
                                              bestURL = urlString;
                                              break;
                                          }
                                      }

                                      if (!bestURL && imageModel.urlList.count > 0) {
                                          bestURL = imageModel.urlList.firstObject;
                                      }

                                      // 如果是实况照片，需要收集图片和视频URL
                                      if (imageModel.clipVideo != nil) {
                                          NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                                          if (videoURL) {
                                              [livePhotos addObject:@{@"imageURL" : bestURL, @"videoURL" : videoURL.absoluteString}];
                                          }
                                      } else {
                                          // 普通图片
                                          [imageURLs addObject:bestURL];
                                      }
                                  }
                              }

                              // 调用视频创建API
                              [DYYYManager createVideoFromMedia:imageURLs
                                  livePhotos:livePhotos
                                  bgmURL:bgmURL
                                  progress:^(NSInteger current, NSInteger total, NSString *status) {
                                  }
                                  completion:^(BOOL success, NSString *message) {
                                    if (success) {
                                    } else {
                                        [DYYYUtils showToast:[NSString stringWithFormat:@"视频制作失败: %@", message]];
                                    }
                                  }];
                            }];
                [actions addObject:createVideoAction];
            }
        }

        // 添加复制文案选项
        if (DYYYGetBool(@"DYYYDoubleTapCopyDesc") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapCopyDesc"]) {

            AWEUserSheetAction *copyTextAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"复制文案"
                                                                                                   imgName:nil
                                                                                                   handler:^{
                                                                                                     NSString *descText = [awemeModel valueForKey:@"descriptionString"];
                                                                                                     [[UIPasteboard generalPasteboard] setString:descText];
                                                                                                     [DYYYToast showSuccessToastWithMessage:@"文案已复制"];
                                                                                                   }];
            [actions addObject:copyTextAction];
        }

        // 添加打开评论区选项
        if (DYYYGetBool(@"DYYYDoubleTapComment") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapComment"]) {

            AWEUserSheetAction *openCommentAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"打开评论"
                                                                                                      imgName:nil
                                                                                                      handler:^{
                                                                                                        [self performCommentAction];
                                                                                                      }];
            [actions addObject:openCommentAction];
        }

        // 添加分享选项
        if (DYYYGetBool(@"DYYYDoubleTapshowSharePanel") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapshowSharePanel"]) {

            AWEUserSheetAction *showSharePanel = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"分享视频"
                                                                                                   imgName:nil
                                                                                                   handler:^{
                                                                                                     [self showSharePanel];
                                                                                                   }];
            [actions addObject:showSharePanel];
        }

        // 添加点赞视频选项
        if (DYYYGetBool(@"DYYYDoubleTapLike") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapLike"]) {

            AWEUserSheetAction *likeAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"点赞视频"
                                                                                               imgName:nil
                                                                                               handler:^{
                                                                                                 [self performLikeAction];
                                                                                               }];
            [actions addObject:likeAction];
        }

        // 添加长按面板
        if (DYYYGetBool(@"DYYYDoubleTapshowDislikeOnVideo") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapshowDislikeOnVideo"]) {

            AWEUserSheetAction *showDislikeOnVideo = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"长按面板"
                                                                                                       imgName:nil
                                                                                                       handler:^{
                                                                                                         [self showDislikeOnVideo];
                                                                                                       }];
            [actions addObject:showDislikeOnVideo];
        }

        // 显示操作表
        [actionSheet setActions:actions];
        [actionSheet show];

        return;
    }

    // 默认行为
    %orig;
}

%end

%hook AFDPrivacyHalfScreenViewController

%new
- (void)updateDarkModeAppearance {
    BOOL isDarkMode = [DYYYUtils isDarkMode];

    UIView *contentView = self.view.subviews.count > 1 ? self.view.subviews[1] : nil;
    if (contentView) {
        if (isDarkMode) {
            contentView.backgroundColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
        } else {
            contentView.backgroundColor = [UIColor whiteColor];
        }
    }

    // 修改标题文本颜色
    if (self.titleLabel) {
        if (isDarkMode) {
            self.titleLabel.textColor = [UIColor whiteColor];
        } else {
            self.titleLabel.textColor = [UIColor blackColor];
        }
    }

    // 修改内容文本颜色
    if (self.contentLabel) {
        if (isDarkMode) {
            self.contentLabel.textColor = [UIColor lightGrayColor];
        } else {
            self.contentLabel.textColor = [UIColor darkGrayColor];
        }
    }

    // 修改左侧按钮颜色和文字颜色
    if (self.leftCancelButton) {
        if (isDarkMode) {
            [self.leftCancelButton setBackgroundColor:[UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0]]; // 暗色模式按钮背景色
            [self.leftCancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];          // 暗色模式文字颜色
        } else {
            [self.leftCancelButton setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]]; // 默认按钮背景色
            [self.leftCancelButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];        // 默认文字颜色
        }
    }
}

- (void)viewDidLoad {
    %orig;
    [self updateDarkModeAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [self updateDarkModeAppearance];
}

- (void)configWithImageView:(UIImageView *)imageView
                  lockImage:(UIImage *)lockImage
           defaultLockState:(BOOL)defaultLockState
             titleLabelText:(NSString *)titleText
           contentLabelText:(NSString *)contentText
       leftCancelButtonText:(NSString *)leftButtonText
     rightConfirmButtonText:(NSString *)rightButtonText
       rightBtnClickedBlock:(void (^)(void))rightBtnBlock
     leftButtonClickedBlock:(void (^)(void))leftBtnBlock {

    %orig;
    [self updateDarkModeAppearance];
}

%end

%hook UITextField

- (void)willMoveToWindow:(UIWindow *)newWindow {
    %orig;

    if (newWindow) {
        BOOL isDarkMode = [DYYYUtils isDarkMode];
        self.keyboardAppearance = isDarkMode ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    }
}

- (BOOL)becomeFirstResponder {
    BOOL isDarkMode = [DYYYUtils isDarkMode];
    self.keyboardAppearance = isDarkMode ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    return %orig;
}

%end

%hook UITextView

- (void)willMoveToWindow:(UIWindow *)newWindow {
    %orig;

    if (newWindow) {
        BOOL isDarkMode = [DYYYUtils isDarkMode];
        self.keyboardAppearance = isDarkMode ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    }
}

- (BOOL)becomeFirstResponder {
    BOOL isDarkMode = [DYYYUtils isDarkMode];
    self.keyboardAppearance = isDarkMode ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    return %orig;
}

%end

// 底栏高度
%hook AWENormalModeTabBar

static Class barBackgroundClass = nil;
static Class generalButtonClass = nil;
static Class plusButtonClass = nil;
static Class tabBarButtonClass = nil;

+ (void)initialize {
    if (self == [%c(AWENormalModeTabBar) class]) {
        barBackgroundClass = NSClassFromString(@"_UIBarBackground");
        generalButtonClass = %c(AWENormalModeTabBarGeneralButton);
        plusButtonClass = %c(AWENormalModeTabBarGeneralPlusButton);
        tabBarButtonClass = %c(UITabBarButton);
    }
}

%new
- (void)initializeOriginalTabBarHeight {
    if (originalTabBarHeight != kInvalidHeight) {
        if (gCurrentTabBarHeight == kInvalidHeight) {
            gCurrentTabBarHeight = originalTabBarHeight;
        }
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: Skipped! originalTabBarHeight already initialized as %.1f.", originalTabBarHeight);
        return;
    }

    UIWindow *targetWindow = self.window ?: [DYYYUtils getActiveWindow];
    if (self.frame.size.height >= 30) {
        originalTabBarHeight = self.frame.size.height;
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: Success! originalTabBarHeight set to %.1f (from self.frame.size.height)", originalTabBarHeight);
    } else if (targetWindow) {
        CGFloat bottomInset = targetWindow.safeAreaInsets.bottom;
        originalTabBarHeight = 49 + bottomInset;
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: Success! originalTabBarHeight set to %.1f (fallback calculation: 49.0 + %.1f)", originalTabBarHeight, bottomInset);
    } else {
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: Failed! No window available.");
    }
    if (originalTabBarHeight != kInvalidHeight) {
        gCurrentTabBarHeight = originalTabBarHeight;
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: gCurrentTabBarHeight synced to %.1f.", gCurrentTabBarHeight);
    }
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [self initializeOriginalTabBarHeight];
    }
}

- (void)layoutSubviews {
    %orig;

    if (originalTabBarHeight == kInvalidHeight) {
        NSLog(@"[DYYY] layoutSubviews: Fallback! originalTabBarHeight initialization triggered.");
        [self initializeOriginalTabBarHeight];
    }

    if (gCurrentTabBarHeight == kInvalidHeight) {
        gCurrentTabBarHeight = originalTabBarHeight;
        NSLog(@"[DYYY] layoutSubviews: gCurrentTabBarHeight fallback synced to %.1f.", gCurrentTabBarHeight);
    }

    BOOL hideShop = DYYYGetBool(@"DYYYHideShopButton");
    BOOL hideMsg = DYYYGetBool(@"DYYYHideMessageButton");
    BOOL hideFri = DYYYGetBool(@"DYYYHideFriendsButton");
    BOOL hideMe = DYYYGetBool(@"DYYYHideMyButton");
    BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

    NSMutableArray *visibleButtons = [NSMutableArray array];
    UIView *ipadContainerView = nil;

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:generalButtonClass] || [subview isKindOfClass:plusButtonClass]) {
            NSString *label = subview.accessibilityLabel;
            BOOL shouldHide = ([label containsString:@"商城"] && hideShop) || ([label containsString:@"消息"] && hideMsg) || ([label containsString:@"朋友"] && hideFri) ||
                              ([label isEqualToString:@"我"] && hideMe);

            subview.userInteractionEnabled = !shouldHide;
            subview.hidden = shouldHide;

            if (!shouldHide) {
                [visibleButtons addObject:subview];
            }
        } else if ([subview isKindOfClass:tabBarButtonClass]) {
            subview.userInteractionEnabled = NO;
            subview.hidden = YES;
        } else if (isPad && !ipadContainerView && [subview isMemberOfClass:UIView.class] && fabs(subview.frame.size.width - self.bounds.size.width) > 0.1) {
            ipadContainerView = subview;
        }
    }

    [visibleButtons sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
      return [@(a.frame.origin.x) compare:@(b.frame.origin.x)];
    }];

    CGFloat offsetX, totalWidth;
    if (ipadContainerView) {
        offsetX = ipadContainerView.frame.origin.x;
        totalWidth = ipadContainerView.bounds.size.width;
    } else {
        offsetX = 0;
        totalWidth = self.bounds.size.width;
    }
    CGFloat buttonWidth = (visibleButtons.count > 0) ? (totalWidth / visibleButtons.count) : 0;

    // 均匀布局按钮
    for (NSInteger i = 0; i < visibleButtons.count; i++) {
        UIView *button = visibleButtons[i];
        button.frame = CGRectMake(offsetX + i * buttonWidth, button.frame.origin.y, buttonWidth, button.frame.size.height);
    }

    // 禁用首页刷新功能
    if (DYYYGetBool(@"DYYYDisableHomeRefresh")) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:generalButtonClass]) {
                AWENormalModeTabBarGeneralButton *button = (AWENormalModeTabBarGeneralButton *)subview;
                if ([button.accessibilityLabel isEqualToString:@"首页"]) {
                    // status == 2 表示选中状态
                    button.userInteractionEnabled = (button.status != 2);
                }
            }
        }
    }

    // 背景和分隔线处理
    BOOL hideBottomBg = DYYYGetBool(@"DYYYHideBottomBg");
    BOOL enableFullScreen = DYYYGetBool(@"DYYYEnableFullScreen");

    if (hideBottomBg || enableFullScreen) {
        if (self.skinContainerView) {
            self.skinContainerView.hidden = YES;
        }

        BOOL isHomeSelected = NO;
        BOOL isFriendsSelected = NO;

        if (enableFullScreen && !hideBottomBg) {
            for (UIView *subview in self.subviews) {
                if ([subview isKindOfClass:generalButtonClass]) {
                    AWENormalModeTabBarGeneralButton *button = (AWENormalModeTabBarGeneralButton *)subview;
                    if (button.status == 2) {
                        if ([button.accessibilityLabel isEqualToString:@"首页"])
                            isHomeSelected = YES;
                        else if ([button.accessibilityLabel containsString:@"朋友"])
                            isFriendsSelected = YES;
                    }
                }
            }
        }

        BOOL hideFriendsButton = DYYYGetBool(@"DYYYHideFriendsButton");
        BOOL shouldHideBackgrounds = hideBottomBg || (enableFullScreen && (isHomeSelected || (isFriendsSelected && !hideFriendsButton)));

        // 单次遍历处理所有背景和分割线
        for (UIView *subview in self.subviews) {
            // 跳过底栏按钮
            if ([subview isKindOfClass:generalButtonClass] || [subview isKindOfClass:plusButtonClass]) {
                continue;
            }
            // 隐藏底栏背景
            if ([subview isKindOfClass:barBackgroundClass] || ([subview isMemberOfClass:[UIView class]] && originalTabBarHeight > 0 && fabs(subview.frame.size.height - gCurrentTabBarHeight) < 0.1)) {
                subview.hidden = shouldHideBackgrounds;
            }
            // 隐藏细分割线
            if (subview.frame.size.height > 0 && subview.frame.size.height < 1 && subview.frame.size.width > 300) {
                subview.hidden = enableFullScreen;
            }
        }
    } else {
        if (self.skinContainerView) {
            self.skinContainerView.hidden = NO;
        }

        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:barBackgroundClass] || [subview isMemberOfClass:[UIView class]]) {
                subview.hidden = NO;
            }
        }
    }
}

- (void)setHidden:(BOOL)hidden {
    %orig(hidden);

    BOOL disableHomeRefresh = DYYYGetBool(@"DYYYDisableHomeRefresh");
    BOOL enableFullScreen = DYYYGetBool(@"DYYYEnableFullScreen");
    BOOL hideBottomBg = DYYYGetBool(@"DYYYHideBottomBg");
    BOOL hideFriendsButton = DYYYGetBool(@"DYYYHideFriendsButton");

    BOOL isHomeSelected = NO;
    BOOL isFriendsSelected = NO;

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:generalButtonClass]) {
            AWENormalModeTabBarGeneralButton *button = (AWENormalModeTabBarGeneralButton *)subview;

            // 禁用首页刷新功能
            if (disableHomeRefresh && [button.accessibilityLabel isEqualToString:@"首页"]) {
                button.userInteractionEnabled = (button.status != 2);
            }

            // 检查当前选中的页
            if (enableFullScreen && button.status == 2) {
                if ([button.accessibilityLabel isEqualToString:@"首页"]) {
                    isHomeSelected = YES;
                } else if ([button.accessibilityLabel containsString:@"朋友"]) {
                    isFriendsSelected = YES;
                }
            }
        }
    }

    if (hideBottomBg || enableFullScreen) {
        if (self.skinContainerView) {
            self.skinContainerView.hidden = YES;
        }

        BOOL shouldHideBackgrounds = NO;
        if (hideBottomBg) {
            shouldHideBackgrounds = YES;
        } else if (enableFullScreen) {
            shouldHideBackgrounds = isHomeSelected || (isFriendsSelected && !hideFriendsButton);
        }

        // 处理所有背景和分割线
        for (UIView *subview in self.subviews) {
            CGFloat subviewHeight = subview.frame.size.height;
            // 跳过底栏按钮
            if ([subview isKindOfClass:generalButtonClass] || [subview isKindOfClass:plusButtonClass]) {
                continue;
            }
            // 隐藏底栏背景
            if ([subview isKindOfClass:barBackgroundClass] || ([subview isMemberOfClass:[UIView class]] && originalTabBarHeight > 0 && fabs(subviewHeight - gCurrentTabBarHeight) < 0.1)) {
                subview.hidden = shouldHideBackgrounds;
            }
            // 隐藏细分割线
            if (subviewHeight > 0 && subviewHeight < 1 && subview.frame.size.width > 300) {
                subview.hidden = enableFullScreen;
            }
        }
    } else {
        if (self.skinContainerView) {
            self.skinContainerView.hidden = NO;
        }
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:barBackgroundClass] || [subview isMemberOfClass:[UIView class]]) {
                subview.hidden = NO;
            }
        }
    }
}

%end

// 精简平板底栏
%hook AWETabBarElementContainerView

- (void)setHidden:(BOOL)hidden {
    if (DYYYGetBool(@"DYYYHidePadTabBarElements")) {
        %orig(YES);
        return;
    }

    %orig(hidden);
}

%end

%hook AWENormalModeTabBarBadgeContainerView

- (void)layoutSubviews {
    %orig;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideBottomDot"]) {
        return;
    }

    static char kDYBadgeCacheKey;
    NSArray *badges = objc_getAssociatedObject(self, &kDYBadgeCacheKey);
    if (!badges) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (UIView *subview in [self subviews]) {
            if ([subview isKindOfClass:NSClassFromString(@"DUXBadge")]) {
                [tmp addObject:subview];
            }
        }
        badges = [tmp copy];
        objc_setAssociatedObject(self, &kDYBadgeCacheKey, badges, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *badge in badges) {
        badge.hidden = YES;
    }
}

%end

// 禁用点击首页刷新
%hook AWENormalModeTabBarGeneralButton

- (BOOL)enableRefresh {
    if ([self.accessibilityLabel isEqualToString:@"首页"]) {
        if (DYYYGetBool(@"DYYYDisableHomeRefresh")) {
            return NO;
        }
    }
    return %orig;
}

%end

%hook AWENormalModeTabBarGeneralPlusButton
+ (id)button {
    BOOL isHidePlusButton = DYYYGetBool(@"DYYYHidePlusButton");
    if (isHidePlusButton) {
        return nil;
    }
    return %orig;
}
%end

%hook AWENormalModeTabBarGeneralPlusInnerButton
+ (id)buttonWithParams:(id)arg1 {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        return nil;
    }
    return %orig;
}
%end

%hook AWENormalModeTabBarTextView

- (void)layoutSubviews {
    @try {
        %orig;

        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self layoutSubviews];
            });
            return;
        }

        if (!self || !self.superview) {
            return;
        }

        NSString *indexTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYIndexTitle"];
        NSString *friendsTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFriendsTitle"];
        NSString *msgTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYMsgTitle"];
        NSString *selfTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYSelfTitle"];

        if (!(indexTitle.length || friendsTitle.length || msgTitle.length || selfTitle.length)) {
            return;
        }

        static char kDYTabTextLabelCacheKey;
        NSArray *labelCache = objc_getAssociatedObject(self, &kDYTabTextLabelCacheKey);
        if (!labelCache) {
            NSMutableArray *tmp = [NSMutableArray array];
            if (!tmp) {
                return;
            }

            NSArray *subviews = [self subviews];
            if (!subviews) {
                return;
            }

            for (UIView *subview in subviews) {
                if (subview && [subview isKindOfClass:[UILabel class]]) {
                    [tmp addObject:subview];
                }
            }

            labelCache = [tmp copy];
            if (labelCache) {
                objc_setAssociatedObject(self, &kDYTabTextLabelCacheKey, labelCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }

        if (!labelCache) {
            return;
        }

        for (UILabel *label in labelCache) {
            if (!label || ![label isKindOfClass:[UILabel class]]) {
                continue;
            }

            NSString *labelText = label.text;
            if (!labelText) {
                continue;
            }

            if ([labelText isEqualToString:@"首页"] && indexTitle.length > 0) {
                label.text = indexTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            } else if ([labelText isEqualToString:@"朋友"] && friendsTitle.length > 0) {
                label.text = friendsTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            } else if ([labelText isEqualToString:@"消息"] && msgTitle.length > 0) {
                label.text = msgTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            } else if ([labelText isEqualToString:@"我"] && selfTitle.length > 0) {
                label.text = selfTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            }
        }

    } @catch (NSException *exception) {
        return;
    }
}
%end

%hook AWENormalModeTabBarFeedView

- (void)layoutSubviews {
    @try {
        %orig;
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDoubleColumnEntry"]) {
            return;
        }

        static char kDYDoubleColumnCacheKey;
        static char kDYDoubleColumnCountKey;
        NSArray *cachedViews = objc_getAssociatedObject(self, &kDYDoubleColumnCacheKey);
        NSNumber *cachedCount = objc_getAssociatedObject(self, &kDYDoubleColumnCountKey);
        if (!cachedViews || cachedCount.unsignedIntegerValue != self.subviews.count) {
            NSMutableArray *views = [NSMutableArray array];
            for (UIView *subview in self.subviews) {
                if (![subview isKindOfClass:[UILabel class]]) {
                    [views addObject:subview];
                }
            }
            cachedViews = [views copy];
            objc_setAssociatedObject(self, &kDYDoubleColumnCacheKey, cachedViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, &kDYDoubleColumnCountKey, @(self.subviews.count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        for (UIView *v in cachedViews) {
            v.hidden = YES;
        }

        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self layoutSubviews];
            });
            return;
        }

        if (!self || !self.superview) {
            return;
        }

        NSString *indexTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYIndexTitle"];

        if (!(indexTitle.length)) {
            return;
        }

        static char kDYTabFeedLabelCacheKey;
        NSArray *labelCache = objc_getAssociatedObject(self, &kDYTabFeedLabelCacheKey);
        if (!labelCache) {
            NSMutableArray *tmp = [NSMutableArray array];
            if (!tmp) {
                return;
            }

            NSArray *subviews = [self subviews];
            if (!subviews) {
                return;
            }

            for (UIView *subview in subviews) {
                if (subview && [subview isKindOfClass:[UILabel class]]) {
                    [tmp addObject:subview];
                }
            }

            labelCache = [tmp copy];
            if (labelCache) {
                objc_setAssociatedObject(self, &kDYTabFeedLabelCacheKey, labelCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }

        if (!labelCache) {
            return;
        }

        for (UILabel *label in labelCache) {
            if (!label || ![label isKindOfClass:[UILabel class]]) {
                continue;
            }

            NSString *labelText = label.text;
            if (!labelText) {
                continue;
            }

            if ([labelText isEqualToString:@"首页"] && indexTitle.length > 0) {
                label.text = indexTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            }
        }

    } @catch (NSException *exception) {
        return;
    }
}
%end

%hook AWEConcernCellLastView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen") && gCurrentTabBarHeight > 0) {
        for (UIView *subview in self.subviews) {
            CGRect frame = subview.frame;
            frame.origin.y -= gCurrentTabBarHeight;
            subview.frame = frame;
        }
    }
}
%end

%hook AWECommentInputBackgroundView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideComment")) {
        [self removeFromSuperview];
        return;
    }

    CGAffineTransform newTransform = CGAffineTransformMakeTranslation(0, originalTabBarHeight - gCurrentTabBarHeight);

    if (!CGAffineTransformEqualToTransform(self.transform, newTransform)) {
        self.transform = newTransform;
    }
}
%end

%hook AWECommentContainerViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    dyyyCommentViewVisible = YES;
    updateSpeedButtonVisibility();
    updateClearButtonVisibility();
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTopBarTransparent"];
    if (transparentValue && transparentValue.length > 0) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {

            UIView *parentView = self.view.superview;
            if (parentView) {
                for (UIView *subview in parentView.subviews) {
                    if ([subview.accessibilityLabel isEqualToString:@"搜索"]) {
                        CGFloat finalAlpha = (alphaValue < 0.011) ? 0.011 : alphaValue;
                        subview.alpha = finalAlpha;
                    }
                }
            }
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    dyyyCommentViewVisible = NO;
    updateSpeedButtonVisibility();
    updateClearButtonVisibility();
}

- (void)viewDidLayoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYEnableCommentBlur"))
        return;

    Class containerViewClass = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputContainerView");
    NSArray<UIView *> *containerViews = [DYYYUtils findAllSubviewsOfClass:containerViewClass inContainer:self.view];
    for (UIView *containerView in containerViews) {
        for (UIView *subview in containerView.subviews) {
            if (subview.hidden == NO && subview.backgroundColor && CGColorGetAlpha(subview.backgroundColor.CGColor) == 1) {
                float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
                if (userTransparency <= 0 || userTransparency > 1) {
                    userTransparency = 0.8;
                }
                [DYYYUtils applyBlurEffectToView:subview transparency:userTransparency blurViewTag:999];
            }
        }
    }

    Class middleContainerClass = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputViewMiddleContainer");
    NSArray<UIView *> *middleContainers = [DYYYUtils findAllSubviewsOfClass:middleContainerClass inContainer:self.view];
    for (UIView *middleContainer in middleContainers) {
        BOOL containsDanmu = NO;
        for (UIView *innerSubviewCheck in middleContainer.subviews) {
            if ([innerSubviewCheck isKindOfClass:[UILabel class]] && [((UILabel *)innerSubviewCheck).text containsString:@"弹幕"]) {
                containsDanmu = YES;
                break;
            }
        }

        if (containsDanmu) {
            UIView *parentView = middleContainer.superview;
            for (UIView *innerSubview in parentView.subviews) {
                if ([innerSubview isKindOfClass:[UIView class]]) {
                    if (innerSubview.subviews.count > 0) {
                        innerSubview.subviews[0].hidden = YES;
                    }

                    UIView *whiteBackgroundView = [[UIView alloc] initWithFrame:innerSubview.bounds];
                    whiteBackgroundView.backgroundColor = [UIColor whiteColor];
                    whiteBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    [innerSubview addSubview:whiteBackgroundView];
                    break;
                }
            }
        } else {
            for (UIView *subview in middleContainer.subviews) {
                if (subview.hidden == NO && subview.backgroundColor && CGColorGetAlpha(subview.backgroundColor.CGColor) == 1) {
                    [DYYYUtils applyBlurEffectToView:subview transparency:0.2f blurViewTag:999];
                }
            }
        }
    }
}

%end

// 开启评论区毛玻璃后滚动区域填满底部
%hook AWEListKitMagicCollectionView

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYEnableCommentBlur")) {
        return;
    }

    UICollectionView *collectionView = (UICollectionView *)self;

    UIView *superview = collectionView.superview;
    CGRect targetFrame = superview.bounds;
    if (superview == nil || CGSizeEqualToSize(targetFrame.size, CGSizeZero) || CGRectEqualToRect(collectionView.frame, targetFrame)) {
        return;
    }

    collectionView.frame = targetFrame;

    CGFloat commentOffset = 166.0;

    UIEdgeInsets inset = collectionView.contentInset;
    inset.bottom = commentOffset;
    collectionView.contentInset = inset;
    collectionView.scrollIndicatorInsets = inset;
}

%end

%hook UIView

- (id)initWithFrame:(CGRect)frame {
    UIView *view = %orig;
    if (hideButton && hideButton.isElementsHidden) {
        for (NSString *className in targetClassNames) {
            if ([view isKindOfClass:NSClassFromString(className)]) {
                if ([view isKindOfClass:NSClassFromString(@"AWELeftSideBarEntranceView")]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                      UIViewController *controller = [hideButton findViewController:view];
                      if ([controller isKindOfClass:NSClassFromString(@"AWEFeedContainerViewController")]) {
                          view.alpha = 0.0;
                      }
                    });
                    break;
                }
                view.alpha = 0.0;
                break;
            }
        }
    }
    return view;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setBackgroundColor:backgroundColor];
        });
        return;
    }

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
        if ([vc isKindOfClass:%c(AWEAwemeDetailTableViewController)] ||
            [vc isKindOfClass:%c(AWEAwemeDetailCellViewController)]) {
            %orig([UIColor clearColor]);
            return;
        }
    }

    %orig(backgroundColor);
}

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        if (self.frame.size.height == originalTabBarHeight && originalTabBarHeight > 0) {
            UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
            if ([vc isKindOfClass:NSClassFromString(@"AWEMixVideoPanelDetailTableViewController")] || [vc isKindOfClass:NSClassFromString(@"AWECommentInputViewController")] ||
                [vc isKindOfClass:NSClassFromString(@"AWEAwemeDetailTableViewController")]) {
                self.backgroundColor = [UIColor clearColor];
            }
        }
    }

    if (DYYYGetBool(@"DYYYEnableFullScreen") || DYYYGetBool(@"DYYYEnableCommentBlur")) {
        UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
        if ([vc isKindOfClass:%c(AWEPlayInteractionViewController)]) {
            for (UIView *subview in self.subviews) {
                if ([subview isKindOfClass:[UIView class]] && subview.backgroundColor && CGColorEqualToColor(subview.backgroundColor.CGColor, [UIColor blackColor].CGColor)) {
                    subview.hidden = YES;
                }
            }
        }
    }
}

- (void)setFrame:(CGRect)frame {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setFrame:frame];
        });
        return;
    }

    BOOL enableBlur = DYYYGetBool(@"DYYYEnableCommentBlur");
    BOOL enableFS = DYYYGetBool(@"DYYYEnableFullScreen");

    UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
    Class DetailVCClass = NSClassFromString(@"AWEMixVideoPanelDetailTableViewController");
    Class PlayVCClass1 = NSClassFromString(@"AWEAwemePlayVideoViewController");
    Class PlayVCClass2 = NSClassFromString(@"AWEDPlayerFeedPlayerViewController");
    Class PlayVCClass3 = NSClassFromString(@"AWEDPlayerViewController_Merge");

    BOOL isDetailVC = (DetailVCClass && [vc isKindOfClass:DetailVCClass]);
    BOOL isPlayVC = ((PlayVCClass1 && [vc isKindOfClass:PlayVCClass1]) ||
                     (PlayVCClass2 && [vc isKindOfClass:PlayVCClass2]) ||
                     (PlayVCClass3 && [vc isKindOfClass:PlayVCClass3]));

    if (isPlayVC && enableBlur) {
        if (frame.origin.x != 0) {
            return;
        }
    }

    if (isPlayVC && enableFS) {
        if (frame.origin.x != 0 && frame.origin.y != 0) {
            %orig(frame);
            return;
        }
        CGRect superF = self.superview.frame;
        if (CGRectGetHeight(superF) > 0 && CGRectGetHeight(frame) > 0 && CGRectGetHeight(frame) < CGRectGetHeight(superF)) {
            CGFloat diff = CGRectGetHeight(superF) - CGRectGetHeight(frame);
            if (fabs(diff - gCurrentTabBarHeight) < 1.0) {
                frame.size.height = CGRectGetHeight(superF);
            }
        }

        %orig(frame);
        return;
    }
    %orig(frame);
}

%new
- (void)dyyy_applyGlobalTransparency {
    if ([NSThread isMainThread]) {
        if (self.window && self.tag != DYYY_IGNORE_GLOBAL_ALPHA_TAG) {
            NSNumber *stored = objc_getAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey);
            CGFloat baseAlpha = stored ? stored.floatValue : self.alpha;
            if (!stored) {
                objc_setAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey, @(baseAlpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            CGFloat finalAlpha = baseAlpha;
            if (gGlobalTransparency != kInvalidAlpha) {
                CGFloat clampedAlpha = MIN(MAX(baseAlpha, 0.0), 1.0);
                finalAlpha = clampedAlpha * gGlobalTransparency;
            }
            if (fabs(self.alpha - finalAlpha) >= 0.01) {
                [UIView animateWithDuration:0.2
                                 animations:^{
                                   dyyyGlobalTransparencyMutationDepth++;
                                   self.alpha = finalAlpha;
                                   if (dyyyGlobalTransparencyMutationDepth > 0) {
                                       dyyyGlobalTransparencyMutationDepth--;
                                   }
                                 }];
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self dyyy_applyGlobalTransparency];
        });
    }
}

%end

%hook AWEIMSkylightListView
- (void)setFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYHideAvatarList")) {
        CGFloat scale = [UIScreen mainScreen].scale ?: 2.0;
        CGFloat minH = MAX(1.0 / scale, 0.5);
        frame.size.height = minH;
    }
    %orig(frame);
}
%end

%hook AFDPureModePageTapController

- (void)onVideoPlayerViewDoubleClicked:(id)arg1 {
    BOOL isSwitchOn = DYYYGetBool(@"DYYYDisableDoubleTapLike");
    if (!isSwitchOn) {
        %orig;
    }
}

%end

%hook AWEPlayInteractionViewController

- (void)onVideoPlayerViewDoubleClicked:(id)arg1 {
    BOOL isSwitchOn = DYYYGetBool(@"DYYYDisableDoubleTapLike");
    if (!isSwitchOn) {
        %orig;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isInPlayInteractionVC = YES;
    dyyyInteractionViewVisible = YES;
    updateSpeedButtonVisibility();
    updateClearButtonVisibility();
}

- (void)viewDidLayoutSubviews {
    %orig;

    if (isFloatSpeedButtonEnabled) {
        BOOL hasRightStack = NO;
        Class stackClass = NSClassFromString(@"AWEElementStackView");
        for (UIView *sub in self.view.subviews) {
            if ([sub isKindOfClass:stackClass] && ([sub.accessibilityLabel isEqualToString:@"right"] || [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEPlayInteractionUserAvatarView")
                                                                                                                              inContainer:self.view])) {
                hasRightStack = YES;
                break;
            }
        }
        if (hasRightStack) {
            if (speedButton == nil) {
                speedButtonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYSpeedButtonSize"] ?: 32.0;
                CGRect screenBounds = [UIScreen mainScreen].bounds;
                CGRect initialFrame = CGRectMake((screenBounds.size.width - speedButtonSize) / 2, (screenBounds.size.height - speedButtonSize) / 2, speedButtonSize, speedButtonSize);
                speedButton = [[FloatingSpeedButton alloc] initWithFrame:initialFrame];
                speedButton.interactionController = self;
                showSpeedX = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYSpeedButtonShowX"];
                updateSpeedButtonUI();
            } else {
                [speedButton resetButtonState];
                if (speedButton.interactionController == nil || speedButton.interactionController != self) {
                    speedButton.interactionController = self;
                }
                if (speedButton.frame.size.width != speedButtonSize) {
                    CGPoint center = speedButton.center;
                    CGRect newFrame = CGRectMake(0, 0, speedButtonSize, speedButtonSize);
                    speedButton.frame = newFrame;
                    speedButton.center = center;
                    speedButton.layer.cornerRadius = speedButtonSize / 2;
                }
            }
            dyyyInteractionViewVisible = YES;
            UIWindow *keyWindow = [DYYYUtils getActiveWindow];
            if (keyWindow && ![speedButton isDescendantOfView:keyWindow]) {
                [keyWindow addSubview:speedButton];
                [speedButton loadSavedPosition];
                [speedButton resetFadeTimer];
            }
        }
    }

    UIWindow *keyWindow = [DYYYUtils getActiveWindow];
    if (keyWindow && keyWindow.safeAreaInsets.bottom == 0) {
        return;
    }

    if (!DYYYGetBool(@"DYYYEnableFullScreen")) {
        return;
    }

    UIViewController *directParentVC = self.parentViewController;
    UIViewController *parentVC = directParentVC;
    int maxIterations = 3;
    int count = 0;

    while (parentVC && count < maxIterations) {
        if ([parentVC isKindOfClass:%c(AFDPlayRemoteFeedTableViewController)]) {
            return;
        }
        parentVC = parentVC.parentViewController;
        count++;
    }

    if (!self.view.superview) {
        return;
    }

    CGRect frame = self.view.frame;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat superviewHeight = self.view.superview.frame.size.height;

    if (frame.size.width != screenWidth && frame.size.height < superviewHeight) {
        return;
    }

    NSString *currentReferString = self.referString;

    BOOL useFullHeight = [currentReferString isEqualToString:@"general_search"] || [currentReferString isEqualToString:@"search_result"] || [currentReferString isEqualToString:@"search_ecommerce"] ||
                         [currentReferString isEqualToString:@"close_friends_moment"] || [currentReferString isEqualToString:@"offline_mode"] || [currentReferString isEqualToString:@"challenge"] ||
                         [currentReferString isEqualToString:@"general_search_scan"] || currentReferString == nil;

    if (!useFullHeight && [currentReferString isEqualToString:@"co_play_watch"]) {
        Class richContentVCClass = NSClassFromString(@"AWEFriendsImpl.RichContentNewListViewController");
        if (richContentVCClass && [directParentVC isKindOfClass:richContentVCClass]) {
            useFullHeight = YES;
        }
    }

    if (!useFullHeight && [currentReferString isEqualToString:@"chat"]) {
        static NSNumber *shouldRestoreChat = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
          BOOL includeChat = NO;
          Class managerClass = %c(AWEVersionUpdateManager);
          if (managerClass && [managerClass respondsToSelector:@selector(sharedInstance)]) {
              AWEVersionUpdateManager *manager = [managerClass sharedInstance];
              if ([manager respondsToSelector:@selector(currentVersion)]) {
                  NSString *currentVersion = manager.currentVersion;
                  if (currentVersion.length > 0) {
                      includeChat = ([DYYYUtils compareVersion:currentVersion toVersion:@"35.5.0"] == NSOrderedAscending);
                  }
              }
          }
          shouldRestoreChat = @(includeChat);
        });

        if (shouldRestoreChat.boolValue) {
            useFullHeight = YES;
        }
    }

    if (useFullHeight) {
        frame.size.height = superviewHeight;
    } else {
        frame.size.height = superviewHeight - gCurrentTabBarHeight;
    }

    if (fabs(frame.size.height - self.view.frame.size.height) > 0.5) {
        self.view.frame = frame;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    BOOL hasRightStack = NO;
    Class stackClass = NSClassFromString(@"AWEElementStackView");
    for (UIView *sub in self.view.subviews) {
        if ([sub isKindOfClass:stackClass] && ([sub.accessibilityLabel isEqualToString:@"right"] || [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEPlayInteractionUserAvatarView")
                                                                                                                          inContainer:self.view])) {
            hasRightStack = YES;
            break;
        }
    }
    if (hasRightStack) {
        dyyyInteractionViewVisible = NO;
        dyyyCommentViewVisible = self.isCommentVCShowing;
        updateSpeedButtonVisibility();
        updateClearButtonVisibility();
    }
}

%new
- (void)speedButtonTapped:(UIButton *)sender {
    [(FloatingSpeedButton *)sender resetFadeTimer];
    NSArray *speeds = getSpeedOptions();
    if (speeds.count == 0)
        return;

    NSInteger currentIndex = getCurrentSpeedIndex();
    NSInteger newIndex = (currentIndex + 1) % speeds.count;

    setCurrentSpeedIndex(newIndex);

    float newSpeed = [speeds[newIndex] floatValue];

    NSString *formattedSpeed;
    if (fmodf(newSpeed, 1.0) == 0) {
        formattedSpeed = [NSString stringWithFormat:@"%.0f", newSpeed];
    } else if (fmodf(newSpeed * 10, 1.0) == 0) {
        formattedSpeed = [NSString stringWithFormat:@"%.1f", newSpeed];
    } else {
        formattedSpeed = [NSString stringWithFormat:@"%.2f", newSpeed];
    }

    if (showSpeedX) {
        formattedSpeed = [formattedSpeed stringByAppendingString:@"x"];
    }

    [sender setTitle:formattedSpeed forState:UIControlStateNormal];

    [UIView animateWithDuration:0.1
        delay:0
        options:UIViewAnimationOptionCurveEaseOut
        animations:^{
          sender.transform = CGAffineTransformMakeScale(1.1, 1.1);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.1
                                delay:0
                              options:UIViewAnimationOptionCurveEaseIn
                           animations:^{
                             sender.transform = CGAffineTransformIdentity;
                           }
                           completion:nil];
        }];

    BOOL speedApplied = NO;

    UIWindow *win = [DYYYUtils getActiveWindow];
    UIViewController *rootVC = win.rootViewController;
    while (rootVC && rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }

    NSArray *viewControllers = rootVC ? findViewControllersInHierarchy(rootVC) : @[];

    for (UIViewController *vc in viewControllers) {
        if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            [(AWEAwemePlayVideoViewController *)vc setVideoControllerPlaybackRate:newSpeed];
            speedApplied = YES;
        }
        if ([vc isKindOfClass:%c(AWEDPlayerFeedPlayerViewController)]) {
            [(AWEDPlayerFeedPlayerViewController *)vc setVideoControllerPlaybackRate:newSpeed];
            speedApplied = YES;
        }
        if ([vc isKindOfClass:objc_getClass("AWEDPlayerViewController_Merge")]) {
            [(AWEAwemePlayVideoViewController *)vc setVideoControllerPlaybackRate:newSpeed];
            speedApplied = YES;
        }
    }

    if (!speedApplied) {
        [DYYYUtils showToast:@"无法找到视频控制器"];
    }
}

%new
- (void)buttonTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1
                     animations:^{
                       sender.alpha = 0.7;
                       sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
                     }];
}

%new
- (void)buttonTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.1
                     animations:^{
                       sender.alpha = 1.0;
                       sender.transform = CGAffineTransformIdentity;
                     }];
}

%end

%hook AWEAwemePlayVideoViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
    %orig(arg0);
    if (!DYYYShouldHandleSpeedFeatures()) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
          float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];
          if (defaultSpeed > 0 && defaultSpeed != 1) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [self setVideoControllerPlaybackRate:defaultSpeed];
              });
          }
      }
      float speed = getCurrentSpeed();
      if (speed != 1.0) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self adjustPlaybackSpeed:speed];
          });
      }
    });
}

- (void)prepareForDisplay {
    %orig;
    if (!DYYYShouldHandleSpeedFeatures()) {
        return;
    }

    BOOL autoRestoreSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
    if (autoRestoreSpeed) {
        setCurrentSpeedIndex(0);
    }
    float speed = getCurrentSpeed();
    if (speed != 1.0) {
        [self adjustPlaybackSpeed:speed];
    }
    updateSpeedButtonUI();
}

%new
- (void)adjustPlaybackSpeed:(float)speed {
    [self setVideoControllerPlaybackRate:speed];
}

%end

%hook AWEDPlayerFeedPlayerViewController

- (void)viewDidLayoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        UIView *contentView = self.contentView;
        if (contentView && contentView.superview) {
            CGRect frame = contentView.frame;
            CGFloat parentHeight = contentView.superview.frame.size.height;

            if (frame.size.height == parentHeight - gCurrentTabBarHeight) {
                frame.size.height = parentHeight;
                contentView.frame = frame;
            } else if (frame.size.height == parentHeight - (gCurrentTabBarHeight * 2)) {
                frame.size.height = parentHeight - gCurrentTabBarHeight;
                contentView.frame = frame;
            }
        }
    }
}

- (void)setIsAutoPlay:(BOOL)arg0 {
    %orig(arg0);
    if (!DYYYShouldHandleSpeedFeatures()) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
          float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];
          if (defaultSpeed > 0 && defaultSpeed != 1) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [self setVideoControllerPlaybackRate:defaultSpeed];
              });
          }
      }
      float speed = getCurrentSpeed();
      if (speed != 1.0) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self adjustPlaybackSpeed:speed];
          });
      }
    });
}

- (void)prepareForDisplay {
    %orig;
    if (!DYYYShouldHandleSpeedFeatures()) {
        return;
    }
    BOOL autoRestoreSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
    if (autoRestoreSpeed) {
        setCurrentSpeedIndex(0);
    }
    float speed = getCurrentSpeed();
    if (speed != 1.0) {
        [self adjustPlaybackSpeed:speed];
    }
    updateSpeedButtonUI();
}

%new
- (void)adjustPlaybackSpeed:(float)speed {
    [self setVideoControllerPlaybackRate:speed];
}

%end

%hook AWEDPlayerViewController_Merge

- (void)viewDidLayoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        UIView *contentView = self.contentView;
        if (contentView && contentView.superview) {
            CGRect frame = contentView.frame;
            CGFloat parentHeight = contentView.superview.frame.size.height;

            if (frame.size.height == parentHeight - gCurrentTabBarHeight) {
                frame.size.height = parentHeight;
                contentView.frame = frame;
            } else if (frame.size.height == parentHeight - (gCurrentTabBarHeight * 2)) {
                frame.size.height = parentHeight - gCurrentTabBarHeight;
                contentView.frame = frame;
            }
        }
    }
}

- (void)setIsAutoPlay:(BOOL)arg0 {
    %orig(arg0);
    if (!DYYYShouldHandleSpeedFeatures()) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
          float defaultSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];
          if (defaultSpeed > 0 && defaultSpeed != 1) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [self setVideoControllerPlaybackRate:defaultSpeed];
              });
          }
      }
      float speed = getCurrentSpeed();
      if (speed != 1.0) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self adjustPlaybackSpeed:speed];
          });
      }
    });
}

- (void)prepareForDisplay {
    %orig;
    if (!DYYYShouldHandleSpeedFeatures()) {
        return;
    }
    BOOL autoRestoreSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
    if (autoRestoreSpeed) {
        setCurrentSpeedIndex(0);
    }
    float speed = getCurrentSpeed();
    if (speed != 1.0) {
        [self adjustPlaybackSpeed:speed];
    }
    updateSpeedButtonUI();
}

%new
- (void)adjustPlaybackSpeed:(float)speed {
    [self setVideoControllerPlaybackRate:speed];
}

%end

%hook AWEFeedTableView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGRect frame = self.frame;
        frame.size.height = self.superview.frame.size.height;
        self.frame = frame;
    } else if (gCurrentTabBarHeight > 0) {
        UIWindow *keyWindow = [DYYYUtils getActiveWindow];
        if (keyWindow && keyWindow.safeAreaInsets.bottom == 0) {
            return;
        }

        CGRect frame = self.frame;
        frame.size.height = self.superview.frame.size.height - gCurrentTabBarHeight;
        self.frame = frame;
    }
}
%end

%hook AWEFeedTableViewCell
- (void)prepareForReuse {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)layoutSubviews {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
}
%end

%hook AWEFeedViewCell
- (void)layoutSubviews {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)setModel:(id)model {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}
%end

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      isAppInTransition = NO;
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      isAppInTransition = NO;
    });
}
%end

%hook AFDPureModePageContainerViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    isPureViewVisible = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    isPureViewVisible = NO;
}
%end

%hook AWEFeedContainerViewController
- (void)aweme:(id)arg1 currentIndexWillChange:(NSInteger)arg2 {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)aweme:(id)arg1 currentIndexDidChange:(NSInteger)arg2 {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)viewWillLayoutSubviews {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
}
%end

static id dyyyWindowKeyObserverToken = nil;
static id dyyyDidBecomeActiveToken = nil;
static id dyyyWillResignActiveToken = nil;
static id dyyyKeyboardWillShowToken = nil;
static void *DYYYGlobalTransparencyContext = &DYYYGlobalTransparencyContext;

static void DYYYRemoveAppLifecycleObservers(void) {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if (dyyyWindowKeyObserverToken) {
        [center removeObserver:dyyyWindowKeyObserverToken];
        dyyyWindowKeyObserverToken = nil;
    }
    if (dyyyDidBecomeActiveToken) {
        [center removeObserver:dyyyDidBecomeActiveToken];
        dyyyDidBecomeActiveToken = nil;
    }
    if (dyyyWillResignActiveToken) {
        [center removeObserver:dyyyWillResignActiveToken];
        dyyyWillResignActiveToken = nil;
    }
}

static void DYYYRemoveKeyboardObserver(void) {
    if (dyyyKeyboardWillShowToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:dyyyKeyboardWillShowToken];
        dyyyKeyboardWillShowToken = nil;
    }
}

%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    initTargetClassNames();

    updateGlobalTransparencyCache();

    [[NSUserDefaults standardUserDefaults] addObserver:(NSObject *)self forKeyPath:kDYYYGlobalTransparencyKey options:NSKeyValueObservingOptionNew context:DYYYGlobalTransparencyContext];

    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFloatClearButton"];
    if (isEnabled) {
        if (hideButton) {
            [hideButton removeFromSuperview];
            hideButton = nil;
        }

        CGFloat buttonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYEnableFloatClearButtonSize"] ?: 40.0;
        hideButton = [[HideUIButton alloc] initWithFrame:CGRectMake(0, 0, buttonSize, buttonSize)];
        hideButton.alpha = 0.5;

        NSString *savedPositionString = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideUIButtonPosition"];
        if (savedPositionString) {
            hideButton.center = CGPointFromString(savedPositionString);
        } else {
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
            hideButton.center = CGPointMake(screenWidth - buttonSize / 2 - 5, screenHeight / 2);
        }

        hideButton.hidden = NO;
        [getKeyWindow() addSubview:hideButton];
        updateClearButtonVisibility();

        DYYYRemoveAppLifecycleObservers();

        dyyyWindowKeyObserverToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeKeyNotification
                                                                                       object:nil
                                                                                        queue:[NSOperationQueue mainQueue]
                                                                                   usingBlock:^(NSNotification *_Nonnull notification) {
                                                                                     updateClearButtonVisibility();
                                                                                   }];

        dyyyDidBecomeActiveToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                                     object:nil
                                                                                      queue:[NSOperationQueue mainQueue]
                                                                                 usingBlock:^(NSNotification *_Nonnull notification) {
                                                                                   isAppActive = YES;
                                                                                   updateClearButtonVisibility();
                                                                                 }];

        dyyyWillResignActiveToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                                                      object:nil
                                                                                       queue:[NSOperationQueue mainQueue]
                                                                                  usingBlock:^(NSNotification *_Nonnull notification) {
                                                                                    isAppActive = NO;
                                                                                    updateClearButtonVisibility();
                                                                                  }];
    } else {
        DYYYRemoveAppLifecycleObservers();
    }

    return result;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    DYYYRemoveAppLifecycleObservers();
    DYYYRemoveKeyboardObserver();
    %orig;
}

- (void)dealloc {
    DYYYRemoveAppLifecycleObservers();
    DYYYRemoveKeyboardObserver();
    @try {
        [[NSUserDefaults standardUserDefaults] removeObserver:(NSObject *)self forKeyPath:kDYYYGlobalTransparencyKey context:DYYYGlobalTransparencyContext];
    } @catch (NSException *exception) {
        NSLog(@"[DYYY] KVO removeObserver failed: %@", exception);
    } 
    %orig;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if (context == DYYYGlobalTransparencyContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
          updateGlobalTransparencyCache();
          [[NSNotificationCenter defaultCenter] postNotificationName:kDYYYGlobalTransparencyDidChangeNotification object:nil];
        });
    } else {
        %orig(keyPath, object, change, context);
    }
}

%end

static Class GuideViewClass = nil;
static Class MuteViewClass = nil;
static Class TagViewClass = nil;

%hook AWEElementStackView

- (void)setAlpha:(CGFloat)alpha {
    BOOL isApplyingGlobal = (dyyyGlobalTransparencyMutationDepth > 0);
    if (!isApplyingGlobal) {
        objc_setAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey, @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // 纯净模式功能
    static AWMSafeDispatchTimer *pureModeTimer = nil;
    static int attempts = 0;
    static BOOL pureModeSet = NO;
    if (DYYYGetBool(@"DYYYEnablePure")) {
        %orig(0.0);
        if (pureModeSet) {
            return;
        }
        if (!pureModeTimer) {
            pureModeTimer = [[AWMSafeDispatchTimer alloc] init];
        }
        if (!pureModeTimer.isRunning) {
            attempts = 0;
            __weak AWMSafeDispatchTimer *weakTimer = pureModeTimer;
            [pureModeTimer startWithInterval:0.5
                                      leeway:0.1
                                       queue:dispatch_get_main_queue()
                                     repeats:YES
                                     handler:^{
                                       AWMSafeDispatchTimer *strongTimer = weakTimer;
                                       UIWindow *keyWindow = [DYYYUtils getActiveWindow];
                                       if (keyWindow && keyWindow.rootViewController) {
                                           UIViewController *feedVC = [DYYYUtils findViewControllerOfClass:NSClassFromString(@"AWEFeedTableViewController")
                                                                                          inViewController:keyWindow.rootViewController];
                                           if (feedVC) {
                                               [feedVC setValue:@YES forKey:@"pureMode"];
                                               pureModeSet = YES;
                                               [strongTimer cancel];
                                               pureModeTimer = nil;
                                               attempts = 0;
                                               return;
                                           }
                                       }
                                       attempts++;
                                       if (attempts >= 10) {
                                           [strongTimer cancel];
                                           pureModeTimer = nil;
                                           attempts = 0;
                                       }
                                     }];
        }
        return;
    }

    // 清理纯净模式的残留状态
    if (pureModeTimer) {
        [pureModeTimer cancel];
        pureModeTimer = nil;
    }
    attempts = 0;
    pureModeSet = NO;

    // 倍速和清屏按钮的状态控制
    BOOL hasFloatingButtons = (speedButton && isFloatSpeedButtonEnabled) || hideButton;
    if (!isApplyingGlobal && hasFloatingButtons && !dyyyIsPerformingFloatClearOperation) {
        const CGFloat threshold = 0.01f;
        if (alpha <= threshold) {
            dyyyCommentViewVisible = YES;
        } else if (alpha >= (1.0f - threshold)) {
            dyyyCommentViewVisible = NO;
        }
        updateSpeedButtonVisibility();
        updateClearButtonVisibility();
    }

    // 值守全局透明度
    CGFloat finalAlpha = alpha;
    if (!isApplyingGlobal && self.tag != DYYY_IGNORE_GLOBAL_ALPHA_TAG && gGlobalTransparency != kInvalidAlpha) {
        CGFloat clampedAlpha = MIN(MAX(alpha, 0.0), 1.0);
        finalAlpha = clampedAlpha * gGlobalTransparency;
    }

    // 统一应用透明度
    if (fabs(self.alpha - finalAlpha) >= 0.01) {
        %orig(finalAlpha);
    }
}

+ (void)initialize {
    GuideViewClass = NSClassFromString(@"AWELivePrestreamGuideView");
    MuteViewClass = NSClassFromString(@"AFDCancelMuteAwemeView");
    TagViewClass = NSClassFromString(@"AWELiveFeedLabelTagView");
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    dyyyCommentViewVisible = NO;
    updateSpeedButtonVisibility();
    updateClearButtonVisibility();
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    dyyyCommentViewVisible = YES;
    updateSpeedButtonVisibility();
    updateClearButtonVisibility();
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [self dyyy_applyGlobalTransparency];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dyyy_applyGlobalTransparency) name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

- (void)layoutSubviews {
    %orig;

    UIViewController *viewController = [DYYYUtils firstAvailableViewControllerFromView:self];

    if ([viewController isKindOfClass:%c(AWELiveNewPreStreamViewController)]) {
        const BOOL shouldShiftUp = DYYYGetBool(@"DYYYEnableFullScreen");
        const CGFloat labelScaleValue = DYYYGetFloat(@"DYYYNicknameScale");
        const CGFloat targetLabelScale = (labelScaleValue != 0.0) ? MAX(0.01, labelScaleValue) : 1.0;
        const CGFloat elementScaleValue = DYYYGetFloat(@"DYYYElementScale");
        const CGFloat targetElementScale = (elementScaleValue != 0.0) ? MAX(0.01, elementScaleValue) : 1.0;

        CGAffineTransform targetTransform = CGAffineTransformIdentity;
        CGFloat boundsWidth = self.bounds.size.width;
        CGFloat currentScale = 1.0;
        CGFloat targetHeight, tx, ty = 0;
        UIWindow *keyWindow = [DYYYUtils getActiveWindow];
        if (keyWindow && keyWindow.safeAreaInsets.bottom == 0) {
            targetHeight = gCurrentTabBarHeight - originalTabBarHeight;
        } else {
            targetHeight = gCurrentTabBarHeight;
        }

        if ([DYYYUtils containsSubviewOfClass:GuideViewClass inContainer:self]) {
            currentScale = targetLabelScale;
            tx = 0; // 中对齐
        } else if ([DYYYUtils containsSubviewOfClass:MuteViewClass inContainer:self]) {
            currentScale = targetElementScale;
            tx = (boundsWidth - boundsWidth * currentScale) / 2; // 右对齐
        } else if ([DYYYUtils containsSubviewOfClass:TagViewClass inContainer:self]) {
            currentScale = targetLabelScale;
            tx = (boundsWidth - boundsWidth * currentScale) / -2; // 左对齐
        }

        NSArray *subviews = [self.subviews copy];
        for (UIView *view in subviews) {
            CGFloat viewHeight = view.bounds.size.height;
            ty += (viewHeight - viewHeight * currentScale) / 2;
        }

        if (shouldShiftUp) {
            ty -= targetHeight;
        }

        targetTransform = CGAffineTransformMake(currentScale, 0, 0, currentScale, tx, ty);

        if (!CGAffineTransformEqualToTransform(self.transform, targetTransform)) {
            self.transform = targetTransform;
        }
    }

    if ([viewController isKindOfClass:%c(AWEPlayInteractionViewController)]) {
        NSString *label = self.accessibilityLabel ?: @"";
        BOOL hasAnchor = [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEFeedAnchorContainerView") inContainer:self];
        BOOL hasAvatar = [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEPlayInteractionUserAvatarView") inContainer:self];

        BOOL isRightStack = ([label isEqualToString:@"right"] || hasAvatar);
        if (!isRightStack) {
            NSArray *subviews = [self.subviews copy];
            for (NSInteger i = (NSInteger)subviews.count - 1; i >= 0; i--) {
                UIView *sub = subviews[i];
                if ([sub respondsToSelector:@selector(elementClassName)]) {
                    NSString *elementClassName = [sub performSelector:@selector(elementClassName)];
                    if ([elementClassName isEqualToString:@"AWEPlayInteractionUserAvatarOptElementElement"]) {
                        isRightStack = YES;
                        break;
                    }
                }
            }
        }

        BOOL isLeftStack = ([label isEqualToString:@"left"] || hasAnchor);
        if (!isLeftStack) {
            NSArray *subviews = [self.subviews copy];
            for (NSInteger i = (NSInteger)subviews.count - 1; i >= 0; i--) {
                UIView *sub = subviews[i];
                if ([sub respondsToSelector:@selector(elementClassName)]) {
                    NSString *elementClassName = [sub performSelector:@selector(elementClassName)];
                    if ([elementClassName isEqualToString:@"AWEPlayInteractionDescriptionElement"]) {
                        isLeftStack = YES;
                        break;
                    }
                }
            }
        }

        // 右侧元素的处理逻辑
        if (isRightStack) {
            NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYElementScale"];
            self.transform = CGAffineTransformIdentity;
            if (scaleValue.length > 0) {
                CGFloat scale = [scaleValue floatValue];
                if (scale > 0 && scale != 1.0) {
                    NSArray *subviews = [self.subviews copy];
                    CGFloat ty = 0;
                    for (UIView *view in subviews) {
                        CGFloat viewHeight = view.frame.size.height;
                        ty += (viewHeight - viewHeight * scale) / 2;
                    }
                    CGFloat frameWidth = self.frame.size.width;
                    CGFloat right_tx = (frameWidth - frameWidth * scale) / 2;
                    self.transform = CGAffineTransformMake(scale, 0, 0, scale, right_tx, ty);
                } else {
                    self.transform = CGAffineTransformIdentity;
                }
            }
        }
        // 左侧元素的处理逻辑
        else if (isLeftStack) {
            NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];
            if (scaleValue.length > 0) {
                CGFloat scale = [scaleValue floatValue];
                self.transform = CGAffineTransformIdentity;
                if (scale > 0 && scale != 1.0) {
                    NSArray *subviews = [self.subviews copy];
                    CGFloat ty = 0;
                    for (UIView *view in subviews) {
                        CGFloat viewHeight = view.frame.size.height;
                        ty += (viewHeight - viewHeight * scale) / 2;
                    }
                    CGFloat frameWidth = self.frame.size.width;
                    CGFloat left_tx = (frameWidth - frameWidth * scale) / 2 - frameWidth * (1 - scale);
                    CGAffineTransform newTransform = CGAffineTransformMakeScale(scale, scale);
                    newTransform = CGAffineTransformTranslate(newTransform, left_tx / scale, ty / scale);
                    self.transform = newTransform;
                }
            }
        }
    }
}

- (NSArray<__kindof UIView *> *)arrangedSubviews {

    UIViewController *viewController = [DYYYUtils firstAvailableViewControllerFromView:self];
    if ([viewController isKindOfClass:%c(AWEPlayInteractionViewController)]) {

        if ([self.accessibilityLabel isEqualToString:@"left"] || [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEFeedAnchorContainerView") inContainer:self]) {
            NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];
            if (scaleValue.length > 0) {
                CGFloat scale = [scaleValue floatValue];
                self.transform = CGAffineTransformIdentity;
                if (scale > 0 && scale != 1.0) {
                    NSArray *subviews = [self.subviews copy];
                    CGFloat ty = 0;
                    for (UIView *view in subviews) {
                        CGFloat viewHeight = view.frame.size.height;
                        ty += (viewHeight - viewHeight * scale) / 2;
                    }
                    CGFloat frameWidth = self.frame.size.width;
                    CGFloat left_tx = (frameWidth - frameWidth * scale) / 2 - frameWidth * (1 - scale);
                    CGAffineTransform newTransform = CGAffineTransformMakeScale(scale, scale);
                    newTransform = CGAffineTransformTranslate(newTransform, left_tx / scale, ty / scale);
                    self.transform = newTransform;
                }
            }
        }
    }

    NSArray *originalSubviews = %orig;
    return originalSubviews;
}

%end

%hook IESLiveStackView

+ (void)initialize {
    GuideViewClass = NSClassFromString(@"AWELivePrestreamGuideView");
    MuteViewClass = NSClassFromString(@"AFDCancelMuteAwemeView");
    TagViewClass = NSClassFromString(@"AWELiveFeedLabelTagView");
}

- (void)setAlpha:(CGFloat)alpha {
    BOOL isApplyingGlobal = (dyyyGlobalTransparencyMutationDepth > 0);
    if (!isApplyingGlobal) {
        objc_setAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey, @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (!isApplyingGlobal && speedButton && isFloatSpeedButtonEnabled) {
        if (alpha == 0) {
            dyyyCommentViewVisible = YES;
        } else if (alpha == 1) {
            dyyyCommentViewVisible = NO;
        }
        updateSpeedButtonVisibility();
        updateClearButtonVisibility();
    }

    CGFloat finalAlpha = alpha;
    if (!isApplyingGlobal && self.tag != DYYY_IGNORE_GLOBAL_ALPHA_TAG && gGlobalTransparency != kInvalidAlpha) {
        CGFloat clampedAlpha = MIN(MAX(alpha, 0.0), 1.0);
        finalAlpha = clampedAlpha * gGlobalTransparency;
    }

    if (fabs(self.alpha - finalAlpha) >= 0.01) {
        %orig(finalAlpha);
    }
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [self dyyy_applyGlobalTransparency];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dyyy_applyGlobalTransparency) name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

- (void)layoutSubviews {
    %orig;

    UIViewController *viewController = [DYYYUtils firstAvailableViewControllerFromView:self];

    if ([viewController isKindOfClass:%c(AWELiveNewPreStreamViewController)]) {
        const BOOL shouldShiftUp = DYYYGetBool(@"DYYYEnableFullScreen");
        const CGFloat labelScaleValue = DYYYGetFloat(@"DYYYNicknameScale");
        const CGFloat targetLabelScale = (labelScaleValue != 0.0) ? MAX(0.01, labelScaleValue) : 1.0;
        const CGFloat elementScaleValue = DYYYGetFloat(@"DYYYElementScale");
        const CGFloat targetElementScale = (elementScaleValue != 0.0) ? MAX(0.01, elementScaleValue) : 1.0;

        CGAffineTransform targetTransform = CGAffineTransformIdentity;
        CGFloat boundsWidth = self.bounds.size.width;
        CGFloat currentScale = 1.0;
        CGFloat targetHeight, tx, ty = 0;
        UIWindow *keyWindow = [DYYYUtils getActiveWindow];
        if (keyWindow && keyWindow.safeAreaInsets.bottom == 0) {
            targetHeight = gCurrentTabBarHeight - originalTabBarHeight;
        } else {
            targetHeight = gCurrentTabBarHeight;
        }

        if ([DYYYUtils containsSubviewOfClass:GuideViewClass inContainer:self]) {
            currentScale = targetLabelScale;
            tx = 0; // 中对齐
        } else if ([DYYYUtils containsSubviewOfClass:MuteViewClass inContainer:self]) {
            currentScale = targetElementScale;
            tx = (boundsWidth - boundsWidth * currentScale) / 2; // 右对齐
        } else if ([DYYYUtils containsSubviewOfClass:TagViewClass inContainer:self]) {
            currentScale = targetLabelScale;
            tx = (boundsWidth - boundsWidth * currentScale) / -2; // 左对齐
        }

        NSArray *subviews = [self.subviews copy];
        for (UIView *view in subviews) {
            CGFloat viewHeight = view.bounds.size.height;
            ty += (viewHeight - viewHeight * currentScale) / 2;
        }

        if (shouldShiftUp) {
            ty -= targetHeight;
        }
        targetTransform = CGAffineTransformMakeTranslation(0, -20);

        if (!CGAffineTransformEqualToTransform(self.transform, targetTransform)) {
            self.transform = targetTransform;
        }
    }
}

%end

%hook AWEStoryContainerCollectionView
- (void)layoutSubviews {
    %orig;
    if ([self.subviews count] == 2)
        return;

    // 获取 enableEnterProfile 属性来判断是否是主页
    id enableEnterProfile = [self valueForKey:@"enableEnterProfile"];
    BOOL isHome = (enableEnterProfile != nil && [enableEnterProfile boolValue]);

    // 检查是否在作者主页
    BOOL isAuthorProfile = NO;
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([NSStringFromClass([responder class]) containsString:@"UserHomeViewController"] || [NSStringFromClass([responder class]) containsString:@"ProfileViewController"]) {
            isAuthorProfile = YES;
            break;
        }
    }

    // 如果不是主页也不是作者主页，直接返回
    if (!isHome && !isAuthorProfile)
        return;

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIView class]]) {
            UIView *nextResponder = (UIView *)subview.nextResponder;

            // 处理主页的情况
            if (isHome && [nextResponder isKindOfClass:%c(AWEPlayInteractionViewController)]) {
                UIViewController *awemeBaseViewController = [nextResponder valueForKey:@"awemeBaseViewController"];
                if (![awemeBaseViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
                    continue;
                }

                CGRect frame = subview.frame;
                if (DYYYGetBool(@"DYYYEnableFullScreen")) {
                    frame.size.height = subview.superview.frame.size.height - gCurrentTabBarHeight;
                    subview.frame = frame;
                }
            }
            // 处理作者主页的情况
            else if (isAuthorProfile) {
                // 检查是否是作品图片
                BOOL isWorkImage = NO;

                // 可以通过检查子视图、标签或其他特性来确定是否是作品图片
                for (UIView *childView in subview.subviews) {
                    if ([NSStringFromClass([childView class]) containsString:@"ImageView"] || [NSStringFromClass([childView class]) containsString:@"ThumbnailView"]) {
                        isWorkImage = YES;
                        break;
                    }
                }

                if (isWorkImage) {
                    // 修复作者主页作品图片上移问题
                    CGRect frame = subview.frame;
                    frame.origin.y += gCurrentTabBarHeight;
                    subview.frame = frame;
                }
            }
        }
    }
}
%end

%hook AFDFastSpeedView
- (void)layoutSubviews {
    %orig;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFullScreen"]) {
        return;
    }

    static char kDYFastSpeedBgKey;
    NSArray *bgViews = objc_getAssociatedObject(self, &kDYFastSpeedBgKey);
    if (!bgViews) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview class] == [UIView class]) {
                [tmp addObject:subview];
            }
        }
        bgViews = [tmp copy];
        objc_setAssociatedObject(self, &kDYFastSpeedBgKey, bgViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *view in bgViews) {
        view.backgroundColor = [UIColor clearColor];
    }
}
%end

%hook TTPlayerView

- (void)layoutSubviews {
    %orig;
    UIView *parent = self.superview;
    if (parent) {
        parent.backgroundColor = self.backgroundColor;
    }
}

%end

%hook TTMetalView
- (void)setCenter:(CGPoint)center {
    BOOL shouldAdjust = NO;
    UIView *view = (UIView *)self;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGFloat viewWidth = CGRectGetWidth(view.bounds);
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        if (viewWidth + 0.5f >= screenWidth) {
            UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:view];
            Class playClass = %c(AWEPlayVideoViewController);
            if (playClass && [vc isKindOfClass:playClass]) {
                AWEPlayVideoViewController *playVC = (AWEPlayVideoViewController *)vc;
                AWEAwemeModel *model = playVC.model;
                if ([model respondsToSelector:@selector(isShowLandscapeEntryView)] && model.isShowLandscapeEntryView) {
                    shouldAdjust = YES;
                }
            }
        }
    }

    if (shouldAdjust) {
        CGFloat offset = gCurrentTabBarHeight > 0 ? gCurrentTabBarHeight : originalTabBarHeight;
        if (offset > 0) {
            center.y -= offset * 0.5;
        }
    }

    %orig(center);
}
%end

%hook TTMetalViewNew
- (void)setCenter:(CGPoint)center {
    BOOL shouldAdjust = NO;
    UIView *view = (UIView *)self;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGFloat viewWidth = CGRectGetWidth(view.bounds);
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        if (viewWidth + 0.5f >= screenWidth) {
            UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:view];
            Class playClass = %c(AWEPlayVideoViewController);
            if (playClass && [vc isKindOfClass:playClass]) {
                AWEPlayVideoViewController *playVC = (AWEPlayVideoViewController *)vc;
                AWEAwemeModel *model = playVC.model;
                if ([model respondsToSelector:@selector(isShowLandscapeEntryView)] && model.isShowLandscapeEntryView) {
                    shouldAdjust = YES;
                }
            }
        }
    }

    if (shouldAdjust) {
        CGFloat offset = gCurrentTabBarHeight > 0 ? gCurrentTabBarHeight : originalTabBarHeight;
        if (offset > 0) {
            center.y -= offset * 0.5;
        }
    }

    %orig(center);
}
%end

// 隐藏图片滑条
%hook AWEStoryProgressContainerView
- (void)setCenter:(CGPoint)center {
    UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
    if ([vc isKindOfClass:NSClassFromString(@"AWEFeedPlayControlImpl.PureModePageCellViewController")] && DYYYGetBool(@"DYYYEnableFullScreen")) {
        center.y -= gCurrentTabBarHeight;
    }
    %orig(center);
}

- (BOOL)isHidden {
    BOOL originalValue = %orig;
    BOOL customHide = DYYYGetBool(@"DYYYHideDotsIndicator");
    return originalValue || customHide;
}

- (void)setHidden:(BOOL)hidden {
    BOOL forceHide = DYYYGetBool(@"DYYYHideDotsIndicator");
    %orig(forceHide ? YES : hidden);
}
%end

%hook AWELandscapeFeedEntryView

- (void)setAlpha:(CGFloat)alpha {
    BOOL isApplyingGlobal = (dyyyGlobalTransparencyMutationDepth > 0);
    if (!isApplyingGlobal) {
        objc_setAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey, @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat finalAlpha = alpha;
    if (!isApplyingGlobal && self.tag != DYYY_IGNORE_GLOBAL_ALPHA_TAG && gGlobalTransparency != kInvalidAlpha) {
        CGFloat clampedAlpha = MIN(MAX(alpha, 0.0), 1.0);
        finalAlpha = clampedAlpha * gGlobalTransparency;
    }

    if (fabs(self.alpha - finalAlpha) >= 0.01) {
        %orig(finalAlpha);
    }
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [self dyyy_applyGlobalTransparency];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dyyy_applyGlobalTransparency) name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYRemoveEntry")) {
        [self removeFromSuperview];
        return;
    }
    if (DYYYGetBool(@"DYYYHideEntry")) {
        for (UIView *subview in self.subviews) {
            subview.hidden = YES;
        }
        return;
    }

    NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];
    CGFloat scale = scaleValue.length > 0 ? [scaleValue floatValue] : 1.0;
    if (scale > 0 && scale != 1.0) {
        self.transform = CGAffineTransformMakeScale(scale, scale);
    } else {
        self.transform = CGAffineTransformIdentity;
    }
}

%end

%hook AWEAwemeDetailTableView

- (void)setFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

        CGFloat remainder = fmod(frame.size.height, screenHeight);
        if (remainder != 0) {
            frame.size.height += (screenHeight - remainder);
        }
    }
    %orig(frame);
}

%end

%hook AWEMixVideoPanelMoreView

- (void)setFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGFloat targetY = frame.origin.y - gCurrentTabBarHeight;
        CGFloat screenHeightMinusGDiff = [UIScreen mainScreen].bounds.size.height - gCurrentTabBarHeight;

        CGFloat tolerance = 10.0;

        if (fabs(targetY - screenHeightMinusGDiff) <= tolerance) {
            frame.origin.y = targetY;
        }
    }
    %orig(frame);
}

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        self.backgroundColor = [UIColor clearColor];
    }
}

%end

%hook CommentInputContainerView

- (void)layoutSubviews {
    %orig;
    UIViewController *parentVC = nil;
    if ([self respondsToSelector:@selector(viewController)]) {
        id viewController = [self performSelector:@selector(viewController)];
        if ([viewController respondsToSelector:@selector(parentViewController)]) {
            parentVC = [viewController parentViewController];
        }
    }

    if (parentVC && ([parentVC isKindOfClass:%c(AWEAwemeDetailTableViewController)] || [parentVC isKindOfClass:%c(AWEAwemeDetailCellViewController)])) {
        static char kDYCommentHideCacheKey;
        UIView *target = objc_getAssociatedObject(self, &kDYCommentHideCacheKey);
        if (!target) {
            for (UIView *subview in [self subviews]) {
                if ([subview class] == [UIView class]) {
                    target = subview;
                    objc_setAssociatedObject(self, &kDYCommentHideCacheKey, target, OBJC_ASSOCIATION_ASSIGN);
                    break;
                }
            }
        }
        if (target) {
            target.hidden = ([(UIView *)self frame].size.height == gCurrentTabBarHeight);
        }
    }
}

%end

// 聊天视频底部评论框背景透明
%hook AWEIMFeedBottomQuickEmojiInputBar

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        UIView *parentView = self.superview;
        while (parentView) {
            if ([NSStringFromClass([parentView class]) isEqualToString:@"UIView"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  parentView.backgroundColor = [UIColor clearColor];
                  parentView.layer.backgroundColor = [UIColor clearColor].CGColor;
                  parentView.opaque = NO;
                });
                break;
            }
            parentView = parentView.superview;
        }
    }
}

%end

// 隐藏上次看到
%hook DUXPopover
- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHidePopover")) {
        return;
    }

    id rawContent = nil;
    @try {
        rawContent = [self valueForKey:@"content"];
    } @catch (__unused NSException *e) {
        return;
    }

    NSString *text = [rawContent isKindOfClass:NSString.class] ? (NSString *)rawContent : [rawContent description];

    if ([text containsString:@"上次看到"]) {
        self.hidden = YES;
        return;
    }
}
%end

%hook _TtC21AWEIncentiveSwiftImpl29IncentivePendantContainerView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePendantGroup")) {
        [self removeFromSuperview];
    }
}
%end

%hook UIImageView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideCommentDiscover")) {
        if (!self.accessibilityLabel) {
            UIView *parentView = self.superview;

            if (parentView && [parentView class] == [UIView class] && [parentView.accessibilityLabel isEqualToString:@"搜索"]) {
                self.hidden = YES;
            }

            else if (parentView && [NSStringFromClass([parentView class]) isEqualToString:@"AWESearchEntryHalfScreenElement"] && [parentView.accessibilityLabel isEqualToString:@"搜索"]) {
                self.hidden = YES;
            }
        }
    }
    return;
}
%end

// 移除极速版我的片面红包横幅
%hook AWELuckyCatBannerView
- (id)initWithFrame:(CGRect)frame {
    return nil;
}

- (id)init {
    return nil;
}
%end

static NSString *const kHideRecentAppsKey = @"DYYYHideSidebarRecentApps";
static NSString *const kHideRecentUsersKey = @"DYYYHideSidebarRecentUsers";

%hook AWELeftSideBarModel

- (NSArray *)moduleModels {
    NSArray *originalModels = %orig;

    BOOL shouldHideRecentApps = DYYYGetBool(kHideRecentAppsKey);
    BOOL shouldHideRecentUsers = DYYYGetBool(kHideRecentUsersKey);

    if (!shouldHideRecentApps && !shouldHideRecentUsers) {
        return originalModels;
    }

    NSMutableArray *filteredModels = [NSMutableArray arrayWithCapacity:originalModels.count];

    for (id moduleModel in originalModels) {
        if ([moduleModel respondsToSelector:@selector(moduleID)]) {
            NSString *moduleID = [moduleModel moduleID];

            if (shouldHideRecentApps && [moduleID isEqualToString:@"recently_apps_module"]) {
                continue;
            }

            if (shouldHideRecentUsers && [moduleID isEqualToString:@"recently_users_module"]) {
                continue;
            }
        }

        id filteredModule = [self filterModuleItems:moduleModel];
        if (filteredModule) {
            [filteredModels addObject:filteredModule];
        }
    }

    return [filteredModels copy];
}

%new
- (id)filterModuleItems:(id)moduleModel {
    if (![moduleModel respondsToSelector:@selector(items)] || ![moduleModel respondsToSelector:@selector(moduleID)]) {
        return moduleModel;
    }

    NSString *moduleID = [moduleModel moduleID];
    NSArray *originalItems = [moduleModel items];

    if ([moduleID isEqualToString:@"top_area"]) {
        // 只保留天气、设置、扫一扫
        NSMutableArray *filteredItems = [NSMutableArray array];

        for (id item in originalItems) {
            if ([item respondsToSelector:@selector(businessType)]) {
                NSString *businessType = [item businessType];

                // 保留需要的组件
                if ([businessType isEqualToString:@"weather_time_tip_component"] || [businessType isEqualToString:@"setting_page_component"] ||
                    [businessType isEqualToString:@"top_area_vertical_cell"]) {
                    [filteredItems addObject:item];
                }
            }
        }

        // 创建新的模块对象，保持原有属性但更新items
        if ([moduleModel respondsToSelector:@selector(copy)]) {
            id newModule = [moduleModel copy];
            if ([newModule respondsToSelector:@selector(setItems:)]) {
                [newModule setItems:[filteredItems copy]];
            }
            return newModule;
        }
    }

    return moduleModel;
}

%end

@interface UIDropShadowView : UIView
@end

// 修复 ios26 模态透明效果
// %hook UIDropShadowView

// - (void)didMoveToSuperview {
//     %orig;

//     if (@available(iOS 26.0, *)) {
//         self.backgroundColor = UIColor.clearColor;
//         self.opaque = NO;
//     }
// }

// - (void)layoutSubviews {
//     %orig;

//     if (@available(iOS 26.0, *)) {
//         self.backgroundColor = UIColor.clearColor;
//         self.opaque = NO;
//     }
// }

// - (void)setBackgroundColor:(UIColor *)color {
//     if (@available(iOS 26.0, *)) {
//         %orig(UIColor.clearColor);
//         return;
//     }
//     %orig;
// }

// %end

%hook AFDViewedBottomView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {

        self.backgroundColor = [UIColor clearColor];

        self.effectView.hidden = YES;
    }
}
%end

// 极速版红包激励挂件容器视图类组（移除逻辑）
%group IncentivePendantGroup
%hook AWEIncentiveSwiftImplDOUYINLite_IncentivePendantContainerView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePendantGroup")) {
        [self removeFromSuperview];
    }
}
%end
%end

// View scaling fix when comment blur is enabled
%group BDMultiContentImageViewGroup
%hook BDMultiContentContainer_ImageContentView

- (void)setTransform:(CGAffineTransform)transform {
    if (DYYYGetBool(@"DYYYEnableCommentBlur")) {
        return;
    }
    %orig(transform);
}

%end
%end

%hook AWEStoryContainerCollectionView

- (void)setFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYEnableCommentBlur")) {
        if (frame.origin.y != 0) {
            return;
        }
    }
    %orig(frame);
}

%end

%hook AWEDPlayerProgressContainerView

- (void)layoutSubviews {
    %orig;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFullScreen"]) {
        return;
    }

    for (UIView *subview in self.subviews) {
        if ([subview isMemberOfClass:[UIView class]]) {
            UIColor *bgColor = subview.backgroundColor;
            if (bgColor) {
                CGFloat h, s, v, a;
                if ([bgColor getHue:&h saturation:&s brightness:&v alpha:&a]) {
                    if (v < 0.2) {
                        subview.backgroundColor = [UIColor clearColor];
                    }
                }
            }
        }
    }
}

%end


// 隐藏键盘 AI
static __weak UIView *cachedHideView = nil;
static void hideParentViewsSubviews(UIView *view) {
    if (!view)
        return;
    UIView *parentView = [view superview];
    if (!parentView)
        return;
    UIView *grandParentView = [parentView superview];
    if (!grandParentView)
        return;
    UIView *greatGrandParentView = [grandParentView superview];
    if (!greatGrandParentView)
        return;
    cachedHideView = greatGrandParentView;
    for (UIView *subview in greatGrandParentView.subviews) {
        subview.hidden = YES;
    }
}

// 递归查找目标视图
static void findTargetViewInView(UIView *view) {
    if (cachedHideView)
        return;
    if ([view isKindOfClass:NSClassFromString(@"AWESearchKeyboardVoiceSearchEntranceView")]) {
        hideParentViewsSubviews(view);
        return;
    }
    for (UIView *subview in view.subviews) {
        findTargetViewInView(subview);
        if (cachedHideView)
            break;
    }
}

%ctor {
    Class interactionBaseLabelClass = objc_getClass("AWECommentSwiftBizUI.CommentInteractionBaseLabel");
    if (interactionBaseLabelClass) {
        %init(DYYYCommentExactTimeGroup, AWECommentSwiftBizUI_CommentInteractionBaseLabel = interactionBaseLabelClass);
    }
    
    Class imMenuComponentClass = objc_getClass("AWEIMCustomMenuComponent");
    if (imMenuComponentClass) {
        SEL legacySelector = NSSelectorFromString(@"msg_showMenuForBubbleFrameInScreen:tapLocationInScreen:menuItemList:moreEmoticon:onCell:extra:");
        SEL tapLocationSelector = NSSelectorFromString(@"msg_showMenuForBubbleFrameInScreen:tapLocationInScreen:menuItemList:menuPanelOptions:moreEmoticon:onCell:extra:");
        SEL highLowSelector = NSSelectorFromString(@"msg_showMenuForBubbleFrameInScreen:highLocationInScreen:lowLocationInScreen:tryHighLocationFirst:menuItemList:menuPanelOptions:onCell:extra:");
        if (legacySelector && class_getInstanceMethod(imMenuComponentClass, legacySelector)) {
            %init(DYYYIMMenuLegacyGroup);
        }
        if (tapLocationSelector && class_getInstanceMethod(imMenuComponentClass, tapLocationSelector)) {
            %init(DYYYIMMenuTapLocationGroup);
        }
        if (highLowSelector && class_getInstanceMethod(imMenuComponentClass, highLowSelector)) {
            %init(DYYYIMMenuHighLowGroup);
        }
    }

    if (!DYYYGetBool(@"DYYYDisableSettingsGesture")) {
        %init(DYYYSettingsGesture);
    }
    if (DYYYGetBool(@"DYYYUserAgreementAccepted")) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
          Class wSwiftImpl = objc_getClass("AWECommentInputViewSwiftImpl.CommentInputContainerView");
          %init(CommentInputContainerView = wSwiftImpl);
        });
        BOOL isAutoPlayEnabled = DYYYGetBool(@"DYYYEnableAutoPlay");
        if (isAutoPlayEnabled) {
            %init(AutoPlay);
        }
        if (DYYYGetBool(@"DYYYForceDownloadEmotion") ||
            DYYYGetBool(@"DYYYForceDownloadCommentAudio") ||
            DYYYGetBool(@"DYYYForceDownloadCommentImage")) {
            %init(EnableStickerSaveMenu);
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        isFloatSpeedButtonEnabled = [defaults boolForKey:@"DYYYEnableFloatSpeedButton"];

        // 初始化红包激励挂件容器视图类组
        Class incentivePendantClass = objc_getClass("AWEIncentiveSwiftImplDOUYINLite.IncentivePendantContainerView");
        if (incentivePendantClass) {
            %init(IncentivePendantGroup, AWEIncentiveSwiftImplDOUYINLite_IncentivePendantContainerView = incentivePendantClass);
        }
        Class imageContentClass = objc_getClass("BDMultiContentContainer.ImageContentView");
        if (imageContentClass) {
            %init(BDMultiContentImageViewGroup, BDMultiContentContainer_ImageContentView = imageContentClass);
        }

        // 动态获取 Swift 类并初始化对应的组
        Class commentHeaderGeneralClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderGeneralView");
        if (commentHeaderGeneralClass) {
            %init(CommentHeaderGeneralGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView = commentHeaderGeneralClass);
        }

        Class commentHeaderGoodsClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderGoodsView");
        if (commentHeaderGoodsClass) {
            %init(CommentHeaderGoodsGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView = commentHeaderGoodsClass);
        }
        Class commentHeaderTemplateClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderTemplateAnchorView");
        if (commentHeaderTemplateClass) {
            %init(CommentHeaderTemplateGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView = commentHeaderTemplateClass);
        }

        Class tipsVCClass = objc_getClass("AWECommentPanelListSwiftImpl.CommentBottomTipsContainerViewController");
        if (tipsVCClass) {
            %init(CommentBottomTipsVCGroup, AWECommentPanelListSwiftImpl_CommentBottomTipsContainerViewController = tipsVCClass);
        }

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        DYYYRemoveKeyboardObserver();
        dyyyKeyboardWillShowToken = [center addObserverForName:UIKeyboardWillShowNotification
                                                        object:nil
                                                         queue:[NSOperationQueue mainQueue]
                                                    usingBlock:^(NSNotification *notification) {
                                                      if (DYYYGetBool(@"DYYYHideKeyboardAI")) {
                                                          if (cachedHideView) {
                                                              for (UIView *subview in cachedHideView.subviews) {
                                                                  subview.hidden = YES;
                                                              }
                                                          } else {
                                                              for (UIWindow *window in [UIApplication sharedApplication].windows) {
                                                                  findTargetViewInView(window);
                                                                  if (cachedHideView)
                                                                      break;
                                                              }
                                                          }
                                                      }
                                                    }];
    }
}
