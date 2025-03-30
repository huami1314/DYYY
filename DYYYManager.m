#import "DYYYManager.h"
#import <Photos/Photos.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreMedia/CMMetadata.h>

// 自定义进度条视图类
@interface DYYYManager(){
    AVAssetExportSession *session;
    AVURLAsset *asset;
    AVAssetReader *reader;
    AVAssetWriter *writer;
    dispatch_queue_t queue;
    dispatch_group_t group;
}
@end


@interface DYYYDownloadProgressView : UIView
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *progressBarBackground;
@property (nonatomic, strong) UIView *progressBar;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, copy) void (^cancelBlock)(void);
@property (nonatomic, assign) BOOL isCancelled; // 添加取消标志

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setProgress:(float)progress;
- (void)show;
- (void)dismiss;

@end

@implementation DYYYDownloadProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.isCancelled = NO;
        
        // 创建容器视图，减小尺寸
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 240, 140)];
        _containerView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        _containerView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
        _containerView.layer.cornerRadius = 12;
        _containerView.clipsToBounds = YES;
        [self addSubview:_containerView];
        
        // 创建进度条背景
        _progressBarBackground = [[UIView alloc] initWithFrame:CGRectMake(20, 50, CGRectGetWidth(_containerView.frame) - 40, 8)];
        _progressBarBackground.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        _progressBarBackground.layer.cornerRadius = 4;
        [_containerView addSubview:_progressBarBackground];
        
        // 创建进度条
        _progressBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGRectGetHeight(_progressBarBackground.frame))];
        _progressBar.backgroundColor = [UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0];
        _progressBar.layer.cornerRadius = 4;
        [_progressBarBackground addSubview:_progressBar];
        
        // 创建进度标签
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_progressBarBackground.frame) + 12, CGRectGetWidth(_containerView.frame), 20)];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.textColor = [UIColor whiteColor];
        _progressLabel.font = [UIFont systemFontOfSize:14];
        _progressLabel.text = @"0%";
        [_containerView addSubview:_progressLabel];
        
        // 创建取消按钮
        _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _cancelButton.frame = CGRectMake((CGRectGetWidth(_containerView.frame) - 80) / 2, CGRectGetMaxY(_progressLabel.frame) + 10, 80, 32);
        _cancelButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelButton.layer.cornerRadius = 16;
        [_cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [_containerView addSubview:_cancelButton];
        
        // 添加标题标签
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, CGRectGetWidth(_containerView.frame), 20)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        titleLabel.text = @"正在下载";
        [_containerView addSubview:titleLabel];
        
        // 设置初始透明度为0，以便动画显示
        self.alpha = 0;
    }
    return self;
}

- (void)setProgress:(float)progress {
    // 确保在主线程中更新UI
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setProgress:progress];
        });
        return;
    }
    
    // 进度值限制在0到1之间
    progress = MAX(0.0, MIN(1.0, progress));
    
    // 设置进度条长度
    CGRect progressFrame = _progressBar.frame;
    progressFrame.size.width = progress * CGRectGetWidth(_progressBarBackground.frame);
    _progressBar.frame = progressFrame;
    
    // 更新进度百分比
    int percentage = (int)(progress * 100);
    _progressLabel.text = [NSString stringWithFormat:@"%d%%", percentage];
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) return;
    
    [window addSubview:self];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)cancelButtonTapped {
    self.isCancelled = YES; // 设置取消标志
    if (self.cancelBlock) {
        self.cancelBlock();
    }
    [self dismiss];
}

@end

@interface DYYYManager() <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionDownloadTask *> *downloadTasks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, DYYYDownloadProgressView *> *progressViews;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *taskProgressMap; // 添加进度映射
@property (nonatomic, strong) NSMutableDictionary<NSString *, void (^)(BOOL success, NSURL *fileURL)> *completionBlocks; // 添加完成回调存储
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *mediaTypeMap; // 添加媒体类型映射

// 批量下载相关属性
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *downloadToBatchMap; // 下载ID到批量ID的映射
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *batchCompletedCountMap; // 批量ID到已完成数量的映射
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *batchSuccessCountMap; // 批量ID到成功数量的映射
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *batchTotalCountMap; // 批量ID到总数量的映射
@property (nonatomic, strong) NSMutableDictionary<NSString *, void (^)(NSInteger current, NSInteger total)> *batchProgressBlocks; // 批量进度回调
@property (nonatomic, strong) NSMutableDictionary<NSString *, void (^)(NSInteger successCount, NSInteger totalCount)> *batchCompletionBlocks; // 批量完成回调
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
        _downloadQueue.maxConcurrentOperationCount = 3; // A maximum of 3 concurrent downloads
        _taskProgressMap = [NSMutableDictionary dictionary]; // Initialize progress mapping
        _completionBlocks = [NSMutableDictionary dictionary]; // Initialize completion blocks
        _mediaTypeMap = [NSMutableDictionary dictionary]; // Initialize media type mapping
        
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
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                    if (w.isKeyWindow) return w;
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
    if (!window) return nil;
    
    UIViewController *topController = window.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

+ (UIColor *)colorWithHexString:(NSString *)hexString {
    // 处理随机颜色的情况
    if ([hexString.lowercaseString isEqualToString:@"random"] || [hexString.lowercaseString isEqualToString:@"#random"]) {
        return [UIColor colorWithRed:(CGFloat)arc4random_uniform(256)/255.0 
                              green:(CGFloat)arc4random_uniform(256)/255.0 
                               blue:(CGFloat)arc4random_uniform(256)/255.0 
                              alpha:1.0];
    }
    
    // 去掉"#"前缀并转为大写
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    CGFloat alpha = 1.0;
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    
    if (colorString.length == 8) {
        // 8位十六进制：AARRGGBB，前两位为透明度
        NSScanner *scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(0, 2)]];
        unsigned int alphaValue;
        [scanner scanHexInt:&alphaValue];
        alpha = (CGFloat)alphaValue / 255.0;
        
        scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(2, 2)]];
        unsigned int redValue;
        [scanner scanHexInt:&redValue];
        red = (CGFloat)redValue / 255.0;
        
        scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(4, 2)]];
        unsigned int greenValue;
        [scanner scanHexInt:&greenValue];
        green = (CGFloat)greenValue / 255.0;
        
        scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(6, 2)]];
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
            colorString = [NSString stringWithFormat:@"%@%@%@%@%@%@", r, r, g, g, b, b];
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

+ (void)saveMedia:(NSURL *)mediaURL mediaType:(MediaType)mediaType completion:(void (^)(void))completion {
    if (mediaType == MediaTypeAudio) {
        return;
    }

    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            // 如果是HEIC类型，先转换为GIF
            if (mediaType == MediaTypeHeic) {
                [self convertHeicToGif:mediaURL completion:^(NSURL *gifURL, BOOL success) {
                    if (success && gifURL) {
                        // 保存转换后的GIF文件
                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                            //获取表情包的数据
                            NSData *gifData = [NSData dataWithContentsOfURL:gifURL];
                            //创建相册资源
                            PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                            //实例相册类资源参数
                            PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                            //定义表情包参数
                            options.uniformTypeIdentifier = @"com.compuserve.gif"; 
                            //保存表情包图片/gif动图
                            [request addResourceWithType:PHAssetResourceTypePhoto data:gifData options:options];  
                        } completionHandler:^(BOOL success, NSError * _Nullable error) {
                            if (success) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self showToast:[NSString stringWithFormat:@"%@已保存到相册", [self getMediaTypeDescription:mediaType]]];
                                });
                                
                                if (completion) {
                                    completion();
                                }
                            } else {
                                [self showToast:@"保存失败"];
                            }
                            // 清理临时文件
                            [[NSFileManager defaultManager] removeItemAtPath:mediaURL.path error:nil];
                            [[NSFileManager defaultManager] removeItemAtPath:gifURL.path error:nil];
                        }];
                    } else {
                        [self showToast:@"转换失败"];
                        [[NSFileManager defaultManager] removeItemAtPath:mediaURL.path error:nil];
                        if (completion) {
                            completion();
                        }
                    }
                }];
            } else {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    if (mediaType == MediaTypeVideo) {
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:mediaURL];
                    } else {
                        UIImage *image = [UIImage imageWithContentsOfFile:mediaURL.path];
                        if (image) {
                            [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                        }
                    }
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if (success) {
                        // 在下载完成后显示一次提示，而不是每个保存操作都显示
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showToast:[NSString stringWithFormat:@"%@已保存到相册", [self getMediaTypeDescription:mediaType]]];
                        });
                        
                        if (completion) {
                            completion();
                        }
                    } else {
                        [self showToast:@"保存失败"];
                    }
                    [[NSFileManager defaultManager] removeItemAtPath:mediaURL.path error:nil];
                }];
            }
        }
    }];
}

// 将HEIC转换为GIF的方法
+ (void)convertHeicToGif:(NSURL *)heicURL completion:(void (^)(NSURL *gifURL, BOOL success))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 创建HEIC图像源
        CGImageSourceRef heicSource = CGImageSourceCreateWithURL((__bridge CFURLRef)heicURL, NULL);
        if (!heicSource) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil, NO);
                }
            });
            return;
        }
        
        // 获取HEIC图像数量
        size_t count = CGImageSourceGetCount(heicSource);
        BOOL isAnimated = (count > 1);
        
        // 创建GIF文件路径
        NSString *gifFileName = [[heicURL.lastPathComponent stringByDeletingPathExtension] stringByAppendingPathExtension:@"gif"];
        NSURL *gifURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:gifFileName]];
        
        // 设置GIF属性
        NSDictionary *gifProperties = @{
            (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                (__bridge NSString *)kCGImagePropertyGIFLoopCount: @0, // 0表示无限循环
            }
        };
        
        // 创建GIF图像目标
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)gifURL, kUTTypeGIF, isAnimated ? count : 1, NULL);
        if (!destination) {
            CFRelease(heicSource);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil, NO);
                }
            });
            return;
        }
        
        // 设置GIF属性
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);
        
        if (isAnimated) {
            // 处理动画HEIC，提取所有帧并添加到GIF
            for (size_t i = 0; i < count; i++) {
                // 获取当前帧
                CGImageRef imageRef = CGImageSourceCreateImageAtIndex(heicSource, i, NULL);
                if (!imageRef) {
                    continue;
                }
                
                // 获取帧属性
                CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(heicSource, i, NULL);
                
                // 获取延迟时间
                float delayTime = 0.1f; // 默认延迟时间
                if (properties) {
                    CFDictionaryRef heicProperties = CFDictionaryGetValue(properties, kCGImagePropertyHEICSDictionary);
                    if (heicProperties) {
                        CFNumberRef delayTimeRef = CFDictionaryGetValue(heicProperties, kCGImagePropertyHEICSDelayTime);
                        if (delayTimeRef) {
                            CFNumberGetValue(delayTimeRef, kCFNumberFloatType, &delayTime);
                        }
                    }
                }
                
                // 创建帧属性
                NSDictionary *frameProperties = @{
                    (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                        (__bridge NSString *)kCGImagePropertyGIFDelayTime: @(delayTime),
                    }
                };
                
                // 添加帧到GIF
                CGImageDestinationAddImage(destination, imageRef, (__bridge CFDictionaryRef)frameProperties);
                
                // 释放资源
                CGImageRelease(imageRef);
                if (properties) {
                    CFRelease(properties);
                }
            }
        } else {
            // 处理静态HEIC，创建单帧GIF
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(heicSource, 0, NULL);
            if (imageRef) {
                // 创建帧属性
                NSDictionary *frameProperties = @{
                    (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                        (__bridge NSString *)kCGImagePropertyGIFDelayTime: @0.1f,
                    }
                };
                
                // 添加帧到GIF
                CGImageDestinationAddImage(destination, imageRef, (__bridge CFDictionaryRef)frameProperties);
                
                // 释放资源
                CGImageRelease(imageRef);
            }
        }
        
        // 完成GIF生成
        BOOL success = CGImageDestinationFinalize(destination);
        
        // 释放资源
        CFRelease(heicSource);
        CFRelease(destination);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(gifURL, success);
            }
        });
    });
}

//保存实况的方法，下载图片和下载视频都用这个
+ (void)downloadLivePhoto:(NSURL *)imageURL videoURL:(NSURL *)videoURL completion:(void (^)(void))completion {
    NSLog(@"开始下载实况照片: 图片URL=%@, 视频URL=%@", imageURL, videoURL);
    
    // 获取共享实例，确保FileLinks字典存在
    DYYYManager *manager = [DYYYManager shared];
    if (!manager.fileLinks) {
        manager.fileLinks = [NSMutableDictionary dictionary];
    }
    
    // 为图片和视频URL创建唯一的键
    NSString *uniqueKey = [NSString stringWithFormat:@"%@_%@", imageURL.absoluteString, videoURL.absoluteString];
    
    // 检查是否已经存在此下载任务
    NSDictionary *existingPaths = [manager.fileLinks objectForKey:uniqueKey];
    if (existingPaths) {
        NSString *imagePath = existingPaths[@"image"];
        NSString *videoPath = existingPaths[@"video"];
        
        BOOL imageExists = [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
        BOOL videoExists = [[NSFileManager defaultManager] fileExistsAtPath:videoPath];
        
        if (imageExists && videoExists) {
            NSLog(@"使用现有文件: 图片=%@, 视频=%@", imagePath, videoPath);
            [[DYYYManager shared] saveLivePhoto:imagePath videoUrl:videoPath];
            if (completion) {
                completion();
            }
            return;
        }
    }
    
    // 创建临时目录
    NSString *livePhotoPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"LivePhoto"];
    [[NSFileManager defaultManager] createDirectoryAtPath:livePhotoPath withIntermediateDirectories:YES attributes:nil error:nil];
    NSLog(@"创建临时目录: %@", livePhotoPath);
    
    // 生成唯一标识符，防止多次调用时文件冲突
    NSString *uniqueID = [NSUUID UUID].UUIDString;
    NSString *imageName = [NSString stringWithFormat:@"%@.heic", uniqueID];
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", uniqueID];
    
    NSString *imagePath = [livePhotoPath stringByAppendingPathComponent:imageName];
    NSString *videoPath = [livePhotoPath stringByAppendingPathComponent:videoName];
    NSLog(@"生成唯一标识符: %@, 图片路径: %@, 视频路径: %@", uniqueID, imagePath, videoPath);
    
    // 存储文件路径，以便下次下载相同的URL时可以复用
    [manager.fileLinks setObject:@{@"image": imagePath, @"video": videoPath} forKey:uniqueKey];
    
    // 创建进度视图
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        DYYYDownloadProgressView *progressView = [[DYYYDownloadProgressView alloc] initWithFrame:screenBounds];
        progressView.progressLabel.text = @"准备下载实况照片...";
        [progressView show];
        
        // 创建下载会话
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:[DYYYManager shared] delegateQueue:[NSOperationQueue mainQueue]];
        
        // 创建一个调度组，确保两个下载都完成后再执行后续操作
        dispatch_group_t group = dispatch_group_create();
        
        __block BOOL imageDownloaded = NO;
        __block BOOL videoDownloaded = NO;
        
        // 下载图片
        NSLog(@"开始下载图片: %@", imageURL);
        dispatch_group_enter(group);
        NSURLSessionDownloadTask *imageTask = [session downloadTaskWithURL:imageURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (!error && location) {
                NSLog(@"图片下载成功，临时位置: %@", location);
                NSError *moveError = nil;
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:imagePath] error:&moveError];
                if (moveError) {
                    NSLog(@"移动图片文件失败: %@", moveError);
                } else {
                    NSLog(@"图片文件已移动到: %@", imagePath);
                    imageDownloaded = YES;
                }
            } else {
                NSLog(@"图片下载失败: %@", error);
            }
            dispatch_group_leave(group);
            
            // 更新进度条
            dispatch_async(dispatch_get_main_queue(), ^{
                if (imageDownloaded) {
                    progressView.progressLabel.text = @"图片下载完成，等待视频...";
                    [progressView setProgress:0.5];
                } else {
                    progressView.progressLabel.text = @"图片下载失败!";
                    [progressView setProgress:0.5];
                }
            });
        }];
        [imageTask resume];
        
        // 下载视频
        NSLog(@"开始下载视频: %@", videoURL);
        dispatch_group_enter(group);
        NSURLSessionDownloadTask *videoTask = [session downloadTaskWithURL:videoURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (!error && location) {
                NSLog(@"视频下载成功，临时位置: %@", location);
                NSError *moveError = nil;
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:videoPath] error:&moveError];
                if (moveError) {
                    NSLog(@"移动视频文件失败: %@", moveError);
                } else {
                    NSLog(@"视频文件已移动到: %@", videoPath);
                    videoDownloaded = YES;
                }
            } else {
                NSLog(@"视频下载失败: %@", error);
            }
            dispatch_group_leave(group);
            
            // 更新进度条
            dispatch_async(dispatch_get_main_queue(), ^{
                if (videoDownloaded) {
                    if (imageDownloaded) {
                        progressView.progressLabel.text = @"下载完成，准备保存...";
                        [progressView setProgress:1.0];
                    } else {
                        progressView.progressLabel.text = @"视频下载完成，图片下载失败";
                        [progressView setProgress:0.75];
                    }
                } else {
                    progressView.progressLabel.text = @"视频下载失败!";
                    [progressView setProgress:0.75];
                }
            });
        }];
        [videoTask resume];
        
        // 设置取消按钮事件
        progressView.cancelBlock = ^{
            [imageTask cancel];
            [videoTask cancel];
            // 移除文件，释放资源
            [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
            [manager.fileLinks removeObjectForKey:uniqueKey];
            if (completion) {
                completion();
            }
        };
        
        // 当两个下载都完成后，保存实况照片
        NSLog(@"等待图片和视频下载完成");
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            NSLog(@"图片和视频下载任务已完成");
            BOOL imageExists = [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
            BOOL videoExists = [[NSFileManager defaultManager] fileExistsAtPath:videoPath];
            NSLog(@"检查文件: 图片存在=%@, 视频存在=%@", imageExists ? @"是" : @"否", videoExists ? @"是" : @"否");
            
            // 隐藏进度视图
            [progressView dismiss];
            
            if (imageExists && videoExists) {
                NSLog(@"准备保存实况照片");
                @try {
                    [[DYYYManager shared] saveLivePhoto:imagePath videoUrl:videoPath];
                    NSLog(@"实况照片保存成功");
                    // 这里不删除文件，因为文件路径已经存储在字典中以供复用
                } @catch (NSException *exception) {
                    NSLog(@"保存实况照片时发生异常: %@", exception);
                    // 删除失败的文件
                    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
                    [manager.fileLinks removeObjectForKey:uniqueKey];
                }
            } else {
                NSLog(@"下载实况照片失败，文件不完整");
                // 清理不完整的文件
                if (imageExists) [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
                if (videoExists) [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
                [manager.fileLinks removeObjectForKey:uniqueKey];
                [DYYYManager showToast:@"下载实况照片失败"];
            }
            
            if (completion) {
                NSLog(@"调用完成回调");
                completion();
            }
        });
    });
}

+ (void)downloadMedia:(NSURL *)url mediaType:(MediaType)mediaType completion:(void (^)(void))completion {
    [self downloadMediaWithProgress:url mediaType:mediaType progress:nil completion:^(BOOL success, NSURL *fileURL) {
        if (success) {
            if (mediaType == MediaTypeAudio) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
                    
                    [activityVC setCompletionWithItemsHandler:^(UIActivityType _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable error) {
                        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
                    }];
                    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
                    [rootVC presentViewController:activityVC animated:YES completion:nil];
                });
            } else {
                [self saveMedia:fileURL mediaType:mediaType completion:completion];
            }
        } else {
            if (completion) {
                completion();
            }
        }
    }];
}

+ (void)downloadMediaWithProgress:(NSURL *)url mediaType:(MediaType)mediaType progress:(void (^)(float progress))progressBlock completion:(void (^)(BOOL success, NSURL *fileURL))completion {
    // 创建自定义进度条界面
    dispatch_async(dispatch_get_main_queue(), ^{
        // 创建进度视图
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        DYYYDownloadProgressView *progressView = [[DYYYDownloadProgressView alloc] initWithFrame:screenBounds];
        
        // 生成下载ID并保存进度视图
        NSString *downloadID = [NSUUID UUID].UUIDString;
        [[DYYYManager shared].progressViews setObject:progressView forKey:downloadID];
        
        // 显示进度视图
        [progressView show];
        
        // 设置取消按钮事件
        progressView.cancelBlock = ^{
            NSURLSessionDownloadTask *task = [[DYYYManager shared].downloadTasks objectForKey:downloadID];
            if (task) {
                [task cancel];
                [[DYYYManager shared].downloadTasks removeObjectForKey:downloadID];
                [[DYYYManager shared].taskProgressMap removeObjectForKey:downloadID];
            }
            
            // 已经在取消按钮中隐藏了进度视图，无需再次隐藏
            [[DYYYManager shared].progressViews removeObjectForKey:downloadID];
            
            if (completion) {
                completion(NO, nil);
            }
        };
        
        // 保存回调
        [[DYYYManager shared] setCompletionBlock:completion forDownloadID:downloadID];
        [[DYYYManager shared] setMediaType:mediaType forDownloadID:downloadID];
        
        // 配置下载会话 - 使用带委托的会话以获取进度更新
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:[DYYYManager shared] delegateQueue:[NSOperationQueue mainQueue]];
        
        // 创建下载任务 - 不使用completionHandler，使用代理方法
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url];
        
        // 存储下载任务
        [[DYYYManager shared].downloadTasks setObject:downloadTask forKey:downloadID];
        [[DYYYManager shared].taskProgressMap setObject:@0.0 forKey:downloadID]; // 初始化进度为0
        
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
        NSURLSessionDownloadTask *task = [[DYYYManager shared].downloadTasks objectForKey:downloadID];
        if (task) {
            [task cancel];
        }
        
        DYYYDownloadProgressView *progressView = [[DYYYManager shared].progressViews objectForKey:downloadID];
        if (progressView) {
            [progressView dismiss];
        }
    }
    
    [[DYYYManager shared].downloadTasks removeAllObjects];
    [[DYYYManager shared].progressViews removeAllObjects];
}

+ (void)downloadAllImages:(NSMutableArray *)imageURLs {
    if (imageURLs.count == 0) {
        return;
    }
    
    [self downloadAllImagesWithProgress:imageURLs progress:nil completion:^(NSInteger successCount, NSInteger totalCount) {
        [self showToast:[NSString stringWithFormat:@"已保存 %ld/%ld 张图片", (long)successCount, (long)totalCount]];
    }];
}

+ (void)downloadAllImagesWithProgress:(NSMutableArray *)imageURLs progress:(void (^)(NSInteger current, NSInteger total))progressBlock completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion {
    if (imageURLs.count == 0) {
        if (completion) {
            completion(0, 0);
        }
        return;
    }
    
    // 创建自定义批量下载进度条界面
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        DYYYDownloadProgressView *progressView = [[DYYYDownloadProgressView alloc] initWithFrame:screenBounds];
        NSString *batchID = [NSUUID UUID].UUIDString;
        [[DYYYManager shared].progressViews setObject:progressView forKey:batchID];
        
        // 显示进度视图
        [progressView show];
        
        // 创建下载任务
        __block NSInteger completedCount = 0;
        __block NSInteger successCount = 0;
        NSInteger totalCount = imageURLs.count;
        
        // 设置取消按钮事件
        progressView.cancelBlock = ^{
            // 在这里可以添加取消批量下载的逻辑
            [self cancelAllDownloads];
            if (completion) {
                completion(successCount, totalCount);
            }
        };
        
        // 存储批量下载的相关信息
        [[DYYYManager shared] setBatchInfo:batchID totalCount:totalCount progressBlock:progressBlock completionBlock:completion];
        
        // 为每个URL创建下载任务
        for (NSString *urlString in imageURLs) {
            NSURL *url = [NSURL URLWithString:urlString];
            if (!url) {
                [[DYYYManager shared] incrementCompletedAndUpdateProgressForBatch:batchID success:NO];
                continue;
            }
            
            // 创建单个下载任务ID
            NSString *downloadID = [NSUUID UUID].UUIDString;
            
            // 关联到批量下载
            [[DYYYManager shared] associateDownload:downloadID withBatchID:batchID];
            
            // 配置下载会话 - 使用带委托的会话以获取进度更新
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:[DYYYManager shared] delegateQueue:[NSOperationQueue mainQueue]];
            
            // 创建下载任务 - 使用代理方法
            NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url];
            
            // 存储下载任务
            [[DYYYManager shared].downloadTasks setObject:downloadTask forKey:downloadID];
            [[DYYYManager shared].taskProgressMap setObject:@0.0 forKey:downloadID];
            [[DYYYManager shared] setMediaType:MediaTypeImage forDownloadID:downloadID];
            
            // 开始下载
            [downloadTask resume];
        }
    });
}

// 设置批量下载信息
- (void)setBatchInfo:(NSString *)batchID totalCount:(NSInteger)totalCount progressBlock:(void (^)(NSInteger current, NSInteger total))progressBlock completionBlock:(void (^)(NSInteger successCount, NSInteger totalCount))completionBlock {
    [self.batchTotalCountMap setObject:@(totalCount) forKey:batchID];
    [self.batchCompletedCountMap setObject:@(0) forKey:batchID];
    [self.batchSuccessCountMap setObject:@(0) forKey:batchID];
    
    if (progressBlock) {
        [self.batchProgressBlocks setObject:[progressBlock copy] forKey:batchID];
    }
    
    if (completionBlock) {
        [self.batchCompletionBlocks setObject:[completionBlock copy] forKey:batchID];
    }
}

// 关联单个下载到批量下载
- (void)associateDownload:(NSString *)downloadID withBatchID:(NSString *)batchID {
    [self.downloadToBatchMap setObject:batchID forKey:downloadID];
}

// 增加批量下载完成计数并更新进度
- (void)incrementCompletedAndUpdateProgressForBatch:(NSString *)batchID success:(BOOL)success {
    @synchronized (self) {
        NSNumber *completedCountNum = self.batchCompletedCountMap[batchID];
        NSInteger completedCount = completedCountNum ? [completedCountNum integerValue] + 1 : 1;
        [self.batchCompletedCountMap setObject:@(completedCount) forKey:batchID];
        
        if (success) {
            NSNumber *successCountNum = self.batchSuccessCountMap[batchID];
            NSInteger successCount = successCountNum ? [successCountNum integerValue] + 1 : 1;
            [self.batchSuccessCountMap setObject:@(successCount) forKey:batchID];
        }
        
        NSNumber *totalCountNum = self.batchTotalCountMap[batchID];
        NSInteger totalCount = totalCountNum ? [totalCountNum integerValue] : 0;
        
        // 更新批量下载进度视图
        DYYYDownloadProgressView *progressView = self.progressViews[batchID];
        if (progressView) {
            float progress = totalCount > 0 ? (float)completedCount / totalCount : 0;
            [progressView setProgress:progress];
            
            // 更新进度标签
            progressView.progressLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)completedCount, (long)totalCount];
        }
        
        // 调用进度回调
        void (^progressBlock)(NSInteger current, NSInteger total) = self.batchProgressBlocks[batchID];
        if (progressBlock) {
            progressBlock(completedCount, totalCount);
        }
        
        // 如果所有下载都已完成，调用完成回调并清理
        if (completedCount >= totalCount) {
            NSInteger successCount = [self.batchSuccessCountMap[batchID] integerValue];
            
            // 调用完成回调
            void (^completionBlock)(NSInteger successCount, NSInteger totalCount) = self.batchCompletionBlocks[batchID];
            if (completionBlock) {
                completionBlock(successCount, totalCount);
            }
            
            // 移除进度视图
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
- (void)setCompletionBlock:(void (^)(BOOL success, NSURL *fileURL))completion forDownloadID:(NSString *)downloadID {
    if (completion) {
        [self.completionBlocks setObject:[completion copy] forKey:downloadID];
    }
}

// 保存媒体类型
- (void)setMediaType:(MediaType)mediaType forDownloadID:(NSString *)downloadID {
    [self.mediaTypeMap setObject:@(mediaType) forKey:downloadID];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // 确保不会除以0
    if (totalBytesExpectedToWrite <= 0) {
        return;
    }
    
    // 计算进度
    float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
    
    // 在主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        // 找到对应的进度视图
        NSString *downloadIDForTask = nil;
        
        // 遍历找到任务对应的ID
        for (NSString *key in self.downloadTasks.allKeys) {
            NSURLSessionDownloadTask *task = self.downloadTasks[key];
            if (task == downloadTask) {
                downloadIDForTask = key;
                break;
            }
        }
        
        // 如果找到对应的进度视图，更新进度
        if (downloadIDForTask) {
            // 更新进度记录
            [self.taskProgressMap setObject:@(progress) forKey:downloadIDForTask];
            
            DYYYDownloadProgressView *progressView = self.progressViews[downloadIDForTask];
            if (progressView) {
                // 确保进度视图存在并且没有被取消
                if (!progressView.isCancelled) {
                    [progressView setProgress:progress];
                }
            }
        }
    });
}

// 添加下载完成的代理方法
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
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
    
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:destinationURL error:&moveError];
    
    if (isBatchDownload) {
        // 批量下载处理
        if (!moveError) {
            [DYYYManager saveMedia:destinationURL mediaType:mediaType completion:^{
                [[DYYYManager shared] incrementCompletedAndUpdateProgressForBatch:batchID success:YES];
            }];
        } else {
            [[DYYYManager shared] incrementCompletedAndUpdateProgressForBatch:batchID success:NO];
        }
        
        // 清理下载任务
        [self.downloadTasks removeObjectForKey:downloadIDForTask];
        [self.taskProgressMap removeObjectForKey:downloadIDForTask];
        [self.mediaTypeMap removeObjectForKey:downloadIDForTask];
    } else {
        // 单个下载处理
        // 获取保存的完成回调
        void (^completionBlock)(BOOL success, NSURL *fileURL) = self.completionBlocks[downloadIDForTask];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 隐藏进度视图
            DYYYDownloadProgressView *progressView = self.progressViews[downloadIDForTask];
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

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
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
        [[DYYYManager shared] incrementCompletedAndUpdateProgressForBatch:batchID success:NO];
        
        // 清理下载任务
        [self.downloadTasks removeObjectForKey:downloadIDForTask];
        [self.taskProgressMap removeObjectForKey:downloadIDForTask];
        [self.mediaTypeMap removeObjectForKey:downloadIDForTask];
        [self.downloadToBatchMap removeObjectForKey:downloadIDForTask];
    } else {
        // 单个下载错误处理
        void (^completionBlock)(BOOL success, NSURL *fileURL) = self.completionBlocks[downloadIDForTask];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 隐藏进度视图
            DYYYDownloadProgressView *progressView = self.progressViews[downloadIDForTask];
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

//MARK: 以下都是创建保存实况的调用方法
- (void)saveLivePhoto:(NSString *)imageSourcePath videoUrl:(NSString *)videoSourcePath {
    NSURL *photoURL = [NSURL fileURLWithPath:imageSourcePath];
    NSURL *videoURL = [NSURL fileURLWithPath:videoSourcePath];
    BOOL available = [PHAssetCreationRequest supportsAssetResourceTypes:@[@(PHAssetResourceTypePhoto), @(PHAssetResourceTypePairedVideo)]];
    if (!available) {
        return;
    }
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            return;
        }
        NSString *identifier = [NSUUID UUID].UUIDString;
        [self useAssetWriter:photoURL video:videoURL identifier:identifier complete:^(BOOL success, NSString *photoFile, NSString *videoFile, NSError *error) {
            NSURL *photo = [NSURL fileURLWithPath:photoFile];
            NSURL *video = [NSURL fileURLWithPath:videoFile];
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                [request addResourceWithType:PHAssetResourceTypePhoto fileURL:photo options:nil];
                [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:video options:nil];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [DYYYManager showToast:@"保存实况成功"];
                        // 删除临时文件
                        [[NSFileManager defaultManager] removeItemAtPath:imageSourcePath error:nil];
                        [[NSFileManager defaultManager] removeItemAtPath:videoSourcePath error:nil];
                        [[NSFileManager defaultManager] removeItemAtPath:photoFile error:nil];
                        [[NSFileManager defaultManager] removeItemAtPath:videoFile error:nil];
                    } 
                });
            }];
        }];
    }];
}
- (void)useAssetWriter:(NSURL *)photoURL video:(NSURL *)videoURL identifier:(NSString *)identifier complete:(void (^)(BOOL success, NSString *photoFile, NSString *videoFile, NSError *error))complete {
    NSString *photoName = [photoURL lastPathComponent];
    NSString *photoFile = [self filePathFromDoc:photoName];
    [self addMetadataToPhoto:photoURL outputFile:photoFile identifier:identifier];
    NSString *videoName = [videoURL lastPathComponent];
    NSString *videoFile = [self filePathFromDoc:videoName];
    [self addMetadataToVideo:videoURL outputFile:videoFile identifier:identifier];
    if (!DYYYManager.shared->group) return;
    dispatch_group_notify(DYYYManager.shared->group, dispatch_get_main_queue(), ^{
        [self finishWritingTracksWithPhoto:photoFile video:videoFile complete:complete];
    });
}
- (void)finishWritingTracksWithPhoto:(NSString *)photoFile video:(NSString *)videoFile complete:(void (^)(BOOL success, NSString *photoFile, NSString *videoFile, NSError *error))complete {
    [DYYYManager.shared->reader cancelReading];
    [DYYYManager.shared->writer finishWritingWithCompletionHandler:^{
        if (complete) complete(YES, photoFile, videoFile, nil);
    }];
}
- (void)addMetadataToPhoto:(NSURL *)photoURL outputFile:(NSString *)outputFile identifier:(NSString *)identifier {
    NSMutableData *data = [NSData dataWithContentsOfURL:photoURL].mutableCopy;
    UIImage *image = [UIImage imageWithData:data];
    CGImageRef imageRef = image.CGImage;
    NSDictionary *imageMetadata = @{(NSString *)kCGImagePropertyMakerAppleDictionary : @{@"17" : identifier}};
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((CFMutableDataRef)data, kUTTypeJPEG, 1, nil);
    CGImageDestinationAddImage(dest, imageRef, (CFDictionaryRef)imageMetadata);
    CGImageDestinationFinalize(dest);
    [data writeToFile:outputFile atomically:YES];
}

- (void)addMetadataToVideo:(NSURL *)videoURL outputFile:(NSString *)outputFile identifier:(NSString *)identifier {
    NSError *error = nil;
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (error) {
        return;
    }
    NSMutableArray<AVMetadataItem *> *metadata = asset.metadata.mutableCopy;
    AVMetadataItem *item = [self createContentIdentifierMetadataItem:identifier];
    [metadata addObject:item];
    NSURL *videoFileURL = [NSURL fileURLWithPath:outputFile];
    [self deleteFile:outputFile];
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:videoFileURL fileType:AVFileTypeQuickTimeMovie error:&error];
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
            writerOuputSettings = @{AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                    AVSampleRateKey : @(44100),
                                    AVNumberOfChannelsKey : @(2),
                                    AVEncoderBitRateKey : @(128000)};
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
    AVTimedMetadataGroup *timedMetadataGroup = [[AVTimedMetadataGroup alloc] initWithItems:@[timedItem] timeRange:timedRange];
    [adaptor appendTimedMetadataGroup:timedMetadataGroup];
    DYYYManager.shared->reader = reader;
    DYYYManager.shared->writer = writer;
    DYYYManager.shared->queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    DYYYManager.shared->group = dispatch_group_create();
    for (NSInteger i = 0; i < reader.outputs.count; ++i) {
        dispatch_group_enter(DYYYManager.shared->group);
        [self writeTrack:i];
    }
}

- (void)writeTrack:(NSInteger)trackIndex {
    AVAssetReaderOutput *output = DYYYManager.shared->reader.outputs[trackIndex];
    AVAssetWriterInput *input = DYYYManager.shared->writer.inputs[trackIndex];
    
    [input requestMediaDataWhenReadyOnQueue:DYYYManager.shared->queue usingBlock:^{
        while (input.readyForMoreMediaData) {
            AVAssetReaderStatus status = DYYYManager.shared->reader.status;
            CMSampleBufferRef buffer = NULL;
            if ((status == AVAssetReaderStatusReading) &&
                (buffer = [output copyNextSampleBuffer])) {
                BOOL success = [input appendSampleBuffer:buffer];
                CFRelease(buffer);
                if (!success) {
                   
                    [input markAsFinished];
                    dispatch_group_leave(DYYYManager.shared->group);
                    return;
                }
            } else {
                if (status == AVAssetReaderStatusReading) {
                   
                } else if (status == AVAssetReaderStatusCompleted) {
                   
                } else if (status == AVAssetReaderStatusCancelled) {
                   
                } else if (status == AVAssetReaderStatusFailed) {
                   
                }
                [input markAsFinished];
                dispatch_group_leave(DYYYManager.shared->group);
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
    NSArray *spec = @[@{(NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier : @"mdta/com.apple.quicktime.still-image-time",
                        (NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType : (NSString *)kCMMetadataBaseDataType_SInt8 }];
    CMFormatDescriptionRef desc = NULL;
    CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, (__bridge CFArrayRef)spec, &desc);
    AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata outputSettings:nil sourceFormatHint:desc];
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
- (NSString *)filePathFromDoc:(NSString *)filename {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:filename];
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
    
    [self downloadAllLivePhotosWithProgress:livePhotos progress:nil completion:^(NSInteger successCount, NSInteger totalCount) {
        [self showToast:[NSString stringWithFormat:@"已保存 %ld/%ld 个实况照片", (long)successCount, (long)totalCount]];
    }];
}

+ (void)downloadAllLivePhotosWithProgress:(NSArray<NSDictionary *> *)livePhotos progress:(void (^)(NSInteger current, NSInteger total))progressBlock completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion {
    if (livePhotos.count == 0) {
        if (completion) {
            completion(0, 0);
        }
        return;
    }
    
    // 创建自定义批量下载进度条界面
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        DYYYDownloadProgressView *progressView = [[DYYYDownloadProgressView alloc] initWithFrame:screenBounds];
        progressView.progressLabel.text = @"准备下载实况照片...";
        [progressView show];
        
        NSString *batchID = [NSUUID UUID].UUIDString;
        
        // 设置取消按钮事件
        progressView.cancelBlock = ^{
            [DYYYManager cancelAllDownloads];
            if (completion) {
                completion(0, livePhotos.count);
            }
        };
        
        // 创建下载任务
        __block NSInteger completedCount = 0;
        __block NSInteger successCount = 0;
        NSInteger totalCount = livePhotos.count;
        
        // 为每个实况照片创建下载任务
        for (NSInteger index = 0; index < livePhotos.count; index++) {
            NSDictionary *livePhoto = livePhotos[index];
            NSURL *imageURL = [NSURL URLWithString:livePhoto[@"imageURL"]];
            NSURL *videoURL = [NSURL URLWithString:livePhoto[@"videoURL"]];
            
            if (!imageURL || !videoURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completedCount++;
                    float progress = (float)completedCount / totalCount;
                    [progressView setProgress:progress];
                    progressView.progressLabel.text = [NSString stringWithFormat:@"进度: %ld/%ld", (long)completedCount, (long)totalCount];
                    
                    if (progressBlock) {
                        progressBlock(completedCount, totalCount);
                    }
                    
                    if (completedCount >= totalCount) {
                        [progressView dismiss];
                        if (completion) {
                            completion(successCount, totalCount);
                        }
                    }
                });
                continue;
            }
            
            // 延迟启动每个下载，避免同时发起大量网络请求
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, index * 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self downloadLivePhoto:imageURL videoURL:videoURL completion:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successCount++;
                        completedCount++;
                        
                        float progress = (float)completedCount / totalCount;
                        [progressView setProgress:progress];
                        progressView.progressLabel.text = [NSString stringWithFormat:@"进度: %ld/%ld", (long)completedCount, (long)totalCount];
                        
                        if (progressBlock) {
                            progressBlock(completedCount, totalCount);
                        }
                        
                        if (completedCount >= totalCount) {
                            [progressView dismiss];
                            if (completion) {
                                completion(successCount, totalCount);
                            }
                        }
                    });
                }];
            });
        }
    });
}

+ (BOOL)isDarkMode {
    return [NSClassFromString(@"AWEUIThemeManager") isLightTheme] ? NO : YES;
}

@end 