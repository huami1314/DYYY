#import <Foundation/Foundation.h>

@interface CityManager : NSObject

@property (nonatomic, strong) NSDictionary *cityCodeMap;

+ (instancetype)sharedInstance;
- (NSString *)getCityNameWithCode:(NSString *)code;
- (NSString *)getProvinceNameWithCode:(NSString *)code;
- (void)loadCityData;
+ (void)fetchLocationWithGeonameId:(NSString *)geonameId completionHandler:(void (^)(NSDictionary *locationInfo, NSError *error))completionHandler;
@end 
