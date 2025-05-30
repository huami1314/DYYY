#import "DYYYSettingViewController.h"
#import "DYYYConstants.h"
#import "DYYYManager.h"
#import "DYYYCustomInputView.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>

extern CFStringRef kUTTypeMovie;

@interface DYYYSettingViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIVisualEffectView *containerBlurView;
@property (nonatomic, strong) UITableView *settingsTableView;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *settingsData;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIVisualEffectView *headerBlurView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *pluginNameLabel;
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, assign) BOOL isAgreementShown;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) AVPlayerLayer *backgroundVideoLayer;
@property (nonatomic, strong) AVPlayer *backgroundPlayer;
@property (nonatomic, assign) BOOL hasCustomBackground;
@end

@implementation DYYYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isAgreementShown = NO;
    self.hasCustomBackground = NO;
    [self setupSettingsData];
    
    [self checkForCustomBackground];
    
    [self setupUI];
}

// 新增方法：检查是否存在自定义背景
- (void)checkForCustomBackground {
    // 检查是否有视频背景
    NSString *videoPath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        self.hasCustomBackground = YES;
        return;
    }
    
    // 检查是否有图片背景
    NSString *imagePath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.jpg"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        UIImage *backgroundImage = [UIImage imageWithContentsOfFile:imagePath];
        if (backgroundImage) {
            self.hasCustomBackground = YES;
        }
    }
}

#pragma mark - 文件管理

- (NSString *)dyyyDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dyyyDirectory = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:dyyyDirectory isDirectory:&isDir] || !isDir) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:dyyyDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"创建DYYY目录失败: %@", error);
        }
    }
    
    return dyyyDirectory;
}

#pragma mark - First Launch Agreement

- (void)checkFirstLaunch {
    BOOL hasAgreed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"];
    
    if (!hasAgreed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAgreementAlert];
        });
    }
}

- (void)showAgreementAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"用户协议"
                                                                             message:@"本插件为开源项目\n基于 Huami 的项目二次开发\n仅供学习交流用途\n如有侵权请联系, GitHub 仓库：Wtrwx/DYYY\n请遵守当地法律法规, 逆向工程仅为学习目的\n盗用源码进行商业用途/发布但未标记开源项目必究\n详情请参阅项目内 MIT 许可证\n\n请输入\"我已阅读并同意继续使用\"以继续使用"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.placeholder = @"请输入确认文本";
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alertController.textFields.firstObject;
        NSString *inputText = textField.text;
        
        if ([inputText isEqualToString:@"我已阅读并同意继续使用"]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DYYYUserAgreementAccepted"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"输入错误"
                                                                               message:@"请正确输入确认文本"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self showAgreementAlert];
            }];
            
            [errorAlert addAction:okAction];
            [self presentViewController:errorAlert animated:YES completion:nil];
        }
    }];

    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    
    [alertController addAction:confirmAction];
    [alertController addAction:exitAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 设置背景

- (void)setupBackgroundView {
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.clipsToBounds = YES;
    self.backgroundImageView.layer.cornerRadius = 16;
    self.backgroundImageView.hidden = YES;
    [self.view insertSubview:self.backgroundImageView belowSubview:self.containerBlurView];
    
    self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundImageView.topAnchor constraintEqualToAnchor:self.containerBlurView.topAnchor],
        [self.backgroundImageView.leadingAnchor constraintEqualToAnchor:self.containerBlurView.leadingAnchor],
        [self.backgroundImageView.trailingAnchor constraintEqualToAnchor:self.containerBlurView.trailingAnchor],
        [self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.containerBlurView.bottomAnchor]
    ]];
    
    [self loadCustomBackground];
}

- (void)loadCustomBackground {
    // 检查是否有视频背景
    NSString *videoPath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        [self setupVideoBackground:videoPath];
        return;
    }
    
    // 检查是否有图片背景
    NSString *imagePath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.jpg"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        UIImage *backgroundImage = [UIImage imageWithContentsOfFile:imagePath];
        if (backgroundImage) {
            self.backgroundImageView.image = backgroundImage;
            self.backgroundImageView.hidden = NO;
        }
    }
}

- (void)setupVideoBackground:(NSString *)videoPath {

    if (self.backgroundVideoLayer) {
        [self.backgroundVideoLayer removeFromSuperlayer];
        self.backgroundVideoLayer = nil;
    }
    if (self.backgroundPlayer) {
        [self.backgroundPlayer pause];
        self.backgroundPlayer = nil;
    }
    
    // 创建新的视频播放器
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    self.backgroundPlayer = [AVPlayer playerWithURL:videoURL];
    self.backgroundPlayer.volume = 0.0; // 静音播放
    
    self.backgroundVideoLayer = [AVPlayerLayer playerLayerWithPlayer:self.backgroundPlayer];
    self.backgroundVideoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.backgroundVideoLayer.cornerRadius = 16;
    self.backgroundVideoLayer.masksToBounds = YES;
    
    [self.view.layer insertSublayer:self.backgroundVideoLayer below:self.containerBlurView.layer];
    
    [self updateVideoLayerFrame];
    
    // 循环播放视频
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.backgroundPlayer.currentItem];
    
    [self.backgroundPlayer play];
}

- (void)updateVideoLayerFrame {
    if (self.backgroundVideoLayer) {
        self.backgroundVideoLayer.frame = self.containerBlurView.frame;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateVideoLayerFrame];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.backgroundPlayer seekToTime:kCMTimeZero];
    [self.backgroundPlayer play];
}

#pragma mark - 设置UI

- (void)setupSettingsData {
    self.settingsData = [NSMutableArray arrayWithArray:@[
        // 基本设置
        [@{
            @"title": @"基本设置",
            @"expanded": @NO,
            @"items": [self loadSettingsForSection:@[
                @{@"title": @"启用弹幕改色", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnableDanmuColor"},
                @{@"title": @"自定弹幕颜色", @"type": @"input", @"value": @"", @"key": @"DYYYdanmuColor", @"placeholder": @"十六进制"},
                @{@"title": @"设置默认倍速", @"type": @"input", @"value": @"1.0", @"key": @"DYYYDefaultSpeed", @"placeholder": @"倍速值"},
                @{@"title": @"设置长按倍速", @"type": @"input", @"value": @"2.0", @"key": @"DYYYLongPressSpeed", @"placeholder": @"倍速值"},
                @{@"title": @"显示进度时长", @"type": @"switch", @"value": @NO, @"key": @"DYYYisShowScheduleDisplay"},
                @{@"title": @"进度纵轴位置", @"type": @"input", @"value": @"-12.5", @"key": @"DYYYTimelineVerticalPosition", @"placeholder": @"-12.5"},
                @{@"title": @"进度标签颜色", @"type": @"input", @"value": @"", @"key": @"DYYYProgressLabelColor", @"placeholder": @"十六进制"},
                @{@"title": @"隐藏视频进度", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideVideoProgress"},
                @{@"title": @"启用自动播放", @"type": @"switch", @"value": @NO, @"key": @"DYYYisEnableAutoPlay"},
                @{@"title": @"推荐过滤直播", @"type": @"switch", @"value": @NO, @"key": @"DYYYisSkipLive"},
                @{@"title": @"推荐过滤热点", @"type": @"switch", @"value": @NO, @"key": @"DYYYisSkipHotSpot"},
                @{@"title": @"推荐过滤低赞", @"type": @"input", @"value": @"0", @"key": @"DYYYfilterLowLikes", @"placeholder": @"填0关闭"},
                @{@"title": @"推荐过滤文案", @"type": @"input", @"value": @"", @"key": @"DYYYfilterKeywords", @"placeholder": @"不填关闭"},
                @{@"title": @"推荐视频时限", @"type": @"input", @"value": @"0", @"key": @"DYYYfiltertimelimit", @"placeholder": @"填0关闭，单位为天"},
                @{@"title": @"启用首页净化", @"type": @"switch", @"value": @NO, @"key": @"DYYYisEnablePure"},
                @{@"title": @"启用首页全屏", @"type": @"switch", @"value": @NO, @"key": @"DYYYisEnableFullScreen"},
                @{@"title": @"启用屏蔽广告", @"type": @"switch", @"value": @NO, @"key": @"DYYYNoAds"},
                @{@"title": @"屏蔽检测更新", @"type": @"switch", @"value": @NO, @"key": @"DYYYNoUpdates"},
                @{@"title": @"去青少年弹窗", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideteenmode"},
                @{@"title": @"评论区毛玻璃", @"type": @"switch", @"value": @NO, @"key": @"DYYYisEnableCommentBlur"},
                @{@"title": @"通知玻璃效果", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnableNotificationTransparency"},
                @{@"title": @"毛玻璃透明度", @"type": @"input", @"value": @"0.8", @"key": @"DYYYCommentBlurTransparent", @"placeholder": @"0-1小数"},
                @{@"title": @"通知圆角半径", @"type": @"input", @"value": @"12", @"key": @"DYYYNotificationCornerRadius", @"placeholder": @"默认12"},
                @{@"title": @"时间属地显示", @"type": @"switch", @"value": @NO, @"key": @"DYYYisEnableArea"},
                @{@"title": @"国外解析账号", @"type": @"input", @"value": @"", @"key": @"DYYYGeonamesUsername", @"placeholder": @"不填默认"},
                @{@"title": @"时间标签颜色", @"type": @"input", @"value": @"", @"key": @"DYYYLabelColor", @"placeholder": @"十六进制"},
                @{@"title": @"时间随机渐变", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnabsuijiyanse"},
                @{@"title": @"隐藏系统顶栏", @"type": @"switch", @"value": @NO, @"key": @"DYYYisHideStatusbar"},
                @{@"title": @"关注二次确认", @"type": @"switch", @"value": @NO, @"key": @"DYYYfollowTips"},
                @{@"title": @"收藏二次确认", @"type": @"switch", @"value": @NO, @"key": @"DYYYcollectTips"},             
                @{@"title": @"直播默认最高画质", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnableLiveHighestQuality"},
                @{@"title": @"视频默认最高画质", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnableVideoHighestQuality"},
                @{@"title": @"禁用直播PCDN功能", @"type": @"switch", @"value": @NO, @"key": @"DYYYDisableLivePCDN"}
            ]]
        } mutableCopy],
        
        // 界面设置
        [@{
            @"title": @"界面设置",
            @"expanded": @NO,
            @"items": [self loadSettingsForSection:@[
                @{@"title": @"设置顶栏透明", @"type": @"input", @"value": @"1.0", @"key": @"DYYYtopbartransparent", @"placeholder": @"0-1小数"},
                @{@"title": @"设置全局透明", @"type": @"input", @"value": @"1.0", @"key": @"DYYYGlobalTransparency", @"placeholder": @"0-1小数"},
                @{@"title": @"首页头像透明", @"type": @"input", @"value": @"1.0", @"key": @"DYYYAvatarViewTransparency", @"placeholder": @"0-1小数"},
                @{@"title": @"右侧栏缩放度", @"type": @"input", @"value": @"", @"key": @"DYYYElementScale", @"placeholder": @"不填默认"},
                @{@"title": @"昵称文案缩放", @"type": @"input", @"value": @"", @"key": @"DYYYNicknameScale", @"placeholder": @"不填默认"},
                @{@"title": @"昵称下移距离", @"type": @"input", @"value": @"", @"key": @"DYYYNicknameVerticalOffset", @"placeholder": @"不填默认"},
                @{@"title": @"文案下移距离", @"type": @"input", @"value": @"", @"key": @"DYYYDescriptionVerticalOffset", @"placeholder": @"不填默认"},
                @{@"title": @"属地上移距离", @"type": @"input", @"value": @"", @"key": @"DYYYIPLabelVerticalOffset", @"placeholder": @"不填默认"},
                @{@"title": @"设置首页标题", @"type": @"input", @"value": @"", @"key": @"DYYYIndexTitle", @"placeholder": @"不填默认"},
                @{@"title": @"设置朋友标题", @"type": @"input", @"value": @"", @"key": @"DYYYFriendsTitle", @"placeholder": @"不填默认"},
                @{@"title": @"设置消息标题", @"type": @"input", @"value": @"", @"key": @"DYYYMsgTitle", @"placeholder": @"不填默认"},
                @{@"title": @"设置我的标题", @"type": @"input", @"value": @"", @"key": @"DYYYSelfTitle", @"placeholder": @"不填默认"}
            ]]
        } mutableCopy],
        
        // 隐藏设置
        [@{
            @"title": @"隐藏设置",
            @"expanded": @NO,
            @"items": [self loadSettingsForSection:@[
                @{@"title": @"隐藏全屏观看", @"type": @"switch", @"value": @NO, @"key": @"DYYYisHiddenEntry"},
                @{@"title": @"隐藏底栏商城", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideShopButton"},
                @{@"title": @"隐藏双列箭头", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideDoubleColumnEntry"},
                @{@"title": @"隐藏底栏消息", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideMessageButton"},
                @{@"title": @"隐藏底栏朋友", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideFriendsButton"},
                @{@"title": @"隐藏底栏我的", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideMyButton"},
                @{@"title": @"隐藏底栏加号", @"type": @"switch", @"value": @NO, @"key": @"DYYYisHiddenJia"},
                @{@"title": @"隐藏底栏红点", @"type": @"switch", @"value": @NO, @"key": @"DYYYisHiddenBottomDot"},
                @{@"title": @"隐藏底栏背景", @"type": @"switch", @"value": @NO, @"key": @"DYYYisHiddenBottomBg"},
                @{@"title": @"隐藏侧栏元素", @"type": @"switch", @"value": @NO, @"key": @"DYYYStreamlinethesidebar"},
                @{@"title": @"隐藏侧栏红点", @"type": @"switch", @"value": @NO, @"key": @"DYYYisHiddenSidebarDot"},
                @{@"title": @"隐藏发作品框", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePostView"},
                @{@"title": @"隐藏头像加号", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLOTAnimationView"},
                @{@"title": @"隐藏点赞数值", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLikeLabel"},
                @{@"title": @"隐藏评论数值", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentLabel"},
                @{@"title": @"隐藏收藏数值", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCollectLabel"},
                @{@"title": @"隐藏分享数值", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideShareLabel"},
                @{@"title": @"隐藏点赞按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLikeButton"},
                @{@"title": @"隐藏评论按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentButton"},
                @{@"title": @"隐藏收藏按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCollectButton"},
                @{@"title": @"隐藏头像按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideAvatarButton"},
                @{@"title": @"隐藏音乐按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideMusicButton"},
                @{@"title": @"隐藏分享按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideShareButton"},
                @{@"title": @"隐藏视频定位", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLocation"},
                @{@"title": @"隐藏右上搜索", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideDiscover"},
                @{@"title": @"隐藏相关搜索", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideInteractionSearch"},
                @{@"title": @"隐藏搜索同款", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideSearchSame"},
                @{@"title": @"隐藏长框搜索", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideSearchEntrance"},
                @{@"title": @"隐藏进入直播", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideEnterLive"},
                @{@"title": @"隐藏评论视图", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentViews"},
                @{@"title": @"隐藏通知提示", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePushBanner"},
                @{@"title": @"隐藏头像列表", @"type": @"switch", @"value": @NO, @"key": @"DYYYisHiddenAvatarList"},
                @{@"title": @"隐藏头像气泡", @"type": @"switch", @"value": @NO, @"key": @"DYYYisHiddenAvatarBubble"},
                @{@"title": @"隐藏左侧边栏", @"type": @"switch", @"value": @NO, @"key": @"DYYYisHiddenLeftSideBar"},
                @{@"title": @"隐藏吃喝玩乐", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideNearbyCapsuleView"},
                @{@"title": @"隐藏弹幕按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideDanmuButton"},
                @{@"title": @"隐藏取消静音", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCancelMute"},
                @{@"title": @"隐藏去汽水听", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideQuqishuiting"},
                @{@"title": @"隐藏共创头像", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideGongChuang"},
                @{@"title": @"隐藏热点提示", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideHotspot"},
                @{@"title": @"隐藏推荐提示", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideRecommendTips"},
                @{@"title": @"隐藏分享提示", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideShareContentView"},
                @{@"title": @"隐藏作者声明", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideAntiAddictedNotice"},
                @{@"title": @"隐藏底部相关", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideBottomRelated"},
                @{@"title": @"隐藏拍摄同款", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideFeedAnchorContainer"},
                @{@"title": @"隐藏挑战贴纸", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideChallengeStickers"},
                @{@"title": @"隐藏校园提示", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideTemplateTags"},
                @{@"title": @"隐藏作者店铺", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideHisShop"},
                @{@"title": @"隐藏关注直播", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideConcernCapsuleView"},
                @{@"title": @"隐藏顶栏横线", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidentopbarprompt"},
                @{@"title": @"隐藏视频合集", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideTemplateVideo"},
                @{@"title": @"隐藏短剧合集", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideTemplatePlaylet"},
                @{@"title": @"隐藏动图标签", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLiveGIF"},
                @{@"title": @"隐藏笔记标签", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideItemTag"},
                @{@"title": @"隐藏底部话题", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideTemplateGroup"},
                @{@"title": @"隐藏相机定位", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCameraLocation"},
                @{@"title": @"隐藏视频滑条", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideStoryProgressSlide"},
                @{@"title": @"隐藏图片滑条", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideDotsIndicator"},
                @{@"title": @"隐藏分享私信", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePrivateMessages"},
                @{@"title": @"隐藏昵称右侧", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideRightLable"},
                @{@"title": @"隐藏群聊商店", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideGroupShop"},
                @{@"title": @"隐藏直播胶囊", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLiveCapsuleView"},
                @{@"title": @"隐藏关注顶端", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidenLiveView"},
                @{@"title": @"隐藏同城顶端", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideMenuView"},
                @{@"title": @"隐藏群直播中", @"type": @"switch", @"value": @NO, @"key": @"DYYYGroupLiving"},
                @{@"title": @"隐藏聊天底栏", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideGroupInputActionBar"},
                @{@"title": @"隐藏添加朋友", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideButton"},
                @{@"title": @"隐藏日常按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideFamiliar"},
                @{@"title": @"隐藏直播广场", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLivePlayground"},
                @{@"title": @"隐藏礼物展馆", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideGiftPavilion"},
                @{@"title": @"隐藏顶栏红点", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideTopBarBadge"},
                @{@"title": @"隐藏退出清屏", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLiveRoomClear"},
                @{@"title": @"隐藏投屏按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLiveRoomMirroring"},
                @{@"title": @"隐藏直播发现", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideLiveDiscovery"},
                @{@"title": @"隐藏直播点歌", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideKTVSongIndicator"},
                @{@"title": @"隐藏流量提醒", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCellularAlert"},
                @{@"title": @"隐藏红包悬浮", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePendantGroup"},
                @{@"title": @"隐藏聊天评论", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideChatCommentBg"},
                @{@"title": @"隐藏章节进度", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideChapterProgress"},
                @{@"title": @"隐藏设置关于", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideSettingsAbout"},
                @{@"title": @"隐藏键盘AI", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidekeyboardai"}
                
            ]]
        } mutableCopy],
        
        // 顶栏移除
        [@{
            @"title": @"顶栏移除",
            @"expanded": @NO,
            @"items": [self loadSettingsForSection:@[
                @{@"title": @"移除推荐", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideHotContainer"},
                @{@"title": @"移除关注", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideFollow"},
                @{@"title": @"移除精选", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideMediumVideo"},
                @{@"title": @"移除商城", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideMall"},
                @{@"title": @"移除朋友", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideFriend"},
                @{@"title": @"移除同城", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideNearby"},
                @{@"title": @"移除团购", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideGroupon"},
                @{@"title": @"移除直播", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideTabLive"},
                @{@"title": @"移除热点", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePadHot"},
                @{@"title": @"移除经验", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideHangout"},
                @{@"title": @"移除短剧", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePlaylet"},
                @{@"title": @"移除看剧", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCinema"},
                @{@"title": @"移除少儿", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideKidsV2"},
                @{@"title": @"移除游戏", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideGame"}
            ]]
        } mutableCopy],
        
        // 隐藏面板
        [@{
            @"title": @"隐藏面板",
            @"expanded": @NO,
            @"items": [self loadSettingsForSection:@[
                @{@"title": @"隐藏面板日常", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelDaily"},
                @{@"title": @"隐藏面板推荐", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelRecommend"},
                @{@"title": @"隐藏面板举报", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelReport"},
                @{@"title": @"隐藏面板倍速", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelSpeed"},
                @{@"title": @"隐藏面板清屏", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelClearScreen"},
                @{@"title": @"隐藏面板缓存", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelFavorite"},
                @{@"title": @"隐藏面板投屏", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelCast"},
                @{@"title": @"隐藏面板弹幕", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelSubtitle"},
                @{@"title": @"隐藏面板识图", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelSearchImage"},
                @{@"title": @"隐藏面板听抖音", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelListenDouyin"},
                @{@"title": @"隐藏电脑Pad打开", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelOpenInPC"},
                @{@"title": @"隐藏面板稍后再看", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelLater"},
                @{@"title": @"隐藏面板自动连播", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelAutoPlay"},
                @{@"title": @"隐藏面板不感兴趣", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelNotInterested"},
                @{@"title": @"隐藏面板后台播放", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelBackgroundPlay"},
                @{@"title": @"隐藏双列快捷入口", @"type": @"switch", @"value": @NO, @"key": @"DYYYHidePanelBiserial"},
                @{@"title": @"隐藏评论分享", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentShareToFriends"},
                @{@"title": @"隐藏评论复制", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentLongPressCopy"},
                @{@"title": @"隐藏评论保存", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentLongPressSaveImage"},
                @{@"title": @"隐藏评论举报", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentLongPressReport"},
                @{@"title": @"隐藏评论搜索", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentLongPressSearch"},
                @{@"title": @"隐藏评论转发日常", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentLongPressDaily"},
                @{@"title": @"隐藏评论视频回复", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentLongPressVideoReply"},
                @{@"title": @"隐藏评论识别图片", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideCommentLongPressPictureSearch"}
            ]]
        } mutableCopy],
        
        // 面板设置
        [@{
            @"title": @"面板设置",
            @"expanded": @NO,
            @"items": [self loadSettingsForSection:@[
                @{@"title": @"启用新版玻璃面板", @"type": @"switch", @"value": @NO, @"key": @"DYYYisEnableModern"},
                @{@"title": @"启用新版浅色面板", @"type": @"switch", @"value": @NO, @"key": @"DYYYisEnableModernLight"},
                @{@"title": @"新版面板跟随系统", @"type": @"switch", @"value": @NO, @"key": @"DYYYModernPanelFollowSystem"},
                @{@"title": @"长按面板保存视频", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressSaveVideo"},
                @{@"title": @"长按面板保存封面", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressSaveCover"},
                @{@"title": @"长按面板保存音频", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressSaveAudio"},
                @{@"title": @"长按面板保存图片", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressSaveCurrentImage"},
                @{@"title": @"长按保存所有图片", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressSaveAllImages"},
                @{@"title": @"长按面板生成视频", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressCreateVideo"},
                @{@"title": @"长按面板复制文案", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressCopyText"},
                @{@"title": @"长按面板复制链接", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressCopyLink"},
                @{@"title": @"长按面板接口解析", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressApiDownload"},
                @{@"title": @"长按面板定时关闭", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressTimerClose"},
                @{@"title": @"长按面板过滤文案", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressFilterTitle"},
                @{@"title": @"长按面板过滤作者", @"type": @"switch", @"value": @NO, @"key": @"DYYYLongPressFilterUser"},
                @{@"title": @"双击面板保存视频", @"type": @"switch", @"value": @NO, @"key": @"DYYYDoubleTapDownload"},
                @{@"title": @"双击面板保存音频", @"type": @"switch", @"value": @NO, @"key": @"DYYYDoubleTapDownloadAudio"},
                @{@"title": @"双击面板接口解析", @"type": @"switch", @"value": @NO, @"key": @"DYYYDoubleInterfaceDownload"},
                @{@"title": @"双击面板复制文案", @"type": @"switch", @"value": @NO, @"key": @"DYYYDoubleTapCopyDesc"},
                @{@"title": @"双击面板打开评论", @"type": @"switch", @"value": @NO, @"key": @"DYYYDoubleTapComment"},
                @{@"title": @"双击面板点赞视频", @"type": @"switch", @"value": @NO, @"key": @"DYYYDoubleTapLike"},
                @{@"title": @"双击面板分享视频", @"type": @"switch", @"value": @NO, @"key": @"DYYYDoubleTapshowSharePanel"},
                @{@"title": @"双击面板长按面板", @"type": @"switch", @"value": @NO, @"key": @"DYYYDoubleTapshowDislikeOnVideo"}
            ]]
        } mutableCopy],
        
        // 功能设置
        [@{
            @"title": @"功能设置",
            @"expanded": @NO,
            @"items": [self loadSettingsForSection:@[
                @{@"title": @"启用双击打开评论", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnableDoubleOpenComment"},
                @{@"title": @"启用双击打开菜单", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnableDoubleOpenAlertController"},
                @{@"title": @"启用自动勾选原图", @"type": @"switch", @"value": @NO, @"key": @"DYYYisAutoSelectOriginalPhoto"},
                @{@"title": @"资料默认进入作品", @"type": @"switch", @"value": @NO, @"key": @"DYYYDefaultEnterWorks"},
                @{@"title": @"启用保存他人头像", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnableSaveAvatar"},
                @{@"title": @"接口解析保存媒体", @"type": @"input", @"value": @"", @"key": @"DYYYInterfaceDownload", @"placeholder": @"不填关闭"},
                @{@"title": @"接口显示清晰选项", @"type": @"switch", @"value": @NO, @"key": @"DYYYShowAllVideoQuality"},
                @{@"title": @"移除评论实况水印", @"type": @"switch", @"value": @NO, @"key": @"DYYYCommentLivePhotoNotWaterMark"},
                @{@"title": @"移除评论图片水印", @"type": @"switch", @"value": @NO, @"key": @"DYYYCommentNotWaterMark"},
                @{@"title": @"禁用点击首页刷新", @"type": @"switch", @"value": @NO, @"key": @"DYYYDisableHomeRefresh"},
                @{@"title": @"禁用双击视频点赞", @"type": @"switch", @"value": @NO, @"key": @"DYYYDouble"},
                @{@"title": @"保存评论区表情包", @"type": @"switch", @"value": @NO, @"key": @"DYYYForceDownloadEmotion"},
                @{@"title": @"保存预览页表情包", @"type": @"switch", @"value": @NO, @"key": @"DYYYForceDownloadPreviewEmotion"},
                @{@"title": @"保存聊天页表情包", @"type": @"switch", @"value": @NO, @"key": @"DYYYForceDownloadIMEmotion"},
                @{@"title": @"长按评论复制文案", @"type": @"switch", @"value": @NO, @"key": @"DYYYCommentCopyText"}
            ]]
        } mutableCopy],
        
        // 悬浮按钮
        [@{
            @"title": @"悬浮按钮",
            @"expanded": @NO,
            @"items": [self loadSettingsForSection:@[
                @{@"title": @"启用快捷倍速按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnableFloatSpeedButton"},
                @{@"title": @"快捷倍速数值设置", @"type": @"input", @"value": @"", @"key": @"DYYYSpeedSettings", @"placeholder": @"逗号分隔"},
                @{@"title": @"自动恢复默认倍速", @"type": @"switch", @"value": @NO, @"key": @"DYYYAutoRestoreSpeed"},
                @{@"title": @"倍速按钮显示后缀", @"type": @"switch", @"value": @NO, @"key": @"DYYYSpeedButtonShowX"},
                @{@"title": @"快捷倍速按钮大小", @"type": @"input", @"value": @"32", @"key": @"DYYYSpeedButtonSize", @"placeholder": @"默认32"},
                @{@"title": @"启用一键清屏按钮", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnableFloatClearButton"},
                @{@"title": @"快捷清屏按钮大小", @"type": @"input", @"value": @"40", @"key": @"DYYYEnableFloatClearButtonSize", @"placeholder": @"默认40"},
                @{@"title": @"清屏移除时间进度", @"type": @"switch", @"value": @NO, @"key": @"DYYYEnabshijianjindu"},
                @{@"title": @"清屏隐藏时间进度", @"type": @"switch", @"value": @NO, @"key": @"DYYYHideTimeProgress"}
            ]]
        } mutableCopy]
    ]];
}

- (NSArray *)loadSettingsForSection:(NSArray *)defaultItems {
    NSMutableArray *loadedItems = [NSMutableArray array];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (NSDictionary *item in defaultItems) {
        NSMutableDictionary *mutableItem = [item mutableCopy];
        NSString *key = item[@"key"];
        NSString *type = item[@"type"];
        
        if ([type isEqualToString:@"switch"]) {
            if ([defaults objectForKey:key] != nil) {
                mutableItem[@"value"] = @([defaults boolForKey:key]);
            }
        } else if ([type isEqualToString:@"input"]) {
            NSString *savedValue = [defaults stringForKey:key];
            if (savedValue != nil) {
                mutableItem[@"value"] = savedValue;
            }
        }
        
        [loadedItems addObject:mutableItem];
    }
    
    return [loadedItems copy];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor clearColor];
    
    BOOL isDarkMode = [DYYYManager isDarkMode];
    
    // 根据是否有自定义背景决定容器效果
    if (self.hasCustomBackground) {
        // 使用半透明效果
        self.containerBlurView = [[UIVisualEffectView alloc] initWithEffect:nil];
        self.containerBlurView.backgroundColor = isDarkMode ? 
            [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7] : 
            [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
    } else {
        // 使用毛玻璃效果
        UIBlurEffectStyle containerBlurStyle = isDarkMode ? UIBlurEffectStyleSystemMaterialDark : UIBlurEffectStyleSystemMaterial;
        UIBlurEffect *containerBlur = [UIBlurEffect effectWithStyle:containerBlurStyle];
        self.containerBlurView = [[UIVisualEffectView alloc] initWithEffect:containerBlur];
    }
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat containerWidth = MIN(screenWidth - 80, 320); 
    CGFloat containerHeight = MIN(screenHeight - 80, 450);
    
    self.containerBlurView.frame = CGRectMake(0, 0, containerWidth, containerHeight);
    self.containerBlurView.center = self.view.center;
    self.containerBlurView.layer.cornerRadius = 16;
    self.containerBlurView.clipsToBounds = YES;
    self.containerBlurView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerBlurView.layer.shadowOffset = CGSizeMake(0, 4);
    self.containerBlurView.layer.shadowOpacity = 0.2;
    self.containerBlurView.layer.shadowRadius = 8;
    [self.view addSubview:self.containerBlurView];
    
    // 添加背景
    [self setupBackgroundView];
    
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = DYYY_SETTINGS_NAME;
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    if (@available(iOS 13.0, *)) {
        self.titleLabel.font = [UIFont fontWithDescriptor:[[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleTitle2] fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded] size:16];
    }
    self.titleLabel.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor labelColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerBlurView.contentView addSubview:self.titleLabel];
    
    // 关闭按钮
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.closeButton.tintColor = isDarkMode ? [UIColor whiteColor] : [UIColor secondaryLabelColor];
    [self.closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerBlurView.contentView addSubview:self.closeButton];
    
    // 设置表格
    self.settingsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.settingsTableView.backgroundColor = [UIColor clearColor];
    self.settingsTableView.dataSource = self;
    self.settingsTableView.delegate = self;
    self.settingsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.settingsTableView.showsVerticalScrollIndicator = NO;
    [self.settingsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SettingsCell"];
    
    // 创建并设置 TableView Header
    [self setupTableViewHeader];
    
    [self.containerBlurView.contentView addSubview:self.settingsTableView];
    
    [self setupConstraints];
}

- (void)setupTableViewHeader {
    // 创建 Header 容器
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    
    // 创建头部毛玻璃容器
    [self setupHeaderBlurView];
    [headerContainer addSubview:self.headerBlurView];
    
    // 设置头部容器的约束
    self.headerBlurView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.headerBlurView.topAnchor constraintEqualToAnchor:headerContainer.topAnchor constant:10],
        [self.headerBlurView.leadingAnchor constraintEqualToAnchor:headerContainer.leadingAnchor constant:0],
        [self.headerBlurView.trailingAnchor constraintEqualToAnchor:headerContainer.trailingAnchor constant:0],
        [self.headerBlurView.bottomAnchor constraintEqualToAnchor:headerContainer.bottomAnchor constant:-10],
        [self.headerBlurView.heightAnchor constraintEqualToConstant:80]
    ]];
    
    self.settingsTableView.tableHeaderView = headerContainer;
}

- (void)setupHeaderBlurView {
    BOOL isDarkMode = [DYYYManager isDarkMode];
    UIBlurEffectStyle headerBlurStyle = isDarkMode ? UIBlurEffectStyleSystemMaterialDark : UIBlurEffectStyleSystemMaterial;
    UIBlurEffect *headerBlur = [UIBlurEffect effectWithStyle:headerBlurStyle];
    self.headerBlurView = [[UIVisualEffectView alloc] initWithEffect:headerBlur];
    self.headerBlurView.layer.cornerRadius = 12;
    self.headerBlurView.clipsToBounds = YES;
    self.headerBlurView.alpha = 0.9;
    
    // 设置头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:223.0/255.0 blue:154.0/255.0 alpha:1.0];
    self.avatarImageView.layer.cornerRadius = 25;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.userInteractionEnabled = YES;
    
    [self loadCustomAvatar];
    
    // 添加点击手势
    UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped)];
    [self.avatarImageView addGestureRecognizer:avatarTap];
    
    [self.headerBlurView.contentView addSubview:self.avatarImageView];
    
    // 插件名称标签
    self.pluginNameLabel = [[UILabel alloc] init];
    self.pluginNameLabel.text = DYYY_NAME;
    self.pluginNameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    if (@available(iOS 13.0, *)) {
        self.pluginNameLabel.font = [UIFont fontWithDescriptor:[[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleTitle2] fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded] size:18];
    }
    self.pluginNameLabel.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor labelColor];
    [self.headerBlurView.contentView addSubview:self.pluginNameLabel];
    
    // 版本标签
    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.text = [NSString stringWithFormat:@"v%@", DYYY_VERSION];
    self.versionLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.versionLabel.textColor = isDarkMode ? [UIColor colorWithWhite:0.7 alpha:1.0] : [UIColor secondaryLabelColor];
    [self.headerBlurView.contentView addSubview:self.versionLabel];
    
    // 设置头部内容的约束
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pluginNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 头像约束
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.headerBlurView.contentView.leadingAnchor constant:20],
        [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.headerBlurView.contentView.centerYAnchor],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:50],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:50],
        
        // 插件名称约束
        [self.pluginNameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:15],
        [self.pluginNameLabel.topAnchor constraintEqualToAnchor:self.headerBlurView.contentView.topAnchor constant:20],
        [self.pluginNameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.headerBlurView.contentView.trailingAnchor constant:-20],
        
        // 版本标签约束
        [self.versionLabel.leadingAnchor constraintEqualToAnchor:self.pluginNameLabel.leadingAnchor],
        [self.versionLabel.topAnchor constraintEqualToAnchor:self.pluginNameLabel.bottomAnchor constant:5],
        [self.versionLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.headerBlurView.contentView.trailingAnchor constant:-20]
    ]];
}

- (void)closeButtonTapped {
    [self dismissWithFadeOut];
}

- (void)loadCustomAvatar {
    NSString *avatarPath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"avatar.jpg"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarPath]) {
        UIImage *customAvatar = [UIImage imageWithContentsOfFile:avatarPath];
        if (customAvatar) {
            self.avatarImageView.image = customAvatar;
            self.avatarImageView.backgroundColor = [UIColor clearColor];
            return;
        }
    }
    
    [self createDefaultAvatar];
}

- (void)createDefaultAvatar {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(50, 50), NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 绘制背景
    [[UIColor colorWithRed:11.0/255.0 green:223.0/255.0 blue:154.0/255.0 alpha:1.0] setFill];
    CGContextFillEllipseInRect(context, CGRectMake(0, 0, 50, 50));
    
    // 绘制字母
    NSString *letter = @"D";
    UIFont *font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    
    CGSize textSize = [letter sizeWithAttributes:attributes];
    CGPoint textPoint = CGPointMake((50 - textSize.width) / 2, (50 - textSize.height) / 2);
    [letter drawAtPoint:textPoint withAttributes:attributes];
    
    UIImage *defaultAvatar = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.avatarImageView.image = defaultAvatar;
    self.avatarImageView.backgroundColor = [UIColor clearColor];
}

- (void)avatarTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"自定义设置"
                                                                   message:@"选择要更改的选项"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *changeAvatarAction = [UIAlertAction actionWithTitle:@"更改头像" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAvatarPickerOptions];
    }];
    
    UIAlertAction *changeBackgroundAction = [UIAlertAction actionWithTitle:@"更改弹窗背景" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showBackgroundPickerOptions];
    }];
    
    UIAlertAction *resetAllAction = [UIAlertAction actionWithTitle:@"恢复默认设置" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self resetAllCustomizations];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:changeAvatarAction];
    [alert addAction:changeBackgroundAction];
    [alert addAction:resetAllAction];
    [alert addAction:cancelAction];
    
    // iPad适配
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.avatarImageView;
        alert.popoverPresentationController.sourceRect = self.avatarImageView.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAvatarPickerOptions {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择头像"
                                                                   message:@"从以下选项中选择"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *photoLibraryAction = [UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openImagePicker:UIImagePickerControllerSourceTypePhotoLibrary forType:@"avatar"];
    }];
    
    UIAlertAction *resetAction = [UIAlertAction actionWithTitle:@"恢复默认头像" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self resetToDefaultAvatar];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:photoLibraryAction];
    [alert addAction:resetAction];
    [alert addAction:cancelAction];
    
    // iPad适配
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.avatarImageView;
        alert.popoverPresentationController.sourceRect = self.avatarImageView.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showBackgroundPickerOptions {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择背景"
                                                                   message:@"从以下选项中选择"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"设置图片背景" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openImagePicker:UIImagePickerControllerSourceTypePhotoLibrary forType:@"background"];
    }];
    
    UIAlertAction *videoAction = [UIAlertAction actionWithTitle:@"设置视频背景" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openVideoPicker];
    }];
    
    UIAlertAction *resetAction = [UIAlertAction actionWithTitle:@"移除自定义背景" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self resetCustomBackground];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:photoAction];
    [alert addAction:videoAction];
    [alert addAction:resetAction];
    [alert addAction:cancelAction];
    
    // iPad适配
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.containerBlurView;
        alert.popoverPresentationController.sourceRect = self.containerBlurView.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetAllCustomizations {
    [self resetToDefaultAvatar];
    [self resetCustomBackground];
}

- (void)resetCustomBackground {
    // 移除视频播放器
    if (self.backgroundVideoLayer) {
        [self.backgroundVideoLayer removeFromSuperlayer];
        self.backgroundVideoLayer = nil;
    }
    if (self.backgroundPlayer) {
        [self.backgroundPlayer pause];
        self.backgroundPlayer = nil;
    }
    
    // 隐藏图片背景
    self.backgroundImageView.hidden = YES;
    self.backgroundImageView.image = nil;
    
    // 删除背景文件
    NSString *videoPath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.mp4"];
    NSString *imagePath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.jpg"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:videoPath]) {
        [fileManager removeItemAtPath:videoPath error:nil];
    }
    if ([fileManager fileExistsAtPath:imagePath]) {
        [fileManager removeItemAtPath:imagePath error:nil];
    }
    
    // 恢复毛玻璃效果
    self.hasCustomBackground = NO;
    BOOL isDarkMode = [DYYYManager isDarkMode];
    UIBlurEffectStyle containerBlurStyle = isDarkMode ? UIBlurEffectStyleSystemMaterialDark : UIBlurEffectStyleSystemMaterial;
    UIBlurEffect *containerBlur = [UIBlurEffect effectWithStyle:containerBlurStyle];
    self.containerBlurView.effect = containerBlur;
    self.containerBlurView.backgroundColor = [UIColor clearColor];
}

- (void)openImagePicker:(UIImagePickerControllerSourceType)sourceType forType:(NSString *)type {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = sourceType;
    
    // 存储当前处理的类型
    objc_setAssociatedObject(picker, "pickerType", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if ([type isEqualToString:@"avatar"]) {
        picker.allowsEditing = YES; // 头像允许编辑
    } else {
        picker.allowsEditing = NO;  // 背景不强制剪切
    }
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)openVideoPicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(__bridge NSString *)kUTTypeMovie];
    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
    picker.allowsEditing = NO;
    
    // 存储当前处理的类型
    objc_setAssociatedObject(picker, "pickerType", @"video", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)resetToDefaultAvatar {
    NSString *avatarPath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"avatar.jpg"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:avatarPath error:nil];
    }
    [self createDefaultAvatar];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    NSString *pickerType = (NSString *)objc_getAssociatedObject(picker, "pickerType");
    
    if ([pickerType isEqualToString:@"avatar"]) {
        [self handleAvatarSelection:info];
    } else if ([pickerType isEqualToString:@"background"]) {
        [self handleBackgroundImageSelection:info];
    } else if ([pickerType isEqualToString:@"video"]) {
        [self handleBackgroundVideoSelection:info];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleAvatarSelection:(NSDictionary *)info {
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    
    if (selectedImage) {
        // 调整图片大小
        UIImage *resizedImage = [self resizeImage:selectedImage toSize:CGSizeMake(100, 100)];
        
        // 保存到文件
        NSString *avatarPath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"avatar.jpg"];
        NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8);
        [imageData writeToFile:avatarPath atomically:YES];
        
        // 更新头像显示
        self.avatarImageView.image = resizedImage;
        self.avatarImageView.backgroundColor = [UIColor clearColor];
    }
}

- (void)handleBackgroundImageSelection:(NSDictionary *)info {
    UIImage *selectedImage = info[UIImagePickerControllerOriginalImage];
    
    if (selectedImage) {
        // 确保先移除视频背景
        if (self.backgroundVideoLayer) {
            [self.backgroundVideoLayer removeFromSuperlayer];
            self.backgroundVideoLayer = nil;
        }
        if (self.backgroundPlayer) {
            [self.backgroundPlayer pause];
            self.backgroundPlayer = nil;
        }
        
        // 删除可能存在的视频文件
        NSString *videoPath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.mp4"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
        }
        
        // 保存背景图片
        NSString *imagePath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.jpg"];
        NSData *imageData = UIImageJPEGRepresentation(selectedImage, 0.8);
        [imageData writeToFile:imagePath atomically:YES];
        
        // 更新背景显示
        self.backgroundImageView.image = selectedImage;
        self.backgroundImageView.hidden = NO;
        
        // 更新容器为半透明
        self.hasCustomBackground = YES;
        self.containerBlurView.effect = nil;
        self.containerBlurView.backgroundColor = [DYYYManager isDarkMode] ? 
            [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7] : 
            [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
    }
}

- (void)handleBackgroundVideoSelection:(NSDictionary *)info {
    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    
    if (videoURL) {
        // 移除图片背景
        self.backgroundImageView.hidden = YES;
        self.backgroundImageView.image = nil;
        
        NSString *imagePath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.jpg"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
        }
        
        NSString *videoPath = [[self dyyyDocumentsDirectory] stringByAppendingPathComponent:@"background.mp4"];
        NSError *error;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
        }
        
        // 复制新视频
        [[NSFileManager defaultManager] copyItemAtURL:videoURL toURL:[NSURL fileURLWithPath:videoPath] error:&error];
        
        if (error) {
            NSLog(@"复制视频文件失败: %@", error);
            return;
        }
        
        [self setupVideoBackground:videoPath];
        
        self.hasCustomBackground = YES;
        self.containerBlurView.effect = nil;
        self.containerBlurView.backgroundColor = [DYYYManager isDarkMode] ? 
            [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7] : 
            [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (void)setupConstraints {
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.settingsTableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 容器视图约束
        [self.containerBlurView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.containerBlurView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.containerBlurView.contentView.topAnchor constant:15],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.containerBlurView.contentView.centerXAnchor],
        
        [self.closeButton.topAnchor constraintEqualToAnchor:self.containerBlurView.contentView.topAnchor constant:15],
        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.containerBlurView.contentView.trailingAnchor constant:-15],
        [self.closeButton.widthAnchor constraintEqualToConstant:25],
        [self.closeButton.heightAnchor constraintEqualToConstant:25],
        
        [self.settingsTableView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:15],
        [self.settingsTableView.leadingAnchor constraintEqualToAnchor:self.containerBlurView.contentView.leadingAnchor constant:16],
        [self.settingsTableView.trailingAnchor constraintEqualToAnchor:self.containerBlurView.contentView.trailingAnchor constant:-16],
        [self.settingsTableView.bottomAnchor constraintEqualToAnchor:self.containerBlurView.contentView.bottomAnchor constant:-16]
    ]];
}

- (void)showModernSettingsPanel {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    self.view.alpha = 0;
    self.containerBlurView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    self.backgroundImageView.transform = self.containerBlurView.transform;
    if (self.backgroundVideoLayer) {
        CATransform3D transform = CATransform3DMakeAffineTransform(self.containerBlurView.transform);
        self.backgroundVideoLayer.transform = transform;
    }
    
    [rootVC presentViewController:self animated:NO completion:^{
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.view.alpha = 1;
            self.containerBlurView.transform = CGAffineTransformIdentity;
            
            self.backgroundImageView.transform = CGAffineTransformIdentity;
            if (self.backgroundVideoLayer) {
                self.backgroundVideoLayer.transform = CATransform3DIdentity;
            }
        } completion:^(BOOL finished) {
            [self updateVideoLayerFrame];
        }];
    }];
}

- (void)dismissWithFadeOut {
    [UIView animateWithDuration:0.25 animations:^{
        self.view.alpha = 0;
        self.containerBlurView.transform = CGAffineTransformMakeScale(0.85, 0.85);
        
        self.backgroundImageView.transform = self.containerBlurView.transform;
        if (self.backgroundVideoLayer) {
            CATransform3D transform = CATransform3DMakeAffineTransform(self.containerBlurView.transform);
            self.backgroundVideoLayer.transform = transform;
        }
    } completion:^(BOOL finished) {
        if (self.backgroundVideoLayer) {
            [self.backgroundVideoLayer removeFromSuperlayer];
        }
        if (self.backgroundPlayer) {
            [self.backgroundPlayer pause];
        }
        
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

#pragma mark - UITableView DataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.settingsData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *sectionData = self.settingsData[section];
    BOOL expanded = [sectionData[@"expanded"] boolValue];
    return expanded ? [sectionData[@"items"] count] + 1 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    // 清除之前的子视图
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }
    
    NSDictionary *sectionData = self.settingsData[indexPath.section];
    BOOL isDarkMode = [DYYYManager isDarkMode];
    BOOL expanded = [sectionData[@"expanded"] boolValue];
    
    if (indexPath.row == 0) {
        // 分类标题行 - 根据模式选择毛玻璃样式
        UIBlurEffectStyle cellBlurStyle = isDarkMode ? UIBlurEffectStyleSystemMaterialDark : UIBlurEffectStyleSystemMaterial;
        UIBlurEffect *cellBlur = [UIBlurEffect effectWithStyle:cellBlurStyle];
        UIVisualEffectView *cellBlurView = [[UIVisualEffectView alloc] initWithEffect:cellBlur];
        cellBlurView.layer.cornerRadius = expanded ? 12 : 12;
        cellBlurView.clipsToBounds = YES;
        cellBlurView.alpha = 0.9;
        
        if (expanded) {
            cellBlurView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        }
        
        cell.backgroundView = cellBlurView;
        
        [self setupSectionHeaderCell:cell withData:sectionData section:indexPath.section];
    } else {
        // 设置项行 - 根据暗黑模式设置背景色
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.1 alpha:0.3] : [UIColor colorWithWhite:0.9 alpha:0.3];
        
        // 获取section中的总行数
        NSInteger totalRows = [sectionData[@"items"] count];
        BOOL isLastRow = (indexPath.row == totalRows);
        
        if (isLastRow) {
            // 最后一行设置底部圆角
            backgroundView.layer.cornerRadius = 12;
            backgroundView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
        }
        
        cell.backgroundView = backgroundView;
        
        NSArray *items = sectionData[@"items"];
        NSDictionary *item = items[indexPath.row - 1];
        [self setupSettingItemCell:cell withData:item indexPath:indexPath];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)setupSectionHeaderCell:(UITableViewCell *)cell withData:(NSDictionary *)sectionData section:(NSInteger)section {
    BOOL isDarkMode = [DYYYManager isDarkMode];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = sectionData[@"title"];
    titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    titleLabel.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor labelColor];
    
    UIImageView *arrowImageView = [[UIImageView alloc] init];
    BOOL expanded = [sectionData[@"expanded"] boolValue];
    arrowImageView.image = [self createArrowImageWithExpanded:expanded];
    arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [cell.contentView addSubview:titleLabel];
    [cell.contentView addSubview:arrowImageView];
    
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:20],
        [titleLabel.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
        
        [arrowImageView.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-20],
        [arrowImageView.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
        [arrowImageView.widthAnchor constraintEqualToConstant:12],
        [arrowImageView.heightAnchor constraintEqualToConstant:12]
    ]];
}

- (UIImage *)createArrowImageWithExpanded:(BOOL)expanded {
    BOOL isDarkMode = [DYYYManager isDarkMode];
    CGSize size = CGSizeMake(12, 12);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *arrowColor = isDarkMode ? [UIColor colorWithWhite:0.8 alpha:1.0] : [UIColor colorWithWhite:0.6 alpha:1.0];
    [arrowColor setStroke];
    CGContextSetLineWidth(context, 1.5);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    if (expanded) {
        // 向下箭头 ↓
        CGContextMoveToPoint(context, 3, 5);
        CGContextAddLineToPoint(context, 6, 8);
        CGContextAddLineToPoint(context, 9, 5);
    } else {
        // 向右箭头 →
        CGContextMoveToPoint(context, 5, 3);
        CGContextAddLineToPoint(context, 8, 6);
        CGContextAddLineToPoint(context, 5, 9);
    }
    
    CGContextStrokePath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)setupSettingItemCell:(UITableViewCell *)cell withData:(NSDictionary *)item indexPath:(NSIndexPath *)indexPath {
    BOOL isDarkMode = [DYYYManager isDarkMode];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = item[@"title"];
    titleLabel.font = [UIFont systemFontOfSize:12];
    titleLabel.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor labelColor];
    [cell.contentView addSubview:titleLabel];
    
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:@"input"]) {
        UIButton *inputButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [inputButton setTitle:item[@"value"] forState:UIControlStateNormal];
        inputButton.titleLabel.font = [UIFont systemFontOfSize:11];
        inputButton.titleLabel.textAlignment = NSTextAlignmentRight; 
        inputButton.tintColor = isDarkMode ? [UIColor colorWithWhite:0.8 alpha:1.0] : [UIColor secondaryLabelColor];
        inputButton.layer.cornerRadius = 6;
        inputButton.tag = indexPath.section * 1000 + indexPath.row;
        [inputButton addTarget:self action:@selector(inputButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIBlurEffectStyle inputBlurStyle = isDarkMode ? UIBlurEffectStyleSystemThinMaterialDark : UIBlurEffectStyleSystemThinMaterial;
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:inputBlurStyle];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.layer.cornerRadius = 6;
        blurView.layer.masksToBounds = YES;
        blurView.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.2 alpha:0.2] : [UIColor colorWithWhite:0.5 alpha:0.2];
        blurView.userInteractionEnabled = NO;
        [inputButton insertSubview:blurView atIndex:0];
        
        [cell.contentView addSubview:inputButton];
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        inputButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:20],
            [titleLabel.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
            [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:inputButton.leadingAnchor constant:-15],
            
            [inputButton.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-20],
            [inputButton.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
            [inputButton.widthAnchor constraintEqualToConstant:60],
            [inputButton.heightAnchor constraintEqualToConstant:26]
        ]];
    } else if ([type isEqualToString:@"switch"]) {
        UISwitch *switchControl = [[UISwitch alloc] init];
        switchControl.on = [item[@"value"] boolValue];
        switchControl.onTintColor = [UIColor colorWithRed:11.0/255.0 green:223.0/255.0 blue:154.0/255.0 alpha:1.0]; // #0BDF9A
        switchControl.tag = indexPath.section * 1000 + indexPath.row;
        switchControl.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [switchControl addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:switchControl];
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        switchControl.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:20],
            [titleLabel.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
            
            [switchControl.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-20],
            [switchControl.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor]
        ]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        NSMutableDictionary *sectionData = self.settingsData[indexPath.section];
        BOOL expanded = [sectionData[@"expanded"] boolValue];
        sectionData[@"expanded"] = @(!expanded);
        
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 0 ? 40 : 35;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 5;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - Actions

- (void)inputButtonTapped:(UIButton *)sender {
    NSInteger section = sender.tag / 1000;
    NSInteger row = sender.tag % 1000;
    
    NSArray *items = self.settingsData[section][@"items"];
    NSDictionary *item = items[row - 1];
    NSString *itemKey = item[@"key"];
    
    DYYYCustomInputView *inputView = [[DYYYCustomInputView alloc] initWithTitle:item[@"title"] 
                                                                    defaultText:item[@"value"] 
                                                                    placeholder:@"请输入内容"];
    
    __weak typeof(self) weakSelf = self;
    inputView.onConfirm = ^(NSString *text) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            NSMutableArray *mutableItems = [strongSelf.settingsData[section][@"items"] mutableCopy];
            NSMutableDictionary *mutableItem = [mutableItems[row - 1] mutableCopy];
            mutableItem[@"value"] = text;
            mutableItems[row - 1] = mutableItem;
            strongSelf.settingsData[section][@"items"] = mutableItems;
            
            [[NSUserDefaults standardUserDefaults] setObject:text forKey:itemKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [strongSelf.settingsTableView reloadData];
        }
    };
    
    [inputView show];
}

- (void)switchValueChanged:(UISwitch *)sender {
    NSInteger section = sender.tag / 1000;
    NSInteger row = sender.tag % 1000;
    
    NSMutableArray *mutableItems = [self.settingsData[section][@"items"] mutableCopy];
    NSMutableDictionary *mutableItem = [mutableItems[row - 1] mutableCopy];
    mutableItem[@"value"] = @(sender.isOn);
    mutableItems[row - 1] = mutableItem;
    self.settingsData[section][@"items"] = mutableItems;
    
    NSString *itemKey = mutableItem[@"key"];
    
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:itemKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc {
    if (self.backgroundPlayer) {
        [self.backgroundPlayer pause];
        self.backgroundPlayer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end