#import <UIKit/UIKit.h>
#import "AwemeHeaders.h"

// 主题管理类（外部类声明）
@interface AWEUIThemeManager : NSObject
@property (nonatomic, assign) BOOL isLightTheme;
@end

/**
 * DYYY 主管理器类
 * 处理UI、媒体下载、保存和视频合成等功能
 */
@interface DYYYManager : NSObject

#pragma mark - 属性和基础方法
//存储文件类型
@property (nonatomic, strong) NSMutableDictionary *fileLinks;

/**
 * 获取单例实例
 */
+ (instancetype)shared;

#pragma mark - UI相关方法
/**
 * 获取当前活动窗口
 */
+ (UIWindow *)getActiveWindow;

/**
 * 获取当前顶层控制器
 */
+ (UIViewController *)getActiveTopController;

/**
 * 根据十六进制字符串创建颜色对象
 * @param hexString 十六进制颜色字符串
 */
+ (UIColor *)colorWithHexString:(NSString *)hexString;

/**
 * 显示提示信息
 * @param text 要显示的文本
 */
+ (void)showToast:(NSString *)text;

/**
 * 检查当前是否为暗黑模式
 */
+ (BOOL)isDarkMode;

#pragma mark - 媒体保存方法
/**
 * 保存媒体文件到相册
 * @param mediaURL 媒体文件URL
 * @param mediaType 媒体类型
 * @param completion 完成回调
 */
+ (void)saveMedia:(NSURL *)mediaURL 
        mediaType:(MediaType)mediaType 
       completion:(void (^)(void))completion;

/**
 * 保存实况照片
 * @param imageSourcePath 图片源路径
 * @param videoSourcePath 视频源路径
 */
- (void)saveLivePhoto:(NSString *)imageSourcePath 
             videoUrl:(NSString *)videoSourcePath;

#pragma mark - 媒体下载方法
/**
 * 下载媒体文件
 * @param url 媒体URL
 * @param mediaType 媒体类型
 * @param completion 完成回调
 */
+ (void)downloadMedia:(NSURL *)url 
            mediaType:(MediaType)mediaType 
           completion:(void (^)(BOOL success))completion;

/**
 * 带进度的媒体下载
 * @param url 媒体URL
 * @param mediaType 媒体类型
 * @param progressBlock 进度回调
 * @param completion 完成回调
 */
+ (void)downloadMediaWithProgress:(NSURL *)url
                        mediaType:(MediaType)mediaType
                         progress:(void (^)(float progress))progressBlock
                       completion:(void (^)(BOOL success, NSURL *fileURL))completion;

/**
 * 下载实况照片
 * @param imageURL 图片URL
 * @param videoURL 视频URL
 * @param completion 完成回调
 */
+ (void)downloadLivePhoto:(NSURL *)imageURL 
                 videoURL:(NSURL *)videoURL 
               completion:(void (^)(void))completion;

/**
 * 批量下载实况照片
 * @param livePhotos 实况照片数组
 */
+ (void)downloadAllLivePhotos:(NSArray<NSDictionary *> *)livePhotos;

/**
 * 带进度的批量实况照片下载
 * @param livePhotos 实况照片数组
 * @param progressBlock 进度回调
 * @param completion 完成回调
 */
+ (void)downloadAllLivePhotosWithProgress:(NSArray<NSDictionary *> *)livePhotos
                                 progress:(void (^)(NSInteger current, NSInteger total))progressBlock
                               completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion;

/**
 * 批量下载图片
 * @param imageURLs 图片URL数组
 */
+ (void)downloadAllImages:(NSMutableArray *)imageURLs;

/**
 * 带进度的批量图片下载
 * @param imageURLs 图片URL数组
 * @param progressBlock 进度回调
 * @param completion 完成回调
 */
+ (void)downloadAllImagesWithProgress:(NSMutableArray *)imageURLs
                             progress:(void (^)(NSInteger current, NSInteger total))progressBlock
                           completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion;

/**
 * 取消所有下载任务
 */
+ (void)cancelAllDownloads;

#pragma mark - 视频处理方法
/**
 * 解析分享链接并下载视频
 * @param shareLink 视频分享链接
 * @param apiKey API密钥
 */
+ (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink 
                                    apiKey:(NSString *)apiKey;

/**
 * 批量下载视频和图片资源
 * @param videos 视频资源数组
 * @param images 图片资源数组
 */
+ (void)batchDownloadResources:(NSArray *)videos 
                        images:(NSArray *)images;

/**
 * 从多种媒体源创建视频
 * @param imageURLs 图片URL数组
 * @param livePhotos 实况照片数组（每项包含图片和视频URL）
 * @param bgmURL 背景音乐URL
 * @param progressBlock 进度回调
 * @param completion 完成回调
 */
+ (void)createVideoFromMedia:(NSArray<NSString *> *)imageURLs
                  livePhotos:(NSArray<NSDictionary *> *)livePhotos
                      bgmURL:(NSString *)bgmURL
                    progress:(void (^)(NSInteger current, NSInteger total, NSString *status))progressBlock
                  completion:(void (^)(BOOL success, NSString *message))completion;

@end