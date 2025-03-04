#import "CityManager.h"
#import <Foundation/Foundation.h>

@implementation CityManager

+ (instancetype)sharedInstance {
    static CityManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CityManager alloc] init];
        [instance loadCityData];
    });
    return instance;
}

- (void)loadCityData {
    // 34个省级行政区
    self.cityCodeMap = @{
        // 23个省
        @"130000": @"河北",
        @"140000": @"山西",
        @"210000": @"辽宁",
        @"220000": @"吉林",
        @"230000": @"黑龙江",
        @"320000": @"江苏",
        @"330000": @"浙江",
        @"340000": @"安徽",
        @"350000": @"福建",
        @"360000": @"江西",
        @"370000": @"山东",
        @"410000": @"河南",
        @"420000": @"湖北",
        @"430000": @"湖南",
        @"440000": @"广东",
        @"460000": @"海南",
        @"510000": @"四川",
        @"520000": @"贵州",
        @"530000": @"云南",
        @"610000": @"陕西",
        @"620000": @"甘肃",
        @"630000": @"青海",
        @"710000": @"台湾(中国)",
        // 5个自治区
        @"150000": @"内蒙古",
        @"450000": @"广西",
        @"540000": @"西藏",
        @"640000": @"宁夏",
        @"650000": @"新疆",
        // 4个直辖市
        @"110000": @"北京",
        @"120000": @"天津",
        @"310000": @"上海",
        @"500000": @"重庆",
        // 2个特别行政区
        @"810000": @"香港(中国)",
        @"820000": @"澳门(中国)"
    };
}

- (NSString *)getCityNameWithCode:(NSString *)code {
    if (!code || code.length < 6) {
        return nil;
    }
    
    NSString *cityName = self.cityCodeMap[code];
    
    if (!cityName) {
        NSString *provinceCode = [code substringToIndex:2];
        provinceCode = [provinceCode stringByAppendingString:@"0000"];
        cityName = self.cityCodeMap[provinceCode];
    }
    
    return cityName ?: @"未知/海外";
}

@end 