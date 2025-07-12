#import "AwemeHeaders.h"
#import "DYYYManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "DYYYABTestHook.h"

#import "DYYYAboutDialogView.h"
#import "DYYYBottomAlertView.h"
#import "DYYYCustomInputView.h"
#import "DYYYIconOptionsDialogView.h"
#import "DYYYKeywordListView.h"
#import "DYYYOptionsSelectionView.h"

#import "DYYYConstants.h"
#import "DYYYSettingsHelper.h"
#import "DYYYUtils.h"

@class DYYYIconOptionsDialogView;
static void showIconOptionsDialog(NSString *title, UIImage *previewImage, NSString *saveFilename, void (^onClear)(void), void (^onSelect)(void));

#import "DYYYBackupPickerDelegate.h"
#import "DYYYImagePickerDelegate.h"

#ifdef __cplusplus
extern "C" {
#endif
void *kViewModelKey = &kViewModelKey;
#ifdef __cplusplus
}
#endif
%hook AWESettingBaseViewController
- (bool)useCardUIStyle {
    return YES;
}

- (AWESettingBaseViewModel *)viewModel {
    AWESettingBaseViewModel *original = %orig;
    if (!original)
        return objc_getAssociatedObject(self, &kViewModelKey);
    return original;
}
%end

%hook AWELeftSideBarWeatherLabel
- (id)initWithFrame:(CGRect)frame {
    id orig = %orig;
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:[UIView class] action:@selector(openDYYYSettingsFromSender:)];
    objc_setAssociatedObject(tapGesture, "targetView", self, OBJC_ASSOCIATION_ASSIGN);
    [self addGestureRecognizer:tapGesture];
    return orig;
}

- (void)drawTextInRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);

    NSDictionary *attributes = @{NSFontAttributeName : [UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName : self.textColor};
    [@"DYYY" drawInRect:rect withAttributes:attributes];
}
%end

%hook AWELeftSideBarWeatherView
- (void)didMoveToSuperview {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      CGRect frame = self.frame;
      frame.origin.y += 10;
      self.frame = frame;
    });
}

- (void)layoutSubviews {
    %orig;
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:[UIView class] action:@selector(openDYYYSettingsFromSender:)];
    objc_setAssociatedObject(tapGesture, "targetView", self, OBJC_ASSOCIATION_ASSIGN);
    [self addGestureRecognizer:tapGesture];

    for (UIView *subview in self.subviews) {
        subview.userInteractionEnabled = YES;
        UITapGestureRecognizer *subTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:[UIView class] action:@selector(openDYYYSettingsFromSender:)];
        objc_setAssociatedObject(subTapGesture, "targetView", self, OBJC_ASSOCIATION_ASSIGN);
        [subview addGestureRecognizer:subTapGesture];

        [subview.subviews enumerateObjectsUsingBlock:^(UIView *childView, NSUInteger idx, BOOL *stop) {
          if (![childView isKindOfClass:%c(AWELeftSideBarWeatherLabel)]) {
              [childView removeFromSuperview];
          }
        }];
    }
}
%end

%hook AWELeftSideBarEntranceView
- (void)leftSideBarEntranceViewTapped:(UITapGestureRecognizer *)gesture {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEntrance"]) {
        %orig;
        return;
    }

    UIViewController *feedVC = [DYYYSettingsHelper findViewController:self];
    if (![feedVC isKindOfClass:%c(AWEFeedContainerViewController)]) {
        feedVC = UIApplication.sharedApplication.keyWindow.rootViewController;
        while (feedVC && ![feedVC isKindOfClass:%c(AWEFeedContainerViewController)]) {
            feedVC = feedVC.presentedViewController;
        }
    }

    if (feedVC) {
        [DYYYSettingsHelper openSettingsWithViewController:feedVC];
    } else {
        %orig;
    }
}
%end

%hook UIView
%new
+ (void)openDYYYSettingsFromSender:(UITapGestureRecognizer *)sender {
    UIView *targetView = objc_getAssociatedObject(sender, "targetView");
    if (targetView) {
        [DYYYSettingsHelper openSettingsFromView:targetView];
    }
}
%end

#ifdef __cplusplus
extern "C"
#endif
    void
    showDYYYSettingsVC(UIViewController *rootVC, BOOL hasAgreed) {
    AWESettingBaseViewController *settingsVC = [[%c(AWESettingBaseViewController) alloc] init];
    if (!hasAgreed) {
        [DYYYSettingsHelper showAboutDialog:@"用户协议"
                                    message:@"本插件为开源项目\n仅供学习交流用途\n如有侵权请联系, GitHub 仓库：huami1314/DYYY\n请遵守当地法律法规, "
                                            @"逆向工程仅为学习目的\n盗用源码进行商业用途/发布但未标记开源项目必究\n详情请参阅项目内 MIT 许可证\n\n请输入\"我已阅读并同意继续使用\"以继续"
                                  onConfirm:^{
                                    [DYYYSettingsHelper showUserAgreementAlert];
                                  }];
    }

    // 等待视图加载并使用KVO安全访问属性
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([settingsVC.view isKindOfClass:[UIView class]]) {
          for (UIView *subview in settingsVC.view.subviews) {
              if ([subview isKindOfClass:%c(AWENavigationBar)]) {
                  AWENavigationBar *navigationBar = (AWENavigationBar *)subview;
                  if ([navigationBar respondsToSelector:@selector(titleLabel)]) {
                      navigationBar.titleLabel.text = DYYY_NAME;
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
          @{@"identifier" : @"DYYYEnableDanmuColor",
            @"title" : @"启用弹幕改色",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_dansquare_outlined_20"},
          @{
              @"identifier" : @"DYYYDanmuColor",
              @"title" : @"自定弹幕颜色",
              @"subTitle" : @"填入 random 使用随机颜色弹幕",
              @"detail" : @"十六进制",
              @"cellType" : @20,
              @"imageName" : @"ic_dansquarenut_outlined_20"
          },
          @{
              @"identifier" : @"DYYYDanmuRainbowRotating",
              @"title" : @"旋转彩虹弹幕",
              @"subTitle" : @"启用后将覆盖上面的自定义弹幕颜色",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_dansquarenut_outlined_20"
          }
      ];

      for (NSDictionary *dict in appearanceSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          [appearanceItems addObject:item];
      }

      // 【视频播放设置】分类
      NSMutableArray<AWESettingItemModel *> *videoItems = [NSMutableArray array];
      NSArray *videoSettings = @[
          @{
              @"identifier" : @"DYYYVideoBGColor",
              @"title" : @"视频背景颜色",
              @"subTitle" : @"可以自定义部分横屏视频的背景颜色",
              @"detail" : @"",
              @"cellType" : @20,
              @"imageName" : @"ic_tv_outlined_20"
          },
          @{@"identifier" : @"DYYYShowScheduleDisplay",
            @"title" : @"显示进度时长",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_playertime_outlined_20"},
          @{@"identifier" : @"DYYYScheduleStyle",
            @"title" : @"进度时长样式",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_playertime_outlined_20"},
          @{@"identifier" : @"DYYYProgressLabelColor",
            @"title" : @"进度标签颜色",
            @"detail" : @"十六进制",
            @"cellType" : @26,
            @"imageName" : @"ic_playertime_outlined_20"},
          @{@"identifier" : @"DYYYTimelineVerticalPosition",
            @"title" : @"进度纵轴位置",
            @"detail" : @"-12.5",
            @"cellType" : @26,
            @"imageName" : @"ic_playertime_outlined_20"},
          @{@"identifier" : @"DYYYHideVideoProgress",
            @"title" : @"隐藏视频进度",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_playertime_outlined_20"},
          @{
              @"identifier" : @"DYYYEnableAutoPlay",
              @"title" : @"启用自动播放",
              @"subTitle" : @"暂时仅支持推荐、搜索和个人主页的自动连播",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_play_outlined_12"
          },
          @{@"identifier" : @"DYYYDefaultSpeed",
            @"title" : @"设置默认倍速",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_speed_outlined_20"},
          @{@"identifier" : @"DYYYLongPressSpeed",
            @"title" : @"设置长按倍速",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_speed_outlined_20"},
          @{@"identifier" : @"DYYYEnableArea",
            @"title" : @"时间属地显示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_location_outlined_20"},
          @{
              @"identifier" : @"DYYYGeonamesUsername",
              @"title" : @"国外解析账号",
              @"subTitle" : @"使用 Geonames.org 账号解析国外 IP 属地",
              @"detail" : @"",
              @"cellType" : @20,
              @"imageName" : @"ic_location_outlined_20"
          },
          @{@"identifier" : @"DYYYLabelColor",
            @"title" : @"属地标签颜色",
            @"detail" : @"十六进制",
            @"cellType" : @26,
            @"imageName" : @"ic_location_outlined_20"},
          @{
              @"identifier" : @"DYYYEnableRandomGradient",
              @"title" : @"属地随机渐变",
              @"subTitle" : @"启用后将覆盖上面的属地标签颜色",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_location_outlined_20"
          }
      ];

      for (NSDictionary *dict in videoSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];

          if ([item.identifier isEqualToString:@"DYYYDefaultSpeed"]) {
              NSString *savedSpeed = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDefaultSpeed"];
              item.detail = savedSpeed ?: @"1.0x";

              item.cellTappedBlock = ^{
                NSArray *speedOptions = @[ @"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x", @"2.5x", @"3.0x" ];

                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYDefaultSpeed"
                                                   optionsArray:speedOptions
                                                     headerText:@"选择默认倍速"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          }

          else if ([item.identifier isEqualToString:@"DYYYLongPressSpeed"]) {
              NSString *savedSpeed = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLongPressSpeed"];
              item.detail = savedSpeed ?: @"2.0x";

              item.cellTappedBlock = ^{
                NSArray *speedOptions = @[ @"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x", @"2.5x", @"3.0x" ];

                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYLongPressSpeed"
                                                   optionsArray:speedOptions
                                                     headerText:@"选择右侧长按倍速"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          }

          else if ([item.identifier isEqualToString:@"DYYYScheduleStyle"]) {
              NSString *savedStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
              item.detail = savedStyle ?: @"默认";
              item.cellTappedBlock = ^{
                NSArray *styleOptions = @[ @"进度条两侧上下", @"进度条左侧剩余", @"进度条左侧完整", @"进度条右侧剩余", @"进度条右侧完整" ];

                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYScheduleStyle"
                                                   optionsArray:styleOptions
                                                     headerText:@"选择进度时长样式"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          }

          [videoItems addObject:item];
      }
      // 【杂项设置】分类
      NSMutableArray<AWESettingItemModel *> *miscellaneousItems = [NSMutableArray array];
      NSArray *miscellaneousSettings = @[
          @{@"identifier" : @"DYYYLiveQuality",
            @"title" : @"默认直播画质",
            @"detail" : @"自动",
            @"cellType" : @26,
            @"imageName" : @"ic_video_outlined_20"},
          @{@"identifier" : @"DYYYEnableVideoHighestQuality",
            @"title" : @"提高视频画质",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_squaretriangletwo_outlined_20"},
          @{@"identifier" : @"DYYYHideStatusbar",
            @"title" : @"隐藏系统顶栏",
            @"subTitle" : @"隐藏系统状态栏",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYEnablePure",
            @"title" : @"启用首页净化",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_broom_outlined"},
          @{@"identifier" : @"DYYYEnableFullScreen",
            @"title" : @"启用首页全屏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_fullscreen_outlined_16"}
      ];

      for (NSDictionary *dict in miscellaneousSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];

          if ([item.identifier isEqualToString:@"DYYYLiveQuality"]) {
              NSString *savedQuality = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLiveQuality"] ?: @"自动";
              item.detail = savedQuality;
              item.cellTappedBlock = ^{
                NSArray *qualities = @[ @"蓝光帧彩", @"蓝光", @"超清", @"高清", @"标清", @"自动" ];

                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYLiveQuality"
                                                   optionsArray:qualities
                                                     headerText:@"选择默认直播画质\n无对应画质时会切换到比选择画质低一级的画质"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          }

          [miscellaneousItems addObject:item];
      }
      // 【过滤与屏蔽】分类
      NSMutableArray<AWESettingItemModel *> *filterItems = [NSMutableArray array];
      NSArray *filterSettings = @[
          @{@"identifier" : @"DYYYSkipLive",
            @"title" : @"推荐过滤直播",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_video_outlined_20"},
          @{@"identifier" : @"DYYYSkipHotSpot",
            @"title" : @"推荐过滤热点",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_squaretriangletwo_outlined_20"},
          @{@"identifier" : @"DYYYFilterLowLikes",
            @"title" : @"推荐过滤低赞",
            @"detail" : @"0",
            @"cellType" : @26,
            @"imageName" : @"ic_thumbsdown_outlined_20"},
          @{@"identifier" : @"DYYYFilterUsers",
            @"title" : @"推荐过滤用户",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_userban_outlined_20"},
          @{@"identifier" : @"DYYYFilterKeywords",
            @"title" : @"推荐过滤文案",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_tag_outlined_20"},
          @{@"identifier" : @"DYYYFilterTimeLimit",
            @"title" : @"推荐视频时限",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_playertime_outlined_20"},
          @{@"identifier" : @"DYYYFilterFeedHDR",
            @"title" : @"推荐过滤HDR",
            @"subTitle" : @"开启后推荐流会屏蔽 HDR 视频",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_sun_outlined"},
          @{@"identifier" : @"DYYYFilterProp",
            @"title" : @"推荐过滤拍同款",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_tag_outlined_20"},
          @{@"identifier" : @"DYYYNoAds",
            @"title" : @"启用屏蔽广告",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_ad_outlined_20"},
          @{@"identifier" : @"DYYYHideteenmode",
            @"title" : @"移除青少年弹窗",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_personcircleclean_outlined_20"},
          @{@"identifier" : @"DYYYNoUpdates",
            @"title" : @"屏蔽抖音检测更新",
            @"subTitle" : @"屏蔽抖音应用的版本更新",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_circletop_outlined"},
          @{@"identifier" : @"DYYYDisableLivePCDN",
            @"title" : @"屏蔽直播PCDN功能",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_video_outlined_20"}
      ];

      for (NSDictionary *dict in filterSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];

          if ([item.identifier isEqualToString:@"DYYYFilterLowLikes"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterLowLikes"];
              item.detail = savedValue ?: @"0";
              item.cellTappedBlock = ^{
                [DYYYSettingsHelper showTextInputAlert:@"设置过滤赞数阈值"
                                           defaultText:item.detail
                                           placeholder:@"填0关闭功能"
                                             onConfirm:^(NSString *text) {
                                               NSScanner *scanner = [NSScanner scannerWithString:text];
                                               NSInteger value;
                                               BOOL isValidNumber = [scanner scanInteger:&value] && [scanner isAtEnd];

                                               if (isValidNumber) {
                                                   if (value < 0)
                                                       value = 0;
                                                   NSString *valueString = [NSString stringWithFormat:@"%ld", (long)value];
                                                   [DYYYSettingsHelper setUserDefaults:valueString forKey:@"DYYYFilterLowLikes"];

                                                   item.detail = valueString;
                                                   [item refreshCell];
                                               } else {
                                                   DYYYAboutDialogView *errorDialog = [[DYYYAboutDialogView alloc] initWithTitle:@"输入错误" message:@"\n\n请输入有效的数字\n\n"];
                                                   [errorDialog show];
                                               }
                                             }
                                              onCancel:nil];
              };
          } else if ([item.identifier isEqualToString:@"DYYYFilterUsers"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterUsers"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                // 将保存的逗号分隔字符串转换为数组
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterUsers"] ?: @"";
                NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:keywordArray];
                keywordListView.onConfirm = ^(NSArray *keywords) {
                  NSString *keywordString = [keywords componentsJoinedByString:@","];
                  [DYYYSettingsHelper setUserDefaults:keywordString forKey:@"DYYYFilterUsers"];
                  item.detail = keywordString;
                  [item refreshCell];
                };

                [keywordListView show];
              };
          } else if ([item.identifier isEqualToString:@"DYYYFilterKeywords"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];
                keywordListView.onConfirm = ^(NSArray *keywords) {
                  NSString *keywordString = [keywords componentsJoinedByString:@","];

                  [DYYYSettingsHelper setUserDefaults:keywordString forKey:@"DYYYFilterKeywords"];
                  item.detail = keywordString;
                  [item refreshCell];
                };
                [keywordListView show];
              };
          } else if ([item.identifier isEqualToString:@"DYYYFilterTimeLimit"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterTimeLimit"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                [DYYYSettingsHelper showTextInputAlert:@"过滤视频的发布时间"
                                           defaultText:item.detail
                                           placeholder:@"单位为天"
                                             onConfirm:^(NSString *text) {
                                               NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                               [DYYYSettingsHelper setUserDefaults:trimmedText forKey:@"DYYYFilterTimeLimit"];
                                               item.detail = trimmedText ?: @"";
                                               [item refreshCell];
                                             }
                                              onCancel:nil];
              };
          } else if ([item.identifier isEqualToString:@"DYYYFilterProp"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterProp"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterProp"] ?: @"";
                NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤词（支持部分匹配）" keywords:keywordArray];
                keywordListView.onConfirm = ^(NSArray *keywords) {
                  NSString *keywordString = [keywords componentsJoinedByString:@","];

                  [DYYYSettingsHelper setUserDefaults:keywordString forKey:@"DYYYFilterProp"];
                  item.detail = keywordString;
                  [item refreshCell];
                };
                [keywordListView show];
              };
          }
          [filterItems addObject:item];
      }

      // 【二次确认】分类
      NSMutableArray<AWESettingItemModel *> *securityItems = [NSMutableArray array];
      NSArray *securitySettings = @[
          @{@"identifier" : @"DYYYFollowTips",
            @"title" : @"关注二次确认",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_userplus_outlined_20"},
          @{@"identifier" : @"DYYYCollectTips",
            @"title" : @"收藏二次确认",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_star_outlined_20"}
      ];

      for (NSDictionary *dict in securitySettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [securityItems addObject:item];
      }

      // 创建并组织所有section
      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"外观设置" items:appearanceItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"视频播放" items:videoItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"杂项设置" items:miscellaneousItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"过滤与屏蔽" footerTitle:@"请不要同时开启过多过滤推荐项目，这会增大视频流加载延迟。" items:filterItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"二次确认" items:securityItems]];

      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"基本设置" sections:sections];
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
          @{@"identifier" : @"DYYYTopBarTransparent",
            @"title" : @"设置顶栏透明",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_module_outlined_20"},
          @{@"identifier" : @"DYYYGlobalTransparency",
            @"title" : @"设置全局透明",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_eye_outlined_20"},
          @{@"identifier" : @"DYYYAvatarViewTransparency",
            @"title" : @"首页头像透明",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_user_outlined_20"},
          @{@"identifier" : @"DYYYEnableCommentBlur",
            @"title" : @"评论区毛玻璃",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_comment_outlined_20"},
          @{@"identifier" : @"DYYYEnableNotificationTransparency",
            @"title" : @"通知栏毛玻璃",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_comment_outlined_20"},
          @{@"identifier" : @"DYYYNotificationCornerRadius",
            @"title" : @"通知圆角半径",
            @"detail" : @"默认12",
            @"cellType" : @26,
            @"imageName" : @"ic_comment_outlined_20"},
          @{@"identifier" : @"DYYYCommentBlurTransparent",
            @"title" : @"毛玻璃透明度",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_eye_outlined_20"},
      ];

      for (NSDictionary *dict in transparencySettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          [transparencyItems addObject:item];
      }

      // 【缩放与大小】分类
      NSMutableArray<AWESettingItemModel *> *scaleItems = [NSMutableArray array];
      NSArray *scaleSettings = @[
          @{@"identifier" : @"DYYYElementScale",
            @"title" : @"右侧栏缩放度",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_zoomin_outlined_20"},
          @{@"identifier" : @"DYYYNicknameScale",
            @"title" : @"昵称文案缩放",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_zoomin_outlined_20"},
          @{@"identifier" : @"DYYYNicknameVerticalOffset",
            @"title" : @"昵称下移距离",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_pensketch_outlined_20"},
          @{@"identifier" : @"DYYYDescriptionVerticalOffset",
            @"title" : @"文案下移距离",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_pensketch_outlined_20"},
          @{@"identifier" : @"DYYYIPLabelVerticalOffset",
            @"title" : @"属地上移距离",
            @"detail" : @"默认为 3",
            @"cellType" : @26,
            @"imageName" : @"ic_pensketch_outlined_20"},
          @{@"identifier" : @"DYYYTabBarHeight",
            @"title" : @"修改底栏高度",
            @"detail" : @"默认为空",
            @"cellType" : @26,
            @"imageName" : @"ic_pensketch_outlined_20"},
      ];

      for (NSDictionary *dict in scaleSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          [scaleItems addObject:item];
      }

      // 【标题自定义】分类
      NSMutableArray<AWESettingItemModel *> *titleItems = [NSMutableArray array];
      NSArray *titleSettings = @[
          @{@"identifier" : @"DYYYModifyTopTabText",
            @"title" : @"设置顶栏标题",
            @"detail" : @"标题=修改#标题=修改",
            @"cellType" : @26,
            @"imageName" : @"ic_tag_outlined_20"},
          @{@"identifier" : @"DYYYIndexTitle",
            @"title" : @"设置首页标题",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_squaretriangle_outlined_20"},
          @{@"identifier" : @"DYYYFriendsTitle",
            @"title" : @"设置朋友标题",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_usertwo_outlined_20"},
          @{@"identifier" : @"DYYYMsgTitle",
            @"title" : @"设置消息标题",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_msg_outlined_20"},
          @{@"identifier" : @"DYYYSelfTitle",
            @"title" : @"设置我的标题",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_user_outlined_20"},
      ];

      for (NSDictionary *dict in titleSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          if ([item.identifier isEqualToString:@"DYYYModifyTopTabText"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYModifyTopTabText"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                NSString *savedPairs = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYModifyTopTabText"] ?: @"";
                NSArray *pairArray = savedPairs.length > 0 ? [savedPairs componentsSeparatedByString:@"#"] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置顶栏标题" keywords:pairArray];
                keywordListView.addItemTitle = @"添加标题修改";
                keywordListView.editItemTitle = @"编辑标题修改";
                keywordListView.inputPlaceholder = @"原标题=新标题";
                keywordListView.onConfirm = ^(NSArray *keywords) {
                  NSString *keywordString = [keywords componentsJoinedByString:@"#"];
                  [DYYYSettingsHelper setUserDefaults:keywordString forKey:@"DYYYModifyTopTabText"];
                  item.detail = keywordString;
                  [item refreshCell];
                };
                [keywordListView show];
              };
          }
          [titleItems addObject:item];
      }

      // 【图标自定义】分类
      NSMutableArray<AWESettingItemModel *> *iconItems = [NSMutableArray array];

      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconLikeBefore" title:@"未点赞图标" svgIcon:@"ic_heart_outlined_20" saveFile:@"like_before.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconLikeAfter" title:@"已点赞图标" svgIcon:@"ic_heart_filled_20" saveFile:@"like_after.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconComment" title:@"评论的图标" svgIcon:@"ic_comment_outlined_20" saveFile:@"comment.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconUnfavorite" title:@"未收藏图标" svgIcon:@"ic_star_outlined_20" saveFile:@"unfavorite.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconFavorite" title:@"已收藏图标" svgIcon:@"ic_star_filled_20" saveFile:@"favorite.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconShare" title:@"分享的图标" svgIcon:@"ic_share_outlined" saveFile:@"share.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconPlus" title:@"拍摄的图标" svgIcon:@"ic_camera_outlined" saveFile:@"tab_plus.png"]];

      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"透明度设置" items:transparencyItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"缩放与大小" items:scaleItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"标题自定义" items:titleItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"图标自定义" items:iconItems]];
      // 创建并组织所有section
      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"界面设置" sections:sections];
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
          @{
              @"identifier" : @"DYYYHideBottomBg",
              @"title" : @"隐藏底栏背景",
              @"subTitle" : @"完全透明化底栏，可能需要配合首页全屏使用",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideBottomDot",
            @"title" : @"隐藏底栏红点",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideDoubleColumnEntry",
              @"title" : @"隐藏双列箭头",
              @"subTitle" : @"隐藏底栏首页旁的双列箭头",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideShopButton",
            @"title" : @"隐藏底栏商城",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMessageButton",
            @"title" : @"隐藏底栏消息",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideFriendsButton",
            @"title" : @"隐藏底栏朋友",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePlusButton",
            @"title" : @"隐藏底栏加号",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMyButton",
            @"title" : @"隐藏底栏我的",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideComment",
            @"title" : @"隐藏底栏评论",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideHotSearch",
            @"title" : @"隐藏底栏热榜",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTopBarBadge",
            @"title" : @"隐藏顶栏红点",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}
      ];

      for (NSDictionary *dict in mainUiSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [mainUiItems addObject:item];
      }

      // 【视频播放界面】分类
      NSMutableArray<AWESettingItemModel *> *videoUiItems = [NSMutableArray array];
      NSArray *videoUiSettings = @[
          @{@"identifier" : @"DYYYHideLOTAnimationView",
            @"title" : @"隐藏头像加号",
            @"subTitle" : @"原始位置可点击",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideFollowPromptView",
            @"title" : @"移除头像加号",
            @"subTitle" : @"完全移除不可点击",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLikeLabel",
            @"title" : @"隐藏点赞数值",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLabel",
            @"title" : @"隐藏评论数值",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCollectLabel",
            @"title" : @"隐藏收藏数值",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideShareLabel",
            @"title" : @"隐藏分享数值",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLikeButton",
            @"title" : @"隐藏点赞按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentButton",
            @"title" : @"隐藏评论按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCollectButton",
            @"title" : @"隐藏收藏按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideShareButton",
            @"title" : @"隐藏分享按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideAvatarButton",
            @"title" : @"隐藏头像按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMusicButton",
            @"title" : @"隐藏音乐按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideEntry",
            @"title" : @"隐藏全屏观看",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideGradient",
              @"title" : @"隐藏遮罩效果",
              @"subTitle" : @"优化视频文案展开时出现的黑色背景遮罩效果，但可能对部分视频的文案可读性产生一定影响。",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          }
      ];

      for (NSDictionary *dict in videoUiSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [videoUiItems addObject:item];
      }

      // 【侧边栏】分类
      NSMutableArray<AWESettingItemModel *> *sidebarItems = [NSMutableArray array];
      NSArray *sidebarSettings = @[
          @{@"identifier" : @"DYYYHideSidebarElements",
            @"title" : @"隐藏侧栏元素",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideSidebarDot",
            @"title" : @"隐藏侧栏红点",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLeftSideBar",
            @"title" : @"隐藏左侧边栏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideBack",
            @"title" : @"隐藏返回按钮",
            @"subTitle" : @"主页视频左上角的返回按钮",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideSettingsAbout",
            @"title" : @"隐藏设置关于",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
      ];

      for (NSDictionary *dict in sidebarSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [sidebarItems addObject:item];
      }

      // 【消息页与我的页】分类
      NSMutableArray<AWESettingItemModel *> *messageAndMineItems = [NSMutableArray array];
      NSArray *messageAndMineSettings = @[
          @{@"identifier" : @"DYYYHidePushBanner",
            @"title" : @"隐藏通知权限提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideAvatarList",
            @"title" : @"隐藏消息头像列表",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideAvatarBubble",
            @"title" : @"隐藏消息头像气泡",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideButton",
            @"title" : @"隐藏我的添加朋友",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideFamiliar",
            @"title" : @"隐藏朋友日常按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGroupShop",
            @"title" : @"隐藏群聊商店按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGroupLiveIndicator",
            @"title" : @"隐藏群头像直播中",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGroupInputActionBar",
            @"title" : @"隐藏聊天页工具栏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePostView",
            @"title" : @"隐藏我的页发作品",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}
      ];
      for (NSDictionary *dict in messageAndMineSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [messageAndMineItems addObject:item];
      }

      // 【提示与位置信息】分类
      NSMutableArray<AWESettingItemModel *> *infoItems = [NSMutableArray array];
      NSArray *infoSettings = @[
          @{@"identifier" : @"DYYYHideLiveView",
            @"title" : @"隐藏关注顶端",
            @"subTitle" : @"隐藏关注页顶端的直播列表",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideMenuView",
              @"title" : @"隐藏同城顶端",
              @"subTitle" : @"隐藏同城页顶端的团购等菜单",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideNearbyCapsuleView",
            @"title" : @"隐藏吃喝玩乐",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideDiscover",
            @"title" : @"隐藏右上搜索",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentDiscover",
            @"title" : @"隐藏评论搜索",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideInteractionSearch",
            @"title" : @"隐藏相关搜索",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideSearchBubble",
              @"title" : @"隐藏弹出热搜",
              @"subTitle" : @"从右上搜索位置处弹出的热搜白框",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideSearchSame",
            @"title" : @"隐藏搜索同款",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideSearchEntrance",
            @"title" : @"隐藏顶部搜索框",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideSearchEntranceIndicator",
            @"title" : @"隐藏搜索框背景",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideDanmuButton",
            @"title" : @"隐藏弹幕按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCancelMute",
            @"title" : @"隐藏静音按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLocation",
            @"title" : @"隐藏视频定位",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideQuqishuiting",
            @"title" : @"隐藏去汽水听",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGongChuang",
            @"title" : @"隐藏共创头像",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideHotspot",
            @"title" : @"隐藏热点提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideRecommendTips",
            @"title" : @"隐藏推荐提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideBottomRelated",
            @"title" : @"隐藏底部相关",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideShareContentView",
            @"title" : @"隐藏分享提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideAntiAddictedNotice",
            @"title" : @"隐藏作者声明",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideFeedAnchorContainer",
              @"title" : @"隐藏视频锚点",
              @"subTitle" : @"包括拍摄同款、抖音精选、游戏、轻颜等供稿链接",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideChallengeStickers",
            @"title" : @"隐藏挑战贴纸",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTemplateTags",
            @"title" : @"隐藏校园提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideHisShop",
            @"title" : @"隐藏作者店铺",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideConcernCapsuleView",
            @"title" : @"隐藏关注直播",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTopBarLine",
            @"title" : @"隐藏顶栏横线",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTemplateVideo",
            @"title" : @"隐藏视频合集",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTemplatePlaylet",
            @"title" : @"隐藏短剧合集",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveGIF",
            @"title" : @"隐藏动图标签",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideItemTag",
            @"title" : @"隐藏笔记标签",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTemplateGroup",
            @"title" : @"隐藏底部话题",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCameraLocation",
            @"title" : @"隐藏相机定位",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentViews",
            @"title" : @"隐藏评论视图",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentTips",
            @"title" : @"隐藏评论提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideLiveCapsuleView",
              @"title" : @"隐藏直播红点",
              @"subTitle" : @"隐藏顶栏的直播中提示",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideStoryProgressSlide",
            @"title" : @"隐藏视频滑条",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideDotsIndicator",
            @"title" : @"隐藏图片滑条",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideChapterProgress",
            @"title" : @"隐藏章节进度",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePopover",
            @"title" : @"隐藏上次看到",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePrivateMessages",
            @"title" : @"隐藏分享私信",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideRightLabel",
            @"title" : @"隐藏昵称右侧",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHidePendantGroup",
              @"title" : @"隐藏红包悬浮",
              @"subTitle" : @"隐藏抖音极速版的红包悬浮按钮，可能失效，不修复。",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideScancode",
              @"title" : @"隐藏输入扫码",
              @"subTitle" : @"隐藏点击搜索后输入框右部的扫码按钮",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideReply",
            @"title" : @"隐藏私信回复",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePauseVideoRelatedWord",
            @"title" : @"隐藏暂停相关",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideKeyboardAI",
              @"title" : @"隐藏键盘 AI",
              @"subTitle" : @"隐藏搜索下方的 AI 和语音搜索按钮",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          }
      ];

      for (NSDictionary *dict in infoSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [infoItems addObject:item];
      }

      // 【直播界面净化】分类
      NSMutableArray<AWESettingItemModel *> *livestreamItems = [NSMutableArray array];
      NSArray *livestreamSettings = @[
          @{@"identifier" : @"DYYYHideLivePlayground",
            @"title" : @"隐藏直播广场",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideEnterLive",
            @"title" : @"隐藏进入直播",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveRoomClose",
            @"title" : @"隐藏关闭按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveRoomFullscreen",
            @"title" : @"隐藏横屏按钮",
            @"subTitle" : @"原始位置可点击",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGiftPavilion",
            @"title" : @"隐藏礼物展馆",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveRoomClear",
            @"title" : @"隐藏退出清屏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveRoomMirroring",
            @"title" : @"隐藏投屏按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveDiscovery",
            @"title" : @"隐藏直播发现",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideLiveDetail",
              @"title" : @"隐藏直播热榜",
              @"subTitle" : @"隐藏用户下方的小时榜、人气榜、热度等信息",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideTouchView",
              @"title" : @"隐藏红包悬浮",
              @"subTitle" : @"隐藏用户下方的红包、积分等悬浮按钮",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideKTVSongIndicator",
            @"title" : @"隐藏直播点歌",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideLiveGoodsMsg",
              @"title" : @"隐藏商品信息",
              @"subTitle" : @"隐藏直播间右下角相关的商品和游戏推荐",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideLiveLikeAnimation",
            @"title" : @"隐藏点赞动画",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideLivePopup",
              @"title" : @"隐藏进场特效",
              @"subTitle" : @"隐藏会员用户进入直播间时出现在弹幕顶部的动画特效",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideLiveDanmaku",
              @"title" : @"隐藏滚动弹幕",
              @"subTitle" : @"隐藏直播间管理员发送的特殊横向滚动弹幕",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideLiveHotMessage",
              @"title" : @"隐藏大家在说",
              @"subTitle" : @"隐藏出现在弹幕顶部的大家说热搜词",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideStickerView",
              @"title" : @"隐藏文字贴纸",
              @"subTitle" : @"隐藏主播设置的预约直播和文字贴纸",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideCellularAlert",
            @"title" : @"隐藏流量提醒",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}

      ];
      for (NSDictionary *dict in livestreamSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [livestreamItems addObject:item];
      }

      // 【长按面板】分类
      NSMutableArray<AWESettingItemModel *> *modernpanels = [NSMutableArray array];
      NSArray *modernpanelSettings = @[
          @{@"identifier" : @"DYYYHidePanelDaily",
            @"title" : @"隐藏面板日常",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelRecommend",
            @"title" : @"隐藏面板推荐",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelReport",
            @"title" : @"隐藏面板举报",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelSpeed",
            @"title" : @"隐藏面板倍速",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelClearScreen",
            @"title" : @"隐藏面板清屏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelFavorite",
            @"title" : @"隐藏面板缓存",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelCast",
            @"title" : @"隐藏面板投屏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelSubtitle",
            @"title" : @"隐藏面板弹幕",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelSearchImage",
            @"title" : @"隐藏面板识图",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelListenDouyin",
            @"title" : @"隐藏面板听抖音",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelOpenInPC",
            @"title" : @"隐藏电脑Pad打开",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelLater",
            @"title" : @"隐藏面板稍后再看",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelAutoPlay",
            @"title" : @"隐藏面板自动连播",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelNotInterested",
            @"title" : @"隐藏面板不感兴趣",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelBackgroundPlay",
            @"title" : @"隐藏面板后台播放",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelTimerClose",
            @"title" : @"隐藏面板定时关闭",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePanelBiserial",
            @"title" : @"隐藏双列快捷入口",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}
      ];

      for (NSDictionary *dict in modernpanelSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [modernpanels addObject:item];
      }

      // 【长按评论分类】
      NSMutableArray<AWESettingItemModel *> *commentpanel = [NSMutableArray array];
      NSArray *commentpanelSettings = @[
          @{@"identifier" : @"DYYYHideCommentShareToFriends",
            @"title" : @"隐藏评论分享",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressCopy",
            @"title" : @"隐藏评论复制",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressSaveImage",
            @"title" : @"隐藏评论保存",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressReport",
            @"title" : @"隐藏评论举报",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressSearch",
            @"title" : @"隐藏评论搜索",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressDaily",
            @"title" : @"隐藏评论转发日常",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressVideoReply",
            @"title" : @"隐藏评论视频回复",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressPictureSearch",
            @"title" : @"隐藏评论识别图片",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}
      ];
      for (NSDictionary *dict in commentpanelSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [commentpanel addObject:item];
      }
      // 创建并组织所有section
      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"主界面元素" items:mainUiItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"视频播放界面" items:videoUiItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"侧边栏元素" items:sidebarItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"消息页与我的页" items:messageAndMineItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"提示与位置信息" items:infoItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"直播间界面" items:livestreamItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"隐藏面板功能" footerTitle:@"隐藏视频长按面板中的功能" items:modernpanels]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"隐藏长按评论功能" footerTitle:@"隐藏评论长按面板中的功能" items:commentpanel]];
      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"隐藏设置" sections:sections];
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
          @{@"identifier" : @"DYYYHideHotContainer",
            @"title" : @"移除推荐",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideFriend",
            @"title" : @"移除朋友",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideFollow",
            @"title" : @"移除关注",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideMediumVideo",
            @"title" : @"移除精选",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideMall",
            @"title" : @"移除商城",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideNearby",
            @"title" : @"移除同城",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideGroupon",
            @"title" : @"移除团购",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideTabLive",
            @"title" : @"移除直播",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHidePadHot",
            @"title" : @"移除热点",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideHangout",
            @"title" : @"移除经验",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHidePlaylet",
            @"title" : @"移除短剧",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideCinema",
            @"title" : @"移除看剧",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideKidsV2",
            @"title" : @"移除少儿",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideGame",
            @"title" : @"移除游戏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideOtherChannel",
            @"title" : @"移除顶栏其他",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_xmark_outlined_20"}
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
          item.isSwitchOn = [DYYYSettingsHelper getUserDefaults:item.identifier];
          __weak AWESettingItemModel *weakItem = item;
          item.switchChangedBlock = ^{
            __strong AWESettingItemModel *strongItem = weakItem;
            if (strongItem) {
                BOOL isSwitchOn = !strongItem.isSwitchOn;
                strongItem.isSwitchOn = isSwitchOn;
                [DYYYSettingsHelper setUserDefaults:@(isSwitchOn) forKey:strongItem.identifier];
            }
          };
          [removeSettingsItems addObject:item];

          if ([item.identifier isEqualToString:@"DYYYHideOtherChannel"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideOtherChannel"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                // 将保存的逗号分隔字符串转换为数组
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideOtherChannel"] ?: @"";
                NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];

                // 创建并显示关键词列表视图
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤其他顶栏" keywords:keywordArray];

                // 设置确认回调
                keywordListView.onConfirm = ^(NSArray *keywords) {
                  // 将关键词数组转换为逗号分隔的字符串
                  NSString *keywordString = [keywords componentsJoinedByString:@","];
                  [DYYYSettingsHelper setUserDefaults:keywordString forKey:@"DYYYHideOtherChannel"];
                  item.detail = keywordString;
                  [item refreshCell];
                };

                // 显示关键词列表视图
                [keywordListView show];
              };
          }
      }

      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"顶栏选项" items:removeSettingsItems]];

      // 创建并推入二级设置页面，使用sections数组而不是直接使用removeSettingsItems
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"顶栏移除" sections:sections];
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
      NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];

      // 【长按面板设置】分类
      NSMutableArray<AWESettingItemModel *> *longPressItems = [NSMutableArray array];
      NSArray *longPressSettings = @[
          @{@"identifier" : @"DYYYLongPressSaveVideo",
            @"title" : @"长按保存当前视频",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressSaveCover",
            @"title" : @"长按保存视频封面",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressSaveAudio",
            @"title" : @"长按保存视频音乐",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressSaveCurrentImage",
            @"title" : @"长按保存当前图片",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressSaveAllImages",
            @"title" : @"长按保存所有图片",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressCreateVideo",
            @"title" : @"长按面板制作视频",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_videosearch_outlined_20"},
          @{@"identifier" : @"DYYYLongPressCopyText",
            @"title" : @"长按复制视频文案",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_rectangleonrectangleup_outlined_20"},
          @{@"identifier" : @"DYYYLongPressCopyLink",
            @"title" : @"长按复制分享链接",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_rectangleonrectangleup_outlined_20"},
          @{@"identifier" : @"DYYYLongPressApiDownload",
            @"title" : @"长按接口解析下载",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_cloudarrowdown_outlined_20"},
          @{@"identifier" : @"DYYYLongPressFilterUser",
            @"title" : @"长按面板过滤用户",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_userban_outlined_20"},
          @{@"identifier" : @"DYYYLongPressFilterTitle",
            @"title" : @"长按面板过滤文案",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_funnel_outlined_20"},
          @{@"identifier" : @"DYYYLongPressTimerClose",
            @"title" : @"长按定时关闭抖音",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_c_alarm_outlined"}
      ];

      for (NSDictionary *dict in longPressSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [longPressItems addObject:item];
      }

      // 【媒体保存】分类
      NSMutableArray<AWESettingItemModel *> *downloadItems = [NSMutableArray array];
      NSArray *downloadSettings = @[
          @{@"identifier" : @"DYYYInterfaceDownload",
            @"title" : @"接口解析保存媒体",
            @"detail" : @"不填关闭",
            @"cellType" : @26,
            @"imageName" : @"ic_cloudarrowdown_outlined_20"},
          @{@"identifier" : @"DYYYShowAllVideoQuality",
            @"title" : @"接口显示清晰选项",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_hamburgernut_outlined_20"},
          @{@"identifier" : @"DYYYEnableSheetBlur",
            @"title" : @"保存面板玻璃效果",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_list_outlined"},
          @{@"identifier" : @"DYYYSheetBlurTransparent",
            @"title" : @"面板毛玻璃透明度",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_eye_outlined_20"},
          @{@"identifier" : @"DYYYCommentLivePhotoNotWaterMark",
            @"title" : @"移除评论实况水印",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_livephoto_outlined_20"},
          @{@"identifier" : @"DYYYCommentNotWaterMark",
            @"title" : @"移除评论图片水印",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_removeimage_outlined_20"},
          @{
              @"identifier" : @"DYYYForceDownloadEmotion",
              @"title" : @"保存评论区表情包",
              @"subTitle" : @"iOS 17+的用户请长按表情本身保存",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_emoji_outlined"
          },
          @{@"identifier" : @"DYYYForceDownloadPreviewEmotion",
            @"title" : @"保存预览页表情包",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_emoji_outlined"},
          @{@"identifier" : @"DYYYForceDownloadIMEmotion",
            @"title" : @"保存聊天页表情包",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_emoji_outlined"},
          @{@"identifier" : @"DYYYHapticFeedbackEnabled",
            @"title" : @"下载完成震动反馈",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_gearsimplify_outlined_20"}
      ];

      for (NSDictionary *dict in downloadSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];

          // 特殊处理接口解析保存媒体选项
          if ([item.identifier isEqualToString:@"DYYYInterfaceDownload"]) {
              // 获取已保存的接口URL
              NSString *savedURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
              item.detail = savedURL.length > 0 ? savedURL : @"不填关闭";

              item.cellTappedBlock = ^{
                NSString *defaultText = [item.detail isEqualToString:@"不填关闭"] ? @"" : item.detail;
                [DYYYSettingsHelper showTextInputAlert:@"设置媒体解析接口"
                                           defaultText:defaultText
                                           placeholder:@"解析接口以url=结尾"
                                             onConfirm:^(NSString *text) {
                                               // 保存用户输入的接口URL
                                               NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                               [DYYYSettingsHelper setUserDefaults:trimmedText forKey:@"DYYYInterfaceDownload"];

                                               item.detail = trimmedText.length > 0 ? trimmedText : @"不填关闭";

                                               [item refreshCell];
                                             }
                                              onCancel:nil];
              };
          }
          [downloadItems addObject:item];
      }

      // 【热更新】分类
      NSMutableArray<AWESettingItemModel *> *hotUpdateItems = [NSMutableArray array];
      NSArray *hotUpdateSettings = @[
          @{@"identifier" : @"DYYYABTestBlockEnabled",
            @"title" : @"禁止下发配置",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_fire_outlined_20"},
          @{@"identifier" : @"DYYYABTestModeString",
            @"title" : @"配置应用方式",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_enterpriseservice_outlined"},
          @{@"identifier" : @"DYYYRemoteConfigURL",
            @"title" : @"远程配置地址",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_cloudarrowdown_outlined_20"},
          @{@"identifier" : @"DYYYCheckUpdate",
            @"title" : @"检查配置更新",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_cloudarrowdown_outlined_20"},
          @{@"identifier" : @"SaveCurrentABTestData",
            @"title" : @"导出当前配置",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_memorycard_outlined_20"},
          @{@"identifier" : @"SaveABTestConfigFile",
            @"title" : @"导出本地配置",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_memorycard_outlined_20"},
          @{@"identifier" : @"LoadABTestConfigFile",
            @"title" : @"导入本地配置",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_phonearrowup_outlined_20"},
          @{@"identifier" : @"DeleteABTestConfigFile",
            @"title" : @"删除本地配置",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_trash_outlined_20"}
      ];

      // --- 声明一个__block变量来持有SaveABTestConfigFileitem ---
      __block AWESettingItemModel *saveABTestConfigFileItemRef = nil;
      __block AWESettingItemModel *remoteURLItemRef = nil;
      __block AWESettingItemModel *checkUpdateItemRef = nil;
      __block AWESettingItemModel *loadConfigItemRef = nil;
      __block AWESettingItemModel *deleteConfigItemRef = nil;
      // --- 定义一个用于刷新SaveABTestConfigFileitem的局部block ---
      void (^refreshSaveABTestConfigFileItem)(void) = ^{
        if (!saveABTestConfigFileItemRef)
            return;

        // 在后台队列执行文件状态检查和大小获取
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
          __weak AWESettingItemModel *weakSaveItem = saveABTestConfigFileItemRef;
          __strong AWESettingItemModel *strongSaveItem = weakSaveItem;
          if (!strongSaveItem) {
              return;
          }

          NSFileManager *fileManager = [NSFileManager defaultManager];
          NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
          NSString *documentsDirectory = [paths firstObject];
          NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
          NSString *jsonFilePath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];

          NSString *loadingStatus = [DYYYABTestHook isLocalConfigLoaded] ? @"已加载：" : @"未加载：";

          NSString *detailText = nil;
          BOOL isItemEnable = NO;

          if (![fileManager fileExistsAtPath:jsonFilePath]) {
              detailText = [NSString stringWithFormat:@"%@ (文件不存在)", loadingStatus];
              isItemEnable = NO;
          } else {
              unsigned long long jsonFileSize = 0;
              NSError *attributesError = nil;
              NSDictionary *attributes = [fileManager attributesOfItemAtPath:jsonFilePath error:&attributesError];
              if (!attributesError && attributes) {
                  jsonFileSize = [attributes fileSize];
                  detailText = [NSString stringWithFormat:@"%@ %@", loadingStatus, [DYYYUtils formattedSize:jsonFileSize]];
                  isItemEnable = YES;
              } else {
                  detailText = [NSString stringWithFormat:@"%@ (读取失败: %@)", loadingStatus, attributesError.localizedDescription ?: @"未知错误"];
                  isItemEnable = NO;
              }
          }

          // 回到主线程更新 UI
          dispatch_async(dispatch_get_main_queue(), ^{
            // 在主线程更新 UI 前检查 item 是否仍然存在
            __strong AWESettingItemModel *strongSaveItemAgain = weakSaveItem;
            if (strongSaveItemAgain) {
                strongSaveItemAgain.detail = detailText;
                strongSaveItemAgain.isEnable = isItemEnable;
                [strongSaveItemAgain refreshCell];
            }
          });
        });
      };

      void (^refreshConfigConflictState)(void) = ^{
        BOOL remoteMode = [DYYYABTestHook isRemoteMode];
        BOOL localLoaded = [DYYYABTestHook isLocalConfigLoaded];
        if (remoteMode) {
            if (loadConfigItemRef) {
                loadConfigItemRef.isEnable = NO;
                [loadConfigItemRef refreshCell];
            }
            if (deleteConfigItemRef) {
                deleteConfigItemRef.isEnable = NO;
                [deleteConfigItemRef refreshCell];
            }
            if (remoteURLItemRef) {
                remoteURLItemRef.isEnable = YES;
                [remoteURLItemRef refreshCell];
            }
            if (checkUpdateItemRef) {
                checkUpdateItemRef.isEnable = YES;
                [checkUpdateItemRef refreshCell];
            }
        } else if (localLoaded) {
            if (remoteURLItemRef) {
                remoteURLItemRef.isEnable = NO;
                [remoteURLItemRef refreshCell];
            }
            if (checkUpdateItemRef) {
                checkUpdateItemRef.isEnable = NO;
                [checkUpdateItemRef refreshCell];
            }
            if (loadConfigItemRef) {
                loadConfigItemRef.isEnable = YES;
                [loadConfigItemRef refreshCell];
            }
            if (deleteConfigItemRef) {
                deleteConfigItemRef.isEnable = YES;
                [deleteConfigItemRef refreshCell];
            }
        } else {
            if (remoteURLItemRef) {
                remoteURLItemRef.isEnable = YES;
                [remoteURLItemRef refreshCell];
            }
            if (checkUpdateItemRef) {
                checkUpdateItemRef.isEnable = YES;
                [checkUpdateItemRef refreshCell];
            }
            if (loadConfigItemRef) {
                loadConfigItemRef.isEnable = YES;
                [loadConfigItemRef refreshCell];
            }
            if (deleteConfigItemRef) {
                deleteConfigItemRef.isEnable = YES;
                [deleteConfigItemRef refreshCell];
            }
        }
      };

      [[NSNotificationCenter defaultCenter] addObserverForName:DYYY_REMOTE_CONFIG_CHANGED_NOTIFICATION
                                                        object:nil
                                                         queue:[NSOperationQueue mainQueue]
                                                    usingBlock:^(NSNotification *_Nonnull note) {
                                                      refreshConfigConflictState();
                                                    }];

      for (NSDictionary *dict in hotUpdateSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];

          if ([item.identifier isEqualToString:@"DYYYABTestBlockEnabled"]) {
              item.switchChangedBlock = ^{
                BOOL newValue = !item.isSwitchOn;

                if (newValue) {
                    [DYYYBottomAlertView showAlertWithTitle:@"禁止热更新下发配置"
                        message:@"这将暂停接收测试新功能的推送。确定要继续吗？"
                        avatarURL:nil
                        cancelButtonText:@"取消"
                        confirmButtonText:@"确定"
                        cancelAction:^{
                          item.isSwitchOn = !newValue;
                          [item refreshCell];
                        }
                        closeAction:nil
                        confirmAction:^{
                          item.isSwitchOn = newValue;
                          [DYYYSettingsHelper setUserDefaults:@(newValue) forKey:@"DYYYABTestBlockEnabled"];

                          [DYYYABTestHook setABTestBlockEnabled:newValue];
                        }];
                } else {
                    item.isSwitchOn = newValue;
                    [DYYYSettingsHelper setUserDefaults:@(newValue) forKey:@"DYYYABTestBlockEnabled"];
                    [DYYYUtils showToast:@"已允许热更新下发配置，重启后生效。"];
                }
              };
          } else if ([item.identifier isEqualToString:@"DYYYABTestModeString"]) {
              BOOL isPatchMode = [DYYYABTestHook isPatchMode];
              if ([DYYYABTestHook isRemoteMode]) {
                  item.detail = isPatchMode ? @"远程模式(覆写)" : @"远程模式(替换)";
              } else {
                  item.detail = isPatchMode ? @"覆写模式" : @"替换模式";
              }

              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                NSString *currentMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYABTestModeString"] ?: @"替换模式：忽略原配置，使用新数据";

                NSArray *modeOptions = @[ @"覆写模式：保留原设置，覆盖同名项", @"替换模式：忽略原配置，使用新数据", DYYY_REMOTE_MODE_STRING ];

                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYABTestModeString"
                                                   optionsArray:modeOptions
                                                     headerText:@"选择本地配置的应用方式"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 BOOL isPatchMode = [DYYYABTestHook isPatchMode];
                                                 if ([DYYYABTestHook isRemoteMode]) {
                                                     item.detail = isPatchMode ? @"远程模式(覆写)" : @"远程模式(替换)";
                                                 } else {
                                                     item.detail = isPatchMode ? @"覆写模式" : @"替换模式";
                                                 }

                                                 BOOL wasRemote = [[NSUserDefaults standardUserDefaults] boolForKey:DYYY_REMOTE_CONFIG_FLAG_KEY];

                                                 if ([selectedValue isEqualToString:DYYY_REMOTE_MODE_STRING]) {
                                                     [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DYYY_REMOTE_CONFIG_FLAG_KEY];
                                                     [[NSUserDefaults standardUserDefaults] synchronize];
                                                     refreshConfigConflictState();
                                                 } else {
                                                     if (wasRemote) {
                                                         [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DYYY_REMOTE_CONFIG_FLAG_KEY];
                                                         [[NSUserDefaults standardUserDefaults] synchronize];
                                                         refreshConfigConflictState();
                                                     }
                                                 }

                                                 if (![selectedValue isEqualToString:currentMode]) {
                                                     [DYYYABTestHook applyFixedABTestData];
                                                 }
                                                 [item refreshCell];
                                               }];
              };
          } else if ([item.identifier isEqualToString:@"DYYYRemoteConfigURL"]) {
              remoteURLItemRef = item;
              NSString *savedURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYRemoteConfigURL"];
              item.detail = savedURL.length > 0 ? savedURL : DYYY_DEFAULT_ABTEST_URL;
              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                NSString *defaultText = item.detail;
                [DYYYSettingsHelper showTextInputAlert:@"设置远程配置地址"
                                           defaultText:defaultText
                                           placeholder:@"JSON URL"
                                             onConfirm:^(NSString *text) {
                                               NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                               [DYYYSettingsHelper setUserDefaults:trimmedText forKey:@"DYYYRemoteConfigURL"];
                                               item.detail = trimmedText.length > 0 ? trimmedText : DYYY_DEFAULT_ABTEST_URL;
                                               [item refreshCell];
                                             }
                                              onCancel:nil];
              };
          } else if ([item.identifier isEqualToString:@"DYYYCheckUpdate"]) {
              checkUpdateItemRef = item;
              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                [DYYYUtils showToast:@"正在检查更新..."];
                [DYYYABTestHook checkForRemoteConfigUpdate:YES];
              };
          } else if ([item.identifier isEqualToString:@"SaveCurrentABTestData"]) {
              item.detail = @"(获取中...)";
              item.isEnable = NO;

              // 在后台队列获取数据并更新 UI
              dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                __weak AWESettingItemModel *weakItem = item;
                __strong AWESettingItemModel *strongItem = weakItem;
                if (!strongItem) {
                    return;
                }

                NSDictionary *currentData = [DYYYABTestHook getCurrentABTestData];

                NSString *detailText = nil;
                BOOL isItemEnable = NO;
                NSData *jsonDataForSize = nil;

                if (!currentData) {
                    detailText = @"(获取失败)";
                    isItemEnable = NO;
                } else {
                    NSError *serializationError = nil;
                    jsonDataForSize = [NSJSONSerialization dataWithJSONObject:currentData options:NSJSONWritingPrettyPrinted error:&serializationError];
                    if (!serializationError && jsonDataForSize) {
                        detailText = [DYYYUtils formattedSize:jsonDataForSize.length];
                        isItemEnable = YES;
                    } else {
                        detailText = [NSString stringWithFormat:@"(序列化失败: %@)", serializationError.localizedDescription ?: @"未知错误"];
                        isItemEnable = NO;
                    }
                }

                // 回到主线程更新 UI
                dispatch_async(dispatch_get_main_queue(), ^{
                  __strong AWESettingItemModel *strongItemAgain = weakItem;
                  if (strongItemAgain) {
                      strongItemAgain.detail = detailText;
                      strongItemAgain.isEnable = isItemEnable;
                      [strongItemAgain refreshCell];
                  }
                });
              });

              item.cellTappedBlock = ^{
                NSDictionary *currentData = [DYYYABTestHook getCurrentABTestData];

                if (!currentData) {
                    [DYYYUtils showToast:@"ABTest配置获取失败"];
                    return;
                }

                NSError *error;
                NSData *sortedJsonData = [NSJSONSerialization dataWithJSONObject:currentData options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:&error];

                if (error) {
                    [DYYYUtils showToast:@"ABTest配置序列化失败"];
                    return;
                }

                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
                NSString *timestamp = [formatter stringFromDate:[NSDate date]];
                NSString *tempFile = [NSString stringWithFormat:@"ABTest_Config_%@.json", timestamp];
                NSString *tempFilePath = [DYYYUtils cachePathForFilename:tempFile];

                BOOL success = [sortedJsonData writeToFile:tempFilePath atomically:YES];

                if (!success) {
                    [DYYYUtils showToast:@"临时文件创建失败"];
                    return;
                }

                NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
                UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURLs:@[ tempFileURL ] inMode:UIDocumentPickerModeExportToService];

                DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
                pickerDelegate.tempFilePath = tempFilePath;
                pickerDelegate.completionBlock = ^(NSURL *url) {
                  [DYYYUtils showToast:@"ABTest配置已保存"];
                };

                static char kABTestPickerDelegateKey;
                documentPicker.delegate = pickerDelegate;
                objc_setAssociatedObject(documentPicker, &kABTestPickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

                UIViewController *topVC = topView();
                [topVC presentViewController:documentPicker animated:YES completion:nil];
              };
          } else if ([item.identifier isEqualToString:@"SaveABTestConfigFile"]) {
              item.detail = @"(获取中...)";

              saveABTestConfigFileItemRef = item;
              refreshSaveABTestConfigFileItem();

              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths firstObject];

                NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
                NSString *jsonFilePath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];

                NSData *jsonData = [NSData dataWithContentsOfFile:jsonFilePath];
                if (!jsonData) {
                    [DYYYUtils showToast:@"本地配置获取失败"];
                    return;
                }

                NSError *error;
                NSDictionary *originalData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
                if (error || ![originalData isKindOfClass:[NSDictionary class]]) {
                    [DYYYUtils showToast:@"本地配置序列化失败"];
                    return;
                }

                NSData *sortedJsonData = [NSJSONSerialization dataWithJSONObject:originalData options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:&error];
                if (error || !sortedJsonData) {
                    [DYYYUtils showToast:@"排序数据序列化失败"];
                    return;
                }

                // 创建临时文件
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
                NSString *timestamp = [formatter stringFromDate:[NSDate date]];
                NSString *tempFile = [NSString stringWithFormat:@"abtest_data_fixed_%@.json", timestamp];
                NSString *tempFilePath = [DYYYUtils cachePathForFilename:tempFile];

                if (![sortedJsonData writeToFile:tempFilePath atomically:YES]) {
                    [DYYYUtils showToast:@"临时文件创建失败"];
                    return;
                }

                UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURLs:@[ [NSURL fileURLWithPath:tempFilePath] ]
                                                                                                               inMode:UIDocumentPickerModeExportToService];

                DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
                pickerDelegate.tempFilePath = tempFilePath;
                pickerDelegate.completionBlock = ^(NSURL *url) {
                  [DYYYUtils showToast:@"本地配置已保存"];
                };

                static char kABTestConfigPickerDelegateKey;
                documentPicker.delegate = pickerDelegate;
                objc_setAssociatedObject(documentPicker, &kABTestConfigPickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

                UIViewController *topVC = topView();
                [topVC presentViewController:documentPicker animated:YES completion:nil];
              };
          } else if ([item.identifier isEqualToString:@"LoadABTestConfigFile"]) {
              loadConfigItemRef = item;
              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                BOOL isPatchMode = [DYYYABTestHook isPatchMode];

                NSString *confirmTitle, *confirmMessage;
                if (isPatchMode) {
                    confirmTitle = @"覆写模式";
                    confirmMessage = @"\n导入后将保留原设置并覆盖同名项，\n\n点击确定后继续操作。\n";
                } else {
                    confirmTitle = @"替换模式";
                    confirmMessage = @"\n导入后将忽略原设置并使用新数据，\n\n点击确定后继续操作。\n";
                }
                DYYYAboutDialogView *confirmDialog = [[DYYYAboutDialogView alloc] initWithTitle:confirmTitle message:confirmMessage];
                confirmDialog.onConfirm = ^{
                  UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[ @"public.json" ] inMode:UIDocumentPickerModeImport];

                  DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
                  pickerDelegate.completionBlock = ^(NSURL *url) {
                    // Delegate 回调通常在主线程，但文件操作和 Hook 调用应在后台
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                      __weak AWESettingItemModel *weakSaveItem = saveABTestConfigFileItemRef;

                      NSURL *sourceURL = url; // 用户选择的源文件 URL

                      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                      NSString *documentsDirectory = [paths firstObject];
                      NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
                      NSURL *destinationURL = [NSURL fileURLWithPath:[dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"]];

                      NSFileManager *fileManager = [NSFileManager defaultManager];
                      NSError *error = nil;
                      BOOL success = NO;
                      NSString *message = nil;

                      if (![fileManager fileExistsAtPath:dyyyFolderPath]) {
                          [fileManager createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
                          if (error) {
                              message = [NSString stringWithFormat:@"创建目录失败: %@", error.localizedDescription];
                          }
                      }

                      if (!message) {
                          // 在同一个目录下创建一个临时文件 URL 以确保原子性
                          NSString *tempFileName = [NSUUID UUID].UUIDString;
                          NSURL *temporaryURL = [NSURL fileURLWithPath:[dyyyFolderPath stringByAppendingPathComponent:tempFileName]];

                          if ([fileManager copyItemAtURL:sourceURL toURL:temporaryURL error:&error]) {
                              if ([fileManager replaceItemAtURL:destinationURL withItemAtURL:temporaryURL backupItemName:nil options:0 resultingItemURL:nil error:&error]) {
                                  [DYYYABTestHook cleanLocalABTestData];
                                  [DYYYABTestHook loadLocalABTestConfig];
                                  [DYYYABTestHook applyFixedABTestData];
                                  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DYYY_REMOTE_CONFIG_FLAG_KEY];
                                  [[NSUserDefaults standardUserDefaults] synchronize];
                                  [[NSNotificationCenter defaultCenter] postNotificationName:DYYY_REMOTE_CONFIG_CHANGED_NOTIFICATION object:nil];
                                  success = YES;
                                  message = @"配置已导入，部分设置需重启应用后生效";
                              } else {
                                  [fileManager removeItemAtURL:temporaryURL error:nil];
                                  message = [NSString stringWithFormat:@"导入失败 (替换文件失败): %@", error.localizedDescription];
                              }
                          } else {
                              message = [NSString stringWithFormat:@"导入失败 (复制到临时文件失败): %@", error.localizedDescription];
                          }
                      }
                      // 回到主线程显示 Toast 和更新 UI
                      dispatch_async(dispatch_get_main_queue(), ^{
                        __strong AWESettingItemModel *strongSaveItemAgain = weakSaveItem;

                        // 无论成功与否，都显示 Toast 告知用户结果
                        NSString *message = success ? @"配置已导入，部分设置需重启应用后生效" : [NSString stringWithFormat:@"导入失败: %@", error.localizedDescription];
                        [DYYYUtils showToast:message];

                        // 仅在导入成功且 item 仍然存在时更新 UI
                        if (success && strongSaveItemAgain) {
                            refreshSaveABTestConfigFileItem();
                            refreshConfigConflictState();
                        }
                      });
                    });
                  };

                  static char kPickerDelegateKey;
                  documentPicker.delegate = pickerDelegate;
                  objc_setAssociatedObject(documentPicker, &kPickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

                  UIViewController *topVC = topView();
                  [topVC presentViewController:documentPicker animated:YES completion:nil];
                };
                [confirmDialog show];
              };
          } else if ([item.identifier isEqualToString:@"DeleteABTestConfigFile"]) {
              deleteConfigItemRef = item;
              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths firstObject];
                NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
                NSString *configPath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];

                if ([[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
                    NSError *error = nil;
                    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:configPath error:&error];

                    NSString *message = success ? @"本地配置已删除成功" : [NSString stringWithFormat:@"删除失败: %@", error.localizedDescription];
                    [DYYYUtils showToast:message];

                    if (success) {
                        [DYYYABTestHook cleanLocalABTestData];
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DYYY_REMOTE_CONFIG_FLAG_KEY];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [[NSNotificationCenter defaultCenter] postNotificationName:DYYY_REMOTE_CONFIG_CHANGED_NOTIFICATION object:nil];
                        // 删除成功后修改 SaveABTestConfigFile item 的状态
                        saveABTestConfigFileItemRef.detail = @"(文件已删除)";
                        saveABTestConfigFileItemRef.isEnable = NO;
                        [saveABTestConfigFileItemRef refreshCell];
                        refreshConfigConflictState();
                    }
                } else {
                    [DYYYUtils showToast:@"本地配置不存在"];
                }
              };
          }

          [hotUpdateItems addObject:item];
      }
      refreshConfigConflictState();

      // 【交互增强】分类
      NSMutableArray<AWESettingItemModel *> *interactionItems = [NSMutableArray array];
      NSArray *interactionSettings = @[
          @{
              @"identifier" : @"DYYYEntrance",
              @"title" : @"左侧边栏快捷入口",
              @"subTitle" : @"将侧边栏替换为 DYYY 快捷入口",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_circlearrowin_outlined_20"
          },
          @{
              @"identifier" : @"DYYYDisableSidebarGesture",
              @"title" : @"禁止侧滑进入边栏",
              @"subTitle" : @"禁止在首页最左边的页面时右滑进入侧边栏",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_circlearrowin_outlined_20"
          },
          @{
              @"identifier" : @"DYYYVideoGesture",
              @"title" : @"横屏视频交互增强",
              @"subTitle" : @"启用横屏视频的手势功能",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_phonearrowdown_outlined_20"
          },
          @{
              @"identifier" : @"DYYYDisableAutoEnterLive",
              @"title" : @"禁用自动进入直播",
              @"subTitle" : @"禁止顶栏直播下自动进入直播间",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_video_outlined_20"
          },
          @{@"identifier" : @"DYYYEnableSaveAvatar",
            @"title" : @"启用保存他人头像",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_personcircleclean_outlined_20"},
          @{@"identifier" : @"DYYYCommentCopyText",
            @"title" : @"复制评论移除昵称",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_at_outlined_20"},
          @{
              @"identifier" : @"DYYYBioCopyText",
              @"title" : @"长按简介复制简介",
              @"subTitle" : @"长按个人主页的简介复制",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_rectangleonrectangleup_outlined_20"
          },
          @{
              @"identifier" : @"DYYYLongPressCopyTextEnabled",
              @"title" : @"长按文案复制文案",
              @"subTitle" : @"长按视频左下角的文案复制",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_rectangleonrectangleup_outlined_20"
          },
          @{
              @"identifier" : @"DYYYMusicCopyText",
              @"title" : @"评论音乐点击复制",
              @"subTitle" : @"含有音乐的视频打开评论区时，移除顶部歌曲去汽水听，点击复制歌曲名",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_quaver_outlined_20"
          },
          @{@"identifier" : @"DYYYAutoSelectOriginalPhoto",
            @"title" : @"启用自动勾选原图",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_image_outlined_20"},
          @{
              @"identifier" : @"DYYYEnableModernPanel",
              @"title" : @"启用新版长按面板",
              @"subTitle" : @"启用抖音灰度测试的新版长按面板",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_squaresplit_outlined_20"
          },
          @{@"identifier" : @"DYYYLongPressPanelBlur",
            @"title" : @"长按面板玻璃效果",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_squaresplit_outlined_20"},
          @{@"identifier" : @"DYYYLongPressPanelDark",
            @"title" : @"长按面板深色模式",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_sun_outlined"},
          @{
              @"identifier" : @"DYYYDefaultEnterWorks",
              @"title" : @"资料默认进入作品",
              @"subTitle" : @"禁止个人资料页自动进入橱窗等页面",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_playsquarestack_outlined_20"
          },
          @{@"identifier" : @"DYYYDisableHomeRefresh",
            @"title" : @"禁用点击首页刷新",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_arrowcircle_outlined_20"},
          @{@"identifier" : @"DYYYDisableDoubleTapLike",
            @"title" : @"禁用双击视频点赞",
            @"subTitle" : @"同时会禁用官方纯净模式的双击点赞",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_thumbsup_outlined_20"},
          @{
              @"identifier" : @"DYYYEnableDoubleOpenComment",
              @"title" : @"启用双击打开评论",
              @"subTitle" : @"与“双击打开菜单”互斥",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_comment_outlined_20"
          },
          @{
              @"identifier" : @"DYYYCommentShowDanmaku",
              @"title" : @"查看评论显示弹幕",
              @"subTitle" : @"打开评论区时保持弹幕可见",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_comment_outlined_20"
          },
          @{
              @"identifier" : @"DYYYEnableDoubleTapMenu",
              @"title" : @"启用双击打开菜单",
              @"subTitle" : @"与“双击打开评论”互斥，下方自定义",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_xiaoxihuazhonghua_outlined_20"
          },
          @{
              @"identifier" : @"DYYYDoubleTapMenuSettings",
              @"title" : @"设置双击菜单项目",
              @"subTitle" : @"自定义双击打开菜单需要显示的项目",
              @"detail" : @"",
              @"cellType" : @20,
              @"imageName" : @"ic_squaresplit_outlined_20"
          }
      ];

      for (NSDictionary *dict in interactionSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          if ([item.identifier isEqualToString:@"DYYYDoubleTapMenuSettings"]) {
              __weak AWESettingItemModel *weakItem = item;
              item.cellTappedBlock = ^{
                __strong AWESettingItemModel *strongItem = weakItem;
                if (!strongItem || !strongItem.isEnable)
                    return;
                NSMutableArray<AWESettingItemModel *> *doubleTapItems = [NSMutableArray array];
                NSArray *doubleTapFunctions = @[
                    @{@"identifier" : @"DYYYDoubleTapDownload",
                      @"title" : @"保存视频/图片",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_boxarrowdown_outlined"},
                    @{@"identifier" : @"DYYYDoubleTapDownloadAudio",
                      @"title" : @"保存音频",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_boxarrowdown_outlined"},
                    @{@"identifier" : @"DYYYDoubleInterfaceDownload",
                      @"title" : @"接口保存",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_cloudarrowdown_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleCreateVideo",
                      @"title" : @"制作视频",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_videosearch_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapCopyDesc",
                      @"title" : @"复制文案",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_rectangleonrectangleup_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapComment",
                      @"title" : @"打开评论",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_comment_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapLike",
                      @"title" : @"点赞视频",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_heart_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapshowDislikeOnVideo",
                      @"title" : @"长按面板",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_xiaoxihuazhonghua_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapshowSharePanel",
                      @"title" : @"分享视频",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_share_outlined"},
                ];

                for (NSDictionary *dict in doubleTapFunctions) {
                    AWESettingItemModel *functionItem = [DYYYSettingsHelper createSettingItem:dict];
                    [doubleTapItems addObject:functionItem];
                }
                NSMutableArray *sections = [NSMutableArray array];
                [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"设置双击菜单项目" items:doubleTapItems]];
                AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"设置双击菜单项目" sections:sections];
                [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
              };
          }

          if ([item.identifier isEqualToString:@"DYYYLongPressPanelDark"]) {
              BOOL isDarkPanelEnabled = [DYYYSettingsHelper getUserDefaults:item.identifier];
              item.svgIconImageName = isDarkPanelEnabled ? @"ic_moon_outlined" : @"ic_sun_outlined";

              void (^originalSwitchChangedBlock)(void) = item.switchChangedBlock;

              __weak AWESettingItemModel *weakItem = item;
              item.switchChangedBlock = ^{
                __strong AWESettingItemModel *strongItem = weakItem;
                if (!strongItem)
                    return;

                if (originalSwitchChangedBlock) {
                    originalSwitchChangedBlock();
                }

                if (strongItem.isSwitchOn) {
                    strongItem.svgIconImageName = @"ic_moon_outlined";
                } else {
                    strongItem.svgIconImageName = @"ic_sun_outlined";
                }
                [strongItem refreshCell];
              };
          }

          [interactionItems addObject:item];
      }

      // 创建并组织所有section
      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"长按面板设置" items:longPressItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"媒体保存" items:downloadItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"交互增强" items:interactionItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"热更新"
                                                         footerTitle:@"允许用户导出或导入抖音的ABTest配置。远程配置由 Nathalie 维护，在应用启动时自动更新远程配置。"
                                                               items:hotUpdateItems]];
      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"增强设置" sections:sections];
      [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
    };

    [mainItems addObject:enhanceSettingItem];

    // 创建悬浮按钮设置分类项
    AWESettingItemModel *floatButtonSettingItem = [[%c(AWESettingItemModel) alloc] init];
    floatButtonSettingItem.identifier = @"DYYYFloatButtonSettings";
    floatButtonSettingItem.title = @"悬浮按钮";
    floatButtonSettingItem.type = 0;
    floatButtonSettingItem.svgIconImageName = @"ic_gongchuang_outlined_20";
    floatButtonSettingItem.cellType = 26;
    floatButtonSettingItem.colorStyle = 0;
    floatButtonSettingItem.isEnable = YES;
    floatButtonSettingItem.cellTappedBlock = ^{
      // 创建悬浮按钮设置二级界面的设置项

      // 快捷倍速section
      NSMutableArray<AWESettingItemModel *> *speedButtonItems = [NSMutableArray array];

      // 倍速按钮
      AWESettingItemModel *enableSpeedButton = [DYYYSettingsHelper
          createSettingItem:
              @{@"identifier" : @"DYYYEnableFloatSpeedButton",
                @"title" : @"启用快捷倍速按钮",
                @"detail" : @"",
                @"cellType" : @6,
                @"imageName" : @"ic_xspeed_outlined"}];
      [speedButtonItems addObject:enableSpeedButton];

      // 添加倍速设置项
      AWESettingItemModel *speedSettingsItem = [[%c(AWESettingItemModel) alloc] init];
      speedSettingsItem.identifier = @"DYYYSpeedSettings";
      speedSettingsItem.title = @"快捷倍速数值设置";
      speedSettingsItem.type = 0;
      speedSettingsItem.svgIconImageName = @"ic_speed_outlined_20";
      speedSettingsItem.cellType = 26;
      speedSettingsItem.colorStyle = 0;
      speedSettingsItem.isEnable = YES;

      // 获取已保存的倍速数值设置
      NSString *savedSpeedSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYSpeedSettings"];
      // 如果没有设置过，使用默认值
      if (!savedSpeedSettings || savedSpeedSettings.length == 0) {
          savedSpeedSettings = @"1.0,1.25,1.5,2.0";
      }
      speedSettingsItem.detail = [NSString stringWithFormat:@"%@", savedSpeedSettings];
      speedSettingsItem.cellTappedBlock = ^{
        [DYYYSettingsHelper showTextInputAlert:@"设置快捷倍速数值"
                                   defaultText:speedSettingsItem.detail
                                   placeholder:@"使用半角逗号(,)分隔倍速值"
                                     onConfirm:^(NSString *text) {
                                       // 保存用户输入的倍速值
                                       NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                       [[NSUserDefaults standardUserDefaults] setObject:trimmedText forKey:@"DYYYSpeedSettings"];
                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                       speedSettingsItem.detail = trimmedText;
                                       [speedSettingsItem refreshCell];
                                     }
                                      onCancel:nil];
      };

      // 添加自动恢复倍速设置项
      AWESettingItemModel *autoRestoreSpeedItem = [[%c(AWESettingItemModel) alloc] init];
      autoRestoreSpeedItem.identifier = @"DYYYAutoRestoreSpeed";
      autoRestoreSpeedItem.title = @"自动恢复默认倍速";
      autoRestoreSpeedItem.detail = @"";
      autoRestoreSpeedItem.type = 1000;
      autoRestoreSpeedItem.svgIconImageName = @"ic_switch_outlined";
      autoRestoreSpeedItem.cellType = 6;
      autoRestoreSpeedItem.colorStyle = 0;
      autoRestoreSpeedItem.isEnable = YES;
      autoRestoreSpeedItem.isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
      autoRestoreSpeedItem.switchChangedBlock = ^{
        BOOL newValue = !autoRestoreSpeedItem.isSwitchOn;
        autoRestoreSpeedItem.isSwitchOn = newValue;
        [[NSUserDefaults standardUserDefaults] setBool:newValue forKey:@"DYYYAutoRestoreSpeed"];
        [[NSUserDefaults standardUserDefaults] synchronize];
      };
      [speedButtonItems addObject:autoRestoreSpeedItem];

      AWESettingItemModel *showXItem = [[%c(AWESettingItemModel) alloc] init];
      showXItem.identifier = @"DYYYSpeedButtonShowX";
      showXItem.title = @"倍速按钮显示后缀";
      showXItem.detail = @"";
      showXItem.type = 1000;
      showXItem.svgIconImageName = @"ic_pensketch_outlined_20";
      showXItem.cellType = 6;
      showXItem.colorStyle = 0;
      showXItem.isEnable = YES;
      showXItem.isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYSpeedButtonShowX"];
      showXItem.switchChangedBlock = ^{
        BOOL newValue = !showXItem.isSwitchOn;
        showXItem.isSwitchOn = newValue;
        [[NSUserDefaults standardUserDefaults] setBool:newValue forKey:@"DYYYSpeedButtonShowX"];
        [[NSUserDefaults standardUserDefaults] synchronize];
      };
      [speedButtonItems addObject:showXItem];
      // 添加按钮大小配置项
      AWESettingItemModel *buttonSizeItem = [[%c(AWESettingItemModel) alloc] init];
      buttonSizeItem.identifier = @"DYYYSpeedButtonSize";
      buttonSizeItem.title = @"快捷倍速按钮大小";
      // 获取当前的按钮大小，如果没有设置则默认为32
      CGFloat currentButtonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYSpeedButtonSize"] ?: 32;
      buttonSizeItem.detail = [NSString stringWithFormat:@"%.0f", currentButtonSize];
      buttonSizeItem.type = 0;
      buttonSizeItem.svgIconImageName = @"ic_zoomin_outlined_20";
      buttonSizeItem.cellType = 26;
      buttonSizeItem.colorStyle = 0;
      buttonSizeItem.isEnable = YES;
      buttonSizeItem.cellTappedBlock = ^{
        NSString *currentValue = [NSString stringWithFormat:@"%.0f", currentButtonSize];
        [DYYYSettingsHelper showTextInputAlert:@"设置按钮大小"
                                   defaultText:currentValue
                                   placeholder:@"请输入20-60之间的数值"
                                     onConfirm:^(NSString *text) {
                                       NSInteger size = [text integerValue];
                                       if (size >= 20 && size <= 60) {
                                           [[NSUserDefaults standardUserDefaults] setFloat:size forKey:@"DYYYSpeedButtonSize"];
                                           [[NSUserDefaults standardUserDefaults] synchronize];
                                           buttonSizeItem.detail = [NSString stringWithFormat:@"%.0f", (CGFloat)size];
                                           [buttonSizeItem refreshCell];
                                       } else {
                                           [DYYYUtils showToast:@"请输入20-60之间的有效数值"];
                                       }
                                     }
                                      onCancel:nil];
      };

      [speedButtonItems addObject:buttonSizeItem];

      [speedButtonItems addObject:speedSettingsItem];

      // 一键清屏section
      NSMutableArray<AWESettingItemModel *> *clearButtonItems = [NSMutableArray array];

      // 清屏按钮
      AWESettingItemModel *enableClearButton = [DYYYSettingsHelper
          createSettingItem:
              @{@"identifier" : @"DYYYEnableFloatClearButton",
                @"title" : @"一键清屏按钮",
                @"detail" : @"",
                @"cellType" : @6,
                @"imageName" : @"ic_eyeslash_outlined_16"}];
      [clearButtonItems addObject:enableClearButton];

      // 添加清屏按钮大小配置项
      AWESettingItemModel *clearButtonSizeItem = [[%c(AWESettingItemModel) alloc] init];
      clearButtonSizeItem.identifier = @"DYYYEnableFloatClearButtonSize";
      clearButtonSizeItem.title = @"清屏按钮大小";
      // 获取当前的按钮大小，如果没有设置则默认为40
      CGFloat currentClearButtonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYEnableFloatClearButtonSize"] ?: 40;
      clearButtonSizeItem.detail = [NSString stringWithFormat:@"%.0f", currentClearButtonSize];
      clearButtonSizeItem.type = 0;
      clearButtonSizeItem.svgIconImageName = @"ic_zoomin_outlined_20";
      clearButtonSizeItem.cellType = 26;
      clearButtonSizeItem.colorStyle = 0;
      clearButtonSizeItem.isEnable = YES;
      clearButtonSizeItem.cellTappedBlock = ^{
        NSString *currentValue = [NSString stringWithFormat:@"%.0f", currentClearButtonSize];
        [DYYYSettingsHelper showTextInputAlert:@"设置清屏按钮大小"
                                   defaultText:currentValue
                                   placeholder:@"请输入20-60之间的数值"
                                     onConfirm:^(NSString *text) {
                                       NSInteger size = [text integerValue];
                                       // 确保输入值在有效范围内
                                       if (size >= 20 && size <= 60) {
                                           [[NSUserDefaults standardUserDefaults] setFloat:size forKey:@"DYYYEnableFloatClearButtonSize"];
                                           [[NSUserDefaults standardUserDefaults] synchronize];
                                           clearButtonSizeItem.detail = [NSString stringWithFormat:@"%.0f", (CGFloat)size];
                                           [clearButtonSizeItem refreshCell];
                                       } else {
                                           [DYYYUtils showToast:@"请输入20-60之间的有效数值"];
                                       }
                                     }
                                      onCancel:nil];
      };
      [clearButtonItems addObject:clearButtonSizeItem];

      // 添加清屏按钮自定义图标选项
      AWESettingItemModel *clearButtonIcon = [DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYClearButtonIcon"
                                                                                                     title:@"清屏按钮图标"
                                                                                                   svgIcon:@"ic_roaming_outlined"
                                                                                                  saveFile:@"qingping.gif"];

      [clearButtonItems addObject:clearButtonIcon];
      // 清屏隐藏弹幕
      AWESettingItemModel *hideDanmakuButton = [DYYYSettingsHelper
          createSettingItem:
              @{@"identifier" : @"DYYYHideDanmaku",
                @"title" : @"清屏隐藏弹幕",
                @"detail" : @"",
                @"cellType" : @6,
                @"imageName" : @"ic_eyeslash_outlined_16"}];
      [clearButtonItems addObject:hideDanmakuButton];

      AWESettingItemModel *enableqingButton = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYRemoveTimeProgress",
          @"title" : @"清屏移除进度",
          @"subTitle" : @"清屏状态下完全移除时间进度条",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:enableqingButton];
      // 清屏隐藏时间进度
      AWESettingItemModel *enableqingButton1 = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideTimeProgress",
          @"title" : @"清屏隐藏进度",
          @"subTitle" : @"原始位置可拖动时间进度条",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:enableqingButton1];
      AWESettingItemModel *hideSliderButton = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideSlider",
          @"title" : @"清屏隐藏滑条",
          @"subTitle" : @"清屏状态下隐藏多图片下方的滑条",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:hideSliderButton];
      AWESettingItemModel *hideChapterButton = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideChapter",
          @"title" : @"清屏隐藏章节",
          @"subTitle" : @"清屏状态下隐藏部分视频出现的章节进度显示",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:hideChapterButton];
      AWESettingItemModel *hideTabButton = [DYYYSettingsHelper
          createSettingItem:
              @{@"identifier" : @"DYYYHideTabBar",
                @"title" : @"清屏隐藏底栏",
                @"detail" : @"",
                @"cellType" : @6,
                @"imageName" : @"ic_eyeslash_outlined_16"}];
      [clearButtonItems addObject:hideTabButton];
      AWESettingItemModel *hideSpeedButton = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideSpeed",
          @"title" : @"清屏隐藏倍速",
          @"subTitle" : @"清屏状态下隐藏DYYY的倍速按钮",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:hideSpeedButton];
      // 获取清屏按钮的当前开关状态
      BOOL isEnabled = [DYYYSettingsHelper getUserDefaults:@"DYYYEnableFloatClearButton"];
      clearButtonSizeItem.isEnable = isEnabled;
      clearButtonIcon.isEnable = isEnabled;

      // 创建并组织所有section
      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"快捷倍速" items:speedButtonItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"一键清屏" items:clearButtonItems]];

      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"悬浮按钮" sections:sections];
      [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
    };
    [mainItems addObject:floatButtonSettingItem];

    // 创建备份设置分类
    AWESettingSectionModel *backupSection = [[%c(AWESettingSectionModel) alloc] init];
    backupSection.sectionHeaderTitle = @"备份";
    backupSection.sectionHeaderHeight = 40;
    backupSection.type = 0;
    NSMutableArray<AWESettingItemModel *> *backupItems = [NSMutableArray array];

    AWESettingItemModel *backupItem = [[%c(AWESettingItemModel) alloc] init];
    backupItem.identifier = @"DYYYBackupSettings";
    backupItem.title = @"备份设置";
    backupItem.detail = @"";
    backupItem.type = 0;
    backupItem.svgIconImageName = @"ic_memorycard_outlined_20";
    backupItem.cellType = 26;
    backupItem.colorStyle = 0;
    backupItem.isEnable = YES;
    backupItem.cellTappedBlock = ^{
      // 获取所有以DYYY开头的NSUserDefaults键值
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSDictionary *allDefaults = [defaults dictionaryRepresentation];
      NSMutableDictionary *dyyySettings = [NSMutableDictionary dictionary];

      for (NSString *key in allDefaults.allKeys) {
          if ([key hasPrefix:@"DYYY"]) {
              dyyySettings[key] = [defaults objectForKey:key];
          }
      }

      // 查找并添加图标文件
      NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
      NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];

      NSArray *iconFileNames = @[ @"like_before.png", @"like_after.png", @"comment.png", @"unfavorite.png", @"favorite.png", @"share.png", @"tab_plus.png", @"qingping.gif" ];

      NSMutableDictionary *iconBase64Dict = [NSMutableDictionary dictionary];

      for (NSString *iconFileName in iconFileNames) {
          NSString *iconPath = [dyyyFolderPath stringByAppendingPathComponent:iconFileName];
          if ([[NSFileManager defaultManager] fileExistsAtPath:iconPath]) {
              // 读取图片数据并转换为Base64
              NSData *imageData = [NSData dataWithContentsOfFile:iconPath];
              if (imageData) {
                  NSString *base64String = [imageData base64EncodedStringWithOptions:0];
                  iconBase64Dict[iconFileName] = base64String;
              }
          }
      }

      // 将图标Base64数据添加到备份设置中
      if (iconBase64Dict.count > 0) {
          dyyySettings[@"DYYYIconsBase64"] = iconBase64Dict;
      }

      // 转换为JSON数据
      NSError *error;
      id jsonObject = DYYYJSONSafeObject(dyyySettings);
      NSData *sortedJsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:&error];

      if (error) {
          [DYYYUtils showToast:@"备份失败：无法序列化设置数据"];
          return;
      }

      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
      NSString *timestamp = [formatter stringFromDate:[NSDate date]];
      NSString *backupFileName = [NSString stringWithFormat:@"DYYY_Backup_%@.json", timestamp];
      NSString *tempFilePath = [DYYYUtils cachePathForFilename:backupFileName];

      BOOL success = [sortedJsonData writeToFile:tempFilePath atomically:YES];

      if (!success) {
          [DYYYUtils showToast:@"备份失败：无法创建临时文件"];
          return;
      }

      // 创建文档选择器让用户选择保存位置
      NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
      UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURLs:@[ tempFileURL ] inMode:UIDocumentPickerModeExportToService];

      DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
      pickerDelegate.tempFilePath = tempFilePath; // 设置临时文件路径
      pickerDelegate.completionBlock = ^(NSURL *url) {
        // 备份成功
        [DYYYUtils showToast:@"备份成功"];
      };

      static char kDYYYBackupPickerDelegateKey;
      documentPicker.delegate = pickerDelegate;
      objc_setAssociatedObject(documentPicker, &kDYYYBackupPickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

      UIViewController *topVC = topView();
      [topVC presentViewController:documentPicker animated:YES completion:nil];
    };
    [backupItems addObject:backupItem];

    // 添加恢复设置
    AWESettingItemModel *restoreItem = [[%c(AWESettingItemModel) alloc] init];
    restoreItem.identifier = @"DYYYRestoreSettings";
    restoreItem.title = @"恢复设置";
    restoreItem.detail = @"";
    restoreItem.type = 0;
    restoreItem.svgIconImageName = @"ic_phonearrowup_outlined_20";
    restoreItem.cellType = 26;
    restoreItem.colorStyle = 0;
    restoreItem.isEnable = YES;
    restoreItem.cellTappedBlock = ^{
      UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[ @"public.json", @"public.text" ] inMode:UIDocumentPickerModeImport];
      documentPicker.allowsMultipleSelection = NO;

      // 设置委托
      DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
      pickerDelegate.completionBlock = ^(NSURL *url) {
        NSData *jsonData = [NSData dataWithContentsOfURL:url];

        if (!jsonData) {
            [DYYYUtils showToast:@"无法读取备份文件"];
            return;
        }

        NSError *jsonError;
        NSDictionary *dyyySettings = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

        if (jsonError || ![dyyySettings isKindOfClass:[NSDictionary class]]) {
            [DYYYUtils showToast:@"备份文件格式错误"];
            return;
        }

        // 恢复图标文件
        NSDictionary *iconBase64Dict = dyyySettings[@"DYYYIconsBase64"];
        if (iconBase64Dict && [iconBase64Dict isKindOfClass:[NSDictionary class]]) {
            NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];

            // 确保DYYY文件夹存在
            if (![[NSFileManager defaultManager] fileExistsAtPath:dyyyFolderPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
            }

            // 从Base64还原图标文件
            for (NSString *iconFileName in iconBase64Dict) {
                NSString *base64String = iconBase64Dict[iconFileName];
                if ([base64String isKindOfClass:[NSString class]]) {
                    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
                    if (imageData) {
                        NSString *iconPath = [dyyyFolderPath stringByAppendingPathComponent:iconFileName];
                        [imageData writeToFile:iconPath atomically:YES];
                    }
                }
            }

            NSMutableDictionary *cleanSettings = [dyyySettings mutableCopy];
            [cleanSettings removeObjectForKey:@"DYYYIconsBase64"];
            dyyySettings = cleanSettings;
        }

        // 恢复设置
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        for (NSString *key in dyyySettings) {
            [defaults setObject:dyyySettings[key] forKey:key];
        }
        [defaults synchronize];

        [DYYYUtils showToast:@"设置已恢复，请重启应用以应用所有更改"];

        [restoreItem refreshCell];
      };

      static char kDYYYRestorePickerDelegateKey;
      documentPicker.delegate = pickerDelegate;
      objc_setAssociatedObject(documentPicker, &kDYYYRestorePickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

      UIViewController *topVC = topView();
      [topVC presentViewController:documentPicker animated:YES completion:nil];
    };
    [backupItems addObject:restoreItem];
    backupSection.itemArray = backupItems;

    // 创建清理section
    AWESettingSectionModel *cleanupSection = [[%c(AWESettingSectionModel) alloc] init];
    cleanupSection.sectionHeaderTitle = @"清理";
    cleanupSection.sectionHeaderHeight = 40;
    cleanupSection.type = 0;
    NSMutableArray<AWESettingItemModel *> *cleanupItems = [NSMutableArray array];
    AWESettingItemModel *cleanSettingsItem = [[%c(AWESettingItemModel) alloc] init];
    cleanSettingsItem.identifier = @"DYYYCleanSettings";
    cleanSettingsItem.title = @"清除设置";
    cleanSettingsItem.detail = @"";
    cleanSettingsItem.type = 0;
    cleanSettingsItem.svgIconImageName = @"ic_trash_outlined_20";
    cleanSettingsItem.cellType = 26;
    cleanSettingsItem.colorStyle = 0;
    cleanSettingsItem.isEnable = YES;
    cleanSettingsItem.cellTappedBlock = ^{
      [DYYYBottomAlertView showAlertWithTitle:@"清除设置"
          message:@"请选择要清除的设置类型"
          avatarURL:nil
          cancelButtonText:@"清除抖音设置"
          confirmButtonText:@"清除插件设置"
          cancelAction:^{
            // 清除抖音设置的确认对话框
            [DYYYBottomAlertView showAlertWithTitle:@"清除抖音设置"
                                            message:@"确定要清除抖音所有设置吗？\n这将无法恢复，应用会自动退出！"
                                          avatarURL:nil
                                   cancelButtonText:@"取消"
                                  confirmButtonText:@"确定"
                                       cancelAction:nil
                                        closeAction:nil
                                      confirmAction:^{
                                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                                        if (paths.count > 0) {
                                            NSString *preferencesPath = [paths.firstObject stringByAppendingPathComponent:@"Preferences"];
                                            NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
                                            NSString *plistPath = [preferencesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", bundleIdentifier]];

                                            NSError *error = nil;
                                            [[NSFileManager defaultManager] removeItemAtPath:plistPath error:&error];

                                            if (!error) {
                                                [DYYYUtils showToast:@"抖音设置已清除，应用即将退出"];

                                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                  exit(0);
                                                });
                                            } else {
                                                [DYYYUtils showToast:[NSString stringWithFormat:@"清除失败: %@", error.localizedDescription]];
                                            }
                                        }
                                      }];
          }
          closeAction:^{
          }
          confirmAction:^{
            // 清除插件设置的确认对话框
            [DYYYBottomAlertView showAlertWithTitle:@"清除插件设置"
                                            message:@"确定要清除所有插件设置吗？\n这将无法恢复！"
                                          avatarURL:nil
                                   cancelButtonText:@"取消"
                                  confirmButtonText:@"确定"
                                       cancelAction:nil
                                        closeAction:nil
                                      confirmAction:^{
                                        // 获取所有以DYYY开头的NSUserDefaults键值并清除
                                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                        NSDictionary *allDefaults = [defaults dictionaryRepresentation];

                                        for (NSString *key in allDefaults.allKeys) {
                                            if ([key hasPrefix:@"DYYY"]) {
                                                [defaults removeObjectForKey:key];
                                            }
                                        }
                                        [defaults synchronize];
                                        [DYYYUtils showToast:@"插件设置已清除，请重启应用"];
                                      }];
          }];
    };
    [cleanupItems addObject:cleanSettingsItem];

    NSArray<NSString *> *customDirs = @[ @"Application Support/gurd_cache", @"Caches", @"BDByteCast", @"kitelog" ];
    NSMutableSet<NSString *> *uniquePaths = [NSMutableSet set];
    [uniquePaths addObject:NSTemporaryDirectory()];
    [uniquePaths addObject:NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject];
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    for (NSString *sub in customDirs) {
        NSString *fullPath = [libraryDir stringByAppendingPathComponent:sub];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
            [uniquePaths addObject:fullPath];
        }
    }
    NSArray<NSString *> *allPaths = [uniquePaths allObjects];

    AWESettingItemModel *cleanCacheItem = [[%c(AWESettingItemModel) alloc] init];
    __weak AWESettingItemModel *weakCleanCacheItem = cleanCacheItem;
    cleanCacheItem.identifier = @"DYYYCleanCache";
    cleanCacheItem.title = @"清理缓存";
    cleanCacheItem.type = 0;
    cleanCacheItem.svgIconImageName = @"ic_broom_outlined";
    cleanCacheItem.cellType = 26;
    cleanCacheItem.colorStyle = 0;
    cleanCacheItem.isEnable = NO;
    cleanCacheItem.detail = @"计算中...";
    __block unsigned long long initialSize = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      for (NSString *basePath in allPaths) {
          initialSize += [DYYYUtils directorySizeAtPath:basePath];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong AWESettingItemModel *strongCleanCacheItem = weakCleanCacheItem;
        if (strongCleanCacheItem) {
            strongCleanCacheItem.detail = [DYYYUtils formattedSize:initialSize];
            strongCleanCacheItem.isEnable = YES;
            [strongCleanCacheItem refreshCell];
        }
      });
    });
    cleanCacheItem.cellTappedBlock = ^{
      __strong AWESettingItemModel *strongCleanCacheItem = weakCleanCacheItem;
      if (!strongCleanCacheItem || !strongCleanCacheItem.isEnable) {
          return;
      }
      // Disable the button to prevent multiple triggers
      strongCleanCacheItem.isEnable = NO;
      strongCleanCacheItem.detail = @"清理中...";
      [strongCleanCacheItem refreshCell];

      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *basePath in allPaths) {
            [DYYYUtils removeAllContentsAtPath:basePath];
        }

        // 修复搜索界面的猜你想搜和猜你想看
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *activeMetadataFilePath = [libraryDir stringByAppendingPathComponent:@"Application Support/gurd_cache/.active_metadata"];
        if ([fileManager fileExistsAtPath:activeMetadataFilePath]) {
            [fileManager removeItemAtPath:activeMetadataFilePath error:nil];
        }

        unsigned long long afterSize = 0;
        for (NSString *basePath in allPaths) {
            afterSize += [DYYYUtils directorySizeAtPath:basePath];
        }

        unsigned long long clearedSize = (initialSize > afterSize) ? (initialSize - afterSize) : 0;

        dispatch_async(dispatch_get_main_queue(), ^{
          [DYYYUtils showToast:[NSString stringWithFormat:@"已清理 %@ 缓存", [DYYYUtils formattedSize:clearedSize]]];

          strongCleanCacheItem.detail = [DYYYUtils formattedSize:afterSize];
          // Re-enable the button after cleaning is done
          strongCleanCacheItem.isEnable = YES;
          [strongCleanCacheItem refreshCell];
        });
      });
    };
    [cleanupItems addObject:cleanCacheItem];

    cleanupSection.itemArray = cleanupItems;

    // 创建关于分类
    AWESettingSectionModel *aboutSection = [[%c(AWESettingSectionModel) alloc] init];
    aboutSection.sectionHeaderTitle = @"关于";
    aboutSection.sectionHeaderHeight = 40;
    aboutSection.type = 0;
    NSMutableArray<AWESettingItemModel *> *aboutItems = [NSMutableArray array];

    // 添加关于
    AWESettingItemModel *aboutItem = [[%c(AWESettingItemModel) alloc] init];
    aboutItem.identifier = @"DYYYAbout";
    aboutItem.title = @"关于插件";
    aboutItem.detail = DYYY_VERSION;
    aboutItem.type = 0;
    aboutItem.iconImageName = @"awe-settings-icon-about";
    aboutItem.cellType = 26;
    aboutItem.colorStyle = 0;
    aboutItem.isEnable = YES;
    aboutItem.cellTappedBlock = ^{
      [DYYYSettingsHelper showAboutDialog:@"关于DYYY"
                                  message:@"版本: " DYYY_VERSION @"\n\n"
                                          @"感谢使用DYYY\n\n"
                                          @"感谢huami开源\n\n"
                                          @"@维他入我心 基于DYYY二次开发\n\n"
                                          @"感谢huami group中群友的支持赞助\n\n"
                                          @"Telegram @huamidev\n\n"
                                          @"Telegram @vita_app\n\n"
                                          @"开源地址 huami1314/DYYY\n\n"
                                          @"仓库地址 Wtrwx/DYYY\n\n"
                                onConfirm:nil];
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
      [DYYYSettingsHelper showAboutDialog:@"MIT License"
                                  message:@"Copyright (c) 2024 huami.\n\n"
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
                                          @"SOFTWARE."
                                onConfirm:nil];
    };
    [aboutItems addObject:licenseItem];
    mainSection.itemArray = mainItems;
    aboutSection.itemArray = aboutItems;

    viewModel.sectionDataArray = @[ mainSection, cleanupSection, backupSection, aboutSection ];
    objc_setAssociatedObject(settingsVC, kViewModelKey, viewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [rootVC.navigationController pushViewController:(UIViewController *)settingsVC animated:YES];
}

%hook AWESettingsViewModel
- (NSArray *)sectionDataArray {
    NSArray *originalSections = %orig;
    BOOL sectionExists = NO;
    BOOL isMainSettingsPage = NO;

    // 遍历检查是否已存在DYYY部分
    for (AWESettingSectionModel *section in originalSections) {
        if ([section.sectionHeaderTitle isEqualToString:DYYY_NAME]) {
            sectionExists = YES;
        }
        if ([section.sectionHeaderTitle isEqualToString:@"账号"]) {
            isMainSettingsPage = YES;
        }
    }

    if (isMainSettingsPage && !sectionExists) {
        AWESettingItemModel *dyyyItem = [[%c(AWESettingItemModel) alloc] init];
        dyyyItem.identifier = DYYY_NAME;
        dyyyItem.title = DYYY_NAME;
        dyyyItem.detail = DYYY_VERSION;
        dyyyItem.type = 0;
        dyyyItem.svgIconImageName = @"ic_sapling_outlined";
        dyyyItem.cellType = 26;
        dyyyItem.colorStyle = 2;
        dyyyItem.isEnable = YES;
        dyyyItem.cellTappedBlock = ^{
          UIViewController *rootVC = self.controllerDelegate;
          BOOL hasAgreed = [DYYYSettingsHelper getUserDefaults:@"DYYYUserAgreementAccepted"];
          showDYYYSettingsVC(rootVC, hasAgreed);
        };

        AWESettingSectionModel *newSection = [[%c(AWESettingSectionModel) alloc] init];
        newSection.itemArray = @[ dyyyItem ];
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
