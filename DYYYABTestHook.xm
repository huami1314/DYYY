#import "DYYYABTestHook.h"
#import <objc/runtime.h>

@interface AWEABTestManager : NSObject
@property(retain, nonatomic) NSMutableDictionary *consistentABTestDic;
@property(copy, nonatomic) NSDictionary *abTestData;
@property(copy, nonatomic) NSDictionary *performanceReversalDic;
@property(nonatomic) BOOL performanceReversalEnabled;
@property(nonatomic) BOOL handledNetFirstBackNotification;
@property(nonatomic) BOOL lastUpdateByIncrement;
@property(nonatomic) BOOL shouldPrintLog;
@property(nonatomic) BOOL localABSettingEnabled;
- (void)fetchConfiguration:(id)arg1;
- (void)fetchConfigurationWithRetry:(BOOL)arg1 completion:(id)arg2;
- (void)incrementalUpdateData:(id)arg1 unchangedKeyList:(id)arg2;
- (void)overrideABTestData:(id)arg1 needCleanCache:(BOOL)arg2;
- (void)setAbTestData:(id)arg1;
- (void)_saveABTestData:(id)arg1;
- (id)getValueOfConsistentABTestWithKey:(id)arg1;
+ (id)sharedManager;
@end

static BOOL s_dataLoaded = NO;
static BOOL s_abTestBlockEnabled = NO;
static NSDictionary *s_localABTestData = nil;
static NSDictionary *s_appliedFixedABTestData = nil;
static dispatch_once_t s_loadOnceToken;

@implementation DYYYABTestHook

/**
 * 判断当前是否为覆写模式
 * 通过DYYYABTestModeString判断，返回YES表示覆写模式，NO表示替换模式
 * 转换为类方法
 */
+ (BOOL)isPatchMode {
    NSString *savedMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYABTestModeString"];
    return ![savedMode isEqualToString:@"替换模式：忽略原配置，写入新数据"];
}

/**
 * 获取本地文件是否已加载的状态
 * 转换为类方法
 */
+ (BOOL)isLocalConfigLoaded {
    return s_dataLoaded;
}

/**
 * 获取禁止下发配置的状态
 * 新增类方法
 */
+ (BOOL)isABTestBlockEnabled {
    return s_abTestBlockEnabled;
}

/**
 * 设置禁止下发配置的状态
 * 转换为类方法
 */
+ (void)setABTestBlockEnabled:(BOOL)enabled {
    s_abTestBlockEnabled = enabled;
}

/**
 * 清除本地加载的ABTest数据，为下次调用 loadLocalABTestConfig 做准备
 * 新增类方法
 */
+ (void)cleanLocalABTestData {
    s_appliedFixedABTestData = nil;
    s_localABTestData = nil;
    s_dataLoaded = NO;
    s_loadOnceToken = 0;
    NSLog(@"[DYYY] 本地ABTest配置已清除");
}

/**
 * 加载本地ABTest配置文件
 * 只加载文件和处理数据，不负责应用
 * 使用 dispatch_once 确保只加载一次
 * 转换为类方法
 */
+ (void)loadLocalABTestConfig {
    dispatch_once(&s_loadOnceToken, ^{
        // 获取存储路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
        NSString *jsonFilePath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];

        // 确保目录存在
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:dyyyFolderPath]) {
            NSError *error = nil;
            [fileManager createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"[DYYY] 创建DYYY目录失败: %@", error.localizedDescription);
            }
        }

        // 读取本地配置文件
        NSError *error = nil;
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonFilePath options:0 error:&error];

        if (jsonData) {
            NSDictionary *loadedData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            if (loadedData && !error) {
                s_localABTestData = [loadedData copy];
                s_dataLoaded = YES;
                NSLog(@"[DYYY] ABTest本地配置已从文件加载成功");
                return;
            } else {
                NSLog(@"[DYYY] ABTest本地配置解析失败: %@", error.localizedDescription);
            }
        } else {
            NSLog(@"[DYYY] ABTest本地配置文件不存在或无法读取");
        }
        
        // 加载失败时的处理
        s_localABTestData = nil;
        s_dataLoaded = NO;
    });
}

/**
 * 应用本地ABTest配置数据 (负责根据模式处理并应用到 Manager)
 * 包含是否应该应用的条件判断
 * 新增类方法
 */
+ (void)applyFixedABTestData {
    if (!s_abTestBlockEnabled || !s_dataLoaded) {
        NSLog(@"[DYYY] 不满足应用本地配置的条件 (禁止下发=%@, 数据加载=%@, 数据是否为空=%@)",
            s_abTestBlockEnabled ? @"开启" : @"关闭",
            s_dataLoaded ? @"成功" : @"失败",
            s_localABTestData ? @"否" : @"是");
        s_appliedFixedABTestData = nil;
        return;
    }

    AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
    if (!manager) {
        NSLog(@"[DYYY] 无法应用本地配置：AWEABTestManager 实例不可用");
        s_appliedFixedABTestData = nil;
        return;
    }

    BOOL usingPatchMode = [self isPatchMode];
    NSDictionary *dataToApply = nil;

    if (usingPatchMode) {
        // 覆写模式：本地配置合并现有配置
        NSMutableDictionary *mergedData = [NSMutableDictionary dictionaryWithDictionary:[manager abTestData] ?: @{}];
        [mergedData addEntriesFromDictionary:s_localABTestData];
        dataToApply = [mergedData copy];
    } else {
        // 替换模式：直接使用本地配置
        dataToApply = [s_localABTestData copy];
    }

    // 应用数据到 Manager
    [manager setAbTestData:dataToApply];
    // 记录下这个被应用的数据实例，供 Hook 中判断使用
    s_appliedFixedABTestData = dataToApply;

    NSLog(@"[DYYY] ABTest本地配置已应用");
}

/**
 * 获取当前ABTest数据
 * 转换为类方法
 */
+ (NSDictionary *)getCurrentABTestData {
    AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
    return manager ? [manager abTestData] : nil;
}

@end

%hook AWEABTestManager

/**
 * Hook: 设置ABTest数据
 * 阻止在禁止下发模式下更新数据，除非数据来自本地配置
 */
- (void)setAbTestData:(id)data {
    if (s_abTestBlockEnabled && data != s_appliedFixedABTestData) {
        NSLog(@"[DYYY] 阻止ABTest数据更新 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

/**
 * Hook: 增量更新ABTest数据
 * 在禁止下发模式下阻止增量更新
 */
- (void)incrementalUpdateData:(id)data unchangedKeyList:(id)keyList {
    if (s_abTestBlockEnabled) {
        NSLog(@"[DYYY] 阻止增量更新ABTest数据 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

/**
 * Hook: 从网络获取配置(带重试)
 * 在禁止下发模式下拦截网络请求，并立即返回空结果
 */
- (void)fetchConfigurationWithRetry:(BOOL)retry completion:(id)completion {
    if (s_abTestBlockEnabled) {
        NSLog(@"[DYYY] 阻止从网络获取ABTest配置 (启用了禁止下发配置)");
        if (completion && [completion isKindOfClass:%c(NSBlock)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ((void (^)(id))completion)(nil);
            });
        }
        return;
    }
    %orig;
}

/**
 * Hook: 从网络获取配置
 * 在禁止下发模式下阻止网络请求
 */
- (void)fetchConfiguration:(id)arg1 {
    if (s_abTestBlockEnabled) {
        NSLog(@"[DYYY] 阻止从网络获取ABTest配置 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

/**
 * Hook: 重写ABTest数据
 * 在禁止下发模式下阻止覆盖数据
 */
- (void)overrideABTestData:(id)data needCleanCache:(BOOL)cleanCache {
    if (s_abTestBlockEnabled) {
        NSLog(@"[DYYY] 阻止重写ABTest数据 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

/**
 * Hook: 保存ABTest数据
 * 在禁止下发模式下阻止保存
 */
- (void)_saveABTestData:(id)data {
    if (s_abTestBlockEnabled) {
        NSLog(@"[DYYY] 阻止保存ABTest数据 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

%end

%ctor {
    %init;
    s_abTestBlockEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYABTestBlockEnabled"];
    
    NSString *currentMode = [DYYYABTestHook isPatchMode] ? @"覆写模式" : @"替换模式";
    
    NSLog(@"[DYYY] ABTest Hook已启动: 禁止下发=%@, 当前模式=%@", 
          s_abTestBlockEnabled ? @"开启" : @"关闭",
          currentMode);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [DYYYABTestHook loadLocalABTestConfig];
        [DYYYABTestHook applyFixedABTestData];
    });
}