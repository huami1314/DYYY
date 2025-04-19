#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 定义警告框操作回调类型
typedef void (^DYYYAlertActionHandler)(void);

@interface DYYYBottomAlertView : UIView

/**
 * 显示警告框，支持完全自定义
 * @param title 标题文本
 * @param message 消息文本
 * @param cancelButtonText 取消按钮文本
 * @param confirmButtonText 确认按钮文本
 * @param cancelAction 点击取消按钮回调
 * @param confirmAction 点击确认按钮回调
 * @return 返回控制器实例，可用于视图管理
 */
+ (UIViewController *)showAlertWithTitle:(nullable NSString *)title
                                 message:(nullable NSString *)message
                         cancelButtonText:(nullable NSString *)cancelButtonText
                        confirmButtonText:(nullable NSString *)confirmButtonText
                            cancelAction:(nullable DYYYAlertActionHandler)cancelAction
                           confirmAction:(nullable DYYYAlertActionHandler)confirmAction;


/**
 * 显示警告框，使用默认按钮文本
 * @param title 标题文本
 * @param message 消息文本
 * @param cancelAction 点击取消按钮回调
 * @param confirmAction 点击确认按钮回调
 * @return 返回控制器实例，可用于视图管理
 */
+ (UIViewController *)showAlertWithTitle:(nullable NSString *)title
                                 message:(nullable NSString *)message
                            cancelAction:(nullable DYYYAlertActionHandler)cancelAction
                           confirmAction:(nullable DYYYAlertActionHandler)confirmAction;

/**
 * 关闭警告框
 */
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END