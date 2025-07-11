#import <Photos/Photos.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YYAnimatedImageView;

@interface DYYYUtils : NSObject

#pragma mark - Public UI/Window/Controller Utilities (公共 UI/窗口/控制器 工具)

/**
 * 获取当前活动窗口
 */
+ (UIWindow *)getActiveWindow;

/**
 * 获取当前显示的顶层视图控制器
 * @return 顶层视图控制器
 */
+ (UIViewController *)topView;

+ (UIViewController *)firstAvailableViewControllerFromView:(UIView *)view;
/* 在视图控制器层级中查找指定类的控制器 */
+ (UIViewController *)findViewControllerOfClass:(Class)targetClass inViewController:(UIViewController *)vc;
+ (UIResponder *)findAncestorResponderOfClass:(Class)targetClass fromView:(UIView *)view;
+ (NSArray<UIView *> *)findAllSubviewsOfClass:(Class)targetClass inView:(UIView *)view;
+ (UIView *)findSubviewOfClass:(Class)targetClass inView:(UIView *)view;
/* 判断视图是否包含指定类型的子视图 */
+ (BOOL)containsSubviewOfClass:(Class)targetClass inView:(UIView *)view;
+ (void)applyBlurEffectToView:(UIView *)view transparency:(float)userTransparency blurViewTag:(NSInteger)tag;
+ (void)clearBackgroundRecursivelyInView:(UIView *)view;

/**
 * 显示提示信息
 * @param text 要显示的文本
 */
+ (void)showToast:(NSString *)text;

/**
 * 检查当前是否为暗黑模式
 */
+ (BOOL)isDarkMode;

#pragma mark - Public File Management (公共文件管理)

/**格式化大小
 * 将大小转换为易读的格式
 * @param size 文件大小（字节数）
 * @return 格式化后的字符串，例如 "1.5 MB"
 */
+ (NSString *)formattedSize:(unsigned long long)size;

/**
 * 递归统计目录大小
 */
+ (unsigned long long)directorySizeAtPath:(NSString *)directoryPath;
/**
 * 递归删除目录下所有内容
 */
+ (void)removeAllContentsAtPath:(NSString *)directoryPath;

/**
 * 返回插件缓存目录路径，默认为 tmp/DYYY
 */
+ (NSString *)cacheDirectory;

/**
 * 清理插件缓存目录
 */
+ (void)clearCacheDirectory;

/**
 * 在缓存目录下生成指定文件名的完整路径
 */
+ (NSString *)cachePathForFilename:(NSString *)filename;

#pragma mark - Public Color Scheme Methods (公共颜色方案方法)

/**
 * @brief 递归地将指定的文本颜色应用到视图及其所有子视图中的 UILabel 和 UIButton。
 *        可以通过 shouldExcludeViewBlock 提供自定义的排除逻辑。
 * @param color 要应用的文本颜色。
 * @param view 起始视图。
 * @param excludeBlock 一个 Block，用于判断是否应该排除某个视图。如果 Block 返回 YES，则该视图不会被应用颜色。可以为 nil。
 */
+ (void)applyTextColorRecursively:(UIColor *)color inView:(UIView *)view shouldExcludeViewBlock:(BOOL (^)(UIView *subview))excludeBlock;

/**
 * @brief 将指定的颜色字符串方案应用到 UILabel 上，实现像素级渐变。
 *        此方法通过修改 UILabel 的 attributedText 来实现颜色效果。
 * @param label 要应用颜色的 UILabel。
 * @param colorHexString 颜色方案字符串
 *        - "rainbow" 或 "#rainbow": 七色渐变彩虹固定方案（红橙黄绿青蓝紫）。
 *        - "rainbow_rotating" 或 "#rainbow_rotating": 七色渐变彩虹旋转方案（每次调用时旋转起始颜色）。
 *        - "random_gradient" 或 "#random_gradient": 随机三色渐变方案（每次调用时随机生成三种颜色）。
 *        - "random" 或 "#random": 返回一个随机单色（每次调用时随机生成颜色）。
 *        - "HEX1,HEX2,..." 或 "#HEX1,#HEX2,...": 返回一个多色渐变方案，支持任意数量的十六进制颜色。
 *        - "HEX" 或 "#HEX": 返回一个单色方案。
 */
+ (void)applyColorSettingsToLabel:(UILabel *)label colorHexString:(NSString *)colorHexString;
+ (void)applyStrokeToLabel:(UILabel *)label strokeColor:(UIColor *)strokeColor strokeWidth:(CGFloat)strokeWidth;
+ (void)applyShadowToLabel:(UILabel *)label shadow:(NSShadow *)shadow;

/**
 * @brief 根据十六进制字符串返回一个适合用于图案填充的 UIColor。
 *        此方法主要用于 UILabel.textColor 等需要 UIColor 对象的场景。
 * @param hexString 颜色方案字符串，用法见 applyColorSettingsToLabel
 * @param targetWidth UIImage 需要的宽度
 * @return 配置好的 UIColor 实例。如果无法解析，返回白色。
 *         - 对于单色或随机色，直接返回对应的 UIColor 对象。
 *         - 对于渐变色，它会渲染一个单像素高度和 targetWidth 宽度的 UIImage 用于图案填充。
 */
+ (UIColor *)colorFromSchemeHexString:(NSString *)hexString targetWidth:(CGFloat)targetWidth;

/**
 * @brief 根据十六进制字符串返回一个配置好的 CALayer (纯色或渐变)。
 *        此方法适用于将颜色方案作为 CALayer 的 mask 或直接作为子层。
 * @param hexString 颜色方案字符串，用法见 applyColorSettingsToLabel
 * @param frame CALayer 的 frame。
 * @return 配置好的 CALayer 实例。如果无法解析或 frame 无效，返回 nil。
 *         - 对于纯色或随机色，返回一个 `CALayer` 实例，其 `backgroundColor` 已设置。
 *         - 对于渐变色返回一个 `CAGradientLayer` 实例。
 *         - 如果无法解析或 `frame` 无效，返回 `nil`。
 */
+ (CALayer *)layerFromSchemeHexString:(NSString *)hexString frame:(CGRect)frame;

@end

#pragma mark - External C Functions (外部 C 函数)

#ifdef __cplusplus
extern "C" {
#endif

/**
 * 清除分享URL中的查询参数
 * @param url 需要清理的URL字符串
 * @return 清理后的URL字符串
 */
NSString *_Nullable cleanShareURL(NSString *_Nullable url);

/**
 * 获取当前显示的顶层视图控制器
 * @return 顶层视图控制器
 */
UIViewController *_Nullable topView(void);

/**
 * 判断视图是否包含指定类型的子视图
 */
BOOL viewContainsSubviewOfClass(UIView *_Nullable view, Class _Nullable viewClass);

/** 判断是否为右侧互动区域 */
BOOL isRightInteractionStack(UIView *_Nullable stackView);

/** 判断是否为左侧互动区域 */
BOOL isLeftInteractionStack(UIView *_Nullable stackView);

/** 在视图控制器层级中查找指定类的控制器 */
UIViewController *_Nullable findViewControllerOfClass(UIViewController *_Nullable rootVC, Class _Nullable targetClass);

/** 根据设置应用顶栏透明度 */
void applyTopBarTransparency(UIView *_Nullable topBar);

/**
 * 递归将任意对象转换为 JSON 可序列化对象
 */
id DYYYJSONSafeObject(id _Nullable obj);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
