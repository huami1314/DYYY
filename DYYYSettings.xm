#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"
#import "DYYYManager.h"
#import <MobileCoreServices/MobileCoreServices.h>

// 导入所有弹窗类
#import "DYYYCustomInputView.h"
#import "DYYYOptionsSelectionView.h"
#import "DYYYAboutDialogView.h"
#import "DYYYIconOptionsDialogView.h"

@class DYYYIconOptionsDialogView;
static void showIconOptionsDialog(NSString *title, UIImage *previewImage, NSString *saveFilename, void (^onClear)(void), void (^onSelect)(void));

@interface DYYYImagePickerDelegate : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, copy) void (^completionBlock)(NSDictionary *info);
@end

@implementation DYYYImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (self.completionBlock) {
        self.completionBlock(info);
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end

@interface AWESettingBaseViewModel : NSObject
@end

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

@interface AWESettingsViewModel (DYYYAdditions)
- (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict;
- (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict cellTapHandlers:(NSMutableDictionary *)cellTapHandlers;
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

static AWESettingItemModel *createIconCustomizationItem(NSString *identifier, NSString *title, NSString *svgIconName, NSString *saveFilename) {
    AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
    item.identifier = identifier;
    item.title = title;
    
    // 检查图片是否存在，使用saveFilename
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];
    NSString *imagePath = [dyyyFolderPath stringByAppendingPathComponent:saveFilename];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
    item.detail = fileExists ? @"已设置" : @"默认";
    
    item.type = 0;
    item.svgIconImageName = svgIconName; // 使用传入的SVG图标名称
    item.cellType = 26;
    item.colorStyle = 0;
    item.isEnable = YES;
    item.cellTappedBlock = ^{
        // 创建文件夹（如果不存在）
        if (![[NSFileManager defaultManager] fileExistsAtPath:dyyyFolderPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dyyyFolderPath 
                                     withIntermediateDirectories:YES 
                                                      attributes:nil 
                                                           error:nil];
        }
        
        UIViewController *topVC = topView();
        
        // 加载预览图片(如果存在)
        UIImage *previewImage = nil;
        if (fileExists) {
            previewImage = [UIImage imageWithContentsOfFile:imagePath];
        }
        
        // 显示选项对话框 - 使用saveFilename作为参数传递
        showIconOptionsDialog(title, previewImage, saveFilename, ^{
            // 清除按钮回调
            if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:imagePath error:&error];
                if (!error) {
                    item.detail = @"默认";
                    
                    // 刷新表格视图
                    if ([topVC isKindOfClass:%c(AWESettingBaseViewController)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UITableView *tableView = nil;
                            for (UIView *subview in topVC.view.subviews) {
                                if ([subview isKindOfClass:[UITableView class]]) {
                                    tableView = (UITableView *)subview;
                                    break;
                                }
                            }
                            
                            if (tableView) {
                                [tableView reloadData];
                            }
                        });
                    }
                }
            }
        }, ^{
           // 选择按钮回调 - 打开图片选择器
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.allowsEditing = NO;
            picker.mediaTypes = @[@"public.image"]; 
            
            // 创建并设置代理
            DYYYImagePickerDelegate *pickerDelegate = [[DYYYImagePickerDelegate alloc] init];
            pickerDelegate.completionBlock = ^(NSDictionary *info) {
                UIImage *selectedImage = info[UIImagePickerControllerOriginalImage];
                if (selectedImage) {
                    // 确保路径存在
                    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                    NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];
                    NSString *imagePath = [dyyyFolderPath stringByAppendingPathComponent:saveFilename];
                    
                    // 保存图片
                    NSData *imageData = UIImagePNGRepresentation(selectedImage);
                    BOOL success = [imageData writeToFile:imagePath atomically:YES];
                    
                    if (success) {
                        // 更新UI
                        item.detail = @"已设置";
                        
                        // 确保在主线程刷新UI
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // 刷新表格视图
                            if ([topVC isKindOfClass:%c(AWESettingBaseViewController)]) {
                                UITableView *tableView = nil;
                                for (UIView *subview in topVC.view.subviews) {
                                    if ([subview isKindOfClass:[UITableView class]]) {
                                        tableView = (UITableView *)subview;
                                        break;
                                    }
                                }
                                
                                if (tableView) {
                                    [tableView reloadData];
                                }
                            }
                        });
                    }
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

// 显示自定义关于弹窗
static void showAboutDialog(NSString *title, NSString *message, void (^onConfirm)(void)) {
    DYYYAboutDialogView *aboutDialog = [[DYYYAboutDialogView alloc] initWithTitle:title message:message];
    aboutDialog.onConfirm = onConfirm;
    [aboutDialog show];
}

static void showTextInputAlert(NSString *title, void (^onConfirm)(NSString *text), void (^onCancel)(void));
static void showTextInputAlert(NSString *title, NSString *defaultText, void (^onConfirm)(NSString *text), void (^onCancel)(void));
static void showTextInputAlert(NSString *title, NSString *defaultText, NSString *placeholder, void (^onConfirm)(NSString *text), void (^onCancel)(void));

static void showTextInputAlert(NSString *title, NSString *defaultText, NSString *placeholder, void (^onConfirm)(NSString *text), void (^onCancel)(void)) {
    DYYYCustomInputView *inputView = [[DYYYCustomInputView alloc] initWithTitle:title defaultText:defaultText placeholder:placeholder];
    inputView.onConfirm = onConfirm;
    inputView.onCancel = onCancel;
    [inputView show];
}

static void showTextInputAlert(NSString *title, NSString *defaultText, void (^onConfirm)(NSString *text), void (^onCancel)(void)) {
    showTextInputAlert(title, defaultText, nil, onConfirm, onCancel);
}

static void showTextInputAlert(NSString *title, void (^onConfirm)(NSString *text), void (^onCancel)(void)) {
    showTextInputAlert(title, nil, nil, onConfirm, onCancel);
}

// 显示自定义选项选择视图
static void showOptionsSelectionSheet(UIViewController *viewController, NSArray<NSString *> *options, NSString *title, void (^onSelect)(NSInteger selectedIndex, NSString *selectedValue)) {
    // 确保选项数组正确
    if (!options || options.count == 0) {
        options = @[@"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x", @"2.5x", @"3.0x"];
    }
    
    DYYYOptionsSelectionView *selectionView = [[DYYYOptionsSelectionView alloc] initWithTitle:title options:options];
    selectionView.onSelect = onSelect;
    [selectionView show];
}

// 获取和设置用户偏好
static bool getUserDefaults(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

static void setUserDefaults(id object, NSString *key) {
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 显示图标选项弹窗
static void showIconOptionsDialog(NSString *title, UIImage *previewImage, NSString *saveFilename, void (^onClear)(void), void (^onSelect)(void)) {
    DYYYIconOptionsDialogView *optionsDialog = [[DYYYIconOptionsDialogView alloc] initWithTitle:title previewImage:previewImage];
    optionsDialog.onClear = onClear;
    optionsDialog.onSelect = onSelect;
    [optionsDialog show];
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

static AWESettingBaseViewController* createSubSettingsViewController(NSString* title, NSArray* sectionsArray) {
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
    viewModel.sectionDataArray = sectionsArray;
    objc_setAssociatedObject(settingsVC, kViewModelKey, viewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return settingsVC;
}

// 创建一个section的辅助方法
static AWESettingSectionModel* createSection(NSString* title, NSArray* items) {
    AWESettingSectionModel *section = [[%c(AWESettingSectionModel) alloc] init];
    section.sectionHeaderTitle = title;
    section.sectionHeaderHeight = 40;
    section.type = 0;
    section.itemArray = items;
    return section;
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
        dyyyItem.detail = @"v2.2-2";
        dyyyItem.type = 0;
        dyyyItem.svgIconImageName = @"ic_sapling_outlined";
        dyyyItem.cellType = 26;
        dyyyItem.colorStyle = 2;
        dyyyItem.isEnable = YES;
        dyyyItem.cellTappedBlock = ^{
            UIViewController *rootVC = self.controllerDelegate;
            AWESettingBaseViewController *settingsVC = [[%c(AWESettingBaseViewController) alloc] init];
            BOOL hasAgreed = getUserDefaults(@"DYYYUserAgreementAccepted");
            if (!hasAgreed) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [DYYYManager showToast:@"当前设置无法生效，因为您还没有前往旧版界面同意使用协议。"];
                });
            }

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
            mainSection.sectionHeaderTitle = @"功能";
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
                NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];
                
                // 【外观设置】分类
                NSMutableArray<AWESettingItemModel *> *appearanceItems = [NSMutableArray array];
                NSArray *appearanceSettings = @[
                    @{@"identifier": @"DYYYEnableDanmuColor", @"title": @"启用弹幕改色", @"detail": @"", @"cellType": @6, @"imageName": @"ic_dansquare_outlined_20"},
                    @{@"identifier": @"DYYYdanmuColor", @"title": @"自定弹幕颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_dansquarenut_outlined_20"},
                    @{@"identifier": @"DYYYLabelColor", @"title": @"时间标签颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_clock_outlined_20"},
               ];
                
                for (NSDictionary *dict in appearanceSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict cellTapHandlers:cellTapHandlers];
                    [appearanceItems addObject:item];
                }
                
                // 【视频播放设置】分类
                NSMutableArray<AWESettingItemModel *> *videoItems = [NSMutableArray array];
                NSArray *videoSettings = @[
                    @{@"identifier": @"DYYYisShowScheduleDisplay", @"title": @"显示进度时长", @"detail": @"", @"cellType": @6, @"imageName": @"ic_playertime_outlined_20"},
                    @{@"identifier": @"DYYYScheduleStyle", @"title": @"进度时长样式", @"detail": @"", @"cellType": @26, @"imageName": @"ic_playertime_outlined_20"},
                    @{@"identifier": @"DYYYTimelineVerticalPosition", @"title": @"时长纵轴位置", @"detail": @"-12.5", @"cellType": @26, @"imageName": @"ic_playertime_outlined_20"},
                    @{@"identifier": @"DYYYHideVideoProgress", @"title": @"隐藏视频进度", @"detail": @"", @"cellType": @6, @"imageName": @"ic_playertime_outlined_20"},
                    @{@"identifier": @"DYYYisEnableAutoPlay", @"title": @"启用自动播放", @"detail": @"", @"cellType": @6, @"imageName": @"ic_play_outlined_12"},
                    @{@"identifier": @"DYYYDefaultSpeed", @"title": @"设置默认倍速", @"detail": @"", @"cellType": @26, @"imageName": @"ic_speed_outlined_20"},
                    @{@"identifier": @"DYYYisEnableArea", @"title": @"时间属地显示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_location_outlined_20"}
                ];
                
                for (NSDictionary *dict in videoSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict cellTapHandlers:cellTapHandlers];
                    
                    // 特殊处理默认倍速选项，使用showOptionsSelectionSheet而不是输入框
                    if ([item.identifier isEqualToString:@"DYYYDefaultSpeed"]) {
                        // 获取已保存的默认倍速值
                        NSString *savedSpeed = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDefaultSpeed"];
                        item.detail = savedSpeed ?: @"1.0x";
                        item.cellTappedBlock = ^{
                            NSArray *speedOptions = @[@"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x", @"2.5x", @"3.0x"];
                            showOptionsSelectionSheet(topView(), speedOptions, @"选择默认倍速", ^(NSInteger selectedIndex, NSString *selectedValue) {
                                setUserDefaults(selectedValue, @"DYYYDefaultSpeed");
                                
                                // 更新UI
                                item.detail = selectedValue;
                                UIViewController *topVC = topView();
                                if ([topVC isKindOfClass:%c(AWESettingBaseViewController)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        UITableView *tableView = nil;
                                        for (UIView *subview in topVC.view.subviews) {
                                            if ([subview isKindOfClass:[UITableView class]]) {
                                                tableView = (UITableView *)subview;
                                                break;
                                            }
                                        }
                                        
                                        if (tableView) {
                                            [tableView reloadData];
                                        }
                                    });
                                }
                            });
                        };
                    }
                    // 添加对进度时长样式的特殊处理
                    else if ([item.identifier isEqualToString:@"DYYYScheduleStyle"]) {
                        NSString *savedStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
                        item.detail = savedStyle ?: @"默认";
                        item.cellTappedBlock = ^{
                            NSArray *styleOptions = @[@"进度条两侧上下", @"进度条两侧左右", @"进度条右侧剩余", @"进度条右侧完整"];
                            showOptionsSelectionSheet(topView(), styleOptions, @"选择进度时长样式", ^(NSInteger selectedIndex, NSString *selectedValue) {
                                setUserDefaults(selectedValue, @"DYYYScheduleStyle");
                                
                                // 更新UI
                                item.detail = selectedValue;
                                UIViewController *topVC = topView();
                                if ([topVC isKindOfClass:%c(AWESettingBaseViewController)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        UITableView *tableView = nil;
                                        for (UIView *subview in topVC.view.subviews) {
                                            if ([subview isKindOfClass:[UITableView class]]) {
                                                tableView = (UITableView *)subview;
                                                break;
                                            }
                                        }
                                        
                                        if (tableView) {
                                            [tableView reloadData];
                                        }
                                    });
                                }
                            });
                        };
                    }
                    
                    [videoItems addObject:item];
                }
                // 【杂项设置】分类
                NSMutableArray<AWESettingItemModel *> *miscellaneousItems = [NSMutableArray array];
                NSArray *miscellaneousSettings = @[
                    @{@"identifier": @"DYYYisDarkKeyBoard", @"title": @"启用深色键盘", @"detail": @"", @"cellType": @6, @"imageName": @"ic_keyboard_outlined"},
                    @{@"identifier": @"DYYYisHideStatusbar", @"title": @"隐藏系统顶栏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisEnablePure", @"title": @"启用首页净化", @"detail": @"", @"cellType": @6, @"imageName": @"ic_broom_outlined"},
                    @{@"identifier": @"DYYYisEnableFullScreen", @"title": @"启用首页全屏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_fullscreen_outlined_16"}
                ];
                
                for (NSDictionary *dict in miscellaneousSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict cellTapHandlers:cellTapHandlers];
                    [miscellaneousItems addObject:item];
                }
                // 【过滤与屏蔽】分类
                NSMutableArray<AWESettingItemModel *> *filterItems = [NSMutableArray array];
                NSArray *filterSettings = @[
                    @{@"identifier": @"DYYYisSkipLive", @"title": @"推荐过滤直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_video_outlined_20"},
                    @{@"identifier": @"DYYYisSkipHotSpot", @"title": @"推荐过滤热点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_squaretriangletwo_outlined_20"},
                    @{@"identifier": @"DYYYfilterLowLikes", @"title": @"推荐过滤低赞", @"detail": @"0", @"cellType": @26, @"imageName": @"ic_thumbsdown_outlined_20"},
                    @{@"identifier": @"DYYYfilterKeywords", @"title": @"推荐过滤文案", @"detail": @"", @"cellType": @26, @"imageName": @"ic_tag_outlined_20"},
                    @{@"identifier": @"DYYYNoAds", @"title": @"启用屏蔽广告", @"detail": @"", @"cellType": @6, @"imageName": @"ic_ad_outlined_20"},
                    @{@"identifier": @"DYYYNoUpdates", @"title": @"屏蔽检测更新", @"detail": @"", @"cellType": @6, @"imageName": @"ic_circletop_outlined"},
                    @{@"identifier": @"DYYYHideteenmode", @"title": @"屏蔽青少年模式弹窗", @"detail": @"", @"cellType": @6, @"imageName": @"ic_personcircleclean_outlined_20"}
                ];
                
                for (NSDictionary *dict in filterSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict cellTapHandlers:cellTapHandlers];

                    if ([item.identifier isEqualToString:@"DYYYfilterLowLikes"]) {
                        NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterLowLikes"];
                        item.detail = savedValue ?: @"0";
                        item.cellTappedBlock = ^{
                            showTextInputAlert(@"设置过滤赞数阈值", item.detail, @"填0关闭功能", ^(NSString *text) {
                                NSScanner *scanner = [NSScanner scannerWithString:text];
                                NSInteger value;
                                BOOL isValidNumber = [scanner scanInteger:&value] && [scanner isAtEnd];
                                
                                if (isValidNumber) {
                                    if (value < 0) value = 0;
                                    NSString *valueString = [NSString stringWithFormat:@"%ld", (long)value];
                                    setUserDefaults(valueString, @"DYYYfilterLowLikes");

                                    item.detail = valueString;
                                    UIViewController *topVC = topView();
                                    if ([topVC isKindOfClass:%c(AWESettingBaseViewController)]) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            UITableView *tableView = nil;
                                            for (UIView *subview in topVC.view.subviews) {
                                                if ([subview isKindOfClass:[UITableView class]]) {
                                                    tableView = (UITableView *)subview;
                                                    break;
                                                }
                                            }
                                            
                                            if (tableView) {
                                                [tableView reloadData];
                                            }
                                        });
                                    }
                                } else {
                                    DYYYAboutDialogView *errorDialog = [[DYYYAboutDialogView alloc] initWithTitle:@"输入错误" message:@"请输入有效的数字\n\n\n"];
                                    [errorDialog show];
                                }
                            }, nil);
                        };
                    } else if ([item.identifier isEqualToString:@"DYYYfilterKeywords"]) {
                        NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"];
                        item.detail = savedValue ?: @"";
                        item.cellTappedBlock = ^{
                            showTextInputAlert(@"设置过滤关键词", item.detail, @"用半角逗号(,)分隔关键词", ^(NSString *text) {
                                NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                setUserDefaults(trimmedText, @"DYYYfilterKeywords");
                                item.detail = trimmedText ?: @"";
                                UIViewController *topVC = topView();
                                if ([topVC isKindOfClass:%c(AWESettingBaseViewController)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        UITableView *tableView = nil;
                                        for (UIView *subview in topVC.view.subviews) {
                                            if ([subview isKindOfClass:[UITableView class]]) {
                                                tableView = (UITableView *)subview;
                                                break;
                                            }
                                        }
                                        if (tableView) {
                                            [tableView reloadData];
                                        }
                                    });
                                }
                            }, nil);
                        };
                    }
                    [filterItems addObject:item];
                }

                // 【二次确认】分类
                NSMutableArray<AWESettingItemModel *> *securityItems = [NSMutableArray array];
                NSArray *securitySettings = @[
                    @{@"identifier": @"DYYYfollowTips", @"title": @"关注二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_userplus_outlined_20"},
                    @{@"identifier": @"DYYYcollectTips", @"title": @"收藏二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_collection_outlined_20"}
                ];
                
                for (NSDictionary *dict in securitySettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict cellTapHandlers:cellTapHandlers];
                    [securityItems addObject:item];
                }
                
                // 创建并组织所有section
                NSMutableArray *sections = [NSMutableArray array];
                [sections addObject:createSection(@"外观设置", appearanceItems)];
                [sections addObject:createSection(@"视频播放", videoItems)];
                [sections addObject:createSection(@"杂项设置", miscellaneousItems)];
                [sections addObject:createSection(@"过滤与屏蔽", filterItems)];
                [sections addObject:createSection(@"二次确认", securityItems)];
                
                // 创建并推入二级设置页面
                AWESettingBaseViewController *subVC = createSubSettingsViewController(@"基本设置", sections);
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
                NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];
                
                // 【透明度设置】分类
                NSMutableArray<AWESettingItemModel *> *transparencyItems = [NSMutableArray array];
                NSArray *transparencySettings = @[
                    @{@"identifier": @"DYYYtopbartransparent", @"title": @"设置顶栏透明", @"detail": @"0-1小数", @"cellType": @26, @"imageName": @"ic_module_outlined_20"},
                    @{@"identifier": @"DYYYGlobalTransparency", @"title": @"设置全局透明", @"detail": @"0-1小数", @"cellType": @26, @"imageName": @"ic_eye_outlined_20"},
                    @{@"identifier": @"DYYYisEnableCommentBlur", @"title": @"评论区毛玻璃", @"detail": @"", @"cellType": @6, @"imageName": @"ic_comment_outlined_20"}, 
                    @{@"identifier": @"DYYYCommentBlurTransparent", @"title": @"毛玻璃透明度", @"detail": @"0-1小数", @"cellType": @26, @"imageName": @"ic_eye_outlined_20"}      
                ];
                
                for (NSDictionary *dict in transparencySettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict cellTapHandlers:cellTapHandlers];
                    [transparencyItems addObject:item];
                }
                
                // 【缩放与大小】分类
                NSMutableArray<AWESettingItemModel *> *scaleItems = [NSMutableArray array];
                NSArray *scaleSettings = @[
                    @{@"identifier": @"DYYYElementScale", @"title": @"右侧栏缩放度", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_zoomin_outlined_20"},
                    @{@"identifier": @"DYYYNicknameScale", @"title": @"昵称文案缩放", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_zoomin_outlined_20"},
                    @{@"identifier": @"DYYYNicknameVerticalOffset", @"title": @"昵称下移距离", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_pensketch_outlined_20"},
                    @{@"identifier": @"DYYYDescriptionVerticalOffset", @"title": @"文案下移距离", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_pensketch_outlined_20"},
                    @{@"identifier": @"DYYYIPLeftShiftOffset", @"title": @"属地左移距离", @"detail": @"", @"cellType": @26, @"imageName": @"ic_pensketch_outlined_20"},
                ];
                
                for (NSDictionary *dict in scaleSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict cellTapHandlers:cellTapHandlers];
                    [scaleItems addObject:item];
                }
                
                // 【标题自定义】分类
                NSMutableArray<AWESettingItemModel *> *titleItems = [NSMutableArray array];
                NSArray *titleSettings = @[
                    @{@"identifier": @"DYYYIndexTitle", @"title": @"设置首页标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_horizontalbook_outlined_20"},
                    @{@"identifier": @"DYYYFriendsTitle", @"title": @"设置朋友标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_usertwo_outlined_20"},
                    @{@"identifier": @"DYYYMsgTitle", @"title": @"设置消息标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_msg_outlined_20"},
                    @{@"identifier": @"DYYYSelfTitle", @"title": @"设置我的标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_user_outlined_20"},
                ];
                
                for (NSDictionary *dict in titleSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict cellTapHandlers:cellTapHandlers];
                    [titleItems addObject:item];
                }

                // 【图标自定义】分类
                NSMutableArray<AWESettingItemModel *> *iconItems = [NSMutableArray array];
                
                // 添加图标自定义项
                [iconItems addObject:createIconCustomizationItem(@"DYYYIconLikeBefore", @"未点赞图标", @"ic_heart_outlined_20", @"like_before.png")];
                [iconItems addObject:createIconCustomizationItem(@"DYYYIconLikeAfter", @"已点赞图标", @"ic_heart_filled_20", @"like_after.png")];
                [iconItems addObject:createIconCustomizationItem(@"DYYYIconComment", @"评论图标", @"ic_comment_outlined_20", @"comment.png")];
                [iconItems addObject:createIconCustomizationItem(@"DYYYIconUnfavorite", @"未收藏图标", @"ic_star_outlined_20", @"unfavorite.png")];
                [iconItems addObject:createIconCustomizationItem(@"DYYYIconFavorite", @"已收藏图标", @"ic_star_filled_20", @"favorite.png")];
                [iconItems addObject:createIconCustomizationItem(@"DYYYIconShare", @"分享图标", @"ic_share_outlined", @"share.png")];
                                
                // 将图标自定义section添加到sections数组
                NSMutableArray *sections = [NSMutableArray array];
                [sections addObject:createSection(@"透明度设置", transparencyItems)];
                [sections addObject:createSection(@"缩放与大小", scaleItems)];
                [sections addObject:createSection(@"标题自定义", titleItems)];
                [sections addObject:createSection(@"图标自定义", iconItems)];
                // 创建并组织所有section
                // 创建并推入二级设置页面
                AWESettingBaseViewController *subVC = createSubSettingsViewController(@"界面设置", sections);
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
                
                // 【主界面元素】分类
                NSMutableArray<AWESettingItemModel *> *mainUiItems = [NSMutableArray array];
                NSArray *mainUiSettings = @[
                    @{@"identifier": @"DYYYisHiddenBottomBg", @"title": @"隐藏底栏背景", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenBottomDot", @"title": @"隐藏底栏红点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideShopButton", @"title": @"隐藏底栏商城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideMessageButton", @"title": @"隐藏底栏消息", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideFriendsButton", @"title": @"隐藏底栏朋友", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenJia", @"title": @"隐藏底栏加号", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"}
                ];
                
                for (NSDictionary *dict in mainUiSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict];
                    [mainUiItems addObject:item];
                }
                
                // 【视频播放界面】分类
                NSMutableArray<AWESettingItemModel *> *videoUiItems = [NSMutableArray array];
                NSArray *videoUiSettings = @[
                    @{@"identifier": @"DYYYHideLOTAnimationView", @"title": @"隐藏头像加号", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideLikeLabel", @"title": @"隐藏点赞数值", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideCommentLabel", @"title": @"隐藏评论数值", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideCollectLabel", @"title": @"隐藏收藏数值", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideShareLabel", @"title": @"隐藏分享数值", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideCommentButton", @"title": @"隐藏评论按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideCollectButton", @"title": @"隐藏收藏按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideShareButton", @"title": @"隐藏分享按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideAvatarButton", @"title": @"隐藏头像按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideMusicButton", @"title": @"隐藏音乐按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenEntry", @"title": @"隐藏全屏观看", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"}
                ];
                
                for (NSDictionary *dict in videoUiSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict];
                    [videoUiItems addObject:item];
                }
                
                // 【侧边栏】分类
                NSMutableArray<AWESettingItemModel *> *sidebarItems = [NSMutableArray array];
                NSArray *sidebarSettings = @[
                    @{@"identifier": @"DYYYisHiddenSidebarDot", @"title": @"隐藏侧栏红点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenLeftSideBar", @"title": @"隐藏左侧边栏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                ];
                
                for (NSDictionary *dict in sidebarSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict];
                    [sidebarItems addObject:item];
                }

                // 【消息页与我的页】分类
                NSMutableArray<AWESettingItemModel *> *messageAndMineItems = [NSMutableArray array];
                NSArray *messageAndMineSettings = @[
                    @{@"identifier": @"DYYYHidePushBanner", @"title": @"隐藏通知权限提示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenAvatarList", @"title": @"隐藏消息头像列表", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYisHiddenAvatarBubble", @"title": @"隐藏消息头像气泡", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideGroupShop", @"title": @"隐藏群聊商店按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYGroupLiving", @"title": @"隐藏群头像直播中", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideGroupInputActionBar", @"title": @"隐藏群聊页工具栏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHidePostView", @"title": @"隐藏我的页发作品", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"}
                ];
                for (NSDictionary *dict in messageAndMineSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict];
                    [messageAndMineItems addObject:item];
                }

                // 【提示与位置信息】分类
                NSMutableArray<AWESettingItemModel *> *infoItems = [NSMutableArray array];
                NSArray *infoSettings = @[
                    @{@"identifier": @"DYYYHidenLiveView", @"title": @"隐藏关注顶端", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideMenuView", @"title": @"隐藏同城顶端", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideNearbyCapsuleView", @"title": @"隐藏吃喝玩乐", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideDiscover", @"title": @"隐藏右上搜索", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideInteractionSearch", @"title": @"隐藏相关搜索", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideEnterLive", @"title": @"隐藏进入直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideDanmuButton", @"title": @"隐藏弹幕按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideCancelMute", @"title": @"隐藏静音按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideLocation", @"title": @"隐藏视频定位", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideQuqishuiting", @"title": @"隐藏去汽水听", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideGongChuang", @"title": @"隐藏共创头像", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideHotspot", @"title": @"隐藏热点提示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideRecommendTips", @"title": @"隐藏推荐提示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideBottomRelated", @"title": @"隐藏底部相关", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},                    
                    @{@"identifier": @"DYYYHideShareContentView", @"title": @"隐藏分享提示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideAntiAddictedNotice", @"title": @"隐藏作者声明", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideFeedAnchorContainer", @"title": @"隐藏拍摄同款", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideChallengeStickers", @"title": @"隐藏挑战贴纸", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideTemplateTags", @"title": @"隐藏校园提示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideHisShop", @"title": @"隐藏作者店铺", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideConcernCapsuleView", @"title": @"隐藏关注直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHidentopbarprompt", @"title": @"隐藏顶栏横线", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideTemplateVideo", @"title": @"隐藏视频合集", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideTemplatePlaylet", @"title": @"隐藏短剧合集", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideLiveGIF", @"title": @"隐藏动图标签", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideItemTag", @"title": @"隐藏笔记标签", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideTemplateGroup", @"title": @"隐藏底部话题", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideCameraLocation", @"title": @"隐藏相机定位", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideLiveCapsuleView", @"title": @"隐藏直播胶囊", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"},
                    @{@"identifier": @"DYYYHideStoryProgressSlide", @"title": @"隐藏视频滑条", @"detail": @"", @"cellType": @6, @"imageName": @"ic_eyeslash_outlined_16"}
                ];
                
                for (NSDictionary *dict in infoSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict];
                    [infoItems addObject:item];
                }
                
                // 创建并组织所有section
                NSMutableArray *sections = [NSMutableArray array];
                [sections addObject:createSection(@"主界面元素", mainUiItems)];
                [sections addObject:createSection(@"视频播放界面", videoUiItems)];
                [sections addObject:createSection(@"侧边栏元素", sidebarItems)];
                [sections addObject:createSection(@"消息页与我的页", messageAndMineItems)];
                [sections addObject:createSection(@"提示与位置信息", infoItems)];
                
                // 创建并推入二级设置页面
                AWESettingBaseViewController *subVC = createSubSettingsViewController(@"隐藏设置", sections);
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
                @{@"identifier": @"DYYYHideHangout", @"title": @"移除经验", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"},
                @{@"identifier": @"DYYYHidePlaylet", @"title": @"移除短剧", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_20"}
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
            
            NSMutableArray *sections = [NSMutableArray array];
            [sections addObject:createSection(@"顶栏选项", removeSettingsItems)];
            
            // 创建并推入二级设置页面，使用sections数组而不是直接使用removeSettingsItems
            AWESettingBaseViewController *subVC = createSubSettingsViewController(@"顶栏移除", sections);
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
                
                // 【复制功能】分类
                NSMutableArray<AWESettingItemModel *> *copyItems = [NSMutableArray array];
                NSArray *copySettings = @[
                    @{@"identifier": @"DYYYCopyText", @"title": @"长按面板复制功能", @"detail": @"", @"cellType": @6, @"imageName": @"ic_rectangleonrectangleup_outlined_20"},
                    @{@"identifier": @"DYYYCommentCopyText", @"title": @"长按评论复制文案", @"detail": @"", @"cellType": @6, @"imageName": @"ic_at_outlined_20"}
                ];
                
                for (NSDictionary *dict in copySettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict];
                    [copyItems addObject:item];
                }
                
                // 【媒体保存】分类
                NSMutableArray<AWESettingItemModel *> *downloadItems = [NSMutableArray array];
                NSArray *downloadSettings = @[
                    @{@"identifier": @"DYYYLongPressDownload", @"title": @"长按面板保存媒体", @"detail": @"无水印保存", @"cellType": @6, @"imageName": @"ic_boxarrowdown_outlined"},
                    @{@"identifier": @"DYYYInterfaceDownload", @"title": @"接口解析保存媒体", @"detail": @"不填关闭", @"cellType": @26, @"imageName": @"ic_cloudarrowdown_outlined_20"},
                    @{@"identifier": @"DYYYShowAllVideoQuality", @"title": @"接口显示清晰选项", @"detail": @"", @"cellType": @6, @"imageName": @"ic_hamburgernut_outlined_20"},
                    @{@"identifier": @"DYYYCommentLivePhotoNotWaterMark", @"title": @"移除评论实况水印", @"detail": @"", @"cellType": @6, @"imageName": @"ic_livephoto_outlined_20"},
                    @{@"identifier": @"DYYYCommentNotWaterMark", @"title": @"移除评论图片水印", @"detail": @"", @"cellType": @6, @"imageName": @"ic_removeimage_outlined_20"},
                    @{@"identifier": @"DYYYFourceDownloadEmotion", @"title": @"保存评论区表情包", @"detail": @"", @"cellType": @6, @"imageName": @"ic_emoji_outlined"}
                ];
                
                for (NSDictionary *dict in downloadSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict];
                    
                    // 特殊处理接口解析保存媒体选项
                    if ([item.identifier isEqualToString:@"DYYYInterfaceDownload"]) {
                        // 获取已保存的接口URL
                        NSString *savedURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
                        item.detail = savedURL.length > 0 ? savedURL : @"不填关闭";
                        
                        item.cellTappedBlock = ^{
                            NSString *defaultText = [item.detail isEqualToString:@"不填关闭"] ? @"" : item.detail;
                            showTextInputAlert(@"设置媒体解析接口", defaultText, @"解析接口以url=结尾", ^(NSString *text) {
                                // 保存用户输入的接口URL
                                NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                setUserDefaults(trimmedText, @"DYYYInterfaceDownload");
                                
                                // 更新UI显示
                                item.detail = trimmedText.length > 0 ? trimmedText : @"不填关闭";
                                
                                // 刷新设置表格
                                UIViewController *topVC = topView();
                                if ([topVC isKindOfClass:%c(AWESettingBaseViewController)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        UITableView *tableView = nil;
                                        for (UIView *subview in topVC.view.subviews) {
                                            if ([subview isKindOfClass:[UITableView class]]) {
                                                tableView = (UITableView *)subview;
                                                break;
                                            }
                                        }
                                        
                                        if (tableView) {
                                            [tableView reloadData];
                                        }
                                    });
                                }
                            }, nil);
                        };
                    }
                    
                    [downloadItems addObject:item];
                }

                // 【交互增强】分类
                NSMutableArray<AWESettingItemModel *> *interactionItems = [NSMutableArray array];
                NSArray *interactionSettings = @[
                    @{@"identifier": @"DYYYDisableHomeRefresh", @"title": @"禁用点击首页刷新", @"detail": @"", @"cellType": @6, @"imageName": @"ic_arrowcircle_outlined_20"},
                    @{@"identifier": @"DYYYDouble", @"title": @"禁用双击视频点赞", @"detail": @"", @"cellType": @6, @"imageName": @"ic_thumbsup_outlined_20"},
                    @{@"identifier": @"DYYYEnableDoubleOpenComment", @"title": @"启用双击打开评论", @"detail": @"", @"cellType": @6, @"imageName": @"ic_comment_outlined_20"},
                    @{@"identifier": @"DYYYEnableDoubleOpenAlertController", @"title": @"启用双击打开菜单", @"detail": @"", @"cellType": @26, @"imageName": @"ic_xiaoxihuazhonghua_outlined_20"}
                ];
                
                for (NSDictionary *dict in interactionSettings) {
                    AWESettingItemModel *item = [self createSettingItem:dict];
                    // 为双击菜单选项添加特殊处理
                    if ([item.identifier isEqualToString:@"DYYYEnableDoubleOpenAlertController"]) {
                        item.cellTappedBlock = ^{
                            NSMutableArray<AWESettingItemModel *> *doubleTapItems = [NSMutableArray array];
                            AWESettingItemModel *enableDoubleTapMenu = [self createSettingItem:@{
                                @"identifier": @"DYYYEnableDoubleOpenAlertController", 
                                @"title": @"启用双击打开菜单", 
                                @"detail": @"", 
                                @"cellType": @6, 
                                @"imageName": @"ic_xiaoxihuazhonghua_outlined_20"
                            }];
                            [doubleTapItems addObject:enableDoubleTapMenu];
                            
                            NSArray *doubleTapFunctions = @[
                                @{@"identifier": @"DYYYDoubleTapDownload", @"title": @"保存视频/图片", @"detail": @"", @"cellType": @6, @"imageName": @"ic_boxarrowdown_outlined"},
                                @{@"identifier": @"DYYYDoubleTapDownloadAudio", @"title": @"保存音频", @"detail": @"", @"cellType": @6, @"imageName": @"ic_boxarrowdown_outlined"},
                                @{@"identifier": @"DYYYDoubleInterfaceDownload", @"title": @"接口保存", @"detail": @"", @"cellType": @6, @"imageName": @"ic_cloudarrowdown_outlined_20"},
                                @{@"identifier": @"DYYYDoubleTapCopyDesc", @"title": @"复制文案", @"detail": @"", @"cellType": @6, @"imageName": @"ic_rectangleonrectangleup_outlined_20"},
                                @{@"identifier": @"DYYYDoubleTapComment", @"title": @"打开评论", @"detail": @"", @"cellType": @6, @"imageName": @"ic_comment_outlined_20"},
                                @{@"identifier": @"DYYYDoubleTapLike", @"title": @"点赞视频", @"detail": @"", @"cellType": @6, @"imageName": @"ic_heart_outlined_20"},
                            ];
                            
                            for (NSDictionary *dict in doubleTapFunctions) {
                                AWESettingItemModel *functionItem = [self createSettingItem:dict];
                                [doubleTapItems addObject:functionItem];
                            }
                            NSMutableArray *sections = [NSMutableArray array];
                            [sections addObject:createSection(@"双击菜单设置", doubleTapItems)];
                            UIViewController *rootVC = self.controllerDelegate;
                            AWESettingBaseViewController *subVC = createSubSettingsViewController(@"双击菜单设置", sections);
                            [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
                        };
                    }
                    
                    [interactionItems addObject:item];
                }
                
                // 创建并组织所有section
                NSMutableArray *sections = [NSMutableArray array];
                [sections addObject:createSection(@"复制功能", copyItems)];
                [sections addObject:createSection(@"媒体保存", downloadItems)];
                [sections addObject:createSection(@"交互增强", interactionItems)];
                // 创建并推入二级设置页面
                AWESettingBaseViewController *subVC = createSubSettingsViewController(@"增强设置", sections);
                [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
            };

            [mainItems addObject:enhanceSettingItem];
            
            // 创建关于分类（单独section）
            AWESettingSectionModel *aboutSection = [[%c(AWESettingSectionModel) alloc] init];
            aboutSection.sectionHeaderTitle = @"关于";
            aboutSection.sectionHeaderHeight = 40;
            aboutSection.type = 0;
            NSMutableArray<AWESettingItemModel *> *aboutItems = [NSMutableArray array];
            
            // 添加关于
            AWESettingItemModel *aboutItem = [[%c(AWESettingItemModel) alloc] init];
            aboutItem.identifier = @"DYYYAbout";
            aboutItem.title = @"关于插件";
            aboutItem.detail = @"v2.2-2";
            aboutItem.type = 0;
            aboutItem.iconImageName = @"awe-settings-icon-about";
            aboutItem.cellType = 26;
            aboutItem.colorStyle = 0;
            aboutItem.isEnable = YES;
            aboutItem.cellTappedBlock = ^{
                showAboutDialog(@"关于DYYY", 
                    @"版本: v2.2-2\n\n"
                    @"感谢使用DYYY\n\n"
                    @"@维他入我心 基于DYYY二次开发\n\n"
                    @"Telegram@vita_app\n\n"
                    @"开源地址@Wtrwx\n\n" 
                    @"感谢Huami开源\n\n"
                    @"开源地址@huami1314\n\n"
                    @"感谢huami group中群友的支持赞助\n\n"
                    @"Telegram@huami group\n\n" , nil);
            };
            [aboutItems addObject:aboutItem];
            
            AWESettingItemModel *licenseItem = [[%c(AWESettingItemModel) alloc] init];
            licenseItem.identifier = @"DYYYLicense";
            licenseItem.title = @"开源协议";
            licenseItem.detail = @"MIT License";
            licenseItem.type = 0;
            licenseItem.iconImageName = @"awe-settings-icon-opensource-notice";
            licenseItem.cellType = 26;
            licenseItem.colorStyle = 0;
            licenseItem.isEnable = YES;
            licenseItem.cellTappedBlock = ^{
                showAboutDialog(@"MIT License", 
                    @"Copyright (c) 2024 huami.\n\n"
                    @"Permission is hereby granted, free of charge, to any person obtaining a copy "
                    @"of this software and associated documentation files (the \"Software\"), to deal "
                    @"in the Software without restriction, including without limitation the rights "
                    @"to use, copy, modify, merge, publish, distribute, sublicense, and/or sell "
                    @"copies of the Software, and to permit persons to whom the Software is "
                    @"furnished to do so, subject to the following conditions:\n\n"
                    @"The above copyright notice and this permission notice shall be included in all "
                    @"copies or substantial portions of the Software.\n\n"
                    @"THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR "
                    @"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, "
                    @"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE "
                    @"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER "
                    @"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, "
                    @"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE "
                    @"SOFTWARE.", nil);
            };
            [aboutItems addObject:licenseItem];
            mainSection.itemArray = mainItems;
            aboutSection.itemArray = aboutItems;
            
            viewModel.sectionDataArray = @[mainSection, aboutSection];
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

%new
- (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict {
    return [self createSettingItem:dict cellTapHandlers:nil];
}

%new
- (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict cellTapHandlers:(NSMutableDictionary *)cellTapHandlers {
    AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
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
    item.isSwitchOn = getUserDefaults(item.identifier);
    
    if (item.cellType == 26 && cellTapHandlers != nil) {
        cellTapHandlers[item.identifier] = ^{
            // 使用新的方法，传递占位符
            showTextInputAlert(item.title, item.detail, placeholder, ^(NSString *text) {
                setUserDefaults(text, item.identifier);
                // 更新item的detail属性
                item.detail = text;
                
                // 查找当前视图控制器并刷新设置表格
                UIViewController *topVC = topView();
                if ([topVC isKindOfClass:%c(AWESettingBaseViewController)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UITableView *tableView = nil;
                        for (UIView *subview in topVC.view.subviews) {
                            if ([subview isKindOfClass:[UITableView class]]) {
                                tableView = (UITableView *)subview;
                                break;
                            }
                        }
                        
                        if (tableView) {
                            [tableView reloadData];
                        }
                    });
                }
            }, nil);
        };
        item.cellTappedBlock = cellTapHandlers[item.identifier];
    } else if (item.cellType == 6) {
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
    
    return item;
}
%end
