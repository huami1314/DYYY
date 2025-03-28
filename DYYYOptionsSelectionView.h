#import <UIKit/UIKit.h>

// 自定义选项选择视图
@interface DYYYOptionsSelectionView : UIView
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NSArray<NSString *> *options;
@property (nonatomic, strong) NSMutableArray<UIButton *> *optionButtons;
@property (nonatomic, copy) void (^onSelect)(NSInteger selectedIndex, NSString *selectedValue);

- (instancetype)initWithTitle:(NSString *)title options:(NSArray<NSString *> *)options;
- (void)show;
- (void)dismiss;
@end
