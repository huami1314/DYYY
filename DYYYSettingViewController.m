#import "DYYYSettingViewController.h"

@interface DYYYSettingViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSArray<DYYYSettingItem *> *> *settingSections;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) UIToolbar *inputAccessoryToolbar;
@property (nonatomic, weak) UITextField *activeTextField;
@property (nonatomic, strong) NSArray<UITextField *> *allTextFields;

@end

@implementation DYYYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    [self setupAppearance];
    [self setupTableView];
    [self setupSettingItems];
    [self setupFooterLabel];
    [self setupInputAccessoryView];
    [self addTitleGradientAnimation];
}

- (void)setupInputAccessoryView {
    self.inputAccessoryToolbar = [[UIToolbar alloc] init];
    [self.inputAccessoryToolbar sizeToFit];
    
    UIBarButtonItem *previousButton = [[UIBarButtonItem alloc] initWithTitle:@"上一个" style:UIBarButtonItemStylePlain target:self action:@selector(previousInputField)];
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"下一个" style:UIBarButtonItemStylePlain target:self action:@selector(nextInputField)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    self.inputAccessoryToolbar.items = @[previousButton, nextButton, flexSpace, doneButton];
    self.inputAccessoryToolbar.barTintColor = [UIColor darkGrayColor];
    self.inputAccessoryToolbar.tintColor = [UIColor whiteColor];
}

- (void)previousInputField {
    NSInteger currentIndex = [self.allTextFields indexOfObject:self.activeTextField];
    if (currentIndex > 0) {
        [self.allTextFields[currentIndex - 1] becomeFirstResponder];
    }
}

- (void)nextInputField {
    NSInteger currentIndex = [self.allTextFields indexOfObject:self.activeTextField];
    if (currentIndex < self.allTextFields.count - 1) {
        [self.allTextFields[currentIndex + 1] becomeFirstResponder];
    }
}

- (void)doneEditing {
    [self.activeTextField resignFirstResponder];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SettingCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.textLabel.text = item.title;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    
    if (item.type == DYYYSettingItemTypeSwitch) {
        UISwitch *switchView = [[UISwitch alloc] init];
        switchView.onTintColor = [UIColor systemBlueColor];
        [switchView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:item.key]];
        [switchView addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
        switchView.tag = indexPath.section * 1000 + indexPath.row;
        cell.accessoryView = switchView;
    } else if (item.type == DYYYSettingItemTypeTextField) {
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.placeholder = item.placeholder;
        textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:item.key];
        textField.textAlignment = NSTextAlignmentRight;
        textField.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        textField.textColor = [UIColor whiteColor];
        textField.delegate = self;
        textField.inputAccessoryView = self.inputAccessoryToolbar;
        textField.tag = indexPath.section * 1000 + indexPath.row;
        cell.accessoryView = textField;
    } else if (item.type == DYYYSettingItemTypeSpeedPicker) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UITextField *speedField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 80, 30)];
        speedField.text = [NSString stringWithFormat:@"%.2fx", [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"]];
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

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag % 1000 inSection:textField.tag / 1000];
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:item.key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)reloadAllTextFields {
    NSMutableArray *textFields = [NSMutableArray array];
    for (NSArray *section in self.settingSections) {
        for (DYYYSettingItem *item in section) {
            if (item.type == DYYYSettingItemTypeTextField) {
                for (UITableViewCell *cell in self.tableView.visibleCells) {
                    UITextField *textField = (UITextField *)cell.accessoryView;
                    if ([textField isKindOfClass:[UITextField class]]) {
                        [textFields addObject:textField];
                    }
                }
            }
        }
    }
    self.allTextFields = [textFields copy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadAllTextFields];
}

@end