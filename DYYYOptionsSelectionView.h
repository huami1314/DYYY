#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYYYOptionsSelectionView : NSObject

/**
 * 显示选项选择视图
 * @param preferenceKey 用于存储选择的NSUserDefaults键
 * @param optionsArray 可选项数组
 * @param headerText 标题文本
 * @param presentingVC 要在其上显示视图的视图控制器
 * @return 当前选中的选项值
 */
+ (NSString *)showWithPreferenceKey:(NSString *)preferenceKey
                       optionsArray:(NSArray<NSString *> *)optionsArray
                         headerText:(NSString *)headerText
                     onPresentingVC:(UIViewController *)presentingVC;

@end

NS_ASSUME_NONNULL_END