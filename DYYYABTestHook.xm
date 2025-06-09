#import "DYYYABTestHook.h"
#import <objc/runtime.h>

@interface AWEABTestManager : NSObject
@property(retain, nonatomic) NSDictionary *abTestData;
@property(retain, nonatomic) NSMutableDictionary *consistentABTestDic;
@property(copy, nonatomic) NSDictionary *performanceReversalDic;
- (void)fetchConfiguration:(id)arg1;
- (void)fetchConfigurationWithRetry:(BOOL)arg1 completion:(id)arg2;
- (void)incrementalUpdateData:(id)arg1 unchangedKeyList:(id)arg2;
- (void)overrideABTestData:(id)arg1 needCleanCache:(BOOL)arg2;
- (void)setAbTestData:(id)arg1;
- (void)_saveABTestData:(id)arg1;
+ (id)sharedManager;
@end

BOOL abTestBlockEnabled = NO;
BOOL abTestPatchEnabled = NO;
NSDictionary *gFixedABTestData = nil;
dispatch_once_t onceToken;
BOOL gDataLoaded = NO;

static NSDate *lastLoadAttemptTime = nil;
static const NSTimeInterval kMinLoadInterval = 60.0;

void ensureABTestDataLoaded(void) {
	dispatch_once(&onceToken, ^{
	  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	  NSString *documentsDirectory = [paths firstObject];

	  NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
	  NSString *jsonFilePath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];

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
		  NSDictionary *loadedData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
		  if (loadedData && !error) {
			  // 成功加载数据，判断应用方式
			  AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
			  if (manager && abTestPatchEnabled) {
				  // 覆写模式：使用合并的mergedData
				  NSDictionary *currentABTestData = [manager abTestData];
				  NSMutableDictionary *mergedData = [NSMutableDictionary dictionaryWithDictionary:currentABTestData ?: @{}];
				  [mergedData addEntriesFromDictionary:loadedData];
				  gFixedABTestData = [mergedData copy];
			  } else {
				  // 替换模式：使用读取的loadedData
				  gFixedABTestData = [loadedData copy];
			  }
			  gDataLoaded = YES;
			  return;
		  }
	  }
	  gFixedABTestData = nil;
	  gDataLoaded = NO;
	});
}

// 获取当前ABTest数据
NSDictionary *getCurrentABTestData(void) {
    ensureABTestDataLoaded();
    AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
    return manager ? [manager abTestData] : nil;
}

static NSMutableDictionary *gCaseCache = nil;

%hook AWEABTestManager

// 拦截设置 ABTest 数据的方法
- (void)setAbTestData:(id)arg1 {
	if (abTestBlockEnabled && arg1 != gFixedABTestData) {
		return;
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
		if (arg2 && [arg2 isKindOfClass:%c(NSBlock)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
			  ((void (^)(id))arg2)(nil);
			});
		}
		return;
	}
	%orig;
}

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

// 拦截一致性ABTest值获取方法
- (id)getValueOfConsistentABTestWithKey:(id)arg1 {
    if (!abTestBlockEnabled && arg1) {
        ensureABTestDataLoaded();
        if (!gDataLoaded) {
            return %orig; 
        }
        NSString *key = (NSString *)arg1;
        id localValue = [gFixedABTestData objectForKey:key];
        
        if (localValue) {
            return localValue;
        }

        if (abTestPatchEnabled) {
            return %orig;
        }

        return nil;
    }
 
    return %orig;
}

// 拦截保存 ABTest 数据的方法
- (void)_saveABTestData:(id)arg1 {
    if (abTestBlockEnabled) {
        return;
    }
    %orig;
}

%end

%ctor {
    %init;
    abTestBlockEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYABTestBlockEnabled"];
    abTestPatchEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYABTestPatchEnabled"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
        if (manager && gDataLoaded && abTestBlockEnabled) {
            ensureABTestDataLoaded();
            [manager setAbTestData:gFixedABTestData];
        }
    });
}
