#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class YYAnimatedImageView;

@interface DYYYUtils : NSObject

/**
 * 获取当前显示的顶层视图控制器
 * @return 顶层视图控制器
 */
+ (UIViewController *)topView;

/**
 * 清除指定目录的所有内容
 * @param directoryPath 要清理的目录路径
 * @return 清理的文件总大小
 */
+ (NSUInteger)clearDirectoryContents:(NSString *)directoryPath;

/**
 * 保存动画贴纸到相册
 * @param targetStickerView 包含动画的YYAnimatedImageView
 */
+ (void)saveAnimatedSticker:(YYAnimatedImageView *)targetStickerView;

@end

#ifdef __cplusplus
extern "C" {
#endif

/**
 * 清除分享URL中的查询参数
 * @param url 需要清理的URL字符串
 * @return 清理后的URL字符串
 */
NSString * _Nullable cleanShareURL(NSString * _Nullable url);

/**
 * 获取当前显示的顶层视图控制器
 * @return 顶层视图控制器
 */
UIViewController * _Nullable topView(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END