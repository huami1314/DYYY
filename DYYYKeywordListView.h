#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYYYKeywordListView : UIView <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) void (^onConfirm)(NSArray *keywords);
@property (nonatomic, copy) void (^onCancel)(void);

- (instancetype)initWithTitle:(NSString *)title keywords:(NSArray * _Nullable)keywords;
- (void)show;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END