#import "DYYYABTestHook.h"
#import <objc/runtime.h>

// 声明ABTestManager接口
@interface AWEABTestManager : NSObject
@property(retain, nonatomic) NSDictionary *abTestData;
@property(retain, nonatomic) NSMutableDictionary *consistentABTestDic;
@property(copy, nonatomic) NSDictionary *performanceReversalDic;
- (void)setAbTestData:(id)arg1;
- (void)_saveABTestData:(id)arg1;
- (id)abTestData;
+ (id)sharedManager;
@end

// 全局变量实现
BOOL abTestBlockEnabled = NO;
NSDictionary *gFixedABTestData = nil;
dispatch_once_t onceToken;
BOOL gDataLoaded = NO;
static NSDate *lastLoadAttemptTime = nil;
static const NSTimeInterval kMinLoadInterval = 60.0;

// 从指定JSON文件加载ABTest数据，仅当需要时加载
void ensureABTestDataLoaded(void) {
    if (gDataLoaded) return;
    
    dispatch_once(&onceToken, ^{
        // 获取Documents目录路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        
        // 修改为DYYY子文件夹下的路径
        NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
        NSString *jsonFilePath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];
        
        // 确保DYYY目录存在
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:dyyyFolderPath]) {
            NSError *error = nil;
            [fileManager createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"[DYYY] 创建DYYY目录失败: %@", error.localizedDescription);
            }
        }
        
        NSError *error = nil;
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonFilePath options:0 error:&error];
        
        if (jsonData) {
            NSDictionary *loadedData = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                                      options:0 
                                                                        error:&error];
            if (loadedData && !error) {
                // 成功加载数据，保存到全局变量
                gFixedABTestData = [loadedData copy];
                gDataLoaded = YES;
                return;
            }
        }
        
        // 如果加载失败，使用空字典
        gFixedABTestData = @{};
        gDataLoaded = YES;
    });
}

// 优化防止频繁加载
NSDictionary* loadFixedABTestData(void) {
    // 检查是否已加载数据
    if (gDataLoaded) {
        return gFixedABTestData;
    }
    
    // 限制加载频率，避免短时间内多次尝试解析大型JSON
    NSDate *now = [NSDate date];
    if (lastLoadAttemptTime && [now timeIntervalSinceDate:lastLoadAttemptTime] < kMinLoadInterval) {
        return gFixedABTestData;
    }
    
    // 更新最后尝试时间
    lastLoadAttemptTime = now;
    
    // 调用已有的加载函数
    ensureABTestDataLoaded();
    return gFixedABTestData;
}

// 替代空数据函数，返回固定数据 - 优化版本
static NSDictionary *fixedABTestData(void) {
    // 如果禁用了热更新拦截，返回nil让原始实现处理
    if (!abTestBlockEnabled) {
        return nil;
    }
    
    // 延迟加载 - 仅当需要时才实际解析JSON
    if (!gDataLoaded) {
        ensureABTestDataLoaded();
    }
    
    return gFixedABTestData;
}

// 获取当前ABTest数据 - 优化版本
NSDictionary *getCurrentABTestData(void) {
    // 如果启用了拦截且已加载固定数据，优先返回固定数据
    if (abTestBlockEnabled) {
        if (!gDataLoaded) {
            ensureABTestDataLoaded();
        }
        return gFixedABTestData;
    }
    
    // 否则从Manager获取当前数据
    AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
    if (!manager) {
        return nil;
    }
    
    NSDictionary *currentData = [manager abTestData];
    return currentData;
}

// 添加缓存策略
static NSMutableDictionary *gCaseCache = nil;

// Hook AWEABTestManager类
%hook AWEABTestManager

// 拦截获取 ABTest 数据的方法
- (id)abTestData {
    if (!abTestBlockEnabled) {
        return %orig;
    }
    
    // 延迟加载数据，仅当需要时才加载
    if (!gDataLoaded) {
        ensureABTestDataLoaded();
    }
    
    return gFixedABTestData ?: %orig;
}

// 拦截设置 ABTest 数据的方法
- (void)setAbTestData:(id)arg1 {
    if (abTestBlockEnabled) {
        return; // 禁用热更新时不执行
    }
    %orig;
}

// 拦截增量数据更新
- (void)incrementalUpdateData:(id)arg1 unchangedKeyList:(id)arg2 {
    if (abTestBlockEnabled) {
        return;
    }
    %orig;
}

// 拦截网络获取配置方法
- (void)fetchConfigurationWithRetry:(BOOL)arg1 completion:(id)arg2 {
    if (abTestBlockEnabled) {
        // 如果有完成回调，调用它但不更新数据
        if (arg2 && [arg2 isKindOfClass:%c(NSBlock)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ((void (^)(id))arg2)(nil);
            });
        }
        return;
    }
    %orig;
}

// 拦截另一个配置方法
- (void)fetchConfiguration:(id)arg1 {
    if (abTestBlockEnabled) {
        return;
    }
    %orig;
}

// 拦截重写ABTest数据的方法
- (void)overrideABTestData:(id)arg1 needCleanCache:(BOOL)arg2 {
    if (abTestBlockEnabled) {
        return;
    }
    %orig;
}

%end

%ctor {
    // 初始化时加载设置
    %init;
    abTestBlockEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"ABTestBlockEnabled"];
}