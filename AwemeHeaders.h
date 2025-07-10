#import <Photos/Photos.h>
#import <UIKit/UIKit.h>

// 获取指定类型设置，键名不存在或类型错误时返回nil
#define DYYYGetBool(key) [[NSUserDefaults standardUserDefaults] boolForKey:key]
#define DYYYGetFloat(key) [[NSUserDefaults standardUserDefaults] floatForKey:key]
#define DYYYGetInteger(key) [[NSUserDefaults standardUserDefaults] integerForKey:key]
#define DYYYGetString(key) [[NSUserDefaults standardUserDefaults] stringForKey:key]
#define DYYY_IGNORE_GLOBAL_ALPHA_TAG 114514
typedef NS_ENUM(NSInteger, MediaType) { MediaTypeVideo, MediaTypeImage, MediaTypeAudio, MediaTypeHeic };

static __weak UICollectionView *gFeedCV = nil;
// 音量控制
@interface AVSystemController : NSObject
+ (instancetype)sharedAVSystemController;
- (BOOL)setVolumeTo:(float)value forCategory:(NSString *)cat;
- (float)volumeForCategory:(NSString *)cat;
@end
// 亮度控制
@interface SBHUDController : NSObject
+ (instancetype)sharedInstance;
- (void)presentHUDWithIcon:(NSString *)name level:(float)level;
@end
// 调节模式&全局状态
typedef NS_ENUM(NSUInteger, DYEdgeMode) {
    DYEdgeModeNone = 0,
    DYEdgeModeBrightness = 1,
    DYEdgeModeVolume = 2,
};
static DYEdgeMode gMode = DYEdgeModeNone;
static CGFloat gStartY = 0.0;
static CGFloat gStartVal = 0.0;

@interface URLModel : NSObject
@property(nonatomic, strong) NSArray *originURLList;
@end

@interface DUXToast : NSObject
+ (void)showText:(NSString *)text;
@end

@interface AWEURLModel : NSObject
@property(nonatomic, copy) NSArray *originURLList;
@property(nonatomic, assign) NSInteger imageWidth;
@property(nonatomic, assign) NSInteger imageHeight;
@property(nonatomic, copy) NSString *URLKey;
- (NSArray *)originURLList;
- (id)URI;
- (NSURL *)getDYYYSrcURLDownload;
@end

@interface AWEVideoModel : NSObject
@property(nonatomic, strong) AWEURLModel *playLowBitURL;
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
@property(copy, nonatomic) NSString *signature;
@property(copy, nonatomic) AWEURLModel *avatarMedium;
@end

@interface AWEAnimatedImageVideoInfo : NSObject
@end

@interface AWEPropGuideV2Model : NSObject
@property(nonatomic, copy) NSString *propName;
@end

@interface AWEECommerceLabel : NSObject
@end

@interface AWELiveFollowFeedCellModel : NSObject
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
@property(nonatomic, assign) BOOL isLivePhoto;
@property(nonatomic, strong) NSString *shareURL;
@property(nonatomic, strong) id hotSpotLynxCardModel;
@property(nonatomic, strong) AWELiveFollowFeedCellModel *cellRoom;
@property(nonatomic, strong) id shareRecExtra;  // 推荐视频专有属性
@property(nonatomic, strong) NSArray<AWEAwemeTextExtraModel *> *textExtras;
@property(nonatomic, copy) NSString *itemTitle;
@property(nonatomic, copy) NSString *descriptionSimpleString;
@property(nonatomic, strong) NSString *itemID;
@property(nonatomic, strong) AWEUserModel *author;
@property(nonatomic, strong) AWEAnimatedImageVideoInfo *animatedImageVideoInfo;
@property(nonatomic, strong) AWEAwemeStatisticsModel *statistics;
@property(nonatomic, strong) AWEPropGuideV2Model *propGuideV2;
@property(nonatomic, strong) AWEECommerceLabel *ecommerceBelowLabel;
- (BOOL)isLive;
- (BOOL)contentFilter;
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

@interface AWEFeedTabJumpGuideView : UIView
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
@end

@interface AWELeftSideBarEntranceView : UIView
- (void)setNumericalRedDot:(id)numericalRedDot;
- (void)setRedDot:(id)redDot;
@end

@interface AWEDanmakuContentLabel : UILabel
@property(nonatomic, assign) long long type;
@property(nonatomic, copy) NSString *danmakuText;
@property(nonatomic, copy) NSArray *danmakuStyleList;
@property(nonatomic, strong) UIColor *strokeColor;
@property(nonatomic, assign) double strokeWidth;
- (id)colorFromHexString:(id)arg0 baseColor:(id)arg1;
- (void)setTextColor:(id)arg0;
- (id)initWithFrame:(id)arg0 textColor:(id)arg1 type:(long long)arg2;
- (id)danmakuText;
- (void)setDanmakuText:(id)arg0;
- (id)danmakuStyleList;
- (void)drawUnderLineWithStart:(long long)arg0 len:(long long)arg1;
- (void)setDanmakuStyleList:(id)arg0;
- (double)strokeWidth;
- (id)accessibilityLabel;
- (void)setStrokeWidth:(double)arg0;
- (void)setAccessibilityLabel:(id)arg0;
- (void)setStrokeColor:(id)arg0;
- (id)strokeColor;
- (long long)type;
- (id)initWithFrame:(id)arg0;
- (id)boundingRectForCharacterRange:(id)arg0;
- (void)drawTextInRect:(id)arg0;
- (void)setType:(long long)arg0;
@end

@interface XIGDanmakuPlayerView : UIView
@end
@interface DDanmakuPlayerView : UIView
@end

@interface AWEDanmakuItemTextInfo : NSObject
@property(nonatomic, strong) NSAttributedString *danmakuText;
@property(nonatomic, assign) id danmakuTextFrame;
@property(nonatomic, assign) double strokeWidth;
@property(nonatomic, strong) UIColor *strokeColor;
@property(nonatomic, strong) UIFont *danmakuFont;
@property(nonatomic, strong) UIColor *danmakuTextColor;
- (id)colorFromHexStringForTextInfo:(id)arg0;
- (void)setDanmakuFont:(id)arg0;
- (id)danmakuFont;
- (id)danmakuText;
- (void)setDanmakuText:(id)arg0;
- (id)danmakuTextFrame;
- (void)setDanmakuTextFrame:(id)arg0;
- (id)danmakuTextColor;
- (void)setDanmakuTextColor:(id)arg0;
- (double)strokeWidth;
- (void)setStrokeWidth:(double)arg0;
- (void)setStrokeColor:(id)arg0;
- (id)strokeColor;
@end

@interface AWELandscapeFeedEntryView : UIView
@end

@interface AWEIMFeedVideoQuickReplayInputViewController : UIViewController
@end

@interface AWEHPSearchBubbleEntranceView : UIView
@end

@interface AWEPlayInteractionViewController : UIViewController
@property(nonatomic, strong) UIView *view;
@property(nonatomic, strong) AWEAwemeModel *model;
@property(nonatomic, strong) NSString *referString;
@property(nonatomic, assign) BOOL isCommentVCShowing;
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

@interface AWEFeedVideoButton : UIButton
@end

@interface AWEMusicCoverButton : UIButton
@end

@interface AWEAwemePlayVideoViewController : UIViewController
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context;
- (void)setVideoControllerPlaybackRate:(double)arg0;

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

@interface AWEAwemeDetailTableView : UITableView
@end

@interface AWECommentContainerViewController : UIViewController
@end

@interface AWECommentInputViewController : UIViewController
@end

@interface AWEAwemeDetailTableViewCell : UIView
@end

@interface IESLiveFeedDrawerEntranceView : UIView
@end

@interface AWEPlayInteractionProgressContainerView : UIView
@end

@interface AFDFastSpeedView : UIView
@end

@interface AWEAwemeOfflineBottomView : UIView
@end

@interface AWEUserWorkCollectionViewComponentCell : UICollectionViewCell
@end

@interface AWELandscapeFeedViewController : UIViewController
@property(nonatomic, strong) UICollectionView *collectionView;
@end

@interface AWEFeedRefreshFooter : UIView
@end

@interface AWERLSegmentView : UIView
@end

@interface AWEBaseListViewController : UIViewController
- (void)applyBlurEffectIfNeeded;
- (UILabel *)findCommentLabel:(UIView *)view;
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

@interface AFDRecommendToFriendTagView : UIView
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

@interface AWEElementStackView : UIView
@property(nonatomic, copy) NSString *accessibilityLabel;
@property(nonatomic, assign) CGRect frame;
@property(nonatomic, strong) NSArray *subviews;
@property(nonatomic, assign) CGAffineTransform transform;
- (BOOL)view:(UIView *)view containsSubviewOfClass:(Class)viewClass;
@end

@interface IESLiveStackView : UIView
@property(nonatomic, assign) CGRect frame;
@property(nonatomic, assign) CGAffineTransform transform;
@property(nonatomic, assign) CGFloat alpha;
@property(nonatomic, strong) UIView *superview;
@property(nonatomic, strong) NSArray *subviews;
@property(nonatomic, copy) NSString *accessibilityLabel;
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

@interface AWEProfileMixItemCollectionViewCell : UICollectionViewCell
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
@end

@interface AWEHPTopBarCTAContainer : UIView
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
@end

@protocol IESIMContentSheetVCProtocol
, AWEMRGlobalAlertTrackProtocol;
@interface DUXBasicSheet : UIViewController
@end

@interface AWEBinding : NSObject
@end

@interface AWESettingItemModel : NSObject
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subTitle;
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
- (void)refreshCell;
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
@end

@interface AWENavigationBar : UIView
@property(nonatomic, strong) UILabel *titleLabel;
@end

@interface AWESettingSectionModel : NSObject
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, assign) CGFloat sectionHeaderHeight;
@property(nonatomic, copy) NSString *sectionHeaderTitle;
@property(nonatomic, copy) NSString *sectionFooterTitle;
@property(nonatomic, assign) BOOL useNewFooterLayout;
@property(nonatomic, strong) NSArray *itemArray;
@property(retain, nonatomic) NSString *identifier;
@property(copy, nonatomic) NSString *title;
- (id)initWithIdentifier:(id)arg1;
- (void)setIsSelect:(BOOL)arg1;
- (BOOL)isSelect;
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

@interface AWELeftSideBarAddChildTransitionObject : NSObject
@end

@interface AWEButton : UIButton
@end

@interface AFDButton : UIButton
@end

@interface AWENoxusHighlightButton : UIButton
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
@property(copy, nonatomic) void (^closeButtonClickedBlock)(void);
@property(copy, nonatomic) void (^singleTapBlock)(void);
@property(copy, nonatomic) void (^toggleBlock)(void);
@property(copy, nonatomic) void (^tapDismissBlock)(void);
@property(copy, nonatomic) void (^slideDismissBlock)(void);
@property(copy, nonatomic) void (^afterDismissBlock)(void);
@property(copy, nonatomic) void (^afterDismissWithSwitchChangedBlock)(void);
@property(copy, nonatomic) NSString *knownButtonText;
@property(assign, nonatomic) BOOL shouldShowKnownButton;
@property(assign, nonatomic) UIEdgeInsets lockImageInset;
@property(retain, nonatomic) UIImage *lockImage;
@property(retain, nonatomic) UIImage *closeImage;
@property(retain, nonatomic) AFDButton *cancelButton;
@property(retain, nonatomic) AWEButton *knownButton;
@property(retain, nonatomic) AWEButton *leftCancelButton;
@property(retain, nonatomic) AWEButton *rightConfirmButton;

- (void)configWithCloseButtonClickedBlock:(void (^)(void))closeButtonClickedBlock singleTapBlock:(void (^)(void))singleTapBlock toggleBlock:(void (^)(void))toggleBlock;
- (void)configWithImageView:(UIImageView *)imageView
                  titleText:(NSString *)titleText
                contentText:(NSString *)contentText
               settingsText:(NSString *)settingsText
             singleTapBlock:(void (^)(void))singleTapBlock;
- (void)configWithImageView:(UIImageView *)imageView
                  lockImage:(UIImage *)lockImage
             lockImageInset:(UIEdgeInsets)lockImageInset
             titleLabelText:(NSString *)titleLabelText
           contentLabelText:(NSString *)contentLabelText
            knownButtonText:(NSString *)knownButtonText
            toggleTitleText:(NSString *)toggleTitleText
               defaultState:(BOOL)defaultState
           defaultLockState:(BOOL)defaultLockState;
- (void)configWithImageView:(UIImageView *)imageView
                 closeImage:(UIImage *)closeImage
                  lockImage:(UIImage *)lockImage
             titleLabelText:(NSString *)titleLabelText
           contentLabelText:(NSString *)contentLabelText
            knownButtonText:(NSString *)knownButtonText
            toggleTitleText:(NSString *)toggleTitleText
               defaultState:(BOOL)defaultState
           defaultLockState:(BOOL)defaultLockState;
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
- (void)cancelButtonTapped;
- (void)settingsTextTapped;
- (void)knownButtonClicked;
- (void)showKnownButton;
- (void)updateDarkModeAppearance;
- (void)presentOnViewController:(UIViewController *)presentingViewController;
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
@interface IESLiveStickerView : UIView
@end
@interface IESLivePreAnnouncementPanelViewNew : UIView
@end
@interface IESLiveDynamicUserEnterView : UIView
@end
@interface IESLiveDynamicRankListEntranceView : UIView
@end
@interface IESLiveShortTouchActionView : UIView
@end
@interface PlatformCanvasView : UIView
@end
@interface IESLiveDanmakuVariousView : UIView
@end
@interface IESLiveLotteryAnimationViewNew : UIView
@end
@interface IESLiveMatrixEntranceView : UIView
@end
@interface IESLiveConfigurableShortTouchEntranceView : UIView
@end
@interface IESLiveRedEnvelopeAniLynxView : UIView
@end
@interface IESLiveBottomRightCardView : UIView
@end
@interface IESLiveGameCPExplainCardContainerImpl : UIView
@end
@interface AWEPOILivePurchaseAtmosphereView : UIView
@end
@interface IESLiveHotMessageView : UIView
@end
@interface AWEHomePageBubbleLiveHeadLabelContentView : UIView
@end

// 隐藏状态栏
@interface AWEFeedRootViewController : UIViewController
- (BOOL)prefersStatusBarHidden;
@end
@interface IESLiveAudienceViewController : UIViewController
- (BOOL)prefersStatusBarHidden;
@end
@interface AWEAwemeDetailTableViewController : UIViewController
- (BOOL)prefersStatusBarHidden;
@end
@interface AWEAwemeHotSpotTableViewController : UIViewController
- (BOOL)prefersStatusBarHidden;
@end
@interface AWEFullPageFeedNewContainerViewController : UIViewController
- (BOOL)prefersStatusBarHidden;
@end

@interface AWEFeedUnfollowFamiliarFollowAndDislikeView : UIView
@end

@interface AWEDPlayerFeedPlayerViewController : UIViewController
@property(nonatomic) UIView *contentView;
- (void)setVideoControllerPlaybackRate:(double)arg0;
@end

@interface AWEPlayInteractionElementMaskView : UIView
@end
@interface AWEGradientView : UIView
@end
@interface AWEHotSpotBlurView : UIView
@end
@interface AWEHotSearchInnerBottomView : UIView
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

@interface AWELiveAutoEnterStyleAView : UIView
@end

@interface IESLiveRoomComponent : NSObject
@end

@interface HTSLiveStreamQualityFragment : IESLiveRoomComponent
@property(nonatomic, strong) NSArray *streamQualityArray;
- (NSArray *)getQualities;
- (void)setResolutionWithIndex:(NSInteger)index isManual:(BOOL)manual beginChange:(void (^)(void))beginChangeBlock completion:(void (^)(void))completionBlock;
@end

@interface DUXPopover : UIView
@end

@interface AWESearchViewController : UIViewController
@property(nonatomic, strong) UITabBarController *tabBarController;
@end

@interface AWEIMCommentShareUserHorizontalSectionController : UIViewController
- (void)configCell:(id)cell index:(NSInteger)index model:(id)model;
@end

@interface AWEIMCommentShareUserHorizontalCollectionViewCell : UIView
@end

@interface AWENormalModeTabBarFeedView : UIView
@end

@interface AWENormalModeTabBarController : UIViewController
@property(nonatomic, strong) AWENormalModeTabBar *awe_tabBar;
- (void)handleApplicationWillEnterForeground:(NSNotification *)notification;
@end

@interface AWELeftSideBarWeatherLabel : UILabel
@property(nonatomic, assign) BOOL userInteractionEnabled;
@property(nonatomic, strong) UIColor *textColor;
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
@end
@interface AWELeftSideBarWeatherView : UIView
@property(nonatomic, readonly) NSArray<UIView *> *subviews;
- (UITapGestureRecognizer *)tapGestureForDYYY;
- (UITapGestureRecognizer *)tapGestureForSubview:(UIView *)subview;
- (void)openDYYYSettings;
@end

@interface AWEFeedContainerViewController : UIViewController
@end

@interface AWEIMGiphyMessage : NSObject
@property(nonatomic, copy, readwrite) AWEURLModel *giphyURL;
@end

@interface AWEIMMessageComponentContext : NSObject
@property(nonatomic, weak, readwrite) AWEIMGiphyMessage *message;
@end

@interface AWEIMReusableCommonCell : UITableViewCell
@property(nonatomic, weak, readwrite) id currentContext;
@end

@interface AWEIMCustomMenuModel : NSObject
@property(nonatomic, copy, readwrite) NSString *title;
@property(nonatomic, copy, readwrite) NSString *imageName;
@property(nonatomic, copy, readwrite) id willPerformMenuActionSelectorBlock;
@property(nonatomic, copy, readwrite) NSString *trackerName;
@property(nonatomic, assign, readwrite) NSUInteger type;
@end

@interface AWEPlayInteractionSpeedController : NSObject
@property(nonatomic, strong) id progressSliderDelegate;
- (CGFloat)longPressFastSpeedValue;
- (void)changeSpeed:(double)speed;
- (void)handleLongPressLockedDoubleSpeedChanged:(id)arg1 gesture:(UIGestureRecognizer *)gesture;
- (void)handleLongPressLockedSpeedBegan;
- (void)handleLongPressLockedDoubleSpeedEnded:(id)arg1 gesture:(UIGestureRecognizer *)gesture;
- (void)longPressSpeedControlDidChangeSpeed:(double)speed;
@end

@interface AWEPlayInteractionUserAvatarView : UIView
@end

@interface AWELeftSideBarViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>
- (UICollectionView *)collectionView;
- (void)adjustContainerViewLayout:(UICollectionViewCell *)cell;
@end

@interface AWESettingsTableViewController : AWESettingBaseViewController
- (id)viewModel;
- (void)removeAboutSection;
@end

@interface AWEProfileMixCollectionView : UICollectionView
@property(nonatomic, assign) BOOL fromHome;
@end

@interface AFDViewedBottomView : UIView
@property(nonatomic, strong, readonly) UIView *effectView;
@end

@interface AWEAwemeDetailNaviBarContainerView : UIView
@end

@interface AWEVideoBSModel : NSObject
@property(nonatomic) NSNumber *bitrate;
@property(nonatomic) AWEURLModel *playAddr;
@end

@interface AWENormalModeTabBarGeneralPlusButton : UIView
@end

@interface AWEMixVideoPanelMoreView : UIView
@end

@interface AWEPlayInteractionUserAvatarElement : NSObject
@property(retain, nonatomic) AWEAwemeModel *model;
@end

@interface AWEPlayInteractionUserAvatarFollowController : UIViewController
@property(retain, nonatomic) AWEAwemeModel *model;
@end

@interface AWECodeGenCommonAnchorBasicInfoModel : UIViewController
@property(copy, nonatomic) NSString *name;
@end

@interface AWEFeedTemplateAnchorView : UIView
@property(retain, nonatomic) AWECodeGenCommonAnchorBasicInfoModel *templateAnchorInfo;
@end

@interface AWEVideoPlayerConfiguration : NSObject
+ (void)setHDRBrightnessStrategy:(id)strategy;
+ (double)getHDRBrightnessOffset:(double)offset brightness:(double)brightness;
@end

@interface IESFiltersManager : NSObject
- (void)setHDRIndensity:(double)intensity;
@end

@interface AWEFeedPauseVideoRelatedWordView : UIView
@end

@interface AWEFeedPauseRelatedWordComponent : NSObject
@property(nonatomic, strong) AWEFeedPauseVideoRelatedWordView *relatedView;
@property(nonatomic, strong) AWEAwemeModel *currentAweme;
@property(nonatomic, assign) long long pauseContentNum;

@end

@interface YYAnimatedImageView : UIImageView
@end

@interface AWEProfileMentionLabel : UILabel
@property(copy, nonatomic) NSString *text;
@end

@interface MTKView : UIView
@end

@interface HTSEventForwardingView : UIView
@property(copy, nonatomic) NSString *levelName;
@end
