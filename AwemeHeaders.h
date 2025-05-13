#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#define DYYYGetBool(key) [[NSUserDefaults standardUserDefaults] boolForKey:key]
#define DYYY_IGNORE_GLOBAL_ALPHA_TAG 114514
typedef NS_ENUM(NSInteger, MediaType) {
  MediaTypeVideo,
  MediaTypeImage,
  MediaTypeAudio,
  MediaTypeHeic
};

@interface URLModel : NSObject
@property(nonatomic, strong) NSArray *originURLList;
@end

@interface DUXToast : NSObject
+ (void)showText:(NSString *)text;
@end

@interface AWEURLModel : NSObject
@property (nonatomic, copy) NSArray *originURLList;
@property (nonatomic, assign) NSInteger imageWidth;
@property (nonatomic, assign) NSInteger imageHeight;
@property (nonatomic, copy) NSString *URLKey;
- (NSArray *)originURLList;
- (id)URI;
- (NSURL *)getDYYYSrcURLDownload;
@end

@interface AWEVideoModel : NSObject
@property (nonatomic, strong) AWEURLModel *playLowBitURL;
@property(retain, nonatomic) AWEURLModel *playURL;
@property(copy, nonatomic) NSArray *manualBitrateModels;
@property(copy, nonatomic) NSArray *bitrateModels;
@property(copy, nonatomic) NSArray *bitrateRawData;
@property(nonatomic, strong) URLModel *h264URL;
@property(nonatomic, strong) URLModel *coverURL;
@end

@interface AWEMusicModel : NSObject
@property(nonatomic, strong) URLModel *playURL;
@end

@interface AWEImageAlbumImageModel : NSObject
@property(nonatomic, strong) NSArray *urlList;
@property(retain, nonatomic) AWEVideoModel *clipVideo;
@end

@interface AWEAwemeStatisticsModel : NSObject
@property(nonatomic, strong) NSNumber *diggCount;
@end

@interface AWESearchAwemeExtraModel : NSObject
@end

@interface AWEAwemeTextExtraModel : NSObject
@property(nonatomic, copy) NSString *hashtagName;
@property(nonatomic, copy) NSString *hashtagId;
@property(nonatomic, copy) NSString *type;
@property(nonatomic, assign) NSRange textRange;
@property(nonatomic, copy) NSString *awemeId;
@property(nonatomic, copy) NSString *userId;
@property(nonatomic, copy) NSString *userUniqueId;
@property(nonatomic, copy) NSString *secUid;
@end

@interface AWEUserModel : NSObject
@property(copy, nonatomic) NSString *nickname;
@property(copy, nonatomic) NSString *shortID;
@end

@interface AWEAwemeModel : NSObject
@property(nonatomic, strong, readwrite) NSNumber *createTime;
@property(nonatomic, assign, readwrite) CGFloat videoDuration;
@property(nonatomic, strong) AWEVideoModel *video;
@property(nonatomic, strong) AWEMusicModel *music;
@property(nonatomic, strong) NSArray<AWEImageAlbumImageModel *> *albumImages;
@property(nonatomic, assign) NSInteger currentImageIndex;
@property(nonatomic, assign) NSInteger awemeType;
@property(nonatomic, strong) NSString *cityCode;
@property(nonatomic, strong) NSString *ipAttribution;
@property(nonatomic, strong) id currentAweme;
@property(nonatomic, copy) NSString *descriptionString;
@property(nonatomic, assign) BOOL isAds;
@property(nonatomic, assign) BOOL isLive;
@property(nonatomic, strong) NSString *shareURL;
@property(nonatomic, strong) id hotSpotLynxCardModel;
@property(nonatomic, copy) NSString *liveReason;
@property(nonatomic, strong) id shareRecExtra; // 推荐视频专有属性
@property(nonatomic, strong) NSArray<AWEAwemeTextExtraModel *> *textExtras;
@property(nonatomic, copy) NSString *itemTitle;
@property(nonatomic, copy) NSString *descriptionSimpleString;
@property(nonatomic, strong) NSString *itemID;
@property(nonatomic, strong) AWEUserModel *author;

@property(nonatomic, strong) AWEAwemeStatisticsModel *statistics;
- (BOOL)isLive;
- (AWESearchAwemeExtraModel *)searchExtraModel;
@end

@interface AWELongPressPanelBaseViewModel : NSObject
@property(nonatomic, copy) NSString *describeString;
@property(nonatomic, assign) NSInteger enterMethod;
@property(nonatomic, assign) NSInteger actionType;
@property(nonatomic, assign) BOOL showIfNeed;
@property(nonatomic, copy) NSString *duxIconName;
@property(nonatomic, copy) void (^action)(void);
@property(nonatomic) BOOL isModern;
@property(nonatomic, strong) AWEAwemeModel *awemeModel;
- (void)setDuxIconName:(NSString *)iconName;
- (void)setDescribeString:(NSString *)descString;
- (void)setAction:(void (^)(void))action;
@end

@interface AWELongPressPanelViewGroupModel : NSObject
@property(nonatomic) unsigned long long groupType;
@property(nonatomic) NSArray *groupArr;
@property(nonatomic) long long numberOfRowsInSection;
@property(nonatomic) long long cellHeight;
@property(nonatomic) BOOL hasMore;
@property(nonatomic) BOOL isModern;
@property(nonatomic) BOOL isDYYYCustomGroup;
@end

@interface AWELongPressPanelManager : NSObject
+ (instancetype)shareInstance;
- (void)dismissWithAnimation:(BOOL)animated completion:(void (^)(void))completion;
- (BOOL)shouldShowMordenLongPressPanel;
- (BOOL)showShareFriends;
@end

@interface AWENormalModeTabBarGeneralButton : UIButton
@property(nonatomic) NSInteger status;
@end

@interface AWEHPTopTabItemBadgeContentView : UIView
@end

@interface AWEProgressLoadingView : UIView
- (id)initWithType:(NSInteger)arg1 title:(NSString *)arg2;
- (id)initWithType:(NSInteger)arg1 title:(NSString *)arg2 progressTextFont:(UIFont *)arg3 progressCircleWidth:(NSNumber *)arg4;
- (void)dismissWithAnimated:(BOOL)arg1;
- (void)dismissAnimated:(BOOL)arg1;
- (void)showOnView:(id)arg1 animated:(BOOL)arg2;
- (void)showOnView:(id)arg1 animated:(BOOL)arg2 afterDelay:(CGFloat)arg3;
@end

@interface AWENormalModeTabBarBadgeContainerView : UIView

@end

@interface AWEFeedContainerContentView : UIView
- (UIViewController *)findViewController:(UIViewController *)vc ofClass:(Class)targetClass;
@end

@interface AWELeftSideBarEntranceView : UIView
- (void)setNumericalRedDot:(id)numericalRedDot;
- (void)setRedDot:(id)redDot;
@end

@interface AWEDanmakuContentLabel : UILabel
- (UIColor *)colorFromHexString:(NSString *)hexString baseColor:(UIColor *)baseColor;
@end

@interface AWELandscapeFeedEntryView : UIView
@end

@interface AWEPlayInteractionViewController : UIViewController
@property(nonatomic, strong) UIView *view;
- (void)performCommentAction;
- (void)performLikeAction;
- (void)showSharePanel;
- (void)showDislikeOnVideo;
- (void)onVideoPlayerViewDoubleClicked:(id)arg1;
- (UIViewController *)firstAvailableUIViewController;
- (void)speedButtonTapped:(id)sender;
- (void)buttonTouchDown:(id)sender;
- (void)buttonTouchUp:(id)sender;
@end

@interface UIView (Transparency)
- (UIViewController *)firstAvailableUIViewController;
@end

@interface AWEFeedVideoButton : UIButton
@end

@interface AWEMusicCoverButton : UIButton
@end

@interface AWEAwemePlayVideoViewController : UIViewController
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context;
- (void)setVideoControllerPlaybackRate:(double)arg0;

@end

@interface AWEDanmakuItemTextInfo : NSObject
- (void)setDanmakuTextColor:(id)arg1;
- (UIColor *)colorFromHexStringForTextInfo:(NSString *)hexString;
@end

@interface AWECommentMiniEmoticonPanelView : UIView

@end

@interface AWEBaseElementView : UIView

@end

@interface AWESearchEntranceView : UIView

@end

@interface AWETextViewInternal : UITextView

@end

@interface AWECommentPublishGuidanceView : UIView

@end

@interface AWEPlayInteractionFollowPromptView : UIView
@end

@interface AWENormalModeTabBarTextView : UIView

@end

@interface AWEFamiliarNavView : UIView
@end

@interface AWEPlayInteractionNewBaseController : UIView
@property(retain, nonatomic) AWEAwemeModel *model;
@end

@interface AWEPlayInteractionProgressController : AWEPlayInteractionNewBaseController
- (UIViewController *)findViewController:(UIViewController *)vc ofClass:(Class)targetClass;
@property(retain, nonatomic) id progressSlider;
- (NSString *)formatTimeFromSeconds:(CGFloat)seconds;
- (NSString *)convertSecondsToTimeString:(NSInteger)totalSeconds;
@end

@interface AWEAdAvatarView : UIView

@end

@interface AWENormalModeTabBar : UIView
@property(nonatomic, assign, readonly) UITabBarController *yy_viewController;
@end

@interface AWEPlayInteractionListenFeedView : UIView

@end

@interface AWEFeedLiveMarkView : UIView

@end

@interface AWEPlayInteractionTimestampElement : UIView
@property(nonatomic, strong) AWEAwemeModel *model;
@end

@interface AWEFeedTableViewController : UIViewController
@end

@interface AWEFeedTableView : UIView
@end

@interface AWEAwemeDetailTableView : UIView
@end

@interface AWEAwemeDetailTableViewCell : UIView
@end

@interface IESLiveFeedDrawerEntranceView : UIView
@end

@interface AWEPlayInteractionProgressContainerView : UIView
@end

@interface AFDFastSpeedView : UIView
@end

@interface AWEUserWorkCollectionViewComponentCell : UICollectionViewCell
@end

@interface AWEFeedRefreshFooter : UIView
@end

@interface AWERLSegmentView : UIView
@end

@interface AWEBaseListViewController : UIViewController
- (void)applyBlurEffectIfNeeded;
- (UILabel *)findCommentLabel:(UIView *)view;
@end

// 隐藏视频定位
@interface AWEFeedTemplateAnchorView : UIView
@end

// 隐藏同城定位
@interface AWEMarkView : UIView
@property(nonatomic, readonly) UILabel *markLabel;
@end

@interface AWEPlayInteractionSearchAnchorView : UIView
@end

@interface AWETemplateHotspotView : UIView
@end

@interface AWEAwemeMusicInfoView : UIView
@end

@interface AWETemplatePlayletView : UIView
@end

@interface AFDRecommendToFriendEntranceLabel : UILabel
@end

@interface AWEStoryContainerCollectionView : UIView
@end

@interface AWELiveNewPreStreamViewController : UIViewController
@end

@interface CommentInputContainerView : UIView
@end

@interface AWELongPressPanelTableViewController : UIViewController
@property(nonatomic, strong) AWEAwemeModel *awemeModel;
@end

@interface AWEModernLongPressPanelTableViewController : UIViewController
@property(nonatomic, strong) AWEAwemeModel *awemeModel;
@end

@interface AWEModernLongPressHorizontalSettingCell : UITableViewCell
@property(nonatomic, strong) UICollectionView *collectionView;
@property(nonatomic, strong) NSArray *dataArray;
@property(nonatomic, strong) AWELongPressPanelViewGroupModel *longPressViewGroupModel;
@end

@interface AWEModernLongPressHorizontalSettingItemCell : UICollectionViewCell
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UIImageView *buttonIcon;
@property(nonatomic, strong) UILabel *buttonLabel;
@property(nonatomic, strong) UIView *separator;
@property(nonatomic, strong) AWELongPressPanelBaseViewModel *longPressPanelVM;

- (void)updateUI:(AWELongPressPanelBaseViewModel *)viewModel;
@end

@interface AWEModernLongPressInteractiveCell : UITableViewCell
@property(nonatomic, strong) UICollectionView *collectionView;
@property(nonatomic, strong) AWELongPressPanelViewGroupModel *longPressViewGroupModel;
@property(nonatomic, strong) NSArray *dataArray;
@property(nonatomic, assign) BOOL isAppearing;
@end

@interface DYYYSettingViewController : UIViewController
@end

@interface AWEElementStackView : UIView
@property(nonatomic, copy) NSString *accessibilityLabel;
@property(nonatomic, assign) CGRect frame;
@property(nonatomic, strong) NSArray *subviews;
@property(nonatomic, assign) CGAffineTransform transform;
@end

@interface AWECommentImageModel : NSObject
@property(nonatomic, copy) NSString *originUrl;
@end

@class AWECommentModel;
@class AWECommentLongPressPanelParam;
@class AWEIMStickerModel;
@class AWEURLModel;

@interface AWECommentLongPressPanelContext : NSObject
- (AWECommentModel *)selectdComment;
- (AWECommentLongPressPanelParam *)params;
@end

@interface AWECommentLongPressPanelParam : NSObject
- (AWECommentModel *)selectdComment;
@end

@interface AWECommentModel : NSObject
- (AWEIMStickerModel *)sticker;
- (NSString *)content;
@end

@interface AWEIMStickerModel : NSObject
- (AWEURLModel *)staticURLModel;
@end

@interface _TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement : NSObject
- (AWECommentLongPressPanelContext *)commentPageContext;
@end

@interface _TtC33AWECommentLongPressPanelSwiftImpl32CommentLongPressPanelCopyElement : NSObject
- (AWECommentLongPressPanelContext *)commentPageContext;
@end

@interface AWEFeedProgressSlider : UIView
@property(nonatomic, assign) float maximumValue;
@property(nonatomic, strong) UIView *leftLabelUI;
@property(nonatomic, strong) UIView *rightLabelUI;
@property(nonatomic) AWEPlayInteractionProgressController *progressSliderDelegate;

- (void)applyCustomProgressStyle;
- (void)applyWidthPercentToSubviews:(CGFloat)widthPercent;
@end

@interface AWEFeedChannelObject : NSObject
@property(nonatomic, copy) NSString *channelID;
@property(nonatomic, copy) NSString *channelTitle;
@end

@interface AWEFeedChannelManager : NSObject
- (AWEFeedChannelObject *)getChannelWithChannelID:(NSString *)channelID;
@end

@interface AWEHPTopTabItemModel : NSObject
@property(nonatomic, copy) NSString *channelID;
@property(nonatomic, copy) NSString *channelTitle;
@property(nonatomic, copy) NSString *title;
@end

@interface AWEPlayInteractionStrongifyShareContentView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEAntiAddictedNoticeBarView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEFeedAnchorContainerView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEIMMessageTabOptPushBannerView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEFeedStickerContainerView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEECommerceEntryView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWETemplateTagsCommonView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AFDSkylightCellBubble : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface LOTAnimationView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWENearbySkyLightCapsuleView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEPlayInteractionCoCreatorNewInfoView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AFDCancelMuteAwemeView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEPlayDanmakuInputContainView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEPlayInteractionRelatedVideoView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEFeedRelatedSearchTipView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEProfileMixCollectionViewCell : UIView
@end

@interface AWEProfileTaskCardStyleListCollectionViewCell : UIView
@end

// AWEVersionUpdateManager相关接口声明
@interface AWEVersionUpdateManager : NSObject
@property(nonatomic, strong) id networkModule;
@property(nonatomic, strong) id badgeModule;
@property(nonatomic, strong) id workflow;
- (NSString *)currentVersion;
- (void)startVersionUpdateWorkflow:(id)arg1 completion:(id)arg2;
- (void)workflowDidFinish:(id)arg1;
+ (id)sharedInstance;
@end

@interface AWEVersionUpdateNetworkModule : NSObject
@end

@interface AWEVersionUpdateBadgeModule : NSObject
@end

@interface AWEVersionUpdateWorkflow : NSObject
@end

@interface AWEStoryProgressSlideView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

// 隐藏好友分享私信
@interface AFDNewFastReplyView
@property(nonatomic, weak) UIView *superview;
@property(nonatomic) BOOL hidden;
@end

@interface AWENewLiveSkylightViewController : UIViewController
- (void)showSkylight:(BOOL)arg0 animated:(BOOL)arg1 actionMethod:(unsigned long long)arg2;
- (void)updateIsSkylightShowing:(BOOL)arg0;
@end

@interface AWENearbyFullScreenViewModel : NSObject
- (void)setShowSkyLight:(id)arg1;
- (void)setHaveSkyLight:(id)arg1;
@end

@interface AWECorrelationItemTag : UIView
- (void)layoutSubviews;
@end

@interface AWEPlayInteractionTemplateButtonGroup : UIView
- (void)layoutSubviews;
@end

@interface AWEHPDiscoverFeedEntranceView : UIView
- (void)configImage:(UIImageView *)imageView Label:(UILabel *)label position:(NSInteger)pos;
@end

@interface AWEIMCellLiveStatusContainerView : UIView
- (void)p_initUI;
@end

@interface AWELiveSkylightCatchView : UIView
- (void)setupUI;
@end

@interface AWEIMFansGroupTopDynamicDomainTemplateView : UIView
- (void)layoutSubviews;
@end

@interface AWETemplateCommonView : UIView
- (void)layoutSubviews;
@end

@interface AWEUIAlertView : UIView
- (void)show;
@end

@interface AWETeenModeAlertView : UIView
- (BOOL)show;
@end

@interface AWETeenModeSimpleAlertView : UIView
- (BOOL)show;
@end

@interface AWEVideoTypeTagView : UIView
@end

@interface AWELiveStatusIndicatorView : UIView
@end

@interface AWEIMInputActionBarInteractor : UIView
- (void)p_setupUI;
@end

@interface AWELiveFeedStatusLabel : UILabel
@end

@interface BDXWebView : UIView
@end

@interface IESLiveActivityBannnerView : UIView
@end
@interface AWECommentSearchAnchorView : UIView
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (void)layoutSubviews;
@end

@interface AWEPOIEntryAnchorView : UIView
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (void)layoutSubviews;
- (void)p_processModels:(id)models withPOIName:(id)poiName;
@end

@interface AWECommentGuideLunaAnchorView : UIView
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (void)layoutSubviews;
@end

@interface AWEFeedTopBarContainer : UIView
- (void)applyDYYYTransparency;
@end

@interface AWEHPTopBarCTAContainer : UIView
- (void)applyDYYYTransparency;
@end

@interface ACCStickerContainerView : UIView
@end

@interface AWEUserActionSheetView : UIView
- (instancetype)init;
- (UIView *)containerView;
- (void)setActions:(NSArray *)actions;
- (void)show;
- (void)applyBlurEffectAndWhiteText;
- (void)setTextColorWhiteRecursivelyInView:(UIView *)view;
@end

@interface AWEUserSheetAction : NSObject
+ (instancetype)actionWithTitle:(NSString *)title imgName:(NSString *)imgName handler:(id)handler;
+ (instancetype)actionWithTitle:(NSString *)title style:(NSUInteger)style imgName:(NSString *)imgName handler:(id)handler;
@end

@interface AWEPlayInteractionDescriptionScrollView : UIScrollView
@end

@interface AWEUserNameLabel : UIView
@end

@interface AWEPlayInteractionDescriptionLabel : UILabel
@end
// 关注直播
@interface AWEConcernSkylightCapsuleView : UIView
@end
// 直播发现
@interface AWEFeedLiveTabRevisitControlView : UIView
@end
// 直播 退出清屏、投屏按钮
@interface IESLiveButton : UIView
@end
// 直播右上关闭按钮
@interface IESLiveLayoutPlaceholderView : UIView
@end
// 直播点歌
@interface IESLiveKTVSongIndicatorView : UIView
@end
// 图片滑条
@interface AWEStoryProgressContainerView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
- (void)layoutSubviews;
- (void)updateIndicatorWithPageCount:(NSInteger)count;
@end

@interface AWESearchAnchorListModel : NSObject
- (id)init;
@end

@interface AWEPlayInteractionAvatarView : UIView
@property(nonatomic, readonly) NSArray *subviews;
@property(nonatomic, readonly) CGRect frame;
@end

// 直播间流量提醒弹窗
@interface AWELiveFlowAlertView : UIView
@end

// 搜索视频底部评论视图
@interface AWECommentInputBackgroundView : UIView
@end

// 聊天视频底部快速回复视图
@interface AWEIMFeedBottomQuickEmojiInputBar : UIView
@end

@interface DUXBadge : UIView
@end

@interface ACCEditTagStickerView : UIView
@end

@interface AWESearchFeedTagView : UIView
@end

@interface AFDRecommendToFriendTagView : UIView
@end

@interface AFDAIbumFolioView : UIView
@end

@interface AWEHPTopBarCTAItemView : UIView
@end

@interface AWEVideoPlayDanmakuContainerView : UIView
@end

// 应用内推送容器
@interface AWEInnerNotificationWindow : UIWindow
- (void)setupBlurEffectForNotificationView;
- (void)applyBlurEffectToView:(UIView *)containerView;
- (void)setLabelsColorWhiteInView:(UIView *)view;
- (void)clearBackgroundRecursivelyInView:(UIView *)view;
@end

@interface AWEFakeProgressSliderView : UIView
- (void)applyCustomProgressStyle;
@end

// 添加 DUXContentSheet 相关声明
@protocol IESIMContentSheetVCProtocol
, AWEMRGlobalAlertTrackProtocol;
@interface DUXBasicSheet : UIViewController
@end

@interface AWEBinding : NSObject
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

@interface AWESettingBaseViewModel : NSObject
@end

@interface AWESettingBaseViewController : UIViewController
@property(nonatomic, strong) UIView *view;
@property(nonatomic, strong) UITableView *tableView;
- (AWESettingBaseViewModel *)viewModel;
@end

@interface AWESettingsViewModel : AWESettingBaseViewModel
@property(nonatomic, assign) NSInteger colorStyle;
@property(nonatomic, strong) NSArray *sectionDataArray;
@property(nonatomic, weak) id controllerDelegate;
@property(nonatomic, strong) NSString *traceEnterFrom;

- (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict;
- (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict cellTapHandlers:(NSMutableDictionary *)cellTapHandlers;

- (void)refreshTableView;
- (void)updateSectionDataArray;
- (void)handleConflictsAndDependenciesForSetting:(NSString *)identifier isEnabled:(BOOL)isEnabled;
- (void)updateDependentItemsForSetting:(NSString *)identifier value:(id)value;
- (void)handleConflictsAndDependenciesForSetting:(NSString *)identifier isEnabled:(BOOL)isEnabled;
- (void)applyDependencyRulesForItem:(AWESettingItemModel *)item;
- (void)updateConflictingItemUIState:(NSString *)identifier withValue:(BOOL)value;
- (NSDictionary *)settingsDependencyConfig;
@end

@interface AWENavigationBar : UIView
@property(nonatomic, strong) UILabel *titleLabel;
@end

@interface AWESettingSectionModel : NSObject
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, assign) CGFloat sectionHeaderHeight;
@property(nonatomic, copy) NSString *sectionHeaderTitle;
@property(nonatomic, strong) NSArray *itemArray;
@property(retain, nonatomic) NSString *identifier;
@property(copy, nonatomic) NSString *title;
- (id)initWithIdentifier:(id)arg1;
- (void)setIsSelect:(BOOL)arg1;
- (BOOL)isSelect;
- (void)setCellTappedBlock:(id)arg1;
- (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict;
- (AWESettingItemModel *)createSettingItem:(NSDictionary *)dict cellTapHandlers:(NSMutableDictionary *)cellTapHandlers;
- (void)applyDependencyRulesForItem:(AWESettingItemModel *)item;
- (void)handleConflictsAndDependenciesForSetting:(NSString *)identifier isEnabled:(BOOL)isEnabled;
- (void)updateDependentItemsForSetting:(NSString *)identifier value:(id)value;
@end

@interface AWEPrivacySettingActionSheetConfig : NSObject
@property(copy, nonatomic) NSArray *models;
@property(copy, nonatomic) NSString *headerText;
@property(copy, nonatomic) NSString *headerTitleText;
@property(nonatomic) BOOL needHighLight;
@property(nonatomic) BOOL useCardUIStyle;
@property(nonatomic) BOOL fromHalfScreen;
@property(retain, nonatomic) UIImage *headerLabelIcon;
@property(nonatomic) CGFloat sheetWidth;
@property(nonatomic) BOOL adaptIpadFromHalfVC;
@end

@interface AWEPrivacySettingActionSheet : UIView
+ (id)sheetWithConfig:(id)arg1;
@property(copy, nonatomic) id closeBlock;
@end

@interface DUXContentSheet : UIViewController
- (void)showOnViewController:(id)arg1 completion:(id)arg2;
- (instancetype)initWithRootViewController:(UIViewController *)controller withTopType:(NSInteger)topType withSheetAligment:(NSInteger)alignment;
- (void)setAutoAlignmentCenter:(BOOL)center;
- (void)setSheetCornerRadius:(CGFloat)radius;
@property(retain, nonatomic) UIView *fullScreenView;
@end

@protocol AFDPrivacyHalfScreenViewControllerProtocol <NSObject>
@end

@interface AWEHalfScreenBaseViewController : UIViewController
- (void)setCornerRadius:(CGFloat)radius;
- (void)setOnlyTopCornerClips:(BOOL)onlyTop;
@end

@interface AWEButton : UIButton
@end

@interface AFDButton : UIButton
@end

@interface AWEProfileToggleView : UIView
@end

@interface DUXAbandonedButton : UIButton
@end

@interface AFDPrivacyHalfScreenViewController : AWEHalfScreenBaseViewController <AFDPrivacyHalfScreenViewControllerProtocol>
@property(retain, nonatomic) UILabel *titleLabel;
@property(retain, nonatomic) UILabel *contentLabel;
@property(retain, nonatomic) UIImageView *imageView;
@property(copy, nonatomic) void (^rightBtnClickedBlock)(void);
@property(copy, nonatomic) void (^leftButtonClickedBlock)(void);
@property(retain, nonatomic) AWEButton *leftCancelButton;
@property(retain, nonatomic) AWEButton *rightConfirmButton;

- (void)configWithImageView:(UIImageView *)imageView
                  lockImage:(UIImage *)lockImage
           defaultLockState:(BOOL)defaultLockState
             titleLabelText:(NSString *)titleText
           contentLabelText:(NSString *)contentText
       leftCancelButtonText:(NSString *)leftButtonText
     rightConfirmButtonText:(NSString *)rightButtonText
       rightBtnClickedBlock:(void (^)(void))rightBtnBlock
     leftButtonClickedBlock:(void (^)(void))leftBtnBlock;

- (void)setCornerRadius:(CGFloat)radius;
- (void)setOnlyTopCornerClips:(BOOL)onlyTop;
- (void)setUseCardUIStyle:(BOOL)arg1;
- (void)setShouldShowToggle:(BOOL)arg1;
- (NSUInteger)animationStyle;
- (NSUInteger)viewStyle;
- (void)setSlideDismissBlock:(void (^)(void))slideDismissBlock;
- (void)setTapDismissBlock:(void (^)(void))tapDismissBlock;
- (void)setAfterDismissBlock:(void (^)(void))afterDismissBlock;
- (void)updateDarkModeAppearance;
@end

@interface AWELoadingAndVolumeView : UIView
@end

@interface BDImageView : UIImageView
@end

@interface AWEIMEmoticonModel : NSObject
- (id)valueForKey:(NSString *)key;
@end

@interface AWEIMEmoticonPreviewV2 : UIView
@property(nonatomic, strong) UIView *container;
@property(nonatomic, strong) BDImageView *content;
@property(nonatomic, strong) AWEIMEmoticonModel *model;
- (void)dyyy_saveButtonTapped:(id)sender;
@end

// 设置修改顶栏标题
@interface AWEHPTopTabItemTextContentView : UIView
- (void)setContentText:(NSString *)text;
@end

// 直播间商品信息
@interface IESECLivePluginLayoutView : UIView
@end

// 直播间点赞动画
@interface HTSLiveDiggView : UIView
@end

// 隐藏状态栏
@interface AWEFeedRootViewController : UIViewController
- (BOOL)prefersStatusBarHidden;
@end

@interface IESLiveAudienceViewController : UIView
- (BOOL)prefersStatusBarHidden;
@end

@interface AWEFeedUnfollowFamiliarFollowAndDislikeView : UIView
@end

@interface AWEDPlayerFeedPlayerViewController : UIViewController
@property(nonatomic) UIView *contentView;
- (void)setVideoControllerPlaybackRate:(double)arg0;
@end

// 底部热点提示框
@interface AWENewHotSpotBottomBarView : UIView
@property(nonatomic, strong, readonly) UIView *superview;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
@end

// 评论区免费去看短剧
@interface AWEShowPlayletCommentHeaderView : UIView
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (void)layoutSubviews;
@end

@interface ACCGestureResponsibleStickerView : UIView
@end

@interface AWEDemaciaChapterProgressSlider : UIView
@end

@interface AWEABTestManager : NSObject
@property(retain, nonatomic) NSDictionary *abTestData;
@property(retain, nonatomic) NSMutableDictionary *consistentABTestDic;
@property(copy, nonatomic) NSDictionary *performanceReversalDic;
- (void)setAbTestData:(id)arg1;
- (void)_saveABTestData:(id)arg1;
- (id)abTestData;
+ (id)sharedManager;
@end

@interface IESLiveRoomComponent : NSObject
@end

@interface HTSLiveStreamQualityFragment : IESLiveRoomComponent
@property(nonatomic, strong) NSArray *streamQualityArray;
- (NSArray *)getQualities;
- (void)setResolutionWithIndex:(NSInteger)index isManual:(BOOL)manual beginChange:(void (^)(void))beginChangeBlock completion:(void (^)(void))completionBlock;
@end