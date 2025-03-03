#import "DYYYSettingViewController.h"

typedef NS_ENUM(NSInteger, DYYYSettingItemType) {
    DYYYSettingItemTypeSwitch,
    DYYYSettingItemTypeTextField,
    DYYYSettingItemTypeSpeedPicker
};

@interface DYYYSettingItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) DYYYSettingItemType type;
@property (nonatomic, copy, nullable) NSString *placeholder;

+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type;
+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type placeholder:(nullable NSString *)placeholder;

@end

@implementation DYYYSettingItem

+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type {
    return [self itemWithTitle:title key:key type:type placeholder:nil];
}

+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type placeholder:(nullable NSString *)placeholder {
    DYYYSettingItem *item = [[DYYYSettingItem alloc] init];
    item.title = title;
    item.key = key;
    item.type = type;
    item.placeholder = placeholder;
    return item;
}

@end

@interface DYYYSettingViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSArray<DYYYSettingItem *> *> *settingSections;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) NSMutableArray<NSString *> *sectionTitles;
@property (nonatomic, strong) NSMutableSet *expandedSections;

@end

@implementation DYYYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"DYYY设置";
    self.expandedSections = [NSMutableSet set];
    [self setupAppearance];
    [self setupTableView];
    [self setupSettingItems];
    [self setupSectionTitles];
    [self setupFooterLabel];
    [self addTitleGradientAnimation];
}

- (void)setupAppearance {
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.tableView.sectionHeaderTopPadding = 0;
    [self.view addSubview:self.tableView];
}

- (void)setupSettingItems {
    self.settingSections = @[
        @[
            [DYYYSettingItem itemWithTitle:@"开启弹幕改色" key:@"DYYYEnableDanmuColor" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"修改弹幕颜色" key:@"DYYYdanmuColor" type:DYYYSettingItemTypeTextField placeholder:@"十六进制"],
        ],
        @[
            [DYYYSettingItem itemWithTitle:@"设置顶栏透明" key:@"DYYYtopbartransparent" type:DYYYSettingItemTypeTextField placeholder:@"0-1小数"],
            [DYYYSettingItem itemWithTitle:@"设置全局透明" key:@"DYYYGlobalTransparency" type:DYYYSettingItemTypeTextField placeholder:@"0-1的小数"],
            [DYYYSettingItem itemWithTitle:@"启用自动播放" key:@"DYYYisEnableAutoPlay" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"设置首页标题" key:@"DYYYIndexTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"设置朋友标题" key:@"DYYYFriendsTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"设置消息标题" key:@"DYYYMsgTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"设置我的标题" key:@"DYYYSelfTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"]
        ],
        @[
            [DYYYSettingItem itemWithTitle:@"隐藏全屏观看" key:@"DYYYisHiddenEntry" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏红点" key:@"DYYYisHiddenBottomDot" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏侧栏红点" key:@"DYYYisHiddenSidebarDot" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏背景" key:@"DYYYisHiddenBottomBg" type:DYYYSettingItemTypeSwitch],
        ]
    ];
}

- (void)setupSectionTitles {
    self.sectionTitles = [@[@"弹幕设置", @"界面设置", @"隐藏设置"] mutableCopy];
}

- (void)setupFooterLabel {
    self.footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    self.footerLabel.text = [NSString stringWithFormat:@"Developer By @huamidev\nVersion: %@ (%@)", @"2.0-1", @"250303"];
    self.footerLabel.textAlignment = NSTextAlignmentCenter;
    self.footerLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.footerLabel.textColor = [UIColor colorWithRed:173/255.0 green:216/255.0 blue:230/255.0 alpha:1.0];
    self.footerLabel.numberOfLines = 2;
    self.footerLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.tableView.tableFooterView = self.footerLabel;
}


- (void)addTitleGradientAnimation {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(__bridge id)[UIColor systemRedColor].CGColor, (__bridge id)[UIColor systemBlueColor].CGColor];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 0);
    gradient.frame = CGRectMake(0, 0, 150, 30);
    
    UIView *titleView = [[UIView alloc] initWithFrame:gradient.frame];
    [titleView.layer addSublayer:gradient];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleView.bounds];
    titleLabel.text = self.title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.textColor = [UIColor clearColor];
    
    gradient.mask = titleLabel.layer;
    self.navigationItem.titleView = titleView;
    
    CABasicAnimation *colorChange = [CABasicAnimation animationWithKeyPath:@"colors"];
    colorChange.toValue = @[(__bridge id)[UIColor systemYellowColor].CGColor, (__bridge id)[UIColor systemGreenColor].CGColor];
    colorChange.duration = 2.0;
    colorChange.autoreverses = YES;
    colorChange.repeatCount = HUGE_VALF;
    
    [gradient addAnimation:colorChange forKey:@"colorChangeAnimation"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.settingSections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"弹幕设置";
        case 1:
            return @"界面设置";
        case 2:
            return @"隐藏设置";
        default:
            return @"";
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 44)];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, headerView.bounds.size.width - 50, 44)];
    titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [headerView addSubview:titleLabel];
    
    UIImageView *arrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x + titleLabel.frame.size.width - 30, 15, 14, 14)];
    arrowImageView.image = [UIImage systemImageNamed:[self.expandedSections containsObject:@(section)] ? @"chevron.down" : @"chevron.right"];
    arrowImageView.tintColor = [UIColor lightGrayColor];
    arrowImageView.tag = 100;
    arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    [headerView addSubview:arrowImageView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = headerView.bounds;
    button.tag = section;
    [button addTarget:self action:@selector(headerTapped:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:button];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.expandedSections containsObject:@(section)] ? self.settingSections[section].count : 0;
}

- (void)toggleSection:(UIButton *)sender {
    NSNumber *section = @(sender.tag);
    if ([self.expandedSections containsObject:section]) {
        [self.expandedSections removeObject:section];
    } else {
        [self.expandedSections addObject:section];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sender.tag] withRowAnimation:UITableViewRowAnimationFade];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SettingCell"];
        cell.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.textLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16].active = YES;
        [cell.textLabel.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor].active = YES;
    }
    
    cell.textLabel.text = item.title;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor colorWithRed:28/255.0 green:28/255.0 blue:29/255.0 alpha:1.0];
    
    if (indexPath.row == [self.settingSections[indexPath.section] count] - 1) {
        UIView *bgView = [[UIView alloc] initWithFrame:cell.bounds];
        bgView.backgroundColor = cell.backgroundColor;
        cell.backgroundView = bgView;
        
        cell.backgroundView.layer.cornerRadius = 10;
        cell.backgroundView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
        cell.backgroundView.clipsToBounds = YES;
    } else {
        cell.backgroundView = nil;
    }
    
    if (item.type == DYYYSettingItemTypeSwitch) {
        UISwitch *switchView = [[UISwitch alloc] init];
        [switchView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:item.key]];
        [switchView addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
        switchView.tag = indexPath.section * 1000 + indexPath.row;
        cell.accessoryView = switchView;
    } else if (item.type == DYYYSettingItemTypeTextField) {
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.placeholder = item.placeholder;
        textField.attributedPlaceholder = [[NSAttributedString alloc]
            initWithString:item.placeholder
            attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
        textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:item.key];
        textField.textAlignment = NSTextAlignmentRight;
        textField.backgroundColor = [UIColor darkGrayColor];
        textField.textColor = [UIColor whiteColor];
        
        [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
        textField.tag = indexPath.section * 1000 + indexPath.row;
        cell.accessoryView = textField;
    } else if (item.type == DYYYSettingItemTypeSpeedPicker) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        UITextField *speedField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 80, 30)];
        speedField.text = [NSString stringWithFormat:@"%.2f", [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"]];
        speedField.textColor = [UIColor whiteColor];
        speedField.borderStyle = UITextBorderStyleNone;
        speedField.backgroundColor = [UIColor clearColor];
        speedField.textAlignment = NSTextAlignmentRight;
        speedField.enabled = NO;
        
        speedField.tag = 999;
        cell.accessoryView = speedField;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat sectionInset = 16;
    cell.contentView.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, UIEdgeInsetsMake(0, sectionInset, 0, sectionInset));
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    if (item.type == DYYYSettingItemTypeSpeedPicker) {
        [self showSpeedPicker];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showSpeedPicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择倍速"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *speeds = @[@0.75, @1.0, @1.25, @1.5, @2.0, @2.5, @3.0];
    for (NSNumber *speed in speeds) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%.2f", speed.floatValue]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
            [[NSUserDefaults standardUserDefaults] setFloat:speed.floatValue forKey:@"DYYYDefaultSpeed"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UITextField *speedField = [cell.accessoryView viewWithTag:999];
            speedField.text = [NSString stringWithFormat:@"%.2f", speed.floatValue];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Actions

- (void)switchToggled:(UISwitch *)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag % 1000 inSection:sender.tag / 1000];
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:item.key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag % 1000 inSection:textField.tag / 1000];
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:item.key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)headerTapped:(UIButton *)sender {
    NSNumber *section = @(sender.tag);
    if ([self.expandedSections containsObject:section]) {
        [self.expandedSections removeObject:section];
    } else {
        [self.expandedSections addObject:section];
    }
    
    UIView *headerView = [self.tableView headerViewForSection:sender.tag];
    UIImageView *arrowImageView = [headerView viewWithTag:100];
    
    [UIView animateWithDuration:0.3 animations:^{
        arrowImageView.image = [UIImage systemImageNamed:[self.expandedSections containsObject:section] ? @"chevron.down" : @"chevron.right"];
    }];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sender.tag] withRowAnimation:UITableViewRowAnimationFade];
}

@end
