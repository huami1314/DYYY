#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"

// 先声明基本视图模型类
@interface AWESettingBaseViewModel : NSObject
@end

// 导入必要的类定义，确保先声明基类再声明子类
@interface AWESettingBaseViewController : UIViewController
@property(nonatomic, strong) UIView *view;
- (AWESettingBaseViewModel *)viewModel;
@end

@interface AWENavigationBar : UIView
@property(nonatomic, strong) UILabel *titleLabel;
@end

@interface AWESettingsViewModel : AWESettingBaseViewModel
@property(nonatomic, assign) NSInteger colorStyle;
@property(nonatomic, strong) NSArray *sectionDataArray;
@property(nonatomic, weak) id controllerDelegate;
@property(nonatomic, strong) NSString *traceEnterFrom;
@end

@interface AWESettingSectionModel : NSObject
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, assign) CGFloat sectionHeaderHeight;
@property(nonatomic, copy) NSString *sectionHeaderTitle;
@property(nonatomic, strong) NSArray *itemArray;
@end

@interface AWESettingItemModel : NSObject
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *detail;
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, copy) NSString *iconImageName;
@property(nonatomic, copy) NSString *svgIconImageName;
@property(nonatomic, assign) NSInteger cellType;
@property(nonatomic, assign) NSInteger colorStyle;
@property(nonatomic, assign) BOOL isEnable;
@property(nonatomic, assign) BOOL isSwitchOn;
@property(nonatomic, copy) void (^cellTappedBlock)(void);
@property(nonatomic, copy) void (^switchChangedBlock)(void);
@end

// 获取顶级视图控制器
static UIViewController *getActiveTopViewController() {
    UIWindowScene *activeScene = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            activeScene = scene;
            break;
        }
    }
    if (!activeScene) {
        for (id scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }
    }
    if (!activeScene) return nil;
    UIWindow *window = activeScene.windows.firstObject;
    UIViewController *topController = window.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

// 获取最上层视图控制器
static UIViewController *topView(void) {
    UIWindow *window = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            window = scene.windows.firstObject;
            break;
        }
    }
    if (!window) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                window = scene.windows.firstObject;
                break;
            }
        }
    }
    if (!window) return nil;
    UIViewController *rootVC = window.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        return ((UINavigationController *)rootVC).topViewController;
    }
    return rootVC;
}

// 显示文本输入弹窗
static void showTextInputAlert(NSString *title, void (^onConfirm)(NSString *text), void (^onCancel)(void)) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"请输入内容";
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *inputText = alertController.textFields.firstObject.text;
        if (onConfirm) onConfirm(inputText);
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (onCancel) onCancel();
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topVC = topView();
        if (topVC) [topVC presentViewController:alertController animated:YES completion:nil];
    });
}

// 获取和设置用户偏好
static bool getUserDefaults(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

static void setUserDefaults(id object, NSString *key) {
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#undef DYYY
#define DYYY @"DYYY设置"

static void *kViewModelKey = &kViewModelKey;
%hook AWESettingBaseViewController
- (bool)useCardUIStyle {
    return YES;
}

- (AWESettingBaseViewModel *)viewModel {
    AWESettingBaseViewModel *original = %orig;
    if (!original) return objc_getAssociatedObject(self, &kViewModelKey);
    return original;
}
%end

// 添加一个方法用于创建二级设置界面
static AWESettingBaseViewController* createSubSettingsViewController(NSString* title, NSArray* settingsItems) {
    AWESettingBaseViewController *settingsVC = [[%c(AWESettingBaseViewController) alloc] init];
    
    // 等待视图加载并设置标题
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([settingsVC.view isKindOfClass:[UIView class]]) {
            for (UIView *subview in settingsVC.view.subviews) {
                if ([subview isKindOfClass:%c(AWENavigationBar)]) {
                    AWENavigationBar *navigationBar = (AWENavigationBar *)subview;
                    if ([navigationBar respondsToSelector:@selector(titleLabel)]) {
                        navigationBar.titleLabel.text = title;
                    }
                    break;
                }
            }
        }
    });
    
    AWESettingsViewModel *viewModel = [[%c(AWESettingsViewModel) alloc] init];
    viewModel.colorStyle = 0;
    
    AWESettingSectionModel *section = [[%c(AWESettingSectionModel) alloc] init];
    section.sectionHeaderTitle = title;
    section.sectionHeaderHeight = 40;
    section.type = 0;
    section.itemArray = settingsItems;
    
    viewModel.sectionDataArray = @[section];
    objc_setAssociatedObject(settingsVC, kViewModelKey, viewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return settingsVC;
}

%hook AWESettingsViewModel
- (NSArray *)sectionDataArray {
    NSArray *originalSections = %orig;
    BOOL sectionExists = NO;
    for (AWESettingSectionModel *section in originalSections) {
        if ([section.sectionHeaderTitle isEqualToString:@"DYYY"]) {
            sectionExists = YES;
            break;
        }
    }
    if (self.traceEnterFrom && !sectionExists) {
        AWESettingItemModel *dyyyItem = [[%c(AWESettingItemModel) alloc] init];
        dyyyItem.identifier = @"DYYY";
        dyyyItem.title = @"DYYY";
        dyyyItem.detail = @"v2.1-7";
        dyyyItem.type = 0;
        dyyyItem.iconImageName = @"noticesettting_like";
        dyyyItem.cellType = 26;
        dyyyItem.colorStyle = 2;
        dyyyItem.isEnable = YES;
        dyyyItem.cellTappedBlock = ^{
            UIViewController *rootVC = self.controllerDelegate;
            AWESettingBaseViewController *settingsVC = [[%c(AWESettingBaseViewController) alloc] init];
            
            // 等待视图加载并使用KVO安全访问属性
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([settingsVC.view isKindOfClass:[UIView class]]) {
                    for (UIView *subview in settingsVC.view.subviews) {
                        if ([subview isKindOfClass:%c(AWENavigationBar)]) {
                            AWENavigationBar *navigationBar = (AWENavigationBar *)subview;
                            if ([navigationBar respondsToSelector:@selector(titleLabel)]) {
                                navigationBar.titleLabel.text = DYYY;
                            }
                            break;
                        }
                    }
                }
            });
            
            AWESettingsViewModel *viewModel = [[%c(AWESettingsViewModel) alloc] init];
            viewModel.colorStyle = 0;
            
            // 创建主分类列表
            AWESettingSectionModel *mainSection = [[%c(AWESettingSectionModel) alloc] init];
            mainSection.sectionHeaderTitle = @"设置分类";
            mainSection.sectionHeaderHeight = 40;
            mainSection.type = 0;
            NSMutableArray<AWESettingItemModel *> *mainItems = [NSMutableArray array];
            
            // 创建基本设置分类项
            AWESettingItemModel *basicSettingItem = [[%c(AWESettingItemModel) alloc] init];
            basicSettingItem.identifier = @"DYYYBasicSettings";
            basicSettingItem.title = @"基本设置";
            basicSettingItem.type = 0;
            basicSettingItem.svgIconImageName = @"ic_gearsimplify_outlined_20";
            basicSettingItem.cellType = 26;
            basicSettingItem.colorStyle = 0;
            basicSettingItem.isEnable = YES;
            basicSettingItem.cellTappedBlock = ^{
                // 创建基本设置二级界面的设置项
                NSMutableArray<AWESettingItemModel *> *basicSettingsItems = [NSMutableArray array];
                NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];
                NSArray *basicSettings = @[
                    @{@"identifier": @"DYYYEnableDanmuColor", @"title": @"开启弹幕改色", @"detail": @"", @"cellType": @6, @"imageName": @"ic_bubbletwo_outlined_20"},
                    @{@"identifier": @"DYYYdanmuColor", @"title": @"修改弹幕颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_bubbletwo_filled_20"},
                    @{@"identifier": @"DYYYPlaceholderColor", @"title": @"改占位符颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_artboardpen_outlined"},
                    @{@"identifier": @"DYYYLabelColor", @"title": @"时间标签颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_clock_outlined_20"},                
                    @{@"identifier": @"DYYYisDarkKeyBoard", @"title": @"启用深色键盘", @"detail": @"", @"cellType": @6, @"imageName": @"ic_keyboard_outlined"},
                    @{@"identifier": @"DYYYisShowSchedule", @"title": @"启用视频进度", @"detail": @"", @"cellType": @6, @"imageName": @"ic_playertime_outlined_20"},
                    @{@"identifier": @"DYYYisEnableAutoPlay", @"title": @"启用自动播放", @"detail": @"", @"cellType": @6, @"imageName": @"ic_play_filled_20"},
                    @{@"identifier": @"DYYYisSkipLive", @"title": @"启用过滤直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_livephoto_outlined_20"},
                    @{@"identifier": @"DYYYisEnablePure", @"title": @"启用首页净化", @"detail": @"", @"cellType": @6, @"imageName": @"ic_broom_outlined"},
                    @{@"identifier": @"DYYYisEnableFullScreen", @"title": @"启用首页全屏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_fullscreen_outlined_16"},
                    @{@"identifier": @"DYYYNoAds", @"title": @"启用屏蔽广告", @"detail": @"", @"cellType": @6, @"imageName": @"ic_ad_outlined_20"},
                    @{@"identifier": @"DYYYisEnableCommentBlur", @"title": @"评论区毛玻璃", @"detail": @"", @"cellType": @6, @"imageName": @"ic_comment_outlined_20"},
                    @{@"identifier": @"DYYYisEnableArea", @"title": @"时间属地显示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_location_outlined_20"},
                    @{@"identifier": @"DYYYfollowTips", @"title": @"关注二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_userplus_outlined_20"},
                    @{@"identifier": @"DYYYcollectTips", @"title": @"收藏二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_collection_outlined_20"}
                ];
                for (NSDictionary *dict in basicSettings) {
                    AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
                    item.identifier = dict[@"identifier"];
                    item.title = dict[@"title"];
                    NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
                    item.detail = savedDetail ?: dict[@"detail"];
                    item.type = 1000;
                    item.svgIconImageName = dict[@"imageName"];
                    item.cellType = [dict[@"cellType"] integerValue];
                    item.colorStyle = 0;
                    item.isEnable = YES;
                    item.isSwitchOn = getUserDefaults(item.identifier);
                    if (item.cellType == 26) {
                        cellTapHandlers[item.identifier] = ^{
                            showTextInputAlert(item.title, ^(NSString *text) {
                                setUserDefaults(text, item.identifier);
                            }, nil);
                        };
                        item.cellTappedBlock = cellTapHandlers[item.identifier];
                    } else {
                        __weak AWESettingItemModel *weakItem = item;
                        item.switchChangedBlock = ^{
                            __strong AWESettingItemModel *strongItem = weakItem;
                            if (strongItem) {
                                BOOL isSwitchOn = !strongItem.isSwitchOn;
                                strongItem.isSwitchOn = isSwitchOn;
                                setUserDefaults(@(isSwitchOn), strongItem.identifier);
                            }
                        };
                    }
                    [basicSettingsItems addObject:item];
                }
                
                // 创建并推入二级设置页面
                AWESettingBaseViewController *subVC = createSubSettingsViewController(@"基本设置", basicSettingsItems);
                [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
            };
            [mainItems addObject:basicSettingItem];
            
            // 创建界面设置分类项
            AWESettingItemModel *uiSettingItem = [[%c(AWESettingItemModel) alloc] init];
            uiSettingItem.identifier = @"DYYYUISettings";
            uiSettingItem.title = @"界面设置";
            uiSettingItem.type = 0;
            uiSettingItem.svgIconImageName = @"ic_ipadiphone_outlined";
            uiSettingItem.cellType = 26;
            uiSettingItem.colorStyle = 0;
            uiSettingItem.isEnable = YES;
            uiSettingItem.cellTappedBlock = ^{
                // 创建界面设置二级界面的设置项
                NSMutableArray<AWESettingItemModel *> *uiSettingsItems = [NSMutableArray array];
                NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];
                NSArray *uiSettings = @[
                    @{@"identifier": @"DYYYtopbartransparent", @"title": @"设置顶栏透明", @"detail": @"", @"cellType": @26, @"imageName": @"ic_arrowup_outlined_20"},
                    @{@"identifier": @"DYYYGlobalTransparency", @"title": @"设置全局透明", @"detail": @"", @"cellType": @26, @"imageName": @"ic_eyeslash_outlined_20"},
                    @{@"identifier": @"DYYYDefaultSpeed", @"title": @"设置默认倍速", @"detail": @"", @"cellType": @26, @"imageName": @"ic_speed_outlined_20"},
                    @{@"identifier": @"DYYYElementScale", @"title": @"右侧栏缩放度", @"detail": @"", @"cellType": @26, @"imageName": @"ic_zoomin_outlined_20"},
                    @{@"identifier": @"DYYYIndexTitle", @"title": @"设置首页标题", @"detail": @"", @"cellType": @26, @"imageName": @"ic_docpen_filled"},
                    @{@"identifier": @"DYYYFriendsTitle", @"title": @"设置朋友标题", @"detail": @"", @"cellType": @26, @"imageName": @"ic_usertwo_outlined_20"},
                    @{@"identifier": @"DYYYMsgTitle", @"title": @"设置消息标题", @"detail": @"", @"cellType": @26, @"imageName": @"ic_msg_outlined_20"},
                    @{@"identifier": @"DYYYSelfTitle", @"title": @"设置我的标题", @"detail": @"", @"cellType": @26, @"imageName": @"ic_user_outlined_20"},
                    @{@"identifier": @"DYYYPlaceholder", @"title": @"自定义占位符", @"detail": @"", @"cellType": @26, @"imageName": @"ic_pensketch_outlined_20"}
                ];
                for (NSDictionary *dict in uiSettings) {
                    AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
                    item.identifier = dict[@"identifier"];
                    item.title = dict[@"title"];
                    NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
                    item.detail = savedDetail ?: dict[@"detail"];
                    item.type = 1000;
                    item.svgIconImageName = dict[@"imageName"];
                    item.cellType = [dict[@"cellType"] integerValue];
                    item.colorStyle = 0;
                    item.isEnable = YES;
                    cellTapHandlers[item.identifier] = ^{
                        showTextInputAlert(item.title, ^(NSString *text) {
                            setUserDefaults(text, item.identifier);
                        }, nil);
                    };
                    item.cellTappedBlock = cellTapHandlers[item.identifier];
                    [uiSettingsItems addObject:item];
                }
                
                // 创建并推入二级设置页面
                AWESettingBaseViewController *subVC = createSubSettingsViewController(@"界面设置", uiSettingsItems);
                [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
            };
            [mainItems addObject:uiSettingItem];
            
            // 创建隐藏设置分类项
            AWESettingItemModel *hideSettingItem = [[%c(AWESettingItemModel) alloc] init];
            hideSettingItem.identifier = @"DYYYHideSettings";
            hideSettingItem.title = @"隐藏设置";
            hideSettingItem.type = 0;
            hideSettingItem.svgIconImageName = @"ic_eyeslash_outlined_20";
            hideSettingItem.cellType = 26;
            hideSettingItem.colorStyle = 0;
            hideSettingItem.isEnable = YES;
            hideSettingItem.cellTappedBlock = ^{
                // 创建隐藏设置二级界面的设置项
                NSMutableArray<AWESettingItemModel *> *hideSettingsItems = [NSMutableArray array];
                NSArray *hideSettings = @[
                    @{@"identifier": @"DYYYisHideStatusbar", @"title": @"隐藏系统顶栏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenEntry", @"title": @"隐藏全屏观看", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideShopButton", @"title": @"隐藏底栏商城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideMessageButton", @"title": @"隐藏底栏信息", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideFriendsButton", @"title": @"隐藏底栏朋友", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenJia", @"title": @"隐藏底栏加号", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenBottomDot", @"title": @"隐藏底栏红点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenBottomBg", @"title": @"隐藏底栏背景", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenSidebarDot", @"title": @"隐藏侧栏红点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideLikeButton", @"title": @"隐藏点赞按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideCommentButton", @"title": @"隐藏评论按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideCollectButton", @"title": @"隐藏收藏按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideAvatarButton", @"title": @"隐藏头像按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideMusicButton", @"title": @"隐藏音乐按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideShareButton", @"title": @"隐藏分享按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideLocation", @"title": @"隐藏视频定位", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideDiscover", @"title": @"隐藏右上搜索", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideMyPage", @"title": @"隐藏我的页面", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideInteractionSearch", @"title": @"隐藏相关搜索", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideQuqishuiting", @"title": @"隐藏去汽水听", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideHotspot", @"title": @"隐藏热点提示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHidentopbarprompt", @"title": @"隐藏顶栏横线", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHidenqipo", @"title": @"隐藏头像气泡", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHidentandeanniu", @"title": @"隐藏弹的按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"}
                ];
                for (NSDictionary *dict in hideSettings) {
                    AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
                    item.identifier = dict[@"identifier"];
                    item.title = dict[@"title"];
                    NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
                    item.detail = savedDetail ?: dict[@"detail"];
                    item.type = 1000;
                    item.svgIconImageName = dict[@"imageName"];
                    item.cellType = [dict[@"cellType"] integerValue];
                    item.colorStyle = 0;
                    item.isEnable = YES;
                    item.isSwitchOn = getUserDefaults(item.identifier);
                    __weak AWESettingItemModel *weakItem = item;
                    item.switchChangedBlock = ^{
                        __strong AWESettingItemModel *strongItem = weakItem;
                        if (strongItem) {
                            BOOL isSwitchOn = !strongItem.isSwitchOn;
                            strongItem.isSwitchOn = isSwitchOn;
                            setUserDefaults(@(isSwitchOn), strongItem.identifier);
                        }
                    };
                    [hideSettingsItems addObject:item];
                }
                
                // 创建并推入二级设置页面
                AWESettingBaseViewController *subVC = createSubSettingsViewController(@"隐藏设置", hideSettingsItems);
                [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
            };
            [mainItems addObject:hideSettingItem];
            
            // 创建顶栏移除分类项
            AWESettingItemModel *removeSettingItem = [[%c(AWESettingItemModel) alloc] init];
            removeSettingItem.identifier = @"DYYYRemoveSettings";
            removeSettingItem.title = @"顶栏移除";
            removeSettingItem.type = 0;
            removeSettingItem.svgIconImageName = @"ic_doublearrowup_outlined_20";
            removeSettingItem.cellType = 26;
            removeSettingItem.colorStyle = 0;
            removeSettingItem.isEnable = YES;
            removeSettingItem.cellTappedBlock = ^{
                // 创建顶栏移除二级界面的设置项
                NSMutableArray<AWESettingItemModel *> *removeSettingsItems = [NSMutableArray array];
                NSArray *removeSettings = @[
                    @{@"identifier": @"DYYYHideHotContainer", @"title": @"移除推荐", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"},
                    @{@"identifier": @"DYYYHideFollow", @"title": @"移除关注", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"},
                    @{@"identifier": @"DYYYHideMediumVideo", @"title": @"移除精选", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"},
                    @{@"identifier": @"DYYYHideMall", @"title": @"移除商城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"},
                    @{@"identifier": @"DYYYHideNearby", @"title": @"移除同城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"},
                    @{@"identifier": @"DYYYHideGroupon", @"title": @"移除团购", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"},
                    @{@"identifier": @"DYYYHideTabLive", @"title": @"移除直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"},
                    @{@"identifier": @"DYYYHidePadHot", @"title": @"移除热点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"},
                    @{@"identifier": @"DYYYHideHangout", @"title": @"移除经验", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"}
                ];
                for (NSDictionary *dict in removeSettings) {
                    AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
                    item.identifier = dict[@"identifier"];
                    item.title = dict[@"title"];
                    NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
                    item.detail = savedDetail ?: dict[@"detail"];
                    item.type = 1000;
                    item.svgIconImageName = dict[@"imageName"];
                    item.cellType = [dict[@"cellType"] integerValue];
                    item.colorStyle = 0;
                    item.isEnable = YES;
                    item.isSwitchOn = getUserDefaults(item.identifier);
                    __weak AWESettingItemModel *weakItem = item;
                    item.switchChangedBlock = ^{
                        __strong AWESettingItemModel *strongItem = weakItem;
                        if (strongItem) {
                            BOOL isSwitchOn = !strongItem.isSwitchOn;
                            strongItem.isSwitchOn = isSwitchOn;
                            setUserDefaults(@(isSwitchOn), strongItem.identifier);
                        }
                    };
                    [removeSettingsItems addObject:item];
                }
                
                // 创建并推入二级设置页面
                AWESettingBaseViewController *subVC = createSubSettingsViewController(@"顶栏移除", removeSettingsItems);
                [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
            };
            [mainItems addObject:removeSettingItem];
            
            // 创建增强设置分类项
            AWESettingItemModel *enhanceSettingItem = [[%c(AWESettingItemModel) alloc] init];
            enhanceSettingItem.identifier = @"DYYYEnhanceSettings";
            enhanceSettingItem.title = @"增强设置";
            enhanceSettingItem.type = 0;
            enhanceSettingItem.svgIconImageName = @"ic_squaresplit_outlined_20";
            enhanceSettingItem.cellType = 26;
            enhanceSettingItem.colorStyle = 0;
            enhanceSettingItem.isEnable = YES;
            enhanceSettingItem.cellTappedBlock = ^{
                // 创建增强设置二级界面的设置项
                NSMutableArray<AWESettingItemModel *> *enhanceSettingsItems = [NSMutableArray array];
                NSArray *enhanceSettings = @[
                    @{@"identifier": @"DYYYDoubleClickedDownload", @"title": @"双击下载", @"detail": @"无水印保存", @"cellType": @6, @"imageName": @"ic_cloudarrowdown_outlined_20"},
                    @{@"identifier": @"DYYYDoubleClickedComment", @"title": @"双击打开评论区", @"detail": @"", @"cellType": @6, @"imageName": @"ic_comment_outlined_20"},
                    @{@"identifier": @"DYYYLongPressDownload", @"title": @"长按下载", @"detail": @"无水印保存", @"cellType": @6, @"imageName": @"ic_boxarrowdown_outlined"},
                    @{@"identifier": @"DYYYCopyText", @"title": @"长按复制文案", @"detail": @"", @"cellType": @6, @"imageName": @"ic_rectangleonrectangleup_outlined_20"},
                    @{@"identifier": @"DYYYCommentLivePhotoNotWaterMark", @"title": @"移除评论实况水印", @"detail": @"", @"cellType": @6, @"imageName": @"ic_livephoto_outlined_20"},
                    @{@"identifier": @"DYYYCommentNotWaterMark", @"title": @"移除评论图片水印", @"detail": @"", @"cellType": @6, @"imageName": @"ic_removeimage_outlined_20"},
                    @{@"identifier": @"DYYYisShowScheduleDisplay", @"title": @"显示视频进度", @"detail": @"", @"cellType": @6, @"imageName": @"ic_playertime_outlined_20"},
                    @{@"identifier": @"DYYYCommentCopyText", @"title": @"忽略艾特用户", @"detail": @"", @"cellType": @6, @"imageName": @"ic_at_outlined_20"}
                ];
                for (NSDictionary *dict in enhanceSettings) {
                    AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
                    item.identifier = dict[@"identifier"];
                    item.title = dict[@"title"];
                    NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
                    item.detail = savedDetail ?: dict[@"detail"];
                    item.type = 1000;
                    item.svgIconImageName = dict[@"imageName"];
                    item.cellType = [dict[@"cellType"] integerValue];
                    item.colorStyle = 0;
                    item.isEnable = YES;
                    item.isSwitchOn = getUserDefaults(item.identifier);
                    __weak AWESettingItemModel *weakItem = item;
                    item.switchChangedBlock = ^{
                        __strong AWESettingItemModel *strongItem = weakItem;
                        if (strongItem) {
                            BOOL isSwitchOn = !strongItem.isSwitchOn;
                            strongItem.isSwitchOn = isSwitchOn;
                            setUserDefaults(@(isSwitchOn), strongItem.identifier);
                        }
                    };
                    [enhanceSettingsItems addObject:item];
                }
                
                // 创建并推入二级设置页面
                AWESettingBaseViewController *subVC = createSubSettingsViewController(@"增强设置\n感谢huami girl pxx", enhanceSettingsItems);
                [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
            };
            [mainItems addObject:enhanceSettingItem];
            
            // 添加关于
            AWESettingItemModel *aboutItem = [[%c(AWESettingItemModel) alloc] init];
            aboutItem.identifier = @"DYYYAbout";
            aboutItem.title = @"关于插件";
            aboutItem.detail = @"v2.1-7";
            aboutItem.type = 0;
            aboutItem.iconImageName = @"awe-settings-icon-about";
            aboutItem.cellType = 26;
            aboutItem.colorStyle = 0;
            aboutItem.isEnable = YES;
            // 添加点击处理，使其可点击
            aboutItem.cellTappedBlock = ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"关于DYYY" 
                                                                                         message:@"版本: v2.1-7\n\n感谢使用DYYY"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:okAction];
                [rootVC presentViewController:alertController animated:YES completion:nil];
            };
            [mainItems addObject:aboutItem];
            
            mainSection.itemArray = mainItems;
            viewModel.sectionDataArray = @[mainSection];
            objc_setAssociatedObject(settingsVC, kViewModelKey, viewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [rootVC.navigationController pushViewController:(UIViewController *)settingsVC animated:YES];
        };
        AWESettingSectionModel *newSection = [[%c(AWESettingSectionModel) alloc] init];
        newSection.itemArray = @[dyyyItem];
        newSection.type = 0;
        newSection.sectionHeaderHeight = 40;
        newSection.sectionHeaderTitle = @"DYYY";
        NSMutableArray *newSections = [NSMutableArray arrayWithArray:originalSections];
        [newSections insertObject:newSection atIndex:0];
        return newSections;
    }
    return originalSections;
}
%end