#import <UIKit/UIKit.h>
#import "AwemeHeaders.h"

@interface DYYYManager : NSObject

+ (instancetype)shared;

+ (UIWindow *)getActiveWindow;
+ (UIViewController *)getActiveTopController;
+ (UIColor *)colorWithHexString:(NSString *)hexString;
+ (void)showToast:(NSString *)text;
+ (void)saveMedia:(NSURL *)mediaURL mediaType:(MediaType)mediaType completion:(void (^)(void))completion;

// 新增带进度的下载方法
+ (void)downloadMedia:(NSURL *)url mediaType:(MediaType)mediaType completion:(void (^)(void))completion;
+ (void)downloadMediaWithProgress:(NSURL *)url mediaType:(MediaType)mediaType progress:(void (^)(float progress))progressBlock completion:(void (^)(BOOL success, NSURL *fileURL))completion;
+ (void)cancelAllDownloads;

// 并发下载多个图片
+ (void)downloadAllImages:(NSMutableArray *)imageURLs;
+ (void)downloadAllImagesWithProgress:(NSMutableArray *)imageURLs progress:(void (^)(NSInteger current, NSInteger total))progressBlock completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion;

@end 