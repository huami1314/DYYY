#import "DYYYSettingViewController.h"

@interface DYYYSettingViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISwitch *hidePlusSwitch;
@property (nonatomic, strong) UISwitch *hideEntryView;
@property (nonatomic, strong) UISwitch *enableDanmuColorSwitch;
@property (nonatomic, strong) UITextField *danmuColorField;
@property (nonatomic, strong) UITextField *topBarTransparentField;
@property (nonatomic, strong) UITextField *globalTransparencyField;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) UISwitch *hideBottomDotSwitch;
@property (nonatomic, strong) UISwitch *hideSidebarDotSwitch;

@end

@implementation DYYYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"设置";
    [self setupAppearance];
    [self setupTableView];
    [self setupFooterLabel];
    [self addTitleGradientAnimation];
}

- (void)setupAppearance {
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor labelColor], NSFontAttributeName: [UIFont systemFontOfSize:20 weight:UIFontWeightMedium]};
}

- (void)setupTableView {
    CGFloat tableHeight = self.view.bounds.size.height - 100;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, tableHeight) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 20);
    self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0);
    [self.view addSubview:self.tableView];
}

- (void)setupFooterLabel {
    self.footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    self.footerLabel.text = @"Developer By @huamidev";
    self.footerLabel.textAlignment = NSTextAlignmentCenter;
    self.footerLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.footerLabel.textColor = [UIColor secondaryLabelColor];
    self.footerLabel.alpha = 0;
    
    [UIView animateWithDuration:1.0 delay:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.footerLabel.alpha = 1.0;
    } completion:nil];
    
    self.tableView.tableFooterView = self.footerLabel;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"] ? 8 : 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"SettingCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.backgroundColor = [UIColor secondarySystemBackgroundColor];
        cell.textLabel.textColor = [UIColor labelColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    switch (indexPath.row) {
        case 0:
            [self configureTopBarTransparentFieldCell:cell];
            break;
        case 1:
            [self configureGlobalTransparencyFieldCell:cell];
            break;
        case 2:
            [self configureHideEntryViewCell:cell];
            break;
        case 3:
            [self configureHidePlusSwitchCell:cell];
            break;
        case 4:
            [self configureHideBottomDotSwitchCell:cell];
            break;
        case 5:
            [self configureHideSidebarDotSwitchCell:cell];
            break;
        case 6:
            [self configureEnableDanmuColorSwitchCell:cell];
            break;
        case 7:
            [self configureDanmuColorFieldCell:cell];
            break;
        default:
            break;
    }
    
    return cell;
}

- (void)configureTopBarTransparentFieldCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"设置顶栏透明";
    self.topBarTransparentField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    self.topBarTransparentField.borderStyle = UITextBorderStyleRoundedRect;
    self.topBarTransparentField.placeholder = @"输入0-1的小数";
    self.topBarTransparentField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYtopbartransparent"] ?: @"1";
    self.topBarTransparentField.textAlignment = NSTextAlignmentRight;
    [self.topBarTransparentField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
    cell.accessoryView = self.topBarTransparentField;
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

- (void)configureGlobalTransparencyFieldCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"设置全局透明";
    self.globalTransparencyField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    self.globalTransparencyField.borderStyle = UITextBorderStyleRoundedRect;
    self.globalTransparencyField.placeholder = @"输入0-1的小数";
    self.globalTransparencyField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYGlobalTransparency"] ?: @"1";
    self.globalTransparencyField.textAlignment = NSTextAlignmentRight;
    [self.globalTransparencyField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
    cell.accessoryView = self.globalTransparencyField;
}

- (void)configureHidePlusSwitchCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"隐藏底栏加号";
    self.hidePlusSwitch = [[UISwitch alloc] init];
    [self.hidePlusSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenJia"]];
    [self.hidePlusSwitch addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = self.hidePlusSwitch;
}

- (void)configureHideEntryViewCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"隐藏全屏观看";
    self.hideEntryView = [[UISwitch alloc] init];
    [self.hideEntryView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenEntry"]];
    [self.hideEntryView addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = self.hideEntryView;
}

- (void)configureEnableDanmuColorSwitchCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"开启弹幕改色";
    self.enableDanmuColorSwitch = [[UISwitch alloc] init];
    [self.enableDanmuColorSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableDanmuColor"]];
    [self.enableDanmuColorSwitch addTarget:self action:@selector(enableDanmuSwitchToggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = self.enableDanmuColorSwitch;
}

- (void)configureDanmuColorFieldCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"修改弹幕颜色";
    self.danmuColorField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    self.danmuColorField.borderStyle = UITextBorderStyleRoundedRect;
    self.danmuColorField.placeholder = @"十六进制颜色";
    self.danmuColorField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYdanmuColor"] ?: @"#FFFFFF";
    self.danmuColorField.textAlignment = NSTextAlignmentRight;
    [self.danmuColorField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
    cell.accessoryView = self.danmuColorField;
}

- (void)configureHideBottomDotSwitchCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"隐藏底栏红点";
    self.hideBottomDotSwitch = [[UISwitch alloc] init];
    [self.hideBottomDotSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenBottomDot"]];
    [self.hideBottomDotSwitch addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = self.hideBottomDotSwitch;
}

- (void)configureHideSidebarDotSwitchCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"隐藏侧栏红点";
    self.hideSidebarDotSwitch = [[UISwitch alloc] init];
    [self.hideSidebarDotSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenSidebarDot"]];
    [self.hideSidebarDotSwitch addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = self.hideSidebarDotSwitch;
}

- (void)switchToggled:(UISwitch *)sender {
    if (sender == self.hidePlusSwitch) {
        [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"DYYYisHiddenJia"];
    } else if (sender == self.hideEntryView) {
        [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"DYYYisHiddenEntry"];
    } else if (sender == self.hideBottomDotSwitch) {
        [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"DYYYisHiddenBottomDot"];
    } else if (sender == self.hideSidebarDotSwitch) {
        [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"DYYYisHiddenSidebarDot"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)enableDanmuSwitchToggled:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"DYYYEnableDanmuColor"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadData];
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSString *key;
    if (textField == self.danmuColorField) {
        key = @"DYYYdanmuColor";
    } else if (textField == self.topBarTransparentField) {
        key = @"DYYYtopbartransparent";
    } else if (textField == self.globalTransparencyField) {
        key = @"DYYYGlobalTransparency";
    }
    [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
