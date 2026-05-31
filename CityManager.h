#import <Foundation/Foundation.h>

@interface CityManager : NSObject

@property(nonatomic, strong) NSDictionary *cityCodeMap;
@property(nonatomic, strong) NSDictionary *countryCodeMap;

+ (instancetype)sharedInstance;
- (NSString *)getCityNameWithCode:(NSString *)code;
- (NSString *)getProvinceNameWithCode:(NSString *)code;
- (NSString *)getCountryNameWithCode:(NSString *)code;
- (void)loadCityData;
- (void)loadCountryData;
+ (void)fetchLocationWithGeonameId:(NSString *)geonameId completionHandler:(void (^)(NSDictionary *locationInfo, NSError *error))completionHandler;
@end
