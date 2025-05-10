#import "DYYYABTestHook.h"
#import <objc/runtime.h>

@interface AWEABTestManager : NSObject
@property(retain, nonatomic) NSDictionary *abTestData;
@property(retain, nonatomic) NSMutableDictionary *consistentABTestDic;
@property(copy, nonatomic) NSDictionary *performanceReversalDic;
- (void)setAbTestData:(id)arg1;
- (void)_saveABTestData:(id)arg1;
- (id)abTestData;
+ (id)sharedManager;
@end

BOOL abTestBlockEnabled = NO;
BOOL abTestPatchEnabled = NO;
NSDictionary *gFixedABTestData = nil;
dispatch_once_t onceToken;
BOOL gDataLoaded = NO;
BOOL gFileExists = NO;
static NSDate *lastLoadAttemptTime = nil;
static const NSTimeInterval kMinLoadInterval = 60.0;
BOOL gABTestDataFixed = NO;

void ensureABTestDataLoaded(void) {
	if (gDataLoaded)
		return;

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

	  // 检查文件是否存在
	  if (![fileManager fileExistsAtPath:jsonFilePath]) {
		  gFileExists = NO;
		  gDataLoaded = YES;
		  return;
	  }

	  NSError *error = nil;
	  NSData *jsonData = [NSData dataWithContentsOfFile:jsonFilePath options:0 error:&error];

	  if (jsonData) {
		  NSDictionary *loadedData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
		  if (loadedData && !error) {
			  // 成功加载数据，保存到全局变量
			  gFixedABTestData = [loadedData copy];
			  gFileExists = YES;
			  gDataLoaded = YES;
			  return;
		  }
	  }
	  gFileExists = NO;
	  gDataLoaded = YES;
	});
}

// 优化防止频繁加载
NSDictionary *loadFixedABTestData(void) {
	if (gDataLoaded) {
		return gFileExists ? gFixedABTestData : nil;
	}

	NSDate *now = [NSDate date];
	if (lastLoadAttemptTime && [now timeIntervalSinceDate:lastLoadAttemptTime] < kMinLoadInterval) {
		return gFileExists ? gFixedABTestData : nil;
	}

	lastLoadAttemptTime = now;

	ensureABTestDataLoaded();
	return gFileExists ? gFixedABTestData : nil;
}

static NSDictionary *fixedABTestData(void) {
	if (!abTestBlockEnabled) {
		return nil;
	}

	if (!gDataLoaded) {
		ensureABTestDataLoaded();
	}

	return gFileExists ? gFixedABTestData : nil;
}

// 获取当前ABTest数据
NSDictionary *getCurrentABTestData(void) {
	if (abTestBlockEnabled) {
		if (!gDataLoaded) {
			ensureABTestDataLoaded();
		}
		if (!gFileExists) {
			AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
			return manager ? [manager abTestData] : nil;
		}
		return gFixedABTestData;
	}

	AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
	if (!manager) {
		return nil;
	}

	NSDictionary *currentData = [manager abTestData];
	return currentData;
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
    if (gABTestDataFixed) {
        return %orig;
    }

    if ((abTestBlockEnabled || abTestPatchEnabled) && arg1) {
        if (!gDataLoaded) {
            ensureABTestDataLoaded();
        }
        if (!gFileExists) {
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

%end

%ctor {
    %init;
    abTestBlockEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYABTestBlockEnabled"];
    abTestPatchEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYABTestPatchEnabled"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AWEABTestManager *manager = [%c(AWEABTestManager) sharedManager];
        if (manager && gFixedABTestData && abTestBlockEnabled && !abTestPatchEnabled) {
            [manager setAbTestData:gFixedABTestData];

            if ([manager respondsToSelector:@selector(_saveABTestData:)]) {
                [manager _saveABTestData:gFixedABTestData];
            }

            gABTestDataFixed = YES;
        } else {
            NSLog(@"[DYYY] 无法设置ABTest数据: manager=%@, data=%@, 模式=%@", 
                manager, 
                gFixedABTestData ? @"已加载" : @"未加载",
                abTestPatchEnabled ? @"补丁模式" : (abTestBlockEnabled ? @"完全替换模式" : @"未启用"));
        }
    });
}
