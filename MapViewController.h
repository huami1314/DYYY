#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol MapViewControllerDelegate <NSObject>
- (void)didSelectLocationWithLatitude:(double)latitude longitude:(double)longitude;
@end

@interface MapViewController : UIViewController
@property (nonatomic, weak) id<MapViewControllerDelegate> delegate;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UISearchBar *searchBar;
@end