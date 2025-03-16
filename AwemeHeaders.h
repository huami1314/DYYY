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

@interface AWEVideoModel : NSObject
@property (nonatomic, strong) URLModel *h264URL;
@property (nonatomic, strong) URLModel *coverURL;
@end

@interface AWEMusicModel : NSObject
@property (nonatomic, strong) URLModel *playURL;
@end

@interface AWEImageAlbumImageModel : NSObject
@property (nonatomic, strong) NSArray *urlList;
@end

@interface AWEAwemeModel : NSObject
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
@property (nonatomic, assign) BOOL isLive;
- (BOOL)isLive;
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
@end

void downloadMedia(NSURL *url, MediaType mediaType, void (^completion)(void));
void downloadAllImages(NSMutableArray *imageURLs);

@interface AWENormalModeTabBarGeneralButton : UIButton
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
@end

@interface AWEDanmakuContentLabel : UILabel
- (UIColor *)colorFromHexString:(NSString *)hexString baseColor:(UIColor *)baseColor;
@end

@interface AWELandscapeFeedEntryView : UIView
@end

@interface AWEPlayInteractionViewController : UIViewController
@property (nonatomic, strong) UIView *view;
- (void)performCommentAction;
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

@interface AWESettingSectionModel : NSObject
@property (nonatomic, copy) NSString *sectionHeaderTitle;
@property (nonatomic, assign) CGFloat sectionHeaderHeight;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, strong) NSArray *itemArray;
@end

@interface AWESettingItemModel : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *iconImageName;
@property (nonatomic, assign) NSInteger cellType;
@property (nonatomic, assign) NSInteger colorStyle;
@property (nonatomic, assign) BOOL isEnable;
@property (nonatomic, copy) void (^cellTappedBlock)(void);
@end

@interface AWESettingsViewModel : NSObject
@property (nonatomic, weak) UIViewController *controllerDelegate;
@property (nonatomic, copy) NSString *traceEnterFrom;
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
@end

@interface AWEIMStickerModel : NSObject
- (AWEURLModel *)staticURLModel;
@end

@interface AWEURLModel : NSObject
- (NSArray *)originURLList;
@end

@interface _TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement : NSObject
- (AWECommentLongPressPanelContext *)commentPageContext;
@end




@interface AWEFeedProgressSlider : UIView
@property (nonatomic, strong) UIView *leftLabelUI;
@property (nonatomic, strong) UIView *rightLabelUI;
@property (nonatomic) AWEPlayInteractionProgressController * progressSliderDelegate;
@end