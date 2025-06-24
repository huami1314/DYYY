#import <Foundation/Foundation.h>

// 声明 DYYYABTestHook 类的接口
@interface DYYYABTestHook : NSObject

/**
 * 判断当前是否为覆写模式
 */
+ (BOOL)isPatchMode;

/**
 * 获取本地固定数据是否已加载的状态
 */
+ (BOOL)isFixedDataLoaded;

/**
 * 获取禁止下发配置的状态
 */
+ (BOOL)isABTestBlockEnabled;

/**
 * 设置禁止下发配置的状态
 */
+ (void)setABTestBlockEnabled:(BOOL)enabled;

/**
 * 清除本地加载的固定ABTest数据，为下次调用 ensureABTestDataLoaded 做准备
 */
+ (void)cleanFixedABTestData;

/**
 * 加载本地ABTest配置数据
 * 如果数据尚未加载，则执行加载逻辑
 */
+ (void)ensureABTestDataLoaded;

/**
 * 获取当前ABTest数据 (从 AWEABTestManager 获取)
 */
+ (NSDictionary *)getCurrentABTestData;

@end