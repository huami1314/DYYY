//
// WCPLSettingViewController.m
//
// Created by dyf on 17/4/6.
// Copyright © 2017 dyf. All rights reserved.
//

#import "WCPLSettingViewController.h"
#import "WCPLRedEnvelopConfig.h"
#import "WCPLMultiSelectGroupsViewController.h"
#import "WCPLFuncService.h"
#import "WeChatRedEnvelop.h"
#import "MapViewController.h"

#import <objc/objc-runtime.h>

@interface WCPLSettingViewController () <MultiSelectGroupsViewControllerDelegate>

@property (nonatomic, strong) WCTableViewManager *tableViewMgr;
- (BOOL)isInContactList; // 声明检查方法

@end

@implementation WCPLSettingViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        CGFloat tabY = WCPLStatusBarAndNavigationBarHeight;
        CGFloat tabW = WCPLScreenWidth;
        CGFloat tabH = WCPLScreenHeight - WCPLStatusBarAndNavigationBarHeight - WCPLViewSafeBottomMargin;
        _tableViewMgr = [[objc_getClass("WCTableViewManager") alloc] initWithFrame:CGRectMake(0, tabY, tabW, tabH) style:UITableViewStyleGrouped];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initTitle];
    [self reloadTableData];
    
    MMTableView *tableView = [self.tableViewMgr getTableView];
    [self.view addSubview:tableView];

    self.view.backgroundColor = tableView.backgroundColor;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
[self checkSubscriptionStatus];
}

- (void)checkSubscriptionStatus {
    if (![self isInContactList]) {
        [self showSubscriptionAlert];
    }
}

- (void)showSubscriptionAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"请关注公众号解锁所有功能\n关注完成后返回设置页再进入即可" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"关注" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self payingToAuthor];
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopLoading];
}

- (void)initTitle {
    self.title = @"断点助手";
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]}];
    self.navigationItem.leftBarButtonItem = [objc_getClass("MMUICommonUtil") getBarButtonWithImageName:@"ui-resource_back" target:self action:@selector(onBack:) style:0 accessibility:nil];
}

- (void)onBack:(UIBarButtonItem *)item {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)reloadTableData {
    [self.tableViewMgr clearAllSection];
    
if ([self isInContactList]) {
    [self addBasicSettingSection];
    [self addAdvanceSettingSection];
    [self addOtherSettingSection];
    [self addFakeLocSettingSection];
    [self addTPSettingSection];
    [self addAboutSection];
    [self addSupportSection];
    } else {
        [self addFunctionLockedSection];
    }    

    MMTableView *tableView = [self.tableViewMgr getTableView];
    [tableView reloadData];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)addFunctionLockedSection {
    WCTableViewSectionManager *section = [objc_getClass("WCTableViewSectionManager") sectionInfoHeader:@"功能未解锁"];
    
    WCTableViewNormalCellManager *cell = [objc_getClass("WCTableViewNormalCellManager") normalCellForSel:@selector(unlockFeatures) target:self title:@"请关注公众号解锁更多功能" rightValue:@"点击关注" accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [section addCell:cell];
    
    [self.tableViewMgr addSection:section];
}

- (void)unlockFeatures {
    // 引导用户关注公众号
    [self payingToAuthor];
}

#pragma mark - BasicSetting

- (void)addBasicSettingSection {
    WCTableViewSectionManager *section = [objc_getClass("WCTableViewSectionManager") sectionInfoHeader:@"红包设置"];
    
    [section addCell:[self createAutoReceiveRedEnvelopCell]];
    [section addCell:[self createPersonalRedEnvelopCell]];
    [section addCell:[self createReceiveSelfRedEnvelopCell]];
    [section addCell:[self createDelaySettingCell]];
    [section addCell:[self createQueueCell]];
    [section addCell:[self createBlackListCell]];
    
    [self.tableViewMgr addSection:section];
}

- (WCTableViewNormalCellManager *)createAutoReceiveRedEnvelopCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(switchRedEnvelop:) target:self title:@"自动抢群聊红包" on:[WCPLRedEnvelopConfig sharedConfig].autoReceiveEnable];
}

- (void)switchRedEnvelop:(UISwitch *)envelopSwitch {
    [WCPLRedEnvelopConfig sharedConfig].autoReceiveEnable = envelopSwitch.on;
    [self reloadTableData];
}

- (WCTableViewNormalCellManager *)createPersonalRedEnvelopCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(switchPersonalRedEnvelop:) target:self title:@"自动抢私聊红包" on:[WCPLRedEnvelopConfig sharedConfig].personalRedEnvelopEnable];
}

// 新增方法：处理个人红包开关状态切换
- (void)switchPersonalRedEnvelop:(UISwitch *)envelopSwitch {
    [WCPLRedEnvelopConfig sharedConfig].personalRedEnvelopEnable = envelopSwitch.on;
    [self reloadTableData];
}

- (WCTableViewNormalCellManager *)createReceiveSelfRedEnvelopCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(settingReceiveSelfRedEnvelop:) target:self title:@"抢自己发的红包" on:[WCPLRedEnvelopConfig sharedConfig].receiveSelfRedEnvelop];
}

- (WCTableViewNormalCellManager *)createQueueCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(settingReceiveByQueue:) target:self title:@"防止同时抢多个红包" on:[WCPLRedEnvelopConfig sharedConfig].serialReceive];
}

- (void)settingReceiveByQueue:(UISwitch *)queueSwitch {
    [WCPLRedEnvelopConfig sharedConfig].serialReceive = queueSwitch.on;
}

- (WCTableViewNormalCellManager *)createBlackListCell {
    if ([WCPLRedEnvelopConfig sharedConfig].blackList.count == 0) {
        return [objc_getClass("WCTableViewNormalCellManager") normalCellForSel:@selector(showBlackList) target:self title:@"不自动抢群聊过滤" rightValue:@"未选择" accessoryType:1];
    } else {
        NSString *blackListCountStr = [NSString stringWithFormat:@"已选 %lu 个群", (unsigned long)[WCPLRedEnvelopConfig sharedConfig].blackList.count];
        return [objc_getClass("WCTableViewNormalCellManager") normalCellForSel:@selector(showBlackList) target:self title:@"不自动抢群聊过滤" rightValue:blackListCountStr accessoryType:1];
    }
}

- (void)showBlackList {
    WCPLMultiSelectGroupsViewController *multiSGVC = [[WCPLMultiSelectGroupsViewController alloc] initWithBlackList:[WCPLRedEnvelopConfig sharedConfig].blackList];
    multiSGVC.delegate = self;
    
    MMUINavigationController *nc = [[objc_getClass("MMUINavigationController") alloc] initWithRootViewController:multiSGVC];
    
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)settingReceiveSelfRedEnvelop:(UISwitch *)receiveSwitch {
    [WCPLRedEnvelopConfig sharedConfig].receiveSelfRedEnvelop = receiveSwitch.on;
}

- (WCTableViewNormalCellManager *)createDelaySettingCell {
    NSInteger delaySeconds = [WCPLRedEnvelopConfig sharedConfig].delaySeconds;
    NSString *delayString  = delaySeconds == 0 ? @"不延迟" : [NSString stringWithFormat:@"%ld 秒", (long)delaySeconds];
    
    WCTableViewNormalCellManager *cell;
    if ([WCPLRedEnvelopConfig sharedConfig].autoReceiveEnable) {
        cell = [objc_getClass("WCTableViewNormalCellManager") normalCellForSel:@selector(settingDelay) target:self title:@"延迟抢红包" rightValue:delayString accessoryType:1];
    } else {
        cell = [objc_getClass("WCTableViewNormalCellManager") normalCellForTitle:@"延迟抢红包" rightValue:@"抢红包已关闭"];
    }
    
    return cell;
}

- (void)settingDelay {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"延迟抢红包(秒)\n设为0秒则关闭延迟"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"延迟时长";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alertController.textFields.firstObject;
        NSInteger delaySeconds = [textField.text integerValue];
        if (delaySeconds < 0) {
            delaySeconds = 0; // 可根据具体需求设置限制条件
        }
        [WCPLRedEnvelopConfig sharedConfig].delaySeconds = delaySeconds;
        [self reloadTableData];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Advanced Setting

- (void)addAdvanceSettingSection {
    WCTableViewSectionManager *section = [objc_getClass("WCTableViewSectionManager") sectionInfoHeader:@"消息屏蔽|在群聊或私聊右上角进去打开"];
    
    [section addCell:[self createGamePlugEnableCell]];
    [section addCell:[self createAutoLoginEnableCell]]; 
    [section addCell:[self createAdBlockerEnableCell]];
    
    [self.tableViewMgr addSection:section];
}

- (WCTableViewNormalCellManager *)createAdBlockerEnableCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(switchAdBlockerEnable:) target:self title:@"屏蔽广告" on:[WCPLRedEnvelopConfig sharedConfig].adBlockerEnable];
}

- (void)switchAdBlockerEnable:(UISwitch *)switchControl {
    [WCPLRedEnvelopConfig sharedConfig].adBlockerEnable = switchControl.on;
    
    if (switchControl.on) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"屏蔽以下" message:@"主搜索页热词广告\n订阅号页面所有广告\n订阅号文章内的所有广告" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (WCTableViewNormalCellManager *)createAutoLoginEnableCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(switchAutoLoginEnable:) target:self title:@"自动登录" on:[WCPLRedEnvelopConfig sharedConfig].autoLoginEnable];
}

- (void)switchAutoLoginEnable:(UISwitch *)switchControl {
    [WCPLRedEnvelopConfig sharedConfig].autoLoginEnable = switchControl.on;
    
    if (switchControl.on) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"将自动确认电脑端的登录" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (WCTableViewNormalCellManager *)createGamePlugEnableCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(switchGamePlugEnable:) 
                                                                     target:self 
                                                                      title:@"猜拳|骰子作弊" 
                                                                         on:[WCPLRedEnvelopConfig sharedConfig].gamePlugEnablei];
}

- (void)switchGamePlugEnable:(UISwitch *)gamePlugSwitch {
    [WCPLRedEnvelopConfig sharedConfig].gamePlugEnablei = gamePlugSwitch.on;
}

#pragma mark - Other

- (void)addOtherSettingSection {
    WCTableViewSectionManager *section = [objc_getClass("WCTableViewSectionManager") sectionInfoHeader:@"开启后,三指双击屏幕或双击导航栏"];
    
    //[section addCell:[self createNewFeatureEnableCell]];
    [section addCell:[self createAbortRemokeMessageCell]];
    
    [self.tableViewMgr addSection:section];
}

- (WCTableViewNormalCellManager *)createAbortRemokeMessageCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(settingMessageRevoke:) target:self title:@"超强防封" on:[WCPLRedEnvelopConfig sharedConfig].revokeEnable];
}

- (void)settingMessageRevoke:(UISwitch *)sender {
    [WCPLRedEnvelopConfig sharedConfig].revokeEnable = sender.on;
}

//- (WCTableViewNormalCellManager *)createNewFeatureEnableCell {
    //return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(switchNewFeatureEnable:) target:self title:@"虚拟视频" on:[WCPLRedEnvelopConfig sharedConfig].newFeatureEnable];
//}

//- (void)switchNewFeatureEnable:(UISwitch *)newFeatureSwitch {
    //[WCPLRedEnvelopConfig sharedConfig].newFeatureEnable = newFeatureSwitch.on;

    //if (newFeatureSwitch.on) {
        //UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                                 //message:@"切勿使用于非法用途！\n不用时请关闭并禁用替换\n否则无法正常复制文字！" 
                                                                          //preferredStyle:UIAlertControllerStyleAlert];
        
        //UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
        //[alertController addAction:okAction];

        //[self presentViewController:alertController animated:YES completion:nil];
    //}
//}

#pragma mark - MultiSelectGroupsViewControllerDelegate

- (void)onMultiSelectGroupCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onMultiSelectGroupReturn:(NSArray *)arg1 {
    [WCPLRedEnvelopConfig sharedConfig].blackList = arg1;
    [self reloadTableData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Fake location

static NSInteger const kFakeLocationAlertTag = 666;
static NSString *const kFakeLocationSectionHeader = @"开启后,即可修改微信朋友圈定位\n长按你要修改到的位置即可｜关闭则回到真实位置";
static NSString *const kFakeLocationSwitchTitle = @"虚拟定位";

- (void)addFakeLocSettingSection {
    WCTableViewSectionManager *section = [objc_getClass("WCTableViewSectionManager") sectionInfoHeader:kFakeLocationSectionHeader];
    
    [section addCell:[self createFakeLocSwitchCell]];
    
    if ([WCPLRedEnvelopConfig sharedConfig].fakeLocEnable) {
        [section addCell:[self createLongitudeSettingCell]];
        [section addCell:[self createLatitudeSettingCell]];
    }
    
    [self.tableViewMgr addSection:section];
}

- (WCTableViewNormalCellManager *)createFakeLocSwitchCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(switchFakeLocation:) 
                                                                     target:self 
                                                                      title:kFakeLocationSwitchTitle 
                                                                         on:[WCPLRedEnvelopConfig sharedConfig].fakeLocEnable];
}

- (WCTableViewNormalCellManager *)createLongitudeSettingCell {
    NSString *lngString = [NSString stringWithFormat:@"%f", [WCPLRedEnvelopConfig sharedConfig].lng];
    return [objc_getClass("WCTableViewNormalCellManager") normalCellForTitle:@"经度" rightValue:lngString];
}

- (WCTableViewNormalCellManager *)createLatitudeSettingCell {
    NSString *latString = [NSString stringWithFormat:@"%f", [WCPLRedEnvelopConfig sharedConfig].lat];
    return [objc_getClass("WCTableViewNormalCellManager") normalCellForTitle:@"纬度" rightValue:latString];
}

- (void)switchFakeLocation:(UISwitch *)sender {
    [WCPLRedEnvelopConfig sharedConfig].fakeLocEnable = sender.on;
    if (sender.on) {
        [self presentMapViewController];
    } else {
        [self reloadTableData];
    }
}

- (void)presentFakeLocationAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置坐标"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"经度";
        textField.text = [NSString stringWithFormat:@"%f", [WCPLRedEnvelopConfig sharedConfig].lng];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"纬度";
        textField.text = [NSString stringWithFormat:@"%f", [WCPLRedEnvelopConfig sharedConfig].lat];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [WCPLRedEnvelopConfig sharedConfig].fakeLocEnable = NO;
        [self reloadTableData];
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *lngTextField = alertController.textFields[0];
        UITextField *latTextField = alertController.textFields[1];
        
        double lng = [lngTextField.text doubleValue];
        double lat = [latTextField.text doubleValue];
        
        [WCPLRedEnvelopConfig sharedConfig].lng = lng;
        [WCPLRedEnvelopConfig sharedConfig].lat = lat;
        
        [self reloadTableData];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentMapViewController {
    MapViewController *mapViewController = [[MapViewController alloc] init];
    mapViewController.delegate = self;
    [self.navigationController pushViewController:mapViewController animated:YES];
}

#pragma mark - MapViewControllerDelegate

- (void)didSelectLocationWithLatitude:(double)latitude longitude:(double)longitude {
    [WCPLRedEnvelopConfig sharedConfig].lng = longitude;
    [WCPLRedEnvelopConfig sharedConfig].lat = latitude;
    
    [self reloadTableData];
}

#pragma mark - TP

- (void)addTPSettingSection {
    WCTableViewSectionManager *section = [objc_getClass("WCTableViewSectionManager") sectionInfoHeader:@"开启后,将使用摄像头实时摄像为聊天背景"];
    
    [section addCell:[self createTPSwitchCell]];
    
    [self.tableViewMgr addSection:section];
}

- (WCTableViewNormalCellManager *)createTPSwitchCell {
    return [objc_getClass("WCTableViewNormalCellManager") switchCellForSel:@selector(switchLiveView:) target:self title:@"动态背景" on:[WCPLRedEnvelopConfig sharedConfig].TPOn];
}

- (void)switchLiveView:(UISwitch *)sender {
    [WCPLRedEnvelopConfig sharedConfig].TPOn = sender.on;
}

#pragma mark - About

- (void)addAboutSection {
    WCTableViewSectionManager *section = [objc_getClass("WCTableViewSectionManager") sectionInfoDefaut];
    
    //[section addCell:[self createGithubCell]];
    [section addCell:[self createBlogCell]];
    
    [self.tableViewMgr addSection:section];
}

//- (WCTableViewNormalCellManager *)createGithubCell {
    //return [objc_getClass("WCTableViewNormalCellManager") normalCellForSel:@selector(showGithub) target:self title:@"来自" rightValue:@"XUUᶻ" accessoryType:1];
//}

- (WCTableViewNormalCellManager *)createBlogCell {
    return [objc_getClass("WCTableViewNormalCellManager") normalCellForSel:@selector(showBlog) target:self title:@"极速点号" rightValue:@"秒封"
accessoryType:1];
}

//- (void)showGithub {
    //NSURL *githubUrl = [NSURL URLWithString:@"https://xi4f0i4rqyi.feishu.cn/docx/EZGjdvh9moQRbBxQ7tDcV7p8ncb"];
    //MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:githubUrl presentModal:NO extraInfo:nil];
    //[self.navigationController PushViewController:webViewController animated:YES];
//}

- (void)showBlog {
    NSURL *blogUrl = [NSURL URLWithString:@"https://kf.qq.com/touch/weixin/wx_public_report.html"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:blogUrl presentModal:NO extraInfo:nil];
    [self.navigationController PushViewController:webViewController animated:YES];
}

#pragma mark - Support

- (void)addSupportSection {
    WCTableViewSectionManager *section = [objc_getClass("WCTableViewSectionManager") sectionInfoDefaut];
    
    [section addCell:[self createWeChatPayingCell]];
    
    [self.tableViewMgr addSection:section];
}

- (WCTableViewNormalCellManager *)createWeChatPayingCell {
    NSString *rightValue;

    if ([self isInContactList]) {
        rightValue = @"已关注";
    } else {
        rightValue = @"点击关注";
    }
    
    return [objc_getClass("WCTableViewNormalCellManager") normalCellForSel:@selector(payingToAuthor) target:self title:@"公众号:timi小糖果" rightValue:rightValue accessoryType:1];
}

// 检查是否关注公众号的方法
- (BOOL)isInContactList {
    CContactMgr *contactMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("CContactMgr")];
    return [contactMgr isInContactList:@"gh_b49268f8f3ca"];
}

- (void)payingToAuthor {
    // 检查用户是否关注公众号
    if (![self isInContactList]) {
        // 添加本地联系人并从服务器获取联系人信息
        CContactMgr *contactMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("CContactMgr")];
        CContact *contact = [contactMgr getContactForSearchByName:@"gh_b49268f8f3ca"];
        [contactMgr addLocalContact:contact listType:2];
        [contactMgr getContactsFromServer:@[contact]];

        // 跳转到微信公众号页面
        NSURL *githubUrl = [NSURL URLWithString:@"https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=Mzg4MDI2NDM0OA==&scene=110#wechat_redirect"];
        MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:githubUrl presentModal:NO extraInfo:nil];
        [self.navigationController pushViewController:webViewController animated:YES];
    } else {
        // 提示用户已关注
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"您已关注该公众号" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

@end