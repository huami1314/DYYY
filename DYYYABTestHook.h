#import <Foundation/Foundation.h>

// 声明 DYYYABTestHook 类的接口
@interface DYYYABTestHook : NSObject

/** 判断当前是否为覆写模式 */
+ (BOOL)isPatchMode;

/** 获取本地文件是否已加载的状态 */
+ (BOOL)isLocalConfigLoaded;

/** 获取禁止下发配置的状态 */
+ (BOOL)isABTestBlockEnabled;

/** 设置禁止下发配置的状态 */
+ (void)setABTestBlockEnabled:(BOOL)enabled;

/** 清除本地加载的ABTest数据，为下次调用 loadLocalABTestConfig 做准备 */
+ (void)cleanLocalABTestData;

/** 加载本地ABTest配置文件 */
+ (void)loadLocalABTestConfig;

/** 应用本地ABTest配置数据 (负责根据模式处理并应用到 Manager) */
+ (void)applyFixedABTestData;

/** 获取当前ABTest数据 (从 AWEABTestManager 获取) */
+ (NSDictionary *)getCurrentABTestData;

/** 当前是否处于远程模式 */
+ (BOOL)isRemoteMode;

/**
 * 从网络检查并下载最新配置
 * @param notify 是否在完成后显示提示
 */
+ (void)checkForRemoteConfigUpdate:(BOOL)notify;

@end
