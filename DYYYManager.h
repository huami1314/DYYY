#import <UIKit/UIKit.h>
#import "AwemeHeaders.h"

@interface AWEUIThemeManager : NSObject
@property (nonatomic, assign) BOOL isLightTheme;
@end

@interface DYYYManager : NSObject
//存储文件类行
@property (nonatomic, strong) NSMutableDictionary *fileLinks; 
+ (instancetype)shared;

+ (UIWindow *)getActiveWindow;
+ (UIViewController *)getActiveTopController;
+ (UIColor *)colorWithHexString:(NSString *)hexString;
+ (void)showToast:(NSString *)text;
+ (void)saveMedia:(NSURL *)mediaURL mediaType:(MediaType)mediaType completion:(void (^)(void))completion;

// 新增带进度的下载方法
+ (void)downloadLivePhoto:(NSURL *)imageURL videoURL:(NSURL *)videoURL completion:(void (^)(void))completion;
+ (void)downloadAllLivePhotos:(NSArray<NSDictionary *> *)livePhotos;
+ (void)downloadAllLivePhotosWithProgress:(NSArray<NSDictionary *> *)livePhotos progress:(void (^)(NSInteger current, NSInteger total))progressBlock completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion;
+ (void)downloadMedia:(NSURL *)url mediaType:(MediaType)mediaType completion:(void (^)(BOOL success))completion;
+ (void)downloadMediaWithProgress:(NSURL *)url mediaType:(MediaType)mediaType progress:(void (^)(float progress))progressBlock completion:(void (^)(BOOL success, NSURL *fileURL))completion;
+ (void)cancelAllDownloads;

// 并发下载多个图片
+ (void)downloadAllImages:(NSMutableArray *)imageURLs;
+ (void)downloadAllImagesWithProgress:(NSMutableArray *)imageURLs progress:(void (^)(NSInteger current, NSInteger total))progressBlock completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion;
- (void)saveLivePhoto:(NSString *)imageSourcePath videoUrl:(NSString *)videoSourcePath;
//获取主题状态
+ (BOOL)isDarkMode;

/**
 * 解析分享链接并下载视频
 * @param shareLink 视频分享链接
 * @param apiKey API密钥
 */
 + (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink apiKey:(NSString *)apiKey;

 /**
  * 批量下载视频和图片资源
  * @param videos 视频资源数组
  * @param images 图片资源数组
  */
 + (void)batchDownloadResources:(NSArray *)videos images:(NSArray *)images;
@end
