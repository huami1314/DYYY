#import <Foundation/Foundation.h>

@interface CityManager : NSObject

@property (nonatomic, strong) NSDictionary *cityCodeMap;

+ (instancetype)sharedInstance;
- (NSString *)getCityNameWithCode:(NSString *)code;
- (NSString *)getprovinceNameWithCode:(NSString *)code;
- (void)loadCityData;

@end 
