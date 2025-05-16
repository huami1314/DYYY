#import "DYYYManager.h"
#import <CoreAudioTypes/CoreAudioTypes.h>
#import <CoreMedia/CMMetadata.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <Photos/Photos.h>
#import <libwebp/decode.h>
#import <libwebp/demux.h>
#import <libwebp/mux.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "DYYYToast.h"

@interface DYYYManager () {
  AVAssetExportSession *session;
  AVURLAsset *asset;
  AVAssetReader *reader;
  AVAssetWriter *writer;
  dispatch_queue_t queue;
  dispatch_group_t group;
}
@end

@interface DYYYManager () <NSURLSessionDownloadDelegate>
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, NSURLSessionDownloadTask *> *downloadTasks;
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, DYYYToast *> *progressViews;
@property(nonatomic, strong) NSOperationQueue *downloadQueue;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *taskProgressMap; // 添加进度映射
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, void (^)(BOOL success, NSURL *fileURL)>
        *completionBlocks; // 添加完成回调存储
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *mediaTypeMap; // 添加媒体类型映射

// 批量下载相关属性
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *>
    *downloadToBatchMap; // 下载ID到批量ID的映射
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *batchCompletedCountMap; // 批量ID到已完成数量的映射
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *batchSuccessCountMap; // 批量ID到成功数量的映射
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *batchTotalCountMap; // 批量ID到总数量的映射
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, void (^)(NSInteger current, NSInteger total)
                        > *batchProgressBlocks; // 批量进度回调
@property(nonatomic, strong)
    NSMutableDictionary<NSString *,
                        void (^)(NSInteger successCount, NSInteger totalCount)>
        *batchCompletionBlocks; // 批量完成回调
@end

@implementation DYYYManager

+ (instancetype)shared {
  static DYYYManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _fileLinks = [NSMutableDictionary dictionary];
    _downloadTasks = [NSMutableDictionary dictionary];
    _progressViews = [NSMutableDictionary dictionary];
    _downloadQueue = [[NSOperationQueue alloc] init];
    _downloadQueue.maxConcurrentOperationCount =
        3; // A maximum of 3 concurrent downloads
    _taskProgressMap =
        [NSMutableDictionary dictionary]; // Initialize progress mapping
    _completionBlocks =
        [NSMutableDictionary dictionary]; // Initialize completion blocks
    _mediaTypeMap =
        [NSMutableDictionary dictionary]; // Initialize media type mapping

    // 初始化批量下载相关字典
    _downloadToBatchMap = [NSMutableDictionary dictionary];
    _batchCompletedCountMap = [NSMutableDictionary dictionary];
    _batchSuccessCountMap = [NSMutableDictionary dictionary];
    _batchTotalCountMap = [NSMutableDictionary dictionary];
    _batchProgressBlocks = [NSMutableDictionary dictionary];
    _batchCompletionBlocks = [NSMutableDictionary dictionary];
  }
  return self;
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

+ (void)saveMedia:(NSURL *)mediaURL
        mediaType:(MediaType)mediaType
       completion:(void (^)(void))completion {
  if (mediaType == MediaTypeAudio) {
    return;
  }

  [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    if (status == PHAuthorizationStatusAuthorized) {
      // 如果是表情包类型，先检查实际格式
      if (mediaType == MediaTypeHeic) {
        // 检测文件的实际格式
        NSString *actualFormat = [self detectFileFormat:mediaURL];

        if ([actualFormat isEqualToString:@"webp"]) {
          // WebP格式处理
          [self convertWebpToGifSafely:mediaURL
                            completion:^(NSURL *gifURL, BOOL success) {
                              if (success && gifURL) {
                                [self
                                    saveGifToPhotoLibrary:gifURL
                                                mediaType:mediaType
                                               completion:^{
                                                 // 清理原始文件
                                                 [[NSFileManager defaultManager]
                                                     removeItemAtPath:mediaURL
                                                                          .path
                                                                error:nil];
                                                 if (completion) {
                                                   completion();
                                                 }
                                               }];
                              } else {
                                [self showToast:@"转换失败"];
                                // 清理临时文件
                                [[NSFileManager defaultManager]
                                    removeItemAtPath:mediaURL.path
                                               error:nil];
                                if (completion) {
                                  completion();
                                }
                              }
                            }];
        } else if ([actualFormat isEqualToString:@"heic"] ||
                   [actualFormat isEqualToString:@"heif"]) {
          // HEIC/HEIF格式处理
          [self convertHeicToGif:mediaURL
                      completion:^(NSURL *gifURL, BOOL success) {
                        if (success && gifURL) {
                          [self saveGifToPhotoLibrary:gifURL
                                            mediaType:mediaType
                                           completion:^{
                                             // 清理原始文件
                                             [[NSFileManager defaultManager]
                                                 removeItemAtPath:mediaURL.path
                                                            error:nil];
                                             if (completion) {
                                               completion();
                                             }
                                           }];
                        } else {
                          [self showToast:@"转换失败"];
                          // 清理临时文件
                          [[NSFileManager defaultManager]
                              removeItemAtPath:mediaURL.path
                                         error:nil];
                          if (completion) {
                            completion();
                          }
                        }
                      }];
        } else if ([actualFormat isEqualToString:@"gif"]) {
          // 已经是GIF格式，直接保存
          [self saveGifToPhotoLibrary:mediaURL
                            mediaType:mediaType
                           completion:completion];
        } else {
          // 其他格式，尝试作为普通图像保存
          [[PHPhotoLibrary sharedPhotoLibrary]
              performChanges:^{
                UIImage *image =
                    [UIImage imageWithContentsOfFile:mediaURL.path];
                if (image) {
                  [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                }
              }
              completionHandler:^(BOOL success, NSError *_Nullable error) {
                if (success) {
                  if (completion) {
                    completion();
                  }
                } else {
                  [self showToast:@"保存失败"];
                }
                // 不管成功失败都清理临时文件
                [[NSFileManager defaultManager] removeItemAtPath:mediaURL.path
                                                           error:nil];
              }];
        }
      } else {
        // 非表情包类型的正常保存流程
        [[PHPhotoLibrary sharedPhotoLibrary]
            performChanges:^{
              if (mediaType == MediaTypeVideo) {
                [PHAssetChangeRequest
                    creationRequestForAssetFromVideoAtFileURL:mediaURL];
              } else {
                UIImage *image =
                    [UIImage imageWithContentsOfFile:mediaURL.path];
                if (image) {
                  [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                }
              }
            }
            completionHandler:^(BOOL success, NSError *_Nullable error) {
              if (success) {

                if (completion) {
                  completion();
                }
              } else {
                [self showToast:@"保存失败"];
              }
              // 不管成功失败都清理临时文件
              [[NSFileManager defaultManager] removeItemAtPath:mediaURL.path
                                                         error:nil];
            }];
      }
    }
  }];
}

// 检测文件格式的方法
+ (NSString *)detectFileFormat:(NSURL *)fileURL {
  // 读取文件的整个数据或足够的字节用于识别
  NSData *fileData = [NSData dataWithContentsOfURL:fileURL
                                           options:NSDataReadingMappedIfSafe
                                             error:nil];
  if (!fileData || fileData.length < 12) {
    return @"unknown";
  }

  // 转换为字节数组以便检查
  const unsigned char *bytes = [fileData bytes];

  // 检查WebP格式："RIFF" + 4字节 + "WEBP"
  if (bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' &&
      bytes[3] == 'F' && bytes[8] == 'W' && bytes[9] == 'E' &&
      bytes[10] == 'B' && bytes[11] == 'P') {
    return @"webp";
  }

  // 检查HEIF/HEIC格式："ftyp" 在第4-7字节位置
  if (bytes[4] == 'f' && bytes[5] == 't' && bytes[6] == 'y' &&
      bytes[7] == 'p') {
    if (fileData.length >= 16) {
      // 检查HEIC品牌
      if (bytes[8] == 'h' && bytes[9] == 'e' && bytes[10] == 'i' &&
          bytes[11] == 'c') {
        return @"heic";
      }
      // 检查HEIF品牌
      if (bytes[8] == 'h' && bytes[9] == 'e' && bytes[10] == 'i' &&
          bytes[11] == 'f') {
        return @"heif";
      }
      // 可能是其他HEIF变体
      return @"heif";
    }
  }

  // 检查GIF格式："GIF87a"或"GIF89a"
  if (bytes[0] == 'G' && bytes[1] == 'I' && bytes[2] == 'F') {
    return @"gif";
  }

  // 检查PNG格式
  if (bytes[0] == 0x89 && bytes[1] == 'P' && bytes[2] == 'N' &&
      bytes[3] == 'G') {
    return @"png";
  }

  // 检查JPEG格式
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return @"jpeg";
  }

  return @"unknown";
}

// 保存GIF到相册的方法
+ (void)saveGifToPhotoLibrary:(NSURL *)gifURL
                    mediaType:(MediaType)mediaType
                   completion:(void (^)(void))completion {
  [[PHPhotoLibrary sharedPhotoLibrary]
      performChanges:^{
        // 获取GIF数据
        NSData *gifData = [NSData dataWithContentsOfURL:gifURL];
        // 创建相册资源
        PHAssetCreationRequest *request =
            [PHAssetCreationRequest creationRequestForAsset];
        // 实例相册类资源参数
        PHAssetResourceCreationOptions *options =
            [[PHAssetResourceCreationOptions alloc] init];
        // 定义GIF参数
        options.uniformTypeIdentifier = @"com.compuserve.gif";
        // 保存GIF图片
        [request addResourceWithType:PHAssetResourceTypePhoto
                                data:gifData
                             options:options];
      }
      completionHandler:^(BOOL success, NSError *_Nullable error) {
        if (success) {
          if (completion) {
            completion();
          }
        } else {
          [self showToast:@"保存失败"];
        }
        // 不管成功失败都清理临时文件
        [[NSFileManager defaultManager] removeItemAtPath:gifURL.path error:nil];
      }];
}

static void ReleaseWebPData(void *info, const void *data, size_t size) {
  free((void *)data);
}

+ (void)convertWebpToGifSafely:(NSURL *)webpURL
                    completion:
                        (void (^)(NSURL *gifURL, BOOL success))completion {
  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 创建GIF文件路径
        NSString *gifFileName =
            [[webpURL.lastPathComponent stringByDeletingPathExtension]
                stringByAppendingPathExtension:@"gif"];
        NSURL *gifURL = [NSURL
            fileURLWithPath:[NSTemporaryDirectory()
                                stringByAppendingPathComponent:gifFileName]];

        // 读取WebP文件数据
        NSData *webpData = [NSData dataWithContentsOfURL:webpURL];
        if (!webpData) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion(nil, NO);
            }
          });
          return;
        }

        // 初始化WebP解码器
        WebPData webp_data;
        webp_data.bytes = webpData.bytes;
        webp_data.size = webpData.length;

        // 创建WebP动画解码器
        WebPDemuxer *demux = WebPDemux(&webp_data);
        if (!demux) {
          // 如果无法解码为动画，尝试直接解码为静态图像
          WebPDecoderConfig config;
          WebPInitDecoderConfig(&config);

          // 设置解码选项，支持透明度
          config.output.colorspace = MODE_RGBA;
          config.options.use_threads = 1;

          // 尝试解码
          VP8StatusCode status =
              WebPDecode(webpData.bytes, webpData.length, &config);

          if (status != VP8_STATUS_OK) {
            // 解码失败
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) {
                completion(nil, NO);
              }
            });
            return;
          }

          // 成功解码为静态图像，创建UIImage
          CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
          CGDataProviderRef provider = CGDataProviderCreateWithData(
              NULL, config.output.u.RGBA.rgba,
              config.output.width * config.output.height * 4,
              ReleaseWebPData); // 使用定义的C函数作为回调

          CGImageRef imageRef = CGImageCreate(
              config.output.width, config.output.height, 8, 32,
              config.output.width * 4, colorSpace,
              kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast,
              provider, NULL, false, kCGRenderingIntentDefault);

          // 创建静态GIF
          NSDictionary *gifProperties = @{
            (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
              (__bridge NSString *)kCGImagePropertyGIFLoopCount : @0,
            }
          };

          CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
              (__bridge CFURLRef)gifURL, kUTTypeGIF, 1, NULL);
          if (!destination) {
            CGImageRelease(imageRef);
            CGDataProviderRelease(provider);
            CGColorSpaceRelease(colorSpace);

            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) {
                completion(nil, NO);
              }
            });
            return;
          }

          CGImageDestinationSetProperties(
              destination, (__bridge CFDictionaryRef)gifProperties);

          NSDictionary *frameProperties = @{
            (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
              (__bridge NSString *)kCGImagePropertyGIFDelayTime : @0.1f,
            }
          };

          CGImageDestinationAddImage(destination, imageRef,
                                     (__bridge CFDictionaryRef)frameProperties);
          BOOL success = CGImageDestinationFinalize(destination);

          CGImageRelease(imageRef);
          CGDataProviderRelease(provider);
          CGColorSpaceRelease(colorSpace);
          CFRelease(destination);

          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion(gifURL, success);
            }
          });
          return;
        }

        // 获取WebP信息
        uint32_t frameCount = WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT);
        int canvasWidth = WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH);
        int canvasHeight = WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT);
        BOOL isAnimated = (frameCount > 1);
        BOOL hasAlpha = WebPDemuxGetI(demux, WEBP_FF_FORMAT_FLAGS) & ALPHA_FLAG;

        // 设置GIF属性
        NSDictionary *gifProperties = @{
          (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
            (__bridge NSString *)
            kCGImagePropertyGIFLoopCount : @0, // 0表示无限循环
          }
        };

        // 创建GIF图像目标
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
            (__bridge CFURLRef)gifURL, kUTTypeGIF, isAnimated ? frameCount : 1,
            NULL);
        if (!destination) {
          WebPDemuxDelete(demux);
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion(nil, NO);
            }
          });
          return;
        }

        // 设置GIF属性
        CGImageDestinationSetProperties(
            destination, (__bridge CFDictionaryRef)gifProperties);

        // 解码每一帧并添加到GIF
        BOOL allFramesAdded = YES;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        // 用于保存上一帧的画布
        CGContextRef prevCanvas = CGBitmapContextCreate(
            NULL, canvasWidth, canvasHeight, 8, canvasWidth * 4, colorSpace,
            kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);

        // 用于当前绘制的画布
        CGContextRef currCanvas = CGBitmapContextCreate(
            NULL, canvasWidth, canvasHeight, 8, canvasWidth * 4, colorSpace,
            kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);

        // 如果画布创建失败，则返回错误
        if (!prevCanvas || !currCanvas) {
          if (prevCanvas)
            CGContextRelease(prevCanvas);
          if (currCanvas)
            CGContextRelease(currCanvas);
          CGColorSpaceRelease(colorSpace);
          WebPDemuxDelete(demux);
          CFRelease(destination);

          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion(nil, NO);
            }
          });
          return;
        }

        // 初始化为透明背景
        CGContextClearRect(prevCanvas,
                           CGRectMake(0, 0, canvasWidth, canvasHeight));

        for (uint32_t i = 0; i < frameCount; i++) {
          WebPIterator iter;
          if (WebPDemuxGetFrame(demux, i + 1, &iter)) {
            // 解码当前帧
            WebPDecoderConfig config;
            WebPInitDecoderConfig(&config);

            // 设置解码配置，强制处理透明度
            config.output.colorspace = MODE_RGBA;
            config.output.is_external_memory = 0;
            config.options.use_threads = 1;

            // 解码
            VP8StatusCode status =
                WebPDecode(iter.fragment.bytes, iter.fragment.size, &config);

            if (status != VP8_STATUS_OK) {
              WebPDemuxReleaseIterator(&iter);
              continue;
            }

            // 创建帧图像
            CGDataProviderRef frameProvider = CGDataProviderCreateWithData(
                NULL, config.output.u.RGBA.rgba,
                config.output.width * config.output.height * 4,
                ReleaseWebPData);

            if (!frameProvider) {
              WebPFreeDecBuffer(&config.output);
              WebPDemuxReleaseIterator(&iter);
              continue;
            }

            CGImageRef frameImageRef = CGImageCreate(
                config.output.width, config.output.height, 8, 32,
                config.output.width * 4, colorSpace,
                kCGBitmapByteOrderDefault |
                    (hasAlpha ? kCGImageAlphaLast : kCGImageAlphaNoneSkipLast),
                frameProvider, NULL, false, kCGRenderingIntentDefault);

            if (!frameImageRef) {
              CGDataProviderRelease(frameProvider);
              WebPDemuxReleaseIterator(&iter);
              continue;
            }

            // 准备当前帧画布 - 根据合成模式处理
            // 首先拷贝上一帧的状态到当前帧
            CGContextCopyBytes(currCanvas, prevCanvas, canvasWidth,
                               canvasHeight);

            // 根据混合模式处理当前帧
            if (iter.blend_method == WEBP_MUX_BLEND) {
              // 使用Alpha混合模式，将当前帧混合到背景上
              CGContextDrawImage(currCanvas,
                                 CGRectMake(iter.x_offset,
                                            canvasHeight - iter.y_offset -
                                                config.output.height,
                                            config.output.width,
                                            config.output.height),
                                 frameImageRef);
            } else {
              // 不混合模式，清除目标区域后再绘制
              CGContextClearRect(currCanvas,
                                 CGRectMake(iter.x_offset,
                                            canvasHeight - iter.y_offset -
                                                config.output.height,
                                            config.output.width,
                                            config.output.height));

              CGContextDrawImage(currCanvas,
                                 CGRectMake(iter.x_offset,
                                            canvasHeight - iter.y_offset -
                                                config.output.height,
                                            config.output.width,
                                            config.output.height),
                                 frameImageRef);
            }

            // 从当前画布创建帧图像
            CGImageRef canvasImageRef = CGBitmapContextCreateImage(currCanvas);

            // 处理帧间延迟
            float delayTime = iter.duration / 1000.0f;
            if (delayTime <= 0.01f) {
              delayTime = 0.1f; // 默认延迟
            }

            // 创建帧属性
            NSDictionary *frameProperties = @{
              (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
                (__bridge NSString *)
                kCGImagePropertyGIFDelayTime : @(delayTime),
                (__bridge NSString *)
                kCGImagePropertyGIFHasGlobalColorMap : @YES,
                (__bridge NSString *)kCGImagePropertyColorModel :
                        hasAlpha ? @"RGBA" : @"RGB",
              }
            };

            // 添加帧到GIF
            CGImageDestinationAddImage(
                destination, canvasImageRef,
                (__bridge CFDictionaryRef)frameProperties);

            // 根据处理模式更新上一帧画布
            if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
              // 处理背景处理模式 - 清除当前帧区域
              CGContextClearRect(prevCanvas,
                                 CGRectMake(iter.x_offset,
                                            canvasHeight - iter.y_offset -
                                                config.output.height,
                                            config.output.width,
                                            config.output.height));
            } else if (iter.dispose_method == WEBP_MUX_DISPOSE_NONE) {
              // 保持当前帧，复制当前画布到上一帧
              CGContextCopyBytes(prevCanvas, currCanvas, canvasWidth,
                                 canvasHeight);
            }

            // 释放资源
            CGImageRelease(canvasImageRef);
            CGImageRelease(frameImageRef);
            CGDataProviderRelease(frameProvider);
            WebPDemuxReleaseIterator(&iter);
          } else {
            allFramesAdded = NO;
          }
        }

        // 释放画布
        CGContextRelease(prevCanvas);
        CGContextRelease(currCanvas);
        CGColorSpaceRelease(colorSpace);

        // 完成GIF生成
        BOOL success =
            CGImageDestinationFinalize(destination) && allFramesAdded;

        // 释放资源
        WebPDemuxDelete(demux);
        CFRelease(destination);

        dispatch_async(dispatch_get_main_queue(), ^{
          if (completion) {
            completion(gifURL, success);
          }
        });
      });
}

// 辅助函数：复制上下文像素数据
static void CGContextCopyBytes(CGContextRef dst, CGContextRef src, int width,
                               int height) {
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(src);
  void *srcData = CGBitmapContextGetData(src);
  void *dstData = CGBitmapContextGetData(dst);

  if (srcData && dstData) {
    memcpy(dstData, srcData, bytesPerRow * height);
  }
}

// 将HEIC转换为GIF的方法
+ (void)convertHeicToGif:(NSURL *)heicURL
              completion:(void (^)(NSURL *gifURL, BOOL success))completion {
  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 1. 创建ImageSource
        CGImageSourceRef src =
            CGImageSourceCreateWithURL((__bridge CFURLRef)heicURL, NULL);
        if (!src) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion)
              completion(nil, NO);
          });
          return;
        }

        // 2. 获取帧数
        size_t count = CGImageSourceGetCount(src);
        BOOL isAnimated = (count > 1);

        // 3. 生成GIF路径
        NSString *gifFileName =
            [[heicURL.lastPathComponent stringByDeletingPathExtension]
                stringByAppendingPathExtension:@"gif"];
        NSURL *gifURL = [NSURL
            fileURLWithPath:[NSTemporaryDirectory()
                                stringByAppendingPathComponent:gifFileName]];

        // 4. GIF属性
        NSDictionary *gifProperties = @{
          (__bridge NSString *)kCGImagePropertyGIFDictionary :
              @{(__bridge NSString *)kCGImagePropertyGIFLoopCount : @0}
        };

        // 5. 创建GIF目标
        CGImageDestinationRef dest = CGImageDestinationCreateWithURL(
            (__bridge CFURLRef)gifURL, kUTTypeGIF, count, NULL);
        if (!dest) {
          CFRelease(src);
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion)
              completion(nil, NO);
          });
          return;
        }
        CGImageDestinationSetProperties(
            dest, (__bridge CFDictionaryRef)gifProperties);

        // 6. 遍历帧并写入GIF
        for (size_t i = 0; i < count; i++) {
          CGImageRef imgRef = CGImageSourceCreateImageAtIndex(src, i, NULL);

          // 获取帧延迟
          float delayTime = 0.1f;
          CFDictionaryRef properties =
              CGImageSourceCopyPropertiesAtIndex(src, i, NULL);
          if (properties) {
            CFDictionaryRef gifDict =
                CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
            if (gifDict) {
              CFNumberRef delayNum =
                  CFDictionaryGetValue(gifDict, kCGImagePropertyGIFDelayTime);
              if (delayNum)
                CFNumberGetValue(delayNum, kCFNumberFloatType, &delayTime);
            }
            if (delayTime <= 0.01f || delayTime > 10.0f)
              delayTime = 0.1f;
            CFRelease(properties);
          }

          NSDictionary *frameProps = @{
            (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
              (__bridge NSString *)kCGImagePropertyGIFDelayTime : @(delayTime)
            }
          };

          if (imgRef) {
            CGImageDestinationAddImage(dest, imgRef,
                                       (__bridge CFDictionaryRef)frameProps);
            CGImageRelease(imgRef);
          }
        }

        // 7. 完成GIF生成
        BOOL success = CGImageDestinationFinalize(dest);
        CFRelease(dest);
        CFRelease(src);

        dispatch_async(dispatch_get_main_queue(), ^{
          if (completion)
            completion(gifURL, success);
        });
      });
}

+ (void)downloadLivePhoto:(NSURL *)imageURL
                 videoURL:(NSURL *)videoURL
               completion:(void (^)(void))completion {
  // 获取共享实例，确保FileLinks字典存在
  DYYYManager *manager = [DYYYManager shared];
  if (!manager.fileLinks) {
    manager.fileLinks = [NSMutableDictionary dictionary];
  }

  // 为图片和视频URL创建唯一的键
  NSString *uniqueKey =
      [NSString stringWithFormat:@"%@_%@", imageURL.absoluteString,
                                 videoURL.absoluteString];

  // 检查是否已经存在此下载任务
  NSDictionary *existingPaths = manager.fileLinks[uniqueKey];
  if (existingPaths) {
    NSString *imagePath = existingPaths[@"image"];
    NSString *videoPath = existingPaths[@"video"];

    // 使用异步检查以避免主线程阻塞
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          BOOL imageExists =
              [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
          BOOL videoExists =
              [[NSFileManager defaultManager] fileExistsAtPath:videoPath];

          dispatch_async(dispatch_get_main_queue(), ^{
            if (imageExists && videoExists) {
              [[DYYYManager shared] saveLivePhoto:imagePath videoUrl:videoPath];
              if (completion) {
                completion();
              }
              return;
            } else {
              // 文件不完整，需要重新下载
              [self startDownloadLivePhotoProcess:imageURL
                                         videoURL:videoURL
                                        uniqueKey:uniqueKey
                                       completion:completion];
            }
          });
        });
  } else {
    // 没有缓存，直接开始下载
    [self startDownloadLivePhotoProcess:imageURL
                               videoURL:videoURL
                              uniqueKey:uniqueKey
                             completion:completion];
  }
}

+ (void)startDownloadLivePhotoProcess:(NSURL *)imageURL
                             videoURL:(NSURL *)videoURL
                            uniqueKey:(NSString *)uniqueKey
                           completion:(void (^)(void))completion {
  // 创建临时目录
  NSString *livePhotoPath =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"LivePhoto"];

  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:livePhotoPath]) {
    [fileManager createDirectoryAtPath:livePhotoPath
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
  }

  // 生成唯一标识符，防止多次调用时文件冲突
  NSString *uniqueID = [NSUUID UUID].UUIDString;
  NSString *imagePath = [livePhotoPath
      stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.heic",
                                                                uniqueID]];
  NSString *videoPath = [livePhotoPath
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"%@.mp4", uniqueID]];

  // 存储文件路径，以便下次下载相同的URL时可以复用
  DYYYManager *manager = [DYYYManager shared];
  [manager.fileLinks setObject:@{@"image" : imagePath, @"video" : videoPath}
                        forKey:uniqueKey];

  dispatch_async(dispatch_get_main_queue(), ^{
    // 创建进度视图
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    DYYYToast *progressView = [[DYYYToast alloc] initWithFrame:screenBounds];
    [progressView show];

    // 优化会话配置
    NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 60.0; // 增加超时时间
    configuration.timeoutIntervalForResource = 60.0;
    configuration.HTTPMaximumConnectionsPerHost = 10; // 增加并发连接数
    configuration.requestCachePolicy =
        NSURLRequestReloadIgnoringLocalCacheData; // 强制从网络重新下载

    // 使用共享委托的session以节省资源
    NSURLSession *session =
        [NSURLSession sessionWithConfiguration:configuration
                                      delegate:[DYYYManager shared]
                                 delegateQueue:[NSOperationQueue mainQueue]];

    dispatch_group_t group = dispatch_group_create();
    __block BOOL imageDownloaded = NO;
    __block BOOL videoDownloaded = NO;
    __block float imageProgress = 0.0;
    __block float videoProgress = 0.0;

    // 设置单独的下载观察者ID用于进度跟踪
    NSString *imageDownloadID =
        [NSString stringWithFormat:@"image_%@", uniqueID];
    NSString *videoDownloadID =
        [NSString stringWithFormat:@"video_%@", uniqueID];

    // 更新合并进度的定时器
    __block NSTimer *progressTimer = [NSTimer
        scheduledTimerWithTimeInterval:0.1
                               repeats:YES
                                 block:^(NSTimer *_Nonnull timer) {
                                   float totalProgress =
                                       (imageProgress + videoProgress) / 2.0;
                                   [progressView setProgress:totalProgress];

                                   // 更新进度文字
                                   NSString *statusText =
                                       @"正在下载实况照片...";
                                   if (imageDownloaded && !videoDownloaded) {
                                     statusText = @"图片下载完成，等待视频...";
                                   } else if (!imageDownloaded &&
                                              videoDownloaded) {
                                     statusText = @"视频下载完成，等待图片...";
                                   } else if (imageDownloaded &&
                                              videoDownloaded) {
                                     statusText = @"下载完成，准备保存...";
                                     [timer invalidate]; // 全部完成时停止定时器
                                   }
                                 }];

    // 下载图片
    dispatch_group_enter(group);
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageURL];
    NSURLSessionDataTask *imageTask =
        [session dataTaskWithRequest:imageRequest
                   completionHandler:^(NSData *_Nullable data,
                                       NSURLResponse *_Nullable response,
                                       NSError *_Nullable error) {
                     if (!error && data) {
                       // 直接写入文件，避免临时文件移动操作
                       if ([data writeToFile:imagePath atomically:YES]) {
                         imageDownloaded = YES;
                         imageProgress = 1.0;
                       }
                     }
                     dispatch_group_leave(group);
                   }];

    // 设置图片下载进度观察
    if ([imageTask respondsToSelector:@selector(taskIdentifier)]) {
      [[manager taskProgressMap] setObject:@(0.0) forKey:imageDownloadID];

      // 使用系统API观察进度 (iOS 11+)
      if (@available(iOS 11.0, *)) {
        [imageTask.progress addObserver:manager
                             forKeyPath:@"fractionCompleted"
                                options:NSKeyValueObservingOptionNew
                                context:(__bridge void *)(imageDownloadID)];
      }
    }

    // 下载视频
    dispatch_group_enter(group);
    NSURLRequest *videoRequest = [NSURLRequest requestWithURL:videoURL];
    NSURLSessionDataTask *videoTask =
        [session dataTaskWithRequest:videoRequest
                   completionHandler:^(NSData *_Nullable data,
                                       NSURLResponse *_Nullable response,
                                       NSError *_Nullable error) {
                     if (!error && data) {
                       // 直接写入文件，避免临时文件移动操作
                       if ([data writeToFile:videoPath atomically:YES]) {
                         videoDownloaded = YES;
                         videoProgress = 1.0;
                       }
                     }
                     dispatch_group_leave(group);
                   }];

    // 设置视频下载进度观察
    if ([videoTask respondsToSelector:@selector(taskIdentifier)]) {
      [[manager taskProgressMap] setObject:@(0.0) forKey:videoDownloadID];

      // 使用系统API观察进度 (iOS 11+)
      if (@available(iOS 11.0, *)) {
        [videoTask.progress addObserver:manager
                             forKeyPath:@"fractionCompleted"
                                options:NSKeyValueObservingOptionNew
                                context:(__bridge void *)(videoDownloadID)];
      }
    }

    // 启动下载任务
    [imageTask resume];
    [videoTask resume];

    // 当两个下载都完成后，保存实况照片
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
      // 停止进度定时器
      [progressTimer invalidate];

      // 移除进度观察
      if (@available(iOS 11.0, *)) {
        if ([imageTask respondsToSelector:@selector(progress)]) {
          [imageTask.progress removeObserver:manager
                                  forKeyPath:@"fractionCompleted"];
        }
        if ([videoTask respondsToSelector:@selector(progress)]) {
          [videoTask.progress removeObserver:manager
                                  forKeyPath:@"fractionCompleted"];
        }
      }

      // 检查文件是否真的存在
      BOOL imageExists =
          [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
      BOOL videoExists =
          [[NSFileManager defaultManager] fileExistsAtPath:videoPath];

      // 隐藏进度视图
      [progressView dismiss];

      if (imageExists && videoExists) {
        @try {
          // 添加iOS版本检查
          if (@available(iOS 15.0, *)) {
            [[DYYYManager shared] saveLivePhoto:imagePath videoUrl:videoPath];
          }
        } @catch (NSException *exception) {
          // 删除失败的文件
          [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
          [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
          [manager.fileLinks removeObjectForKey:uniqueKey];
          [DYYYManager showToast:@"保存实况照片失败"];
        }
      } else {
        // 清理不完整的文件
        if (imageExists)
          [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
        if (videoExists)
          [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
        [manager.fileLinks removeObjectForKey:uniqueKey];
        [DYYYManager showToast:@"下载实况照片失败"];
      }

      if (completion) {
        completion();
      }
    });
  });
}

// 需要添加KVO回调方法来处理下载进度
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"fractionCompleted"] &&
      [object isKindOfClass:[NSProgress class]]) {
    NSString *downloadID = (__bridge NSString *)context;
    if (downloadID) {
      NSProgress *progress = (NSProgress *)object;
      float fractionCompleted = progress.fractionCompleted;
      [self.taskProgressMap setObject:@(fractionCompleted) forKey:downloadID];
    }
  } else {
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}

+ (void)downloadMedia:(NSURL *)url
            mediaType:(MediaType)mediaType
           completion:(void (^)(BOOL success))completion {
  [self downloadMediaWithProgress:url
                        mediaType:mediaType
                         progress:nil
                       completion:^(BOOL success, NSURL *fileURL) {
                         if (success) {
                           if (mediaType == MediaTypeAudio) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                               UIActivityViewController *activityVC =
                                   [[UIActivityViewController alloc]
                                       initWithActivityItems:@[ fileURL ]
                                       applicationActivities:nil];

                               [activityVC
                                   setCompletionWithItemsHandler:^(
                                       UIActivityType _Nullable activityType,
                                       BOOL completed,
                                       NSArray *_Nullable returnedItems,
                                       NSError *_Nullable error) {
                                     [[NSFileManager defaultManager]
                                         removeItemAtURL:fileURL
                                                   error:nil];
                                   }];
                               UIViewController *rootVC =
                                   [UIApplication sharedApplication]
                                       .keyWindow.rootViewController;
                               [rootVC presentViewController:activityVC
                                                    animated:YES
                                                  completion:nil];
                               if (completion) {
                                 completion(YES);
                               }
                             });
                           } else {
                             [self saveMedia:fileURL
                                   mediaType:mediaType
                                  completion:^{
                                    if (completion) {
                                      completion(YES);
                                    }
                                  }];
                           }
                         } else {
                           if (completion) {
                             completion(NO);
                           }
                         }
                       }];
}

+ (void)downloadMediaWithProgress:(NSURL *)url
                        mediaType:(MediaType)mediaType
                         progress:(void (^)(float progress))progressBlock
                       completion:
                           (void (^)(BOOL success, NSURL *fileURL))completion {
  // 创建自定义进度条界面
  dispatch_async(dispatch_get_main_queue(), ^{
    // 创建进度视图
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    DYYYToast *progressView = [[DYYYToast alloc] initWithFrame:screenBounds];

    // 生成下载ID并保存进度视图
    NSString *downloadID = [NSUUID UUID].UUIDString;
    [[DYYYManager shared].progressViews setObject:progressView
                                           forKey:downloadID];

    [progressView show];

    // 保存回调
    [[DYYYManager shared] setCompletionBlock:completion
                               forDownloadID:downloadID];
    [[DYYYManager shared] setMediaType:mediaType forDownloadID:downloadID];

    // 配置下载会话 - 使用带委托的会话以获取进度更新
    NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session =
        [NSURLSession sessionWithConfiguration:configuration
                                      delegate:[DYYYManager shared]
                                 delegateQueue:[NSOperationQueue mainQueue]];

    // 创建下载任务 - 不使用completionHandler，使用代理方法
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url];

    // 存储下载任务
    [[DYYYManager shared].downloadTasks setObject:downloadTask
                                           forKey:downloadID];
    [[DYYYManager shared].taskProgressMap
        setObject:@0.0
           forKey:downloadID]; // 初始化进度为0

    // 开始下载
    [downloadTask resume];
  });
}

+ (NSString *)getMediaTypeDescription:(MediaType)mediaType {
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

// 取消所有下载
+ (void)cancelAllDownloads {
  NSArray *downloadIDs = [[DYYYManager shared].downloadTasks allKeys];

  for (NSString *downloadID in downloadIDs) {
    NSURLSessionDownloadTask *task =
        [[DYYYManager shared].downloadTasks objectForKey:downloadID];
    if (task) {
      [task cancel];
    }

    DYYYToast *progressView =
        [[DYYYManager shared].progressViews objectForKey:downloadID];
    if (progressView) {
      [progressView dismiss];
    }
  }

  NSString *livePhotoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LivePhotoBatch"];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:livePhotoPath]) {
    NSError *error = nil;
    [fileManager removeItemAtPath:livePhotoPath error:&error];
    if (error) {
      NSLog(@"清理实况照片临时目录失败: %@", error.localizedDescription);
    }
  }
  
  NSString *generalLivePhotoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LivePhoto"];
  if ([fileManager fileExistsAtPath:generalLivePhotoPath]) {
    NSError *error = nil;
    [fileManager removeItemAtPath:generalLivePhotoPath error:&error];
    if (error) {
      NSLog(@"清理LivePhoto临时目录失败: %@", error.localizedDescription);
    }
  }

  [[DYYYManager shared].downloadTasks removeAllObjects];
  [[DYYYManager shared].progressViews removeAllObjects];
}

+ (void)downloadAllImages:(NSMutableArray *)imageURLs {
  if (imageURLs.count == 0) {
    return;
  }

  [self downloadAllImagesWithProgress:imageURLs
                             progress:nil
                           completion:^(NSInteger successCount,
                                        NSInteger totalCount){
                           }];
}

+ (void)downloadAllImagesWithProgress:(NSMutableArray *)imageURLs
                             progress:(void (^)(NSInteger current,
                                                NSInteger total))progressBlock
                           completion:
                               (void (^)(NSInteger successCount,
                                         NSInteger totalCount))completion {
  if (imageURLs.count == 0) {
    if (completion) {
      completion(0, 0);
    }
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    DYYYToast *progressView = [[DYYYToast alloc] initWithFrame:screenBounds];
    NSString *batchID = [NSUUID UUID].UUIDString;
    [[DYYYManager shared].progressViews setObject:progressView forKey:batchID];

    [progressView show];

    __block NSInteger completedCount = 0;
    __block NSInteger successCount = 0;
    NSInteger totalCount = imageURLs.count;

    progressView.cancelBlock = ^{
      [self cancelAllDownloads];
      if (completion) {
        completion(successCount, totalCount);
      }
    };

    // 存储批量下载的相关信息
    [[DYYYManager shared] setBatchInfo:batchID
                            totalCount:totalCount
                         progressBlock:progressBlock
                       completionBlock:completion];

    // 为每个URL创建下载任务
    for (NSString *urlString in imageURLs) {
      NSURL *url = [NSURL URLWithString:urlString];
      if (!url) {
        [[DYYYManager shared]
            incrementCompletedAndUpdateProgressForBatch:batchID
                                                success:NO];
        continue;
      }

      // 创建单个下载任务ID
      NSString *downloadID = [NSUUID UUID].UUIDString;
      [[DYYYManager shared] associateDownload:downloadID withBatchID:batchID];
      NSURLSessionConfiguration *configuration =
          [NSURLSessionConfiguration defaultSessionConfiguration];
      NSURLSession *session =
          [NSURLSession sessionWithConfiguration:configuration
                                        delegate:[DYYYManager shared]
                                   delegateQueue:[NSOperationQueue mainQueue]];

      // 创建下载任务 - 使用代理方法
      NSURLSessionDownloadTask *downloadTask =
          [session downloadTaskWithURL:url];
      [[DYYYManager shared].downloadTasks setObject:downloadTask
                                             forKey:downloadID];
      [[DYYYManager shared].taskProgressMap setObject:@0.0 forKey:downloadID];
      [[DYYYManager shared] setMediaType:MediaTypeImage
                           forDownloadID:downloadID];
      [downloadTask resume];
    }
  });
}

// 设置批量下载信息
- (void)setBatchInfo:(NSString *)batchID
          totalCount:(NSInteger)totalCount
       progressBlock:(void (^)(NSInteger current, NSInteger total))progressBlock
     completionBlock:(void (^)(NSInteger successCount,
                               NSInteger totalCount))completionBlock {
  [self.batchTotalCountMap setObject:@(totalCount) forKey:batchID];
  [self.batchCompletedCountMap setObject:@(0) forKey:batchID];
  [self.batchSuccessCountMap setObject:@(0) forKey:batchID];

  if (progressBlock) {
    [self.batchProgressBlocks setObject:[progressBlock copy] forKey:batchID];
  }

  if (completionBlock) {
    [self.batchCompletionBlocks setObject:[completionBlock copy]
                                   forKey:batchID];
  }
}

// 关联单个下载到批量下载
- (void)associateDownload:(NSString *)downloadID
              withBatchID:(NSString *)batchID {
  [self.downloadToBatchMap setObject:batchID forKey:downloadID];
}

// 批量下载完成计数并更新进度
- (void)incrementCompletedAndUpdateProgressForBatch:(NSString *)batchID
                                            success:(BOOL)success {
  @synchronized(self) {
    NSNumber *completedCountNum = self.batchCompletedCountMap[batchID];
    NSInteger completedCount =
        completedCountNum ? [completedCountNum integerValue] + 1 : 1;
    [self.batchCompletedCountMap setObject:@(completedCount) forKey:batchID];

    if (success) {
      NSNumber *successCountNum = self.batchSuccessCountMap[batchID];
      NSInteger successCount =
          successCountNum ? [successCountNum integerValue] + 1 : 1;
      [self.batchSuccessCountMap setObject:@(successCount) forKey:batchID];
    }

    NSNumber *totalCountNum = self.batchTotalCountMap[batchID];
    NSInteger totalCount = totalCountNum ? [totalCountNum integerValue] : 0;

    DYYYToast *progressView = self.progressViews[batchID];
    if (progressView) {
      float progress = totalCount > 0 ? (float)completedCount / totalCount : 0;
      [progressView setProgress:progress];
    }

    void (^progressBlock)(NSInteger current, NSInteger total) =
        self.batchProgressBlocks[batchID];
    if (progressBlock) {
      progressBlock(completedCount, totalCount);
    }

    if (completedCount >= totalCount) {
      NSInteger successCount =
          [self.batchSuccessCountMap[batchID] integerValue];

      void (^completionBlock)(NSInteger successCount, NSInteger totalCount) =
          self.batchCompletionBlocks[batchID];
      if (completionBlock) {
        completionBlock(successCount, totalCount);
      }

      [progressView dismiss];
      [self.progressViews removeObjectForKey:batchID];

      // 清理批量下载相关信息
      [self.batchCompletedCountMap removeObjectForKey:batchID];
      [self.batchSuccessCountMap removeObjectForKey:batchID];
      [self.batchTotalCountMap removeObjectForKey:batchID];
      [self.batchProgressBlocks removeObjectForKey:batchID];
      [self.batchCompletionBlocks removeObjectForKey:batchID];

      // 移除关联的下载ID
      NSArray *downloadIDs = [self.downloadToBatchMap allKeysForObject:batchID];
      for (NSString *downloadID in downloadIDs) {
        [self.downloadToBatchMap removeObjectForKey:downloadID];
      }
    }
  }
}

// 保存完成回调
- (void)setCompletionBlock:(void (^)(BOOL success, NSURL *fileURL))completion
             forDownloadID:(NSString *)downloadID {
  if (completion) {
    [self.completionBlocks setObject:[completion copy] forKey:downloadID];
  }
}

// 保存媒体类型
- (void)setMediaType:(MediaType)mediaType forDownloadID:(NSString *)downloadID {
  [self.mediaTypeMap setObject:@(mediaType) forKey:downloadID];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
  // 确保不会除以0
  if (totalBytesExpectedToWrite <= 0) {
    return;
  }

  // 计算进度
  float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;

  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *downloadIDForTask = nil;

    for (NSString *key in self.downloadTasks.allKeys) {
      NSURLSessionDownloadTask *task = self.downloadTasks[key];
      if (task == downloadTask) {
        downloadIDForTask = key;
        break;
      }
    }

    // 如果找到对应的进度视图，更新进度
    if (downloadIDForTask) {
      [self.taskProgressMap setObject:@(progress) forKey:downloadIDForTask];

      DYYYToast *progressView = self.progressViews[downloadIDForTask];
      if (progressView) {
        if (!progressView.isCancelled) {
          [progressView setProgress:progress];
        }
      }
    }
  });
}

// 下载完成的代理方法
- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
    didFinishDownloadingToURL:(NSURL *)location {
  // 找到对应的下载ID
  NSString *downloadIDForTask = nil;
  for (NSString *key in self.downloadTasks.allKeys) {
    NSURLSessionDownloadTask *task = self.downloadTasks[key];
    if (task == downloadTask) {
      downloadIDForTask = key;
      break;
    }
  }

  if (!downloadIDForTask) {
    return;
  }

  // 检查是否属于批量下载
  NSString *batchID = self.downloadToBatchMap[downloadIDForTask];
  BOOL isBatchDownload = (batchID != nil);

  // 获取该下载任务的mediaType
  NSNumber *mediaTypeNumber = self.mediaTypeMap[downloadIDForTask];
  MediaType mediaType = MediaTypeImage; // 默认为图片
  if (mediaTypeNumber) {
    mediaType = (MediaType)[mediaTypeNumber integerValue];
  }

  // 处理下载的文件
  NSString *fileName = [downloadTask.originalRequest.URL lastPathComponent];

  if (!fileName.pathExtension.length) {
    switch (mediaType) {
    case MediaTypeVideo:
      fileName = [fileName stringByAppendingPathExtension:@"mp4"];
      break;
    case MediaTypeImage:
      fileName = [fileName stringByAppendingPathExtension:@"jpg"];
      break;
    case MediaTypeAudio:
      fileName = [fileName stringByAppendingPathExtension:@"mp3"];
      break;
    case MediaTypeHeic:
      fileName = [fileName stringByAppendingPathExtension:@"heic"];
      break;
    }
  }

  NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
  NSURL *destinationURL = [tempDir URLByAppendingPathComponent:fileName];

  NSError *moveError;
  if ([[NSFileManager defaultManager] fileExistsAtPath:destinationURL.path]) {
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
  }

  [[NSFileManager defaultManager] moveItemAtURL:location
                                          toURL:destinationURL
                                          error:&moveError];

  if (isBatchDownload) {
    // 批量下载处理
    if (!moveError) {
      [DYYYManager saveMedia:destinationURL
                   mediaType:mediaType
                  completion:^{
                    [[DYYYManager shared]
                        incrementCompletedAndUpdateProgressForBatch:batchID
                                                            success:YES];
                  }];
    } else {
      [[DYYYManager shared] incrementCompletedAndUpdateProgressForBatch:batchID
                                                                success:NO];
    }

    // 清理下载任务
    [self.downloadTasks removeObjectForKey:downloadIDForTask];
    [self.taskProgressMap removeObjectForKey:downloadIDForTask];
    [self.mediaTypeMap removeObjectForKey:downloadIDForTask];
  } else {
    // 单个下载处理
    // 获取保存的完成回调
    void (^completionBlock)(BOOL success, NSURL *fileURL) =
        self.completionBlocks[downloadIDForTask];

    dispatch_async(dispatch_get_main_queue(), ^{
      // 隐藏进度视图
      DYYYToast *progressView = self.progressViews[downloadIDForTask];
      BOOL wasCancelled = progressView.isCancelled;

      [progressView dismiss];
      [self.progressViews removeObjectForKey:downloadIDForTask];
      [self.downloadTasks removeObjectForKey:downloadIDForTask];
      [self.taskProgressMap removeObjectForKey:downloadIDForTask];
      [self.completionBlocks removeObjectForKey:downloadIDForTask];
      [self.mediaTypeMap removeObjectForKey:downloadIDForTask];

      // 如果已取消，直接返回
      if (wasCancelled) {
        return;
      }

      if (!moveError) {
        if (completionBlock) {
          completionBlock(YES, destinationURL);
        }
      } else {
        if (completionBlock) {
          completionBlock(NO, nil);
        }
      }
    });
  }
}

- (void)URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
  if (!error) {
    return; // 成功完成的情况已在didFinishDownloadingToURL处理
  }

  // 处理错误情况
  NSString *downloadIDForTask = nil;
  for (NSString *key in self.downloadTasks.allKeys) {
    NSURLSessionTask *existingTask = self.downloadTasks[key];
    if (existingTask == task) {
      downloadIDForTask = key;
      break;
    }
  }

  if (!downloadIDForTask) {
    return;
  }

  // 检查是否属于批量下载
  NSString *batchID = self.downloadToBatchMap[downloadIDForTask];
  BOOL isBatchDownload = (batchID != nil);

  if (isBatchDownload) {
    // 批量下载错误处理
    [[DYYYManager shared] incrementCompletedAndUpdateProgressForBatch:batchID
                                                              success:NO];

    // 清理下载任务
    [self.downloadTasks removeObjectForKey:downloadIDForTask];
    [self.taskProgressMap removeObjectForKey:downloadIDForTask];
    [self.mediaTypeMap removeObjectForKey:downloadIDForTask];
    [self.downloadToBatchMap removeObjectForKey:downloadIDForTask];
  } else {
    // 单个下载错误处理
    void (^completionBlock)(BOOL success, NSURL *fileURL) =
        self.completionBlocks[downloadIDForTask];

    dispatch_async(dispatch_get_main_queue(), ^{
      // 隐藏进度视图
      DYYYToast *progressView = self.progressViews[downloadIDForTask];
      [progressView dismiss];

      [self.progressViews removeObjectForKey:downloadIDForTask];
      [self.downloadTasks removeObjectForKey:downloadIDForTask];
      [self.taskProgressMap removeObjectForKey:downloadIDForTask];
      [self.completionBlocks removeObjectForKey:downloadIDForTask];
      [self.mediaTypeMap removeObjectForKey:downloadIDForTask];

      if (error.code != NSURLErrorCancelled) {
        [DYYYManager showToast:@"下载失败"];
      }

      if (completionBlock) {
        completionBlock(NO, nil);
      }
    });
  }
}

// MARK: 以下都是创建保存实况的调用方法
- (void)saveLivePhoto:(NSString *)imageSourcePath
             videoUrl:(NSString *)videoSourcePath {
  // 首先检查iOS版本
  if (@available(iOS 15.0, *)) {
    // iOS 15及更高版本使用原有的实现
    NSURL *photoURL = [NSURL fileURLWithPath:imageSourcePath];
    NSURL *videoURL = [NSURL fileURLWithPath:videoSourcePath];
    BOOL available = [PHAssetCreationRequest supportsAssetResourceTypes:@[
      @(PHAssetResourceTypePhoto), @(PHAssetResourceTypePairedVideo)
    ]];
    if (!available) {
      return;
    }
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
      if (status != PHAuthorizationStatusAuthorized) {
        return;
      }
      NSString *identifier = [NSUUID UUID].UUIDString;
      [self useAssetWriter:photoURL
                     video:videoURL
                identifier:identifier
                  complete:^(BOOL success, NSString *photoFile,
                             NSString *videoFile, NSError *error) {
                    NSURL *photo = [NSURL fileURLWithPath:photoFile];
                    NSURL *video = [NSURL fileURLWithPath:videoFile];
                    [[PHPhotoLibrary sharedPhotoLibrary]
                        performChanges:^{
                          PHAssetCreationRequest *request =
                              [PHAssetCreationRequest creationRequestForAsset];
                          [request addResourceWithType:PHAssetResourceTypePhoto
                                               fileURL:photo
                                               options:nil];
                          [request
                              addResourceWithType:PHAssetResourceTypePairedVideo
                                          fileURL:video
                                          options:nil];
                        }
                        completionHandler:^(BOOL success,
                                            NSError *_Nullable error) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                            if (success) {
                              // 删除临时文件
                              [[NSFileManager defaultManager]
                                  removeItemAtPath:imageSourcePath
                                             error:nil];
                              [[NSFileManager defaultManager]
                                  removeItemAtPath:videoSourcePath
                                             error:nil];
                              [[NSFileManager defaultManager]
                                  removeItemAtPath:photoFile
                                             error:nil];
                              [[NSFileManager defaultManager]
                                  removeItemAtPath:videoFile
                                             error:nil];
                            }
                          });
                        }];
                  }];
    }];
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [DYYYManager
          showToast:@"当前iOS版本不支持实况照片，将分别保存图片和视频"];
    });
  }
}

- (void)useAssetWriter:(NSURL *)photoURL
                 video:(NSURL *)videoURL
            identifier:(NSString *)identifier
              complete:(void (^)(BOOL success, NSString *photoFile,
                                 NSString *videoFile, NSError *error))complete {
  NSString *photoName = [photoURL lastPathComponent];
  NSString *photoFile = [self filePathFromTmp:photoName];
  [self addMetadataToPhoto:photoURL outputFile:photoFile identifier:identifier];
  NSString *videoName = [videoURL lastPathComponent];
  NSString *videoFile = [self filePathFromTmp:videoName];
  [self addMetadataToVideo:videoURL outputFile:videoFile identifier:identifier];
  if (!DYYYManager.shared->group)
    return;
  dispatch_group_notify(DYYYManager.shared->group, dispatch_get_main_queue(), ^{
    [self finishWritingTracksWithPhoto:photoFile
                                 video:videoFile
                              complete:complete];
  });
}
- (void)finishWritingTracksWithPhoto:(NSString *)photoFile
                               video:(NSString *)videoFile
                            complete:(void (^)(BOOL success,
                                               NSString *photoFile,
                                               NSString *videoFile,
                                               NSError *error))complete {
  [DYYYManager.shared->reader cancelReading];
  [DYYYManager.shared->writer finishWritingWithCompletionHandler:^{
    if (complete)
      complete(YES, photoFile, videoFile, nil);
  }];
}
- (void)addMetadataToPhoto:(NSURL *)photoURL
                outputFile:(NSString *)outputFile
                identifier:(NSString *)identifier {
  NSMutableData *data = [NSData dataWithContentsOfURL:photoURL].mutableCopy;
  UIImage *image = [UIImage imageWithData:data];
  CGImageRef imageRef = image.CGImage;
  NSDictionary *imageMetadata = @{
    (NSString *)kCGImagePropertyMakerAppleDictionary : @{@"17" : identifier}
  };
  CGImageDestinationRef dest = CGImageDestinationCreateWithData(
      (CFMutableDataRef)data, kUTTypeJPEG, 1, nil);
  CGImageDestinationAddImage(dest, imageRef, (CFDictionaryRef)imageMetadata);
  CGImageDestinationFinalize(dest);
  [data writeToFile:outputFile atomically:YES];
}

- (void)addMetadataToVideo:(NSURL *)videoURL
                outputFile:(NSString *)outputFile
                identifier:(NSString *)identifier {
  NSError *error = nil;
  AVAsset *asset = [AVAsset assetWithURL:videoURL];
  AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset
                                                        error:&error];
  if (error) {
    return;
  }
  NSMutableArray<AVMetadataItem *> *metadata = asset.metadata.mutableCopy;
  AVMetadataItem *item = [self createContentIdentifierMetadataItem:identifier];
  [metadata addObject:item];
  NSURL *videoFileURL = [NSURL fileURLWithPath:outputFile];
  [self deleteFile:outputFile];
  AVAssetWriter *writer =
      [AVAssetWriter assetWriterWithURL:videoFileURL
                               fileType:AVFileTypeQuickTimeMovie
                                  error:&error];
  if (error) {
    return;
  }
  [writer setMetadata:metadata];
  NSArray<AVAssetTrack *> *tracks = [asset tracks];
  for (AVAssetTrack *track in tracks) {
    NSDictionary *readerOutputSettings = nil;
    NSDictionary *writerOuputSettings = nil;
    if ([track.mediaType isEqualToString:AVMediaTypeAudio]) {
      readerOutputSettings = @{AVFormatIDKey : @(kAudioFormatLinearPCM)};
      writerOuputSettings = @{
        AVFormatIDKey : @(kAudioFormatMPEG4AAC),
        AVSampleRateKey : @(44100),
        AVNumberOfChannelsKey : @(2),
        AVEncoderBitRateKey : @(128000)
      };
    }
    AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput
        assetReaderTrackOutputWithTrack:track
                         outputSettings:readerOutputSettings];
    AVAssetWriterInput *input =
        [AVAssetWriterInput assetWriterInputWithMediaType:track.mediaType
                                           outputSettings:writerOuputSettings];
    if ([reader canAddOutput:output] && [writer canAddInput:input]) {
      [reader addOutput:output];
      [writer addInput:input];
    }
  }
  AVAssetWriterInput *input = [self createStillImageTimeAssetWriterInput];
  AVAssetWriterInputMetadataAdaptor *adaptor =
      [AVAssetWriterInputMetadataAdaptor
          assetWriterInputMetadataAdaptorWithAssetWriterInput:input];
  if ([writer canAddInput:input]) {
    [writer addInput:input];
  }
  [writer startWriting];
  [writer startSessionAtSourceTime:kCMTimeZero];
  [reader startReading];
  AVMetadataItem *timedItem = [self createStillImageTimeMetadataItem];
  CMTimeRange timedRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(1, 100));
  AVTimedMetadataGroup *timedMetadataGroup =
      [[AVTimedMetadataGroup alloc] initWithItems:@[ timedItem ]
                                        timeRange:timedRange];
  [adaptor appendTimedMetadataGroup:timedMetadataGroup];
  DYYYManager.shared->reader = reader;
  DYYYManager.shared->writer = writer;
  DYYYManager.shared->queue =
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  DYYYManager.shared->group = dispatch_group_create();
  for (NSInteger i = 0; i < reader.outputs.count; ++i) {
    dispatch_group_enter(DYYYManager.shared->group);
    [self writeTrack:i];
  }
}

- (void)writeTrack:(NSInteger)trackIndex {
  AVAssetReaderOutput *output = DYYYManager.shared->reader.outputs[trackIndex];
  AVAssetWriterInput *input = DYYYManager.shared->writer.inputs[trackIndex];

  [input
      requestMediaDataWhenReadyOnQueue:DYYYManager.shared->queue
                            usingBlock:^{
                              while (input.readyForMoreMediaData) {
                                AVAssetReaderStatus status =
                                    DYYYManager.shared->reader.status;
                                CMSampleBufferRef buffer = NULL;
                                if ((status == AVAssetReaderStatusReading) &&
                                    (buffer = [output copyNextSampleBuffer])) {
                                  BOOL success =
                                      [input appendSampleBuffer:buffer];
                                  CFRelease(buffer);
                                  if (!success) {

                                    [input markAsFinished];
                                    dispatch_group_leave(
                                        DYYYManager.shared->group);
                                    return;
                                  }
                                } else {
                                  if (status == AVAssetReaderStatusReading) {

                                  } else if (status ==
                                             AVAssetReaderStatusCompleted) {

                                  } else if (status ==
                                             AVAssetReaderStatusCancelled) {

                                  } else if (status ==
                                             AVAssetReaderStatusFailed) {
                                  }
                                  [input markAsFinished];
                                  dispatch_group_leave(
                                      DYYYManager.shared->group);
                                  return;
                                }
                              }
                            }];
}
- (AVMetadataItem *)createContentIdentifierMetadataItem:(NSString *)identifier {
  AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
  item.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
  item.key = AVMetadataQuickTimeMetadataKeyContentIdentifier;
  item.value = identifier;
  return item;
}

- (AVAssetWriterInput *)createStillImageTimeAssetWriterInput {
  NSArray *spec = @[ @{
    (NSString *)
    kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier :
        @"mdta/com.apple.quicktime.still-image-time",
    (NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType :
        (NSString *)kCMMetadataBaseDataType_SInt8
  } ];
  CMFormatDescriptionRef desc = NULL;
  CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
      kCFAllocatorDefault, kCMMetadataFormatType_Boxed,
      (__bridge CFArrayRef)spec, &desc);
  AVAssetWriterInput *input =
      [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata
                                         outputSettings:nil
                                       sourceFormatHint:desc];
  return input;
}

- (AVMetadataItem *)createStillImageTimeMetadataItem {
  AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
  item.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
  item.key = @"com.apple.quicktime.still-image-time";
  item.value = @(-1);
  item.dataType = (NSString *)kCMMetadataBaseDataType_SInt8;
  return item;
}
- (NSString *)filePathFromTmp:(NSString *)filename {
  NSString *tempPath = NSTemporaryDirectory();
  NSString *filePath = [tempPath stringByAppendingPathComponent:filename];
  return filePath;
}

- (void)deleteFile:(NSString *)file {
  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:file]) {
    [fm removeItemAtPath:file error:nil];
  }
}

+ (void)downloadAllLivePhotos:(NSArray<NSDictionary *> *)livePhotos {
  if (livePhotos.count == 0) {
    return;
  }

  [self downloadAllLivePhotosWithProgress:livePhotos
                                 progress:nil
                               completion:^(NSInteger successCount,
                                            NSInteger totalCount){
                               }];
}
+ (void)downloadAllLivePhotosWithProgress:(NSArray<NSDictionary *> *)livePhotos
                                 progress:(void (^)(NSInteger current, NSInteger total))progressBlock
                               completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion {
    if (livePhotos.count == 0) {
        if (completion) {
            completion(0, 0);
        }
        return;
    }

    // 检查iOS版本是否支持实况照片
    BOOL supportsLivePhoto = NO;
    if (@available(iOS 15.0, *)) {
        supportsLivePhoto = YES;
    }

    if (!supportsLivePhoto) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showToast:@"当前iOS版本不支持实况照片"];
            if (completion) {
                completion(0, livePhotos.count);
            }
        });
        return;
    }

    // 创建进度显示UI
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        DYYYToast *progressView = [[DYYYToast alloc] initWithFrame:screenBounds];
        [progressView show];

        progressView.cancelBlock = ^{
            [self cancelAllDownloads];
            if (completion) {
                completion(0, livePhotos.count);
            }
        };

        NSMutableArray<NSDictionary *> *downloadedFiles = [NSMutableArray arrayWithCapacity:livePhotos.count];
        for (int i = 0; i < livePhotos.count; i++) {
            [downloadedFiles addObject:@{@"imageURL": livePhotos[i][@"imageURL"], 
                                        @"videoURL": livePhotos[i][@"videoURL"],
                                        @"imagePath": [NSNull null],
                                        @"videoPath": [NSNull null]}];
        }

        // 进度计算 - 为三个阶段分配权重
        NSInteger totalSteps = livePhotos.count * 10; // 每个实况照片总共10步(4+4+2)
        __block NSInteger completedSteps = 0;
        __block NSInteger phase = 0; // 0:下载图片阶段，1:下载视频阶段，2:合成阶段
        
        // 创建临时目录
        NSString *livePhotoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LivePhotoBatch"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:livePhotoPath withIntermediateDirectories:YES attributes:nil error:nil];

        // 更新进度的block
        void (^updateProgress)(NSString *)= ^(NSString *statusText){
            float progress = (float)completedSteps / totalSteps;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [progressView setProgress:progress];
                if (progressBlock) {
                    progressBlock(completedSteps, totalSteps);
                }
            });
        };

        // 下载完成后的处理
        void (^finishProcess)(void) = ^{
            __block NSInteger successCount = 0;
            
            // 请求相册权限
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {

                    dispatch_queue_t processQueue = dispatch_queue_create("com.dyyy.livephoto.process", DISPATCH_QUEUE_SERIAL);
                    dispatch_group_t saveGroup = dispatch_group_create();
                    
                    NSInteger validFileCount = 0;
                    for (NSDictionary *fileInfo in downloadedFiles) {
                        NSString *imagePath = fileInfo[@"imagePath"];
                        NSString *videoPath = fileInfo[@"videoPath"];
                        
                        if (![imagePath isKindOfClass:[NSNull class]] && 
                            ![videoPath isKindOfClass:[NSNull class]] &&
                            [fileManager fileExistsAtPath:imagePath] && 
                            [fileManager fileExistsAtPath:videoPath]) {
                            validFileCount++;
                        }
                    }
                    
                    if (validFileCount == 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [progressView dismiss];
                            [fileManager removeItemAtPath:livePhotoPath error:nil];
                            if (completion) {
                                completion(0, livePhotos.count);
                            }
                        });
                        return;
                    }
                    
                    float progressPerItem = (float)(livePhotos.count * 2) / totalSteps;
                    __block NSInteger processedCount = 0;
                    
                    for (NSDictionary *fileInfo in downloadedFiles) {
                        NSString *imagePath = fileInfo[@"imagePath"];
                        NSString *videoPath = fileInfo[@"videoPath"];
                        
                        if (![imagePath isKindOfClass:[NSNull class]] && 
                            ![videoPath isKindOfClass:[NSNull class]] &&
                            [fileManager fileExistsAtPath:imagePath] && 
                            [fileManager fileExistsAtPath:videoPath]) {
                            
                            dispatch_group_enter(saveGroup);
                            
                            dispatch_async(processQueue, ^{
                                // 生成唯一标识符
                                NSString *identifier = [NSUUID UUID].UUIDString;
                                
                                // 创建每个任务的专属实例变量，避免共享变量冲突
                                AVAssetReader *localReader = nil;
                                AVAssetWriter *localWriter = nil;
                                dispatch_queue_t localQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                                dispatch_group_t localGroup = dispatch_group_create();
                                
                                // 处理照片和元数据
                                NSString *photoName = [imagePath lastPathComponent];
                                NSString *photoFile = [[DYYYManager shared] filePathFromTmp:photoName];
                                [[DYYYManager shared] addMetadataToPhoto:[NSURL fileURLWithPath:imagePath] 
                                                              outputFile:photoFile 
                                                             identifier:identifier];
                                
                                // 处理视频和元数据
                                NSString *videoName = [videoPath lastPathComponent];
                                NSString *videoFile = [[DYYYManager shared] filePathFromTmp:videoName];
                                
                                // 使用本地变量而非全局共享变量
                                [[DYYYManager shared] addMetadataToVideoWithLocalVars:[NSURL fileURLWithPath:videoPath]
                                                                          outputFile:videoFile
                                                                         identifier:identifier
                                                                           reader:&localReader
                                                                           writer:&localWriter
                                                                            queue:localQueue
                                                                            group:localGroup
                                                                         complete:^(BOOL success, NSString *photoFile, NSString *videoFile, NSError *error) {
                                    if (success) {
                                        NSURL *photo = [NSURL fileURLWithPath:photoFile];
                                        NSURL *video = [NSURL fileURLWithPath:videoFile];
                                        
                                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                            PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                                            [request addResourceWithType:PHAssetResourceTypePhoto fileURL:photo options:nil];
                                            [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:video options:nil];
                                        } completionHandler:^(BOOL success, NSError *_Nullable error) {
                                            if (success) {
                                                successCount++;
                                            }
                                            
                                            NSArray *filesToDelete = @[imagePath, videoPath, photoFile, videoFile];
                                            for (NSString *path in filesToDelete) {
                                                [fileManager removeItemAtPath:path error:nil];
                                            }
                                            
                                            // 增加进度步数
                                            processedCount++;
                                            completedSteps += 2; // 每完成一个合成任务增加2步
                                            updateProgress([NSString stringWithFormat:@"已合成 %ld/%ld", (long)processedCount, (long)validFileCount]);
                                            
                                            dispatch_group_leave(saveGroup);
                                        }];
                                    } else {
                                        [fileManager removeItemAtPath:imagePath error:nil];
                                        [fileManager removeItemAtPath:videoPath error:nil];
                                        if (photoFile) [fileManager removeItemAtPath:photoFile error:nil];
                                        if (videoFile) [fileManager removeItemAtPath:videoFile error:nil];
                                        
                                        // 增加进度步数（即使失败也增加）
                                        processedCount++;
                                        completedSteps += 2;
                                        updateProgress([NSString stringWithFormat:@"已合成 %ld/%ld", (long)processedCount, (long)validFileCount]);
                                        
                                        dispatch_group_leave(saveGroup);
                                    }
                                }];
                            });
                        }
                    }
                    
                    dispatch_group_notify(saveGroup, dispatch_get_main_queue(), ^{
                        [progressView dismiss];
                        
                        [fileManager removeItemAtPath:livePhotoPath error:nil];
                        
                        if (completion) {
                            completion(successCount, livePhotos.count);
                        }
                    });
                } else {
                    // 没有相册权限
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [progressView dismiss];
                        [self showToast:@"没有相册权限，无法保存实况照片"];
                        
                        [fileManager removeItemAtPath:livePhotoPath error:nil];
                        
                        if (completion) {
                            completion(0, livePhotos.count);
                        }
                    });
                }
            }];
        };

        // 第一阶段：批量下载所有图片
        dispatch_group_t imageDownloadGroup = dispatch_group_create();
        updateProgress(@"正在下载图片...");
        
        for (NSInteger i = 0; i < livePhotos.count; i++) {
            NSDictionary *livePhoto = downloadedFiles[i];
            NSString *imageURLString = livePhoto[@"imageURL"];
            NSURL *imageURL = [NSURL URLWithString:imageURLString];
            
            if (!imageURL) {
                completedSteps += 4; // 图片下载占4步
                continue;
            }
            
            dispatch_group_enter(imageDownloadGroup);
            
            // 创建文件路径
            NSString *uniqueID = [NSUUID UUID].UUIDString;
            NSString *imagePath = [livePhotoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.heic", uniqueID]];
            
            // 配置下载会话
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            configuration.timeoutIntervalForRequest = 60.0;
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            
            NSURLSessionDataTask *imageTask = [session dataTaskWithURL:imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (!error && data) {
                    if ([data writeToFile:imagePath atomically:YES]) {
                        NSMutableDictionary *updatedInfo = [downloadedFiles[i] mutableCopy];
                        updatedInfo[@"imagePath"] = imagePath;
                        downloadedFiles[i] = updatedInfo;
                    }
                }
                
                completedSteps += 4; // 图片下载占4步
                updateProgress([NSString stringWithFormat:@"已下载图片 %ld/%ld", (long)(i+1), (long)livePhotos.count]);
                dispatch_group_leave(imageDownloadGroup);
            }];
            
            [imageTask resume];
        }
        
        // 所有图片下载完成后，开始下载视频
        dispatch_group_notify(imageDownloadGroup, dispatch_get_main_queue(), ^{
            phase = 1; // 进入视频下载阶段
            updateProgress(@"正在下载视频...");
            
            dispatch_group_t videoDownloadGroup = dispatch_group_create();
            
            for (NSInteger i = 0; i < livePhotos.count; i++) {
                NSDictionary *fileInfo = downloadedFiles[i];
                
                // 只处理图片下载成功的项
                if ([fileInfo[@"imagePath"] isKindOfClass:[NSNull class]]) {
                    completedSteps += 4; // 视频下载占4步
                    continue;
                }
                
                NSString *videoURLString = fileInfo[@"videoURL"];
                NSURL *videoURL = [NSURL URLWithString:videoURLString];
                
                if (!videoURL) {
                    completedSteps += 4; // 视频下载占4步
                    continue;
                }
                
                dispatch_group_enter(videoDownloadGroup);
                
                // 使用与图片相同的ID但不同的扩展名
                NSString *imagePath = fileInfo[@"imagePath"];
                NSString *baseName = [[imagePath lastPathComponent] stringByDeletingPathExtension];
                NSString *videoPath = [livePhotoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", baseName]];
                
                // 配置下载会话
                NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                configuration.timeoutIntervalForRequest = 60.0;
                NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
                
                NSURLSessionDataTask *videoTask = [session dataTaskWithURL:videoURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (!error && data) {
                        if ([data writeToFile:videoPath atomically:YES]) {
                            NSMutableDictionary *updatedInfo = [downloadedFiles[i] mutableCopy];
                            updatedInfo[@"videoPath"] = videoPath;
                            downloadedFiles[i] = updatedInfo;
                        }
                    }
                    
                    completedSteps += 4; // 视频下载占4步
                    updateProgress([NSString stringWithFormat:@"已下载视频 %ld/%ld", (long)(i+1), (long)livePhotos.count]);
                    dispatch_group_leave(videoDownloadGroup);
                }];
                
                [videoTask resume];
            }
            
            // 所有视频下载完成后，开始合成实况照片
            dispatch_group_notify(videoDownloadGroup, dispatch_get_main_queue(), ^{
                phase = 2; // 进入合成阶段
                finishProcess();
            });
        });
    });
}

// 使用本地变量处理视频
- (void)addMetadataToVideoWithLocalVars:(NSURL *)videoURL
                             outputFile:(NSString *)outputFile
                            identifier:(NSString *)identifier
                                reader:(AVAssetReader **)readerPtr
                                writer:(AVAssetWriter **)writerPtr
                                 queue:(dispatch_queue_t)queue
                                 group:(dispatch_group_t)group
                              complete:(void (^)(BOOL success, NSString *photoFile, NSString *videoFile, NSError *error))complete {
    NSError *error = nil;
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (error) {
        if (complete) complete(NO, nil, nil, error);
        return;
    }
    
    *readerPtr = reader;
    
    NSMutableArray<AVMetadataItem *> *metadata = asset.metadata.mutableCopy;
    AVMetadataItem *item = [self createContentIdentifierMetadataItem:identifier];
    [metadata addObject:item];
    NSURL *videoFileURL = [NSURL fileURLWithPath:outputFile];
    [self deleteFile:outputFile];
    
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:videoFileURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
        if (complete) complete(NO, nil, nil, error);
        return;
    }
    
    *writerPtr = writer;
    [writer setMetadata:metadata];
    
    NSArray<AVAssetTrack *> *tracks = [asset tracks];
    for (AVAssetTrack *track in tracks) {
        NSDictionary *readerOutputSettings = nil;
        NSDictionary *writerOuputSettings = nil;
        if ([track.mediaType isEqualToString:AVMediaTypeAudio]) {
            readerOutputSettings = @{AVFormatIDKey : @(kAudioFormatLinearPCM)};
            writerOuputSettings = @{
                AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                AVSampleRateKey : @(44100),
                AVNumberOfChannelsKey : @(2),
                AVEncoderBitRateKey : @(128000)
            };
        }
        
        AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:readerOutputSettings];
        AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:track.mediaType outputSettings:writerOuputSettings];
        
        if ([reader canAddOutput:output] && [writer canAddInput:input]) {
            [reader addOutput:output];
            [writer addInput:input];
        }
    }
    
    AVAssetWriterInput *input = [self createStillImageTimeAssetWriterInput];
    AVAssetWriterInputMetadataAdaptor *adaptor = [AVAssetWriterInputMetadataAdaptor assetWriterInputMetadataAdaptorWithAssetWriterInput:input];
    if ([writer canAddInput:input]) {
        [writer addInput:input];
    }
    
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    [reader startReading];
    
    AVMetadataItem *timedItem = [self createStillImageTimeMetadataItem];
    CMTimeRange timedRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(1, 100));
    AVTimedMetadataGroup *timedMetadataGroup = [[AVTimedMetadataGroup alloc] initWithItems:@[ timedItem ] timeRange:timedRange];
    [adaptor appendTimedMetadataGroup:timedMetadataGroup];
    
    for (NSInteger i = 0; i < reader.outputs.count; ++i) {
        dispatch_group_enter(group);
        [self writeTrackWithLocalVars:i reader:reader writer:writer queue:queue group:group];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [reader cancelReading];
        [writer finishWritingWithCompletionHandler:^{
            AVAssetWriterStatus status = writer.status;
            if (status == AVAssetWriterStatusCompleted) {
                NSString *photoName = [[videoURL lastPathComponent] stringByDeletingPathExtension];
                NSString *photoFile = [self filePathFromTmp:[photoName stringByAppendingPathExtension:@"heic"]];
                if (complete) complete(YES, photoFile, outputFile, nil);
            } else {
                if (complete) complete(NO, nil, nil, writer.error);
            }
        }];
    });
}

// 处理视频曲目的写入
- (void)writeTrackWithLocalVars:(NSInteger)trackIndex 
                         reader:(AVAssetReader *)reader
                         writer:(AVAssetWriter *)writer
                          queue:(dispatch_queue_t)queue 
                          group:(dispatch_group_t)group {
    AVAssetReaderOutput *output = reader.outputs[trackIndex];
    AVAssetWriterInput *input = writer.inputs[trackIndex];

    [input requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        while (input.readyForMoreMediaData) {
            AVAssetReaderStatus status = reader.status;
            CMSampleBufferRef buffer = NULL;
            if ((status == AVAssetReaderStatusReading) && (buffer = [output copyNextSampleBuffer])) {
                BOOL success = [input appendSampleBuffer:buffer];
                CFRelease(buffer);
                if (!success) {
                    [input markAsFinished];
                    dispatch_group_leave(group);
                    return;
                }
            } else {
                [input markAsFinished];
                dispatch_group_leave(group);
                return;
            }
        }
    }];
}

+ (BOOL)isDarkMode {
  return [NSClassFromString(@"AWEUIThemeManager") isLightTheme] ? NO : YES;
}

+ (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink
                                    apiKey:(NSString *)apiKey {
  if (shareLink.length == 0 || apiKey.length == 0) {
    [self showToast:@"分享链接或API密钥无效"];
    return;
  }

  NSString *apiUrl = [NSString
      stringWithFormat:@"%@%@", apiKey,
                       [shareLink
                           stringByAddingPercentEncodingWithAllowedCharacters:
                               [NSCharacterSet URLQueryAllowedCharacterSet]]];

  NSURL *url = [NSURL URLWithString:apiUrl];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  NSURLSession *session = [NSURLSession sharedSession];

  NSURLSessionDataTask *dataTask = [session
      dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
              [self showToast:[NSString
                                  stringWithFormat:@"接口请求失败: %@",
                                                   error.localizedDescription]];
              return;
            }

            NSError *jsonError;
            NSDictionary *json =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:&jsonError];
            if (jsonError) {
              [self showToast:@"解析接口返回数据失败"];
              return;
            }

            NSInteger code = [json[@"code"] integerValue];
            if (code != 0 && code != 200) {
              [self showToast:[NSString stringWithFormat:@"接口返回错误: %@",
                                                         json[@"msg"]
                                                             ?: @"未知错误"]];
              return;
            }

            NSDictionary *dataDict = json[@"data"];
            if (!dataDict) {
              [self showToast:@"接口返回数据为空"];
              return;
            }
            NSArray *videos = dataDict[@"videos"];
            NSArray *images = dataDict[@"images"];
            NSArray *videoList = dataDict[@"video_list"];
            BOOL hasVideos =
                [videos isKindOfClass:[NSArray class]] && videos.count > 0;
            BOOL hasImages =
                [images isKindOfClass:[NSArray class]] && images.count > 0;
            BOOL hasVideoList = [videoList isKindOfClass:[NSArray class]] &&
                                videoList.count > 0;
            BOOL shouldShowQualityOptions =
                [[NSUserDefaults standardUserDefaults]
                    boolForKey:@"DYYYShowAllVideoQuality"];

            // 如果启用了显示清晰度选项，并且存在 videoList，则弹出选择面板
            if (shouldShowQualityOptions && hasVideoList) {
              AWEUserActionSheetView *actionSheet =
                  [[NSClassFromString(@"AWEUserActionSheetView") alloc] init];
              NSMutableArray *actions = [NSMutableArray array];

              for (NSDictionary *videoDict in videoList) {
                NSString *url = videoDict[@"url"];
                NSString *level = videoDict[@"level"];
                if (url.length > 0 && level.length > 0) {
                  AWEUserSheetAction *qualityAction = [NSClassFromString(
                      @"AWEUserSheetAction")
                      actionWithTitle:level
                              imgName:nil
                              handler:^{
                                NSURL *videoDownloadUrl =
                                    [NSURL URLWithString:url];
                                [self
                                    downloadMedia:videoDownloadUrl
                                        mediaType:MediaTypeVideo
                                       completion:^(BOOL success) {
                                         if (success) {
                                         } else {
                                           [self showToast:
                                                     [NSString
                                                         stringWithFormat:
                                                             @"已取消保存 (%@)",
                                                             level]];
                                         }
                                       }];
                              }];
                  [actions addObject:qualityAction];
                }
              }

              // 附加批量下载选项（如果开启清晰度选项 + 有视频/图片）
              if (hasVideos || hasImages) {
                AWEUserSheetAction *batchDownloadAction =
                    [NSClassFromString(@"AWEUserSheetAction")
                        actionWithTitle:@"批量下载所有资源"
                                imgName:nil
                                handler:^{
                                  [self batchDownloadResources:videos
                                                        images:images];
                                }];
                [actions addObject:batchDownloadAction];
              }

              if (actions.count > 0) {
                [actionSheet setActions:actions];
                [actionSheet show];
                return;
              }
            }

            // 如果未开启清晰度选项，但有 video_list，自动下载第一个清晰度
            if (!shouldShowQualityOptions && hasVideoList) {
              NSDictionary *firstVideo = videoList.firstObject;
              NSString *url = firstVideo[@"url"];
              NSString *level = firstVideo[@"level"] ?: @"默认清晰度";

              if (url.length > 0) {
                NSURL *videoDownloadUrl = [NSURL URLWithString:url];
                [self downloadMedia:videoDownloadUrl
                          mediaType:MediaTypeVideo
                         completion:^(BOOL success) {
                           if (success) {
                           } else {
                             [self showToast:[NSString stringWithFormat:
                                                           @"已取消保存 (%@)",
                                                           level]];
                           }
                         }];
                return;
              }
            }

            [self batchDownloadResources:videos images:images];
          });
        }];

  [dataTask resume];
}

+ (void)batchDownloadResources:(NSArray *)videos images:(NSArray *)images {
  BOOL hasVideos = [videos isKindOfClass:[NSArray class]] && videos.count > 0;
  BOOL hasImages = [images isKindOfClass:[NSArray class]] && images.count > 0;

  NSMutableArray<id> *videoFiles =
      [NSMutableArray arrayWithCapacity:videos.count];
  NSMutableArray<id> *imageFiles =
      [NSMutableArray arrayWithCapacity:images.count];
  for (NSInteger i = 0; i < videos.count; i++)
    [videoFiles addObject:[NSNull null]];
  for (NSInteger i = 0; i < images.count; i++)
    [imageFiles addObject:[NSNull null]];

  dispatch_group_t downloadGroup = dispatch_group_create();
  __block NSInteger totalDownloads = 0;
  __block NSInteger completedDownloads = 0;
  __block NSInteger successfulDownloads = 0;

  if (hasVideos) {
    totalDownloads += videos.count;
    for (NSInteger i = 0; i < videos.count; i++) {
      NSDictionary *videoDict = videos[i];
      NSString *videoUrl = videoDict[@"url"];
      if (videoUrl.length == 0) {
        completedDownloads++;
        continue;
      }
      dispatch_group_enter(downloadGroup);
      NSURL *videoDownloadUrl = [NSURL URLWithString:videoUrl];
      [self downloadMediaWithProgress:videoDownloadUrl
                            mediaType:MediaTypeVideo
                             progress:nil
                           completion:^(BOOL success, NSURL *fileURL) {
                             if (success && fileURL) {
                               @synchronized(videoFiles) {
                                 videoFiles[i] = fileURL;
                               }
                               successfulDownloads++;
                             }
                             completedDownloads++;
                             dispatch_group_leave(downloadGroup);
                           }];
    }
  }

  if (hasImages) {
    totalDownloads += images.count;
    for (NSInteger i = 0; i < images.count; i++) {
      NSString *imageUrl = images[i];
      if (imageUrl.length == 0) {
        completedDownloads++;
        continue;
      }
      dispatch_group_enter(downloadGroup);
      NSURL *imageDownloadUrl = [NSURL URLWithString:imageUrl];
      [self downloadMediaWithProgress:imageDownloadUrl
                            mediaType:MediaTypeImage
                             progress:nil
                           completion:^(BOOL success, NSURL *fileURL) {
                             if (success && fileURL) {
                               @synchronized(imageFiles) {
                                 imageFiles[i] = fileURL;
                               }
                               successfulDownloads++;
                             }
                             completedDownloads++;
                             dispatch_group_leave(downloadGroup);
                           }];
    }
  }

  dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
    NSInteger videoSuccessCount = 0;
    for (id file in videoFiles) {
      if ([file isKindOfClass:[NSURL class]]) {
        [self saveMedia:(NSURL *)file mediaType:MediaTypeVideo completion:nil];
        videoSuccessCount++;
      }
    }

    NSInteger imageSuccessCount = 0;
    for (id file in imageFiles) {
      if ([file isKindOfClass:[NSURL class]]) {
        [self saveMedia:(NSURL *)file mediaType:MediaTypeImage completion:nil];
        imageSuccessCount++;
      }
    }
  });
}

#define DYYYLogVideo(format, ...) NSLog((@"[DYYY视频合成] " format), ##__VA_ARGS__)
// 创建视频合成器从多种媒体源
+ (void)createVideoFromMedia:(NSArray<NSString *> *)imageURLs
                  livePhotos:(NSArray<NSDictionary *> *)livePhotos
                      bgmURL:(NSString *)bgmURL
                    progress:(void (^)(NSInteger current, NSInteger total, NSString *status))progressBlock
                  completion:(void (^)(BOOL success, NSString *message))completion {
    DYYYLogVideo(@"开始创建视频 - 图片数量: %lu, 实况照片数量: %lu, 背景音乐: %@", 
                (unsigned long)imageURLs.count, 
                (unsigned long)livePhotos.count, 
                bgmURL.length > 0 ? @"有" : @"无");
                
    if ((imageURLs.count == 0 && livePhotos.count == 0) || 
        (imageURLs == nil && livePhotos == nil)) {
        DYYYLogVideo(@"错误: 没有提供媒体资源");
        if (completion) {
            completion(NO, @"没有提供媒体资源");
        }
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        DYYYToast *progressView = [[DYYYToast alloc] initWithFrame:screenBounds];
        [progressView show];
        
        progressView.cancelBlock = ^{
            DYYYLogVideo(@"用户取消了视频合成");
            [self cancelAllDownloads];
            if (completion) {
                completion(NO, @"用户取消了操作");
            }
        };
        
        // 创建临时目录
        NSString *mediaPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"VideoComposition"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:mediaPath]) {
            DYYYLogVideo(@"正在清理旧的临时目录: %@", mediaPath);
            [fileManager removeItemAtPath:mediaPath error:nil];
        }
        
        NSError *dirError = nil;
        [fileManager createDirectoryAtPath:mediaPath withIntermediateDirectories:YES attributes:nil error:&dirError];
        if (dirError) {
            DYYYLogVideo(@"创建临时目录失败: %@", dirError);
            if (completion) {
                completion(NO, @"创建临时文件夹失败");
            }
            return;
        }
        DYYYLogVideo(@"成功创建临时目录: %@", mediaPath);
        
        // 计算总共需要下载的文件数和合成步骤
        NSInteger totalImages = imageURLs.count;
        NSInteger totalLivePhotos = livePhotos.count * 2; // 每个实况照片有2个文件
        NSInteger hasBGM = (bgmURL.length > 0) ? 1 : 0;
        
        // 总步骤：下载所有媒体 + 合成视频 + 保存视频
        NSInteger totalSteps = totalImages + totalLivePhotos + hasBGM + 2;
        __block NSInteger completedSteps = 0;
        
        // 储存下载的媒体文件路径
        NSMutableArray *imageFilePaths = [NSMutableArray array];
        NSMutableArray<NSDictionary *> *livePhotoFilePaths = [NSMutableArray array];
        __block NSString *bgmFilePath = nil;
        
        void (^updateProgress)(NSString *) = ^(NSString *status) {
            float progress = (float)completedSteps / totalSteps;
            dispatch_async(dispatch_get_main_queue(), ^{
                [progressView setProgress:progress];
                DYYYLogVideo(@"进度更新: %.2f%% - %@", progress * 100, status);
                if (progressBlock) {
                    progressBlock(completedSteps, totalSteps, status);
                }
            });
        };
        
        // 第一阶段：下载所有普通图片
        dispatch_group_t imageDownloadGroup = dispatch_group_create();
        updateProgress(@"正在下载图片...");

        for (NSInteger i = 0; i < imageURLs.count; i++) {
            NSString *imageURLString = imageURLs[i];
            NSURL *imageURL = [NSURL URLWithString:imageURLString];
            
            if (!imageURL) {
                DYYYLogVideo(@"图片URL无效: %@", imageURLString);
                completedSteps++;
                updateProgress(@"图片URL无效");
                continue;
            }
            
            dispatch_group_enter(imageDownloadGroup);
            
            // 创建文件路径
            NSString *uniqueID = [NSUUID UUID].UUIDString;
            NSString *imagePath = [mediaPath stringByAppendingPathComponent:[NSString stringWithFormat:@"image_%@.jpg", uniqueID]];
            DYYYLogVideo(@"开始下载图片 %ld/%ld: %@", (long)(i+1), (long)imageURLs.count, imageURLString);
            
            // 配置下载会话
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            
            NSURLSessionDataTask *imageTask = [session dataTaskWithURL:imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) {
                    DYYYLogVideo(@"下载图片失败 %ld/%ld: %@", (long)(i+1), (long)imageURLs.count, error);
                } else if (!data) {
                    DYYYLogVideo(@"下载图片数据为空 %ld/%ld", (long)(i+1), (long)imageURLs.count);
                } else {
                    NSInteger dataSize = data.length;
                    if ([data writeToFile:imagePath atomically:YES]) {
                        DYYYLogVideo(@"成功下载并保存图片 %ld/%ld: %@ (大小: %.2f KB)", 
                                   (long)(i+1), (long)imageURLs.count, imagePath, dataSize/1024.0);
                        [imageFilePaths addObject:imagePath];
                    } else {
                        DYYYLogVideo(@"保存图片文件失败 %ld/%ld: %@", (long)(i+1), (long)imageURLs.count, imagePath);
                    }
                }
                
                completedSteps++;
                updateProgress([NSString stringWithFormat:@"已下载图片 %ld/%ld", (long)(i+1), (long)imageURLs.count]);
                dispatch_group_leave(imageDownloadGroup);
            }];
            
            [imageTask resume];
        }
        
        // 第二阶段：下载所有实况照片
        dispatch_group_t livePhotoDownloadGroup = dispatch_group_create();
        
        dispatch_group_notify(imageDownloadGroup, dispatch_get_main_queue(), ^{
            DYYYLogVideo(@"第一阶段完成，已下载 %ld 张图片", (long)imageFilePaths.count);
            updateProgress(@"正在下载实况照片...");
            DYYYLogVideo(@"开始第二阶段: 下载实况照片 (%ld 项)", (long)livePhotos.count);
            
            for (NSInteger i = 0; i < livePhotos.count; i++) {
                NSDictionary *livePhoto = livePhotos[i];
                NSString *imageURLString = livePhoto[@"imageURL"];
                NSString *videoURLString = livePhoto[@"videoURL"];
                NSURL *imageURL = [NSURL URLWithString:imageURLString];
                NSURL *videoURL = [NSURL URLWithString:videoURLString];
                
                if (!imageURL || !videoURL) {
                    DYYYLogVideo(@"实况照片URL无效: 图片=%@, 视频=%@", imageURLString, videoURLString);
                    completedSteps += 2;
                    updateProgress(@"实况照片URL无效");
                    continue;
                }
                
                NSString *uniqueID = [NSUUID UUID].UUIDString;
                NSString *imagePath = [mediaPath stringByAppendingPathComponent:[NSString stringWithFormat:@"livephoto_img_%@.jpg", uniqueID]];
                NSString *videoPath = [mediaPath stringByAppendingPathComponent:[NSString stringWithFormat:@"livephoto_vid_%@.mp4", uniqueID]];
                
                // 下载图片部分
                dispatch_group_enter(livePhotoDownloadGroup);
                NSURLSessionConfiguration *imgConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                NSURLSession *imgSession = [NSURLSession sessionWithConfiguration:imgConfig];
                
                DYYYLogVideo(@"开始下载实况照片图片部分 %ld/%ld: %@", (long)(i+1), (long)livePhotos.count, imageURLString);
                NSURLSessionDataTask *imageTask = [imgSession dataTaskWithURL:imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        DYYYLogVideo(@"下载实况照片图片部分失败 %ld/%ld: %@", (long)(i+1), (long)livePhotos.count, error);
                    } else if (!data) {
                        DYYYLogVideo(@"下载实况照片图片数据为空 %ld/%ld", (long)(i+1), (long)livePhotos.count);
                    } else if ([data writeToFile:imagePath atomically:YES]) {
                        DYYYLogVideo(@"成功保存实况照片图片部分 %ld/%ld: %@ (大小: %.2f KB)", 
                                   (long)(i+1), (long)livePhotos.count, imagePath, data.length/1024.0);
                    } else {
                        DYYYLogVideo(@"保存实况照片图片文件失败 %ld/%ld: %@", (long)(i+1), (long)livePhotos.count, imagePath);
                    }
                    
                    completedSteps++;
                    updateProgress([NSString stringWithFormat:@"已下载实况照片(图片) %ld/%ld", (long)(i+1), (long)livePhotos.count]);
                    dispatch_group_leave(livePhotoDownloadGroup);
                }];
                
                // 下载视频部分
                dispatch_group_enter(livePhotoDownloadGroup);
                NSURLSessionConfiguration *vidConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                NSURLSession *vidSession = [NSURLSession sessionWithConfiguration:vidConfig];
                
                DYYYLogVideo(@"开始下载实况照片视频部分 %ld/%ld: %@", (long)(i+1), (long)livePhotos.count, videoURLString);
                NSURLSessionDataTask *videoTask = [vidSession dataTaskWithURL:videoURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        DYYYLogVideo(@"下载实况照片视频部分失败 %ld/%ld: %@", (long)(i+1), (long)livePhotos.count, error);
                    } else if (!data) {
                        DYYYLogVideo(@"下载实况照片视频数据为空 %ld/%ld", (long)(i+1), (long)livePhotos.count);
                    } else if ([data writeToFile:videoPath atomically:YES]) {
                        DYYYLogVideo(@"成功保存实况照片视频部分 %ld/%ld: %@ (大小: %.2f MB)", 
                                   (long)(i+1), (long)livePhotos.count, videoPath, data.length/(1024.0*1024.0));
                        @synchronized(livePhotoFilePaths) {
                            [livePhotoFilePaths addObject:@{
                                @"image": imagePath,
                                @"video": videoPath
                            }];
                            DYYYLogVideo(@"成功记录实况照片对: 图片=%@, 视频=%@", imagePath, videoPath);
                        }
                    } else {
                        DYYYLogVideo(@"保存实况照片视频文件失败 %ld/%ld: %@", (long)(i+1), (long)livePhotos.count, videoPath);
                    }
                    
                    completedSteps++;
                    updateProgress([NSString stringWithFormat:@"已下载实况照片(视频) %ld/%ld", (long)(i+1), (long)livePhotos.count]);
                    dispatch_group_leave(livePhotoDownloadGroup);
                }];
                
                [imageTask resume];
                [videoTask resume];
            }
            
            // 第三阶段：下载背景音乐
            dispatch_group_t bgmDownloadGroup = dispatch_group_create();
            
            dispatch_group_notify(livePhotoDownloadGroup, dispatch_get_main_queue(), ^{
                DYYYLogVideo(@"第二阶段完成，已下载 %ld 组实况照片", (long)livePhotoFilePaths.count);
                
                if (bgmURL.length > 0) {
                    DYYYLogVideo(@"开始第三阶段: 下载背景音乐 %@", bgmURL);
                    updateProgress(@"正在下载背景音乐...");
                    NSURL *bgmURL_obj = [NSURL URLWithString:bgmURL];
                    
                    if (!bgmURL_obj) {
                        DYYYLogVideo(@"背景音乐URL无效: %@", bgmURL);
                        completedSteps++;
                        updateProgress(@"背景音乐URL无效");
                    } else {
                        dispatch_group_enter(bgmDownloadGroup);
                        
                        // 创建文件路径
                        NSString *uniqueID = [NSUUID UUID].UUIDString;
                        NSString *audioPath = [mediaPath stringByAppendingPathComponent:[NSString stringWithFormat:@"bgm_%@.mp3", uniqueID]];
                        
                        // 配置下载会话
                        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
                        
                        NSURLSessionDataTask *audioTask = [session dataTaskWithURL:bgmURL_obj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                            if (error) {
                                DYYYLogVideo(@"下载背景音乐失败: %@", error);
                            } else if (!data) {
                                DYYYLogVideo(@"下载背景音乐数据为空");
                            } else if ([data writeToFile:audioPath atomically:YES]) {
                                DYYYLogVideo(@"成功保存背景音乐: %@ (大小: %.2f MB)", audioPath, data.length/(1024.0*1024.0));
                                bgmFilePath = audioPath;
                            } else {
                                DYYYLogVideo(@"保存背景音乐文件失败: %@", audioPath);
                            }
                            
                            completedSteps++;
                            updateProgress(@"背景音乐下载完成");
                            dispatch_group_leave(bgmDownloadGroup);
                        }];
                        
                        [audioTask resume];
                    }
                }
                
                // 第四阶段：合成视频
                dispatch_group_notify(bgmDownloadGroup, dispatch_get_main_queue(), ^{
                    DYYYLogVideo(@"第三阶段完成，背景音乐状态: %@", bgmFilePath ? @"已下载" : @"无或下载失败");
                    DYYYLogVideo(@"开始第四阶段: 合成视频");
                    updateProgress(@"正在合成视频...");
                    
                    // 如果没有成功下载任何媒体，则退出
                    if (imageFilePaths.count == 0 && livePhotoFilePaths.count == 0) {
                        DYYYLogVideo(@"错误: 没有成功下载任何媒体文件，取消合成");
                        [progressView dismiss];
                        if (completion) {
                            completion(NO, @"没有成功下载任何媒体文件");
                        }
                        [fileManager removeItemAtPath:mediaPath error:nil];
                        return;
                    }
                    
                    DYYYLogVideo(@"媒体文件统计: %ld张图片, %ld组实况照片, 背景音乐: %@", 
                               (long)imageFilePaths.count, 
                               (long)livePhotoFilePaths.count, 
                               bgmFilePath ? @"有" : @"无");
                    
                    NSString *outputPath = [mediaPath stringByAppendingPathComponent:[NSString stringWithFormat:@"final_%@.mp4", [NSUUID UUID].UUIDString]];
                    DYYYLogVideo(@"视频输出路径: %@", outputPath);
                    
                    // 使用AVFoundation合成视频
                    [self composeVideo:imageFilePaths 
                           livePhotos:livePhotoFilePaths 
                           bgmPath:bgmFilePath 
                           outputPath:outputPath 
                           completion:^(BOOL success) {
                        completedSteps++;
                        if (success) {
                            DYYYLogVideo(@"视频合成成功");
                        } else {
                            DYYYLogVideo(@"视频合成失败");
                        }
                        updateProgress(@"视频合成完成");
                        
                        if (success) {
                            DYYYLogVideo(@"开始保存视频到相册");
                            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:outputPath]];
                            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                                completedSteps++;
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [progressView dismiss];
                                    
                                    if (success) {
                                        DYYYLogVideo(@"视频已成功保存到相册");
                                        if (completion) {
                                            completion(YES, @"视频已成功保存到相册");
                                        }
                                    } else {
                                        DYYYLogVideo(@"保存视频到相册失败: %@", error);
                                        if (completion) {
                                            completion(NO, [NSString stringWithFormat:@"保存视频到相册失败: %@", error.localizedDescription]);
                                        }
                                    }
                                    
                                    DYYYLogVideo(@"清理临时文件: %@", mediaPath);
                                    [fileManager removeItemAtPath:mediaPath error:nil];
                                });
                            }];
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [progressView dismiss];
                                if (completion) {
                                    completion(NO, @"视频合成失败");
                                }
                                
                                DYYYLogVideo(@"清理临时文件: %@", mediaPath);
                                [fileManager removeItemAtPath:mediaPath error:nil];
                            });
                        }
                    }];
                });
            });
        });
    });
}

// 视频合成核心方法
+ (void)composeVideo:(NSArray<NSString *> *)imageFiles
          livePhotos:(NSArray<NSDictionary *> *)livePhotoFiles
             bgmPath:(NSString *)bgmPath
          outputPath:(NSString *)outputPath
          completion:(void (^)(BOOL success))completion {
    // 视频尺寸（标准1080p）
    CGSize videoSize = CGSizeMake(1080, 1920);
    DYYYLogVideo(@"开始合成视频 - 目标尺寸: %.0fx%.0f", videoSize.width, videoSize.height);
    DYYYLogVideo(@"媒体源: %ld张图片, %ld组实况照片, 背景音乐: %@", 
               (long)imageFiles.count, (long)livePhotoFiles.count, bgmPath ? @"有" : @"无");
    
    dispatch_group_t processingGroup = dispatch_group_create();
    
    // 存储所有媒体片段信息
    NSMutableArray *mediaSegments = [NSMutableArray array];
    
    // 处理静态图片 - 先将所有图片转换为临时视频片段
    for (NSInteger i = 0; i < imageFiles.count; i++) {
        NSString *imagePath = imageFiles[i];
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            DYYYLogVideo(@"错误: 图片文件不存在: %@", imagePath);
            continue;
        }
        
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        if (!image) {
            DYYYLogVideo(@"错误: 无法加载图片: %@", imagePath);
            continue;
        }
        DYYYLogVideo(@"处理图片 %ld/%ld: 尺寸 %.0fx%.0f", 
                   (long)(i+1), (long)imageFiles.count, image.size.width, image.size.height);
        
        // 创建临时视频文件路径
        NSString *tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"temp_img_%@.mp4", [NSUUID UUID].UUIDString]];
        
        dispatch_group_enter(processingGroup);
        
        // 使用Core Animation创建静态图片视频
        [self createVideoFromImage:image duration:5.0 outputPath:tempVideoPath completion:^(BOOL success) {
            if (success) {
                @synchronized(mediaSegments) {
                    [mediaSegments addObject:@{
                        @"type": @"image",
                        @"path": tempVideoPath,
                        @"duration": @5.0
                    }];
                    DYYYLogVideo(@"成功创建图片视频片段 %ld/%ld: %@", 
                               (long)(i+1), (long)imageFiles.count, tempVideoPath);
                }
            } else {
                DYYYLogVideo(@"错误: 创建图片视频片段失败 %ld/%ld", (long)(i+1), (long)imageFiles.count);
            }
            dispatch_group_leave(processingGroup);
        }];
    }
    
    // 处理实况照片 - 收集所有视频路径信息
    for (NSInteger i = 0; i < livePhotoFiles.count; i++) {
        NSDictionary *livePhoto = livePhotoFiles[i];
        NSString *imagePath = livePhoto[@"image"];
        NSString *videoPath = livePhoto[@"video"];
        
        DYYYLogVideo(@"处理实况照片 %ld/%ld: 图片=%@, 视频=%@", 
                   (long)(i+1), (long)livePhotoFiles.count, imagePath, videoPath);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
            DYYYLogVideo(@"错误: 实况照片视频不存在: %@", videoPath);
            continue;
        }
        
        [mediaSegments addObject:@{
            @"type": @"video",
            @"path": videoPath
        }];
        DYYYLogVideo(@"成功添加实况照片视频片段 %ld/%ld", (long)(i+1), (long)livePhotoFiles.count);
    }
    
    // 等待所有临时视频处理完成
    dispatch_group_notify(processingGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        DYYYLogVideo(@"所有媒体处理完成，共有 %ld 个可用片段", (long)mediaSegments.count);
        
        if (mediaSegments.count == 0) {
            DYYYLogVideo(@"错误: 没有有效的媒体片段可以合成");
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
            }
            return;
        }
        
        // 创建AVMutableComposition作为容器
        DYYYLogVideo(@"开始创建视频合成容器");
        AVMutableComposition *composition = [AVMutableComposition composition];
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.frameDuration = CMTimeMake(1, 30); // 30fps
        videoComposition.renderSize = videoSize;
        
        // 创建视频轨道
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo 
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
        if (!videoTrack) {
            DYYYLogVideo(@"错误: 无法创建视频轨道");
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
            }
            return;
        }
        
        // 创建音频轨道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
        if (!audioTrack) {
            DYYYLogVideo(@"错误: 无法创建音频轨道");
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
            }
            return;
        }
        
        // 添加背景音乐
        __block CMTime currentTime = kCMTimeZero;
        if (bgmPath && [[NSFileManager defaultManager] fileExistsAtPath:bgmPath]) {
            DYYYLogVideo(@"添加背景音乐: %@", bgmPath);
            AVAsset *audioAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:bgmPath]];
            AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            
            if (audioAssetTrack) {
                // 先处理所有视频片段以确定总时长
                CMTime totalDuration = kCMTimeZero;
                for (NSDictionary *segment in mediaSegments) {
                    NSString *segmentPath = segment[@"path"];
                    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:segmentPath]];
                    totalDuration = CMTimeAdd(totalDuration, asset.duration);
                }
                
                // 循环播放背景音乐直到覆盖整个视频时长
                CMTime audioDuration = audioAsset.duration;
                CMTime currentAudioTime = kCMTimeZero;
                
                if (CMTimeCompare(audioDuration, totalDuration) < 0) {
                    DYYYLogVideo(@"背景音乐时长(%.2f秒)小于视频时长(%.2f秒)，将循环播放", 
                               CMTimeGetSeconds(audioDuration), 
                               CMTimeGetSeconds(totalDuration));
                    
                    while (CMTimeCompare(currentAudioTime, totalDuration) < 0) {
                        // 确定当前片段的时长（如果到达视频末尾则截断）
                        CMTime remainingTime = CMTimeSubtract(totalDuration, currentAudioTime);
                        CMTime segmentDuration = audioDuration;
                        
                        if (CMTimeCompare(remainingTime, audioDuration) < 0) {
                            segmentDuration = remainingTime;
                        }
                        
                        // 插入音频片段
                        NSError *audioError = nil;
                        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, segmentDuration)
                                           ofTrack:audioAssetTrack
                                            atTime:currentAudioTime
                                             error:&audioError];
                        
                        if (audioError) {
                            DYYYLogVideo(@"添加背景音乐循环片段失败: %@", audioError);
                            break;
                        }
                        
                        DYYYLogVideo(@"添加背景音乐循环片段 - 位置: %.2f秒, 时长: %.2f秒", 
                                  CMTimeGetSeconds(currentAudioTime),
                                  CMTimeGetSeconds(segmentDuration));
                        
                        // 更新当前音频时间点
                        currentAudioTime = CMTimeAdd(currentAudioTime, segmentDuration);
                    }
                    
                    DYYYLogVideo(@"成功添加循环背景音乐，总时长: %.2f秒", CMTimeGetSeconds(currentAudioTime));
                } else {
                    // 音乐长度足够，直接添加
                    NSError *audioError = nil;
                    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, totalDuration)
                                       ofTrack:audioAssetTrack
                                        atTime:kCMTimeZero
                                         error:&audioError];
                    
                    if (audioError) {
                        DYYYLogVideo(@"添加背景音乐失败: %@", audioError);
                    } else {
                        DYYYLogVideo(@"成功添加背景音乐，时长: %.2f秒", CMTimeGetSeconds(totalDuration));
                    }
                }
            } else {
                DYYYLogVideo(@"错误: 背景音乐没有有效的音轨");
            }
        }
        
        NSMutableArray *instructions = [NSMutableArray array];
        
        // 处理所有媒体片段（按顺序）
        DYYYLogVideo(@"开始按顺序处理 %ld 个媒体片段", (long)mediaSegments.count);
        for (NSInteger i = 0; i < mediaSegments.count; i++) {
            NSDictionary *segment = mediaSegments[i];
            NSString *segmentType = segment[@"type"];
            NSString *segmentPath = segment[@"path"];
            
            DYYYLogVideo(@"处理片段 %ld/%ld: 类型=%@, 路径=%@", 
                       (long)(i+1), (long)mediaSegments.count, segmentType, segmentPath);
            
            AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:segmentPath]];
            NSArray<AVAssetTrack *> *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            
            if (videoTracks.count == 0) {
                DYYYLogVideo(@"错误: 媒体片段没有视频轨道: %@", segmentPath);
                continue;
            }
            
            AVAssetTrack *assetVideoTrack = videoTracks.firstObject;
            CMTime assetDuration = asset.duration;
            DYYYLogVideo(@"片段 %ld/%ld: 时长=%.2f秒, 尺寸=%.0fx%.0f", 
                       (long)(i+1), (long)mediaSegments.count, 
                       CMTimeGetSeconds(assetDuration),
                       assetVideoTrack.naturalSize.width,
                       assetVideoTrack.naturalSize.height);
            
            // 插入视频片段
            NSError *insertError = nil;
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetDuration)
                                ofTrack:assetVideoTrack
                                 atTime:currentTime
                                  error:&insertError];
            
            if (insertError) {
                DYYYLogVideo(@"插入视频片段失败: %@", insertError);
                continue;
            } else {
                DYYYLogVideo(@"成功插入视频片段 %ld/%ld 到位置 %.2f秒", 
                           (long)(i+1), (long)mediaSegments.count, 
                           CMTimeGetSeconds(currentTime));
            }
            
            // 创建视频合成指令
            AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            instruction.timeRange = CMTimeRangeMake(currentTime, assetDuration);
            
            AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            // 计算适当的视频变换
            CGAffineTransform transform = [self transformForAssetTrack:assetVideoTrack targetSize:videoSize];
            [layerInstruction setTransform:transform atTime:currentTime];
            
            instruction.layerInstructions = @[layerInstruction];
            [instructions addObject:instruction];
            DYYYLogVideo(@"添加合成指令: 时间范围=%.2f到%.2f秒", 
                       CMTimeGetSeconds(currentTime), 
                       CMTimeGetSeconds(CMTimeAdd(currentTime, assetDuration)));
            
            
            // 更新时间点
            currentTime = CMTimeAdd(currentTime, assetDuration);
        }
        
        // 设置合成指令
        videoComposition.instructions = instructions;
        DYYYLogVideo(@"设置了 %ld 个视频合成指令，总时长: %.2f秒", 
                   (long)instructions.count, CMTimeGetSeconds(currentTime));
        
        // 检查是否有内容需要导出
        if (instructions.count == 0 || CMTimeGetSeconds(currentTime) < 0.1) {
            DYYYLogVideo(@"错误: 没有足够的内容可以导出");
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
            }
            
            for (NSDictionary *segment in mediaSegments) {
                if ([segment[@"type"] isEqualToString:@"image"]) {
                    [[NSFileManager defaultManager] removeItemAtPath:segment[@"path"] error:nil];
                    DYYYLogVideo(@"清理临时图片视频文件: %@", segment[@"path"]);
                }
            }
            return;
        }
        
        // 设置导出会话
        DYYYLogVideo(@"创建视频导出会话，使用最高质量编码");
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
        if (!exportSession) {
            DYYYLogVideo(@"错误: 创建导出会话失败");
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
            }
            return;
        }
        
        exportSession.videoComposition = videoComposition;
        exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        // 导出视频
        DYYYLogVideo(@"开始导出视频到: %@", outputPath);
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            for (NSDictionary *segment in mediaSegments) {
                if ([segment[@"type"] isEqualToString:@"image"]) {
                    NSError *removeError = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:segment[@"path"] error:&removeError];
                    if (removeError) {
                        DYYYLogVideo(@"清理临时文件失败: %@, 错误: %@", segment[@"path"], removeError);
                    } else {
                        DYYYLogVideo(@"清理临时图片视频文件: %@", segment[@"path"]);
                    }
                }
            }
                        switch (exportSession.status) {
                case AVAssetExportSessionStatusCompleted: {
                    DYYYLogVideo(@"视频导出成功: %@", outputPath);
                    
                    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:outputPath error:nil];
                    if (fileAttrs) {
                        unsigned long long fileSize = [fileAttrs fileSize];
                        DYYYLogVideo(@"导出视频大小: %.2f MB", fileSize / (1024.0 * 1024.0));
                    }
                    
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(YES);
                        });
                    }
                    break;
                }
                
                case AVAssetExportSessionStatusFailed: {
                    DYYYLogVideo(@"导出视频失败: %@", exportSession.error);
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(NO);
                        });
                    }
                    break;
                }
                
                case AVAssetExportSessionStatusCancelled: {
                    DYYYLogVideo(@"导出视频被取消");
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(NO);
                        });
                    }
                    break;
                }
                    
                default: {
                    DYYYLogVideo(@"导出视频结束，状态码: %ld", (long)exportSession.status);
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(NO);
                        });
                    }
                    break;
                }
            }
        }];
    });
}

// 创建从静态图片生成的视频片段
+ (void)createVideoFromImage:(UIImage *)image 
                    duration:(float)duration 
                  outputPath:(NSString *)outputPath 
                  completion:(void (^)(BOOL success))completion {
    // 视频尺寸和参数
    CGSize videoSize = CGSizeMake(1080, 1920);
    NSInteger frameRate = 30;
    
    NSError *error = nil;
    // 设置视频写入器
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:outputPath]
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    if (error) {
        NSLog(@"创建视频写入器失败: %@", error);
        if (completion) completion(NO);
        return;
    }
    
    // 配置视频设置
    NSDictionary *videoSettings = @{
        AVVideoCodecKey: AVVideoCodecTypeH264,
        AVVideoWidthKey: @(videoSize.width),
        AVVideoHeightKey: @(videoSize.height),
        AVVideoCompressionPropertiesKey: @{
            AVVideoAverageBitRateKey: @(6000000),
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
        }
    };
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    writerInput.expectsMediaDataInRealTime = YES;
    
    // 创建像素缓冲区适配器
    NSDictionary *sourcePixelBufferAttributes = @{
        (NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
        (NSString*)kCVPixelBufferWidthKey: @(videoSize.width),
        (NSString*)kCVPixelBufferHeightKey: @(videoSize.height)
    };
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                    assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                    sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    
    [videoWriter addInput:writerInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    // 不再调整图片大小，只在需要时适配
    // UIImage *resizedImage = [self resizeImage:image toSize:videoSize];
    
    // 创建上下文并绘制图像
    CVPixelBufferRef pixelBuffer = NULL;
    CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor.pixelBufferPool, &pixelBuffer);
    
    if (pixelBuffer == NULL) {
        // 如果池创建失败，手动创建像素缓冲区
        NSDictionary *pixelBufferAttributes = @{
            (NSString*)kCVPixelBufferCGImageCompatibilityKey: @YES,
            (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
            (NSString*)kCVPixelBufferWidthKey: @(videoSize.width),
            (NSString*)kCVPixelBufferHeightKey: @(videoSize.height)
        };
        CVPixelBufferCreate(kCFAllocatorDefault, videoSize.width, videoSize.height,
                          kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)pixelBufferAttributes, &pixelBuffer);
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, videoSize.width, videoSize.height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    
    // 填充背景
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, videoSize.width, videoSize.height));
    
    // 居中绘制图像，保持原始比例
    CGRect drawRect = [self rectForImageAspectFit:image.size inSize:videoSize];
    CGContextDrawImage(context, drawRect, image.CGImage);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    // 计算帧数
    NSInteger totalFrames = duration * frameRate;
    
    // 写入每一帧
    dispatch_queue_t queue = dispatch_queue_create("com.dyyy.videoframe", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        BOOL success = YES;
        for (int i = 0; i < totalFrames; i++) {
            if (writerInput.readyForMoreMediaData) {
                CMTime frameTime = CMTimeMake(i, frameRate);
                success = [adaptor appendPixelBuffer:pixelBuffer withPresentationTime:frameTime];
                if (!success) {
                    NSLog(@"无法写入像素缓冲区");
                    break;
                }
            } else {
                // 如果写入器未准备好，等待
                usleep(10000);
                i--;
            }
        }
        
        // 完成视频写入
        [writerInput markAsFinished];
        [videoWriter finishWritingWithCompletionHandler:^{
            if (pixelBuffer) {
                CVPixelBufferRelease(pixelBuffer);
            }
            
            if (videoWriter.status == AVAssetWriterStatusCompleted) {
                if (completion) completion(YES);
            } else {
                NSLog(@"写入视频失败: %@", videoWriter.error);
                if (completion) completion(NO);
            }
        }];
    });
}

// 缩放图片到指定尺寸
+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage ?: image;
}

+ (CGRect)rectForImageAspectFit:(CGSize)imageSize inSize:(CGSize)containerSize {
    CGFloat hScale = containerSize.width / imageSize.width;
    CGFloat vScale = containerSize.height / imageSize.height;
    CGFloat scale = MIN(hScale, vScale); // 使用MIN而不是MAX来保持原始比例
    
    CGFloat newWidth = imageSize.width * scale;
    CGFloat newHeight = imageSize.height * scale;
    
    CGFloat x = (containerSize.width - newWidth) / 2.0;
    CGFloat y = (containerSize.height - newHeight) / 2.0;
    
    return CGRectMake(x, y, newWidth, newHeight);
}

// 计算视频轨道的变换（保持原始比例）
+ (CGAffineTransform)transformForAssetTrack:(AVAssetTrack *)track targetSize:(CGSize)targetSize {
    CGSize trackSize = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
    trackSize = CGSizeMake(fabs(trackSize.width), fabs(trackSize.height));
    
    CGFloat xScale = targetSize.width / trackSize.width;
    CGFloat yScale = targetSize.height / trackSize.height;
    CGFloat scale = MIN(xScale, yScale); // 使用MIN而不是MAX来保持原始比例
    
    CGAffineTransform transform = track.preferredTransform;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(scale, scale));
    
    // 居中显示
    CGFloat xOffset = (targetSize.width - trackSize.width * scale) / 2.0;
    CGFloat yOffset = (targetSize.height - trackSize.height * scale) / 2.0;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(xOffset, yOffset));
    
    return transform;
}

// 计算图片的变换（保持原始比例）
+ (CGAffineTransform)transformForImage:(UIImage *)image targetSize:(CGSize)targetSize {
    CGSize imageSize = image.size;
    
    CGFloat xScale = targetSize.width / imageSize.width;
    CGFloat yScale = targetSize.height / imageSize.height;
    CGFloat scale = MIN(xScale, yScale);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, scale, scale);
    
    // 居中显示
    CGFloat xOffset = (targetSize.width - imageSize.width * scale) / 2.0;
    CGFloat yOffset = (targetSize.height - imageSize.height * scale) / 2.0;
    transform = CGAffineTransformTranslate(transform, xOffset / scale, yOffset / scale);
    
    return transform;
}
@end