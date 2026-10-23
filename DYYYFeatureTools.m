#import "DYYYFeatureTools.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <objc/runtime.h>
#import <ImageIO/ImageIO.h>

#pragma mark - Progress GIF picker

@interface DYYYGIFPickerCoordinator : NSObject <UIDocumentPickerDelegate>
@property(nonatomic, copy) void (^completion)(NSString * _Nullable savedPath);
@end

@implementation DYYYGIFPickerCoordinator
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    if (self.completion) self.completion(nil);
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *source = urls.firstObject;
    if (!source) { if (self.completion) self.completion(nil); return; }
    BOOL scoped = [source startAccessingSecurityScopedResource];
    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *directory = [documents URLByAppendingPathComponent:@"DYYY" isDirectory:YES];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    [fm createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:&error];
    NSURL *destination = [directory URLByAppendingPathComponent:@"DYYYProgressAnimation.gif"];
    if (!error && [fm fileExistsAtPath:destination.path]) [fm removeItemAtURL:destination error:&error];
    if (!error) [fm copyItemAtURL:source toURL:destination error:&error];
    if (scoped) [source stopAccessingSecurityScopedResource];
    NSString *savedPath = error ? nil : destination.path;
    if (savedPath) {
        [[NSUserDefaults standardUserDefaults] setObject:savedPath forKey:@"DYYYProgressAnimationPath"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        NSLog(@"[DYYY] GIF 导入失败: %@", error);
    }
    if (self.completion) self.completion(savedPath);
}
@end

void DYYYPresentProgressGIFPicker(UIViewController *presentingViewController, void (^completion)(NSString * _Nullable savedPath)) {
    if (!presentingViewController) { if (completion) completion(nil); return; }
    UIDocumentPickerViewController *picker = nil;
    if (@available(iOS 14.0, *)) {
        UTType *gifType = [UTType typeWithFilenameExtension:@"gif"];
        UTType *fallbackType = [UTType typeWithIdentifier:@"public.data"];
        picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:(gifType ? @[gifType] : (fallbackType ? @[fallbackType] : @[])) asCopy:YES];
    } else {
        picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"com.compuserve.gif"] inMode:UIDocumentPickerModeImport];
    }
    DYYYGIFPickerCoordinator *coordinator = [DYYYGIFPickerCoordinator new];
    coordinator.completion = completion;
    picker.delegate = coordinator;
    objc_setAssociatedObject(picker, @selector(DYYYPresentProgressGIFPicker), coordinator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [presentingViewController presentViewController:picker animated:YES completion:nil];
}


UIImage *DYYYAnimatedImageFromGIFPath(NSString *path) {
    if (path.length == 0) return nil;
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!source) return nil;
    size_t count = CGImageSourceGetCount(source);
    NSMutableArray<UIImage *> *frames = [NSMutableArray arrayWithCapacity:count];
    NSTimeInterval duration = 0;
    for (size_t i = 0; i < count; i++) {
        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, i, NULL);
        if (!cgImage) continue;
        NSDictionary *properties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, i, NULL));
        NSDictionary *gif = properties[(NSString *)kCGImagePropertyGIFDictionary];
        NSNumber *delay = gif[(NSString *)kCGImagePropertyGIFUnclampedDelayTime] ?: gif[(NSString *)kCGImagePropertyGIFDelayTime];
        NSTimeInterval frameDuration = delay.doubleValue;
        if (frameDuration < 0.02) frameDuration = 0.1;
        duration += frameDuration;
        [frames addObject:[UIImage imageWithCGImage:cgImage scale:UIScreen.mainScreen.scale orientation:UIImageOrientationUp]];
        CGImageRelease(cgImage);
    }
    CFRelease(source);
    if (frames.count == 0) return nil;
    if (frames.count == 1) return frames.firstObject;
    return [UIImage animatedImageWithImages:frames duration:MAX(duration, 0.1)];
}
