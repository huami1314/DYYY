#import "DYYYSettingsHelper.h"
#import "DYYYUtils.h"
#import <UIKit/UIKit.h>

#import "DYYYAboutDialogView.h"
#import "DYYYCustomInputView.h"

@implementation DYYYSettingsHelper

// 获取用户默认设置
+ (bool)getUserDefaults:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

// 设置用户默认设置
+ (void)setUserDefaults:(id)object forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 显示自定义关于弹窗
+ (void)showAboutDialog:(NSString *)title message:(NSString *)message onConfirm:(void (^)(void))onConfirm {
    DYYYAboutDialogView *aboutDialog = [[DYYYAboutDialogView alloc] initWithTitle:title message:message];
    aboutDialog.onConfirm = onConfirm;
    [aboutDialog show];
}

// 显示文本输入弹窗（完整版本）
+ (void)showTextInputAlert:(NSString *)title defaultText:(NSString *)defaultText placeholder:(NSString *)placeholder onConfirm:(void (^)(NSString *text))onConfirm onCancel:(void (^)(void))onCancel {
    DYYYCustomInputView *inputView = [[DYYYCustomInputView alloc] initWithTitle:title defaultText:defaultText placeholder:placeholder];
    inputView.onConfirm = onConfirm;
    inputView.onCancel = onCancel;
    [inputView show];
}

// 显示文本输入弹窗（无placeholder版本）
+ (void)showTextInputAlert:(NSString *)title defaultText:(NSString *)defaultText onConfirm:(void (^)(NSString *text))onConfirm onCancel:(void (^)(void))onCancel {
    [self showTextInputAlert:title defaultText:defaultText placeholder:nil onConfirm:onConfirm onCancel:onCancel];
}

// 显示文本输入弹窗（简化版本）
+ (void)showTextInputAlert:(NSString *)title onConfirm:(void (^)(NSString *text))onConfirm onCancel:(void (^)(void))onCancel {
    [self showTextInputAlert:title defaultText:nil placeholder:nil onConfirm:onConfirm onCancel:onCancel];
}

+ (NSDictionary *)settingsDependencyConfig {
    static NSDictionary *config = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
      config = @{
          // ===== 依赖关系配置 =====
          @"dependencies" : @{
              // 普通依赖：当源设置开启时，目标设置项可用
              @"DYYYEnableDanmuColor" : @[ @"DYYYdanmuColor" ],
              @"DYYYisEnableArea" : @[ @"DYYYLabelColor" ],
              @"DYYYisShowScheduleDisplay" : @[ @"DYYYScheduleStyle", @"DYYYProgressLabelColor", @"DYYYTimelineVerticalPosition" ],
              @"DYYYEnableNotificationTransparency" : @[ @"DYYYNotificationCornerRadius" ],
              @"DYYYEnableFloatSpeedButton" : @[ @"DYYYAutoRestoreSpeed", @"DYYYSpeedButtonShowX", @"DYYYSpeedButtonSize", @"DYYYSpeedSettings" ],
              @"DYYYEnableFloatClearButton" : @[ @"DYYYClearButtonIcon", @"DYYYEnableFloatClearButtonSize", @"DYYYEnabshijianjindu", @"DYYYHideTimeProgress", @"DYYYHideDanmaku", @"DYYYHideSlider", @"DYYYHideTabBar" ],
          },

          // ===== 条件依赖配置 =====
          // 一些设置项依赖于多个其他设置项的复杂条件
          @"conditionalDependencies" : @{
              @"DYYYCommentBlurTransparent" : @{@"condition" : @"OR", @"settings" : @[ @"DYYYisEnableCommentBlur", @"DYYYEnableNotificationTransparency" ]},
          },

          // ===== 冲突配置 =====
          // 当源设置项开启时，会自动关闭目标设置项
          @"conflicts" : @{
              @"DYYYEnableDoubleOpenComment" : @[ @"DYYYEnableDoubleOpenAlertController" ],
              @"DYYYEnableDoubleOpenAlertController" : @[ @"DYYYEnableDoubleOpenComment" ],
              @"DYYYABTestBlockEnabled" : @[ @"DYYYABTestPatchEnabled" ],
              @"DYYYABTestPatchEnabled" : @[ @"DYYYABTestBlockEnabled" ],
              @"DYYYEnabshijianjindu" : @[ @"DYYYHideTimeProgress" ],
              @"DYYYHideTimeProgress" : @[ @"DYYYEnabshijianjindu" ],
              @"DYYYHideLOTAnimationView" : @[ @"DYYYHideFollowPromptView" ],
              @"DYYYHideFollowPromptView" : @[ @"DYYYHideLOTAnimationView" ],
              @"DYYYisEnableModern" : @[ @"DYYYisEnableModernLight" ],
              @"DYYYisEnableModernLight" : @[ @"DYYYisEnableModern" ]
          },

          // ===== 互斥激活配置 =====
          // 当源设置项关闭时，目标设置项才能激活
          @"mutualExclusive" : @{
              @"DYYYEnableDoubleOpenComment" : @[ @"DYYYEnableDoubleOpenAlertController" ],
              @"DYYYEnableDoubleOpenAlertController" : @[ @"DYYYEnableDoubleOpenComment" ],
              @"DYYYABTestBlockEnabled" : @[ @"DYYYABTestPatchEnabled" ],
              @"DYYYABTestPatchEnabled" : @[ @"DYYYABTestBlockEnabled" ],
              @"DYYYEnabshijianjindu" : @[ @"DYYYHideTimeProgress" ],
              @"DYYYHideTimeProgress" : @[ @"DYYYEnabshijianjindu" ],
              @"DYYYHideLOTAnimationView" : @[ @"DYYYHideFollowPromptView" ],
              @"DYYYHideFollowPromptView" : @[ @"DYYYHideLOTAnimationView" ]
          },

          // ===== 值依赖配置 =====
          // 基于字符串值的依赖关系
          @"valueDependencies" :
              @{@"DYYYInterfaceDownload" : @{@"valueType" : @"string", @"condition" : @"isNotEmpty", @"dependents" : @[ @"DYYYShowAllVideoQuality", @"DYYYDoubleInterfaceDownload" ]}},
      };
    });

    return config;
}

+ (void)applyDependencyRulesForItem:(AWESettingItemModel *)item {
    NSDictionary *dependencies = [self settingsDependencyConfig][@"dependencies"];
    NSDictionary *conditionalDependencies = [self settingsDependencyConfig][@"conditionalDependencies"];
    NSDictionary *mutualExclusive = [self settingsDependencyConfig][@"mutualExclusive"];
    NSDictionary *valueDependencies = [self settingsDependencyConfig][@"valueDependencies"];

    for (NSString *sourceKey in dependencies) {
        NSArray *dependentItems = dependencies[sourceKey];
        if ([dependentItems containsObject:item.identifier]) {
            BOOL sourceValue = [self getUserDefaults:sourceKey];
            item.isEnable = sourceValue;
            return;
        }
    }

    for (NSString *targetKey in conditionalDependencies) {
        NSDictionary *conditionConfig = conditionalDependencies[targetKey];
        if ([targetKey isEqualToString:item.identifier]) {
            NSString *conditionType = conditionConfig[@"condition"];
            NSArray *settingList = conditionConfig[@"settings"];

            if ([conditionType isEqualToString:@"OR"]) {
                BOOL shouldEnable = NO;
                for (NSString *settingKey in settingList) {
                    if ([self getUserDefaults:settingKey]) {
                        shouldEnable = YES;
                        break;
                    }
                }
                item.isEnable = shouldEnable;
                return;
            } else if ([conditionType isEqualToString:@"AND"]) {
                BOOL shouldEnable = YES;
                for (NSString *settingKey in settingList) {
                    if (![self getUserDefaults:settingKey]) {
                        shouldEnable = NO;
                        break;
                    }
                }
                item.isEnable = shouldEnable;
                return;
            }
        }
    }

    for (NSString *sourceKey in mutualExclusive) {
        NSArray *exclusiveItems = mutualExclusive[sourceKey];
        if ([exclusiveItems containsObject:item.identifier]) {
            BOOL sourceValue = [self getUserDefaults:sourceKey];
            item.isEnable = !sourceValue; // 当源设置关闭时，目标设置才能激活
            return;
        }
    }

    for (NSString *sourceKey in valueDependencies) {
        NSDictionary *valueConfig = valueDependencies[sourceKey];
        NSArray *dependentItems = valueConfig[@"dependents"];

        if ([dependentItems containsObject:item.identifier]) {
            NSString *valueType = valueConfig[@"valueType"];
            NSString *condition = valueConfig[@"condition"];

            if ([valueType isEqualToString:@"string"] && [condition isEqualToString:@"isNotEmpty"]) {
                NSString *sourceValue = [[NSUserDefaults standardUserDefaults] objectForKey:sourceKey];
                item.isEnable = (sourceValue != nil && sourceValue.length > 0);
                return;
            }
        }
    }
}

+ (void)handleConflictsAndDependenciesForSetting:(NSString *)identifier isEnabled:(BOOL)isEnabled {
    NSDictionary *conflicts = [self settingsDependencyConfig][@"conflicts"];
    NSDictionary *dependencies = [self settingsDependencyConfig][@"dependencies"];
    if (isEnabled) {
        NSArray *conflictingItems = conflicts[identifier];
        if (conflictingItems) {
            for (NSString *conflictItem in conflictingItems) {
                // 更新NSUserDefaults
                [self setUserDefaults:@(NO) forKey:conflictItem];

                // 立即更新互斥项的UI状态
                [self updateConflictingItemUIState:conflictItem withValue:NO];
            }
        }
    }

    [self updateDependentItemsForSetting:identifier value:@(isEnabled)];

    [self refreshTableView];
}
+ (void)updateConflictingItemUIState:(NSString *)identifier withValue:(BOOL)value {
    UIViewController *topVC = topView();
    AWESettingBaseViewController *settingsVC = nil;

    // 查找当前视图控制器
    if ([topVC isKindOfClass:NSClassFromString(@"AWESettingBaseViewController")]) {
        settingsVC = (AWESettingBaseViewController *)topVC;
    } else {
        UIView *firstLevelView = [topVC.view.subviews firstObject];
        UIView *secondLevelView = firstLevelView ? [firstLevelView.subviews firstObject] : nil;
        UIView *thirdLevelView = secondLevelView ? [secondLevelView.subviews firstObject] : nil;

        UIResponder *responder = thirdLevelView;
        while (responder) {
            if ([responder isKindOfClass:NSClassFromString(@"AWESettingBaseViewController")]) {
                settingsVC = (AWESettingBaseViewController *)responder;
                break;
            }
            responder = [responder nextResponder];
        }
    }

    // 更新设置项UI
    if (settingsVC) {
        AWESettingsViewModel *viewModel = (AWESettingsViewModel *)[settingsVC viewModel];
        if (viewModel && [viewModel respondsToSelector:@selector(sectionDataArray)]) {
            NSArray *sectionDataArray = [viewModel sectionDataArray];
            for (AWESettingSectionModel *section in sectionDataArray) {
                if ([section respondsToSelector:@selector(itemArray)]) {
                    NSArray *itemArray = section.itemArray;
                    for (id itemObj in itemArray) {
                        if ([itemObj isKindOfClass:NSClassFromString(@"AWESettingItemModel")]) {
                            AWESettingItemModel *item = (AWESettingItemModel *)itemObj;
                            if ([item.identifier isEqualToString:identifier]) {
                                item.isSwitchOn = value;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}

+ (void)updateDependentItemsForSetting:(NSString *)identifier value:(id)value {
    NSDictionary *dependencies = [self settingsDependencyConfig][@"dependencies"];
    NSDictionary *conditionalDependencies = [self settingsDependencyConfig][@"conditionalDependencies"];
    NSDictionary *mutualExclusive = [self settingsDependencyConfig][@"mutualExclusive"];
    NSDictionary *valueDependencies = [self settingsDependencyConfig][@"valueDependencies"];
    NSDictionary *conflicts = [self settingsDependencyConfig][@"conflicts"];

    UIViewController *topVC = topView();
    AWESettingBaseViewController *settingsVC = nil;

    UIView *firstLevelView = [topVC.view.subviews firstObject];
    UIView *secondLevelView = [firstLevelView.subviews firstObject];
    UIView *thirdLevelView = [secondLevelView.subviews firstObject];

    UIResponder *responder = thirdLevelView;
    while (responder) {
        if ([responder isKindOfClass:NSClassFromString(@"AWESettingBaseViewController")]) {
            settingsVC = (AWESettingBaseViewController *)responder;
            break;
        }
        responder = [responder nextResponder];
    }

    AWESettingsViewModel *viewModel = (AWESettingsViewModel *)[settingsVC viewModel];
    if (!viewModel || ![viewModel respondsToSelector:@selector(sectionDataArray)])
        return;

    NSArray *sectionDataArray = [viewModel sectionDataArray];

    NSMutableSet *itemsToUpdate = [NSMutableSet set];

    NSArray *directDependents = dependencies[identifier];
    if (directDependents) {
        [itemsToUpdate addObjectsFromArray:directDependents];
    }

    NSArray *exclusiveItems = mutualExclusive[identifier];
    if (exclusiveItems) {
        [itemsToUpdate addObjectsFromArray:exclusiveItems];
    }

    NSArray *conflictItems = conflicts[identifier];
    if (conflictItems) {
        [itemsToUpdate addObjectsFromArray:conflictItems];
    }

    for (NSString *targetItem in conditionalDependencies) {
        NSDictionary *conditionInfo = conditionalDependencies[targetItem];
        NSArray *settingsList = conditionInfo[@"settings"];
        if ([settingsList containsObject:identifier]) {
            [itemsToUpdate addObject:targetItem];
        }
    }

    NSDictionary *valueDepInfo = valueDependencies[identifier];
    if (valueDepInfo) {
        NSArray *dependentItems = valueDepInfo[@"dependents"];
        if (dependentItems) {
            [itemsToUpdate addObjectsFromArray:dependentItems];
        }
    }

    for (AWESettingSectionModel *section in sectionDataArray) {
        if (![section respondsToSelector:@selector(itemArray)])
            continue;

        NSArray *itemArray = section.itemArray;
        for (id itemObj in itemArray) {
            if (![itemObj isKindOfClass:NSClassFromString(@"AWESettingItemModel")])
                continue;

            AWESettingItemModel *item = (AWESettingItemModel *)itemObj;
            if ([itemsToUpdate containsObject:item.identifier]) {
                [self applyDependencyRulesForItem:item];
            }
        }
    }
}

+ (void)refreshTableView {
    UIViewController *topVC = topView();
    AWESettingBaseViewController *settingsVC = nil;
    UITableView *tableView = nil;

    UIView *firstLevelView = [topVC.view.subviews firstObject];
    UIView *secondLevelView = [firstLevelView.subviews firstObject];
    UIView *thirdLevelView = [secondLevelView.subviews firstObject];

    UIResponder *responder = thirdLevelView;
    while (responder) {
        if ([responder isKindOfClass:NSClassFromString(@"AWESettingBaseViewController")]) {
            settingsVC = (AWESettingBaseViewController *)responder;
            break;
        }
        responder = [responder nextResponder];
    }

    if (settingsVC) {
        for (UIView *subview in settingsVC.view.subviews) {
            if ([subview isKindOfClass:[UITableView class]]) {
                tableView = (UITableView *)subview;
                break;
            }
        }

        if (tableView) {
            [tableView reloadData];
        }
    }
}

+ (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict {
    return [self createSettingItem:dict cellTapHandlers:nil];
}

+ (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict cellTapHandlers:(NSMutableDictionary *)cellTapHandlers {
    AWESettingItemModel *item = [[NSClassFromString(@"AWESettingItemModel") alloc] init];
    item.identifier = dict[@"identifier"];
    item.title = dict[@"title"];

    // 获取保存的实际值
    NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
    NSString *placeholder = dict[@"detail"];
    item.detail = savedDetail ?: @"";

    item.type = 1000;
    item.svgIconImageName = dict[@"imageName"];
    item.cellType = [dict[@"cellType"] integerValue];
    item.colorStyle = 0;
    item.isEnable = YES;
    item.isSwitchOn = [self getUserDefaults:item.identifier];

    [self applyDependencyRulesForItem:item];
    if (item.cellType == 26 && cellTapHandlers != nil) {
        cellTapHandlers[item.identifier] = ^{
          if (!item.isEnable)
              return;

          [self showTextInputAlert:item.title 
                       defaultText:item.detail 
                       placeholder:placeholder
                        onConfirm:^(NSString *text) {
              [self setUserDefaults:text forKey:item.identifier];
              item.detail = text;

              if ([item.identifier isEqualToString:@"DYYYInterfaceDownload"]) {
                  [self updateDependentItemsForSetting:@"DYYYInterfaceDownload" value:text];
              }

              [self refreshTableView];
          } onCancel:nil];
        };
        item.cellTappedBlock = cellTapHandlers[item.identifier];
    } else if (item.cellType == 6) {
        __weak AWESettingItemModel *weakItem = item;
        item.switchChangedBlock = ^{
          __strong AWESettingItemModel *strongItem = weakItem;
          if (strongItem) {
              if (!strongItem.isEnable)
                  return;
              BOOL isSwitchOn = !strongItem.isSwitchOn;
              strongItem.isSwitchOn = isSwitchOn;
              [self setUserDefaults:@(isSwitchOn) forKey:strongItem.identifier];

              if ([strongItem.identifier isEqualToString:@"DYYYForceDownloadEmotion"] && isSwitchOn) {
                  [self showAboutDialog:@"防蠢提示" message:@"这里指的是长按整条评论而非表情图片\n" onConfirm:nil];
              }
              [self handleConflictsAndDependenciesForSetting:strongItem.identifier isEnabled:isSwitchOn];
          }
        };
    }

    return item;
}

@end
