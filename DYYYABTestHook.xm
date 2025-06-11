#import "DYYYABTestHook.h"
#import <objc/runtime.h>

@interface AWEABTestManager : NSObject
@property(retain, nonatomic) NSDictionary *abTestData;
@property(retain, nonatomic) NSMutableDictionary *consistentABTestDic;
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

BOOL abTestBlockEnabled = NO;
NSDictionary *gFixedABTestData = nil;
dispatch_once_t onceToken;
BOOL gDataLoaded = NO;

static NSDate *lastLoadAttemptTime = nil;
static const NSTimeInterval kMinLoadInterval = 60.0;

/**
 * 判断当前是否为覆写模式
 * 通过DYYYABTestModeString判断，返回YES表示覆写模式，NO表示替换模式
 */
BOOL isPatchMode(void) {
    NSString *savedMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYABTestModeString"];
    return [savedMode isEqualToString:@"覆写模式：保留原设置，覆盖同名项"];
}

/**
 * 加载本地ABTest配置数据
 * 根据不同模式（覆写/替换）处理配置数据
 */
void ensureABTestDataLoaded(void) {
    dispatch_once(&onceToken, ^{
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
                // 成功加载数据，根据应用方式处理
                AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
                BOOL usingPatchMode = isPatchMode();
                
                if (manager && usingPatchMode) {
                    // 覆写模式：合并现有配置和本地配置
                    NSDictionary *currentABTestData = [manager abTestData];
                    NSMutableDictionary *mergedData = [NSMutableDictionary dictionaryWithDictionary:currentABTestData ?: @{}];
                    [mergedData addEntriesFromDictionary:loadedData];
                    gFixedABTestData = [mergedData copy];
                    NSLog(@"[DYYY] ABTest本地配置已加载(覆写模式)");
                } else {
                    // 替换模式：直接使用本地配置
                    gFixedABTestData = [loadedData copy];
                    NSLog(@"[DYYY] ABTest本地配置已加载(替换模式)");
                }
                gDataLoaded = YES;
                return;
            } else {
                NSLog(@"[DYYY] ABTest本地配置解析失败: %@", error.localizedDescription);
            }
        } else {
            NSLog(@"[DYYY] ABTest本地配置文件不存在或无法读取");
        }
        
        // 加载失败时的处理
        gFixedABTestData = nil;
        gDataLoaded = NO;
    });
}

/**
 * 获取当前ABTest数据
 */
NSDictionary *getCurrentABTestData(void) {
    ensureABTestDataLoaded();
    
    AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
    return manager ? [manager abTestData] : nil;
}

%hook AWEABTestManager

/**
 * Hook: 设置ABTest数据
 * 阻止在禁止下发模式下更新数据，除非数据来自本地配置
 */
- (void)setAbTestData:(id)data {
    if (abTestBlockEnabled && data != gFixedABTestData) {
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
    if (abTestBlockEnabled) {
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
    if (abTestBlockEnabled) {
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
    if (abTestBlockEnabled) {
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
    if (abTestBlockEnabled) {
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
    if (abTestBlockEnabled) {
        NSLog(@"[DYYY] 阻止保存ABTest数据 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

%end

%ctor {
    %init;
    abTestBlockEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYABTestBlockEnabled"];
    
    NSString *currentMode = isPatchMode() ? @"覆写模式" : @"替换模式";
    
    NSLog(@"[DYYY] ABTest Hook已启动: 禁止下发=%@, 当前模式=%@", 
          abTestBlockEnabled ? @"开启" : @"关闭", 
          currentMode);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
        ensureABTestDataLoaded();
        
        if (manager && gDataLoaded && abTestBlockEnabled) {
            [manager setAbTestData:gFixedABTestData];
        }
    });
}