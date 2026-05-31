#import "DYYYUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <UIKit/UIKit.h>
#import <math.h>
#import <os/lock.h>
#import <os/log.h>
#import <stdatomic.h>
#import <stdarg.h>
#import <unistd.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"
#import "DYYYToast.h"
#import "DYYYConstants.h"

@class YYImageDecoder;
@class YYImageFrame;

@interface YYImageFrame : NSObject
@property(nonatomic, strong) UIImage *image;
@property(nonatomic) CGFloat duration;
@end

@interface YYImageDecoder : NSObject
@property(nonatomic, readonly) NSUInteger frameCount;
+ (instancetype)decoderWithData:(NSData *)data scale:(CGFloat)scale;
- (YYImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay;
@end

static const void *kLabelColorStateKey = &kLabelColorStateKey;
static const NSTimeInterval kDYYYUtilsDefaultFrameDelay = 0.1f;

static NSString *DYYYRuntimeLogFilePath(void) {
    static NSString *logPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSString *logsDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"DYYYLogs"];
      [[NSFileManager defaultManager] createDirectoryAtPath:logsDirectory
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil];
      logPath = [logsDirectory stringByAppendingPathComponent:@"runtime.log"];
    });
    return logPath;
}

void DYYYNSLog(NSString *format, ...) {
    if (format.length == 0) {
        return;
    }

    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    if (message.length == 0) {
        return;
    }

    static os_log_t dyyyLogger = nil;
    static dispatch_once_t loggerOnceToken;
    dispatch_once(&loggerOnceToken, ^{
      dyyyLogger = os_log_create("com.dyyy.tweak", "runtime");
    });
    os_log_with_type(dyyyLogger, OS_LOG_TYPE_DEFAULT, "%{public}@", message);

    const char *stderrMessage = message.UTF8String;
    if (stderrMessage) {
        fprintf(stderr, "%s\n", stderrMessage);
        fflush(stderr);
    }

    static dispatch_queue_t logQueue = nil;
    static dispatch_once_t queueOnceToken;
    dispatch_once(&queueOnceToken, ^{
      logQueue = dispatch_queue_create("com.dyyy.runtime-log.queue", DISPATCH_QUEUE_SERIAL);
    });

    dispatch_async(logQueue, ^{
      @autoreleasepool {
          NSString *line = [NSString stringWithFormat:@"[%@][pid:%d] %@\n", [NSDate date], getpid(), message];
          NSData *lineData = [line dataUsingEncoding:NSUTF8StringEncoding];
          if (lineData.length == 0) {
              return;
          }

          NSString *logPath = DYYYRuntimeLogFilePath();
          NSFileManager *fileManager = [NSFileManager defaultManager];
          if (![fileManager fileExistsAtPath:logPath]) {
              [fileManager createFileAtPath:logPath contents:nil attributes:nil];
          }

          NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
          if (!fileHandle) {
              return;
          }
          @try {
              [fileHandle seekToEndOfFile];
              [fileHandle writeData:lineData];
          } @catch (NSException *exception) {
          }
          [fileHandle closeFile];
      }
    });
}

static inline CGFloat DYYYUtilsNormalizedDelay(CGFloat delay) {
    if (!isfinite(delay) || delay < 0.01f) {
        return kDYYYUtilsDefaultFrameDelay;
    }
    return delay;
}

@interface DYYYLabelColorState : NSObject
@property(nonatomic, copy) NSString *textSignature;
@property(nonatomic, copy) NSString *colorKey;
@property(nonatomic, copy) NSString *fontName;
@property(nonatomic, assign) CGFloat fontSize;
@end

@implementation DYYYLabelColorState
@end

static inline BOOL DYYYStringsEqual(NSString *lhs, NSString *rhs) {
    if (lhs == rhs) {
        return YES;
    }
    return [lhs isEqualToString:rhs];
}

static NSString *DYYYNormalizedColorKey(NSString *colorHexString) {
    if (colorHexString.length == 0) {
        return nil;
    }
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [colorHexString stringByTrimmingCharactersInSet:whitespace];
    if (trimmed.length == 0) {
        return nil;
    }
    return trimmed.lowercaseString;
}

static BOOL DYYYColorKeyIsDynamic(NSString *normalizedKey) {
    if (normalizedKey.length == 0) {
        return NO;
    }
    NSString *key = [normalizedKey hasPrefix:@"#"] ? [normalizedKey substringFromIndex:1] : normalizedKey;
    return [key isEqualToString:@"random"] || [key isEqualToString:@"random_gradient"] || [key isEqualToString:@"rainbow_rotating"];
}

static YYImageDecoder *DYYYUtilsCreateYYDecoderWithData(NSData *data, CGFloat scale) {
    if (!data || data.length == 0) {
        return nil;
    }

    Class decoderClass = NSClassFromString(@"YYImageDecoder");
    if (!decoderClass || ![decoderClass respondsToSelector:@selector(decoderWithData:scale:)]) {
        return nil;
    }

    CGFloat resolvedScale = scale > 0 ? scale : 1.0f;
    id decoderInstance = [(id)decoderClass decoderWithData:data scale:resolvedScale];
    if (![decoderInstance isKindOfClass:decoderClass]) {
        return nil;
    }

    return (YYImageDecoder *)decoderInstance;
}

static CGFloat DYYYUtilsTotalDurationFromYYDecoder(YYImageDecoder *decoder) {
    if (!decoder || decoder.frameCount == 0) {
        return 0;
    }

    CGFloat totalDuration = 0;
    NSUInteger frameCount = decoder.frameCount;
    for (NSUInteger i = 0; i < frameCount; i++) {
        YYImageFrame *frame = [decoder frameAtIndex:i decodeForDisplay:NO];
        if (!frame) {
            continue;
        }
        CGFloat frameDuration = frame.duration > 0 ? frame.duration : kDYYYUtilsDefaultFrameDelay;
        totalDuration += frameDuration;
    }

    return totalDuration;
}

static uint32_t DYYYUtilsReadUInt32BigEndian(const uint8_t *bytes) {
    return ((uint32_t)bytes[0] << 24) | ((uint32_t)bytes[1] << 16) | ((uint32_t)bytes[2] << 8) | (uint32_t)bytes[3];
}

static uint64_t DYYYUtilsReadUInt64BigEndian(const uint8_t *bytes) {
    uint64_t value = 0;
    for (NSUInteger i = 0; i < 8; i++) {
        value = (value << 8) | (uint64_t)bytes[i];
    }
    return value;
}

static NSTimeInterval DYYYUtilsParseMVHDDuration(const uint8_t *bytes, NSUInteger length) {
    NSUInteger position = 0;
    while (position + 8 <= length) {
        uint64_t rawSize = DYYYUtilsReadUInt32BigEndian(bytes + position);
        NSUInteger header = 8;

        if (rawSize == 1) {
            if (position + 16 > length) {
                break;
            }
            rawSize = DYYYUtilsReadUInt64BigEndian(bytes + position + 8);
            header = 16;
        } else if (rawSize == 0) {
            rawSize = length - position;
        }

        if (rawSize < header || position + rawSize > length) {
            break;
        }

        const uint8_t *typePtr = bytes + position + 4;
        if (typePtr[0] == 'm' && typePtr[1] == 'v' && typePtr[2] == 'h' && typePtr[3] == 'd') {
            const uint8_t *payload = bytes + position + header;
            NSUInteger payloadLength = (NSUInteger)rawSize - header;
            if (payloadLength < 20) {
                break;
            }

            uint8_t version = payload[0];
            if (version == 0) {
                uint32_t timescale = DYYYUtilsReadUInt32BigEndian(payload + 12);
                uint32_t duration = DYYYUtilsReadUInt32BigEndian(payload + 16);
                if (timescale > 0) {
                    return (NSTimeInterval)duration / (NSTimeInterval)timescale;
                }
            } else if (version == 1) {
                if (payloadLength < 32) {
                    break;
                }
                uint32_t timescale = DYYYUtilsReadUInt32BigEndian(payload + 20);
                uint64_t duration = DYYYUtilsReadUInt64BigEndian(payload + 24);
                if (timescale > 0) {
                    return (NSTimeInterval)duration / (NSTimeInterval)timescale;
                }
            }
        }

        position += (NSUInteger)rawSize;
    }

    return 0;
}

static NSTimeInterval DYYYUtilsParseHEIFDuration(const uint8_t *bytes, NSUInteger length) {
    NSUInteger position = 0;
    while (position + 8 <= length) {
        uint64_t rawSize = DYYYUtilsReadUInt32BigEndian(bytes + position);
        NSUInteger header = 8;

        if (rawSize == 1) {
            if (position + 16 > length) {
                break;
            }
            rawSize = DYYYUtilsReadUInt64BigEndian(bytes + position + 8);
            header = 16;
        } else if (rawSize == 0) {
            rawSize = length - position;
        }

        if (rawSize < header || position + rawSize > length) {
            break;
        }

        const uint8_t *typePtr = bytes + position + 4;
        if (typePtr[0] == 'm' && typePtr[1] == 'o' && typePtr[2] == 'o' && typePtr[3] == 'v') {
            NSTimeInterval duration = DYYYUtilsParseMVHDDuration(bytes + position + header, (NSUInteger)rawSize - header);
            if (duration > 0) {
                return duration;
            }
        }

        position += (NSUInteger)rawSize;
    }

    return 0;
}

static NSTimeInterval DYYYUtilsHEIFDurationFromData(NSData *data) {
    if (!data || data.length < 16) {
        return 0;
    }
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    return DYYYUtilsParseHEIFDuration(bytes, data.length);
}

static NSURL *DYYYUtilsTemporaryGIFURLForSourceURL(NSURL *sourceURL) {
    NSString *baseName = sourceURL.lastPathComponent.stringByDeletingPathExtension;
    if (baseName.length == 0) {
        baseName = @"image";
    }
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.gif", baseName, [[NSUUID UUID] UUIDString]];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:path];
}

static BOOL DYYYUtilsWriteGIFUsingYYDecoder(YYImageDecoder *decoder, NSURL *gifURL, NSTimeInterval fallbackTotalDuration) {
    if (!decoder || decoder.frameCount == 0) {
        return NO;
    }

    NSUInteger frameCount = (NSUInteger)decoder.frameCount;
    CGFloat fallbackFrameDuration = 0;
    if (fallbackTotalDuration > 0 && frameCount > 0) {
        fallbackFrameDuration = fallbackTotalDuration / frameCount;
    }
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)gifURL, kUTTypeGIF, frameCount, NULL);
    if (!dest) {
        return NO;
    }

    NSDictionary *gifProperties = @{(__bridge NSString *)kCGImagePropertyGIFDictionary : @{(__bridge NSString *)kCGImagePropertyGIFLoopCount : @0}};
    CGImageDestinationSetProperties(dest, (__bridge CFDictionaryRef)gifProperties);

    BOOL hasFrame = NO;
    for (NSUInteger i = 0; i < frameCount; i++) {
        YYImageFrame *frame = [decoder frameAtIndex:i decodeForDisplay:YES];
        UIImage *image = frame.image;
        CGImageRef imageRef = image.CGImage;
        if (!imageRef) {
            continue;
        }

        CGFloat frameDuration = frame.duration;
        if ((!isfinite(frameDuration) || frameDuration <= 0) && fallbackFrameDuration > 0) {
            frameDuration = fallbackFrameDuration;
        }
        CGFloat delay = DYYYUtilsNormalizedDelay(frameDuration);
        NSDictionary *frameProps = @{(__bridge NSString *)kCGImagePropertyGIFDictionary : @{(__bridge NSString *)kCGImagePropertyGIFDelayTime : @(delay)}};
        CGImageDestinationAddImage(dest, imageRef, (__bridge CFDictionaryRef)frameProps);
        hasFrame = YES;
    }

    BOOL success = hasFrame ? CGImageDestinationFinalize(dest) : NO;
    CFRelease(dest);
    return success;
}

static BOOL DYYYUtilsConvertAnimatedDataWithYYDecoder(NSData *data, NSURL *gifURL, CGFloat scale) {
    YYImageDecoder *decoder = DYYYUtilsCreateYYDecoderWithData(data, scale);
    if (!decoder) {
        return NO;
    }
    return DYYYUtilsWriteGIFUsingYYDecoder(decoder, gifURL, 0);
}

static BOOL DYYYUtilsWriteStaticImageToGIF(UIImage *image, NSURL *gifURL) {
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return NO;
    }

    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)gifURL, kUTTypeGIF, 1, NULL);
    if (!dest) {
        return NO;
    }

    NSDictionary *gifProperties = @{(__bridge NSString *)kCGImagePropertyGIFDictionary : @{(__bridge NSString *)kCGImagePropertyGIFLoopCount : @0}};
    CGImageDestinationSetProperties(dest, (__bridge CFDictionaryRef)gifProperties);

    NSDictionary *frameProperties = @{(__bridge NSString *)kCGImagePropertyGIFDictionary : @{(__bridge NSString *)kCGImagePropertyGIFDelayTime : @(kDYYYUtilsDefaultFrameDelay)}};
    CGImageDestinationAddImage(dest, imageRef, (__bridge CFDictionaryRef)frameProperties);

    BOOL success = CGImageDestinationFinalize(dest);
    CFRelease(dest);
    return success;
}

@interface DYYYUtils ()
+ (NSString *)fallbackLocationFromIPAttribution:(AWEAwemeModel *)model;
+ (NSString *)displayLocationForGeoNamesError:(NSError *)error model:(AWEAwemeModel *)model;
@end

@implementation DYYYUtils

static const void *kCurrentIPRequestCityCodeKey = &kCurrentIPRequestCityCodeKey;

static NSString *DYYYJSONStringFromObject(id object) {
    if (!object) {
        return nil;
    }
    if (![NSJSONSerialization isValidJSONObject:object]) {
        return nil;
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (error || jsonData.length == 0) {
        return nil;
    }

    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

static void DYYYApplyDisplayLocationToLabel(UILabel *label, NSString *displayLocation, NSString *colorHexString) {
    if (!label) {
        return;
    }

    NSString *resolvedLocation = displayLocation ?: @"";
    resolvedLocation = [resolvedLocation stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (resolvedLocation.length == 0) {
        resolvedLocation = @"未知";
    }

    NSString *currentLabelText = label.text ?: @"";
    NSString *newText = nil;
    NSRange ipRange = [currentLabelText rangeOfString:@"IP属地："];
    if (ipRange.location != NSNotFound) {
        NSString *baseText = [currentLabelText substringToIndex:ipRange.location];
        newText = [NSString stringWithFormat:@"%@IP属地：%@", baseText, resolvedLocation];
    } else {
        if (currentLabelText.length > 0) {
            newText = [NSString stringWithFormat:@"%@  IP属地：%@", currentLabelText, resolvedLocation];
        } else {
            newText = [NSString stringWithFormat:@"IP属地：%@", resolvedLocation];
        }
    }

    if (newText.length > 0 && ![label.text isEqualToString:newText]) {
        label.text = newText;
    } else if (label.text.length == 0) {
        label.text = newText;
    }

    [DYYYUtils applyColorSettingsToLabel:label colorHexString:colorHexString];
}

+ (void)processAndApplyIPLocationToLabel:(UILabel *)label forModel:(AWEAwemeModel *)model withLabelColor:(NSString *)colorHexString {
    NSString *originalText = label.text ?: @"";
    NSString *cityCode = model.cityCode;

    if (cityCode.length == 0) {
        return;
    }

    objc_setAssociatedObject(label, kCurrentIPRequestCityCodeKey, cityCode, OBJC_ASSOCIATION_COPY_NONATOMIC);

    NSString *cityName = [CityManager.sharedInstance getCityNameWithCode:cityCode];
    NSString *provinceName = [CityManager.sharedInstance getProvinceNameWithCode:cityCode];

    if (!cityName || cityName.length == 0) {
        NSString *cacheKey = cityCode;
        static NSCache *geoNamesCache = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
          geoNamesCache = [[NSCache alloc] init];
          geoNamesCache.name = @"com.dyyy.geonames.cache";
          geoNamesCache.countLimit = 1000;
        });

        // 1 & 2. 查内存和磁盘缓存
        NSDictionary *cachedData = [geoNamesCache objectForKey:cacheKey];
        if (!cachedData) {
            NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
            NSString *geoNamesCacheDir = [cachesDir stringByAppendingPathComponent:@"DYYYGeoNamesCache"];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:geoNamesCacheDir]) {
                [fileManager createDirectoryAtPath:geoNamesCacheDir withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *cacheFilePath = [geoNamesCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", cacheKey]];
            if ([fileManager fileExistsAtPath:cacheFilePath]) {
                cachedData = [NSDictionary dictionaryWithContentsOfFile:cacheFilePath];
                if (cachedData) {
                    [geoNamesCache setObject:cachedData forKey:cacheKey];
                }
            }
        }

        // 3. 处理缓存数据或发起网络请求
        if (cachedData) {
            NSString *countryName = cachedData[@"countryName"];
            NSString *adminName1 = cachedData[@"adminName1"];
            NSString *localName = cachedData[@"name"];
            NSString *displayLocation = @"未知";

            if (countryName.length > 0) {
                if (adminName1.length > 0 && localName.length > 0 && ![countryName isEqualToString:@"中国"] && ![countryName isEqualToString:localName]) {
                    displayLocation = [NSString stringWithFormat:@"%@ %@ %@", countryName, adminName1, localName];
                } else if (localName.length > 0 && ![countryName isEqualToString:localName]) {
                    displayLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
                } else {
                    displayLocation = countryName;
                }
            } else if (localName.length > 0) {
                displayLocation = localName;
            }

            if (displayLocation.length == 0 || [displayLocation isEqualToString:@"未知"]) {
                NSString *fallbackLocation = [DYYYUtils fallbackLocationFromIPAttribution:model];
                if (fallbackLocation.length > 0) {
                    displayLocation = fallbackLocation;
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
              NSString *currentRequestCode = objc_getAssociatedObject(label, kCurrentIPRequestCityCodeKey);
              if (![currentRequestCode isEqualToString:cityCode]) {
                  return;
              }

              DYYYApplyDisplayLocationToLabel(label, displayLocation, colorHexString);
            });
        } else {
            [CityManager fetchLocationWithGeonameId:cityCode
                                  completionHandler:^(NSDictionary *locationInfo, NSError *error) {
                                    __block NSString *displayLocation = @"未知";

                                    if (error) {
                                        if ([error.domain isEqualToString:DYYYGeonamesErrorDomain]) {
                                            displayLocation = [DYYYUtils displayLocationForGeoNamesError:error model:model];
                                        } else {
                                            NSLog(@"[DYYY] GeoNames fetch failed: %@", error.localizedDescription);
                                            NSString *fallbackLocation = [DYYYUtils fallbackLocationFromIPAttribution:model];
                                            if (fallbackLocation.length > 0) {
                                                displayLocation = fallbackLocation;
                                            }
                                        }
                                    } else if (locationInfo) {
                                        BOOL shouldCacheLocation = NO;
                                        NSString *countryName = locationInfo[@"countryName"];
                                        NSString *adminName1 = locationInfo[@"adminName1"];
                                        NSString *localName = locationInfo[@"name"];

                                        if (countryName.length > 0) {
                                            if (adminName1.length > 0 && localName.length > 0 && ![countryName isEqualToString:@"中国"] && ![countryName isEqualToString:localName]) {
                                                displayLocation = [NSString stringWithFormat:@"%@ %@ %@", countryName, adminName1, localName];
                                            } else if (localName.length > 0 && ![countryName isEqualToString:localName]) {
                                                displayLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
                                            } else {
                                                displayLocation = countryName;
                                            }
                                            shouldCacheLocation = YES;
                                        } else if (localName.length > 0) {
                                            displayLocation = localName;
                                            shouldCacheLocation = YES;
                                        }

                                        if (displayLocation.length == 0 || [displayLocation isEqualToString:@"未知"]) {
                                            NSString *fallbackLocation = [DYYYUtils fallbackLocationFromIPAttribution:model];
                                            if (fallbackLocation.length > 0) {
                                                displayLocation = fallbackLocation;
                                            }
                                            shouldCacheLocation = NO;
                                        }

                                        if (shouldCacheLocation && ![displayLocation isEqualToString:@"未知"]) {
                                            [geoNamesCache setObject:locationInfo forKey:cacheKey];
                                            NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
                                            NSString *geoNamesCacheDir = [cachesDir stringByAppendingPathComponent:@"DYYYGeoNamesCache"];
                                            NSString *cacheFilePath = [geoNamesCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", cacheKey]];
                                            [locationInfo writeToFile:cacheFilePath atomically:YES];
                                        }
                                    }

                                    dispatch_async(dispatch_get_main_queue(), ^{
                                      NSString *currentRequestCode = objc_getAssociatedObject(label, kCurrentIPRequestCityCodeKey);
                                      if (![currentRequestCode isEqualToString:cityCode]) {
                                          return;
                                      }

                                      DYYYApplyDisplayLocationToLabel(label, displayLocation, colorHexString);
                                    });
                                  }];
        }
    }

    else if (![originalText containsString:cityName]) {
        BOOL isDirectCity = [provinceName isEqualToString:cityName] || ([cityCode hasPrefix:@"11"] || [cityCode hasPrefix:@"12"] || [cityCode hasPrefix:@"31"] || [cityCode hasPrefix:@"50"]);
        if (!model.ipAttribution) {
            if (isDirectCity) {
                label.text = [NSString stringWithFormat:@"%@  IP属地：%@", originalText, cityName];
            } else {
                label.text = [NSString stringWithFormat:@"%@  IP属地：%@ %@", originalText, provinceName, cityName];
            }
        } else {
            BOOL containsProvince = [originalText containsString:provinceName];
            BOOL containsCity = [originalText containsString:cityName];
            if (containsProvince && !isDirectCity && !containsCity) {
                label.text = [NSString stringWithFormat:@"%@ %@", originalText, cityName];
            } else if (isDirectCity && !containsCity) {
                label.text = [NSString stringWithFormat:@"%@  IP属地：%@", originalText, cityName];
            }
        }
        [DYYYUtils applyColorSettingsToLabel:label colorHexString:colorHexString];
    }
}

+ (NSString *)fallbackLocationFromIPAttribution:(AWEAwemeModel *)model {
    if (!model) {
        return nil;
    }

    NSString *rawAttribution = nil;
    @try {
        rawAttribution = model.ipAttribution;
    } @catch (NSException *exception) {
        return nil;
    }

    if (![rawAttribution isKindOfClass:[NSString class]]) {
        return nil;
    }

    NSString *trimmedValue = [rawAttribution stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedValue.length == 0) {
        return nil;
    }

    NSArray<NSString *> *prefixes = @[ @"IP属地：", @"IP属地:", @"IP 属地：", @"IP 属地:" ];
    for (NSString *prefix in prefixes) {
        if ([trimmedValue hasPrefix:prefix]) {
            trimmedValue = [trimmedValue substringFromIndex:prefix.length];
            break;
        }
    }

    trimmedValue = [trimmedValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    return trimmedValue.length > 0 ? trimmedValue : nil;
}

+ (NSString *)displayLocationForGeoNamesError:(NSError *)error model:(AWEAwemeModel *)model {
    NSString *fallbackLocation = [DYYYUtils fallbackLocationFromIPAttribution:model];
    if (fallbackLocation.length > 0) {
        return fallbackLocation;
    }

    NSDictionary *status = error.userInfo[DYYYGeonamesStatusUserInfoKey];
    if ([status isKindOfClass:[NSDictionary class]]) {
        NSString *statusJSON = DYYYJSONStringFromObject(@{ @"status" : status });
        if (statusJSON.length > 0) {
            return [NSString stringWithFormat:@"未知 %@", statusJSON];
        }
    }

    NSString *message = error.localizedDescription ?: @"";
    message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (message.length > 0) {
        return [NSString stringWithFormat:@"未知 %@", message];
    }

    return @"未知";
}

#pragma mark - Public UI Utilities (公共 UI/窗口/控制器 工具)

+ (UIWindow *)getActiveWindow {
    UIWindow *fallbackWindow = [UIApplication sharedApplication].keyWindow ?: [UIApplication sharedApplication].delegate.window ?: [UIApplication sharedApplication].windows.firstObject;

    if (@available(iOS 13.0, *)) {
        UIWindowScene *activeScene = nil, *inactiveScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UISceneActivationState state = scene.activationState;
                if (state == UISceneActivationStateForegroundActive) {
                    activeScene = (UIWindowScene *)scene;
                    break;
                } else if (state == UISceneActivationStateForegroundInactive) {
                    if (inactiveScene == nil) {
                        inactiveScene = (UIWindowScene *)scene;
                    }
                }
            }
        }

        UIWindowScene *targetScene = activeScene ?: inactiveScene;
        if (targetScene) {
            if (@available(iOS 15.0, *)) {
                return targetScene.keyWindow ?: targetScene.windows.firstObject ?: fallbackWindow;
            } else {
                UIWindow *firstVisibleWindow = nil;

                for (UIWindow *window in targetScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    } else if (firstVisibleWindow == nil && !window.isHidden && window.rootViewController) {
                        firstVisibleWindow = window;
                    }
                }

                return firstVisibleWindow ?: targetScene.windows.firstObject ?: fallbackWindow;
            }
        }
    }

    return fallbackWindow;
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
    if (!targetClass || !vc)
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

+ (NSArray<__kindof UIView *> *)findAllSubviewsOfClass:(Class)targetClass inContainer:(id)container {
    if (!targetClass || !container) {
        return @[];
    }

    UIView *startView = nil;
    if ([container isKindOfClass:[UIView class]]) {
        startView = (UIView *)container;
    } else if ([container isKindOfClass:[UIViewController class]]) {
        startView = ((UIViewController *)container).view;
    }

    NSMutableArray *resultViews = [NSMutableArray array];
    [self _traverseViewHierarchy:startView
                        forClass:targetClass
                      usingBlock:^BOOL(UIView *foundView) {
                        [resultViews addObject:foundView];
                        return NO;
                      }];

    return [resultViews copy];
}

+ (__kindof UIView *)findSubviewOfClass:(Class)targetClass inContainer:(id)container {
    if (!targetClass || !container) {
        return nil;
    }

    UIView *startView = nil;
    if ([container isKindOfClass:[UIView class]]) {
        startView = (UIView *)container;
    } else if ([container isKindOfClass:[UIViewController class]]) {
        startView = ((UIViewController *)container).view;
    }

    __block UIView *resultView = nil;
    [self _traverseViewHierarchy:startView
                        forClass:targetClass
                      usingBlock:^BOOL(UIView *foundView) {
                        resultView = foundView;
                        return YES;
                      }];

    return resultView;
}

+ (__kindof UIView *)nearestCommonSuperviewOfViews:(NSArray<UIView *> *)views {
    if (views.count == 0)
        return nil;
    if (views.count == 1)
        return views.firstObject.superview;

    UIView *commonSuperview = views.firstObject;
    for (UIView *view in views) {
        commonSuperview = [self _nearestCommonSuperviewOfView:commonSuperview andView:view];
        if (!commonSuperview) break;
    }

    return commonSuperview;
}

+ (BOOL)containsSubviewOfClass:(Class)targetClass inContainer:(id)container {
    return [self findSubviewOfClass:targetClass inContainer:container] != nil;
}

+ (void)applyBlurEffectToView:(UIView *)view transparency:(float)userTransparency blurViewTag:(NSInteger)tag {
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

    SEL isLightThemeSEL = NSSelectorFromString(@"isLightTheme");
    if ([themeManagerClass respondsToSelector:isLightThemeSEL]) {
        BOOL isLightTheme = ((BOOL (*)(id, SEL))objc_msgSend)(themeManagerClass, isLightThemeSEL);
        return !isLightTheme;
    }

    id themeManager = nil;
    SEL sharedManagerSEL = NSSelectorFromString(@"sharedManager");
    SEL sharedInstanceSEL = NSSelectorFromString(@"sharedInstance");
    if ([themeManagerClass respondsToSelector:sharedManagerSEL]) {
        themeManager = [themeManagerClass performSelector:sharedManagerSEL];
    } else if ([themeManagerClass respondsToSelector:sharedInstanceSEL]) {
        themeManager = [themeManagerClass performSelector:sharedInstanceSEL];
    }

    if (themeManager) {
        if ([themeManager respondsToSelector:isLightThemeSEL]) {
            BOOL isLightTheme = ((BOOL (*)(id, SEL))objc_msgSend)(themeManager, isLightThemeSEL);
            return !isLightTheme;
        }

        @try {
            id lightThemeValue = [themeManager valueForKey:@"isLightTheme"];
            if ([lightThemeValue respondsToSelector:@selector(boolValue)]) {
                return ![lightThemeValue boolValue];
            }
        } @catch (NSException *exception) {
        }
    }

    return NO;
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

#pragma mark - Public Media Helper Methods (公共媒体工具方法)

+ (NSString *)detectFileFormat:(NSURL *)fileURL {
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:nil];
    if (!fileData || fileData.length < 12) {
        return @"unknown";
    }

    const unsigned char *bytes = [fileData bytes];

    if (bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' && bytes[3] == 'F' && bytes[8] == 'W' && bytes[9] == 'E' && bytes[10] == 'B' && bytes[11] == 'P') {
        return @"webp";
    }

    if (bytes[4] == 'f' && bytes[5] == 't' && bytes[6] == 'y' && bytes[7] == 'p') {
        if (fileData.length >= 16) {
            if (bytes[8] == 'h' && bytes[9] == 'e' && bytes[10] == 'i' && bytes[11] == 'c') {
                return @"heic";
            }
            if (bytes[8] == 'h' && bytes[9] == 'e' && bytes[10] == 'i' && bytes[11] == 'f') {
                return @"heif";
            }
            return @"heif";
        }
    }

    if (bytes[0] == 'G' && bytes[1] == 'I' && bytes[2] == 'F') {
        return @"gif";
    }

    if (bytes[0] == 0x89 && bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G') {
        return @"png";
    }

    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return @"jpeg";
    }

    return @"unknown";
}

+ (NSString *)mediaTypeDescription:(MediaType)mediaType {
    switch (mediaType) {
        case MediaTypeVideo:
            return @"视频";
        case MediaTypeImage:
            return @"图片";
        case MediaTypeAudio:
            return @"音频";
        case MediaTypeHeic:
            return @"表情包";
        default:
            return @"文件";
    }
}

+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    if (!image || size.width <= 0 || size.height <= 0) {
        return image;
    }
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage ?: image;
}

+ (CGRect)rectForImageAspectFit:(CGSize)imageSize inSize:(CGSize)containerSize {
    if (imageSize.width <= 0 || imageSize.height <= 0 || containerSize.width <= 0 || containerSize.height <= 0) {
        return CGRectZero;
    }

    CGFloat hScale = containerSize.width / imageSize.width;
    CGFloat vScale = containerSize.height / imageSize.height;
    CGFloat scale = MIN(hScale, vScale);

    CGFloat newWidth = imageSize.width * scale;
    CGFloat newHeight = imageSize.height * scale;

    CGFloat x = (containerSize.width - newWidth) / 2.0;
    CGFloat y = (containerSize.height - newHeight) / 2.0;

    return CGRectMake(x, y, newWidth, newHeight);
}

+ (CGAffineTransform)transformForAssetTrack:(AVAssetTrack *)track targetSize:(CGSize)targetSize {
    if (!track || targetSize.width <= 0 || targetSize.height <= 0) {
        return CGAffineTransformIdentity;
    }

    CGSize trackSize = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
    trackSize = CGSizeMake(fabs(trackSize.width), fabs(trackSize.height));
    if (trackSize.width <= 0 || trackSize.height <= 0) {
        return track.preferredTransform;
    }

    CGFloat xScale = targetSize.width / trackSize.width;
    CGFloat yScale = targetSize.height / trackSize.height;
    CGFloat scale = MIN(xScale, yScale);

    CGAffineTransform transform = track.preferredTransform;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(scale, scale));

    CGFloat xOffset = (targetSize.width - trackSize.width * scale) / 2.0;
    CGFloat yOffset = (targetSize.height - trackSize.height * scale) / 2.0;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(xOffset, yOffset));

    return transform;
}

+ (CGAffineTransform)transformForImage:(UIImage *)image targetSize:(CGSize)targetSize {
    if (!image || targetSize.width <= 0 || targetSize.height <= 0 || image.size.width <= 0 || image.size.height <= 0) {
        return CGAffineTransformIdentity;
    }

    CGSize imageSize = image.size;
    CGFloat xScale = targetSize.width / imageSize.width;
    CGFloat yScale = targetSize.height / imageSize.height;
    CGFloat scale = MIN(xScale, yScale);

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, scale, scale);

    CGFloat xOffset = (targetSize.width - imageSize.width * scale) / 2.0;
    CGFloat yOffset = (targetSize.height - imageSize.height * scale) / 2.0;
    transform = CGAffineTransformTranslate(transform, xOffset / scale, yOffset / scale);

    return transform;
}

+ (BOOL)isBDImageWithHeifURL:(UIImage *)image {
    if (!image) {
        return NO;
    }

    if ([NSStringFromClass([image class]) containsString:@"BDImage"]) {
        if ([image respondsToSelector:@selector(bd_webURL)]) {
            NSURL *webURL = [image performSelector:@selector(bd_webURL)];
            if (webURL) {
                NSString *urlString = webURL.absoluteString;
                return [urlString containsString:@".heif"] || [urlString containsString:@".heic"];
            }
        }
    }

    return NO;
}

+ (NSArray *)getImagesFromYYAnimatedImageView:(YYAnimatedImageView *)imageView {
    if (!imageView || !imageView.image) {
        return nil;
    }
    if ([imageView.image respondsToSelector:@selector(images)]) {
        return [imageView.image performSelector:@selector(images)];
    }
    return nil;
}

+ (CGFloat)getDurationFromYYAnimatedImageView:(YYAnimatedImageView *)imageView {
    if (!imageView || !imageView.image) {
        return 0;
    }

    UIImage *image = imageView.image;

    if (image.images.count > 0) {
        NSTimeInterval builtInDuration = image.duration;
        if (builtInDuration <= 0) {
            builtInDuration = image.images.count * kDYYYUtilsDefaultFrameDelay;
        }
        return builtInDuration;
    }

    SEL frameCountSEL = NSSelectorFromString(@"animatedImageFrameCount");
    SEL frameDurationSEL = NSSelectorFromString(@"animatedImageDurationAtIndex:");
    if ([image respondsToSelector:frameCountSEL] && [image respondsToSelector:frameDurationSEL]) {
        NSUInteger frameCount = ((NSUInteger(*)(id, SEL))objc_msgSend)(image, frameCountSEL);
        if (frameCount > 0) {
            CGFloat totalDuration = 0;
            for (NSUInteger i = 0; i < frameCount; i++) {
                CGFloat frameDuration = ((CGFloat(*)(id, SEL, NSUInteger))objc_msgSend)(image, frameDurationSEL, i);
                totalDuration += frameDuration > 0 ? frameDuration : kDYYYUtilsDefaultFrameDelay;
            }
            if (totalDuration > 0) {
                return totalDuration;
            }
        }
    }

    SEL dataSEL = NSSelectorFromString(@"animatedImageData");
    NSData *animatedData = nil;
    if ([image respondsToSelector:dataSEL]) {
        animatedData = ((NSData *(*)(id, SEL))objc_msgSend)(image, dataSEL);
    }
    if (animatedData.length > 0) {
        CGFloat scale = image.scale > 0 ? image.scale : 1.0f;
        YYImageDecoder *decoder = DYYYUtilsCreateYYDecoderWithData(animatedData, scale);
        CGFloat decoderDuration = DYYYUtilsTotalDurationFromYYDecoder(decoder);
        if (decoderDuration > 0) {
            return decoderDuration;
        }
    }

    if ([image respondsToSelector:@selector(duration)]) {
        NSTimeInterval duration = image.duration;
        if (duration > 0) {
            return duration;
        }
    }

    id durationValue = [image valueForKey:@"duration"];
    return [durationValue respondsToSelector:@selector(floatValue)] ? [durationValue floatValue] : 0;
}

+ (BOOL)framesFromAnimatedData:(NSData *)data
                         scale:(CGFloat)scale
                        images:(NSArray<UIImage *> *_Nullable *)images
                 totalDuration:(CGFloat *_Nullable)totalDuration {
    if (images) {
        *images = nil;
    }
    if (totalDuration) {
        *totalDuration = 0;
    }
    if (!data.length) {
        return NO;
    }

    CGFloat resolvedScale = scale > 0 ? scale : 1.0f;
    YYImageDecoder *decoder = DYYYUtilsCreateYYDecoderWithData(data, resolvedScale);
    if (!decoder || decoder.frameCount == 0) {
        return NO;
    }

    NSMutableArray<UIImage *> *decodedFrames = [NSMutableArray arrayWithCapacity:decoder.frameCount];
    CGFloat durationAccumulator = 0;
    for (NSUInteger i = 0; i < decoder.frameCount; i++) {
        YYImageFrame *frame = [decoder frameAtIndex:i decodeForDisplay:YES];
        if (!frame || !frame.image) {
            continue;
        }
        [decodedFrames addObject:frame.image];
        durationAccumulator += DYYYUtilsNormalizedDelay(frame.duration);
    }

    if (decodedFrames.count == 0) {
        return NO;
    }

    if (images) {
        *images = [decodedFrames copy];
    }
    if (totalDuration) {
        *totalDuration = durationAccumulator > 0 ? durationAccumulator : decodedFrames.count * kDYYYUtilsDefaultFrameDelay;
    }

    return YES;
}

+ (BOOL)createGIFWithImages:(NSArray *)images duration:(CGFloat)duration path:(NSString *)path progress:(void (^)(float progress))progressBlock {
    if (images.count == 0 || path.length == 0) {
        return NO;
    }

    CGFloat safeDuration = duration > 0 ? duration : (0.1f * images.count);
    float frameDuration = safeDuration / images.count;
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], kUTTypeGIF, images.count, NULL);
    if (!destination) {
        return NO;
    }

    NSDictionary *gifProperties = @{(__bridge NSString *)kCGImagePropertyGIFDictionary : @{(__bridge NSString *)kCGImagePropertyGIFLoopCount : @0}};
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);

    for (NSUInteger i = 0; i < images.count; i++) {
        UIImage *image = images[i];
        NSDictionary *frameProperties = @{(__bridge NSString *)kCGImagePropertyGIFDictionary : @{(__bridge NSString *)kCGImagePropertyGIFDelayTime : @(frameDuration)}};
        CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        if (progressBlock) {
            progressBlock((float)(i + 1) / images.count);
        }
    }

    BOOL success = CGImageDestinationFinalize(destination);
    CFRelease(destination);
    return success;
}

+ (void)saveGIFToPhotoLibrary:(NSString *)path completion:(void (^)(BOOL success, NSError *error))completion {
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    [[PHPhotoLibrary sharedPhotoLibrary]
        performChanges:^{
          PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
          [request addResourceWithType:PHAssetResourceTypePhoto fileURL:fileURL options:nil];
        }
        completionHandler:^(BOOL success, NSError *_Nullable error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success, error);
            }
            NSError *removeError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&removeError];
            if (removeError) {
                NSLog(@"删除临时GIF文件失败: %@", removeError);
            }
          });
        }];
}

+ (void)saveGifToPhotoLibrary:(NSURL *)gifURL completion:(void (^)(BOOL success))completion {
    [[PHPhotoLibrary sharedPhotoLibrary]
        performChanges:^{
          NSData *gifData = [NSData dataWithContentsOfURL:gifURL];
          PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
          PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
          options.uniformTypeIdentifier = @"com.compuserve.gif";
          [request addResourceWithType:PHAssetResourceTypePhoto data:gifData options:options];
        }
        completionHandler:^(BOOL success, NSError *_Nullable error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) {
                [DYYYUtils showToast:@"保存失败"];
            }
            [[NSFileManager defaultManager] removeItemAtPath:gifURL.path error:nil];
            if (completion) {
                completion(success);
            }
          });
        }];
}

+ (BOOL)videoHasAudio:(NSURL *)videoURL {
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    return audioTracks.count > 0;
}

+ (void)downloadAudioAndMergeWithVideo:(NSURL *)videoURL
                              audioURL:(NSURL *)audioURL
                            completion:(void (^)(BOOL success, NSURL *mergedURL))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSData *audioData = [NSData dataWithContentsOfURL:audioURL];
      if (!audioData) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(NO, nil);
            }
          });
          return;
      }

      NSString *audioPath = [DYYYUtils cachePathForFilename:[NSString stringWithFormat:@"temp_%@", audioURL.lastPathComponent]];
      NSURL *audioFile = [NSURL fileURLWithPath:audioPath];
      if (![audioData writeToURL:audioFile atomically:YES]) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(NO, nil);
            }
          });
          return;
      }

      [self mergeVideo:videoURL
             withAudio:audioFile
            completion:^(BOOL success, NSURL *mergedURL) {
              [[NSFileManager defaultManager] removeItemAtURL:audioFile error:nil];
              dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(success, mergedURL);
                }
              });
            }];
    });
}

+ (void)mergeVideo:(NSURL *)videoURL
         withAudio:(NSURL *)audioURL
        completion:(void (^)(BOOL success, NSURL *mergedURL))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
      AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:audioURL options:nil];
      AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
      AVAssetTrack *audioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
      if (!videoTrack || !audioTrack) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(NO, nil);
            }
          });
          return;
      }

      AVMutableComposition *composition = [AVMutableComposition composition];
      AVMutableCompositionTrack *compVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
      [compVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];

      AVMutableCompositionTrack *compAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
      [compAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:nil];

      NSString *outputPath = [DYYYUtils cachePathForFilename:[NSString stringWithFormat:@"merged_%@", videoURL.lastPathComponent]];
      NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
      if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
          [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
      }

      AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
      exportSession.outputURL = outputURL;
      exportSession.outputFileType = AVFileTypeMPEG4;
      [exportSession exportAsynchronouslyWithCompletionHandler:^{
        BOOL success = exportSession.status == AVAssetExportSessionStatusCompleted;
        if (!success) {
            NSLog(@"Merge export failed: %@", exportSession.error);
        } else {
            [[NSFileManager defaultManager] removeItemAtURL:videoURL error:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
          if (completion) {
              completion(success, success ? outputURL : nil);
          }
        });
      }];
    });
}

+ (void)convertWebpToGifSafely:(NSURL *)webpURL completion:(void (^)(NSURL *gifURL, BOOL success))completion {
    if (!webpURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (completion) {
              completion(nil, NO);
          }
        });
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSData *webpData = [NSData dataWithContentsOfURL:webpURL options:NSDataReadingMappedIfSafe error:nil];
      if (!webpData) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, NO);
            }
          });
          return;
      }

      NSURL *gifURL = DYYYUtilsTemporaryGIFURLForSourceURL(webpURL);
      [[NSFileManager defaultManager] removeItemAtURL:gifURL error:nil];

      BOOL success = DYYYUtilsConvertAnimatedDataWithYYDecoder(webpData, gifURL, 1.0f);
      if (!success) {
          UIImage *fallbackImage = [UIImage imageWithData:webpData];
          if (fallbackImage) {
              success = DYYYUtilsWriteStaticImageToGIF(fallbackImage, gifURL);
          }
      }

      if (!success) {
          [[NSFileManager defaultManager] removeItemAtURL:gifURL error:nil];
      }

      dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion(success ? gifURL : nil, success);
        }
      });
    });
}

+ (void)convertHeicToGif:(NSURL *)heicURL completion:(void (^)(NSURL *gifURL, BOOL success))completion {
    if (!heicURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (completion) {
              completion(nil, NO);
          }
        });
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSData *heicData = [NSData dataWithContentsOfURL:heicURL options:NSDataReadingMappedIfSafe error:nil];
      NSTimeInterval heifDuration = DYYYUtilsHEIFDurationFromData(heicData);
      NSURL *gifURL = DYYYUtilsTemporaryGIFURLForSourceURL(heicURL);
      [[NSFileManager defaultManager] removeItemAtURL:gifURL error:nil];

      BOOL success = NO;
      NSString *failureReason = nil;

      if (!heicData || heicData.length == 0) {
          failureReason = @"读取HEIC数据失败或数据为空";
      } else {
          YYImageDecoder *decoder = DYYYUtilsCreateYYDecoderWithData(heicData, 1.0f);
          if (!decoder) {
              failureReason = @"无法通过YYImageDecoder解析HEIC数据，可能是资源不是动图或SDK不可用";
          } else if (decoder.frameCount == 0) {
              failureReason = @"YYImageDecoder未解析到任何帧，HEIC资源可能不是动图";
          } else {
              success = DYYYUtilsWriteGIFUsingYYDecoder(decoder, gifURL, heifDuration);
              if (!success) {
                  failureReason = @"YYImageDecoder写入GIF失败，可能是图像数据损坏或磁盘空间不足";
              }
          }
      }

      if (!success) {
          [[NSFileManager defaultManager] removeItemAtURL:gifURL error:nil];
          if (failureReason.length > 0) {
              NSLog(@"[DYYY] convertHeicToGif失败: %@", failureReason);
          }
      }

      dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion(success ? gifURL : nil, success);
        }
      });
    });
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
    if (!label)
        return;

    NSAttributedString *existingAttributed = nil;
    if ([label.attributedText isKindOfClass:[NSAttributedString class]] && label.attributedText.length > 0) {
        existingAttributed = label.attributedText;
    }

    NSString *textSignature = existingAttributed.string;
    if (textSignature.length == 0) {
        NSString *fallbackText = label.text ?: @"";
        textSignature = fallbackText;
    }

    if (textSignature.length == 0) {
        label.attributedText = [[NSAttributedString alloc] initWithString:@""];
        return;
    }

    UIFont *font = label.font ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
    NSString *fontName = font.fontName ?: @"";
    CGFloat fontSize = font.pointSize;

    NSString *normalizedKey = DYYYNormalizedColorKey(colorHexString);
    BOOL allowCache = normalizedKey.length == 0 ? YES : !DYYYColorKeyIsDynamic(normalizedKey);

    DYYYLabelColorState *state = objc_getAssociatedObject(label, &kLabelColorStateKey);
    if (allowCache && state && DYYYStringsEqual(state.textSignature, textSignature) && DYYYStringsEqual(state.colorKey, normalizedKey ?: @"") &&
        DYYYStringsEqual(state.fontName, fontName) && fabs(state.fontSize - fontSize) <= 0.01) {
        return;
    }

    NSMutableAttributedString *attributedText = nil;
    if (existingAttributed) {
        attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:existingAttributed];
    } else {
        attributedText = [[NSMutableAttributedString alloc] initWithString:textSignature];
    }

    NSRange fullRange = NSMakeRange(0, attributedText.length);
    [attributedText removeAttribute:NSForegroundColorAttributeName range:fullRange];
    [attributedText removeAttribute:NSStrokeColorAttributeName range:fullRange];
    [attributedText removeAttribute:NSStrokeWidthAttributeName range:fullRange];
    [attributedText removeAttribute:NSShadowAttributeName range:fullRange];

    if (![attributedText attribute:NSFontAttributeName atIndex:0 effectiveRange:nil] && font) {
        [attributedText addAttribute:NSFontAttributeName value:font range:fullRange];
    }

    if (!colorHexString || colorHexString.length == 0) {
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
    } else {
        CGSize maxTextSize = CGSizeMake(CGFLOAT_MAX, label.bounds.size.height);
        CGRect textRect =
            [attributedText boundingRectWithSize:maxTextSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
        CGFloat actualTextWidth = MAX(1.0, ceil(textRect.size.width));

        UIColor *finalTextColor = [self colorFromSchemeHexString:colorHexString targetWidth:actualTextWidth];

        if (finalTextColor) {
            [attributedText addAttribute:NSForegroundColorAttributeName value:finalTextColor range:fullRange];
        } else {
            [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
        }
    }

    label.attributedText = attributedText;

    if (!state) {
        state = [[DYYYLabelColorState alloc] init];
        objc_setAssociatedObject(label, &kLabelColorStateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    state.textSignature = [textSignature copy];
    state.colorKey = normalizedKey ?: @"";
    state.fontName = fontName;
    state.fontSize = fontSize;
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

/*
 * @brief 私有辅助方法：计算两个指定视图的最近公共父视图。
 * @param first 第一个视图。
 * @param second 第二个视图。
 * @return 两个视图的最近公共父视图，如果不存在则返回 nil。
 */
+ (__kindof UIView *)_nearestCommonSuperviewOfView:(UIView *)first andView:(UIView *)second {
    NSMutableSet *ancestors = [NSMutableSet set];
    UIView *view = first;
    while (view) {
        [ancestors addObject:view];
        view = view.superview;
    }

    view = second;
    while (view) {
        if ([ancestors containsObject:view]) {
            return view;
        }
        view = view.superview;
    }

    return nil;
}

/**
 * @brief 私有辅助方法：核心遍历引擎，使用 block 回调处理匹配的视图。
 * @param view 要遍历的根视图。
 * @param targetClass 要匹配的类。
 * @param block 找到匹配视图时执行的回调。返回 YES 可立即中止遍历。
 * @return 如果遍历被中止，则返回 YES。
 */
+ (BOOL)_traverseViewHierarchy:(UIView *)view forClass:(Class)targetClass usingBlock:(BOOL (^)(UIView *foundView))block {
    if (!view || !targetClass || !block) {
        return NO;
    }

    if ([view isKindOfClass:targetClass]) {
        if (block(view)) {
            return YES;
        }
    }

    for (UIView *subview in view.subviews) {
        if ([self _traverseViewHierarchy:subview forClass:targetClass usingBlock:block]) {
            return YES;
        }
    }

    return NO;
}

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

#pragma mark - Version Utilities

+ (NSComparisonResult)compareVersion:(NSString *)lhs toVersion:(NSString *)rhs {
    if (lhs.length == 0 && rhs.length == 0) {
        return NSOrderedSame;
    }
    if (lhs.length == 0) {
        return NSOrderedAscending;
    }
    if (rhs.length == 0) {
        return NSOrderedDescending;
    }

    NSArray<NSString *> *lhsComponents = [lhs componentsSeparatedByString:@"."];
    NSArray<NSString *> *rhsComponents = [rhs componentsSeparatedByString:@"."];
    NSUInteger maxCount = MAX(lhsComponents.count, rhsComponents.count);

    for (NSUInteger idx = 0; idx < maxCount; idx++) {
        NSInteger lhsValue = (idx < lhsComponents.count) ? lhsComponents[idx].integerValue : 0;
        NSInteger rhsValue = (idx < rhsComponents.count) ? rhsComponents[idx].integerValue : 0;

        if (lhsValue < rhsValue) {
            return NSOrderedAscending;
        }
        if (lhsValue > rhsValue) {
            return NSOrderedDescending;
        }
    }

    return NSOrderedSame;
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

UIViewController *findViewControllerOfClass(UIViewController *vc, Class targetClass) {
    if (!vc || !targetClass)
        return nil;
    return [DYYYUtils findViewControllerOfClass:targetClass inViewController:vc];
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
