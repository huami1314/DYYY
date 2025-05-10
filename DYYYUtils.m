#import "DYYYUtils.h"

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
        // 跳过隐藏文件
        if ([item hasPrefix:@"."]) {
            continue;
        }
        
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:item];
        
        // 获取文件属性
        NSDictionary<NSFileAttributeKey, id> *attrs = [fileManager attributesOfItemAtPath:fullPath error:nil];
        NSUInteger fileSize = attrs ? [attrs fileSize] : 0;
        
        // 判断是文件还是目录
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
            if (isDirectory) {
                // 如果是目录，先递归清理内容
                fileSize += [self clearDirectoryContents:fullPath];
            }
            
            // 然后删除文件或空目录
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
@end

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
