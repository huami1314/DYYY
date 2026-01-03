#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYYYFilterSettingsView : UIView

// 确认按钮点击时的回调，参数为选择的文本
@property(nonatomic, copy, nullable) void (^onConfirm)(NSString *selectedText);

// 取消按钮点击时的回调
@property(nonatomic, copy, nullable) void (^onCancel)(void);

// 过滤关键词按钮点击时的回调
@property(nonatomic, copy, nullable) void (^onKeywordFilterTap)(void);

// 初始化方法，接受标题、待分词文本和当前拍同款名称（可选）
- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text propName:(nullable NSString *)propName;

// 兼容旧接口
- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text;

// 显示对话框
- (void)show;

// 关闭对话框
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END