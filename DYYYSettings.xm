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

// 添加缺少的辅助函数定义
static BOOL getUserDefaults(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

static void setUserDefaults(id value, NSString *key) {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static void showTextInputAlert(NSString *title, void(^completion)(NSString *text), NSString *defaultText) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = defaultText;
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *text = alertController.textFields.firstObject.text;
        if (completion) completion(text);
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:alertController animated:YES completion:nil];
}

// 修复DYYY宏定义问题 - 确保是字符串而不是数字
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
            
            // 基本设置
            AWESettingSectionModel *basicSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
            basicSettingsSection.sectionHeaderTitle = @"基本设置";
            basicSettingsSection.sectionHeaderHeight = 40;
            basicSettingsSection.type = 0;
            NSMutableArray<AWESettingItemModel *> *basicSettingsItems = [NSMutableArray array];
            NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];
            NSArray *basicSettings = @[
                @{@"identifier": @"DYYYEnableDanmuColor", @"title": @"开启弹幕改色", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYdanmuColor", @"title": @"修改弹幕颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYPlaceholderColor", @"title": @"改占位符颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYLabelColor", @"title": @"时间标签颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_gear_filled"},                
                @{@"identifier": @"DYYYisDarkKeyBoard", @"title": @"启用深色键盘", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYisShowSchedule", @"title": @"启用视频进度", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYisEnableAutoPlay", @"title": @"启用自动播放", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYisSkipLive", @"title": @"启用过滤直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYisEnablePure", @"title": @"启用首页净化", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYisEnableFullScreen", @"title": @"启用首页全屏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYNoAds", @"title": @"启用屏蔽广告", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYisEnableCommentBlur", @"title": @"评论区毛玻璃", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYisEnableArea", @"title": @"时间属地显示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYfollowTips", @"title": @"关注二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
                @{@"identifier": @"DYYYcollectTips", @"title": @"收藏二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"}
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
            basicSettingsSection.itemArray = basicSettingsItems;

            // 界面设置
            AWESettingSectionModel *uiSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
            uiSettingsSection.sectionHeaderTitle = @"界面设置";
            uiSettingsSection.sectionHeaderHeight = 40;
            uiSettingsSection.type = 0;
            NSMutableArray<AWESettingItemModel *> *uiSettingsItems = [NSMutableArray array];
            NSArray *uiSettings = @[
                @{@"identifier": @"DYYYtopbartransparent", @"title": @"设置顶栏透明", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
                @{@"identifier": @"DYYYGlobalTransparency", @"title": @"设置全局透明", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
                @{@"identifier": @"DYYYDefaultSpeed", @"title": @"设置默认倍速", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
                @{@"identifier": @"DYYYElementScale", @"title": @"右侧栏缩放度", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
                @{@"identifier": @"DYYYIndexTitle", @"title": @"设置首页标题", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
                @{@"identifier": @"DYYYFriendsTitle", @"title": @"设置朋友标题", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
                @{@"identifier": @"DYYYMsgTitle", @"title": @"设置消息标题", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
                @{@"identifier": @"DYYYSelfTitle", @"title": @"设置我的标题", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
                @{@"identifier": @"DYYYPlaceholder", @"title": @"自定义占位符", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"}
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
            uiSettingsSection.itemArray = uiSettingsItems;

            // 隐藏设置
            AWESettingSectionModel *hideSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
            hideSettingsSection.sectionHeaderTitle = @"隐藏设置";
            hideSettingsSection.sectionHeaderHeight = 40;
            hideSettingsSection.type = 0;
            NSMutableArray<AWESettingItemModel *> *hideSettingsItems = [NSMutableArray array];
            NSArray *hideSettings = @[
                @{@"identifier": @"DYYYisHideStatusbar", @"title": @"隐藏系统顶栏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYisHiddenEntry", @"title": @"隐藏全屏观看", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideShopButton", @"title": @"隐藏底栏商城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideMessageButton", @"title": @"隐藏底栏信息", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideFriendsButton", @"title": @"隐藏底栏朋友", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYisHiddenJia", @"title": @"隐藏底栏加号", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYisHiddenBottomDot", @"title": @"隐藏底栏红点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYisHiddenBottomBg", @"title": @"隐藏底栏背景", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYisHiddenSidebarDot", @"title": @"隐藏侧栏红点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideLikeButton", @"title": @"隐藏点赞按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideCommentButton", @"title": @"隐藏评论按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideCollectButton", @"title": @"隐藏收藏按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideAvatarButton", @"title": @"隐藏头像按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideMusicButton", @"title": @"隐藏音乐按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideShareButton", @"title": @"隐藏分享按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideLocation", @"title": @"隐藏视频定位", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideDiscover", @"title": @"隐藏右上搜索", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideMyPage", @"title": @"隐藏我的页面", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideInteractionSearch", @"title": @"隐藏相关搜索", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideQuqishuiting", @"title": @"隐藏去汽水听", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHideHotspot", @"title": @"隐藏热点提示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHidentopbarprompt", @"title": @"隐藏顶栏横线", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHidenqipo", @"title": @"隐藏头像气泡", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
                @{@"identifier": @"DYYYHidentandeanniu", @"title": @"隐藏弹的按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"}
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
            hideSettingsSection.itemArray = hideSettingsItems;

            // 顶栏移除
            AWESettingSectionModel *removeSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
            removeSettingsSection.sectionHeaderTitle = @"顶栏移除";
            removeSettingsSection.sectionHeaderHeight = 40;
            removeSettingsSection.type = 0;
            NSMutableArray<AWESettingItemModel *> *removeSettingsItems = [NSMutableArray array];
            NSArray *removeSettings = @[
                @{@"identifier": @"DYYYHideHotContainer", @"title": @"移除推荐", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
                @{@"identifier": @"DYYYHideFollow", @"title": @"移除关注", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
                @{@"identifier": @"DYYYHideMediumVideo", @"title": @"移除精选", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
                @{@"identifier": @"DYYYHideMall", @"title": @"移除商城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
                @{@"identifier": @"DYYYHideNearby", @"title": @"移除同城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
                @{@"identifier": @"DYYYHideGroupon", @"title": @"移除团购", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
                @{@"identifier": @"DYYYHideTabLive", @"title": @"移除直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
                @{@"identifier": @"DYYYHidePadHot", @"title": @"移除热点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
                @{@"identifier": @"DYYYHideHangout", @"title": @"移除经验", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"}
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
            removeSettingsSection.itemArray = removeSettingsItems;

            // 增强设置
            AWESettingSectionModel *enhanceSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
            enhanceSettingsSection.sectionHeaderTitle = @"增强设置\n感谢huami girl pxx";
            enhanceSettingsSection.sectionHeaderHeight = 40;
            enhanceSettingsSection.type = 0;

            NSMutableArray<AWESettingItemModel *> *enhanceSettingsItems = [NSMutableArray array];
            NSArray *enhanceSettings = @[
                @{@"identifier": @"DYYYDoubleClickedDownload", @"title": @"双击下载", @"detail": @"无水印保存", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},
                @{@"identifier": @"DYYYDoubleClickedComment", @"title": @"双击打开评论区", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},
                @{@"identifier": @"DYYYLongPressDownload", @"title": @"长按下载", @"detail": @"无水印保存", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},
                @{@"identifier": @"DYYYCopyText", @"title": @"长按复制文案", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},
                @{@"identifier": @"DYYYCommentLivePhotoNotWaterMark", @"title": @"移除评论实况水印", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},
                @{@"identifier": @"DYYYCommentNotWaterMark", @"title": @"移除评论图片水印", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},
                @{@"identifier": @"DYYYisShowScheduleDisplay", @"title": @"显示视频进度", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},
                @{@"identifier": @"DYYYCommentCopyText", @"title": @"忽略艾特用户", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"}
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
            enhanceSettingsSection.itemArray = enhanceSettingsItems;

            viewModel.sectionDataArray = @[basicSettingsSection, uiSettingsSection, hideSettingsSection, removeSettingsSection, enhanceSettingsSection];
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