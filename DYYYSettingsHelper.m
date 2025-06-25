#import "DYYYSettingsHelper.h"
#import "DYYYUtils.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "DYYYImagePickerDelegate.h"

#import "DYYYAboutDialogView.h"
#import "DYYYCustomInputView.h"
#import "DYYYIconOptionsDialogView.h"

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
              @"DYYYisEnableCommentBlur" : @[ @"DYYYisEnableCommentBarTransparent" ],
              @"DYYYisEnableArea" : @[ @"DYYYGeonamesUsername", @"DYYYLabelColor", @"DYYYEnabsuijiyanse" ],
              @"DYYYisShowScheduleDisplay" : @[ @"DYYYScheduleStyle", @"DYYYProgressLabelColor", @"DYYYTimelineVerticalPosition" ],
              @"DYYYEnableNotificationTransparency" : @[ @"DYYYNotificationCornerRadius" ],
              @"DYYYEnableFloatSpeedButton" : @[ @"DYYYAutoRestoreSpeed", @"DYYYSpeedButtonShowX", @"DYYYSpeedButtonSize", @"DYYYSpeedSettings" ],
              @"DYYYEnableFloatClearButton" : @[ @"DYYYClearButtonIcon", @"DYYYEnableFloatClearButtonSize", @"DYYYEnabshijianjindu", @"DYYYHideTimeProgress", @"DYYYHideDanmaku", @"DYYYHideSlider", @"DYYYHideTabBar", @"DYYYHideSpeed", @"DYYYHideChapter" ],
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
              @"DYYYEnabshijianjindu" : @[ @"DYYYHideTimeProgress" ],
              @"DYYYHideTimeProgress" : @[ @"DYYYEnabshijianjindu" ],
              @"DYYYHideLOTAnimationView" : @[ @"DYYYHideFollowPromptView" ],
              @"DYYYHideFollowPromptView" : @[ @"DYYYHideLOTAnimationView" ],
              @"DYYYisEnableModern" : @[ @"DYYYisEnableModernLight" ],
              @"DYYYisEnableModernLight" : @[ @"DYYYisEnableModern" ],
              @"DYYYLabelColor" : @[ @"DYYYEnabsuijiyanse" ],
              @"DYYYEnabsuijiyanse" : @[ @"DYYYLabelColor" ]
          },

          // ===== 互斥激活配置 =====
          // 当源设置项关闭时，目标设置项才能激活
          @"mutualExclusive" : @{
              @"DYYYEnableDoubleOpenComment" : @[ @"DYYYEnableDoubleOpenAlertController" ],
              @"DYYYEnableDoubleOpenAlertController" : @[ @"DYYYEnableDoubleOpenComment" ],
              @"DYYYEnabshijianjindu" : @[ @"DYYYHideTimeProgress" ],
              @"DYYYHideTimeProgress" : @[ @"DYYYEnabshijianjindu" ],
              @"DYYYHideLOTAnimationView" : @[ @"DYYYHideFollowPromptView" ],
              @"DYYYHideFollowPromptView" : @[ @"DYYYHideLOTAnimationView" ],
              @"DYYYLabelColor" : @[ @"DYYYEnabsuijiyanse" ],
              @"DYYYEnabsuijiyanse" : @[ @"DYYYLabelColor" ]
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
            item.isEnable = !sourceValue;
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
                                item.isEnable = value;
                                [item refreshCell];
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
                [item refreshCell];
            }
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
    item.subTitle = dict[@"subTitle"];

    NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
    NSString *placeholder = dict[@"detail"];
    item.detail = savedDetail ?: @"";

    item.svgIconImageName = dict[@"imageName"];
    item.cellType = [dict[@"cellType"] integerValue];
    item.colorStyle = 0;
    item.isEnable = YES;
    item.isSwitchOn = [self getUserDefaults:item.identifier];

    [self applyDependencyRulesForItem:item];
    if ((item.cellType == 20 || item.cellType == 26) && cellTapHandlers != nil) {
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

              [item refreshCell];
          } onCancel:nil];
        };
        item.cellTappedBlock = cellTapHandlers[item.identifier];
    } else if (item.cellType == 6 || item.cellType == 37) {
        __weak AWESettingItemModel *weakItem = item;
        item.switchChangedBlock = ^{
          __strong AWESettingItemModel *strongItem = weakItem;
          if (strongItem) {
              if (!strongItem.isEnable)
                  return;
              BOOL isSwitchOn = !strongItem.isSwitchOn;
              strongItem.isSwitchOn = isSwitchOn;
              [self setUserDefaults:@(isSwitchOn) forKey:strongItem.identifier];
              [self handleConflictsAndDependenciesForSetting:strongItem.identifier isEnabled:isSwitchOn];
          }
        };
    }

    return item;
}

#pragma mark

extern void showDYYYSettingsVC(UIViewController *rootVC, BOOL hasAgreed);
extern void *kViewModelKey;


static void showIconOptionsDialog(NSString *title, UIImage *previewImage, NSString *saveFilename, void (^onClear)(void), void (^onSelect)(void)) {
    DYYYIconOptionsDialogView *optionsDialog = [[DYYYIconOptionsDialogView alloc] initWithTitle:title previewImage:previewImage];
    optionsDialog.onClear = onClear;
    optionsDialog.onSelect = onSelect;
    [optionsDialog show];
}

+ (AWESettingItemModel *)createIconCustomizationItemWithIdentifier:(NSString *)identifier
                                  title:(NSString *)title
                               svgIcon:(NSString *)svgIconName
                            saveFile:(NSString *)saveFilename {
    AWESettingItemModel *item = [[NSClassFromString(@"AWESettingItemModel") alloc] init];
    item.identifier = identifier;
    item.title = title;

    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];
    NSString *imagePath = [dyyyFolderPath stringByAppendingPathComponent:saveFilename];

    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
    item.detail = fileExists ? @"已设置" : @"默认";

    item.type = 0;
    item.svgIconImageName = svgIconName;
    item.cellType = 26;
    item.colorStyle = 0;
    item.isEnable = YES;

    __weak AWESettingItemModel *weakItem = item;
    item.cellTappedBlock = ^{
        if (![[NSFileManager defaultManager] fileExistsAtPath:dyyyFolderPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        }

        UIViewController *topVC = topView();

        UIImage *previewImage = nil;
        if (fileExists) {
            previewImage = [UIImage imageWithContentsOfFile:imagePath];
        }

        showIconOptionsDialog(title, previewImage, saveFilename, ^{
          if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
              NSError *error = nil;
              [[NSFileManager defaultManager] removeItemAtPath:imagePath error:&error];
              if (!error) {
                  weakItem.detail = @"默认";
                  [weakItem refreshCell];
              }
          }
        }, ^{
          UIImagePickerController *picker = [[UIImagePickerController alloc] init];
          picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
          picker.allowsEditing = NO;
          picker.mediaTypes = @[ @"public.image" ];

          DYYYImagePickerDelegate *pickerDelegate = [[DYYYImagePickerDelegate alloc] init];
          pickerDelegate.completionBlock = ^(NSDictionary *info) {
            NSURL *originalImageURL = info[UIImagePickerControllerImageURL];
            if (!originalImageURL) {
                originalImageURL = info[UIImagePickerControllerReferenceURL];
            }
            if (originalImageURL) {
                NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];
                NSString *imagePath = [dyyyFolderPath stringByAppendingPathComponent:saveFilename];

                NSData *imageData = [NSData dataWithContentsOfURL:originalImageURL];
                const char *bytes = (const char *)imageData.bytes;
                BOOL isGIF = (imageData.length >= 6 && (memcmp(bytes, "GIF87a", 6) == 0 || memcmp(bytes, "GIF89a", 6) == 0));
                if (isGIF) {
                    [imageData writeToFile:imagePath atomically:YES];
                } else {
                    UIImage *selectedImage = [UIImage imageWithData:imageData];
                    imageData = UIImagePNGRepresentation(selectedImage);
                    [imageData writeToFile:imagePath atomically:YES];
                }

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    weakItem.detail = @"已设置";
                    [weakItem refreshCell];
                });
            }
          };

          static char kDYYYPickerDelegateKey;
          picker.delegate = pickerDelegate;
          objc_setAssociatedObject(picker, &kDYYYPickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
          [topVC presentViewController:picker animated:YES completion:nil];
        });
    };

    return item;
}

+ (AWESettingSectionModel *)createSectionWithTitle:(NSString *)title items:(NSArray *)items {
    return [self createSectionWithTitle:title footerTitle:nil items:items];
}

+ (AWESettingSectionModel *)createSectionWithTitle:(NSString *)title footerTitle:(NSString *)footerTitle items:(NSArray *)items {
    AWESettingSectionModel *section = [[NSClassFromString(@"AWESettingSectionModel") alloc] init];
    section.sectionHeaderTitle = title;
    section.sectionHeaderHeight = 40;
    section.sectionFooterTitle = footerTitle;
    section.useNewFooterLayout = YES;
    section.type = 0;
    section.itemArray = items;
    return section;
}

+ (AWESettingBaseViewController *)createSubSettingsViewController:(NSString *)title
                                                        sections:(NSArray *)sectionsArray {
    AWESettingBaseViewController *settingsVC = [[NSClassFromString(@"AWESettingBaseViewController") alloc] init];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([settingsVC.view isKindOfClass:[UIView class]]) {
            Class navBarClass = NSClassFromString(@"AWENavigationBar");
            for (UIView *subview in settingsVC.view.subviews) {
                if (navBarClass && [subview isKindOfClass:navBarClass]) {
                    id navigationBar = subview;
                    if ([navigationBar respondsToSelector:@selector(titleLabel)]) {
                        UILabel *label = [navigationBar valueForKey:@"titleLabel"];
                        label.text = title;
                    }
                    break;
                }
            }
        }
    });

    AWESettingsViewModel *viewModel = [[NSClassFromString(@"AWESettingsViewModel") alloc] init];
    viewModel.colorStyle = 0;
    viewModel.sectionDataArray = sectionsArray;
    objc_setAssociatedObject(settingsVC, &kViewModelKey, viewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return settingsVC;
}

+ (UIViewController *)findViewController:(UIResponder *)responder {
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

+ (void)openSettingsWithViewController:(UIViewController *)vc {
    BOOL hasAgreed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"];
    showDYYYSettingsVC(vc, hasAgreed);
}

+ (void)openSettingsFromView:(UIView *)view {
    UIViewController *currentVC = [self findViewController:view];
    if ([currentVC isKindOfClass:NSClassFromString(@"AWELeftSideBarViewController")]) {
        [self openSettingsWithViewController:currentVC];
    }
}

+ (void)addTapGestureToView:(UIView *)view target:(id)target {
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(openDYYYSettings)];
    [view addGestureRecognizer:tapGesture];
}

+ (void)showUserAgreementAlert {
    [self showTextInputAlert:@"用户协议" defaultText:@"" placeholder:@"" onConfirm:^(NSString *text) {
        if ([text isEqualToString:@"我已阅读并同意继续使用"]) {
            [self setUserDefaults:@"YES" forKey:@"DYYYUserAgreementAccepted"];
        } else {
            [DYYYUtils showToast:@"请正确输入内容"];
            [self showUserAgreementAlert];
        }
    } onCancel:^{
        [DYYYUtils showToast:@"请立即卸载本插件"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exit(0);
        });
    }];
}

@end
