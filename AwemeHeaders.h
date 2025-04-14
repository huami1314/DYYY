#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#define DYYY 100

typedef NS_ENUM(NSInteger, MediaType) {
    MediaTypeVideo,
    MediaTypeImage,
    MediaTypeAudio,
    MediaTypeHeic
};

@interface URLModel : NSObject
@property (nonatomic, strong) NSArray *originURLList;
@end

@interface DUXToast : NSObject
+ (void)showText:(NSString *)text;
@end


@interface AWEURLModel : NSObject
- (NSArray *)originURLList;
- (id)URI;
- (NSURL *)getDYYYSrcURLDownload;
@end

@interface AWEVideoModel : NSObject
@property (retain, nonatomic) AWEURLModel *playURL;
@property (copy, nonatomic) NSArray * manualBitrateModels;
@property (copy, nonatomic) NSArray * bitrateModels;
@property (nonatomic, strong) URLModel *h264URL;
@property (nonatomic, strong) URLModel *coverURL;
@end

@interface AWEMusicModel : NSObject
@property (nonatomic, strong) URLModel *playURL;
@end

@interface AWEImageAlbumImageModel : NSObject
@property (nonatomic, strong) NSArray *urlList;
@property (retain, nonatomic) AWEVideoModel *clipVideo;
@end

@interface AWEAwemeStatisticsModel : NSObject
@property (nonatomic, strong) NSNumber *diggCount;
@end

@interface AWESearchAwemeExtraModel : NSObject
@end

@interface AWEAwemeTextExtraModel : NSObject
@property (nonatomic, copy) NSString *hashtagName;
@property (nonatomic, copy) NSString *hashtagId;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) NSRange textRange;
@property (nonatomic, copy) NSString *awemeId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *userUniqueId;
@property (nonatomic, copy) NSString *secUid;
@end

@interface AWEAwemeModel : NSObject
@property (nonatomic, strong, readwrite) NSNumber *createTime;
@property (nonatomic, assign,readwrite) CGFloat videoDuration;
@property (nonatomic, strong) AWEVideoModel *video;
@property (nonatomic, strong) AWEMusicModel *music;
@property (nonatomic, strong) NSArray<AWEImageAlbumImageModel *> *albumImages;
@property (nonatomic, assign) NSInteger currentImageIndex;
@property (nonatomic, assign) NSInteger awemeType;
@property (nonatomic, strong) NSString *cityCode;
@property (nonatomic, strong) NSString *ipAttribution;
@property (nonatomic, strong) id currentAweme;
@property (nonatomic, copy) NSString *descriptionString;
@property (nonatomic, assign) BOOL isAds;
@property (nonatomic, assign) BOOL isLive;
@property (nonatomic, strong) NSString *shareURL;
@property (nonatomic, strong) id hotSpotLynxCardModel;
@property (nonatomic, copy) NSString *liveReason;
@property (nonatomic, strong) id shareRecExtra; // 推荐视频专有属性
@property (nonatomic, strong) NSArray<AWEAwemeTextExtraModel *> *textExtras;
@property (nonatomic, copy) NSString *itemTitle;
@property (nonatomic, copy) NSString *descriptionSimpleString;
@property (nonatomic, strong) NSString *itemID;

@property (nonatomic, strong) AWEAwemeStatisticsModel *statistics;
- (BOOL)isLive;
- (AWESearchAwemeExtraModel *)searchExtraModel;
@end

@interface AWELongPressPanelBaseViewModel : NSObject
@property (nonatomic, copy) NSString *describeString;
@property (nonatomic, assign) NSInteger enterMethod;
@property (nonatomic, assign) NSInteger actionType;
@property (nonatomic, assign) BOOL showIfNeed;
@property (nonatomic, copy) NSString *duxIconName;
@property (nonatomic, copy) void (^action)(void);
@property (nonatomic, strong) AWEAwemeModel *awemeModel;
- (void)setDuxIconName:(NSString *)iconName;
- (void)setDescribeString:(NSString *)descString;
- (void)setAction:(void (^)(void))action;
@end

@interface AWELongPressPanelViewGroupModel : NSObject
@property (nonatomic, assign) NSInteger groupType;
@property (nonatomic, strong) NSArray *groupArr;
@end

@interface AWELongPressPanelManager : NSObject
+ (instancetype)shareInstance;
- (void)dismissWithAnimation:(BOOL)animated completion:(void (^)(void))completion;
- (BOOL)shouldShowMordenLongPressPanel;
- (BOOL)showShareFriends;
@end

@interface AWENormalModeTabBarGeneralButton : UIButton
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
@property (nonatomic, strong) UIView *view;
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
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context;
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

@interface AWEPlayInteractionNewBaseController : UIView
@property (retain, nonatomic) AWEAwemeModel * model;
@end

@interface AWEPlayInteractionProgressController : AWEPlayInteractionNewBaseController
- (UIViewController *)findViewController:(UIViewController *)vc ofClass:(Class)targetClass;
@property (retain, nonatomic) id progressSlider;
- (NSString *)formatTimeFromSeconds:(CGFloat)seconds;
- (NSString *)convertSecondsToTimeString:(NSInteger)totalSeconds;
@end

@interface AWEAdAvatarView : UIView

@end

@interface AWENormalModeTabBar : UIView
@property (nonatomic, assign, readonly) UITabBarController *yy_viewController;
@end

@interface AWEPlayInteractionListenFeedView : UIView

@end

@interface AWEFeedLiveMarkView : UIView

@end

@interface AWEPlayInteractionTimestampElement : UIView
@property (nonatomic, strong) AWEAwemeModel *model;
@end

@interface AWEFeedTableViewController : UIViewController
@end

@interface AWEFeedTableView : UIView
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

@interface AWEFeedTemplateAnchorView : UIView
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
@property (nonatomic, strong) AWEAwemeModel *awemeModel;
@end

@interface AWEModernLongPressPanelTableViewController : UIViewController
@property (nonatomic, strong) AWEAwemeModel *awemeModel;
@end

@interface DYYYSettingViewController : UIViewController
@end

@interface AWEElementStackView : UIView
@property (nonatomic, copy) NSString *accessibilityLabel;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong) NSArray *subviews;
@property (nonatomic, assign) CGAffineTransform transform;
@end

@interface AWECommentImageModel : NSObject
@property (nonatomic, copy) NSString *originUrl;
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
@property (nonatomic, strong) UIView *leftLabelUI;
@property (nonatomic, strong) UIView *rightLabelUI;
@property (nonatomic) AWEPlayInteractionProgressController * progressSliderDelegate;
@end

@interface AWEFeedChannelObject : NSObject
@property (nonatomic, copy) NSString *channelID;
@property (nonatomic, copy) NSString *channelTitle;
@end

@interface AWEFeedChannelManager : NSObject
- (AWEFeedChannelObject *)getChannelWithChannelID:(NSString *)channelID;
@end

@interface AWEHPTopTabItemModel : NSObject
@property (nonatomic, copy) NSString *channelID;
@property (nonatomic, copy) NSString *channelTitle;
@end

@interface AWEPlayInteractionStrongifyShareContentView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEAntiAddictedNoticeBarView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEFeedAnchorContainerView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEIMMessageTabOptPushBannerView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEFeedStickerContainerView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEECommerceEntryView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWETemplateTagsCommonView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AFDSkylightCellBubble : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface LOTAnimationView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWENearbySkyLightCapsuleView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEPlayInteractionCoCreatorNewInfoView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AFDCancelMuteAwemeView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEPlayDanmakuInputContainView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEPlayInteractionRelatedVideoView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEFeedRelatedSearchTipView : UIView
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface AWEProfileMixCollectionViewCell : UIView
@end

@interface AWEProfileTaskCardStyleListCollectionViewCell : UIView
@end

// AWEVersionUpdateManager相关接口声明
@interface AWEVersionUpdateManager : NSObject
@property (nonatomic, strong) id networkModule;
@property (nonatomic, strong) id badgeModule;
@property (nonatomic, strong) id workflow;
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
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

//隐藏好友分享私信
@interface AFDNewFastReplyView @property (nonatomic, weak) UIView *superview;
@property (nonatomic) BOOL hidden;
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
- (void)setActions:(NSArray *)actions;
- (void)show;
@end

@interface AWEUserSheetAction : NSObject
+ (instancetype)actionWithTitle:(NSString *)title imgName:(NSString *)imgName handler:(id)handler;
+ (instancetype)actionWithTitle:(NSString *)title style:(NSUInteger)style imgName:(NSString *)imgName handler:(id)handler;
@end

@interface AWEFeedProgressSlider (CustomAdditions)
- (void)applyCustomProgressStyle;
@end

@interface AWEPlayInteractionDescriptionScrollView : UIScrollView
@end

@interface AWEUserNameLabel : UIView
@end

@interface AWEPlayInteractionDescriptionLabel : UILabel
@end
//关注直播
@interface AWEConcernSkylightCapsuleView : UIView
@end
//直播发现
@interface AWEFeedLiveTabRevisitControlView : UIView
@end
//直播 退出清屏、投屏按钮
@interface IESLiveButton : UIView
@end

//直播点歌
@interface IESLiveKTVSongIndicatorView : UIView
@end
//图片滑条
@interface AWEStoryProgressContainerView : UIView 
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
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

//直播间流量提醒弹窗
@interface AWELiveFlowAlertView : UIView
@end

//搜索视频底部评论视图
@interface AWECommentInputBackgroundView : UIView
@end

//聊天视频底部快速回复视图
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

//应用内推送容器
@interface AWEInnerNotificationWindow : UIWindow
- (void)setupBlurEffectForNotificationView;
- (void)applyBlurEffectToView:(UIView *)containerView;
- (void)setLabelsColorWhiteInView:(UIView *)view;
- (void)clearBackgroundRecursivelyInView:(UIView *)view;
@end

@interface AWEFakeProgressSliderView : UIView
- (void)applyCustomProgressStyle;
@end
