#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 定义警告框操作回调类型
typedef void (^DYYYAlertActionHandler)(void);

@interface DYYYBottomAlertView : UIView

/**
 * 显示带头像的警告框，支持自定义按钮文本
 * @param title 标题文本
 * @param message 消息文本
 * @param avatarURL 头像URL (为空时不显示头像)
 * @param cancelButtonText 取消按钮文本 (为空时使用默认文本)
 * @param confirmButtonText 确认按钮文本 (为空时使用默认文本)
 * @param cancelAction 点击取消按钮回调
 * @param closeAction 点击关闭按钮、下滑或点击外部区域关闭弹窗回调 (为空时使用取消按钮回调)
 * @param confirmAction 点击确认按钮回调
 * @return 返回控制器实例，可用于视图管理
 */
+ (UIViewController *)showAlertWithTitle:(nullable NSString *)title
                                 message:(nullable NSString *)message
                               avatarURL:(nullable NSString *)avatarURL
                        cancelButtonText:(nullable NSString *)cancelButtonText
                       confirmButtonText:(nullable NSString *)confirmButtonText
                            cancelAction:(nullable DYYYAlertActionHandler)cancelAction
                             closeAction:(nullable DYYYAlertActionHandler)closeAction
                           confirmAction:(nullable DYYYAlertActionHandler)confirmAction;

/**
 * 关闭警告框
 */
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END