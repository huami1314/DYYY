#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYYYUtils : NSObject

/**
 * 获取当前显示的顶层视图控制器
 * @return 顶层视图控制器
 */
+ (UIViewController *)topView;

+ (NSUInteger)clearDirectoryContents:(NSString *)directoryPath;
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