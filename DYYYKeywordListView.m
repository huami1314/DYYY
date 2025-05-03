#import "DYYYKeywordListView.h"
#import "DYYYCustomInputView.h"
#import "DYYYManager.h"

@interface DYYYKeywordListView ()

@property(nonatomic, strong) UIVisualEffectView *blurView;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UITableView *keywordsTableView;
@property(nonatomic, strong) UIButton *addButton;
@property(nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, strong) UIButton *confirmButton;
@property(nonatomic, assign) CGRect originalFrame;
@property(nonatomic, strong) NSMutableArray *keywords;

@end

@implementation DYYYKeywordListView

- (instancetype)initWithTitle:(NSString *)title keywords:(NSArray *)keywords {
  if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
    self.keywords = [NSMutableArray arrayWithArray:keywords ?: @[]];
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];

    BOOL isDarkMode = [DYYYManager isDarkMode];

    // 创建模糊效果背景
    self.blurView = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect
                           effectWithStyle:isDarkMode
                                               ? UIBlurEffectStyleDark
                                               : UIBlurEffectStyleLight]];
    self.blurView.frame = self.bounds;
    self.blurView.alpha = isDarkMode ? 0.3 : 0.2;
    [self addSubview:self.blurView];

    // 创建内容视图 - 根据模式设置背景色
    self.contentView =
        [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 350)];
    CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
    self.contentView.center =
        CGPointMake(self.frame.size.width / 2, screenHeight / 3);
    self.originalFrame = self.contentView.frame;
    self.contentView.backgroundColor = isDarkMode ? 
        [UIColor colorWithRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1.0] :
        [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.alpha = 0;
    self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [self addSubview:self.contentView];

    // 主标题 - 根据模式设置文本颜色
    self.titleLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 24)];
    self.titleLabel.text = title ?: @"过滤过滤项";
    self.titleLabel.textColor = isDarkMode ? 
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] : 
        [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:18
                                             weight:UIFontWeightMedium];
    [self.contentView addSubview:self.titleLabel];

    // 表格视图 - 根据模式设置背景色和分隔线颜色
    self.keywordsTableView =
        [[UITableView alloc] initWithFrame:CGRectMake(20, 54, 260, 260)];
    self.keywordsTableView.delegate = self;
    self.keywordsTableView.dataSource = self;
    self.keywordsTableView.backgroundColor = isDarkMode ?
        [UIColor colorWithRed:45/255.0 green:45/255.0 blue:45/255.0 alpha:1.0] :
        [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0];
    self.keywordsTableView.layer.cornerRadius = 8;
    self.keywordsTableView.tableFooterView = [UIView new]; // 隐藏空行分隔线
    self.keywordsTableView.separatorStyle =
        UITableViewCellSeparatorStyleSingleLine;
    self.keywordsTableView.separatorInset = UIEdgeInsetsMake(0, 15, 0, 15);
    self.keywordsTableView.separatorColor = isDarkMode ?
        [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] :
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    [self.contentView addSubview:self.keywordsTableView];

    // 添加按钮 - 根据模式设置背景色
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addButton.frame = CGRectMake(20, 324, 260, 40);
    self.addButton.backgroundColor = isDarkMode ?
        [UIColor colorWithRed:45/255.0 green:45/255.0 blue:45/255.0 alpha:1.0] :
        [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0];
    self.addButton.layer.cornerRadius = 8;
    [self.addButton setTitle:@"+ 添加过滤项" forState:UIControlStateNormal];
    [self.addButton setTitleColor:[UIColor colorWithRed:11/255.0
                                                  green:223/255.0
                                                   blue:154/255.0
                                                  alpha:1.0]
                         forState:UIControlStateNormal]; // 强调色保持不变 #0BDF9A
    [self.addButton addTarget:self
                       action:@selector(addKeywordTapped)
             forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.addButton];

    // 添加内容和按钮之间的分割线 - 根据模式设置颜色
    UIView *contentButtonSeparator =
        [[UIView alloc] initWithFrame:CGRectMake(0, 374, 300, 0.5)];
    contentButtonSeparator.backgroundColor = isDarkMode ?
        [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] :
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    [self.contentView addSubview:contentButtonSeparator];

    // 按钮容器
    UIView *buttonContainer = [[UIView alloc]
        initWithFrame:CGRectMake(0, contentButtonSeparator.frame.origin.y + 0.5,
                                 300, 55.5)];
    [self.contentView addSubview:buttonContainer];

    // 取消按钮 - 根据模式设置文本颜色
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.frame = CGRectMake(0, 0, 149.5, 55.5);
    self.cancelButton.backgroundColor = [UIColor clearColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:isDarkMode ?
        [UIColor colorWithRed:160/255.0 green:160/255.0 blue:165/255.0 alpha:1.0] :
        [UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0]
                            forState:UIControlStateNormal];
    [self.cancelButton addTarget:self
                          action:@selector(cancelTapped)
                forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:self.cancelButton];

    // 按钮之间的分割线 - 根据模式设置颜色
    UIView *buttonSeparator =
        [[UIView alloc] initWithFrame:CGRectMake(149.5, 0, 0.5, 55.5)];
    buttonSeparator.backgroundColor = isDarkMode ?
        [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] :
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    [buttonContainer addSubview:buttonSeparator];

    // 确认按钮 - 根据模式设置文本颜色
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.confirmButton.frame = CGRectMake(150, 0, 150, 55.5);
    self.confirmButton.backgroundColor = [UIColor clearColor];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:isDarkMode ?
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] :
        [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0]
                             forState:UIControlStateNormal];
    [self.confirmButton addTarget:self
                           action:@selector(confirmTapped)
                 forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:self.confirmButton];

    // 更新内容视图高度
    CGRect frame = self.contentView.frame;
    frame.size.height =
        buttonContainer.frame.origin.y + buttonContainer.frame.size.height - 85;
    self.contentView.frame = frame;
    self.contentView.center =
        CGPointMake(self.frame.size.width / 2, screenHeight / 2);
    self.originalFrame = self.contentView.frame;
  }
  return self;
}

- (void)show {
  UIWindow *window = [UIApplication sharedApplication].keyWindow;
  [window addSubview:self];

  [UIView animateWithDuration:0.12
                   animations:^{
                     self.contentView.alpha = 1.0;
                     self.contentView.transform = CGAffineTransformIdentity;
                   }];
}

- (void)dismiss {
  [UIView animateWithDuration:0.1
      animations:^{
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.blurView.alpha = 0;
      }
      completion:^(BOOL finished) {
        [self removeFromSuperview];
      }];
}

- (void)addKeywordTapped {
  DYYYCustomInputView *inputView = [[DYYYCustomInputView alloc]
      initWithTitle:@"添加过滤项"
        defaultText:nil
        placeholder:@"请输入过滤项，多个用逗号分隔"];

  __weak typeof(self) weakSelf = self;
  inputView.onConfirm = ^(NSString *text) {
    if (text.length > 0) {
      // 使用逗号分隔多个过滤项
      NSArray *newKeywords = [text componentsSeparatedByString:@","];
      for (NSString *keyword in newKeywords) {
        NSString *trimmedKeyword =
            [keyword stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedKeyword.length > 0) {
          [weakSelf.keywords addObject:trimmedKeyword];
        }
      }
      [weakSelf.keywordsTableView reloadData];
    }
  };

  [inputView show];
}

- (void)confirmTapped {
  if (self.onConfirm) {
    self.onConfirm([self.keywords copy]);
  }
  [self dismiss];
}

- (void)cancelTapped {
  if (self.onCancel) {
    self.onCancel();
  }
  [self dismiss];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return self.keywords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"KeywordCell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  
  BOOL isDarkMode = [DYYYManager isDarkMode];

  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellIdentifier];

    // 删除按钮
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteButton.frame = CGRectMake(0, 0, 30, 30);

    // 使用无填充的圆形 X 图标
    UIImage *xImage = [[UIImage systemImageNamed:@"xmark"]
        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [deleteButton setImage:xImage forState:UIControlStateNormal];
    
    // 设置删除按钮颜色
    [deleteButton setTintColor:isDarkMode ?
        [UIColor colorWithRed:160/255.0 green:160/255.0 blue:165/255.0 alpha:1.0] :
        [UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0]];

    // 设置灰色
    cell.accessoryView = deleteButton;
    cell.textLabel.textColor = [UIColor colorWithRed:124 / 255.0
                                             green:124 / 255.0
                                              blue:130 / 255.0
                                             alpha:1.0]; // #7c7c82

    // 添加按压效果
    deleteButton.adjustsImageWhenHighlighted = YES;

    [deleteButton addTarget:self
                     action:@selector(deleteKeyword:)
           forControlEvents:UIControlEventTouchUpInside];

    cell.accessoryView = deleteButton;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = isDarkMode ?
        [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] :
        [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0];
  }

  // 配置单元格
  cell.textLabel.text = self.keywords[indexPath.row];
  cell.accessoryView.tag = indexPath.row; // 用于识别删除哪个过滤项
  
  // 设置背景色透明，以便表格背景色可见
  cell.backgroundColor = [UIColor clearColor];

  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 44.0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  NSString *currentKeyword = self.keywords[indexPath.row];
  DYYYCustomInputView *inputView =
      [[DYYYCustomInputView alloc] initWithTitle:@"编辑过滤项"
                                     defaultText:currentKeyword
                                     placeholder:@"请输入过滤项"];

  __weak typeof(self) weakSelf = self;
  inputView.onConfirm = ^(NSString *text) {
    if (text.length > 0) {
      weakSelf.keywords[indexPath.row] = text;
      [weakSelf.keywordsTableView
          reloadRowsAtIndexPaths:@[ indexPath ]
                withRowAnimation:UITableViewRowAnimationNone];
    }
  };

  [inputView show];
}

- (void)deleteKeyword:(UIButton *)sender {
  NSInteger index = sender.tag;
  if (index < self.keywords.count) {
    [self.keywords removeObjectAtIndex:index];
    [self.keywordsTableView reloadData];
  }
}

@end