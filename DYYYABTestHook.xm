#import "DYYYABTestHook.h"
#import "DYYYConstants.h"
#import "DYYYUtils.h"
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

static BOOL s_abTestBlockEnabled = NO;
static BOOL s_isApplyingFixedData = NO;
static NSDictionary *s_localABTestData = nil;
static NSString *s_fileMode = nil;

// 默认远程配置地址常量
static NSString *const kDefaultRemoteConfigURL = DYYY_DEFAULT_ABTEST_URL;

static dispatch_once_t s_loadOnceToken;
static dispatch_queue_t s_abTestHookQueue;
static dispatch_once_t s_queueOnceToken;
static void *s_queueSpecificKey = &s_queueSpecificKey;

static dispatch_queue_t DYYYABTestQueue() {
    dispatch_once(&s_queueOnceToken, ^{
      if (!s_abTestHookQueue) {
          s_abTestHookQueue = dispatch_queue_create("com.dyyy.abtesthook.queue", DISPATCH_QUEUE_SERIAL);
          // Mark the queue with specific key for reentrancy checks
          dispatch_queue_set_specific(s_abTestHookQueue, s_queueSpecificKey, (void *)1, NULL);
      }
    });
    return s_abTestHookQueue;
}

static void DYYYQueueSync(dispatch_block_t block) {
    dispatch_queue_t queue = DYYYABTestQueue();
    if (dispatch_get_specific(s_queueSpecificKey)) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}

@implementation DYYYABTestHook

/**
 * 判断当前是否为覆写模式
 * 通过DYYYABTestModeString判断，返回YES表示覆写模式，NO表示替换模式
 * 转换为类方法
 */
+ (BOOL)isPatchMode {
    NSString *savedMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYABTestModeString"];
    if (savedMode) {
        if ([savedMode isEqualToString:DYYY_REMOTE_MODE_STRING] || [[savedMode lowercaseString] isEqualToString:@"remote"]) {
            if (s_fileMode) {
                return ![[s_fileMode lowercaseString] isEqualToString:@"DYYY_MODE_REPLACE"];
            }
            return YES;
        }
        if ([savedMode isEqualToString:@"替换模式：忽略原配置，使用新数据"] || [[savedMode lowercaseString] isEqualToString:@"DYYY_MODE_REPLACE"]) {
            return NO;
        }
        return YES;
    }
    if (s_fileMode) {
        return ![[s_fileMode lowercaseString] isEqualToString:@"DYYY_MODE_REPLACE"];
    }
    return YES;
}

/**
 * 获取本地文件是否已加载的状态
 * 使用 dispatch_sync 在队列上同步读取 s_localABTestData 的状态
 */
+ (BOOL)isLocalConfigLoaded {
    __block BOOL loaded = NO;
    DYYYQueueSync(^{
      loaded = (s_localABTestData != nil);
    });
    return loaded;
}

/**
 * 当前是否处于远程模式
 */
+ (BOOL)isRemoteMode {
    NSString *savedMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYABTestModeString"];
    if (savedMode) {
        return [savedMode isEqualToString:DYYY_REMOTE_MODE_STRING] || [[savedMode lowercaseString] isEqualToString:@"remote"];
    }
    return NO;
}

/**
 * 获取禁止下发配置的状态
 * 使用 dispatch_sync 在队列上同步读取状态
 */
+ (BOOL)isABTestBlockEnabled {
    __block BOOL enabled = NO;
    DYYYQueueSync(^{
      enabled = s_abTestBlockEnabled;
    });
    return enabled;
}

/**
 * 设置禁止下发配置的状态
 * 使用 dispatch_async 在队列上异步设置状态
 */
+ (void)setABTestBlockEnabled:(BOOL)enabled {
    dispatch_async(DYYYABTestQueue(), ^{
      s_abTestBlockEnabled = enabled;
    });
}

/**
 * 清除本地加载的ABTest数据，为下次调用 loadLocalABTestConfig 做准备
 * 使用 dispatch_async 在队列上异步清除数据
 */
+ (void)cleanLocalABTestData {
    dispatch_async(DYYYABTestQueue(), ^{
      s_localABTestData = nil;
      s_loadOnceToken = 0;
      NSLog(@"[DYYY] 本地ABTest配置已清除");
    });
}

/**
 * 加载本地ABTest配置文件
 * 只加载文件和处理数据，不负责应用
 * 使用 dispatch_once 确保只加载一次
 * 整个加载过程在队列上异步执行
 */
+ (void)loadLocalABTestConfig {
    dispatch_async(DYYYABTestQueue(), ^{
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
                id modeValue = loadedData[@"mode"];
                s_fileMode = nil;
                if ([modeValue isKindOfClass:[NSString class]]) {
                    s_fileMode = [modeValue lowercaseString];
                }
                NSDictionary *actualData = loadedData[@"data"];
                if (!actualData) {
                    NSMutableDictionary *tmp = [loadedData mutableCopy];
                    [tmp removeObjectForKey:@"mode"];
                    actualData = [tmp copy];
                }
                s_localABTestData = [actualData copy];
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
      });
    });
}

/**
 * 应用本地ABTest配置数据 (负责根据模式处理并应用到 Manager)
 * 包含是否应该应用的条件判断
 * 整个应用过程在队列上异步执行
 */
+ (void)applyFixedABTestData {
    dispatch_async(DYYYABTestQueue(), ^{
      if (!s_abTestBlockEnabled || !s_localABTestData) {
          NSLog(@"[DYYY] 不满足应用本地配置的条件 (禁止下发=%@, 数据是否为空=%@)", s_abTestBlockEnabled ? @"开启" : @"关闭", s_localABTestData ? @"否" : @"是");
          s_isApplyingFixedData = NO; // 确保标志关闭
          return;
      }

      AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
      if (!manager) {
          NSLog(@"[DYYY] 无法应用本地配置：AWEABTestManager 实例不可用");
          s_isApplyingFixedData = NO; // 确保标志关闭
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

      // 设置状态标志，表明接下来对 setAbTestData: 的调用是来自我们 Hook 的应用逻辑
      s_isApplyingFixedData = YES;

      // 应用数据到 Manager
      // 这里的调用发生在队列上，Hook 内部的检查也会在队列上同步进行，是安全的。
      [manager setAbTestData:dataToApply];

      // 重置状态标志
      s_isApplyingFixedData = NO;

      NSLog(@"[DYYY] ABTest本地配置已应用");
    });
}

/**
 * 获取当前ABTest数据
 */
+ (NSDictionary *)getCurrentABTestData {
    AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
    return manager ? [manager abTestData] : nil;
}

/**
 * 从网络检查并下载最新配置
 */
+ (void)checkForRemoteConfigUpdate:(BOOL)notify {
    dispatch_async(DYYYABTestQueue(), ^{
      NSString *urlString = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYRemoteConfigURL"];
      if (urlString.length == 0) {
          urlString = kDefaultRemoteConfigURL;
      }
      NSURL *url = [NSURL URLWithString:urlString];
      if (!url) {
          if (notify) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [DYYYUtils showToast:@"配置更新失败"];
              });
          }
          return;
      }
      NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                 BOOL updated = NO;
                                                                 if (data && !error) {
                                                                     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                                                     NSString *documentsDirectory = [paths firstObject];
                                                                     NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
                                                                     NSString *jsonFilePath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];
                                                                     [[NSFileManager defaultManager] createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
                                                                     NSData *existingData = [NSData dataWithContentsOfFile:jsonFilePath];
                                                                     if (!existingData || ![existingData isEqualToData:data]) {
                                                                         [data writeToFile:jsonFilePath atomically:YES];
                                                                         updated = YES;
                                                                     }
                                                                     if ([DYYYABTestHook isRemoteMode]) {
                                                                         [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DYYY_REMOTE_CONFIG_FLAG_KEY];
                                                                         [[NSUserDefaults standardUserDefaults] synchronize];
                                                                         [[NSNotificationCenter defaultCenter] postNotificationName:DYYY_REMOTE_CONFIG_CHANGED_NOTIFICATION object:nil];
                                                                     }
                                                                 }
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                   if (error || !data) {
                                                                       if (notify) {
                                                                           [DYYYUtils showToast:@"配置更新失败"];
                                                                       }
                                                                   } else if (updated) {
                                                                       if (notify) {
                                                                           [DYYYUtils showToast:@"配置已更新"];
                                                                       }
                                                                       [DYYYABTestHook cleanLocalABTestData];
                                                                       [DYYYABTestHook loadLocalABTestConfig];
                                                                       [DYYYABTestHook applyFixedABTestData];
                                                                   } else {
                                                                       if (notify) {
                                                                           [DYYYUtils showToast:@"已是最新配置"];
                                                                       }
                                                                   }
                                                                 });
                                                               }];
      [task resume];
    });
}

@end

%hook AWEABTestManager

/**
 * Hook: 设置ABTest数据
 * 阻止在禁止下发模式下更新数据，除非当前正在应用本地配置
 * 使用 dispatch_sync 在队列上同步检查状态标志
 */
- (void)setAbTestData:(id)data {
    __block BOOL shouldBlock = NO;
    DYYYQueueSync(^{
      // 在队列上安全地检查禁止下发标志 和 正在应用本地数据的标志
      // 如果禁止下发开启 并且 不是正在应用本地数据，则阻止
      if (s_abTestBlockEnabled && !s_isApplyingFixedData) {
          shouldBlock = YES;
      }
    });

    if (shouldBlock) {
        NSLog(@"[DYYY] 阻止ABTest数据更新 (启用了禁止下发配置且非本地应用)");
        return;
    }
    %orig;
}

/**
 * Hook: 增量更新ABTest数据
 * 在禁止下发模式下阻止增量更新
 * 使用 dispatch_sync 在队列上同步检查状态
 */
- (void)incrementalUpdateData:(id)data unchangedKeyList:(id)keyList {
    __block BOOL shouldBlock = NO;
    DYYYQueueSync(^{
      shouldBlock = s_abTestBlockEnabled;
    });

    if (shouldBlock) {
        NSLog(@"[DYYY] 阻止增量更新ABTest数据 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

/**
 * Hook: 从网络获取配置(带重试)
 * 在禁止下发模式下拦截网络请求，并立即返回空结果
 * 使用 dispatch_sync 在队列上同步检查状态
 */
- (void)fetchConfigurationWithRetry:(BOOL)retry completion:(id)completion {
    __block BOOL shouldBlock = NO;
    DYYYQueueSync(^{
      shouldBlock = s_abTestBlockEnabled;
    });

    if (shouldBlock) {
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
 * 使用 dispatch_sync 在队列上同步检查状态
 */
- (void)fetchConfiguration:(id)arg1 {
    __block BOOL shouldBlock = NO;
    DYYYQueueSync(^{
      shouldBlock = s_abTestBlockEnabled;
    });

    if (shouldBlock) {
        NSLog(@"[DYYY] 阻止从网络获取ABTest配置 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

/**
 * Hook: 重写ABTest数据
 * 在禁止下发模式下阻止覆盖数据
 * 使用 dispatch_sync 在队列上同步检查状态
 */
- (void)overrideABTestData:(id)data needCleanCache:(BOOL)cleanCache {
    __block BOOL shouldBlock = NO;
    DYYYQueueSync(^{
      shouldBlock = s_abTestBlockEnabled;
    });

    if (shouldBlock) {
        NSLog(@"[DYYY] 阻止重写ABTest数据 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

/**
 * Hook: 保存ABTest数据
 * 在禁止下发模式下阻止保存
 * 使用 dispatch_sync 在队列上同步检查状态
 */
- (void)_saveABTestData:(id)data {
    __block BOOL shouldBlock = NO;
    DYYYQueueSync(^{
      shouldBlock = s_abTestBlockEnabled;
    });

    if (shouldBlock) {
        NSLog(@"[DYYY] 阻止保存ABTest数据 (启用了禁止下发配置)");
        return;
    }
    %orig;
}

%end

%ctor {
    // 预初始化队列以避免早期访问为 NULL
    DYYYABTestQueue();

    %init;

    // 在队列上异步读取初始状态并加载/应用配置
    dispatch_async(DYYYABTestQueue(), ^{
      s_abTestBlockEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYABTestBlockEnabled"];

      NSString *currentMode = nil;
      if ([DYYYABTestHook isRemoteMode]) {
          currentMode = [DYYYABTestHook isPatchMode] ? @"远程模式(覆写)" : @"远程模式(替换)";
      } else {
          currentMode = [DYYYABTestHook isPatchMode] ? @"覆写模式" : @"替换模式";
      }

      NSLog(@"[DYYY] ABTest Hook已启动: 禁止下发=%@, 当前模式=%@", s_abTestBlockEnabled ? @"开启" : @"关闭", currentMode);

      [DYYYABTestHook loadLocalABTestConfig];
      [DYYYABTestHook applyFixedABTestData];
      if ([DYYYABTestHook isRemoteMode]) {
          [DYYYABTestHook checkForRemoteConfigUpdate:NO];
      }
    });
}
