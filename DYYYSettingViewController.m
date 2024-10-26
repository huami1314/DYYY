#import "DYYYSettingViewController.h"

@@interface DYYYSettingViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSArray<DYYYSettingItem *> *> *settingSections;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, assign) BOOL isDanmuColorEnabled; // 新增属性
@end

@implementation DYYYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    [self setupAppearance];
    [self setupTableView];
    [self setupSettingItems];
    [self setupFooterLabel];
    [self addTitleGradientAnimation];

    // 添加键盘事件监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardFrame.size.height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

- (void)setupSettingItems {
    self.isDanmuColorEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"];
    
    self.settingSections = @[
        @[
            [DYYYSettingItem itemWithTitle:@"设置顶栏透明" key:@"DYYYtopbartransparent" type:DYYYSettingItemTypeTextField placeholder:@"输入0-1的小数"],
            [DYYYSettingItem itemWithTitle:@"设置全局透明" key:@"DYYYGlobalTransparency" type:DYYYSettingItemTypeTextField placeholder:@"输入0-1的小数"],
            [DYYYSettingItem itemWithTitle:@"设置默认倍速" key:@"DYYYDefaultSpeed" type:DYYYSettingItemTypeSpeedPicker]
        ],
        @[
            [DYYYSettingItem itemWithTitle:@"隐藏全屏观看" key:@"DYYYisHiddenEntry" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏加号" key:@"DYYYisHiddenJia" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏红点" key:@"DYYYisHiddenBottomDot" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏侧栏红点" key:@"DYYYisHiddenSidebarDot" type:DYYYSettingItemTypeSwitch]
        ],
        @[
            [DYYYSettingItem itemWithTitle:@"隐藏点赞按钮" key:@"DYYYHideLikeButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏评论按钮" key:@"DYYYHideCommentButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏收藏按钮" key:@"DYYYHideCollectButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏分享按钮" key:@"DYYYHideShareButton" type:DYYYSettingItemTypeSwitch]
        ],
        @[
            [DYYYSettingItem itemWithTitle:@"开启弹幕改色" key:@"DYYYEnableDanmuColor" type:DYYYSettingItemTypeSwitch],
            self.isDanmuColorEnabled ? [DYYYSettingItem itemWithTitle:@"修改弹幕颜色" key:@"DYYYdanmuColor" type:DYYYSettingItemTypeTextField placeholder:@"十六进制颜色"] : nil
        ]
    ].mutableCopy;
    
    // 移除nil值
    for (NSMutableArray *section in self.settingSections) {
        [section removeObjectIdenticalTo:[NSNull null]];
    }
}

#pragma mark - UITableViewDelegate

- (void)switchToggled:(UISwitch *)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag % 1000 inSection:sender.tag / 1000];
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:item.key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([item.key isEqualToString:@"DYYYEnableDanmuColor"]) {
        self.isDanmuColorEnabled = sender.isOn;
        [self setupSettingItems];
        [self.tableView reloadData];
    }
}

@end