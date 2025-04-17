#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 城市选择器代理协议
@protocol CitySelectorDelegate <NSObject>
@optional
- (void)citySelectorDidSelect:(NSString *)provinceCode provinceName:(NSString *)provinceName 
                     cityCode:(NSString *)cityCode cityName:(NSString *)cityName 
                 districtCode:(NSString *)districtCode districtName:(NSString *)districtName;
@end

@interface CityManager : NSObject

+ (instancetype)sharedInstance;

// 数据获取方法
- (NSString *)getProvinceNameWithCode:(NSString *)provinceCode;
- (NSString *)getCityNameWithCode:(NSString *)cityCode;
- (NSDictionary *)getDistrictsInCity:(NSString *)parentCode;
- (NSArray *)getStreetsInDistrict:(NSString *)districtCode;
- (NSDictionary<NSString *, NSString *> *)getAllProvinces;
- (NSDictionary<NSString *, NSString *> *)getCitiesInProvince:(NSString *)provinceCode;
- (NSString *)getDistrictNameWithCode:(NSString *)districtCode;

// 城市选择器方法
- (void)showCitySelectorInViewController:(UIViewController *)parentVC delegate:(id<CitySelectorDelegate>)delegate;
- (void)showCitySelectorInViewController:(UIViewController *)parentVC delegate:(id<CitySelectorDelegate>)delegate initialSelectedCode:(NSString *)areaCode;
- (void)dismissCitySelector;

@end
