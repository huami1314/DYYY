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

+ (void)saveAnimatedSticker:(YYAnimatedImageView *)targetStickerView {
    if (!targetStickerView) {
        [DYYYManager showToast:@"无法获取表情视图"];
        return;
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status != PHAuthorizationStatusAuthorized) {
                [DYYYManager showToast:@"需要相册权限才能保存"];
                return;
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // 获取GIF帧和持续时间
                NSArray *images = [self getImagesFromYYAnimatedImageView:targetStickerView];
                CGFloat duration = [self getDurationFromYYAnimatedImageView:targetStickerView];
                
                if (!images || images.count == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [DYYYManager showToast:@"无法获取表情帧"];
                    });
                    return;
                }
                
                NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                                      [NSString stringWithFormat:@"sticker_%ld.gif", (long)[[NSDate date] timeIntervalSince1970]]];
                
                BOOL success = [self createGIFWithImages:images duration:duration path:tempPath progress:^(float progress) {
                    // 进度回调保留但不再使用
                }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!success) {
                        return;
                    }
                    
                    [self saveGIFToPhotoLibrary:tempPath completion:^(BOOL saved, NSError *error) {
                        if (saved) {
                            [DYYYToast showSuccessToastWithMessage:@"已保存到相册"];
                        } else {
                            NSString *errorMsg = error ? error.localizedDescription : @"未知错误";
                            [DYYYManager showToast:[NSString stringWithFormat:@"保存失败: %@", errorMsg]];
                        }
                    }];
                });
            });
        });
    }];
}

+ (NSArray *)getImagesFromYYAnimatedImageView:(YYAnimatedImageView *)imageView {
    if (!imageView || !imageView.image) {
        return nil;
    }
    
    if ([imageView.image respondsToSelector:@selector(images)]) {
        return [imageView.image performSelector:@selector(images)];
    } else if (imageView.animationImages) {
        return imageView.animationImages;
    }
    
    return nil;
}

+ (CGFloat)getDurationFromYYAnimatedImageView:(YYAnimatedImageView *)imageView {
    if (!imageView || !imageView.image) {
        return 0;
    }
    
    if ([imageView.image respondsToSelector:@selector(duration)]) {
        CGFloat duration = [[imageView.image performSelector:@selector(duration)] floatValue];
        if (duration > 0) {
            return duration;
        }
    }
    
    if (imageView.animationDuration > 0 && imageView.animationImages.count > 0) {
        return imageView.animationDuration;
    }
    
    NSArray *images = [self getImagesFromYYAnimatedImageView:imageView];
    return 0.1 * (images ? images.count : 10);
}

+ (BOOL)createGIFWithImages:(NSArray *)images duration:(CGFloat)duration path:(NSString *)path progress:(void(^)(float progress))progressBlock {
    if (images.count == 0) return NO;
    
    // 计算每帧延迟时间
    float frameDuration = duration / images.count;
    
    // 创建GIF文件
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
        (__bridge CFURLRef)[NSURL fileURLWithPath:path],
        kUTTypeGIF,
        images.count,
        NULL
    );
    
    if (!destination) return NO;
    
    // 设置GIF属性
    NSDictionary *gifProperties = @{
        (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
            (__bridge NSString *)kCGImagePropertyGIFLoopCount: @0  // 无限循环
        }
    };
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);
    
    // 添加每一帧
    for (NSUInteger i = 0; i < images.count; i++) {
        UIImage *image = images[i];
        
        // 设置帧延迟
        NSDictionary *frameProperties = @{
            (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                (__bridge NSString *)kCGImagePropertyGIFDelayTime: @(frameDuration)
            }
        };
        
        CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        
        if (progressBlock) {
            progressBlock((float)(i + 1) / images.count);
        }
    }
    
    // 完成GIF创建
    BOOL success = CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    return success;
}

+ (void)saveGIFToPhotoLibrary:(NSString *)path completion:(void(^)(BOOL success, NSError *error))completion {
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:fileURL options:nil];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
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

@end